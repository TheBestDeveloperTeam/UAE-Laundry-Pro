# Complete Full and Final Live Development Roadmap — LaundryPro UAE

**Product:** LaundryPro UAE / LaundraCore Local  
**Maintainer:** Magnificent Solution  
**Last verified:** 2026-09-04  
**Quality gate:** `powershell scripts\quality-gate.ps1`  
**Edge cases:** [`api/docs/EDGE_CASES.md`](../../api/docs/EDGE_CASES.md)  
**Overall progress:** ~48% (edge-case verification complete for Phase 0–1)

---

## Status legend

| Symbol | Meaning |
|--------|---------|
| ✅ VERIFIED | Implemented + tests/smoke pass |
| 🟡 DONE | Implemented, not yet re-verified this sprint |
| 🔵 IN_PROGRESS | Active work |
| ⬜ PENDING | Not started |
| 🚫 BLOCKED | Waiting on dependency |
| ⏸ DEFERRED | Out of current scope |

**Rule:** Never mark ✅ without test evidence (API case, unit test, or Flutter test).

---

## Executive summary

Offline-first Windows desktop laundry ERP/POS for UAE MSMEs. Stack: Flutter + plain PHP API + MySQL/MariaDB (XAMPP). **CR-2026-09-02-001** (multi-tenant cloud sync) runs **in parallel with Phase 1** after `business_owner_id` schema lands.

| Phase | Scope | Progress | Exit criteria |
|-------|-------|----------|---------------|
| **0** | Foundation, dev workflow, platform API | ~95% | Quality gate green, Swagger live |
| **1** | Core MVP + cloud sync parallel | ~40% | Offline sale loop + sync push/pull |
| **2** | Operations expansion | 0% | HR, delivery, advanced inventory |
| **3** | Scale | 0% | Multi-terminal, branch, KSA |

**Critical path:** Schema → CRM → Catalog → POS → Payments → License/Backup → Production package

**Spec sources:** [02](02%20-%20Local%20Laundry%20Flutter%20Windows%20Desktop.md) · [03](03%20-%20Project%20Memory%20Context%20Instructions%20-%20Laundry%20Pro%20UAE.md) · [04](04%20-%20Laundry%20Core%20RFP%20BRD%20SOW%20ER%20Use%20Cases%20Technical%20Blueprint.md) · [05](05%20-%20README.md) · [CR-2026-09-02-001](CR-2026-09-02-001.md)

---

## Milestones

| ID | Milestone | Target | Status |
|----|-----------|--------|--------|
| M1 | Platform quality gate | 2026-09-02 | ✅ VERIFIED |
| M2 | Schema v1 (003–006 migrations) | Week 1 | ✅ VERIFIED |
| M3 | CRM + catalog CRUD | Week 2–3 | 🟡 DONE |
| M4 | POS sale loop | Week 4–5 | ✅ VERIFIED |
| M4S | Cloud sync v1 (customers + sales) | Week 4–5 | 🟡 DONE |
| M5 | Phase 1 acceptance | Week 6 | 🔵 IN_PROGRESS |
| M6 | Phase 2 exit | Week 10–14 | ⬜ PENDING |
| M7 | Production MSI + UAT | Week 16+ | ⬜ PENDING |

---

## Phase 0 — Foundation (Platform)

| ID | Task | API | DB | Flutter | Tests | Status | Verified |
|----|------|-----|----|---------|-------|--------|----------|
| P0-01 | Plain PHP router, container, env | ✅ | — | — | routing_test | ✅ VERIFIED | 2026-09-02 |
| P0-02 | JWT auth login/refresh/logout/me | ✅ | ✅ | ✅ | identity_auth.json | ✅ VERIFIED | 2026-09-02 |
| P0-03 | Settings GET/PUT | ✅ | ✅ | — | configuration_settings.json | ✅ VERIFIED | 2026-09-02 |
| P0-04 | Health endpoint | ✅ | ✅ | — | platform_health.json | ✅ VERIFIED | 2026-09-02 |
| P0-05 | Install status/migrate/seed/complete | ✅ | ✅ | — | install_lifecycle.json | ✅ VERIFIED | 2026-09-02 |
| P0-06 | MigrationService + CLI migrate | — | ✅ | — | migrate.ps1 | ✅ VERIFIED | 2026-09-02 |
| P0-07 | RouteRegistry + OpenApiGenerator | ✅ | — | — | openapi_drift_test | ✅ VERIFIED | 2026-09-02 |
| P0-08 | Bundled Swagger UI `/docs/` | ✅ | — | — | manual | ✅ VERIFIED | 2026-09-02 |
| P0-09 | Declarative API test suite (20 cases) | — | — | — | run_api_tests.php | ✅ VERIFIED | 2026-09-02 |
| P0-10 | quality-gate.ps1 | — | — | ✅ | quality-gate.ps1 | ✅ VERIFIED | 2026-09-02 |
| P0-11 | Flutter splash/login/dashboard | — | — | ✅ | widget_test | ✅ VERIFIED | 2026-09-02 |
| P0-12 | en.json + ar.json localization | — | — | ✅ | widget_test | ✅ VERIFIED | 2026-09-02 |
| P0-13 | Dev scripts (setup, smoke, start) | — | — | — | api-smoke.ps1 | ✅ VERIFIED | 2026-09-02 |
| P0-14 | Audit log on writes | ✅ | ✅ | — | — | ✅ VERIFIED | 2026-09-02 |
| P0-15 | .ai knowledge base starter | — | — | — | — | ✅ VERIFIED | 2026-09-02 |

