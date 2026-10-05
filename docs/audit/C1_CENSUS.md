# C1 — Full Census & File Inventory

> **Chunk:** C1 | **Date:** 2026-10-05 | **Resume Token:** `RT-C1-20261005-CENSUS-COMPLETE`
> **Depends On:** C0 (PROJECT_LEDGER.md)

---

## 1. Flutter Desktop Client (`lib/`)

### 1.1 Entry Points (2 files)
| File | Size | Purpose |
|:-----|:-----|:--------|
| `main.dart` | 2.3 KB | App bootstrap, provider scope init |
| `app.dart` | 1.7 KB | MaterialApp config, theme, router injection |

### 1.2 Views Layer (42 files, ~615 KB total)
| # | File | Size | Domain |
|:--|:-----|:-----|:-------|
| 1 | `pos_screen.dart` | 29.4 KB | Point of Sale |
| 2 | `pending_invoices_screen.dart` | 15.5 KB | Invoice settlement |
| 3 | `production_screen.dart` | 15.7 KB | Garment workflow |
| 4 | `dashboard_screen.dart` | 15.6 KB | KPI dashboard |
| 5 | `setup_wizard_screen.dart` | 17.8 KB | Onboarding |
| 6 | `global_config_screen.dart` | 16.2 KB | System config |
| 7 | `expenses_screen.dart` | 12.4 KB | Expense management |
| 8 | `peripherals_screen.dart` | 11.5 KB | Hardware config |
| 9 | `license_screen.dart` | 9.3 KB | License mgmt |
| 10 | `splash_screen.dart` | 8.2 KB | Boot sequence |
| 11 | `login_screen.dart` | 8.4 KB | Authentication |
| 12 | `app_shell.dart` | 13.6 KB | Navigation shell |
| 13 | `catalog_screen.dart` | 7.1 KB | Product catalog |
| 14 | `purchasing_screen.dart` | 31.4 KB | Procurement + GRN |
| 15 | `reports_screen.dart` | 12.1 KB | Reporting |
| 16 | `role_editor_screen.dart` | 13.0 KB | RBAC editor |
| 17 | `delivery_screen.dart` | 10.9 KB | Delivery dispatch |
| 18 | `employees_screen.dart` | 32.0 KB | HR management |
| 19 | `attendance_screen.dart` | 22.0 KB | Attendance tracking |
| 20 | `leave_screen.dart` | 21.8 KB | Leave management |
| 21 | `payroll_screen.dart` | 21.9 KB | Payroll + WPS/SIF |
| 22 | `salary_advances_screen.dart` | 17.7 KB | Salary advances |
| 23 | `advanced_cycle_screen.dart` | 33.1 KB | Machine cycles |
| 24 | `sterilization_screen.dart` | 26.4 KB | Sterilization |
| 25 | `equipment_screen.dart` | 30.9 KB | Equipment mgmt |
| 26 | `operator_screen.dart` | 25.0 KB | Operator certs |
| 27 | `rfid_tracking_screen.dart` | 13.4 KB | RFID garment tracking |
| 28 | `branches_screen.dart` | 14.7 KB | Multi-branch |
| 29 | `terminals_screen.dart` | 13.6 KB | Terminal pairing |
| 30 | `analytics_screen.dart` | 18.5 KB | Analytics dashboard |
| 31 | `channels_screen.dart` | 10.7 KB | Notification channels |
| 32 | `accounting_screen.dart` | 21.7 KB | Accounting export |
| 33 | `localization_screen.dart` | 12.0 KB | GCC profiles |
| 34 | `storefront_screen.dart` | 12.4 KB | Online orders |
| 35 | `customer_portal_screen.dart` | 19.5 KB | Customer tracking |
| 36 | `sync_settings_screen.dart` | 22.2 KB | Sync config |
| 37 | `settings_screen.dart` | 16.2 KB | App settings |
| 38 | `challans_screen.dart` | 10.6 KB | Challans/manifests |
| 39 | `notifications_screen.dart` | 10.0 KB | Alert center |
| 40 | `business_screen.dart` | 13.6 KB | Business profile |
| 41 | `customers_screen.dart` | 10.6 KB | CRM |
| 42 | `vendors_screen.dart` | 13.7 KB | Vendor mgmt |

