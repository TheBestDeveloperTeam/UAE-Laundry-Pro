# Workflow traceability matrix — LaundryPro UAE v2.0

**Date:** 2026-10-15 | **Status:** Baseline after re-audit | **Evidence:** [POST_UAT_REAUDIT_2026-10.md](POST_UAT_REAUDIT_2026-10.md)

Columns: **Workflow_ID** | **UC_or_Agent** | **User_Persona** | **API_Endpoints** | **Flutter_Screen** | **Test_File** | **Status**

---

## 1. Blueprint use cases (UC-01 … UC-15)

| Workflow_ID | UC_or_Agent | User_Persona | API_Endpoints | Flutter_Screen | Test_File | Status |
|-------------|-------------|--------------|---------------|----------------|-----------|--------|
| WF-UC-01 | UC-01 Boot | Cashier | `GET /api/v1/health`, install/migrate hooks | `splash` | `router_test.dart` | Pass |
| WF-UC-02 | UC-02 Walk-in sale | Cashier | `POST /api/v1/sales`, payments | `pos_screen` | `phase2_workflow_test.dart` | Pass |
| WF-UC-03 | UC-03 Customer search | Cashier | `GET /api/v1/customers` | `customers_screen` | `run_api_tests.php` | Pass |
| WF-UC-04 | UC-04 Modifiers | Cashier | services/modifiers | `pos_screen` | `phase2_workflow_test.dart` | Pass |
| WF-UC-05 | UC-05 Production | Operator | orders status | `production_screen` | `run_api_tests.php` | Pass |
| WF-UC-06 | UC-06 Challan | Dispatcher | `POST /api/v1/challans` | `challans_screen` | `phase2_workflow_test.dart` | Pass |
| WF-UC-07 | UC-07 Delivery | Driver | `delivery-tasks` | `delivery_screen` | `run_api_tests.php` | Pass |
| WF-UC-08 | UC-08 HR/WPS | HR | payroll, attendance | `employees_screen` | `phase2_hr_test.dart` | Pass |
| WF-UC-09 | UC-09 UMAC | System | `license/*` | `license_screen` | `run_api_tests.php` | Pass |
| WF-UC-10 | UC-10 Sync | Background | `sync/push`, `sync/pull` | sync provider | `sync_engine_test.dart` | Pass |
| WF-UC-11 | UC-11 Split pay | Cashier | sales payments multi-tender | `pos_screen` | `run_api_tests.php` | Pass |
| WF-UC-12 | UC-12 Refund | Manager | invoices correction | `sales_screen` | `run_api_tests.php` | Pass |
| WF-UC-13 | UC-13 Shift close | Supervisor | reports shift | `reports_screen` | `phase2_workflow_test.dart` | Pass |
| WF-UC-14 | UC-14 Low stock | Manager | inventory, purchasing | `inventory_screen` | `phase3_service_test.dart` | Pass |
| WF-UC-15 | UC-15 Onboarding | Super-Admin | install, settings, business | `setup_wizard` | `run_api_tests.php` | Pass |

---

## 2. API domains (cloud route parity script)

| Workflow_ID | UC_or_Agent | User_Persona | API_Endpoints | Test_File | Status |
|-------------|-------------|--------------|---------------|-----------|--------|
| WF-DOM-* | 35 domains in `verify_route_parity.php` | JWT tenant user | `/api/v1/{domain}/*` | `run_api_tests.php` + `openapi_drift_test.php` | Pass (integration); cloud live deploy **pending** |

Install/Setup and RFID/LAN on cloud: **0 routes** (intentional parity). Deploy automation: `POST /api/v1/internal/deploy/*` (token-gated; swagger `x-internal`).

---

## 3. RBAC personas (unique users)

| Persona | Role seed | Representative workflow | Test_File | Status |
|---------|-----------|-------------------------|-----------|--------|
| Administrator | `administrator` | Settings + reports | `run_api_tests.php` (auth suite) | Pass |
| Cashier | `cashier` | POS sale | `run_api_tests.php` | Pass |
| Manager | `manager` | Refund / shift | `run_api_tests.php` | Pass |
| Storekeeper | `storekeeper` | Inventory GRN | `run_api_tests.php` | Pass |
| HR | `hr` | Payroll | `phase2_hr_test.dart` | Pass |
| Auditor | `auditor` | Read-only reports | `run_api_tests.php` | Pass |
| Cloud Super-Admin | `cloud_super_admins` | License / tenant console | cloud routes (when deployed) | **Amber** — prior build live; deploy routes pending extract |

---

## 4. Specialist agents (~49) — verification obligations

Mapped to [.ai/UNIFIED_AI_LOGICS.md](../../.ai/UNIFIED_AI_LOGICS.md) department specialists (48) + **Chief Architect** (49). Each row is the **audit obligation**, not a runnable agent.

| Dept | Specialist focus | Obligation | Automated check | Status |
|------|------------------|------------|-----------------|--------|
| Engineering (9) | API, sync, deploy | Route registry + deploy smoke | `openapi_drift_test.php`, `deploy_automation_smoke_test.php` | Pass |
| Quality (6) | Regression | Flutter + API suites | `flutter test`, `run_api_tests.php` | Pass |
| Product (5) | UC coverage | UC-01…15 matrix | This document | Pass |
| Data (5) | Schema | Migrations 001–003 local/cloud | `deploy.php`, migration SQL | Pass |
| Operations (5) | Deploy/FTP | cPanel docroot + zip extract | `cloud_ftp_deploy.php`, `cloud_live_smoke.ps1` | **Amber** — health 200; apply/bootstrap 404 until zip extract |
| Security (4) | Token/RBAC | Deploy token + JWT | `DeployAutomationController`, auth tests | Pass local |
| HR (2) | WPS | Payroll endpoints | `phase2_hr_test.dart` | Pass |
| Finance (3) | VAT/immutable invoices | Sales/invoices API | `run_api_tests.php` | Pass |
| Marketing (4) | Storefront | storefront routes | `run_api_tests.php` | Pass |
| Legal (2) | PDPL/audit | audit middleware | `AUDIT_SECURITY.md` review | Pass |
| R&D (3) | Sterilization/RFID | cycles, rfid local | sprint tests in `run_api_tests.php` | Pass |
| Chief Architect (1) | Parity | Local ↔ cloud domain set | `verify_route_parity.php` | Pass |

---

## 5. Sentinel bots (LP-BOT-*)

| Bot | Workflow_ID | Check | Status |
|-----|-------------|-------|--------|
| LP-BOT-MONEY | WF-BOT-MONEY | DECIMAL/bcmath in API tests | Pass |
| LP-BOT-TENANT | WF-BOT-TENANT | Tenant scope on cloud reports | C14 TSK-1.4 |
| LP-BOT-SYNC | WF-BOT-SYNC | Sync outbox tests | `sync_engine_test.dart` |
| LP-BOT-MIGRATE | WF-BOT-MIGRATE | Migration 003 parity | SQL files present |
| LP-BOT-RBAC | WF-BOT-RBAC | Auth integration tests | `run_api_tests.php` |

---

## 6. Gaps (explicit)

| Gap | Owner action |
|-----|----------------|
| Live cloud HTTP apply | cPanel docroot or extract zip |
| E2E Flutter UI offline | AUDIT_TESTING G-031 (optional) |
| PHPUnit migration | AUDIT_TESTING G-032 (optional) |
