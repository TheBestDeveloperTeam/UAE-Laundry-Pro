# LaundryPro UAE — System Architecture

> **Version:** 2.0.0 | **Last Updated:** 2026-09-30 | **Status:** Authoritative

---

## 1. System Overview

LaundryPro UAE is a **dual-API, dual-portal, dual-database, offline-first** enterprise laundry management platform designed for the UAE market.

### 1.1 Component Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CLOUD INFRASTRUCTURE                          │
│                                                                         │
│  ┌──────────────────────┐    ┌─────────────────────────────────────┐   │
│  │   Cloud Super-Admin  │    │         Cloud API (PHP 8.2)        │   │
│  │    Portal (AdminLTE) │◄──►│  Multi-Tenant REST + Sync Receiver │   │
│  │  ● Tenant Management │    │  ● License Validation              │   │
│  │  ● License Issuance  │    │  ● Sync Push/Pull                  │   │
│  │  ● Sync Inspector    │    │  ● Centralized Reports             │   │
│  │  ● Audit Logs        │    │  ● Device Telemetry                │   │
│  └──────────────────────┘    └─────────────────┬───────────────────┘   │
│                                                 │                       │
│                              ┌──────────────────┴──────────────────┐   │
│                              │    Cloud MariaDB (Multi-Tenant)     │   │
│                              │  ● businesses, cloud_licenses       │   │
│                              │  ● sync_records, sync_inbox         │   │
│                              │  ● cloud_telemetry, audit_logs      │   │
│                              └──────────────────┬──────────────────┘   │
└─────────────────────────────────────────────────┼──────────────────────┘
                                                  │
                         ╔════════════════════════╧═════════════════╗
                         ║   SYNC CHANNEL (HTTPS, Outbox/Inbox)    ║
                         ║   Local API ↔ Cloud API (background)    ║
                         ║   Flutter NEVER sees sync internals     ║
                         ╚════════════════════════╤═════════════════╝
                                                  │
┌─────────────────────────────────────────────────┼──────────────────────┐
│                     LOCAL WORKSTATION (Per Store)│                      │
│                                                 │                      │
│  ┌────────────────────┐    ┌───────────────────┴────────────────┐    │
│  │  Local Admin Portal │    │       Local API (PHP 8.2)         │    │
│  │  (AdminLTE v4)      │◄──►│  Offline-First REST API           │    │
│  │  ● Dashboard KPIs   │    │  ● 178 Endpoints                  │    │
│  │  ● Sales/Orders     │    │  ● JWT Auth + RBAC                │    │
│  │  ● HR/Payroll       │    │  ● Sync Outbox → Cloud            │    │
│  │  ● Reports          │    │  ● License + UMAC Validation      │    │
│  └────────────────────┘    └───────────────────┬────────────────┘    │
│                                                 │                      │
│  ┌────────────────────┐    ┌───────────────────┴────────────────┐    │
│  │  Flutter Desktop   │    │    Local MariaDB (Single-Tenant)   │    │
│  │  (Windows POS)     │◄──►│  ● ~90 Tables (full business data)│    │
│  │  ● Offline-First   │    │  ● sync_outbox, sync_state         │    │
│  │  ● SQLite Cache    │    │  ● audit_logs                      │    │
│  │  ● ESC/POS Print   │    └────────────────────────────────────┘    │
│  │  ● RFID/Barcode    │                                              │
│  └────────────────────┘    ┌────────────────────────────────────┐    │
│                            │  Windows Registry (Write-Once)     │    │
│                            │  ● UMAC Hardware Fingerprint       │    │
│                            │  ● Install Pulse (Anti-Tamper)     │    │
│                            └────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

### 1.2 Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| **Local API** | Pure PHP (no framework) | 8.2 | Zero-dependency micro-framework |
| **Cloud API** | Pure PHP (no framework) | 8.2 | Multi-tenant REST + portal |
| **Database** | MariaDB / MySQL | 10.6+ / 8.0+ | ACID-compliant RDBMS |
| **Flutter App** | Flutter Desktop (Windows) | 3.x | Offline-first POS client |
| **State Management** | Riverpod | 2.6.x | Reactive state management |
| **HTTP Client** | Dio | 5.11.x | HTTP with interceptors |
| **Local Storage** | SQLite (sqflite_common_ffi) | 2.3.x | Offline cache |
| **Secure Storage** | flutter_secure_storage | 9.2.x | Token/credential storage |
| **Printing** | ESC/POS + PDF | Various | Thermal + A4 receipt/invoice |
| **Portal UI** | AdminLTE v4 | 4.x | Enterprise admin dashboard |

---

## 2. API Architecture

### 2.1 Dual-API Design

Both APIs share identical endpoint signatures but differ in scope:

