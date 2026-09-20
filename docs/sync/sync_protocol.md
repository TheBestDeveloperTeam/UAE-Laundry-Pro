# Sync Protocol Specification - LaundryPro UAE
> **Version:** 1.0.0

## Sync Outbox Schema
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Entry ID |
| sequence_number | BIGINT UNSIGNED | Monotonic sequence |
| idempotency_key | CHAR(36) UUID | Deduplication key |
| table_name | VARCHAR(100) | Target table |
| row_id | BIGINT UNSIGNED | Target row PK |
| operation | ENUM('INSERT','UPDATE','DELETE') | Operation type |
| payload | JSON | Data payload |
| business_owner_id | BIGINT UNSIGNED FK | Tenant scope |
| status | ENUM('pending','synced','failed','dead') | Sync status |
| retry_count | INT DEFAULT 0 | Retry attempts |
| created_at | DATETIME | Entry creation time |
| synced_at | DATETIME NULL | Sync completion time |

## Push Protocol
POST /api/v1/sync/push with batch of outbox entries (max 100 per request).

## Pull Protocol
GET /api/v1/sync/pull?since={last_sequence}&limit=100.

## Conflict Resolution
Last-Write-Wins by updated_at. If equal timestamps, higher sequence_number wins.
Unresolvable conflicts moved to dead-letter queue for manual resolution.