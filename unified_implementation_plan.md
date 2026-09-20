# Full Project Audit & Unified Sprint Roadmap — LaundryPro UAE
> **Audit Date:** 2026-09-21 | **Auditor:** AI Principal Architect
> **Status:** Production Development — Sprint 1 Ready

---

## Part 1: Complete Project Audit

### 1.1 Source Code Inventory

| Layer | Files | Lines | Status |
|-------|-------|-------|--------|
| Flutter (lib/) | 148 .dart | 16,026 | Active development |
| PHP API (api/) | 120 .php | 11,065 | Active development |
| Cloud API (cloud-api/) | 16 .php | 1,360 | Basic scaffold |
| SQL Migrations | 66 .sql | ~7,500 | Baseline + 30 archived |
| Tests | 22 .dart | ~1,200 | Peripherals only |
| .ai/ Ecosystem | 182 .md | ~15,000 | **COMPLETE** |
| docs/ Universe | 115 .md | ~8,000 | **COMPLETE** |
| Scripts | 12 | ~800 | Utility scripts |
| **TOTAL** | **681** | **~60,000** | |

### 1.2 Flutter Architecture Audit

#### Existing Screens (42 views) ✅
| Screen | File | Status |
|--------|------|--------|
| Login | login_screen.dart | ✅ Built |
| Dashboard | dashboard_screen.dart | ✅ Built |
| POS | pos_screen.dart | ✅ Built |
| Customers | customers_screen.dart | ✅ Built |
| Catalog/Services | catalog_screen.dart | ✅ Built |
| Orders/Sales | (via pos_screen) | ✅ Built |
| Employees | employees_screen.dart | ✅ Built |
| Attendance | attendance_screen.dart | ✅ Built |
| Payroll | payroll_screen.dart | ✅ Built |
| Leave | leave_screen.dart | ✅ Built |
| Delivery | delivery_screen.dart | ✅ Built |
| Branches | branches_screen.dart | ✅ Built |
| Invoices | pending_invoices_screen.dart | ✅ Built |
| Inventory/Equipment | equipment_screen.dart | ✅ Built |
| Expenses | expenses_screen.dart | ✅ Built |
| Reports | reports_screen.dart | ✅ Built |
| Analytics | analytics_screen.dart | ✅ Built |
| Settings | settings_screen.dart | ✅ Built |
| Production | production_screen.dart | ✅ Built |
| Operators | operator_screen.dart | ✅ Built |
| License | license_screen.dart | ✅ Built |
| Peripherals | peripherals_screen.dart | ✅ Built |
| Sync Settings | sync_settings_screen.dart | ✅ Built |
| Vendors | vendors_screen.dart | ✅ Built |
| Purchasing | purchasing_screen.dart | ✅ Built |
| Challans | challans_screen.dart | ✅ Built |
| Notifications | notifications_screen.dart | ✅ Built |
| Channels | channels_screen.dart | ✅ Built |
| RFID Tracking | rfid_tracking_screen.dart | ✅ Built |
| Sterilization | sterilization_screen.dart | ✅ Built |
| Storefront | storefront_screen.dart | ✅ Built |
| Customer Portal | customer_portal_screen.dart | ✅ Built |
| Accounting | accounting_screen.dart | ✅ Built |
| Setup Wizard | setup_wizard_screen.dart | ✅ Built |
| App Shell | app_shell.dart | ✅ Built |
| Splash | splash_screen.dart | ✅ Built |
| Business | business_screen.dart | ✅ Built |
| Localization | localization_screen.dart | ✅ Built |
| Role Editor | role_editor_screen.dart | ✅ Built |
| Terminals | terminals_screen.dart | ✅ Built |
| Global Config | global_config_screen.dart | ✅ Built |
| Salary Advances | salary_advances_screen.dart | ✅ Built |
| Advanced Cycle | advanced_cycle_screen.dart | ✅ Built |

#### Existing Services (37 services) ✅
All 37 API service clients are built covering auth, sales, customers, employees, payroll, delivery, inventory, reports, sync, and more.