| Aspect | Local API (`api/`) | Cloud API (`cloud-api/`) |
|---|---|---|
| **Scope** | Single workstation/store | All tenants (multi-tenant) |
| **Auth** | JWT (user-scoped) | JWT (tenant+user-scoped) |
| **Database** | `laundrypro` (local) | `laundrypro_cloud` (centralized) |
| **URL** | `https://laundrypro-api` | `https://laundrypro-cloudapi.magnificentsolution.co.in` |
| **Parity Target** | Reference implementation | 99.99% identical surface |

### 2.2 Request Lifecycle

```
Client Request
    │
    ▼
┌────────────────┐
│   CORS Check   │  ← CorsMiddleware
└───────┬────────┘
        ▼
┌────────────────┐
│  Rate Limiter  │  ← RateLimitMiddleware
└───────┬────────┘
        ▼
┌────────────────┐
│  JWT Decode    │  ← AuthMiddleware (extracts user_id, role_id)
└───────┬────────┘
        ▼
┌────────────────┐
│  Permission    │  ← PermissionMiddleware (checks role.permissions vs route)
│  Check         │
└───────┬────────┘
        ▼
┌────────────────┐
│  Idempotency   │  ← IdempotencyMiddleware (POST/PUT dedup via X-Idempotency-Key)
└───────┬────────┘
        ▼
┌────────────────┐
│  Controller    │  ← Domain logic
│  Method        │
└───────┬────────┘
        ▼
┌────────────────┐
│  Audit Log     │  ← AuditLogMiddleware (records action to audit_logs)
└───────┬────────┘
        ▼
JSON Response Envelope
```

### 2.3 Standard Response Envelope

Every API response follows this structure:

```json
{
  "success": true,
  "code": "OPERATION_SUCCESS_CODE",
  "message_key": "localization.key",
  "data": { },
  "errors": [],
  "meta": {
    "request_id": "a1b2c3d4e5f6",
    "server_time": "2026-09-30T14:00:00+04:00",
    "version": "1.2.0"
  }
}
```

---

## 3. Sync Architecture

### 3.1 Core Principles

1. **Sync = Local API ↔ Cloud API ONLY.** Flutter never sees sync.
2. **Outbox pattern** — mutations are queued locally, pushed asynchronously.
3. **Cursor-based pull** — global sequence IDs, not timestamps.
4. **3-way merge** — conflict resolution uses base + local + cloud states.
5. **Dead-letter queue** — unresolvable conflicts are quarantined for manual review.

### 3.2 Sync State Machine (Per Row)

```
        ┌──────────────────────────────────────────────────────┐
        │                                                      │
        ▼                                                      │
    ┌─────────┐    Push     ┌─────────┐   ACK    ┌─────────┐ │
    │ pending │──────────►│ pushing │────────►│ synced  │ │
    └─────────┘            └─────────┘          └─────────┘ │
        │                      │                     │        │
        │                      │ NACK/Timeout        │ Mutate │
        │                      ▼                     │        │
        │               ┌──────────┐                 │        │
        │               │  failed  │                 │        │
        │               └──────────┘                 │        │
        │                    │ Retry                  │        │
        │                    │ (backoff)              │        │
        │                    ▼                        │        │
        │            ┌──────────────┐                │        │
        │            │ dead_letter  │                │        │
        │            │ (attempts>10)│                │        │
        │            └──────────────┘                │        │
        │                                            │        │
        └────────────────────────────────────────────┘        │
                                                              │
    ┌──────────┐                                              │
    │ conflict │  ← 3-way merge detected divergence ──────────┘
    └──────────┘
```

### 3.3 Conflict Resolution Rules

| Field Category | Resolution Strategy |
|---|---|
| Structural data (name, address, config) | Cloud wins |
| Operational status (order status, delivery) | Local wins (latest timestamp) |
| Financial data (prices, totals) | Cloud wins (audit trail) |
| Metadata (updated_at, sync_status) | Auto-resolved |

---

## 4. License Architecture

### 4.1 3-Way Handshake

```
Flutter ──► Local API ──► Cloud API
                │              │
                ▼              ▼
          Win Registry    Cloud DB
          (UMAC + Pulse)  (License Record)
```

1. **Step 1:** Flutter requests activation via Local API
2. **Step 2:** Local API generates UMAC (hardware fingerprint) from CPU ID + baseboard serial
3. **Step 3:** UMAC written to Windows Registry (write-once, anti-tamper)
4. **Step 4:** Local API sends `{license_key, umac}` to Cloud API
5. **Step 5:** Cloud API validates key, checks device limits, returns plan details
6. **Step 6:** Local API stores validated license in local `license` table

### 4.2 Plan Types

| Plan | Max Devices | Max Invoices | Max Customers | Features |
|---|---|---|---|---|
| Trial | 1 | 9 | 9 | Basic POS, 7-day limit |
| Standard | 1 | Unlimited | Unlimited | Full POS + Reports |
| Premium | 5 | Unlimited | Unlimited | Multi-branch + Sync |
| Enterprise | 999 | Unlimited | Unlimited | Full platform + API |

