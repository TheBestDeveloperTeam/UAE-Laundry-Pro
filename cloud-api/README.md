# Cloud API scaffold — multi-tenant sync (CR-2026-09-02-001)

Plain PHP cloud API for tenant-isolated sync. Deploy separately from local `api/`.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/businesses/register` | Register tenant |
| POST | `/api/v1/sync/push` | Receive local changes |
| GET | `/api/v1/sync/pull` | Return changes since timestamp |

All requests require `X-Business-Owner-Id` + `Authorization: Bearer <cloud_token>`.

## Local integration

Local API `POST /api/v1/sync/push` marks outbox rows synced; configure cloud URL via `PUT /api/v1/sync/config`.

Run scheduler: `php api/scripts/sync_scheduler.php`