#### Existing Core (9 files) ✅
Theme, localization, receipt model/renderer, document renderer, phone normalizer, constants, API exception.

---

### 1.3 PHP API Architecture Audit

#### Controllers (37) ✅
Full CRUD controllers for all modules including Auth, Sales, Customers, HR, Delivery, Inventory, Reports, Sync, License, Settings, and specialized controllers (RFID, Sterilization, Storefront, Portal).

#### Repositories (34) ✅
Complete repository layer with data access for all entities.

#### Security (4 files) ✅
- JwtService.php ✅
- PasswordHasher.php ✅
- PermissionChecker.php ✅
- UmacService.php ✅

#### Middleware (2 files)
- Middleware.php ✅
- RateLimitMiddleware.php ✅

#### Services (11 files)
- AuthService ✅, BackupService ✅, InstallService ✅, LicenseService ✅
- MessagingService ✅, MigrationService ✅, SeedService ✅, SyncService ✅
- AccountingExportService ✅, TwilioSmsAdapter ✅, SmsAdapterInterface ✅

---

### 1.4 Critical Gap Analysis

> [!IMPORTANT]
> The following items are **MISSING** and required for production readiness.

#### Flutter — Missing Models (14 files)
| Model | Purpose | Priority |
|-------|---------|----------|
| order_model.dart | Order data class with fromJson/toJson | P0 |
| customer_model.dart | Customer data class | P0 |
| invoice_model.dart | Invoice data class (immutable posted) | P0 |
| product_model.dart | Service/product catalog model | P0 |
| employee_model.dart | Employee data class | P0 |
| payment_model.dart | Payment transaction model | P0 |
| branch_model.dart | Branch data class | P0 |
| service_model.dart | Laundry service type model | P0 |
| delivery_model.dart | Delivery assignment model | P1 |
| inventory_model.dart | Inventory item model | P1 |
| attendance_model.dart | Attendance record model | P1 |
| payroll_model.dart | Payroll calculation model | P1 |
| sync_entry_model.dart | Sync outbox entry model | P1 |
| garment_tag_model.dart | Garment barcode/RFID tag model | P2 |

#### Flutter — Missing Core Utilities (6 files)
| File | Purpose | Priority |
|------|---------|----------|
| validators.dart | Form validation functions (UAE phone, TRN, email) | P0 |
| formatters.dart | Currency, date, number formatters | P0 |
| money_utils.dart | Decimal-safe money arithmetic | P0 |
| date_utils.dart | Date helpers, business day calc | P1 |
| database/local_database.dart | SQLite local DB setup (drift) | P1 |
| sync/sync_engine.dart | Offline sync outbox engine | P1 |

#### Flutter — Missing Localization (2 files)
| File | Purpose | Priority |
|------|---------|----------|
| l10n/en.json | English locale strings | P0 |
| l10n/ar.json | Arabic locale strings | P0 |

#### PHP — Missing Business Services (5 files)
| Service | Purpose | Priority |
|---------|---------|----------|
| VatCalculator.php | UAE VAT 5% calculation (bcmath) | P0 |
| InvoiceNumberGenerator.php | Sequential INV-YYYY-NNNNNN | P0 |
| OrderNumberGenerator.php | Sequential ORD-YYYY-NNNNNN | P0 |
| PayrollCalculator.php | UAE overtime rules (1.25x/1.5x/2x) | P1 |
| SifExporter.php | WPS SIF file generation | P1 |

#### PHP — Missing Middleware (2 files)
| Middleware | Purpose | Priority |
|-----------|---------|----------|
| IdempotencyMiddleware.php | Prevent duplicate writes via UUID key | P0 |
| AuditLogMiddleware.php | Auto-log all state changes | P0 |

#### Configuration — Missing (2 files)
| File | Purpose | Priority |
|------|---------|----------|
| .env.example | Environment variable template | P0 |
| api/.env.example | API environment template | P0 |

---

### 1.5 Module Readiness Matrix

