# LaundryPro UAE — Component Map

> **Version:** 2.0.0 | **Authoritative System Index** | **Last Updated:** 2026-09-30

---

## 1. Top-Level Directory Overview

```
UAE-Laundry-Pro/
├── api/                    # Local Workstation REST API (PHP 8.2, MariaDB/SQLite)
│   ├── config/             # App, Database, Security & Rate Limit Configurations
│   ├── database/           # Local Database Migrations & Seeds
│   ├── docs/               # Local OpenAPI 3.0 JSON specifications & Swagger UI
│   ├── logs/               # Monolog / Local Request & Error Audit Logs
│   ├── public/             # Apache DocumentRoot, index.php front controller, assets
│   ├── routes/             # api.php authoritative route definitions (178 routes)
│   ├── scripts/            # Background schedulers, sync workers, database seeders
│   ├── src/                # Controllers, Repositories, Services, Middleware, Core
│   └── storage/            # Backups, rate limit counters, installed.lock lockfile
├── cloud-api/              # Central Cloud Multi-Tenant REST API & Super-Admin Portal
│   ├── config/             # Cloud Database & Environment settings
│   ├── database/           # Cloud MariaDB migrations (001_cloud_initial_schema.sql)
│   ├── logs/               # Cloud access & error logs
│   ├── public/             # Cloud DocumentRoot, AdminLTE portal assets, index.php
│   ├── src/                # Cloud Controllers, Core Framework, Views (AdminLTE v4)
│   └── storage/            # Tenant backup storage, session locks
├── lib/                    # Standalone Flutter Desktop / Mobile Client App
│   ├── core/               # App constants, themes, network config, router
│   ├── models/             # Domain entity data classes with JSON serialization
│   ├── providers/          # Riverpod state notifiers (Auth, Cart, Locale, Sync)
│   ├── services/           # 38 Typed HTTP API clients & SQLite offline cache
│   ├── views/              # 42 Desktop & POS screens (Bilingual EN/AR)
│   └── widgets/            # Reusable enterprise UI components (Purple Dark theme)
├── database/               # Master SQL Schemas
│   ├── local/              # Clean de-duplicated Local Workstation schema (schema.sql)
│   └── cloud/              # Multi-tenant Cloud Gateway schema (schema.sql)
├── docs/                   # Authoritative Technical & Operational Documentation
│   ├── architecture/       # System Architecture, Component Map, Topology
│   ├── api/                # Local & Cloud API References, Response Codes
│   ├── sync/               # Outbox/Inbox Delta Sync Engine, Conflict Resolution
│   ├── licensing/          # 3-Way Hardware Handshake (UMAC / Registry / Cloud)
│   ├── security/           # Threat Model, RBAC, JWT Lifecycle, Hardening
│   ├── compliance/         # UAE VAT 5%, FTA E-Invoicing, Bilingual Receipts
│   ├── flows/              # Order Processing Lifecycle, Split Payment Reconciliation
│   ├── testing/            # Unit, Integration, UAT & Contract Test Plans
│   ├── operations/         # Production Deployment & Backup/Disaster Recovery
│   ├── peripherals/        # Thermal 80mm ESC/POS Printers, Cash Drawers, Scanners
│   ├── ui/                 # "Purple Dark" Theme Tokens, AdminLTE v4 Palette
│   ├── training/           # Administrator & POS Cashier Operational Manuals
│   ├── multitenancy/       # Tenant Isolation & Data Boundary Enforcements
│   ├── blueprints/         # Franchise Enterprise Topology & Central Plant Routing
│   ├── requirements/       # Product Requirements Document (PRD) & Non-Functionals
│   ├── user-journeys/      # Retail, Hotel Linen, Delivery & Corporate Customer Paths
│   ├── workflows/          # Garment Sorting, Chemical Dosing, Dispatch Challans
│   ├── edge-cases/         # Network Partitions, Crash Recovery, Offline Lockouts
│   ├── integrations/       # Accounting Exports (Tally/Zoho), WhatsApp/SMS Gateways
│   ├── data/               # Full Schema Data Dictionary & Column Cross-Reference
│   ├── forms/              # UI Form Field Specifications & Validation Rules
│   ├── reference/          # Enterprise Laundry & Textile Care Technical Glossary
│   ├── appendices/         # Architectural Decision Records (ADRs) & Master Index
│   ├── dependencies/       # Matrix of PHP Extensions, Flutter Packages, Drivers
│   ├── marketing/          # Edition Matrix (Standard vs Premium vs Enterprise)
│   └── swagger/            # OpenAPI 3.0.3 YAML Specs (Local, Cloud, Unified)
└── scripts/                # Node deployment, setup, and orchestration scripts
```

---

## 2. Local API Layer (`api/src/`)

