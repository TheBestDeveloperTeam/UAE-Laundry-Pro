# API Contract (v1)

Base URL: `http://localhost/laundrypro-api/public/api/v1`

Live spec: `GET /docs/openapi.json`  
Swagger UI: `/docs/`  
Version: **1.1.0** (Phase 2)

## OpenAPI tags

| Tag | Endpoints |
|-----|-----------|
| Platform | `GET /health`, `GET /docs`, `GET /docs/openapi.json` |
| Identity | `POST /auth/login`, `/refresh`, `/logout`, `GET /auth/me` |
| Configuration | `GET /settings`, `PUT /settings`, `GET /business`, `PUT /business` |
| Install | `GET /install/status`, `POST /install/migrate`, `/seed`, `/complete` |
| Customers | `GET/POST /customers`, `GET/PUT /customers/{id}` |
| Vendors | `GET/POST /vendors`, `GET/PUT /vendors/{id}` |
| Catalog | `GET/POST /services`, `GET/PUT /services/{id}`, products, modifiers, service-product map |
| Sales | `GET /sales`, `POST /sales/draft`, confirm, payment, `PATCH /sales/{id}/status`, status-history, delivery tasks |
| Inventory | `POST /inventory/receipt`, `/adjustment`, `GET /movements`, `/stock`, `POST /reconcile` |
| Purchasing | `GET/POST /purchase-orders`, `PUT /purchase-orders/{id}`, `POST /purchase-orders/{id}/receive` |
| Challans | `GET/POST /challans`, `GET/PUT /challans/{id}`, `POST /challans/{id}/cancel` |
| Delivery | `GET/POST /sales/{id}/delivery`, `PATCH /delivery-tasks/{id}/complete` |
| HR | `GET/POST /employees`, attendance, leave-requests, payroll periods/run, salary-advances |
| Expenses | `GET/POST /expense-categories`, `GET/POST /expenses`, `PATCH /expenses/{id}/approve\|reject` |
| Reports | sales, expenses, payroll, inventory valuation, production throughput summaries |
| Notifications | `GET /notifications`, `PATCH /notifications/{id}/read`, `POST /notifications/generate` |
| Sync | `GET /sync/status`, `POST /sync/push`, `GET /sync/pull`, `PUT /sync/config` |
| License | `GET /license/status`, `POST /license/activate` |
| Backup | `POST /backup/run`, `GET /backup/history`, `POST /backup/verify`, `POST /backup/restore/validate` |

## Response envelope

```json
{
  "success": true,
  "code": "OK",
  "message_key": "common.success",
  "data": {},
  "errors": [],
  "meta": { "request_id": "...", "server_time": "...", "version": "1.1.0" }
}
```