| Module | Screen | Service | Controller | Repository | Model | Tests | **Ready** |
|--------|:------:|:-------:|:----------:|:----------:|:-----:|:-----:|:---------:|
| Auth | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | 80% |
| Dashboard | ✅ | ✅ | ✅ | ✅ | N/A | ❌ | 80% |
| POS/Sales | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Customers | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Catalog | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Employees | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Attendance | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Payroll | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 60% |
| Leave | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Delivery | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Inventory | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Production | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Invoicing | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 60% |
| Reports | ✅ | ✅ | ✅ | ✅ | N/A | ❌ | 75% |
| Sync | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 50% |
| License/UMAC | ✅ | ✅ | ✅ | N/A | N/A | ❌ | 70% |
| Peripherals | ✅ | ✅ | N/A | N/A | N/A | ✅ | 85% |
| Settings | ✅ | ✅ | ✅ | ✅ | N/A | ❌ | 80% |

### 1.6 Architecture Compliance

| Rule | Status | Notes |
|------|--------|-------|
| DECIMAL(18,2) for money | ✅ | Enforced in 001_baseline.sql |
| business_owner_id on data tables | ✅ | Present in baseline schema |
| RBAC PermissionChecker | ✅ | api/src/Security/PermissionChecker.php exists |
| JWT Auth | ✅ | JwtService.php + auth middleware |
| MVVM + Riverpod | ⚠️ | Screens exist but models layer is thin (only user_model) |
| Clean Architecture (PHP) | ✅ | Controller -> Service -> Repository -> PDO |
| Offline-first sync outbox | ⚠️ | Table exists, SyncService.php exists, Flutter sync_engine missing |
| LTR/RTL support | ⚠️ | Localization core exists but en.json/ar.json missing |
| Audit logging | ⚠️ | AuditLogRepository exists, auto-middleware missing |
| Sequential numbering | ❌ | InvoiceNumberGenerator + OrderNumberGenerator missing |
| UMAC licensing | ✅ | UmacService.php + license_screen.dart exist |
| SHA-256 backups | ✅ | BackupService.php exists |

---

## Part 2: Unified Sprint Roadmap — Remaining Development

> [!NOTE]
> Based on the audit, the project is approximately **65-70% complete**. The remaining work focuses on: models, utilities, localization, missing middleware/services, comprehensive tests, and production hardening.

---