### 1.3 Services Layer (38 files, ~82 KB total)
| File | Size | Domain |
|:-----|:-----|:-------|
| `accounting_service.dart` | 2.7 KB | Accounting export |
| `advanced_cycle_service.dart` | 1.0 KB | Machine cycles |
| `analytics_service.dart` | 1.2 KB | Analytics |
| `api_client.dart` | 7.3 KB | HTTP client (core) |
| `attendance_service.dart` | 1.0 KB | Attendance |
| `auth_service.dart` | 2.1 KB | Authentication |
| `backup_service.dart` | 1.4 KB | Backup/Restore |
| `branch_service.dart` | 1.0 KB | Branch mgmt |
| `business_service.dart` | 0.6 KB | Business profile |
| `catalog_service.dart` | 3.4 KB | Product catalog |
| `challan_service.dart` | 1.0 KB | Challans |
| `channel_service.dart` | 0.8 KB | Notification channels |
| `customer_portal_service.dart` | 0.7 KB | Customer portal |
| `customer_service.dart` | 1.1 KB | CRM |
| `delivery_service.dart` | 1.0 KB | Delivery |
| `employee_service.dart` | 1.3 KB | HR |
| `equipment_service.dart` | 0.9 KB | Equipment |
| `expense_service.dart` | 1.8 KB | Expenses |
| `global_config_service.dart` | 7.1 KB | Config mgmt |
| `install_service.dart` | 1.5 KB | Installation |
| `leave_service.dart` | 1.1 KB | Leave mgmt |
| `license_service.dart` | 0.6 KB | Licensing |
| `localization_service.dart` | 0.6 KB | Localization |
| `notification_service.dart` | 1.0 KB | Notifications |
| `operator_service.dart` | 0.9 KB | Operator mgmt |
| `payroll_service.dart` | 4.9 KB | Payroll/WPS |
| `peripheral_print_service.dart` | 5.7 KB | Thermal printing |
| `purchase_service.dart` | 1.3 KB | Purchasing |
| `reports_service.dart` | 5.3 KB | Reports |
| `rfid_service.dart` | 2.9 KB | RFID |
| `sales_service.dart` | 6.5 KB | Sales/POS |
| `settings_service.dart` | 0.6 KB | Settings |
| `sterilization_service.dart` | 1.2 KB | Sterilization |
| `storefront_service.dart` | 0.9 KB | Storefront |
| `sync_service.dart` | 5.9 KB | Sync engine |
| `system_guard_service.dart` | 4.5 KB | UMAC/License guard |
| `terminal_service.dart` | 0.9 KB | Terminal mgmt |
| `token_storage.dart` | 1.5 KB | JWT storage |

### 1.4 Models Layer (23 files, ~65 KB total)
| File | Size |
|:-----|:-----|
| `attendance_model.dart` | 3.7 KB |
| `branch_model.dart` | 2.6 KB |
| `cart_line_model.dart` | 1.4 KB |
| `challan_model.dart` | 1.9 KB |
| `customer_model.dart` | 3.0 KB |
| `dashboard_metrics_model.dart` | 1.4 KB |
| `delivery_model.dart` | 3.4 KB |
| `employee_model.dart` | 5.8 KB |
| `garment_tag_model.dart` | 2.0 KB |
| `inventory_model.dart` | 4.1 KB |
| `invoice_model.dart` | 3.2 KB |
| `leave_model.dart` | 2.7 KB |
| `order_item_model.dart` | 2.6 KB |
| `order_model.dart` | 6.0 KB |
| `payment_model.dart` | 2.4 KB |
| `payroll_model.dart` | 7.7 KB |
| `purchase_order_model.dart` | 3.9 KB |
| `report_config_model.dart` | 1.3 KB |
| `salary_advance_model.dart` | 2.8 KB |
| `service_model.dart` | 1.9 KB |
| `sync_entry_model.dart` | 2.5 KB |
| `user_model.dart` | 2.6 KB |
| `vendor_model.dart` | 1.5 KB |

### 1.5 Core Utilities (17 files + 1 subdirectory, ~40 KB total)
| File | Size | Purpose |
|:-----|:-----|:--------|
| `api_client.dart` | 1.4 KB | Base HTTP helper |
| `app_state.dart` | 0.5 KB | Global state flags |
| `constants.dart` | 0.3 KB | App constants |
| `date_utils.dart` | 1.2 KB | Date formatting |
| `document_renderer.dart` | 5.3 KB | PDF/Document generation |
| `formatters.dart` | 1.0 KB | Number/currency formatters |
| `localization.dart` | 1.4 KB | i18n strings |
| `localization_extension.dart` | 0.2 KB | BuildContext extension |
| `logger.dart` | 1.2 KB | Logging utility |
| `money_utils.dart` | 0.8 KB | bcmath-style money helpers |
| `phone_normalizer.dart` | 1.9 KB | UAE phone normalization |
| `receipt_model.dart` | 4.6 KB | Receipt data model |
| `receipt_renderer.dart` | 11.0 KB | ESC/POS receipt builder |
| `safe_parser.dart` | 1.0 KB | Defensive JSON parser |
| `theme.dart` | 6.2 KB | Design system tokens |
| `ui_utils.dart` | 0.9 KB | Shared UI helpers |
| `validators.dart` | 1.6 KB | Form validation rules |
| `errors/` | (dir) | Error types |

