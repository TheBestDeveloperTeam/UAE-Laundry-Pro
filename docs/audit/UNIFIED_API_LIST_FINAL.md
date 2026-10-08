# LaundryPro UAE — Unified API List (Final)

This document represents the canonical API topology mapping Local execution to Cloud synchronization.

| Domain | Sub-Module | Local API (`localhost:8000`) | Cloud API (`cloud.magnificentsolution.co.in`) | Notes |
|:-------|:-----------|:-----------------------------|:----------------------------------------------|:------|
| **Platform** | Health | ✅ `/api/v1/health` | ✅ `/api/v1/health` | |
| | Docs | ✅ `/api/v1/docs` | ✅ `/api/v1/docs` | |
| | Settings | ✅ `/api/v1/settings` | ✅ `/api/v1/settings` | |
| **Auth** | Login/JWT | ✅ `/api/v1/auth/login` | ✅ `/api/v1/auth/login` | Cloud supports cross-tenant login |
| | Me/Profile | ✅ `/api/v1/auth/me` | ✅ `/api/v1/auth/me` | |
| **Catalog** | Services | ✅ `/api/v1/services` | ✅ `/api/v1/services` | |
| | Products | ✅ `/api/v1/products` | ✅ `/api/v1/products` | |
| **Sales** | POS Draft | ✅ `/api/v1/sales/draft` | ✅ `/api/v1/sales/draft` | |
| | Confirm/Pay | ✅ `/api/v1/sales/{id}/confirm` | ✅ `/api/v1/sales/{id}/confirm` | |
| | Invoices | ✅ `/api/v1/invoices` | ✅ `/api/v1/invoices` | |
| **Customers** | Profiles | ✅ `/api/v1/customers` | ✅ `/api/v1/customers` | |
| **Inventory** | Stock/Move | ✅ `/api/v1/inventory/stock` | ✅ `/api/v1/inventory/stock` | |
| | Purchase | ✅ `/api/v1/purchase-orders` | ✅ `/api/v1/purchase-orders` | |
| **HR** | Employees | ✅ `/api/v1/employees` | ✅ `/api/v1/employees` | |
| | Payroll/Leave| ✅ `/api/v1/payroll` | ✅ `/api/v1/payroll` | |
| **Reporting** | Summaries | ✅ `/api/v1/reports/*` | ✅ `/api/v1/reports/*` | |
| **Hardware** | LAN Bind | ✅ `/api/v1/lan/bind` | ❌ *Removed (P0)* | Local only |
| | RFID Scan | ✅ `/api/v1/rfid/scan` | ❌ *Removed (P0)* | Local only |
| **Setup** | Install | ✅ `/api/v1/install/*` | ❌ *Removed (P0)* | Local only |
| **Cloud** | Sync Push | ❌ N/A | ✅ `/api/v1/sync/push` | Cloud only |
| | Sync Pull | ❌ N/A | ✅ `/api/v1/sync/pull` | Cloud only |
| | License | ❌ N/A | ✅ `/api/v1/license/approve` | Cloud only |
| | Super-Admin | ❌ N/A | ✅ `/api/v1/admin/console/*` | Cloud only |
