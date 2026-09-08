# Project Summary & Live Brain Context

**Product Name:** LaundryPro UAE / LaundraCore Local  
**Maintainer & Architecture:** Magnificent Solution  
**Status:** 100% Production Ready (Phase 0, 1A-1C, 2, 3, 4 Peripherals, Central Cloud API, and AdminLTE Super-Admin Portal Verified)  
**Primary Execution Host:** Windows Desktop 64-bit (x64)  

---

## 1. System Topology & Dual-Layer Architecture

The system operates across two tightly harmonized layers:

### Layer A: Local Client Workstation Node (`LaundryPro Local`)
- **Frontend Workstation:** Standalone Flutter (Dart 3.x) Windows Desktop Application (`build/windows/x64/runner/Release/laundrypro_uae.exe`).
  - Architecture: Layered MVVM + Provider + GoRouter.
  - Localization: Dynamic LTR / RTL switching (English `en-AE`, Arabic `ar-AE`).
  - Hardware: Thermal receipt printing (ESC/POS 80mm/58mm), barcode scanning (Keyboard Wedge / Serial), cash drawer kick (`ESC p 0 25 250`).
- **Local Application API:** Pure PHP 8.2 REST API without third-party frameworks located in `api/`.
  - Served via local Apache VirtualHost `http://laundrypro-localapi/api/v1` (with `Require local` security to prevent outside tampering).
- **Local Database:** MySQL / MariaDB (via XAMPP) database `laundrypro` with 19 migrations (`001_baseline.sql` consolidated schema).
- **Anti-Tamper Evaluation Guard:**
  - Hardware identity `UMAC-XXXX-XXXX-XXXX` derived from CPU ID + Motherboard Serial + Windows Machine GUID.
  - Windows Registry heartbeat (`HKCU\Software\LaundryProUAE\Evaluation\InstallPulse`) preventing system clock rollbacks.
  - Strict 7-day TTL, maximum 9 invoices, and maximum 9 customers trial enforcement with offline cryptographic `.lic` import and online handshake.

### Layer B: Central Multi-Tenant Cloud API & Super-Admin Portal (`cloud-api`)
- **Cloud Gateway:** Pure PHP 8.2 REST API located in `cloud-api/` (`http://localhost/cloud-api/public` or `https://www.laundrypro-cloudapi.magnificentsolution.co.in/`).
- **Super-Admin Web Portal (`/admin`):**
  - Styled with AdminLTE v4 (Bootstrap 5, Material-style responsive interface).
  - Secure session-based authentication with CSRF tokens and salted bcrypt password verification (`superadmin` / `SuperAdmin@LaundryPro2026!`).
  - Modules: Executive Dashboard, Registered Tenants & Business Nodes, Cryptographic License Generation & Instant Revocation, Real-time Sync Payload Stream Inspector, System Audit Trail.
- **Cloud Database:** MariaDB/MySQL database `laundrypro_cloud` (`cloud-api/database/001_cloud_schema.sql` + `002_cloud_seeds.sql`).

---

## 2. Key Verification Metrics & Quality Gates

All quality gates and test suites run and pass cleanly:
- **Flutter Test Suite:** 116 / 116 unit & widget tests passed (`powershell scripts/dev.ps1 test`).
- **Flutter Analysis:** 0 issues found (`powershell scripts/dev.ps1 analyze`).
- **Backend API Integration Tests:** 178 passed, 0 failed, 4 skipped (`powershell scripts/dev.ps1 test-api`).
- **PHP Syntax Lint:** 85 local API files + 16 Cloud API files = 101 PHP files with 0 syntax errors (`powershell scripts/dev.ps1 lint`).
- **Release Build:** Native 64-bit Windows executable generated and verified.

---

## 3. Directory & Context Pointers

- **Local API Contract:** [`.ai-knowledge/api-contract.md`](../.ai-knowledge/api-contract.md)
- **Database Relational Schemas:** [`.ai-knowledge/database-schema.md`](../.ai-knowledge/database-schema.md)
- **Dependency & Architecture Graphs:** [`dependency-graphs.md`](dependency-graphs.md)
- **Algorithms & Core Logic Reference:** [`algorithms-and-business-logic.md`](algorithms-and-business-logic.md)
- **Architectural Decision Records:** [`.ai-decision/`](../.ai-decision/)
- **Live Development Roadmap:** [`../../marketing/03-technical/complete-full-and-final-live-updated-development-roadmap.md`](../../marketing/03-technical/complete-full-and-final-live-updated-development-roadmap.md)
- **Operator User Manual:** [`../../docs/MANUAL_OPERATOR_BOOK.md`](../../docs/MANUAL_OPERATOR_BOOK.md)
- **Super-Admin Portal Manual:** [`../../docs/MANUAL_ADMIN_SUPERADMIN_BOOK.md`](../../docs/MANUAL_ADMIN_SUPERADMIN_BOOK.md)
- **Operational Use-Case Blueprint:** [`../../docs/BLUEPRINT_WORKFLOWS_USE_CASES.md`](../../docs/BLUEPRINT_WORKFLOWS_USE_CASES.md)