### 1.6 Providers (5 files, ~8 KB total)
| File | Size | Purpose |
|:-----|:-----|:--------|
| `auth_provider.dart` | 3.7 KB | Auth state + JWT |
| `catalog_provider.dart` | 0.7 KB | Catalog cache |
| `locale_provider.dart` | 0.5 KB | Language toggle |
| `pos_cart_provider.dart` | 1.1 KB | POS cart state |
| `sync_provider.dart` | 2.2 KB | Sync state |

### 1.7 Widgets (4 files, ~8.5 KB total)
| File | Size | Purpose |
|:-----|:-----|:--------|
| `app_data_table.dart` | 2.4 KB | Reusable data table |
| `app_form_dialog.dart` | 2.9 KB | Modal form dialog |
| `empty_state.dart` | 1.7 KB | Empty state placeholder |
| `status_badge.dart` | 1.5 KB | Status pill component |

### 1.8 Router (1 file)
| File | Size |
|:-----|:-----|
| `app_router.dart` | 8.5 KB |

### 1.9 Peripherals (7+ files across 5 subdirectories)
| Directory | Purpose |
|:----------|:--------|
| `core/` | Base peripheral abstractions |
| `features/` | Feature-specific peripherals |
| `printers/` | ESC/POS thermal printing |
| `scanners/` | Barcode scanner integration |
| `shareables/` | Shared peripheral utilities |
| `bootstrap.dart` | Peripheral init |
| `peripheral_service.dart` | Service orchestrator |

### 1.10 Features (3 subdirectories)
| Directory | Purpose |
|:----------|:--------|
| `auth/` | Auth feature module |
| `pos/` | POS feature module |
| `wizard/` | Setup wizard feature |

---

## 2. Local PHP API (`api/`)

### 2.1 Core Framework (14 files, ~53 KB)
| File | Size | Purpose |
|:-----|:-----|:--------|
| `Application.php` | 26.1 KB | Main app kernel, DI, routing |
| `Autoloader.php` | 1.5 KB | PSR-4 autoloader |
| `Container.php` | 1.4 KB | Service container |
| `Env.php` | 1.5 KB | Environment loader |
| `EventBus.php` | 1.3 KB | Event dispatcher |
| `Money.php` | 3.1 KB | bcmath money class |
| `PdoFactory.php` | 0.8 KB | PDO connection factory |
| `Request.php` | 3.7 KB | HTTP request parser |
| `RequestPathResolver.php` | 2.1 KB | URL path resolver |
| `Response.php` | 0.6 KB | JSON response builder |
| `RouteRegistry.php` | 0.9 KB | Route registration |
| `Router.php` | 3.7 KB | Route dispatcher |
| `Uuid.php` | 0.7 KB | UUID v4 generator |
| `Validator.php` | 5.7 KB | Input validation engine |

### 2.2 Controllers (43 files, ~130 KB)
| File | Size | Domain |
|:-----|:-----|:-------|
| `AccountingController.php` | 2.1 KB | Accounting |
| `AdminController.php` | 2.2 KB | Admin operations |
| `AdvancedCycleController.php` | 4.7 KB | Machine cycles |
| `AnalyticsController.php` | 1.8 KB | Analytics |
| `AuthController.php` | 3.4 KB | Authentication |
| `BackupController.php` | 6.1 KB | Backup/Restore |
| `BranchController.php` | 2.4 KB | Branches |
| `BusinessController.php` | 1.4 KB | Business profile |
| `CatalogController.php` | 8.8 KB | Product catalog |
| `ChallanController.php` | 3.0 KB | Challans |
| `ChannelController.php` | 2.2 KB | Notifications |
| `ChemicalController.php` | 0.9 KB | Chemicals |
| `CustomerController.php` | 2.7 KB | CRM |
| `CustomerPortalController.php` | 1.8 KB | Customer portal |
| `DeliveryController.php` | 3.4 KB | Delivery |
| `DocsController.php` | 1.1 KB | API docs |
| `EquipmentController.php` | 2.4 KB | Equipment |
| `ExpenseController.php` | 5.3 KB | Expenses |
| `HealthController.php` | 0.9 KB | Health check |
| `HrController.php` | 11.2 KB | HR (attendance, leave, payroll) |
| `InstallController.php` | 2.6 KB | Installation |
| `InventoryController.php` | 3.5 KB | Inventory |
| `InvoiceController.php` | 1.7 KB | Invoices |
| `LanController.php` | 1.3 KB | LAN discovery |
| `LicenseController.php` | 3.5 KB | Licensing |
| `LocalizationController.php` | 1.6 KB | Localization |
| `NotificationController.php` | 3.6 KB | Notifications |
| `OperatorController.php` | 1.4 KB | Operators |
| `ProductController.php` | 2.0 KB | Products |
| `PurchaseController.php` | 3.1 KB | Purchasing |
| `RefundController.php` | 1.7 KB | Refunds |
| `ReportController.php` | 3.1 KB | Reports (legacy) |
| `ReportsController.php` | 9.6 KB | Reports (v2) |
| `RfidController.php` | 1.2 KB | RFID |
| `RoleController.php` | 2.8 KB | RBAC |
| `SalesController.php` | 6.0 KB | Sales/POS |
| `SettingsController.php` | 1.8 KB | Settings |
| `SetupController.php` | 1.4 KB | Setup wizard |
| `SterilizationController.php` | 3.6 KB | Sterilization |
| `StorefrontController.php` | 3.0 KB | Storefront |
| `SyncController.php` | 1.5 KB | Sync |
| `TerminalController.php` | 2.7 KB | Terminals |
| `VendorController.php` | 2.6 KB | Vendors |