### Sprint R1: Models & Core Utilities (Week 1-2)
> **Goal:** Complete the data model layer and core utilities that every module depends on.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R1.01 | Create `customer_model.dart` with fromJson/toJson, Equatable, copyWith | lib/models/customer_model.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.02 | Create `order_model.dart` + `order_item_model.dart` | lib/models/order_model.dart, lib/models/order_item_model.dart | ENG-FLUTTER | 3h | P0 | — |
| R1.03 | Create `invoice_model.dart` with immutability flag | lib/models/invoice_model.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.04 | Create `payment_model.dart` | lib/models/payment_model.dart | ENG-FLUTTER | 1h | P0 | — |
| R1.05 | Create `employee_model.dart` | lib/models/employee_model.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.06 | Create `branch_model.dart` | lib/models/branch_model.dart | ENG-FLUTTER | 1h | P0 | — |
| R1.07 | Create `service_model.dart` (catalog) | lib/models/service_model.dart | ENG-FLUTTER | 1h | P0 | — |
| R1.08 | Create `delivery_model.dart` | lib/models/delivery_model.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.09 | Create `inventory_model.dart` | lib/models/inventory_model.dart | ENG-FLUTTER | 1h | P1 | — |
| R1.10 | Create `attendance_model.dart` | lib/models/attendance_model.dart | ENG-FLUTTER | 1h | P1 | — |
| R1.11 | Create `payroll_model.dart` | lib/models/payroll_model.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.12 | Create `sync_entry_model.dart` | lib/models/sync_entry_model.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.13 | Create `garment_tag_model.dart` | lib/models/garment_tag_model.dart | ENG-FLUTTER | 1h | P2 | — |
| R1.14 | Create `money_utils.dart` (Decimal-safe math, ROUND_HALF_UP) | lib/core/money_utils.dart | ENG-FLUTTER | 3h | P0 | — |
| R1.15 | Create `validators.dart` (UAE phone +971, TRN 15-digit, email, required) | lib/core/validators.dart | ENG-FLUTTER | 3h | P0 | — |
| R1.16 | Create `formatters.dart` (currency AED, date DD/MM/YYYY, number) | lib/core/formatters.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.17 | Create `date_utils.dart` (business days, overtime calc support) | lib/core/date_utils.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.18 | Create `.env.example` at project root | .env.example | ENG-DEVOPS | 1h | P0 | — |
| R1.19 | Create `api/.env.example` | api/.env.example | ENG-DEVOPS | 1h | P0 | — |
| R1.20 | Update all 37 services to use typed models instead of raw Maps | lib/services/*.dart | ENG-FLUTTER | 8h | P0 | R1.01-R1.13 |

> **Sprint R1 Total: ~38 hours | 20 tasks | Exit: All models compile, all services typed**

---

### Sprint R2: Localization & RTL (Week 3-4)
> **Goal:** Full bilingual support (English + Arabic) across all 42 screens.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R2.01 | Create `en.json` with all UI strings (~500+ keys) | lib/l10n/en.json | PROD-UID | 6h | P0 | — |
| R2.02 | Create `ar.json` with Arabic translations (~500+ keys) | lib/l10n/ar.json | PROD-UID | 8h | P0 | R2.01 |
| R2.03 | Integrate flutter_localizations + intl in pubspec.yaml | pubspec.yaml | ENG-FLUTTER | 1h | P0 | — |
| R2.04 | Create localization delegate and app_localizations.dart | lib/core/app_localizations.dart | ENG-FLUTTER | 3h | P0 | R2.01 |
| R2.05 | Replace all hardcoded strings in 42 screens with locale keys | lib/views/*.dart | ENG-FLUTTER | 12h | P0 | R2.04 |
| R2.06 | Add RTL layout testing for all screens | test/l10n/ | QA-A11Y | 6h | P0 | R2.05 |
| R2.07 | Add Arabic font (Noto Sans Arabic) to assets | pubspec.yaml, fonts/ | PROD-UID | 1h | P0 | — |
| R2.08 | Implement locale toggle in app shell (EN/AR switch) | lib/views/app_shell.dart | ENG-FLUTTER | 2h | P0 | R2.04 |
| R2.09 | Ensure all padding/margin uses start/end (not left/right) | lib/views/*.dart | ENG-FLUTTER | 4h | P0 | — |
| R2.10 | Ensure number display stays LTR in RTL context | lib/core/formatters.dart | ENG-FLUTTER | 2h | P1 | R2.04 |

> **Sprint R2 Total: ~45 hours | 10 tasks | Exit: App fully usable in Arabic RTL**

---

### Sprint R3: PHP Business Services & Middleware (Week 5-6)
> **Goal:** Complete missing server-side business logic and security middleware.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R3.01 | Create `VatCalculator.php` (5% VAT, bcmath, ROUND_HALF_UP) | api/src/Services/VatCalculator.php | FIN-VAT | 3h | P0 | — |
| R3.02 | Create `InvoiceNumberGenerator.php` (INV-YYYY-NNNNNN, gap-free) | api/src/Services/InvoiceNumberGenerator.php | FIN-BILLING | 4h | P0 | — |
| R3.03 | Create `OrderNumberGenerator.php` (ORD-YYYY-NNNNNN, gap-free) | api/src/Services/OrderNumberGenerator.php | ENG-PHP | 3h | P0 | — |
| R3.04 | Create `PayrollCalculator.php` (UAE overtime 1.25x/1.5x/2x, gratuity) | api/src/Services/PayrollCalculator.php | HR-PAYROLL | 6h | P0 | — |
| R3.05 | Create `SifExporter.php` (WPS SIF file format) | api/src/Services/SifExporter.php | HR-PAYROLL | 4h | P1 | R3.04 |
| R3.06 | Create `IdempotencyMiddleware.php` (UUID dedup on write ops) | api/src/Middleware/IdempotencyMiddleware.php | ENG-PHP | 4h | P0 | — |
| R3.07 | Create `AuditLogMiddleware.php` (auto-log all POST/PATCH/DELETE) | api/src/Middleware/AuditLogMiddleware.php | SEC-AUDIT | 4h | P0 | — |
| R3.08 | Integrate VatCalculator into SalesController + InvoiceController | api/src/Controllers/ | ENG-PHP | 3h | P0 | R3.01 |
| R3.09 | Integrate sequential numbering into Sales + Invoice flows | api/src/Controllers/ | ENG-PHP | 3h | P0 | R3.02, R3.03 |
| R3.10 | Register IdempotencyMiddleware on all write endpoints | api/src/routes.php or equivalent | ENG-PHP | 2h | P0 | R3.06 |
| R3.11 | Register AuditLogMiddleware on all state-changing endpoints | api/src/routes.php or equivalent | ENG-PHP | 2h | P0 | R3.07 |
| R3.12 | Implement immutable invoice enforcement (block UPDATE on status=posted) | api/src/Services/ | FIN-BILLING | 3h | P0 | — |
| R3.13 | Add correction memo endpoint (POST /invoices/:id/correction) | api/src/Controllers/SalesController.php | FIN-BILLING | 4h | P1 | R3.12 |
| R3.14 | Implement hash-chained audit logs (SHA-256 chain) | api/src/Repositories/AuditLogRepository.php | SEC-AUDIT | 4h | P1 | — |

> **Sprint R3 Total: ~49 hours | 14 tasks | Exit: All business services operational, middleware enforced**

---

### Sprint R4: Offline Sync Engine (Week 7-8)
> **Goal:** Complete offline-first sync between Flutter SQLite and PHP/MariaDB.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R4.01 | Setup drift (SQLite ORM) in Flutter project | pubspec.yaml, lib/core/database/ | ENG-FLUTTER | 4h | P0 | — |
| R4.02 | Create local database schema mirroring key MariaDB tables | lib/core/database/local_database.dart | ENG-FLUTTER | 6h | P0 | R4.01 |
| R4.03 | Create `sync_outbox.dart` (local outbox table + CRUD) | lib/core/sync/sync_outbox.dart | ENG-SYNC | 4h | P0 | R4.01 |
| R4.04 | Create `sync_engine.dart` (push/pull coordinator) | lib/core/sync/sync_engine.dart | ENG-SYNC | 8h | P0 | R4.03 |
| R4.05 | Implement connectivity detection (online/offline status) | lib/core/sync/connectivity_monitor.dart | ENG-SYNC | 3h | P0 | — |
| R4.06 | Implement push protocol (batch POST to /sync/push) | lib/core/sync/push_protocol.dart | ENG-SYNC | 4h | P0 | R4.04 |
| R4.07 | Implement pull protocol (GET /sync/pull?since=) | lib/core/sync/pull_protocol.dart | ENG-SYNC | 4h | P0 | R4.04 |
| R4.08 | Implement conflict resolution (LWW by updated_at) | lib/core/sync/conflict_resolver.dart | ENG-SYNC | 4h | P0 | R4.06, R4.07 |
| R4.09 | Create sync status UI widget (pending/synced/failed counts) | lib/widgets/sync_status_widget.dart | ENG-FLUTTER | 3h | P1 | R4.04 |
| R4.10 | Integrate sync engine into all write operations across services | lib/services/*.dart | ENG-SYNC | 6h | P0 | R4.04 |
| R4.11 | Dead-letter queue management screen | lib/views/sync_settings_screen.dart | ENG-FLUTTER | 3h | P1 | R4.04 |
| R4.12 | Sync engine unit tests (offline, online, conflict scenarios) | test/sync/ | QA-AUTO | 6h | P0 | R4.04 |

> **Sprint R4 Total: ~55 hours | 12 tasks | Exit: App works 30+ days offline, syncs correctly**

---

### Sprint R5: Unit Tests — Auth, Models, Core (Week 9-10)
> **Goal:** 80%+ test coverage on models, core utilities, and auth flow.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R5.01 | Unit tests for all 14 model classes (fromJson, toJson, equality) | test/models/ | QA-AUTO | 8h | P0 | R1 |
| R5.02 | Unit tests for money_utils.dart (precision, rounding, edge cases) | test/core/money_utils_test.dart | QA-AUTO | 4h | P0 | R1.14 |
| R5.03 | Unit tests for validators.dart (UAE phone, TRN, email) | test/core/validators_test.dart | QA-AUTO | 3h | P0 | R1.15 |
| R5.04 | Unit tests for formatters.dart (currency, date, number) | test/core/formatters_test.dart | QA-AUTO | 3h | P0 | R1.16 |
| R5.05 | Unit tests for VatCalculator.php (5% calc, rounding, zero, max) | test/php/VatCalculatorTest.php | QA-AUTO | 3h | P0 | R3.01 |
| R5.06 | Unit tests for InvoiceNumberGenerator.php (sequential, no gaps) | test/php/InvoiceNumberTest.php | QA-AUTO | 3h | P0 | R3.02 |
| R5.07 | Unit tests for OrderNumberGenerator.php (sequential, no gaps) | test/php/OrderNumberTest.php | QA-AUTO | 2h | P0 | R3.03 |
| R5.08 | Unit tests for PayrollCalculator.php (overtime, gratuity) | test/php/PayrollCalculatorTest.php | QA-AUTO | 4h | P0 | R3.04 |
| R5.09 | Unit tests for auth_service.dart (login, refresh, logout, error) | test/services/auth_service_test.dart | QA-AUTO | 4h | P0 | — |
| R5.10 | Unit tests for AuthService.php + JwtService.php | test/php/AuthServiceTest.php | QA-AUTO | 4h | P0 | — |
| R5.11 | Unit tests for PermissionChecker.php (all 6 roles, scope combos) | test/php/PermissionCheckerTest.php | QA-AUTO | 4h | P0 | — |
| R5.12 | Unit tests for UmacService.php (hash, validate, grace period) | test/php/UmacServiceTest.php | QA-AUTO | 3h | P1 | — |
| R5.13 | Unit tests for SyncService.php (push, pull, conflict, idempotency) | test/php/SyncServiceTest.php | QA-AUTO | 4h | P0 | — |
| R5.14 | Unit tests for AuditLogRepository (hash chain integrity) | test/php/AuditLogTest.php | QA-AUTO | 3h | P1 | R3.14 |
| R5.15 | Run flutter test with coverage report, verify >= 80% | — | QA-AUTO | 2h | P0 | R5.01-R5.04 |

> **Sprint R5 Total: ~52 hours | 15 tasks | Exit: 80%+ unit test coverage, all tests green**

---

### Sprint R6: Integration Tests & API Tests (Week 11-12)
> **Goal:** End-to-end API testing and cross-module integration verification.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R6.01 | API integration test: Auth flow (login -> token -> refresh -> logout) | test/integration/auth_flow_test.dart | QA-AUTO | 4h | P0 | R5 |
| R6.02 | API integration test: Order lifecycle (create -> update -> complete) | test/integration/order_flow_test.dart | QA-AUTO | 6h | P0 | R5 |
| R6.03 | API integration test: Invoice lifecycle (create -> post -> immutable) | test/integration/invoice_flow_test.dart | QA-AUTO | 4h | P0 | R5 |
| R6.04 | API integration test: Payment flow (full, partial, split) | test/integration/payment_flow_test.dart | QA-AUTO | 4h | P0 | R5 |
| R6.05 | API integration test: Tenant isolation (cross-tenant blocked) | test/integration/tenant_isolation_test.dart | QA-SECTEST | 4h | P0 | — |
| R6.06 | API integration test: RBAC enforcement (6 roles x key endpoints) | test/integration/rbac_test.dart | QA-SECTEST | 6h | P0 | — |
| R6.07 | API integration test: Sync push/pull (batch, idempotency, conflict) | test/integration/sync_test.dart | QA-AUTO | 6h | P0 | R4 |
| R6.08 | API integration test: Payroll + SIF export | test/integration/payroll_test.dart | QA-AUTO | 4h | P1 | R3.04 |
| R6.09 | API integration test: Backup + SHA-256 verify + restore | test/integration/backup_test.dart | QA-AUTO | 3h | P1 | — |
| R6.10 | Widget integration test: POS flow (select -> pay -> receipt) | test/widget/pos_flow_test.dart | QA-AUTO | 6h | P0 | R1, R2 |
| R6.11 | Widget integration test: Login -> Dashboard -> Navigate | test/widget/navigation_test.dart | QA-AUTO | 4h | P0 | R2 |
| R6.12 | Edge case test suite: monetary precision (zero, max, negative) | test/edge/monetary_edge_test.dart | QA-EDGE | 4h | P0 | R1.14 |
| R6.13 | Edge case test suite: offline 30-day scenario | test/edge/offline_edge_test.dart | QA-EDGE | 4h | P0 | R4 |
| R6.14 | PHPUnit test suite setup and CI runner script | scripts/run_php_tests.ps1 | QA-AUTO | 3h | P0 | — |

> **Sprint R6 Total: ~62 hours | 14 tasks | Exit: All integration tests green, edge cases validated**

---

### Sprint R7: Production Hardening & Security (Week 13-14)
> **Goal:** Security hardening, performance optimization, and production readiness.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R7.01 | SQL injection audit: verify all queries use prepared statements | api/src/Repositories/*.php | SEC-APPSEC | 6h | P0 | — |
| R7.02 | XSS prevention: sanitize all user inputs in API responses | api/src/Controllers/*.php | SEC-APPSEC | 4h | P0 | — |
| R7.03 | RBAC endpoint coverage: verify every route has PermissionChecker | api/src/routes.php | SEC-APPSEC | 4h | P0 | — |
| R7.04 | Rate limiting configuration for auth endpoints (brute-force) | api/src/Middleware/RateLimitMiddleware.php | SEC-APPSEC | 2h | P0 | — |
| R7.05 | Account lockout after 5 failed login attempts | api/src/Services/AuthService.php | SEC-APPSEC | 3h | P0 | — |
| R7.06 | UMAC full flow test (bind, validate, grace period, read-only) | test/security/ | QA-SECTEST | 4h | P0 | — |
| R7.07 | PII encryption at rest for sensitive fields | api/src/Core/Encryption.php | SEC-APPSEC | 6h | P1 | — |
| R7.08 | Database query optimization: add missing composite indexes | api/database/migrations/003_indexes.sql | ENG-DB | 4h | P0 | — |
| R7.09 | API response time profiling (target P95 < 500ms) | scripts/api_benchmark.ps1 | ENG-PERF | 4h | P0 | — |
| R7.10 | Flutter widget rebuild profiling (eliminate unnecessary rebuilds) | lib/views/*.dart | ENG-PERF | 6h | P1 | — |
| R7.11 | Memory leak detection and fix | — | ENG-PERF | 4h | P1 | — |
| R7.12 | Create SECURITY.md (vulnerability disclosure process) | SECURITY.md | SEC-APPSEC | 2h | P1 | — |
| R7.13 | Dependency vulnerability scan (pub audit, composer audit) | — | SEC-APPSEC | 2h | P0 | — |

> **Sprint R7 Total: ~51 hours | 13 tasks | Exit: Security audit clean, perf targets met**

---

### Sprint R8: MSIX Packaging & Release (Week 15-16)
> **Goal:** Production MSIX build, code signing, install testing, go-live.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R8.01 | Configure msix_config.yaml with production values | msix_config.yaml | ENG-MSIX | 2h | P0 | — |
| R8.02 | Code signing certificate setup (.pfx) | — | ENG-MSIX | 4h | P0 | — |
| R8.03 | Build release Flutter Windows executable | — | ENG-MSIX | 2h | P0 | R7 |
| R8.04 | Build and sign MSIX package | — | ENG-MSIX | 2h | P0 | R8.02, R8.03 |
| R8.05 | Install test on clean Windows 10 machine | — | QA-MANUAL | 3h | P0 | R8.04 |
| R8.06 | Install test on clean Windows 11 machine | — | QA-MANUAL | 3h | P0 | R8.04 |
| R8.07 | Uninstall + reinstall test (data preservation) | — | QA-MANUAL | 2h | P0 | R8.04 |
| R8.08 | Auto-update mechanism via AppInstaller | — | ENG-MSIX | 4h | P1 | R8.04 |
| R8.09 | Full regression suite on release build | — | QA-REGRESS | 8h | P0 | R8.04 |
| R8.10 | WCAG 2.1 AA accessibility audit (all 42 screens) | — | QA-A11Y | 6h | P0 | R2 |
| R8.11 | Create CHANGELOG.md with v1.0.0 release notes | CHANGELOG.md | PROD-PO | 2h | P0 | — |
| R8.12 | Create README.md install/quickstart guide | README.md | OPS-TRAIN | 3h | P0 | — |
| R8.13 | Version bump: pubspec.yaml, msix_config.yaml (1.0.0) | — | ENG-MSIX | 1h | P0 | — |
| R8.14 | CTO + CEO sign-off for GA release | — | EXEC | 2h | P0 | R8.09 |
| R8.15 | Tag v1.0.0 in Git and push release | — | ENG-DEVOPS | 1h | P0 | R8.14 |

> **Sprint R8 Total: ~45 hours | 15 tasks | Exit: v1.0.0 MSIX signed, tested, released**

---

## Part 3: Summary Dashboard

### Sprint Overview

| Sprint | Focus | Tasks | Hours | Weeks | Deps |
|--------|-------|-------|-------|-------|------|
| **R1** | Models & Core Utilities | 20 | 38h | 1-2 | — |
| **R2** | Localization & RTL | 10 | 45h | 3-4 | R1 |
| **R3** | PHP Business Services | 14 | 49h | 5-6 | — |
| **R4** | Offline Sync Engine | 12 | 55h | 7-8 | R1 |
| **R5** | Unit Tests | 15 | 52h | 9-10 | R1,R3 |
| **R6** | Integration Tests | 14 | 62h | 11-12 | R4,R5 |
| **R7** | Security & Performance | 13 | 51h | 13-14 | R6 |
| **R8** | MSIX & Release | 15 | 45h | 15-16 | R7 |
| **TOTAL** | | **113 tasks** | **397h** | **16 weeks** | |

### Parallel Execution Opportunities
- **R1 + R3** can run in parallel (Flutter models + PHP services, different developers)
- **R2** can start once R1 is 50% done (screens exist, just need locale keys)
- **R4** can start once R1 is complete (needs models)
- **R5 + R6** sequential (unit before integration)

### Optimized Timeline (with parallelism)
```
Week 1-2:  R1 (Models)  +  R3 (PHP Services)     [PARALLEL]
Week 3-4:  R2 (L10n)    +  R3 cont.               [PARALLEL]
Week 5-6:  R4 (Sync)    +  R2 cont.               [PARALLEL]
Week 7-8:  R5 (Unit Tests)
Week 9-10: R6 (Integration Tests)
Week 11-12: R7 (Security & Perf)
Week 13-14: R8 (MSIX & Release)
```
**Optimized: 14 weeks to GA v1.0.0**

### Milestone Gates

| Milestone | Sprint | Criteria |
|-----------|--------|----------|
| **M1: Feature Complete** | R4 | All models, services, sync, localization operational |
| **M2: Test Complete** | R6 | 80%+ coverage, all integration tests green |
| **M3: Release Candidate** | R7 | Security clean, perf targets met |
| **M4: GA v1.0.0** | R8 | MSIX signed, install tested, CTO approved |
