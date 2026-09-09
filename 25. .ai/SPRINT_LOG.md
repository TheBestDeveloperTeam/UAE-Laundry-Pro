# Sprint Log — UAE Laundry Pro

---

## Sprint Overview

### Sprint 01: Architecture Hardening & Global Configuration (Completed)
- [x] GlobalConfigService singleton in Flutter with validation and persistence
- [x] Standalone Global Configuration Admin UI (lib/views/global_config_screen.dart)
- [x] BACKUP_PATH / INVOICE_PATH / IMAGE_PATH / LOG_PATH / EXPORT_PATH / TEMP_PATH / TEMPLATE_PATH editable by admin
- [x] C:/LaundryPro/ directory auto-creation on app startup (GlobalConfigService().init() in main.dart)
- [x] Ensure api/.env keys match global_config_service.dart defaults

### Sprint Summary
| Sprint | Name | Status | Key Deliverables |
| :--- | :--- | :--- | :--- |
| S01 | Foundation & Config | ✅ Done | Global path resolution, settings singleton, env sync |
| S02 | Auth & Security | ✅ Done | OAuth2 JWT, RBAC matrix, UMAC hardware lock, Account lockout |
| S03 | Schema & Migrations | ✅ Done | Consolidated 001_baseline.sql, performance indexes, UAE seeds |
| S04 | App Shell & Setup Wizard | ✅ Done | 8-step setup wizard, app header bar, status bar, RTL language |
| S05 | Customer & Vendor Master | ✅ Done | UAE phone normalization, duplicate detection, quick customer |
| S06 | Catalog & Services | ⏳ In Progress | Service/Product hierarchy, composite items, modifiers |
| S07 | Core Sales (POS) | ⏳ Pending | Drafts, order confirmation, cart, taxes |

---

## Active Sprint Details

### Sprint 03: Database Schema Completion & Migrations (Completed)
1. Consolidated `001_baseline.sql` with migrations 001 through 031 (including account lockout, seed roles, and performance indexes).
2. Verified foreign key constraints, `utf8mb4` charset, and critical indexes for customers, vendors, catalog, sales, and movements.
3. Updated `001_all_seeds.sql` with full role matrix and standard UAE VAT (5%) and TRN settings.
4. Added multi-path resolution in `scripts/migrate.ps1` for local XAMPP environments.

### Sprint 04: App Shell & Setup Wizard (Completed)
1. Implemented complete 8-step first-run **Setup Wizard** (`SetupWizardScreen`): Business Profile, Locale/Currency, Doc Prefixes, Admin User, Backup Path, Printer Defaults, Workstation Binding, License Activation.
2. Updated `AppShell` with a top header bar (brand logo, branch, terminal, user, language toggle) and bottom real-time status bar (API status, printers, scanner wedge, disk space, version).
3. Verified bidirectional English/Arabic RTL flipping via `Directionality` and `LocaleProvider`.

### Sprint 05: Customer & Vendor Master (Completed)
1. Implemented `PhoneNormalizer` algorithm for UAE numbers (+971/05x) and Levenshtein duplicate detection.
2. Built rich `CustomersScreen` supporting fast search, code lookup, balance tracking, address/notes, and duplicate warnings.

### Next Sprint (S06) Priorities
1. Service & Product hierarchy models.
2. Catalog UI enhancements and modifier management.
3. Composite bundle mapping and inventory tracking logic.