### 2.3 Repositories (39 files, ~170 KB)
All 39 repositories map directly to database entities. Key repositories:
- `SalesRepository.php` (17.4 KB) — largest, handles multi-tender transactions
- `CatalogRepository.php` (14.4 KB) — product/category/modifier hierarchy
- `InventoryRepository.php` (13.8 KB) — stock movements
- `PayrollRepository.php` (12.1 KB) — payroll runs, SIF generation

### 2.4 Services (16 files, ~47 KB)
Core business logic layer including `BackupService`, `SyncService`, `PayrollCalculator`, `VatCalculator`, `SifExporter`, `InvoiceNumberGenerator`, `MigrationService`.

### 2.5 Security (4 files, ~4.7 KB)
`JwtService`, `PasswordHasher` (Argon2id), `PermissionChecker` (RBAC), `UmacService` (hardware lock).

### 2.6 Middleware (5 files, ~10 KB)
`Middleware` (core), `AuditLogMiddleware`, `IdempotencyMiddleware`, `RateLimitMiddleware`, `MiddlewareInterface`.

### 2.7 Routes (1 file, 51.4 KB)
Single `api.php` route file — comprehensive route registry covering all 43 controller endpoints.

---

## 3. Cloud PHP API (`cloud-api/`)

### 3.1 Controllers (18 files, ~156 KB)
| File | Size | Domain |
|:-----|:-----|:-------|
| `CloudApiController.php` | 24.4 KB | Master cloud gateway |
| `TenantApiController.php` | 17.2 KB | Tenant-scoped operations |
| `SalesController.php` | 14.7 KB | Multi-tenant sales |
| `HrController.php` | 13.8 KB | Multi-tenant HR |
| `AdminPortalController.php` | 10.1 KB | Admin portal |
| `PlatformController.php` | 10.8 KB | Platform management |
| `CatalogController.php` | 10.5 KB | Tenant catalog |
| `OperationsController.php` | 8.7 KB | Operations |
| `ReportsController.php` | 7.7 KB | Cross-tenant reports |
| `CustomerController.php` | 6.2 KB | Customer mgmt |
| `InventoryController.php` | 6.4 KB | Inventory |
| `VendorController.php` | 5.7 KB | Vendors |
| `SyncManagementController.php` | 5.0 KB | Sync orchestration |
| `ExpenseController.php` | 4.2 KB | Expenses |
| `AuthController.php` | 4.2 KB | Auth |
| `DeliveryController.php` | 4.2 KB | Delivery |
| `ChallanController.php` | 3.6 KB | Challans |
| `BaseController.php` | 2.1 KB | Base class |

### 3.2 Routes (1 file, 19.4 KB)
Cloud API route registry with tenant-scoped middleware.

### 3.3 Infrastructure
| File | Purpose |
|:-----|:--------|
| `Dockerfile` | 1.8 KB — PHP 8.2 FPM container |
| `.htaccess` | Apache rewrite rules |
| `.env.production` | Production env config |

---

## 4. Database Layer

### 4.1 Schema Files
| File | Size | Tables |
|:-----|:-----|:-------|
| `database/schema.sql` | 176 KB | 219 CREATE TABLE statements (master) |
| `database/local/schema.sql` | 62 KB | Local-only schema |
| `database/cloud/schema.sql` | 31 KB | Cloud-only schema |
| `database/seed.sql` | 4.6 KB | Initial seed data |

