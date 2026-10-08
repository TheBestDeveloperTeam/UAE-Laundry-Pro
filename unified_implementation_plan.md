# LaundryPro UAE — C15: Unified Implementation Plan

> **Date:** 2026-10-07 | **Status:** ✅ ACTIVE BLUEPRINT
> **Author:** Project Delivery Production Manager

This document serves as the master execution blueprint derived from the exhaustive 14-part architectural audit of the LaundryPro UAE system. It consolidates all 47 findings into actionable, prioritized sprints.

---

## 1. Audit Statistics & Readiness Assessment

| Metric | Count | Description |
|:-------|:------|:------------|
| **Total Findings** | 47 | Across Database, APIs, Sync, Flutter, Security, Hardware, and QA. |
| **P0 Blockers** | 3 | Critical security and architectural flaws that break the offline-first mandate. |
| **P1 Blockers** | 15 | Major missing features or incomplete integrations (Sync, UI, Portals). |
| **P2 Tech Debt** | 29 | Testing, QA, CI/CD, Documentation, and minor routing duplications. |
| **Readiness** | **RED** | The codebase requires immediate execution of Sprint 1 (P0/P1) before any QA or UAT. |

---

## 2. Sprint 1: Critical Path (P0 & P1 Remediation)

*This sprint must be executed immediately. It addresses all architectural blockers.*

### Epic 1: The Sync Engine & Data Consistency
*Targeting: F-031, F-032, F-038*
- **Task 1.1 [F-031]:** Re-engineer the Cloud API's `SyncController@push`. It currently only writes to `sync_records`. It must actually unpack the JSON payload and execute `INSERT / UPDATE` statements on the target tables (Sales, Inventory, etc.).
- **Task 1.2 [F-032]:** Implement `PULL` logic in the Local API's `sync_scheduler.php`. The POS must be able to pull remote configuration changes down from the Cloud.
- **Task 1.3 [F-038]:** Modify the Sync Engine to include `audit_logs` in the synchronization payload to ensure the Cloud Super-Admin has full visibility over local POS mutations.

### Epic 2: Security & Licensing
*Targeting: F-035, F-036, F-016*
- **Task 2.1 [F-035] (P0):** Fix the **Blind Activation Bypass**. The Local API currently activates simply by receiving a key. It MUST cryptographically verify the key's signature using the Cloud API's public RSA key.
- **Task 2.2 [F-036]:** Implement a Windows OS Registry write-once guard for the activated license key to prevent horizontal tenant cloning.
- **Task 2.3 [F-016]:** Add explicit CORS headers to the Local API to secure LAN traffic from malicious web origins.

### Epic 3: API Parity & Routing Strictness
*Targeting: F-022, F-023, F-019, F-020, F-029*
- **Task 3.1 [F-022] (P0):** Strip all Local-only hardware routes (`/lan`, `/rfid`) from the Cloud API router (`routes/api.php`).
- **Task 3.2 [F-023] (P0):** Strip the Installation Wizard endpoints (`/install`) from the Cloud API.
- **Task 3.3 [F-019, F-020, F-029]:** Add missing Super-Admin routing to the Cloud API for License approval (`/api/v1/license/approve`), revoking, and Web Portal Controllers.

### Epic 4: Frontend & Portals
*Targeting: F-025, F-028, F-040, F-041*
- **Task 4.1 [F-025]:** Implement the missing `InventoryScreen.dart` and bind it to the `/inventory` route in Flutter.
- **Task 4.2 [F-028]:** Create the missing `local-portal` directory. The entire PHP AdminLTE HTML dashboard for the Local POS manager is missing from the repository.
- **Task 4.3 [F-040, F-041]:** Replace `DummyRfidAdapter` with real Serial FFI logic in Flutter. Implement real Twilio API cURL logic in `TwilioSmsAdapter` to stop blackholing SMS messages.

---

## 3. Sprint 2: Hardening, QA, & Polish (P2 Remediation)

*This sprint stabilizes the platform for production deployment.*

### Epic 5: Refactoring & Parity
- **Task 5.1 [F-001]:** Create a shared composer package (`laundrypro-core`) to house the Kernel, AuthMiddleware, and Sync schemas to eliminate duplicate code between Local and Cloud APIs.
- **Task 5.2 [F-004, F-014]:** Consolidate `ReportController` and `ReportsController`.
- **Task 5.3 [F-015]:** Move inline controller validation into dedicated `Validator` classes (or `FormRequest` equivalents).

### Epic 6: Testing & QA Architecture
- **Task 6.1 [F-044]:** Migrate all custom `assert()` PHP tests (e.g. `jwt_test.php`) to PHPUnit. Create a `phpunit.xml`.
- **Task 6.2 [F-043]:** Write Flutter `integration_test` E2E scripts to simulate UI behavior during network drops (Offline Mode UX).
- **Task 6.3 [F-045]:** Create `k6` load testing scripts to stress-test the `sync_outbox` concurrency limits.

### Epic 7: DevOps & Deployment
- **Task 7.1 [F-046]:** Write a `docker-compose.yml` for the Cloud API to orchestrate the PHP-FPM container alongside MariaDB and Nginx.
- **Task 7.2 [F-047]:** Update the Windows `setup-task-scheduler.ps1` to include a daily chron-trigger for database backups (`BackupService.php`).

---

## 4. Execution Mandate

The development team is hereby authorized to commence **Sprint 1 (Critical Path)**.

**Rules of Engagement:**
1. Do not push to Git until a task is completely verified locally.
2. Adhere strictly to the "No Third-Party PHP Framework" (AC-1) constraint when fixing the APIs.
3. Validate all changes against the `UNIFIED_SWAGGER.yaml` OpenAPI spec.

> *"Fix the foundation before painting the walls. Execute Sprint 1."*
