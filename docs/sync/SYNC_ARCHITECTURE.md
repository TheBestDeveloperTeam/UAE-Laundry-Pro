# LaundryPro UAE — Sync Architecture

> **Version:** 2.0.0 | **Last Updated:** 2026-09-30

---

## 1. Overview

Sync operates exclusively between **Local API ↔ Cloud API**. Flutter never sees sync internals. The sync engine uses an **outbox/inbox pattern** with **cursor-based pagination** and **3-way merge conflict resolution**.

## 2. Core Principles

| # | Principle | Details |
|---|---|---|
| 1 | **Flutter isolation** | Flutter POS app has ZERO awareness of sync. All CRUD goes through Local API. |
| 2 | **Outbox pattern** | Local mutations are queued in `sync_outbox`, pushed asynchronously to Cloud. |
| 3 | **Inbox pattern** | Cloud-originated changes are queued in `sync_inbox`, pulled by Local API. |
| 4 | **Cursor-based** | Pull uses `global_sequence_id`, never timestamps (avoids clock skew). |
| 5 | **Idempotent** | Push uses `entity_uuid` as dedup key. Duplicate pushes are safe. |
| 6 | **Batch processing** | All sync operations use batches of ≤100 records per request. |
| 7 | **Exponential backoff** | Failed pushes retry with `delay = 2^attempts * 60s`, max 10 attempts. |
| 8 | **Dead-letter queue** | Records exceeding retry limit are moved to `sync_conflicts`. |

## 3. Sync Flow

### 3.1 Push Flow (Local → Cloud)

```
Local DB Mutation (INSERT/UPDATE/DELETE)
    │
    ▼
sync_outbox INSERT (status=pending, entity_uuid, payload)
    │
    ▼ (Background daemon, every 60s)
SELECT FROM sync_outbox WHERE status IN ('pending','failed') AND next_retry_at <= NOW() LIMIT 100
    │
    ▼
POST /api/v1/sync/push → Cloud API
    │
    ├─── 200 OK ──► UPDATE sync_outbox SET status='synced'
    │
    ├─── 409 Conflict ──► INSERT sync_conflicts, status='conflict'
    │
    └─── 5xx / Timeout ──► attempts++
                           if attempts > 10: status='dead_letter'
                           else: next_retry_at = NOW() + 2^attempts * 60s
```

### 3.2 Pull Flow (Cloud → Local)

```
Sync Daemon Timer (every 60s)
    │
    ▼
GET /api/v1/sync/pull?since={last_global_sequence_id}&limit=100
    │
    ▼
Cloud API returns batch of records
    │
    ▼
For each record:
    ├── Fetch local entity baseline (last synced state)
    ├── Fetch local entity current state
    ├── Compare with cloud state
    │
    ├── No local changes since baseline ──► Overwrite with cloud state
    ├── Only cloud changed ──► Apply cloud state
    ├── Both changed (no field overlap) ──► Merge fields
    └── Both changed (field conflict) ──► Apply conflict resolution rules
    │
    ▼
Update last_global_sequence_id
```

## 4. Syncable Entity Types

| Entity | Direction | Conflict Strategy | Priority |
|---|---|---|---|
| `customers` | Bidirectional | Cloud wins (name/address), Local wins (balance) | P0 |
| `services` | Bidirectional | Cloud wins | P0 |
| `products` | Bidirectional | Cloud wins | P0 |
| `sales_orders` | Local → Cloud | Local authoritative (origin store) | P0 |
| `payment_transactions` | Local → Cloud | Local authoritative | P0 |
| `invoices` | Local → Cloud | Local authoritative | P0 |
| `employees` | Bidirectional | Cloud wins | P1 |
| `vendors` | Bidirectional | Cloud wins | P1 |
| `expenses` | Local → Cloud | Local authoritative | P1 |
| `inventory_movements` | Local → Cloud | Local authoritative | P1 |
| `settings` | Cloud → Local | Cloud authoritative | P1 |
| `roles` | Cloud → Local | Cloud authoritative | P2 |

## 5. Database Tables

### 5.1 Local Tables

**`sync_outbox`** — Queue of local mutations to push to cloud

| Column | Type | Description |
|---|---|---|
| `id` | BIGINT PK | Auto-increment |
| `uuid` | CHAR(36) | Unique outbox record ID |
| `entity_type` | VARCHAR(100) | e.g., 'customers', 'sales_orders' |
| `entity_id` | CHAR(36) | `row_uuid` of the mutated entity |
| `operation` | ENUM | INSERT, UPDATE, DELETE |
| `payload` | JSON | Full entity snapshot |
| `status` | ENUM | pending, pushing, synced, failed, dead_letter |
| `attempts` | TINYINT | Retry count (max 10) |
| `next_retry_at` | TIMESTAMP | Next retry time (exponential backoff) |
| `created_at` | TIMESTAMP | When mutation occurred |

**`sync_state`** — Global sync configuration and last-sync cursors

| Column | Type | Description |
|---|---|---|
| `admin_id` | INT PK | Business owner ID |
| `is_enabled` | TINYINT | Sync on/off |
| `cloud_api_url` | VARCHAR(500) | Target cloud URL |
| `cloud_token` | VARCHAR(255) | Auth token for cloud |
| `last_push_at` | TIMESTAMP | Last successful push |
| `last_pull_at` | TIMESTAMP | Last successful pull |
| `last_global_sequence_id` | BIGINT | Pull cursor |

### 5.2 Cloud Tables

**`sync_records`** — Received push records from all tenants

**`sync_inbox`** — Outbound records for tenants to pull

**`sync_conflicts`** — Dead-letter queue for unresolvable conflicts

**`sync_health_snapshots`** — Periodic health metrics per tenant

## 6. API Endpoints

### 6.1 Local API Sync Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/v1/sync/status` | Current sync state and pending counts |
| `GET` | `/api/v1/sync/entities` | List syncable entity types |
| `POST` | `/api/v1/sync/push` | Push pending outbox records to cloud |
| `GET` | `/api/v1/sync/pull` | Pull new records from cloud |
| `GET` | `/api/v1/sync/config` | Get/update sync configuration |

### 6.2 Cloud API Sync Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/sync/push` | Receive push from local API |
| `GET` | `/api/v1/sync/pull` | Serve pull requests from local API |
| `GET` | `/api/v1/sync/health` | Sync health metrics per tenant |
| `POST` | `/api/v1/sync/backup` | Receive backup upload from local |

## 7. Backoff Algorithm

```
function calculateDelay(attempts: int): seconds
    if attempts > 10:
        return DEAD_LETTER  // Move to dead-letter queue
    base_delay = 60         // 1 minute
    delay = 2^attempts * base_delay
    max_delay = 86400       // 24 hours cap
    jitter = random(0, delay * 0.1)
    return min(delay + jitter, max_delay)
```

| Attempt | Delay |
|---|---|
| 1 | ~2 min |
| 2 | ~4 min |
| 3 | ~8 min |
| 4 | ~16 min |
| 5 | ~32 min |
| 6 | ~1 hour |
| 7 | ~2 hours |
| 8 | ~4 hours |
| 9 | ~8.5 hours |
| 10 | ~17 hours |
| 11+ | Dead letter |

---

*This document is the authoritative sync architecture reference.*