### 4.2 API Database Layer
| Directory | Files |
|:----------|:------|
| `api/database/` | Migration support files |

---

## 5. Test Layer

### 5.1 Flutter Tests (17 files + 1 subdirectory)
| File | Size | Coverage |
|:-----|:-----|:---------|
| `catalog_test.dart` | 0.6 KB | Catalog CRUD |
| `edge_case_test.dart` | 4.3 KB | Edge cases |
| `i18n_test.dart` | 1.0 KB | Localization |
| `model_test.dart` | 2.5 KB | Data models |
| `peripheral_print_service_test.dart` | 1.8 KB | Printing |
| `phase2_expense_test.dart` | 4.9 KB | Expense workflows |
| `phase2_hr_test.dart` | 8.2 KB | HR workflows |
| `phase2_rtl_test.dart` | 1.1 KB | RTL layout |
| `phase2_workflow_test.dart` | 4.8 KB | Business workflows |
| `phase3_service_test.dart` | 7.6 KB | Service layer |
| `qa_smoke_test.dart` | 3.8 KB | Smoke tests |
| `receipt_test.dart` | 1.3 KB | Receipt generation |
| `router_test.dart` | 0.5 KB | Routing |
| `rtl_test.dart` | 0.6 KB | RTL support |
| `sync_engine_test.dart` | 3.1 KB | Sync engine |
| `widget_test.dart` | 0.8 KB | Widget tests |
| `peripherals/` | (dir) | Peripheral-specific tests |
| `peripherals_test_support.dart` | 0.9 KB | Test utilities |

---

## 6. Documentation Layer (32+ docs, 28 subdirectories)

| Directory | Purpose |
|:----------|:--------|
| `docs/api/` | API endpoint documentation |
| `docs/architecture/` | System architecture diagrams |
| `docs/blueprints/` | Feature blueprints |
| `docs/compliance/` | UAE FTA, VAT, ZATCA docs |
| `docs/data/` | Data models & schemas |
| `docs/edge-cases/` | Edge case handling |
| `docs/flows/` | Business workflow diagrams |
| `docs/forms/` | Form specifications |
| `docs/integrations/` | Third-party integrations |
| `docs/licensing/` | License management |
| `docs/multitenancy/` | Multi-tenant architecture |
| `docs/operations/` | Operational procedures |
| `docs/peripherals/` | Hardware integration |
| `docs/reference/` | Reference materials |
| `docs/requirements/` | Business requirements |
| `docs/security/` | Security policies |
| `docs/swagger/` | OpenAPI specs |
| `docs/sync/` | Sync engine docs |
| `docs/testing/` | Test strategy |
| `docs/training/` | User training materials |
| `docs/ui/` | UI/UX guidelines |
| `docs/use-cases/` | Use case documents |
| `docs/user-journeys/` | User journey maps |
| `docs/workflows/` | Workflow definitions |

Key standalone docs:
- `docs/UNIFIED_DOCUMENTATION.md` (192 KB) — master reference
- `docs/BLUEPRINT_WORKFLOWS_USE_CASES.md` (24 KB) — workflow blueprints

---

## 7. Infrastructure & Config

| File | Size | Purpose |
|:-----|:-----|:--------|
| `pubspec.yaml` | 1.6 KB | Flutter dependencies |
| `analysis_options.yaml` | 1.5 KB | Dart lint rules |
| `build_windows.ps1` | 1.5 KB | MSIX build script |
| `docs/msix_config.yaml` | 0.3 KB | MSIX installer config |
| `.gitignore` | 3.4 KB | Git exclusions |
| `README.md` | 13.1 KB | Project README |
| `.env` / `.env.example` | Various | Environment configs |

---

## 8. Total Project Metrics

| Metric | Value |
|:-------|:------|
| **Total Dart files** | 192 |
| **Total PHP files (local)** | 129 |
| **Total PHP files (cloud)** | 35 |
| **Total SQL schema tables** | 219 |
| **Total documentation files** | 32+ |
| **Total test assertions** | 315 (all passing) |
| **Total screens** | 42 |
| **Total services (Flutter)** | 38 |
| **Total controllers (local API)** | 43 |
| **Total repositories (local API)** | 39 |
| **Total controllers (cloud API)** | 18 |
| **Estimated total LOC** | ~45,000+ |

---

> **Resume Token:** `RT-C1-20261005-CENSUS-COMPLETE`
> **Next Chunk:** C2 — Database Schema Deep-Dive