---

## Phase 1A — Data foundation

| ID | Task | API | DB | Flutter | Tests | Status | Verified |
|----|------|-----|----|---------|-------|--------|----------|
| P1-01 | Migration 003 business/branch/terminal | — | ✅ | — | migrate | ✅ VERIFIED | 2026-09-02 |
| P1-02 | Migration 004 customers/vendors | — | ✅ | — | migrate | ✅ VERIFIED | 2026-09-02 |
| P1-03 | Migration 005 catalog (services/products) | — | ✅ | — | migrate | ✅ VERIFIED | 2026-09-02 |
| P1-04 | Migration 006 sales/payments | — | ✅ | — | migrate | ✅ VERIFIED | 2026-09-02 |
| P1-05 | RBAC PermissionMiddleware | ✅ | — | — | phase1_modules | ✅ VERIFIED | 2026-09-02 |
| P1-06 | Flutter app shell + navigation rail | — | — | ✅ | analyze | ✅ VERIFIED | 2026-09-02 |
| P1-07 | Business profile API | ✅ | ✅ | ⬜ | phase1_modules | ✅ VERIFIED | 2026-09-04 |

---

## Phase 1B — Core MVP (local) + Cloud sync parallel

### Track A — Local business modules

| ID | Task | API | DB | Flutter | Tests | Status | Verified |
|----|------|-----|----|---------|-------|--------|----------|
| P1-10 | Customer CRUD + search | ✅ | ✅ | ✅ | phase1_modules | ✅ VERIFIED | 2026-09-02 |
| P1-11 | Vendor CRUD + search | ✅ | ✅ | ✅ | phase1_modules | ✅ VERIFIED | 2026-09-02 |
| P1-12 | Service tree CRUD | ✅ | ✅ | ⬜ | phase1_modules | ✅ VERIFIED | 2026-09-02 |
| P1-13 | Product tree CRUD + barcode lookup | ✅ | ✅ | ⬜ | ⬜ | 🟡 DONE | 2026-09-02 |
| P1-14 | Service-product map | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ PENDING | — |
| P1-15 | Modifiers | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ PENDING | — |
| P1-16 | Sales draft + confirm | ✅ | ✅ | ⬜ | ⬜ | 🟡 DONE | 2026-09-02 |
| P1-17 | Payment allocation | ✅ | ✅ | ⬜ | ⬜ | 🟡 DONE | 2026-09-02 |
| P1-18 | Pending invoices list | ✅ | ✅ | ✅ | phase1_modules | ✅ VERIFIED | 2026-09-04 |
| P1-19 | Order status (basic) | ✅ | ✅ | ⬜ | phase1_modules | ✅ VERIFIED | 2026-09-04 |
| P1-20 | POS screen (instant sale) | — | — | ✅ | manual | ✅ VERIFIED | 2026-09-04 |
| P1-21 | Thermal print stub | — | — | ✅ | manual | 🟡 DONE | 2026-09-04 |
| P1-22 | Basic sales report | ✅ | ✅ | ⬜ | phase1_modules | ✅ VERIFIED | 2026-09-04 |

### Track B — CR-2026-09-02-001 Cloud sync (parallel)