### 2.1 Controllers (`api/src/Controllers/`)
| Controller | Domain Responsibility | Endpoint Count |
|---|---|:---:|
| `HealthController` | Health check, MariaDB ping, disk usage | 1 |
| `DocsController` | Live Swagger UI and OpenAPI 3.0.3 JSON schema delivery | 2 |
| `AuthController` | JWT token issuance, session refresh, logout, `/auth/me` | 4 |
| `SettingsController` | Store-level config, tax rates, printer settings | 2 |
| `InstallController` | First-time setup wizard, database verification, admin init | 4 |
| `CustomerController` | CRM, customer balance ledger, loyalty points | 4 |
| `VendorController` | Supplier catalog, contact information, purchase ledger | 4 |
| `CatalogController` | Services, items, categories, pricing, modifiers | 15 |
| `SalesController` | POS order draft, item modification, confirmation, cancellation | 9 |
| `InvoiceController` | UAE VAT tax invoices, thermal receipt re-prints, refunds | 4 |
| `PaymentController` | Cash, Card, Split tenders, advance deposits | 3 |
| `DeliveryController` | Van driver assignment, pickup/delivery route management | 5 |
| `ChallanController` | Factory dispatch manifests, garment handover tracking | 4 |
| `InventoryController` | Stock level tracking, manual adjustments, reorder alerts | 6 |
| `PurchaseController` | Vendor Purchase Orders (PO), Goods Receipt Notes (GRN) | 4 |
| `ExpenseController` | Daily petty cash expenses, receipt image attachments | 7 |
| `HrController` | Employee directory, biometric attendance, shift logs | 6 |
| `PayrollController` | Monthly payroll calculation, WPS file generation, advances | 5 |
| `LeaveController` | Vacation, sick, emergency leave requests & approvals | 4 |
| `NotificationController`| SMS/WhatsApp message outbox, delivery status checks | 6 |
| `ReportsController` | Sales summary, item profitability, cashier shift Z-report | 17 |
| `AnalyticsController` | Daily dashboard KPIs, revenue trends, customer retention | 3 |
| `LicenseController` | Local license validation, 3-way handshake activation | 2 |
| `SyncController` | Local outbox push, inbox pull application, status health | 5 |
| `BackupController` | Automated MariaDB mysqldump, restore verification | 4 |
| `TerminalController` | Registered POS workstations, cash drawer hardware IDs | 2 |
| `EquipmentController` | Commercial washers, dryers, ironers, maintenance logs | 4 |
| `OperatorController` | Machine operator certifications and authorizations | 2 |
| `RfidController` | Garment UHF RFID chip scanning and batch tracking | 1 |
| `AdvancedCycleController`| Sterilization, cleanroom disinfection, chemical cycles | 4 |
| `StorefrontController` | QR code order tracking for end-consumer status lookup | 5 |
| `CustomerPortalController`| Customer account statements, invoice download links | 2 |
| `LanController` | Local network terminal peer discovery and heartbeat | 2 |
| `AccountingController` | General ledger batches, VAT return exports (FTA 201) | 3 |
| `LocalizationController` | Bilingual Arabic/English string dictionaries | 2 |

### 2.2 Middleware Pipeline (`api/src/Middleware/`)
1. **`CORS Middleware`**: Evaluates origin, headers (`Authorization`, `X-Install-Token`), exposes rate limit headers.
2. **`RateLimitMiddleware`**: Sliding window memory/file-backed rate limiter (default 120 req/min).
3. **`AuthMiddleware`**: Cryptographic validation of RS256/HS256 Bearer JWT tokens.
4. **`PermissionMiddleware`**: Evaluates RBAC role privileges against endpoint action.
5. **`IdempotencyMiddleware`**: Enforces `X-Idempotency-Key` on payment and order creation mutations.
6. **`AuditLogMiddleware`**: Persists mutation requests to `audit_logs` table with user and IP context.

---

## 3. Cloud API Layer (`cloud-api/src/`)

### 3.1 Architecture Overview
- **Multi-Tenant Gateway**: All requests are scoped by `tenant_id` derived from verified tenant credentials.
- **Sync Receiver**: Ingestion pipeline (`/api/v1/sync/push`) accepting JSON delta batches with sequence idempotency.
- **Super-Admin Control Plane**: Web management portal (`/admin`) for license generation, tenant quotas, and health analytics.

### 3.2 Core Components
- `CloudApiController`: 7 high-performance endpoints for health, tenant registration, sync push/pull, backups, reports.
- `AdminPortalController`: Full MVC web portal controller managing Super-Admin sessions, tenant rosters, license keys, and sync failures.
- `Database`: PDO connection manager with connection pooling and SSL encryption support.
- `Router`: Fast regex route dispatcher supporting RESTful parameters and HTTP verb matching.

---

## 4. Flutter Client Layer (`lib/`)

### 4.1 State Management Architecture
- **Riverpod 2.x**: State notification with immutable state models.
- **`AuthNotifier`**: Handles login tokens, active branch session, user permissions.
- **`CartNotifier`**: In-memory high-speed POS cart with real-time VAT calculations, modifiers, and express turnaround surcharge logic.
- **`SyncNotifier`**: Background synchronization status monitor displaying connectivity and pending queue counts.

### 4.2 Local Persistence (`SQLite FFI`)
- **Offline First**: All transactional records are written locally to SQLite first.
- **Outbox Queue**: Local mutations trigger `sync_queue` inserts for async sync daemon transmission.
- **Cache Invalidation**: Automatic TTL and delta-based invalidation upon incoming Cloud sync pulls.
