# LaundryPro UAE — Local API Reference

> **Version:** 2.0.0 | **Authoritative Specification** | **Base URL:** `http://127.0.0.1:8080/api/v1`

---

## 1. Authentication & Security Headers

All protected endpoints require the HTTP `Authorization` header containing a valid Bearer JWT:
```http
Authorization: Bearer <jwt_access_token>
```

For first-time installation and provisioning endpoints:
```http
X-Install-Token: <install_setup_token>
```

For mutation requests requiring idempotency (Order Creation, Invoice Settlement, Payments):
```http
X-Idempotency-Key: <unique_client_uuid>
```

---

## 2. Standard Response Envelope

Every endpoint returns a standardized JSON envelope:

```json
{
  "success": true,
  "code": "OK",
  "message_key": "sales.order_created",
  "data": { ... },
  "errors": [],
  "meta": {
    "request_id": "a9f3b20c-4e81-4231-b519-74351b6ce952",
    "server_time": "2026-09-30T10:15:30Z",
    "version": "2.0.0",
    "page": 1,
    "per_page": 50,
    "total": 128
  }
}
```

---

## 3. Core Endpoint Catalog

### 3.1 Platform & Infrastructure
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `GET` | `/health` | None | Returns database connectivity, disk space, and daemon status |
| `GET` | `/docs/openapi.json` | None | Live-generated OpenAPI 3.0.3 specification JSON |
| `GET` | `/docs` | None | Embedded Swagger UI interactive documentation page |

### 3.2 Authentication & Identity (`/auth`)
| Method | Path | Auth | Request Body | Description |
|---|---|:---:|---|---|
| `POST` | `/auth/login` | None | `{username, password}` | Issues JWT access token (15m) & refresh token (30d) |
| `POST` | `/auth/refresh` | None | `{refresh_token}` | Rotates refresh token and issues fresh access token |
| `POST` | `/auth/logout` | JWT | None | Revokes refresh token and terminates session |
| `GET` | `/auth/me` | JWT | None | Returns active user profile, assigned branch, and RBAC permissions |

### 3.3 Sales & POS Intake (`/sales`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `POST` | `/sales/draft` | JWT | Creates a new order draft; calculates itemized VAT and totals |
| `POST` | `/sales/orders` | JWT | Confirms order draft into booked order; prints thermal garment tags |
| `GET` | `/sales/orders` | JWT | Paginated order list (supports `?status=`, `?customer_id=`, `?from=`, `?to=`) |
| `GET` | `/sales/orders/{id}` | JWT | Complete order detail including line items, tags, and payment history |
| `PATCH`| `/sales/orders/{id}/status` | JWT | Updates order workflow stage (`processing`, `ready`, `delivered`) |
| `POST` | `/sales/orders/{id}/cancel` | JWT | Cancels unfulfilled order; restores stock; issues credit note if paid |

### 3.4 Invoicing & UAE VAT Compliance (`/invoices`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `POST` | `/invoices/generate` | JWT | Creates official FTA-compliant tax invoice with QR code and TRN |
| `GET` | `/invoices/{id}` | JWT | Retrieves tax invoice details and line item breakdown |
| `GET` | `/invoices/{id}/pdf` | JWT | Downloads standard A4 or 80mm thermal bilingual PDF invoice |
| `POST` | `/invoices/{id}/refund` | JWT | Processes full or partial refund; generates FTA credit note |

### 3.5 Catalog Management (`/catalog`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `GET` | `/catalog/categories` | JWT | List laundry service categories (Dry Clean, Wash & Fold, Pressing) |
| `POST` | `/catalog/categories` | JWT | Create new service category |
| `GET` | `/catalog/services` | JWT | List all services with base price and turn-around hours |
| `POST` | `/catalog/services` | JWT | Create or update service item and garment type |
| `GET` | `/catalog/modifiers` | JWT | Starch level, hanger type, scent, stain treatment options |

### 3.6 Customers & CRM (`/customers`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `GET` | `/customers` | JWT | Search customers by phone number, name, or customer code |
| `POST` | `/customers` | JWT | Register new customer with address, TRN, and credit limit |
| `GET` | `/customers/{id}` | JWT | Customer ledger, pending garments, outstanding balance |
| `PUT` | `/customers/{id}` | JWT | Update customer profile and delivery preferences |

### 3.7 Inventory & Purchasing (`/inventory`, `/purchases`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `GET` | `/inventory/stock` | JWT | Stock on hand for consumables (detergents, poly rolls, hangers) |
| `POST` | `/inventory/adjust` | JWT | Record manual stock intake, wastage, or physical audit adjustment |
| `POST` | `/purchases/orders` | JWT | Create vendor Purchase Order (PO) |
| `POST` | `/purchases/grn` | JWT | Receive Goods Receipt Note (GRN); updates inventory and ledger |

### 3.8 Logistics & Factory Challans (`/delivery`, `/challans`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `POST` | `/challans/dispatch` | JWT | Dispatches garment batch to central cleaning plant with manifest |
| `POST` | `/challans/receive` | JWT | Re-intakes clean garments returned from factory; checks missing items |
| `GET` | `/delivery/tasks` | JWT | Van driver pickup and delivery schedule for the day |
| `PATCH`| `/delivery/tasks/{id}` | JWT | Driver updates task: `collected`, `attempted`, `delivered` |

### 3.9 Human Resources & Payroll (`/hr`, `/payroll`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `GET` | `/hr/employees` | JWT | List branch staff, job titles, and labor contract details |
| `POST` | `/hr/attendance` | JWT | Clock-in / clock-out logging with terminal hardware ID |
| `POST` | `/payroll/run` | JWT | Generates monthly salary breakdown with allowances and deductions |
| `GET` | `/payroll/wps` | JWT | Exports UAE Wages Protection System (WPS) SIF file |

### 3.10 Sync Engine Operations (`/sync`)
| Method | Path | Auth | Description |
|---|---|:---:|---|
| `GET` | `/sync/outbox/pending`| JWT | Lists pending local mutations awaiting cloud push |
| `PATCH`| `/sync/outbox/ack` | JWT | Marks records as successfully pushed with cloud sequence IDs |
| `POST` | `/sync/inbox/apply` | JWT | Executes 3-way merge on incoming changes pulled from cloud |
| `GET` | `/sync/health` | JWT | Returns outbox lag, failure counts, and last sync timestamp |
| `POST` | `/sync/trigger` | JWT | Forces an immediate push/pull sync cycle |
