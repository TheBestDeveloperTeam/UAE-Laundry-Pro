# LaundryPro UAE — API Reference

> **Version:** 1.2.1 · **Base URL:** `http://<host>/laundrypro-api/public` · **Spec UI:** `/docs/`

---

## Table of Contents

- [Framework Overview](#framework-overview)
- [Standard JSON Envelope](#standard-json-envelope)
- [Authentication](#authentication)
- [Rate Limiting](#rate-limiting)
- [Endpoint Reference](#endpoint-reference)
  - [Health](#health)
  - [Install](#install)
  - [Auth](#auth)
  - [Sales](#sales)
  - [Catalog](#catalog)
  - [Inventory](#inventory)
  - [Customers](#customers)
  - [Customer Portal](#customer-portal)
  - [HR — Employees, Attendance, Leave, Payroll, Salary Advances](#hr)
  - [Delivery](#delivery)
  - [Challans](#challans)
  - [Vendors & Purchasing](#vendors--purchasing)
  - [Expenses](#expenses)
  - [Reports & Analytics](#reports--analytics)
  - [Backup](#backup)
  - [Sync](#sync)
  - [Settings](#settings)
  - [Branches](#branches)
  - [Terminals](#terminals)
  - [Roles](#roles)
  - [Localization](#localization)
  - [Notifications](#notifications)
  - [Accounting](#accounting)
  - [Storefront](#storefront)
  - [Channels](#channels)
  - [LAN Discovery](#lan-discovery)
  - [Docs](#docs)
- [Data Types & Financial Precision](#data-types--financial-precision)
- [Sync Engine Deep-Dive](#sync-engine-deep-dive)
- [Security Architecture](#security-architecture)
- [Error Codes Reference](#error-codes-reference)

---

## Framework Overview

The LaundryPro API is built on a **custom PHP 8.2 micro-framework** with zero external Composer runtime dependencies. Every component is hand-crafted for minimal footprint and maximum deployability on shared XAMPP environments.

### Core Components

| Component | Description |
|---|---|
| **DI Container** | Service-locator style dependency injection container; services are registered as singletons or factories and resolved on demand |
| **Router** | Regex-based URL router mapping `METHOD /path` patterns to `Controller::method`; supports path parameters (`:id`) and optional segments |
| **Request** | Wraps `$_SERVER`, `$_GET`, `$_POST`, and `php://input`; provides typed getters for query params, JSON body, path params, and uploaded files |
| **Response** | Fluent builder for JSON responses; sets `Content-Type: application/json` and HTTP status automatically |
| **Middleware Chain** | Ordered pipeline executed before every controller. Default chain: `CorsMiddleware → RateLimitMiddleware → AuthMiddleware` |

### Middleware Details

| Middleware | File | Behaviour |
|---|---|---|
| `CorsMiddleware` | `Middleware.php` | Sets `Access-Control-Allow-*` headers; short-circuits `OPTIONS` preflight requests with `204 No Content` |
| `AuthMiddleware` | `Middleware.php` | Validates `Authorization: Bearer <token>` JWT; injects decoded claims into `Request::$user`; bypassed on public routes (`/health`, `/install/*`, `/auth/login`, `/docs/*`) |
| `RateLimitMiddleware` | `RateLimitMiddleware.php` | IP-keyed counter stored in the `settings` table; applies only to `/auth/*` routes (see [Rate Limiting](#rate-limiting)) |

---

## Standard JSON Envelope

Every response body — success or error — conforms to this envelope:

```json
{
  "success": true,
  "message": "Human-readable status message",
  "data": { },
  "errors": null,
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 142,
    "last_page": 6
  }
}
```

| Field | Type | Always Present | Description |
|---|---|---|---|
| `success` | `boolean` | ✅ | `true` for 2xx responses; `false` for all errors |
| `message` | `string` | ✅ | Short human-readable description |
| `data` | `object \| array \| null` | ✅ | Response payload; `null` on error or empty results |
| `errors` | `object \| null` | ✅ | Field-level validation errors keyed by field name; `null` on success |
| `meta` | `object \| null` | ❌ | Pagination metadata; present only on paginated list endpoints |

### Pagination Query Parameters

All list endpoints accept:

| Parameter | Default | Description |
|---|---|---|
| `page` | `1` | Page number (1-indexed) |
| `per_page` | `25` | Records per page (max 100) |
| `sort` | endpoint-defined | Column to sort by |
| `order` | `desc` | `asc` or `desc` |
| `search` | — | Full-text search string |

---

## Authentication

LaundryPro uses a **JWT access + refresh token pair**.

### Token Lifecycle

```
Client                          API
  │                               │
  │── POST /auth/login ──────────▶│
  │◀── { access_token,            │
  │       refresh_token } ────────│
  │                               │
  │── GET /api/v1/... ───────────▶│  Authorization: Bearer <access_token>
  │◀── 200 OK ────────────────────│
  │                               │
  │  (access_token expires)       │
  │── POST /auth/refresh ────────▶│  { refresh_token: "..." }
  │◀── { access_token,            │
  │       refresh_token } ────────│
  │                               │
  │── POST /auth/logout ─────────▶│  Authorization: Bearer <access_token>
  │◀── 200 OK ────────────────────│
```

### Token Storage (Client)

Access and refresh tokens are persisted in `flutter_secure_storage` (Windows Credential Store) via the `token_storage` service. They are never written to disk in plain text.

### Token Properties

| Property | Access Token | Refresh Token |
|---|---|---|
| TTL | 15 minutes (configurable) | 7 days (configurable) |
| Algorithm | HS256 | HS256 |
| Claims | `sub`, `iat`, `exp`, `role`, `branch_id`, `permissions[]` | `sub`, `iat`, `exp`, `jti` |
| Storage (server) | Stateless (validated by signature) | Persisted in `refresh_tokens` table |
| Revocation | Not possible until expiry | Deleted on logout; `RefreshTokenRepository` |

### Sending the Token

```http
GET /api/v1/sales HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Rate Limiting

Rate limiting is applied **exclusively to `/auth/*` routes** to prevent brute-force attacks.

| Property | Value |
|---|---|
| Scope | Per client IP address |
| Max attempts | 5 |
| Window duration | 60 seconds |
| Storage | `settings` table (key: `rate_limit:{ip}:{window_start}`) |
| Exceeded response | `429 Too Many Requests` with `Retry-After` header |

When the limit is exceeded:

```json
{
  "success": false,
  "message": "Too many login attempts. Please try again later.",
  "data": null,
  "errors": { "retry_after": 47 }
}
```

---

## Endpoint Reference

All routes are prefixed with `/api/v1` unless otherwise noted.

### Legend

| Symbol | Meaning |
|---|---|
| 🔓 | Public — no authentication required |
| 🔒 | Requires valid JWT Bearer token |
| 🛡️ | Requires specific RBAC permission (listed in parentheses) |
| 📄 | Returns paginated list |

---

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/health` | 🔓 | Returns API version, DB connectivity status, and server timestamp |

**Response `data`:**

```json
{
  "status": "ok",
  "version": "1.2.1",
  "database": "connected",
  "timestamp": "2026-09-10T20:05:25+05:30"
}
```

---

### Install

> These endpoints are available only while `install_complete = false` in the settings table. Once installation is finalised, they return `403 Forbidden`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/install/status` | 🔓 | Returns current installation state: pending, migrated, seeded, or complete |
| `POST` | `/api/v1/install/migrate` | 🔓 | Runs all pending database migration scripts in order; idempotent |
| `POST` | `/api/v1/install/seed` | 🔓 | Inserts default roles, permissions, admin user, and system settings |
| `POST` | `/api/v1/install/complete` | 🔓 | Locks the install endpoints and finalises setup |

---

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/auth/login` | 🔓 | Authenticates username + password; returns access and refresh tokens |
| `POST` | `/api/v1/auth/refresh` | 🔓 | Exchanges a valid refresh token for a new token pair |
| `POST` | `/api/v1/auth/logout` | 🔒 | Revokes the current refresh token; invalidates the session |

**Login Request Body:**

```json
{
  "username": "admin",
  "password": "Admin@1234"
}
```

**Login / Refresh Response `data`:**

```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 900,
  "user": {
    "id": 1,
    "username": "admin",
    "role": "Administrator",
    "branch_id": 1,
    "permissions": ["sales.create", "reports.view", "..."]
  }
}
```

---

### Sales

Handled by `SalesController` / `SalesRepository`. All monetary values use `DECIMAL(18,2)`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/sales` | 🔒 🛡️`sales.view` 📄 | List all sales orders with filters: `status`, `date_from`, `date_to`, `customer_id`, `branch_id` |
| `POST` | `/api/v1/sales` | 🔒 🛡️`sales.create` | Create a new sales order |
| `GET` | `/api/v1/sales/:id` | 🔒 🛡️`sales.view` | Retrieve a single order with line items and payment history |
| `PUT` | `/api/v1/sales/:id` | 🔒 🛡️`sales.edit` | Update an order (status, items, discounts) — only allowed in `draft` state |
| `DELETE` | `/api/v1/sales/:id` | 🔒 🛡️`sales.delete` | Void/cancel an order; triggers audit log entry |
| `POST` | `/api/v1/sales/:id/pay` | 🔒 🛡️`sales.pay` | Record a payment against an order (supports partial payments and split tender) |
| `POST` | `/api/v1/sales/:id/refund` | 🔒 🛡️`sales.refund` | Issue a full or partial refund; creates a credit memo |

**Order Statuses:** `draft` → `confirmed` → `in_production` → `ready` → `delivered` → `paid` | `void` | `refunded`

---

### Catalog

Handled by `CatalogController` / `CatalogRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/catalog/services` | 🔒 🛡️`catalog.view` 📄 | List laundry services with category, pricing, and tax rate |
| `POST` | `/api/v1/catalog/services` | 🔒 🛡️`catalog.create` | Create a new service |
| `GET` | `/api/v1/catalog/services/:id` | 🔒 🛡️`catalog.view` | Get a single service |
| `PUT` | `/api/v1/catalog/services/:id` | 🔒 🛡️`catalog.edit` | Update a service |
| `DELETE` | `/api/v1/catalog/services/:id` | 🔒 🛡️`catalog.delete` | Soft-delete a service |
| `GET` | `/api/v1/catalog/products` | 🔒 🛡️`catalog.view` 📄 | List retail products (consumables, accessories) |
| `POST` | `/api/v1/catalog/products` | 🔒 🛡️`catalog.create` | Create a new product |
| `GET` | `/api/v1/catalog/products/:id` | 🔒 🛡️`catalog.view` | Get a single product |
| `PUT` | `/api/v1/catalog/products/:id` | 🔒 🛡️`catalog.edit` | Update a product |
| `DELETE` | `/api/v1/catalog/products/:id` | 🔒 🛡️`catalog.delete` | Soft-delete a product |

---

### Inventory

Handled by `InventoryController` / `InventoryRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/inventory` | 🔒 🛡️`inventory.view` 📄 | List current stock levels per product per branch |
| `POST` | `/api/v1/inventory/receipt` | 🔒 🛡️`inventory.receive` | Record a stock receipt (goods received against purchase order) |
| `POST` | `/api/v1/inventory/transfer` | 🔒 🛡️`inventory.transfer` | Create inter-branch stock transfer |
| `POST` | `/api/v1/inventory/adjustment` | 🔒 🛡️`inventory.adjust` | Record a manual stock adjustment (shrinkage, damage, cycle count) |
| `GET` | `/api/v1/inventory/movements` | 🔒 🛡️`inventory.view` 📄 | Audit trail of all stock movements with reason codes |

---

### Customers

Handled by `CustomerController` / `CustomerRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/customers` | 🔒 🛡️`customers.view` 📄 | List customers with search by name, phone, email |
| `POST` | `/api/v1/customers` | 🔒 🛡️`customers.create` | Create a new customer profile |
| `GET` | `/api/v1/customers/:id` | 🔒 🛡️`customers.view` | Get customer detail with order history summary and loyalty balance |
| `PUT` | `/api/v1/customers/:id` | 🔒 🛡️`customers.edit` | Update customer profile |
| `DELETE` | `/api/v1/customers/:id` | 🔒 🛡️`customers.delete` | Soft-delete customer record |
| `GET` | `/api/v1/customers/:id/orders` | 🔒 🛡️`customers.view` 📄 | Paginated order history for a customer |
| `GET` | `/api/v1/customers/:id/statement` | 🔒 🛡️`customers.view` | Account statement (outstanding balance, payments, credits) |

### Customer Portal

Handled by `CustomerPortalController` / `CustomerPortalRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/portal/orders` | 🔒 (customer token) | Customer-facing order status list |
| `GET` | `/api/v1/portal/orders/:id` | 🔒 (customer token) | Single order status and tracking detail |

---

### HR

Handled by `HrController` backed by `EmployeeRepository`, `AttendanceRepository`, `LeaveRepository`, `PayrollRepository`.

#### Employees

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/hr/employees` | 🔒 🛡️`hr.view` 📄 | List all employees |
| `POST` | `/api/v1/hr/employees` | 🔒 🛡️`hr.create` | Create a new employee record with role and branch assignment |
| `GET` | `/api/v1/hr/employees/:id` | 🔒 🛡️`hr.view` | Get employee profile |
| `PUT` | `/api/v1/hr/employees/:id` | 🔒 🛡️`hr.edit` | Update employee details |
| `DELETE` | `/api/v1/hr/employees/:id` | 🔒 🛡️`hr.delete` | Deactivate employee |

#### Attendance

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/hr/attendance` | 🔒 🛡️`hr.view` 📄 | Attendance records filtered by employee, branch, and date range |
| `POST` | `/api/v1/hr/attendance` | 🔒 🛡️`hr.attendance` | Record a clock-in or clock-out event |
| `PUT` | `/api/v1/hr/attendance/:id` | 🔒 🛡️`hr.attendance` | Amend an attendance record (manager correction) |

#### Leave

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/hr/leave` | 🔒 🛡️`hr.view` 📄 | List leave requests |
| `POST` | `/api/v1/hr/leave` | 🔒 🛡️`hr.leave.request` | Submit a leave request |
| `PUT` | `/api/v1/hr/leave/:id/approve` | 🔒 🛡️`hr.leave.approve` | Approve a pending leave request |
| `PUT` | `/api/v1/hr/leave/:id/reject` | 🔒 🛡️`hr.leave.approve` | Reject a leave request with reason |

#### Payroll

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/hr/payroll` | 🔒 🛡️`hr.payroll` 📄 | List payroll runs |
| `POST` | `/api/v1/hr/payroll/run` | 🔒 🛡️`hr.payroll` | Execute a payroll run for a given period and branch |
| `GET` | `/api/v1/hr/payroll/:id` | 🔒 🛡️`hr.payroll` | Get payroll run details with per-employee breakdown |
| `GET` | `/api/v1/hr/payroll/:id/payslip/:employee_id` | 🔒 🛡️`hr.payroll` | Download individual payslip as PDF |

#### Salary Advances

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/hr/advances` | 🔒 🛡️`hr.advances` 📄 | List salary advance requests |
| `POST` | `/api/v1/hr/advances` | 🔒 🛡️`hr.advances.create` | Submit a salary advance request |
| `PUT` | `/api/v1/hr/advances/:id/approve` | 🔒 🛡️`hr.advances.approve` | Approve an advance disbursement |
| `PUT` | `/api/v1/hr/advances/:id/reject` | 🔒 🛡️`hr.advances.approve` | Reject an advance request |

---

### Delivery

Handled by `DeliveryController` / `DeliveryRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/delivery` | 🔒 🛡️`delivery.view` 📄 | List delivery tasks with status filter: `pending`, `assigned`, `in_transit`, `completed`, `failed` |
| `POST` | `/api/v1/delivery` | 🔒 🛡️`delivery.create` | Create a delivery task linked to an order |
| `GET` | `/api/v1/delivery/:id` | 🔒 🛡️`delivery.view` | Get delivery task detail including address and driver assignment |
| `PUT` | `/api/v1/delivery/:id` | 🔒 🛡️`delivery.edit` | Update delivery task (reassign driver, reschedule) |
| `POST` | `/api/v1/delivery/:id/complete` | 🔒 🛡️`delivery.complete` | Mark delivery as completed; optionally captures signature or photo proof |
| `POST` | `/api/v1/delivery/:id/fail` | 🔒 🛡️`delivery.complete` | Mark delivery as failed with a reason code |

---

### Challans

Handled by `ChallanController` / `ChallanRepository`. Challans are batch garment transfer documents used in multi-branch workflows.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/challans` | 🔒 🛡️`challans.view` 📄 | List all challan documents |
| `POST` | `/api/v1/challans` | 🔒 🛡️`challans.create` | Create a new challan for a batch of order items |
| `GET` | `/api/v1/challans/:id` | 🔒 🛡️`challans.view` | Get challan with item list and branch routing |
| `PUT` | `/api/v1/challans/:id` | 🔒 🛡️`challans.edit` | Update challan items or routing (before dispatch) |
| `POST` | `/api/v1/challans/:id/dispatch` | 🔒 🛡️`challans.dispatch` | Mark challan as dispatched; locks the document |
| `POST` | `/api/v1/challans/:id/receive` | 🔒 🛡️`challans.receive` | Confirm receipt at the destination branch |

---

### Vendors & Purchasing

Handled by `VendorController` / `PurchaseController`.

#### Vendors

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/vendors` | 🔒 🛡️`vendors.view` 📄 | List suppliers |
| `POST` | `/api/v1/vendors` | 🔒 🛡️`vendors.create` | Create a supplier record |
| `GET` | `/api/v1/vendors/:id` | 🔒 🛡️`vendors.view` | Get supplier detail with purchase history |
| `PUT` | `/api/v1/vendors/:id` | 🔒 🛡️`vendors.edit` | Update supplier details |
| `DELETE` | `/api/v1/vendors/:id` | 🔒 🛡️`vendors.delete` | Deactivate supplier |

#### Purchase Orders

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/purchasing` | 🔒 🛡️`purchasing.view` 📄 | List purchase orders |
| `POST` | `/api/v1/purchasing` | 🔒 🛡️`purchasing.create` | Create a purchase order |
| `GET` | `/api/v1/purchasing/:id` | 🔒 🛡️`purchasing.view` | Get purchase order with line items |
| `PUT` | `/api/v1/purchasing/:id` | 🔒 🛡️`purchasing.edit` | Update a purchase order (before receiving) |
| `POST` | `/api/v1/purchasing/:id/receive` | 🔒 🛡️`purchasing.receive` | Record goods receipt; updates inventory |
| `DELETE` | `/api/v1/purchasing/:id` | 🔒 🛡️`purchasing.delete` | Cancel a purchase order |

---

### Expenses

Handled by `ExpenseController` / `ExpenseRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/expenses` | 🔒 🛡️`expenses.view` 📄 | List expenses with filters: `category`, `branch_id`, `date_from`, `date_to` |
| `POST` | `/api/v1/expenses` | 🔒 🛡️`expenses.create` | Log an operational expense |
| `GET` | `/api/v1/expenses/:id` | 🔒 🛡️`expenses.view` | Get expense detail |
| `PUT` | `/api/v1/expenses/:id` | 🔒 🛡️`expenses.edit` | Update an expense entry |
| `DELETE` | `/api/v1/expenses/:id` | 🔒 🛡️`expenses.delete` | Delete an expense entry |

---

### Reports & Analytics

Handled by `ReportsController` / `AnalyticsController` backed by `ReportsRepository` / `AnalyticsRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/reports/sales-summary` | 🔒 🛡️`reports.view` | Aggregated sales revenue, item count, and tax collected for a period |
| `GET` | `/api/v1/reports/aging` | 🔒 🛡️`reports.view` | Accounts receivable aging buckets: 0–30, 31–60, 61–90, 90+ days |
| `GET` | `/api/v1/reports/payment-breakdown` | 🔒 🛡️`reports.view` | Revenue split by payment method (cash, card, wallet, credit) |
| `GET` | `/api/v1/reports/pnl` | 🔒 🛡️`reports.view` | Operational profit & loss: revenue minus expenses by category |
| `GET` | `/api/v1/reports/employees` | 🔒 🛡️`reports.hr` | Attendance and productivity summary per employee |
| `GET` | `/api/v1/analytics/trends` | 🔒 🛡️`reports.analytics` | Time-series revenue and order volume trends (daily / weekly / monthly) |
| `GET` | `/api/v1/analytics/top-services` | 🔒 🛡️`reports.analytics` | Top-N services by revenue and order count |
| `GET` | `/api/v1/analytics/top-customers` | 🔒 🛡️`reports.analytics` | Top-N customers by lifetime value |
| `GET` | `/api/v1/analytics/branch-performance` | 🔒 🛡️`reports.analytics` | Side-by-side branch comparison metrics |

**Common query parameters for all report endpoints:**

| Parameter | Description |
|---|---|
| `date_from` | ISO 8601 date (`YYYY-MM-DD`) |
| `date_to` | ISO 8601 date (`YYYY-MM-DD`) |
| `branch_id` | Filter to a specific branch; omit for all branches |
| `format` | `json` (default) or `csv` |

---

### Backup

Handled by `BackupController` / `BackupService`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/backup/run` | 🔒 🛡️`backup.run` | Initiates a full database + file backup; stores ZIP with SHA-256 manifest at `C:/LaundryPro/backups/` |
| `GET` | `/api/v1/backup/list` | 🔒 🛡️`backup.view` | Lists available backup archives with filename, size, and manifest hash |
| `POST` | `/api/v1/backup/restore` | 🔒 🛡️`backup.restore` | Restores from a named backup file after SHA-256 manifest validation |

**Backup Archive Structure:**

```
laundrypro_backup_20260910_200525.zip
├── manifest.json          # { "sha256": "...", "created_at": "...", "tables": [...] }
├── database.sql           # Full MariaDB dump
└── files/
    ├── invoices/
    └── uploads/
```

---

### Sync

Handled by `SyncController` / `SyncService` / `SyncOutboxRepository`. See also [Sync Engine Deep-Dive](#sync-engine-deep-dive).

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/sync/status` | 🔒 🛡️`sync.view` | Returns outbox queue depth, last successful sync timestamp, and per-terminal status |
| `POST` | `/api/v1/sync/push` | 🔒 🛡️`sync.push` | Accepts a batch of outbox records from a client terminal; applies changes server-side |
| `GET` | `/api/v1/sync/pull` | 🔒 🛡️`sync.pull` | Returns all server-side changes since a client's last `sync_cursor` |

---

### Settings

Handled by `SettingsController` / `SettingsRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/settings` | 🔒 🛡️`settings.view` | Retrieve all application settings as a key-value map |
| `PUT` | `/api/v1/settings` | 🔒 🛡️`settings.edit` | Update one or more settings keys in a single request |

---

### Branches

Handled by `BranchController` / `BranchRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/branches` | 🔒 🛡️`branches.view` 📄 | List all branches |
| `POST` | `/api/v1/branches` | 🔒 🛡️`branches.create` | Create a new branch |
| `GET` | `/api/v1/branches/:id` | 🔒 🛡️`branches.view` | Get branch detail and configuration |
| `PUT` | `/api/v1/branches/:id` | 🔒 🛡️`branches.edit` | Update branch settings |
| `DELETE` | `/api/v1/branches/:id` | 🔒 🛡️`branches.delete` | Deactivate a branch |

---

### Terminals

Handled by `TerminalController` / `TerminalRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/terminals` | 🔒 🛡️`terminals.view` 📄 | List registered POS terminals |
| `POST` | `/api/v1/terminals` | 🔒 🛡️`terminals.create` | Register a new terminal; returns a terminal token |
| `GET` | `/api/v1/terminals/:id` | 🔒 🛡️`terminals.view` | Get terminal detail and last-seen timestamp |
| `PUT` | `/api/v1/terminals/:id` | 🔒 🛡️`terminals.edit` | Update terminal configuration |
| `DELETE` | `/api/v1/terminals/:id` | 🔒 🛡️`terminals.delete` | Deregister a terminal |

---

### Roles

Handled by `RoleController` / `RoleRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/roles` | 🔒 🛡️`roles.view` | List all roles with their assigned permission sets |
| `POST` | `/api/v1/roles` | 🔒 🛡️`roles.create` | Create a new role |
| `PUT` | `/api/v1/roles/:id` | 🔒 🛡️`roles.edit` | Update a role's name or permissions |
| `DELETE` | `/api/v1/roles/:id` | 🔒 🛡️`roles.delete` | Delete a role (not permitted if users are assigned) |
| `GET` | `/api/v1/roles/permissions` | 🔒 🛡️`roles.view` | Retrieve the full list of available system permissions |

---

### Localization

Handled by `LocalizationController` / `LocalizationRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/localization` | 🔒 | Retrieve current locale settings (language, date format, currency) |
| `PUT` | `/api/v1/localization` | 🔒 🛡️`settings.edit` | Update locale settings |
| `GET` | `/api/v1/localization/strings/:lang` | 🔓 | Download the full translation string map for `en` or `ar` |

> Language files are also bundled in the Flutter app at `assets/lang/en.json` and `assets/lang/ar.json` for offline use.

---

### Notifications

Handled by `NotificationController` / `NotificationRepository` / `MessagingService`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/notifications` | 🔒 📄 | List notifications for the authenticated user |
| `POST` | `/api/v1/notifications/send` | 🔒 🛡️`notifications.send` | Send an in-app or SMS notification to a user or customer |
| `PUT` | `/api/v1/notifications/:id/read` | 🔒 | Mark a notification as read |
| `PUT` | `/api/v1/notifications/read-all` | 🔒 | Mark all notifications for the current user as read |

SMS delivery is handled by `MessagingService` via the `SmsAdapterInterface`, with `TwilioSmsAdapter` as the concrete implementation.

---

### Accounting

Handled by `AccountingController` / `AccountingRepository` / `AccountingExportService`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/accounting/ledger` | 🔒 🛡️`accounting.view` 📄 | General ledger entries for a date range |
| `GET` | `/api/v1/accounting/export` | 🔒 🛡️`accounting.export` | Export ledger as CSV or Excel-compatible format |

---

### Storefront

Handled by `StorefrontController` / `StorefrontRepository`.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/storefront/config` | 🔒 🛡️`storefront.view` | Retrieve customer-facing portal configuration |
| `PUT` | `/api/v1/storefront/config` | 🔒 🛡️`storefront.edit` | Update portal branding, enabled features, and contact info |
| `GET` | `/api/v1/storefront/catalog` | 🔓 | Public-facing service and product list for self-service ordering |

---

### Channels

Handled by `ChannelController` / `ChannelRepository`. Channels define sales origination sources (e.g., walk-in, WhatsApp, storefront).

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/channels` | 🔒 🛡️`settings.view` | List configured sales channels |
| `POST` | `/api/v1/channels` | 🔒 🛡️`settings.edit` | Create a sales channel |
| `PUT` | `/api/v1/channels/:id` | 🔒 🛡️`settings.edit` | Update a sales channel |
| `DELETE` | `/api/v1/channels/:id` | 🔒 🛡️`settings.edit` | Delete a sales channel |

---

### LAN Discovery

Handled by `LanController`. Enables terminals on the same local network to auto-discover the server without manual IP configuration.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/lan/beacon` | 🔓 | Returns server identity (name, version, branch_id) for LAN discovery broadcast |

---

### Docs

Handled by `DocsController`. Exposes the machine-readable OpenAPI specification.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/docs/` | 🔓 | Swagger UI — interactive API explorer |
| `GET` | `/api/v1/docs/openapi.json` | 🔓 | Raw OpenAPI 3.0 JSON specification |

---

## Data Types & Financial Precision

### Database Types

| Concept | MariaDB Type | Notes |
|---|---|---|
| Monetary amounts | `DECIMAL(18,2)` | 18 significant digits, 2 decimal places |
| IDs | `INT UNSIGNED` or `BIGINT UNSIGNED` | Auto-increment primary keys |
| UUIDs | `CHAR(36)` | Used for sync outbox record identity |
| Timestamps | `DATETIME` | UTC stored; converted to local on output |
| Boolean flags | `TINYINT(1)` | `0` = false, `1` = true |
| Text fields | `VARCHAR(255)` or `TEXT` | `utf8mb4` collation throughout |

### Financial Precision in PHP

All monetary arithmetic in `SalesRepository` (and any financial path) uses PHP's **`bcmath`** extension with `scale=2`:

```php
// Addition
$total = bcadd($subtotal, $tax, 2);

// Multiplication (qty × unit price)
$lineTotal = bcmul((string)$quantity, $unitPrice, 2);

// Subtraction (discount)
$payable = bcsub($total, $discountAmount, 2);
```

**Never use floating-point arithmetic** (`+`, `-`, `*`, `/`) for monetary values — IEEE 754 rounding errors will accumulate across multi-line orders.

### JSON Representation

Monetary values are serialised as **strings** in API responses to preserve precision across all client environments:

```json
{
  "subtotal": "125.50",
  "tax_amount": "6.28",
  "discount": "12.55",
  "total": "119.23",
  "amount_paid": "100.00",
  "balance_due": "19.23"
}
```

Clients **must** treat these as strings and use appropriate fixed-point libraries (Dart: `Decimal` package or manual string parsing; JavaScript: `big.js` or similar).

---

## Sync Engine Deep-Dive

LaundryPro supports offline-first operation at each terminal. Changes are queued locally and synchronised to the central server when connectivity is restored.

### Outbox Schema (`sync_outbox` table)

```sql
CREATE TABLE sync_outbox (
    id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    uuid          CHAR(36)         NOT NULL UNIQUE,          -- client-generated UUID
    terminal_id   INT UNSIGNED     NOT NULL,
    entity_type   VARCHAR(64)      NOT NULL,                 -- e.g. 'sale', 'customer'
    entity_id     VARCHAR(64)      NOT NULL,                 -- local entity PK or UUID
    operation     ENUM('create','update','delete') NOT NULL,
    payload       JSON             NOT NULL,                 -- full entity snapshot
    status        ENUM('pending','synced','failed') NOT NULL DEFAULT 'pending',
    attempts      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    last_error    TEXT,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    synced_at     DATETIME,
    PRIMARY KEY (id),
    INDEX idx_status_attempts (status, attempts),
    INDEX idx_terminal (terminal_id)
);
```

### Exponential Backoff Algorithm

The `SyncService` retries failed outbox records with exponential backoff:

```
delay(attempt) = min(2^attempt × base_delay_seconds, max_delay_seconds)
```

| Attempt | Delay |
|---|---|
| 1 | 2 s |
| 2 | 4 s |
| 3 | 8 s |
| 4 | 16 s |
| 5 | 32 s |
| 6 | 64 s |
| 7 | 128 s (~2 min) |
| 8 | 256 s (~4 min) |
| 9 | 512 s (~9 min) |
| 10 | **MAX — record marked `failed`** |

After **10 attempts**, the record status is set to `failed` and human intervention is required. Failed records are surfaced in the **Sync Settings** screen and via the `GET /api/v1/sync/status` endpoint.

### Push / Pull Protocol

```
Terminal (client)                     Server
     │                                   │
     │── POST /sync/push ───────────────▶│
     │   { cursor: "last_sync_ts",       │
     │     records: [ outbox_record ] }  │
     │                                   │── Apply records (idempotent by UUID)
     │                                   │── Update sync_cursor for terminal
     │◀── { accepted: 12, rejected: 0 } ─│
     │                                   │
     │── GET /sync/pull?cursor=... ─────▶│
     │◀── { changes: [...],              │
     │      new_cursor: "..." } ─────────│
```

### Conflict Resolution Strategy

| Scenario | Strategy |
|---|---|
| Same record updated on two terminals before sync | **Last-write-wins** based on `updated_at` timestamp; server timestamp is authoritative |
| Record deleted on server, updated on client | Server delete wins; client receives `delete` change on next pull |
| Duplicate UUID push | Idempotent — second push of the same UUID is acknowledged but not re-applied |
| Schema mismatch | Push rejected with `409 Conflict`; client should pull latest schema and retry |

---

## Security Architecture

### JWT Implementation

```
Header:  { "alg": "HS256", "typ": "JWT" }
Payload: {
  "sub":         1,              -- user ID
  "iat":         1725984325,     -- issued at (Unix)
  "exp":         1725985225,     -- expiry (Unix)
  "role":        "Manager",
  "branch_id":   2,
  "permissions": ["sales.view", "sales.create", "reports.view"]
}
Signature: HMAC-SHA256(base64(header) + "." + base64(payload), JWT_SECRET)
```

- **JWT_SECRET** must be at least 32 characters of random entropy; store in `.env` only
- Access tokens are **stateless** — they cannot be individually revoked before expiry; keep TTL short (15 minutes)
- Refresh tokens are **stateful** — stored in the `refresh_tokens` table via `RefreshTokenRepository`; deleted on logout

### RBAC Permission System

Permissions follow the convention `<resource>.<action>`:

```
sales.view        sales.create     sales.edit       sales.delete
sales.pay         sales.refund     catalog.view     catalog.create
catalog.edit      catalog.delete   inventory.view   inventory.receive
inventory.adjust  customers.view   customers.create hr.view
hr.create         hr.payroll       reports.view     reports.analytics
backup.run        backup.restore   settings.edit    branches.create
roles.edit        sync.push        sync.pull        ...
```

The `AuthMiddleware` extracts the `permissions` array from the JWT and checks it against the required permission for each route. A `403 Forbidden` response is returned if the permission is absent.

### SQL Injection Prevention

All database interaction goes through the `Repository` layer using **prepared statements exclusively**:

```php
$stmt = $this->db->prepare(
    "SELECT * FROM sales WHERE branch_id = ? AND status = ? AND created_at >= ?"
);
$stmt->bind_param('iss', $branchId, $status, $dateFrom);
$stmt->execute();
```

No user-supplied input is ever interpolated directly into SQL strings.

### Rate Limiting Implementation

The `RateLimitMiddleware` uses the `settings` table as a lightweight counter store:

```php
$key   = 'rate_limit:' . $clientIp . ':' . floor(time() / $windowSeconds);
$count = (int)$settings->get($key, 0);

if ($count >= $maxAttempts) {
    // Return 429
}

$settings->increment($key, ttl: $windowSeconds);
```

Each window key expires automatically after the window duration via a `DELETE WHERE created_at <` sweep on the next request.

### Backup Integrity

Every backup archive embeds a `manifest.json` containing the SHA-256 hash of the database dump file. On restore, `BackupService` recomputes the hash and aborts if there is a mismatch:

```php
$actualHash   = hash_file('sha256', $extractedDumpPath);
$expectedHash = $manifest['sha256'];

if (!hash_equals($expectedHash, $actualHash)) {
    throw new BackupCorruptException("Manifest hash mismatch — backup may be corrupted.");
}
```

---

## Error Codes Reference

All error responses include `"success": false`. The HTTP status code is the primary error signal; the `errors` object provides structured field-level detail where applicable.

| HTTP Status | Code Constant | When Used |
|---|---|---|
| `400 Bad Request` | `VALIDATION_ERROR` | Request body fails validation; `errors` contains field messages |
| `401 Unauthorized` | `UNAUTHENTICATED` | Missing, malformed, or expired JWT |
| `403 Forbidden` | `FORBIDDEN` | Valid JWT but insufficient RBAC permission |
| `404 Not Found` | `NOT_FOUND` | Requested resource does not exist |
| `409 Conflict` | `CONFLICT` | Duplicate creation attempt or sync schema mismatch |
| `422 Unprocessable Entity` | `BUSINESS_RULE` | Request is valid but violates a business rule (e.g., refund > original amount) |
| `429 Too Many Requests` | `RATE_LIMITED` | IP rate limit exceeded on auth routes |
| `500 Internal Server Error` | `INTERNAL_ERROR` | Unexpected server-side error; details logged to `C:/LaundryPro/logs/` |
| `503 Service Unavailable` | `DB_UNAVAILABLE` | MariaDB connection failed |

### Error Response Example

```json
{
  "success": false,
  "message": "Validation failed",
  "data": null,
  "errors": {
    "customer_id": ["The customer_id field is required."],
    "items":       ["At least one line item is required."],
    "items.0.unit_price": ["unit_price must be a positive decimal value."]
  }
}
```

---

*LaundryPro UAE API Reference — version 1.2.1 · PHP 8.2 · MariaDB · XAMPP*