---

## 5. Security Model

### 5.1 Authentication

- **Local API:** JWT Bearer tokens (short-lived access + long-lived refresh)
- **Cloud API:** JWT Bearer tokens (tenant-scoped)
- **Portal:** Session-based with CSRF tokens

### 5.2 Authorization (RBAC)

- Roles stored in `roles` table with JSON permissions array
- PermissionMiddleware checks route requirements against user's role
- Wildcard `*` permission grants full access (administrator role)

### 5.3 Hardware Identity (UMAC)

- Unique Machine Authentication Code
- Generated from: `SHA256(hostname | CPU_ID | baseboard_serial)`
- Format: `UMAC-XXXX-XXXX-XXXX`
- Stored in Windows Registry at `HKCU\Software\LaundryProUAE\Evaluation`

---

## 6. Directory Structure

```
UAE-Laundry-Pro/
├── api/                          # Local API (PHP 8.2)
│   ├── config/                   # App, database, security config
│   ├── database/                 # Migration runner
│   ├── docs/                     # OpenAPI spec, QA checklists
│   ├── logs/                     # Apache error/access logs
│   ├── public/                   # Web root (index.php, .htaccess)
│   ├── routes/                   # api.php (178 routes)
│   ├── src/
│   │   ├── Adapters/             # Hardware interface adapters
│   │   ├── Controllers/          # 43 domain controllers
│   │   ├── Core/                 # Router, Container, Request, Response
│   │   ├── Docs/                 # OpenAPI generator
│   │   ├── Helpers/              # ApiResponse, Logger
│   │   ├── Middleware/           # Auth, CORS, RateLimit, Audit, Idempotency
│   │   ├── Repositories/        # 39 data access repositories
│   │   ├── Security/            # JWT, PasswordHasher, UMAC, Permissions
│   │   ├── Services/            # 16 business services
│   │   └── Views/               # Portal PHP templates
│   └── storage/                  # Logs, rate limits, backups
│
├── cloud-api/                    # Cloud API (PHP 8.2)
│   ├── config/                   # App, database config
│   ├── database/                 # Migration runner + migrations/
│   ├── logs/                     # Apache logs
│   ├── public/                   # Web root
│   ├── scripts/                  # Deployment scripts
│   ├── src/
│   │   ├── Controllers/          # Cloud API + Admin Portal controllers
│   │   ├── Core/                 # Database, Env, Request, Response, Router
│   │   └── Views/               # Portal PHP templates (AdminLTE)
│   └── storage/                  # Backups, sessions
│
├── lib/                          # Flutter Desktop App
│   ├── core/                     # Constants, theme, validators, formatters
│   ├── features/                 # Auth, POS, Wizard feature modules
│   ├── models/                   # 23 domain models
│   ├── peripherals/              # Printers, scanners, hardware integration
│   ├── providers/                # 5 Riverpod providers
│   ├── router/                   # GoRouter navigation
│   ├── services/                 # 38 API service wrappers
│   ├── views/                    # 42 screen widgets
│   └── widgets/                  # 4 shared UI widgets
│
├── database/
│   ├── local/schema.sql          # Local-only schema (single-tenant)
│   ├── cloud/schema.sql          # Cloud-only schema (multi-tenant)
│   ├── schema.sql                # Legacy combined (deprecated)
│   └── seed.sql                  # Seed data
│
├── docs/                         # Documentation root
│   ├── architecture/             # System architecture docs
│   ├── api/                      # API reference docs
│   ├── sync/                     # Sync engine documentation
│   ├── security/                 # Security model docs
│   ├── swagger/                  # OpenAPI specifications
│   └── ...                       # Other doc categories
│
├── assets/                       # Flutter assets
│   ├── lang/                     # en.json, ar.json
│   ├── images/                   # App images
│   └── animations/               # Lottie animations
│
└── scripts/                      # Automation scripts
    └── setup-client-node.ps1     # Workstation setup automation
```

---

## 7. Environment Configuration

### 7.1 Local Development

| File | Purpose |
|---|---|
| `api/.env` | Local API database, JWT, paths |
| `cloud-api/.env` | Cloud API database (dev) |
| Windows `hosts` | `127.0.0.1 laundrypro-api` + `127.0.0.1 cloud-api` |
| Apache vhosts | Virtual hosts for both APIs |

### 7.2 Production

| File | Purpose |
|---|---|
| `api/.env` | Production local API config |
| `cloud-api/.env.production` | Production cloud credentials (NOT in git) |
| DNS | `laundrypro-cloudapi.magnificentsolution.co.in` |

---

*This document is the authoritative architecture reference for the LaundryPro UAE platform.*
