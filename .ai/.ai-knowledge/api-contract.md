# API Contract Specification (v1.2.1)

This document provides the exhaustive specification for both the **Local Workstation API** and the **Central Multi-Tenant Cloud API**.

---

## 1. Local Workstation API

- **Base URL:** http://laundrypro-localapi/api/v1 (or http://localhost/laundrypro-api/public/api/v1)
- **Interactive Documentation:** http://laundrypro-localapi/docs/ (Bundled Swagger UI)
- **OpenAPI Schema:** GET /docs/openapi.json
- **Security:** Authorization: Bearer <JWT_ACCESS_TOKEN>
- **Response Envelope:**
`json
{
   success: true,
  code: OK,
  message_key: common.success,
  data: {},
  errors: [],
  meta: {
    request_id: req-665b12879a,
    server_time: 2026-09-08T13:30:00Z,
    version: 1.2.1
  }
}
`

### Module Route Map

| Domain | Methods & Routes | Description |
|---|---|---|
| **Platform** | GET /health<br/>GET /docs/openapi.json | Local node health status & OpenAPI specification |
| **Identity & Auth** | POST /auth/login<br/>POST /auth/refresh<br/>POST /auth/logout<br/>GET /auth/me | User login, JWT refresh token rotation, current profile |
| **System Install** | GET /install/status<br/>POST /install/migrate<br/>POST /install/seed<br/>POST /install/complete | Self-healing background migration & baseline seeds |
| **Business Profile** | GET /business<br/>PUT /business | Laundry trade name, TRN tax number, address, phone |
| **Settings** | GET /settings<br/>PUT /settings | Key-value application configurations (tax, printer, locale) |
| **Customers** | GET /customers<br/>POST /customers<br/>GET /customers/{id}<br/>PUT /customers/{id} | Customer master, contact details, balance, credit limit |
| **Vendors** | GET /vendors<br/>POST /vendors<br/>GET /vendors/{id}<br/>PUT /vendors/{id} | Supplier directory, tax registration, payment terms |
| **Catalog** | GET /services<br/>POST /services<br/>GET /products<br/>POST /products<br/>GET /catalog/categories | Service & product hierarchy, price matrix, bundles |
| **Sales & POS** | POST /sales/draft<br/>POST /sales/orders<br/>GET /sales/orders/{id}<br/>POST /sales/orders/{id}/payments<br/>PUT /sales/orders/{id}/status | Instant POS transaction, payments, receipt generation |
| **Challans** | GET /challans<br/>POST /challans<br/>GET /challans/{id}<br/>POST /challans/{id}/cancel | Internal factory transfer challan slips & line tracking |
| **Delivery** | GET /delivery/tasks<br/>POST /delivery/tasks/schedule<br/>PUT /delivery/tasks/{id}/complete | Driver delivery dispatch and completion workflows |
| **Inventory** | GET /inventory/stock<br/>POST /inventory/adjustments<br/>GET /inventory/movements | Real-time stock counts, stock audits, item consumption |
| **Purchasing** | GET /purchasing/orders<br/>POST /purchasing/orders<br/>POST /purchasing/orders/{id}/receive | Purchase orders, supplier goods receipt notes (GRN) |
| **HR & Payroll** | GET /employees<br/>POST /employees<br/>POST /attendance/check-in<br/>POST /attendance/check-out<br/>GET /payroll/periods<br/>POST /payroll/generate | Staff master, biometric/manual punch, WPS payroll run |
| **Expenses** | GET /expenses<br/>POST /expenses<br/>GET /expenses/categories | Petty cash vouchers, utility bills, rent, approvals |
| **Reports** | GET /reports/sales/summary<br/>GET /reports/expenses/summary<br/>GET /reports/payroll/summary | Daily closing, Z-report, profit & loss, VAT report |
| **License & UMAC** | GET /license/status<br/>POST /license/activate | UMAC validation, trial limits, cryptographic license key |
| **Backup & Restore** | POST /backup/run<br/>GET /backup/history<br/>POST /backup/verify | SQL automated dump, archive verification, restore |
| **Sync Engine** | GET /sync/status<br/>POST /sync/push<br/>GET /sync/pull<br/>PUT /sync/config | Local outbox status and manual trigger to cloud |

---

## 2. Central Multi-Tenant Cloud API

- **Base URL:** https://www.laundrypro-cloudapi.magnificentsolution.co.in/ (or http://localhost/cloud-api/public)
- **Tenant Identification:** Header X-Business-Owner-Id: <tenant-uuid>
- **Authorization:** Authorization: Bearer <cloud_token>

| Method | Endpoint | Description |
|---|---|---|
| GET | /api/v1/health | Multi-tenant cloud gateway operational status |
| POST | /api/v1/businesses/register | Auto-registers new local laundry node and issues cloud token |
| POST | /api/v1/sync/push | Ingests queued local outbox delta payloads into cloud storage |
| GET | /api/v1/sync/pull | Fetches delta updates from cloud partitioned by tenant |
| POST | /api/v1/license/handshake | Machine fingerprint telemetry, remote kill-switch, renewal |

---

## 3. Super-Admin Web Portal Routes (/admin)

| Method | Endpoint | Access Level | Description |
|---|---|---|---|
| GET | /admin/login | Public | Super-Admin AdminLTE login screen |
| POST | /admin/login | Public (CSRF) | Authenticates session with bcrypt hash verification |
| GET | /admin | Authenticated | Super-Admin Executive KPI Dashboard |
| GET | /admin/tenants | Authenticated | Registered tenant nodes, tokens, and status toggles |
| GET | /admin/licenses | Authenticated | Cryptographic license generator and active licenses |
| POST | /admin/licenses/issue | Authenticated | Generates signed license key for hardware UMAC |
| POST | /admin/licenses/revoke| Authenticated | Instantly kills/revokes an active tenant license |
| GET | /admin/sync | Authenticated | Live stream inspector of ingested node data records |
| GET | /admin/audit | Authenticated | Chronological audit log of all super-admin actions |
| POST | /admin/logout | Authenticated | Terminates super-admin session |