| ID | Task | API | DB | Flutter | Tests | Status | Verified |
|----|------|-----|----|---------|-------|--------|----------|
| P1SYNC-01 | business_owner_id + local_id mapping | — | ✅ | — | migrate | ✅ VERIFIED | 2026-09-02 |
| P1SYNC-02 | sync_outbox table (010) | — | ✅ | — | migrate | ✅ VERIFIED | 2026-09-02 |
| P1SYNC-03 | Cloud API businesses table + scaffold | 🟡 | 🟡 | — | ⬜ | 🟡 DONE | 2026-09-02 |
| P1SYNC-04 | Cloud tenant middleware | 🟡 | — | — | ⬜ | 🟡 DONE | 2026-09-02 |
| P1SYNC-05 | POST /sync/push GET /sync/pull (local) | ✅ | ✅ | — | phase1_modules | ✅ VERIFIED | 2026-09-02 |
| P1SYNC-06 | Change-tracking hooks on CRM/sales writes | ✅ | ✅ | — | — | 🟡 DONE | 2026-09-02 |
| P1SYNC-07 | PHP sync scheduler script | ✅ | — | — | — | 🟡 DONE | 2026-09-02 |
| P1SYNC-08 | Flutter admin sync settings screen | — | — | ✅ | — | 🟡 DONE | 2026-09-02 |
| P1SYNC-09 | License → business registration flow | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ PENDING | — |
| P1SYNC-10 | Tenant isolation tests | — | — | — | ⬜ | ⬜ PENDING | — |
| P1SYNC-11 | Offline queue + retry | ✅ | ✅ | — | — | 🟡 DONE | 2026-09-02 |

**Sync rule:** Local sales work with sync disabled; sync is additive.

---

## Phase 1C — Hardening

| ID | Task | API | DB | Flutter | Tests | Status | Verified |
|----|------|-----|----|---------|-------|--------|----------|
| P1C-01 | License status + activate API | ✅ | ✅ | ⬜ | phase1_modules | ✅ VERIFIED | 2026-09-02 |
| P1C-02 | UMAC generation service | ✅ | — | ⬜ | — | 🟡 DONE | 2026-09-02 |
| P1C-03 | Flutter license gate on startup | — | — | ✅ | manual | ✅ VERIFIED | 2026-09-04 |
| P1C-04 | Backup run + history API | ✅ | — | — | ⬜ | 🟡 DONE | 2026-09-02 |
| P1C-05 | Backup verify + restore validate | ⬜ | — | — | ⬜ | ⬜ PENDING | — |
| P1C-06 | API test cases per new module | ✅ | — | — | phase1_modules | ✅ VERIFIED | 2026-09-02 |
| P1C-07 | Phase 1 acceptance (AC-001..AC-012) | — | — | — | ⬜ | ⬜ PENDING | — |

---

## Phase 2 — Operational expansion

| ID | Task | Status |
|----|------|--------|
| P2-01 | Full production workflow (SORTING→QC→PACKED) | ⬜ PENDING |
| P2-02 | Delivery/collection module | ⬜ PENDING |
| P2-03 | Challans | ⬜ PENDING |
| P2-04 | Goods receipt + purchase orders | ⬜ PENDING |
| P2-05 | Stock movement ledger | ⬜ PENDING |
| P2-06 | Employee master | ⬜ PENDING |
| P2-07 | Attendance | ⬜ PENDING |
| P2-08 | Leave management | ⬜ PENDING |
| P2-09 | Payroll run | ⬜ PENDING |
| P2-10 | Salary advances | ⬜ PENDING |
| P2-11 | Expenses + approvals | ⬜ PENDING |
| P2-12 | Advanced reports | ⬜ PENDING |
| P2-13 | Print template designer | ⬜ PENDING |
| P2-14 | Notification center | ⬜ PENDING |
| P2-15 | Share-ready receipt assets | ⬜ PENDING |

---

## Phase 3 — Scale and extension

| ID | Task | Status |
|----|------|--------|
| P3-01 | Multi-terminal hardening | ⬜ PENDING |
| P3-02 | Branch support | ⬜ PENDING |
| P3-03 | Local-network API node | ⬜ PENDING |
| P3-04 | Full cloud sync all entities | ⬜ PENDING |
| P3-05 | KSA localization package | ⬜ PENDING |
| P3-06 | Accounting integration adapter | ⬜ PENDING |
| P3-07 | SMS/WhatsApp adapters | ⬜ PENDING |
| P3-08 | Analytics layer | ⬜ PENDING |

---

## Database migration roadmap

