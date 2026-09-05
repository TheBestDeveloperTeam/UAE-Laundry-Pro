# API Contract (v1)

Base URL: `http://localhost/laundrypro-api/public/api/v1`

Live spec: `GET /docs/openapi.json`  
Swagger UI: `/docs/`  
Version: **1.2.1** (Phase 3 + peripherals client)

## OpenAPI tags

| Tag | Endpoints |
|-----|-----------|
| Platform | `GET /health`, `GET /docs`, `GET /docs/openapi.json` |
| Identity | `POST /auth/login`, `/refresh`, `/logout`, `GET /auth/me` |
| Configuration | `GET /settings`, `PUT /settings`, `GET /business`, `PUT /business` |
| Install | `GET /install/status`, `POST /install/migrate`, `/seed`, `/complete` |
| Customers | `GET/POST /customers`, `GET/PUT /customers/{id}` |
| Vendors | `GET/POST /vendors`, `GET/PUT /vendors/{id}` |
| Catalog | `GET/POST /services`, products, modifiers, service-product map |
| Sales | draft, confirm, payment, status, delivery tasks |
| Inventory | receipt, adjustment, movements, stock, reconcile |
| Purchasing | purchase-orders, receive |
| Challans | CRUD, cancel |
| Delivery | schedule, complete |
| HR | employees, attendance, leave, payroll, salary-advances |
| Expenses | categories, expenses, approve/reject |
| Reports | sales, expenses, payroll, inventory, production summaries |
| Notifications | list, read, generate |
| Branches | `/branches`, `/terminals`, register |
| Analytics | summary, trends, refresh |
| Localization | profiles, country |
| Channels | SMS/WhatsApp config + test |
| Accounting | export batches |
| Storefront | public catalog, orders |
| CustomerPortal | tokens, order status |
| Sync | status, push, pull, entities, config |
| License | status, activate |
| Backup | run, history, verify, restore validate |

## Peripherals (Flutter client only)

No API routes. Hardware handled in `lib/peripherals/` via Windows spooler, keyboard wedge, and local SQLite. Admin console: `/settings/peripherals`. See `docs/peripherals/README.md`.

## Response envelope

```json
{
  "success": true,
  "code": "OK",
  "message_key": "common.success",
  "data": {},
  "errors": [],
  "meta": { "request_id": "...", "server_time": "...", "version": "1.2.1" }
}
```