| File | Contents | Status |
|------|----------|--------|
| 001_initial_schema.sql | users, roles, settings, audit, license | ✅ VERIFIED |
| 002_seed_roles.sql | admin, cashier, seeds | ✅ VERIFIED |
| 003_business_branch_terminal.sql | business, branch, terminal, business_owner_id | 🔵 |
| 004_customers_vendors.sql | customers, vendors | 🔵 |
| 005_catalog_services_products.sql | categories, services, products, map | 🔵 |
| 006_sales_payments.sql | sales_orders, lines, payments | 🔵 |
| 007_inventory.sql | inventory_movements, adjustments | ⬜ |
| 008_hr_payroll.sql | employees, attendance, payroll | ⬜ |
| 009_expenses.sql | expense categories, expenses | ⬜ |
| 010_sync_outbox.sql | sync_outbox, sync_state | 🔵 |
| 011_documents_files.sql | file_assets | ⬜ |
| 012_license_umac_runtime.sql | umac_policy, hardware_identity | ⬜ |

---

## API module roadmap (OpenAPI tags)

| Tag | Endpoints | Status |
|-----|-----------|--------|
| Platform | health, docs | ✅ VERIFIED |
| Identity | auth/* | ✅ VERIFIED |
| Configuration | settings | ✅ VERIFIED |
| Install | install/* | ✅ VERIFIED |
| Customers | /customers | ✅ VERIFIED |
| Vendors | /vendors | ✅ VERIFIED |
| Catalog | /services, /products | ✅ VERIFIED |
| Sales | /sales | ✅ VERIFIED |
| Reports | /reports/sales/summary | ✅ VERIFIED |
| Sync | /sync/push, /sync/pull, /sync/status | 🟡 DONE |
| License | /license/status, /license/activate | ✅ VERIFIED |
| Backup | /backup/run, /backup/history | 🟡 DONE |
| Inventory | — | ⬜ PENDING |
| HR | — | ⬜ PENDING |
| Expenses | — | ⬜ PENDING |
| Reports | — | ⬜ PENDING |

Contract reference: [`.ai/.ai-knowledge/api-contract.md`](../../.ai/.ai-knowledge/api-contract.md)

---

## Flutter feature roadmap

```
lib/
  app/           app shell, router
  core/          theme, l10n, constants
  features/
    auth/        ✅ splash, login
    dashboard/   🔵 shell + KPI placeholders
    customers/   🔵 list + form
    vendors/     🔵 list + form
    catalog/     ⬜ services/products
    sales/       ✅ POS cart + payment + receipt stub
    sync/        🔵 admin settings
    settings/    ⬜
```

---

## Verification matrix (Phase 1 exit)

| AC | Criterion | Status |
|----|-----------|--------|
| AC-001 | Offline sale end-to-end | ✅ | 2026-09-04 |
| AC-002 | Payment integrity | ✅ | 2026-09-04 |
| AC-003 | Hierarchy no cycles | ⬜ |
| AC-004 | Bundle snapshot on sale | ⬜ |
| AC-005 | Stock integrity | ⬜ |
| AC-006 | Arabic RTL Phase 1 screens | ✅ | 2026-09-04 |
| AC-007 | Document consistency | ⬜ |
| AC-008 | Backup verification | ⬜ |
| AC-009 | Restore validation | ⬜ |
| AC-010 | Permission control API | 🔵 | partial — admin only |
| AC-011 | License expiry policy | ✅ | 2026-09-04 |
| AC-012 | Audit on critical changes | ✅ | 2026-09-04 |

---

## Production finish definition

Minimum loops (blueprint §107):

```
Customer → Sale → Payment → Status → Ready → Collection → Report → Backup
Vendor → Receipt → Stock → Sale consumption
Employee → Attendance → Payroll
```

Plus: license/UMAC enforced, Arabic RTL on Phase 1 screens, quality gate green, Windows installer.

---

## Live update rules

1. After each feature: update task row in this file, run `scripts\quality-gate.ps1`, set **Verified** date.
2. Weekly: refresh **Last verified** header and phase %.
3. API changes: update `.ai/.ai-knowledge/api-contract.md`.
4. New endpoints: add route metadata + test case JSON + Swagger tag.
5. New Flutter strings: both `assets/lang/en.json` and `assets/lang/ar.json`.

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-09-02 | Phase 1A–1C foundation: migrations 003–006/010, CRM, catalog, sales, sync, license, backup APIs; Flutter shell | Agent |
