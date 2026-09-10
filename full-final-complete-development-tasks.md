# LaundryPro UAE — Full, Final & Complete Development Tasks (Sprint-Wise)

> **Source Documents:** `LaundryPro UAE — README.md` (v1 Master Spec) + `LaundryPro UAE — Full & Final Production Audit, Correction & Implementation Roadmap` (v1.2.1+4 Audit)
> **Purpose:** Zero-data-loss, zero-omission consolidated task backlog covering every Critical Gap (CG), High-Priority Correction (HC), Database Gap (DB), Documentation Gap, Cloud Portal Spec item, and Backlog item (R-001–R-050) from the audit, organized into executable, sprint-wise, in-depth development tasks.
> **Scope Baseline:** Sprints 29 → 33 (post-audit remediation + production launch), inclusive of all sub-tasks required to reach the Final Quality Gate (README §32.10).
> **Traceability Rule:** Every task below is tagged with its source ID (`CG-xx`, `HC-xx`, `DB-xx`, `R-0xx`, `Doc-xx`, `Cloud-xx`) so nothing from the audit is lost or re-interpreted.

---

## 📌 How to Use This Document

- Each **Sprint** = 1 section, broken into **Epics → Tasks → Sub-Tasks → Acceptance Criteria**.
- Every task carries: **Source ID**, **Owner Track** (Backend/Frontend/DB/DevOps/QA/Cloud), **Estimate (days)**, **Dependencies**, **Definition of Done**.
- Nothing is summarized away — every backlog line item (R-001 to R-050), every Critical Gap (CG-01 to CG-08), every High Correction (HC-01 to HC-05), every DB gap (DB-01 to DB-04), every Documentation gap, and the full Cloud Super-Admin Portal spec are represented as executable tasks.
- Sprint 33 ends with the **Final Quality Gate Checklist** (README §32.10) mapped 1:1 to verification tasks.

---

## 🗓️ SPRINT OVERVIEW TABLE

| Sprint | Focus | Duration | Primary Source IDs |
|---|---|---|---|
| **Sprint 29** | UI System Unification + POS/Dashboard/Login UX | 2 weeks | HC-01 to HC-05, R-011 to R-030 |
| **Sprint 30** | Database Hardening + Security + Backup/Sync Fixes | 2 weeks | CG-01, CG-05, CG-06, CG-07, DB-01 to DB-04, R-001 to R-010, R-031 to R-037 |
| **Sprint 31** | Automated Testing (Backend + Frontend + Integration + Hardware Mocks) | 1.5 weeks | CG-02, R-038 to R-041 |
| **Sprint 32** | Cloud Super-Admin Portal + Integrations + Localization | 3 weeks | CG-03, Cloud Portal Spec, R-042 to R-049, Doc gaps |
| **Sprint 33** | Production Launch (Installer, Packaging, Sign-off) | 1 week | CG-04, CG-08, R-007, R-009, R-050, Final Quality Gate |

---

# 🚀 SPRINT 29 — UI System Unification (2 Weeks)

**Goal:** Eliminate hardcoded UI values, build the reusable design system, and close all POS/Dashboard/Login UX gaps (HC-01 to HC-05) plus their associated backlog items (R-011 to R-030).

## Epic 29.1 — Design Token & Theme System (HC-01, R-011, R-012, R-013)

### Task 29.1.1 — Typography System
- **Source:** HC-01, R-011 | **Track:** Frontend | **Estimate:** 0.5d
- Add `Poppins` font family for LTR (en-AE) and `Cairo` font family for RTL (ar-AE) as bundled assets in `pubspec.yaml` (`fonts:` section, all weights: Regular, Medium, SemiBold, Bold).
- Implement full `TextTheme` in `lib/core/theme.dart`:
  - `headlineLarge` → 28px / Bold / Poppins (or Cairo when RTL)
  - `headlineMedium` → 22px / Bold
  - `headlineSmall` → 18px / SemiBold
  - `titleLarge` → 16px / SemiBold
  - `bodyLarge` → 15px / Regular
  - `bodyMedium` → 13px / Regular
  - `bodySmall` → 11px / Regular / Grey
- Build a `FontResolver` utility that returns the correct family based on active `Locale`.
- **DoD:** No screen renders with Flutter's default `Roboto` fallback; verified visually in both locales.

### Task 29.1.2 — Dark Mode Theme Variant
- **Source:** HC-01, R-012 | **Track:** Frontend | **Estimate:** 1d
- Define `ThemeData.dark()` counterpart inside `AppTheme` (`lib/core/theme.dart`) mirroring the light theme's structure.
- Add a `ThemeModeProvider` (Riverpod) persisting user choice (Light/Dark/System) to local settings table.
- Add a theme toggle to Setup → Preferences screen.
- **DoD:** Every screen (Login, Dashboard, POS, Orders, Customers, Inventory, HR, Reports, Setup) renders correctly in dark mode with no illegible contrast pairs.

### Task 29.1.3 — Semantic Color Tokens
- **Source:** HC-01, R-013 | **Track:** Frontend | **Estimate:** 0.5d
- Add semantic color constants to `AppColors`:
  - `success = #2E7D32`, `warning = #F57C00`, `danger = #C62828`, `info = #1565C0`, `pending = #546E7A`, `neutral = #ECEFF1`
- Extend `ThemeExtension<AppSemanticColors>` so tokens are theme-aware (auto-adjust for dark mode) and accessible via `Theme.of(context).extension<AppSemanticColors>()`.
- Replace all ad-hoc inline `Color(0xFF...)` usages across the codebase for status/severity indicators with the semantic tokens.
- **DoD:** Grep for raw hex color literals outside `theme.dart` returns zero results in status-related widgets.

### Task 29.1.4 — Supplementary Theme Components
- **Source:** HC-01 | **Track:** Frontend | **Estimate:** 0.5d (folded into 29.1.1–29.1.3 estimate buffer)
- Add `DividerThemeData`, `TooltipThemeData`, `SnackBarThemeData`, `DialogThemeData` to both light and dark `ThemeData`.
- **DoD:** All snackbars, dialogs, tooltips, dividers pull from theme, zero inline `Divider(color: ...)` style overrides remain.

## Epic 29.2 — Reusable Widget Library (R-014, R-015, R-016, R-017, R-018)

### Task 29.2.1 — `StatusBadge` Widget
- **Source:** R-014 | **Track:** Frontend | **Estimate:** 0.5d
- Build a pill-shaped badge widget accepting `status` enum (Received/Processing/Ready/Delivered/Cancelled/Held/Overdue/Paid/PartiallyPaid/Unpaid) and mapping to semantic colors from 29.1.3.
- Support icon + text and icon-only compact mode (for table cells).
- **DoD:** Used consistently across Orders list, POS cart lines, Delivery board, Payment status column.

### Task 29.2.2 — `EmptyState` Widget
- **Source:** R-015 | **Track:** Frontend | **Estimate:** 0.5d
- Build a reusable empty-state component (illustration/icon + headline + subtext + optional CTA button), localized via JSON label keys (README Critical Rule: no hardcoded UI strings).
- **DoD:** Applied to Orders, Customers, Inventory, Reports, Notifications, Search-results-empty scenarios.

### Task 29.2.3 — `AppFormDialog` Standard Wrapper
- **Source:** R-016 | **Track:** Frontend | **Estimate:** 1d
- Build a generic modal dialog wrapper supporting: title bar, scrollable form body, footer action buttons, built-in **loading overlay** state, built-in **inline error banner** state, Esc-to-close, and focus trap.
- **DoD:** Exposes a simple API (`AppFormDialog(title:, isLoading:, errorMessage:, child:, actions:)`) ready for 29.2.5 migration.

### Task 29.2.4 — `AppDataTable` Widget
- **Source:** R-017 | **Track:** Frontend | **Estimate:** 2d
- Build a generic sortable, paginated data table component:
  - Column sort (asc/desc) with sort-indicator icons
  - Server-side or client-side pagination toggle
  - Row density toggle (compact/comfortable)
  - Sticky header row
  - RTL-aware column ordering
- **DoD:** Replaces bespoke `DataTable` implementations in Orders, Customers, Products, Inventory, Employees, Purchase Orders, Expenses list screens.

### Task 29.2.5 — Global Error Widget Builder
- **Source:** R-018 | **Track:** Frontend | **Estimate:** 0.5d
- Register `ErrorWidget.builder` in `main.dart` to render a friendly, branded fallback screen (not Flutter's red error box) in release mode, while preserving full stack trace logging to the diagnostic/support export (README §14, §23).
- **DoD:** Forced widget-build exception in a debug harness renders the branded fallback in release builds; debug builds still show full red-box detail.

### Task 29.2.6 — Standardize All Form Dialogs onto `AppFormDialog`
- **Source:** R-020 | **Track:** Frontend | **Estimate:** 2d
- Migrate every existing modal/form dialog (Customer create/edit, Product/Service create/edit, Employee create/edit, Expense entry, Purchase Order entry, Payment collection, Backup schedule, Settings sub-forms) to use `AppFormDialog` from Task 29.2.3.
- **DoD:** Zero bespoke dialog scaffolds remain outside `AppFormDialog`; loading/error states consistent app-wide.

## Epic 29.3 — RTL & Localization Fixes (HC-02, R-019)

### Task 29.3.1 — Directionality Wrapping & Nav Rail Mirroring
- **Source:** HC-02, R-019 | **Track:** Frontend | **Estimate:** 1d
- Wrap the app body (`app_shell.dart`) in a `Directionality` widget bound to the active `Locale`'s text direction.
- Fix `NavigationRail` to mirror to the right edge when `ar-AE` is active (currently stays left per HC-02).
- Remove the fixed `88px` width; make nav rail width responsive/label-aware so Arabic labels do not clip or overflow.
- Add `Tooltip` widgets to every nav icon for accessibility (English + Arabic tooltip text from JSON label store).
- **DoD:** Full app tested end-to-end in `ar-AE`: nav rail on right, all icons tooltip-accessible, no RTL layout breakage on any screen.

## Epic 29.4 — Login Screen UX Polish (HC-03, R-030)

### Task 29.4.1 — Specific Auth Failure Messaging
- **Source:** HC-03 | **Track:** Frontend + Backend | **Estimate:** included below
- Update login API error contract to return a distinguishable `error_code` (e.g., `INVALID_CREDENTIALS`, `ACCOUNT_LOCKED`, `LICENSE_EXPIRED`, `RATE_LIMITED`) instead of a generic failure string.
- Map each `error_code` to a localized, user-friendly message + icon on the login screen.

### Task 29.4.2 — Focus Chain, Enter Submit, Rate-Limit Countdown
- **Source:** HC-03, R-030 | **Track:** Frontend | **Estimate:** 0.25d
- Add explicit `FocusNode` chaining: Tab order = Username → Password → Submit.
- Bind Enter key on both fields to trigger form submission.
- After 5 failed attempts (aligned with backend rate-limit in R-031), display a live countdown timer (mm:ss) disabling the submit button until the lockout window expires, sourced from the `RATE_LIMITED` response's `retry_after_seconds`.
- **DoD:** Manual QA script: 5 failed logins → countdown UI appears and matches backend lockout duration exactly.

## Epic 29.5 — POS Screen Critical Workflow Gaps (HC-04, R-021 to R-025)

### Task 29.5.1 — VAT Rate from Settings
- **Source:** HC-04, R-025 | **Track:** Frontend + Backend | **Estimate:** 0.5d
- Remove hardcoded `0.05` from `CartLine.vatAmount` calculation.
- Fetch VAT rate from the `settings` table via `SettingsRepository` (already flagged in DB-01 for `reference_id` column) and cache in `PosCartProvider` at session start; re-fetch on settings change broadcast.
- **DoD:** Changing VAT rate in Setup → Tax Settings reflects on next POS cart calculation without app restart.

### Task 29.5.2 — In-POS Customer Quick-Search
- **Source:** HC-04, R-022 | **Track:** Frontend | **Estimate:** 1d
- Add an inline searchable customer combo-box directly in the POS customer panel (search by name/phone/customer code) with "Add New Customer" inline action that opens `AppFormDialog` without leaving POS.
- **DoD:** Cashier can search, select, or create a customer without navigating away from the Instant Sale screen (README §32.5 layout reference).

### Task 29.5.3 — POS Keyboard Shortcuts
- **Source:** HC-04, R-021 | **Track:** Frontend | **Estimate:** 1d
- Bind global `Shortcuts`/`Actions` on the POS screen: `F1` = New Order, `F2` = Payment, `F3` = Print, `Esc` = Cancel/Close active dialog.
- Add a small on-screen legend (togglable via `?` icon) listing active shortcuts.
- **DoD:** All four shortcuts function identically to their corresponding on-screen buttons; no conflicts with text-field input focus.

### Task 29.5.4 — Void/Refund Button Visibility
- **Source:** HC-04 | **Track:** Frontend | **Estimate:** included in 29.5.3 estimate buffer
- Surface a clearly visible Void/Refund action on the POS action bar (README §32.5), gated by RBAC permission (`pos.void`, `pos.refund`).
- **DoD:** Button visible only to roles with permission; triggers confirmation dialog before executing.

### Task 29.5.5 — Order Hold/Park Functionality
- **Source:** HC-04, R-024 | **Track:** Frontend + Backend | **Estimate:** 1d
- Add "Hold" action storing the current cart as a `status='held'` draft order (append-only ledger rule respected — no destructive overwrite).
- Add a "Held Orders" quick-access panel/drawer to resume a parked cart.
- **DoD:** Cart can be held, POS screen cleared for next customer, held order resumable with full line-item and modifier state intact.

### Task 29.5.6 — Cash Change Calculator
- **Source:** HC-04, R-023 | **Track:** Frontend | **Estimate:** 0.5d
- Add a change-due calculator to the payment dialog: cashier enters tendered amount, system computes and displays change in real time, with quick-tender preset buttons (e.g., round AED denominations).
- **DoD:** Deterministic decimal arithmetic (README G2) — no floating-point rounding artifacts in change calculation.

### Task 29.5.7 — Debounced Barcode Scan Lookup
- **Source:** HC-04 | **Track:** Frontend | **Estimate:** included in 29.5.6 buffer
- Add debounce (e.g., 150–250ms) to the barcode scanner input handler before triggering product lookup, preventing duplicate/partial-scan lookups during rapid wedge-scanner input bursts.
- **DoD:** Rapid-fire scanning of 10 barcodes in sequence produces exactly 10 correct product-lookup calls, no duplicates/misses.

## Epic 29.6 — Dashboard Live Data & Visual Hierarchy (HC-05, R-026 to R-029)

### Task 29.6.1 — Error State with Retry
- **Source:** HC-05 | **Track:** Frontend | **Estimate:** included below
- Replace raw `'failed'` string error display with the `EmptyState`/error variant component, including a "Retry" button that re-triggers the dashboard data fetch.

### Task 29.6.2 — Auto-Refresh Interval
- **Source:** HC-05, R-026 | **Track:** Frontend | **Estimate:** 0.5d
- Add a `Timer.periodic` (60s) auto-refresh to the Dashboard provider, pausable when the app window loses focus (to avoid unnecessary local API load) and resumable on focus regain.

### Task 29.6.3 — Settings-Driven Currency Formatter
- **Source:** HC-05 | **Track:** Frontend + Backend | **Estimate:** included below
- Remove hardcoded `'AED '` prefix; build a `CurrencyFormatter` utility reading currency code/symbol/decimal-places from the active country/currency profile (README §1 multi-currency architecture: AED/Fils, INR/Paise, USD/Cent, SAR/Halala-ready).

### Task 29.6.4 — Dashboard Quick-Action Buttons
- **Source:** HC-05, R-028 | **Track:** Frontend | **Estimate:** 0.5d
- Add quick-action buttons: "New Order", "New Customer", "View Reports" prominently on the Dashboard, each routing to the respective pre-focused screen/dialog.

### Task 29.6.5 — KPI Card Trend Indicators / Sparklines
- **Source:** HC-05, R-027 | **Track:** Frontend | **Estimate:** 1d
- Add color-coded trend arrows (up/down/flat, using semantic tokens) and a small sparkline mini-chart per KPI card (Revenue, Orders, Avg. Ticket, Pending Payments) showing the trailing 7/30-day trend.
- **DoD:** KPI cards visually communicate direction and magnitude of change at a glance, correctly colored (green=good trend, red=bad trend per KPI semantics).

## Epic 29.7 — API Client Resilience (R-029)

### Task 29.7.1 — Timeout + Auto-Retry on `ApiClient`
- **Source:** R-029 | **Track:** Frontend | **Estimate:** 1d
- Add configurable request timeout (e.g., 10s) to the local `ApiClient` HTTP layer.
- Add auto-retry (max 2 retries, exponential backoff e.g. 500ms/1500ms) for idempotent GET requests only; never auto-retry mutating POST/PUT/DELETE requests to avoid double-submission.
- Surface a clear "Local API unreachable — check XAMPP/Apache" error state distinct from generic network errors.
- **DoD:** Simulated local API downtime produces a clear, actionable error message within timeout window; GET requests transparently retry and succeed once API returns.

## Epic 29.8 — DI Standardization (R-008)

### Task 29.8.1 — Standardize Dependency Injection
- **Source:** R-008 | **Track:** Frontend | **Estimate:** 2d
- Audit all screens/providers for DI pattern usage; resolve the inconsistency where `PosScreen` uses a different DI approach than the rest of the app (Riverpod elsewhere).
- Decision: migrate `PosScreen` fully onto Riverpod (remove any alternate/legacy DI usage) to keep one consistent architecture app-wide per README's MVVM + Repository Pattern.
- **DoD:** `flutter analyze` shows no mixed-DI lint warnings; architecture doc (`.ai/ARCHITECTURE.md`, see Sprint 32 Doc tasks) updated to reflect single DI strategy.

## Sprint 29 — Exit Criteria
- [x] All HC-01 to HC-05 items closed and demoed.
- [x] All R-008, R-011 to R-030 backlog items closed.
- [x] Full regression pass on Login, Dashboard, POS in both `en-AE` and `ar-AE` locales, light and dark themes.

---

# 🔒 SPRINT 30 — Database Hardening + Security (2 Weeks)

**Goal:** Close every Critical Gap related to data integrity, migrations, backup/restore, sync reliability, and security hardening (CG-01, CG-05, CG-06, CG-07, DB-01 to DB-04, R-001 to R-010, R-031 to R-037).

## Epic 30.1 — SQL Migration Infrastructure (CG-01, R-001, DB-01)

### Task 30.1.1 — Create `api/migrations/` Directory Structure
- **Source:** CG-01, R-001 | **Track:** Backend/DB | **Estimate:** 3d total (broken down below)
- Create the missing `api/migrations/` directory (currently referenced by `MigrationService.php` at runtime but does not exist — fresh installs fail, upgrade paths undefined, `seed` command has no baseline).
- Establish numbering convention: `NNN_description.sql` (3-digit, zero-padded, sequential).

### Task 30.1.2 — `001_initial_schema.sql`
- **Source:** CG-01, R-001 | **Track:** DB | **Estimate:** included in 3d total
- Write the full baseline schema covering every entity implied by the README feature set: `users`, `roles`, `permissions`, `role_permissions`, `branches`, `terminals`, `customers`, `vendors`, `service_categories`, `services`, `product_categories`, `products`, `modifiers`, `modifier_groups`, `orders`, `order_lines`, `order_status_history`, `payments`, `payment_allocations`, `inventory_items`, `inventory_movements`, `purchase_orders`, `purchase_order_lines`, `employees`, `attendance`, `leave_requests`, `payroll_runs`, `payroll_lines`, `salary_advances`, `expenses`, `expense_categories`, `deliveries`, `notifications`, `audit_log`, `settings`, `licenses`, `backups`.
- Every table's `CREATE TABLE` statement wrapped `IF NOT EXISTS`.
- All monetary columns declared `DECIMAL(18,2)` (cross-checked against DB-03/R-037, see Task 30.4.2).
- Append-only ledger tables (orders, order_lines, inventory_movements, payments) include no `UPDATE`-friendly design flaws — corrections modeled as reversal/adjustment rows per README §2 Key Differentiators.

### Task 30.1.3 — `002_add_sync_outbox.sql`
- **Source:** CG-01, R-001 | **Track:** DB | **Estimate:** included in 3d total
- Create `sync_outbox`, `sync_state`, `sync_entity_types` tables (currently referenced by `SyncOutboxRepository.php` / `SyncService.php` with **no migration** per DB-01 table).
- Include the `attempts` counter and `next_retry_at` timestamp columns directly in this migration so CG-06 (Task 30.3) has its schema ready.

### Task 30.1.4 — `003_add_settings_reference_id.sql`
- **Source:** CG-01, R-001, R-004, DB-01 | **Track:** DB | **Estimate:** included in 3d total
- Add the missing `reference_id` column to the `settings` table (referenced by `SettingsRepository.php`, currently missing per DB-01).
- Use `ALTER TABLE settings ADD COLUMN IF NOT EXISTS reference_id ...` idempotent pattern.

### Task 30.1.5 — `004_add_login_attempts.sql`
- **Source:** DB-01, R-031 (supporting) | **Track:** DB | **Estimate:** included in 3d total
- Create `login_attempts` table (currently does not exist per DB-01, recommended in SEC-02) to support the rate-limiting middleware in Task 30.4.1: columns for `username`, `ip_address`, `attempted_at`, `success`, `terminal_id`.

### Task 30.1.6 — Subsequent Migrations (005+)
- **Source:** CG-01, R-001 | **Track:** DB | **Estimate:** included in 3d total
- Continue numbered migrations for any remaining structural needs surfaced during Sprint 30 implementation (e.g., AES-256 backup metadata columns for R-010, sync retry columns already covered in 30.1.3).
- **DoD (Epic 30.1 overall):** Fresh XAMPP/MariaDB install + running `MigrationService` from empty database successfully creates 100% of the schema with zero manual SQL intervention; running migrations twice is a safe no-op (idempotency verified).

## Epic 30.2 — Seed Data (R-002, DB-02)

### Task 30.2.1 — Write Seed SQL Files
- **Source:** R-002, DB-02 | **Track:** DB | **Estimate:** 1d
- Default admin user (first-login credentials, forced password change on first login).
- Default roles + permissions: Administrator, Cashier, Manager, Delivery (README §3 actor matrix expanded to concrete role rows + `role_permissions` mapping).
- Default service catalog: Wash, Dry Clean, Iron, Fold, Express.
- Default expense categories: Electricity, Rent, Supplies, etc.
- Default branch (`MAIN`) + default terminal (`T01`) — directly resolving the HC-02/CG-04 hardcoded `'MAIN'`/`'T01'` values by giving them a real DB-backed source.
- Default system settings: VAT rate = 5%, currency = AED, timezone = `Asia/Dubai`.
- **DoD:** Running `seed` command against a freshly migrated empty DB produces a fully operable system: an admin can log in, VAT/currency/timezone are correct, and Branch/Terminal chips (Sprint 29 Task 29.3.1 dependency) resolve to real data instead of placeholders.

## Epic 30.3 — Backup, Restore & Sync Reliability (CG-05, CG-06, R-003, R-006, R-010, DB-04)

### Task 30.3.1 — Implement Real `BackupController::restore()`
- **Source:** CG-05, R-003 | **Track:** Backend | **Estimate:** 2d
- Accept a ZIP file path parameter from the restore request.
- Extract the ZIP and verify SHA-256 hash of contents against `backup_manifest.json`.
- Execute `mysql < db_dump.sql` against the target database (via a safely shelled-out subprocess with parameterized paths — no string-concatenated shell injection risk).
- Validate post-restore record counts against the manifest's expected counts per table.
- On any verification/restore failure: roll back to the pre-restore safety snapshot (see README §15 Backup & Disaster Recovery) and raise a clear alert/audit entry.
- **DoD:** End-to-end test: take backup → corrupt live DB intentionally → restore → verify record counts match manifest exactly → verify a forced-failure restore (tampered ZIP) is rejected and rolled back cleanly.

### Task 30.3.2 — AES-256 Backup Encryption
- **Source:** R-010 | **Track:** Backend | **Estimate:** 1.5d
- Encrypt the backup ZIP payload with AES-256 using a key derived from the license/UMAC-bound secret (or an operator-set backup passphrase, per business decision — document the choice in `.ai/ARCHITECTURE.md` per Sprint 32 doc tasks).
- Update `BackupController::restore()` (Task 30.3.1) to decrypt before hash verification/extraction.
- **DoD:** Backup files are unreadable without the correct key; restore flow correctly decrypts and validates round-trip with zero data loss.

### Task 30.3.3 — Sync Retry / Exponential Backoff
- **Source:** CG-06 (TC-24-003), R-006 | **Track:** Backend | **Estimate:** 1d
- Use the `attempts` and `next_retry_at` columns added in Task 30.1.3.
- Implement exponential backoff calculation: `delay = min(300, 2^attempts * 5)` seconds.
- Set a max retry ceiling of 10 attempts; beyond that, mark the `sync_outbox` row `status='failed'` and raise a notification/alert (README Notification Alert Center) for operator review.
- On each sync attempt, increment `attempts`, and only skip-and-retry rows whose `next_retry_at <= NOW()`.
- **DoD:** Simulated repeated sync failures show correct backoff timing progression (5s, 10s, 20s, 40s... capped at 300s) and correctly transition to `failed` status after the 10th attempt, with an alert generated.

### Task 30.3.4 — Backup Retention Policy Enforcement
- **Source:** R-036, DB-04 | **Track:** Backend | **Estimate:** 1d
- `BackupController::history()` currently lists backups but does not prune per policy (per DB-04). Implement pruning logic matching README §32.7: 14 daily, 8 weekly, 12 monthly retained backups, oldest-beyond-policy automatically deleted (with an audit log entry per deletion).
- **DoD:** Simulated 90-day backup history correctly retains exactly the policy-defined counts per tier and deletes the rest, verified via automated test.

## Epic 30.4 — Race Condition & Data Integrity Fixes (CG-07, R-005, DB-03)

### Task 30.4.1 — Fix `InventoryRepository::transfer()` TOCTOU Race
- **Source:** CG-07, R-005 | **Track:** Backend | **Estimate:** 0.5d
- Move `beginTransaction()` to **before** the `SELECT ... FOR UPDATE` read (currently called after the read, per CG-07, creating a time-of-check-to-time-of-use race condition on concurrent stock transfers).
- Ensure the full read-modify-write transfer sequence (source deduction + destination addition + movement ledger insert) is wrapped in one atomic transaction with row-level locking held throughout.
- **DoD:** Concurrency test — two simultaneous transfer requests against the same product/branch — produces mathematically consistent stock levels with no lost updates or over-deduction.

### Task 30.4.2 — DECIMAL(18,2) Consistency Audit
- **Source:** DB-03, R-037 | **Track:** DB | **Estimate:** 0.5d
- Audit every monetary column across the full schema (from Task 30.1.2) to confirm `DECIMAL(18,2)` typing per README Critical Rule #1 — zero `FLOAT`/`DOUBLE` columns permitted for money anywhere (orders, order_lines, payments, expenses, payroll, purchase orders, inventory valuation, etc.).
- Write and run an automated schema-linter script (`scripts/verify_decimal_columns.sql` or PHP CLI tool) that fails CI if any newly added monetary-named column is not `DECIMAL(18,2)`.
- **DoD:** Linter script passes clean against the full schema; committed as a reusable CI gate for future migrations.

## Epic 30.5 — Security Hardening (R-031 to R-035)

### Task 30.5.1 — Rate-Limiting Middleware on Login
- **Source:** R-031 | **Track:** Backend | **Estimate:** 1d
- Use the `login_attempts` table (Task 30.1.5) to track failed attempts per username+IP.
- After 5 failed attempts within a rolling window, lock out further attempts for a defined cooldown (e.g., 5 minutes, exponential on repeat offenses), returning `error_code = RATE_LIMITED` with `retry_after_seconds` (feeds Sprint 29 Task 29.4.2 countdown UI).
- **DoD:** Automated test simulates 6 rapid failed logins; 6th request is rejected with `RATE_LIMITED` and correct `retry_after_seconds`.

### Task 30.5.2 — HTTP Security Headers
- **Source:** R-032 | **Track:** Backend | **Estimate:** 0.5d
- Add `X-Frame-Options: DENY`, `Content-Security-Policy`, `X-Content-Type-Options: nosniff` to every API response (local API and, later, cloud API in Sprint 32).
- **DoD:** All API responses inspected via automated header-assertion test include the three headers with correct values.

### Task 30.5.3 — Password Policy Enforcement
- **Source:** R-033 | **Track:** Backend | **Estimate:** 0.5d
- Enforce a minimum password policy (length ≥ 8, at least one uppercase, one number, one special character — confirm exact policy against `.ai/` security doc, document final policy in `.ai/ARCHITECTURE.md`) at the registration/user-creation endpoint.
- **DoD:** Weak-password submission attempts are rejected with a clear validation error; policy is enforced server-side (not just client-side) as the source of truth.

### Task 30.5.4 — CORS Restriction to LAN Subnet
- **Source:** R-034 | **Track:** Backend | **Estimate:** 0.5d
- Restrict CORS `Access-Control-Allow-Origin` on the local API to the configured LAN subnet / known terminal origins only (not `*`), consistent with the offline-first, local-network-only deployment model.
- **DoD:** Requests from origins outside the configured allow-list are rejected; legitimate LAN terminal requests succeed.

### Task 30.5.5 — `X-Request-Id` Tracing Header
- **Source:** R-035 | **Track:** Backend | **Estimate:** 0.5d
- Generate and attach a unique `X-Request-Id` (UUID v4) to every API response; propagate/log it through the request lifecycle for support diagnostics (README §14/§23 diagnostic export).
- **DoD:** Every API response includes a unique `X-Request-Id`; the diagnostic/support export tool (Sprint 33 pre-flight checklist item) can correlate logs by this ID.

## Sprint 30 — Exit Criteria
- [x] Fresh install from zero database succeeds via migrations + seed with no manual SQL.
- [x] Backup → Restore full round trip verified with AES-256 encryption and retention pruning.
- [x] Sync outbox backoff/retry/failed-state behavior verified.
- [x] Inventory transfer race condition fix verified under concurrency test.
- [x] All monetary columns verified `DECIMAL(18,2)` via CI-gated linter.
- [x] Rate-limiting, security headers, password policy, CORS, and request tracing all verified.

---

# 🧪 SPRINT 31 — Automated Testing (1.5 Weeks)

**Goal:** Close CG-02 (zero test files existing anywhere in the project despite `flutter_test` being a declared dependency) by building a real, CI-ready automated test suite (R-038 to R-041).

## Epic 31.1 — Flutter Widget Tests (R-038)

### Task 31.1.1 — Login Screen Widget Tests
- **Source:** R-038, CG-02 | **Track:** QA/Frontend | **Estimate:** included in 3d total
- Test: valid credentials submit successfully; invalid credentials show correct `error_code`-mapped message (Task 29.4.1); Tab/Enter focus chain behaves correctly (Task 29.4.2); rate-limit countdown renders and counts down correctly given a mocked `RATE_LIMITED` response.

### Task 31.1.2 — Dashboard Widget Tests
- **Source:** R-038, CG-02 | **Track:** QA/Frontend | **Estimate:** included in 3d total
- Test: KPI cards render with correct formatted currency (Task 29.6.3); error state shows retry button and successfully re-fetches on tap (Task 29.6.1); auto-refresh timer fires at the configured interval (mockable clock, Task 29.6.2); quick-action buttons navigate correctly (Task 29.6.4).

### Task 31.1.3 — POS Screen Widget Tests
- **Source:** R-038, CG-02 | **Track:** QA/Frontend | **Estimate:** included in 3d total
- Test: adding cart lines computes VAT from settings-provided rate, not hardcoded (Task 29.5.1); keyboard shortcuts F1/F2/F3/Esc trigger correct actions (Task 29.5.3); hold/resume order preserves full cart state (Task 29.5.5); change calculator computes correct change for various tendered amounts (Task 29.5.6); barcode debounce prevents duplicate lookups (Task 29.5.7).
- **DoD (Epic 31.1 overall):** 3 full widget-test suites committed under `test/widgets/`, passing in CI, covering the critical screens named explicitly in CG-02.

## Epic 31.2 — PHP Unit Tests (R-039)

### Task 31.2.1 — `SalesRepository` Unit Tests
- **Source:** R-039, CG-02 | **Track:** QA/Backend | **Estimate:** included in 2d total
- Test every repository method: order creation, line-item addition, discount/modifier application, payment allocation, balance calculation, status transitions (Received→Processing→Ready→Delivered), void/refund logic, and append-only ledger integrity (no destructive updates — verified by asserting reversal rows are created instead of edits).

### Task 31.2.2 — `InventoryRepository` Unit Tests
- **Source:** R-039, CG-02 | **Track:** QA/Backend | **Estimate:** included in 2d total
- Test: stock receiving, adjustments, purchase-order-driven receipts, the fixed `transfer()` method (Task 30.4.1) under simulated concurrent calls, and closing-balance calculations.
- **DoD (Epic 31.2 overall):** PHPUnit suite committed under `api/tests/Unit/`, achieving meaningful coverage of both repositories, passing in CI.

## Epic 31.3 — PHP Integration Tests (R-040)

### Task 31.3.1 — Full Order Lifecycle Integration Test
- **Source:** R-040, CG-02 | **Track:** QA/Backend | **Estimate:** 2d
- End-to-end API flow test: **auth (login) → create order → confirm order → collect payment → print receipt (mocked hardware adapter)**, asserting correct database state, correct status-history entries, and correct audit-log entries at every step.
- Include a negative-path variant: attempted payment overpayment/underpayment behavior, attempted status transition out of allowed sequence (e.g., Delivered → Received) is rejected.
- **DoD:** Integration suite runs against a migrated + seeded test database (Sprint 30 output), fully green in CI, covering both happy path and rejected/negative path.

## Epic 31.4 — Hardware Mock Tests (R-041)

### Task 31.4.1 — Printer / Scanner / Cash Drawer Mock Tests
- **Source:** R-041, CG-02 | **Track:** QA | **Estimate:** 1d
- Build mock adapter implementations for: ESC/POS thermal printer (57mm + 80mm), inkjet/dot-matrix printer, USB-wedge + Bluetooth barcode scanner, and cash drawer trigger.
- Test that each hardware abstraction interface correctly formats/sends commands against the mock and correctly reports success/failure/timeout states back to the calling screen (POS, Delivery, Backup).
- **DoD:** Hardware mock suite passes without requiring physical hardware attached, enabling CI execution; matches README §32.10 pre-production checklist items (Scanner test, Thermal printer test, Inkjet printer test, Dot matrix test, Cash drawer test).

## Sprint 31 — Exit Criteria
- [x] Flutter widget test suite (Login, Dashboard, POS) green in CI.
- [x] PHPUnit suite (SalesRepository, InventoryRepository) green in CI.
- [x] Full order-lifecycle integration test green in CI.
- [x] Hardware mock test suite green in CI without physical hardware.
- [x] CG-02 fully closed — project coverage moves from **0% → target 60%+** per Sprint 33 documentation goal.

---

# ☁️ SPRINT 32 — Cloud Portal + Integrations + Localization (3 Weeks)

**Goal:** Build the entire missing `cloud-api/` Multi-Tenant Cloud Platform + AdminLTE v4 Super-Admin Web Portal (CG-03), close remaining documentation gaps, and deliver KSA-readiness/localization/messaging integrations (R-042 to R-049).

## Epic 32.1 — Cloud API Project Scaffold (CG-03, R-042)

### Task 32.1.1 — Create `cloud-api/` Project Structure
- **Source:** CG-03, R-042 | **Track:** Cloud/Backend | **Estimate:** 5d total (broken down below)
- Scaffold the exact structure specified in the audit:
```
cloud-api/
├── public/index.php        # Entry point + routing
├── src/
│   ├── Controllers/        # Tenant, License, Sync, Analytics, Support
│   ├── Middleware/         # Session auth (not JWT), CSRF protection
│   ├── Repositories/       # Multi-tenant PDO queries
│   └── Views/              # AdminLTE 4 HTML templates
├── admin-portal/           # AdminLTE 4 static assets
└── composer.json
```
- Pure PHP 8.2, no third-party frameworks (matching README's local-API philosophy, extended to cloud), `composer.json` for autoloading + AdminLTE 4 asset dependencies only.

### Task 32.1.2 — Session Auth + CSRF Middleware
- **Source:** CG-03 (Required Structure: Middleware) | **Track:** Cloud/Backend | **Estimate:** included in 5d total
- Implement session-based authentication (distinct from the local API's JWT model, per README: "Secure Session/CSRF (Super-Admin)").
- Implement CSRF token generation/validation middleware for all state-changing admin-portal requests.

### Task 32.1.3 — Multi-Tenant Repository Layer
- **Source:** CG-03 (Required Structure: Repositories) | **Track:** Cloud/Backend | **Estimate:** included in 5d total
- Build PDO-based repositories enforcing tenant isolation (every query scoped by `tenant_id`), preventing any cross-tenant data leakage by construction (e.g., a base `TenantScopedRepository` class all others extend).

### Task 32.1.4 — AdminLTE 4 View Layer
- **Source:** CG-03 (Required Structure: Views, admin-portal/) | **Track:** Cloud/Frontend | **Estimate:** included in 5d total
- Integrate AdminLTE v4 static assets under `admin-portal/`.
- Build base layout templates (sidebar nav, topbar, breadcrumb, flash-message region) that all panel views extend.
- **DoD (Epic 32.1 overall):** `cloud-api/` runs standalone, super-admin can log in via session auth, CSRF protection verified on a test POST form, and a placeholder tenant list page renders inside the AdminLTE shell.

## Epic 32.2 — Super-Admin Panels (R-043, R-044, Cloud Portal Spec Panels 1–2)

### Task 32.2.1 — Tenant Management Panel
- **Source:** Cloud Portal Spec (Panel 1) | **Track:** Cloud/Backend+Frontend | **Estimate:** included in R-043's 3d
- CRUD tenants (create/view/edit/deactivate).
- Suspend/activate tenant toggle (immediately blocks/unblocks that tenant's sync + license validation).
- Usage stats per tenant (order volume, active terminals, storage/backup usage).

### Task 32.2.2 — License Management Panel
- **Source:** R-043, Cloud Portal Spec (Panel 2) | **Track:** Cloud/Backend+Frontend | **Estimate:** 3d
- Issue new license (duration-based, tied to physical address + UMAC per README §16).
- Revoke license (immediate effect propagated to local app's next license-check call).
- Extend license duration.
- View UMAC bindings per tenant/machine, with a manual UMAC-reset/re-bind workflow for legitimate hardware changes (support-assisted).
- **DoD:** Full license lifecycle (issue → activate on a test local instance → extend → revoke) verified end-to-end against the local app's license-check flow (README §16).

### Task 32.2.3 — Sync Monitoring Dashboard
- **Source:** R-044, Cloud Portal Spec (Panel 3) | **Track:** Cloud/Backend+Frontend | **Estimate:** 2d
- Show pending `sync_outbox` count per tenant (reading from the cloud-side mirror of sync state, populated by inbound sync pushes).
- "Force sync" trigger action per tenant (signals the local instance, or simply re-processes any queued cloud-side backlog, depending on sync direction design — document the exact push/pull model in `.ai/ARCHITECTURE.md`, Task 32.4.3).
- Error log view surfacing failed sync rows (leveraging the `status='failed'` rows from Sprint 30 Task 30.3.3's backoff ceiling).

### Task 32.2.4 — Cross-Tenant Analytics Panel
- **Source:** R-043 area / Cloud Portal Spec (Panel 4) | **Track:** Cloud/Backend+Frontend | **Estimate:** included in R-043's 3d buffer
- Cross-tenant revenue, order volume, and active-session aggregate dashboards for Magnificent Solution's internal visibility (not exposed to individual tenants).

### Task 32.2.5 — Support Tools Panel
- **Source:** Cloud Portal Spec (Panel 5) | **Track:** Cloud/Backend+Frontend | **Estimate:** included in R-043's buffer
- Remote log viewer (strictly opt-in per tenant, respecting data-sovereignty commitments from README §1).
- Backup download tool for support-assisted disaster recovery (works in conjunction with Sprint 30's AES-256 encrypted backups — decryption key never leaves the tenant's control unless explicitly shared for support).

## Epic 32.3 — Customer Self-Service Portal (R-045, Cloud Portal Spec)

### Task 32.3.1 — Order Tracking by Order Number or Phone
- **Source:** R-045 (Customer Self-Service Portal item 1) | **Track:** Cloud/Backend+Frontend | **Estimate:** included in R-045's 3d
- Public-facing (tenant-branded) lookup page: customer enters order number or phone number, sees current status (Received/Processing/Ready/Delivered) without requiring account login.

### Task 32.3.2 — Payment History & Invoice Download
- **Source:** R-045 (item 2) | **Track:** Cloud/Backend+Frontend | **Estimate:** 3d
- Authenticated (lightweight OTP-via-phone or similar) customer view of past payments and downloadable invoice PDFs.

### Task 32.3.3 — Notification Preferences
- **Source:** R-045 (item 3) | **Track:** Cloud/Backend+Frontend | **Estimate:** included in R-045's 3d
- Customer-manageable preferences for SMS/WhatsApp notification opt-in/out per notification type (order ready, payment reminder, promotional — if applicable).
- **DoD (Epic 32.3 overall):** A customer can track an order, view/download an invoice, and manage notification preferences entirely through the self-service portal without needing the desktop app.

## Epic 32.4 — Messaging Integrations & Localization (R-046 to R-049)

### Task 32.4.1 — Twilio SMS Adapter
- **Source:** R-046 | **Track:** Cloud/Backend | **Estimate:** 1d
- Build a Twilio adapter behind the existing Notification abstraction, sending order-status and payment-reminder SMS messages.
- **DoD:** Test send verified against a Twilio sandbox/test credential; failure states (invalid number, quota exceeded) handled gracefully and logged.

### Task 32.4.2 — WhatsApp Business API Adapter
- **Source:** R-047 | **Track:** Cloud/Backend | **Estimate:** 2d
- Build a WhatsApp Business API adapter (template-message based, per WhatsApp's compliance requirements) for order-ready and payment notifications.
- **DoD:** Test send verified against a WhatsApp Business test number; template approval requirements documented for the client's production rollout.

### Task 32.4.3 — KSA Locale Support
- **Source:** R-048 | **Track:** Backend/Frontend | **Estimate:** 1.5d
- Add a Saudi Arabia country profile: currency = SAR (Halala sub-unit), timezone = `Asia/Riyadh`, VAT rate = 15%, address schema adjustments — all driven by the existing country-profile architecture (README §2: "UAE-first, KSA-ready localization... does not require rewriting the monetary or localization engine").
- **DoD:** Switching the active country profile to KSA correctly recalculates VAT, displays SAR/Halala formatting, and uses Riyadh timezone for all date/time displays — with zero changes required to the core monetary engine code (validating the README's architectural claim).

### Task 32.4.4 — Hijri Calendar Support
- **Source:** R-049 | **Track:** Frontend | **Estimate:** 2d
- Add Hijri (Islamic) calendar display/selection option to all date pickers (Order due-date, Delivery scheduling, HR leave requests, Reports date-range), togglable alongside Gregorian, respecting the active locale/country profile.
- **DoD:** Date pickers correctly convert and display Hijri dates in `ar-AE`/KSA contexts; underlying stored dates remain Gregorian/ISO for data integrity, with Hijri as a display-layer conversion only.

## Epic 32.5 — Documentation Closure (Doc-01 to Doc-04)

### Task 32.5.1 — `.ai/SPRINT_LOG.md` — Add Sprints 21–28 Entries
- **Source:** Doc-01 | **Track:** Docs | **Estimate:** 0.5d
- Backfill missing sprint-log entries for Sprints 21 through 28 (currently only Sprints 1–20 documented), ensuring full historical traceability before Sprint 29–33 entries are appended as each sprint in this roadmap completes.

### Task 32.5.2 — `README.md` Installation Section Completion
- **Source:** Doc-02 | **Track:** Docs | **Estimate:** 0.5d
- Add missing installation documentation: `.env` setup instructions, Apache VirtualHost configuration steps for `http://laundrypro-localapi`, and Windows Task Scheduler daemon setup (for scheduled backups/sync per README §15).

### Task 32.5.3 — OpenAPI Swagger Completion
- **Source:** Doc-03 | **Track:** Docs/Backend | **Estimate:** 1d
- Add missing Swagger/OpenAPI documentation for: Backup endpoints (Sprint 30), Sync endpoints (Sprint 30), Notifications endpoints, Branches endpoints, Terminals endpoints, Accounting export endpoints.
- **DoD:** `/docs/` Swagger UI shows 100% of implemented endpoints with request/response schemas, including all endpoints touched across Sprints 29–32.

### Task 32.5.4 — `.ai/ARCHITECTURE.md` Update
- **Source:** Doc-04 | **Track:** Docs | **Estimate:** 1d
- Add: LAN network topology diagram (local API + MySQL + multiple terminals), cloud sync data flow diagram (push/pull direction decided in Task 32.2.3), and a settings-precedence diagram (how branch/terminal/global settings override each other, relevant to Sprint 29's Branch/Terminal-chip fix and Sprint 30's VAT-settings work).
- **DoD:** Architecture doc fully current with Sprints 29–32 changes; no outdated diagrams remain.

## Sprint 32 — Exit Criteria
- [x] `cloud-api/` fully implemented and deployable, matching the exact spec structure.
- [x] All 5 Super-Admin panels functional (Tenant, License, Sync, Analytics, Support).
- [x] Customer Self-Service Portal functional (tracking, invoices, notification prefs).
- [x] Twilio + WhatsApp adapters sending real test messages.
- [x] KSA locale + Hijri calendar verified.
- [x] All 4 documentation gaps closed.

---

# 📦 SPRINT 33 — Production Launch (1 Week)

**Goal:** Close remaining Critical Gaps CG-04 and CG-08, finish backlog items R-007, R-009, R-050, and walk the full **Final Quality Gate Checklist** (README §32.10) to sign-off.

## Epic 33.1 — Hardcoded String Elimination (CG-04, R-007)

### Task 33.1.1 — Fix `app_shell.dart` Hardcoded Strings
- **Source:** CG-04, R-007 | **Track:** Frontend | **Estimate:** 1d
- Replace every hardcoded string identified in the audit with a live, dynamic source:
  - `'Branch: MAIN'` → pulled from live branch/settings API (now backed by real seed data from Sprint 30 Task 30.2.1).
  - `'Terminal: T01'` → pulled from terminal session state (`TerminalSessionProvider`, per Sprint 29 Task 29.3.1).
  - `'API Node: Online'` / `'API Node: Offline'` → driven by the `ApiClient` connectivity state (Sprint 29 Task 29.7.1).
  - `'Printers: Ready'`, `'Scanner: Wedge Active'` → driven by live hardware adapter status (validated against Sprint 31 hardware mocks, now wired to real adapters).
  - `'Disk Space: OK (>20%)'` → driven by a live disk-space check utility with the correct real-time percentage and threshold-based warning state.
  - `'v1.2.1-UAE'` → pulled dynamically from `pubspec.yaml` via the `PackageInfo` plugin, not hardcoded.
- Move all remaining static label text through the JSON-controlled label store (README Critical Rule #4 — zero hardcoded UI strings) for both `en-AE` and `ar-AE`.
- **DoD:** Full grep audit of `app_shell.dart` (and any other flagged files) shows zero hardcoded user-facing strings; all values verified live/dynamic in a running instance.

## Epic 33.2 — Installer & Packaging (CG-08, R-009)

### Task 33.2.1 — MSIX Configuration
- **Source:** CG-08, R-009 | **Track:** DevOps | **Estimate:** included in 2d total
- Add the missing `msix` configuration block to `pubspec.yaml` (dependency was declared but unconfigured per CG-08): app identity, publisher, display name, version (synced with `PackageInfo` from Task 33.1.1), icons, capabilities.

### Task 33.2.2 — Inno Setup Installer Script
- **Source:** CG-08, R-009 | **Track:** DevOps | **Estimate:** 2d
- Write a full Inno Setup (`.iss`) script that:
  - Automates pre-flight checks for XAMPP, PHP, and MariaDB presence/version.
  - Auto-creates the `C:\LaundryPro\` directory structure (currently not automated, per CG-08).
  - Installs/configures the Apache VirtualHost for `http://laundrypro-localapi` (per Task 32.5.2's documented manual steps — now automated).
  - Runs the database migration + seed commands (Sprint 30 Epics 30.1–30.2) as a post-install step.
  - Registers the Windows Task Scheduler daemon for scheduled backups/sync (per Task 32.5.2).
- **DoD:** Running the Inno Setup installer on a clean Windows machine with no pre-existing XAMPP results in a fully operational, first-login-ready LaundryPro UAE instance with zero manual configuration steps.

## Epic 33.3 — MSIX Windows Store Submission (R-050)

### Task 33.3.1 — Code Signing + Store Submission Package
- **Source:** R-050 | **Track:** DevOps | **Estimate:** 2d
- Acquire/configure a code-signing certificate; sign the MSIX package.
- Prepare the Windows Store submission package (screenshots, description, privacy policy link, age rating) if the distribution model includes Store listing (alternatively: signed MSIX for direct/sideload distribution, per final business decision — document the chosen channel).
- **DoD:** Signed MSIX installs without SmartScreen/publisher-untrusted warnings; submission package (if Store-bound) passes Microsoft's pre-submission validation checks.

## Epic 33.4 — Final Quality Gate (README §32.10) — Verification Sign-Off

Each checklist item below is executed as a **verification task**, mapped to the sprint/epic that implemented it, ensuring zero gaps remain before production sign-off:

| # | Checklist Item (README §32.10) | Verified By (Sprint/Task) |
|---|---|---|
| 1 | BRD approved | Pre-existing baseline — confirm sign-off on file |
| 2 | Scope baseline approved | This document itself — confirm client/stakeholder sign-off |
| 3 | ERD reviewed | Sprint 30, Task 30.1.2 (`001_initial_schema.sql`) reviewed against README data model |
| 4 | Database migration tested | Sprint 30, Epic 30.1 exit criteria |
| 5 | API Swagger complete | Sprint 32, Task 32.5.3 |
| 6 | Auth/permission tests passed | Sprint 31, Task 31.3.1 (auth step) + RBAC regression |
| 7 | Sales end-to-end passed | Sprint 31, Task 31.3.1 |
| 8 | Payment end-to-end passed | Sprint 31, Task 31.3.1 |
| 9 | Inventory reconciliation passed | Sprint 31, Task 31.2.2 + Sprint 30, Task 30.4.1 |
| 10 | Order status tests passed | Sprint 31, Task 31.2.1 |
| 11 | Arabic RTL tests passed | Sprint 29, Task 29.3.1 |
| 12 | Print templates passed | Sprint 31, Task 31.4.1 |
| 13 | Scanner test passed | Sprint 31, Task 31.4.1 |
| 14 | Thermal printer test passed | Sprint 31, Task 31.4.1 |
| 15 | Inkjet printer test passed | Sprint 31, Task 31.4.1 |
| 16 | Dot matrix test passed | Sprint 31, Task 31.4.1 |
| 17 | Cash drawer test passed where supported | Sprint 31, Task 31.4.1 |
| 18 | Backup verified | Sprint 30, Task 30.3.1 + 30.3.2 |
| 19 | Restore verified | Sprint 30, Task 30.3.1 |
| 20 | License activation verified | Sprint 32, Task 32.2.2 |
| 21 | UMAC verification verified | Sprint 32, Task 32.2.2 |
| 22 | Disk-space warnings tested | Sprint 33, Task 33.1.1 |
| 23 | App restart recovery tested | New verification task — confirm held orders (Task 29.5.5) and in-flight sync state (Task 30.3.3) survive an app/process restart cleanly |
| 24 | Data migration tested | Sprint 30, Epic 30.1 |
| 25 | Support diagnostic export tested | Sprint 30, Task 30.5.5 (`X-Request-Id` correlation) + existing diagnostic export tool |
| 26 | Acceptance test sign-off completed | Final client/stakeholder sign-off meeting, referencing this full checklist |

### Task 33.4.1 — Execute Full Quality Gate Walkthrough
- **Source:** README §32.10, all Sprints 29–33 | **Track:** QA/PM | **Estimate:** 1d
- Run through all 26 checklist items above in a single structured acceptance session, capturing evidence (screenshots/logs/test-run outputs) for each.
- Produce a signed **Sign-Off Baseline** record (README §32.11 format) updated to reflect the final v1.3.0 (or agreed version) production release, with a corresponding **Change Log** entry (README §32.12 template) documenting Sprints 29–33 as a single consolidated release line.
- **DoD:** All 26 items checked off with evidence attached; formal sign-off obtained from Owner/Manager stakeholder and Magnificent Solution technical lead.

## Sprint 33 — Exit Criteria
- [x] Zero hardcoded strings remain in `app_shell.dart` or elsewhere (CG-04 closed).
- [x] MSIX + Inno Setup installer fully automates fresh-machine deployment (CG-08 closed).
- [x] Signed MSIX package ready for distribution/Store submission (R-050 closed).
- [x] Full README §32.10 Final Quality Gate checklist passed and signed off.
- [x] **Project status: Production-Ready — 100% of Critical Gaps, High Corrections, DB Gaps, Documentation Gaps, and R-001–R-050 Backlog closed.**

---

# 📋 FULL TRACEABILITY MATRIX (Zero-Loss Cross-Check)

This matrix confirms every source item from the audit document is represented above with no omissions.

## Critical Gaps (CG-01 to CG-08)
| ID | Closed In |
|---|---|
| CG-01 — No SQL Migration Files Directory | Sprint 30, Epic 30.1 |
| CG-02 — No Automated Test Suite | Sprint 31 (entire sprint) |
| CG-03 — Cloud Super-Admin Portal Not Implemented | Sprint 32, Epics 32.1–32.3 |
| CG-04 — `app_shell.dart` Hardcoded Strings | Sprint 33, Epic 33.1 |
| CG-05 — Backup `restore()` Stub | Sprint 30, Task 30.3.1 |
| CG-06 — SyncService No Retry/Backoff | Sprint 30, Task 30.3.3 |
| CG-07 — `InventoryRepository::transfer()` Race Condition | Sprint 30, Task 30.4.1 |
| CG-08 — No MSIX/Inno Setup Installer | Sprint 33, Epic 33.2 |

## High Priority Corrections (HC-01 to HC-05)
| ID | Closed In |
|---|---|
| HC-01 — Theme System Gaps | Sprint 29, Epic 29.1 |
| HC-02 — Nav Rail RTL + Hardcoded Widths | Sprint 29, Epic 29.3 |
| HC-03 — Login Screen UX Polish | Sprint 29, Epic 29.4 |
| HC-04 — POS Screen Workflow Gaps | Sprint 29, Epic 29.5 |
| HC-05 — Dashboard Live Data + Visual Hierarchy | Sprint 29, Epic 29.6 |

## Database Gaps (DB-01 to DB-04)
| ID | Closed In |
|---|---|
| DB-01 — Missing Tables/Columns (sync_outbox, sync_state, sync_entity_types, settings.reference_id, login_attempts) | Sprint 30, Epic 30.1 |
| DB-02 — No Seed Data | Sprint 30, Epic 30.2 |
| DB-03 — DECIMAL(18,2) Consistency | Sprint 30, Task 30.4.2 |
| DB-04 — Backup Retention Policy | Sprint 30, Task 30.3.4 |

## Documentation Gaps
| ID | Closed In |
|---|---|
| Doc-01 — `.ai/SPRINT_LOG.md` Sprints 21–28 | Sprint 32, Task 32.5.1 |
| Doc-02 — README Installation Section | Sprint 32, Task 32.5.2 |
| Doc-03 — OpenAPI Swagger | Sprint 32, Task 32.5.3 |
| Doc-04 — `.ai/ARCHITECTURE.md` | Sprint 32, Task 32.5.4 |

## Cloud Super-Admin Portal Spec
| Item | Closed In |
|---|---|
| `cloud-api/` structure (public/, src/Controllers, Middleware, Repositories, Views, admin-portal/, composer.json) | Sprint 32, Epic 32.1 |
| Panel 1 — Tenant Management | Sprint 32, Task 32.2.1 |
| Panel 2 — License Management | Sprint 32, Task 32.2.2 |
| Panel 3 — Sync Monitoring | Sprint 32, Task 32.2.3 |
| Panel 4 — Analytics | Sprint 32, Task 32.2.4 |
| Panel 5 — Support Tools | Sprint 32, Task 32.2.5 |
| Customer Self-Service — Order tracking | Sprint 32, Task 32.3.1 |
| Customer Self-Service — Payment history/invoices | Sprint 32, Task 32.3.2 |
| Customer Self-Service — Notification preferences | Sprint 32, Task 32.3.3 |

## Prioritized Backlog (R-001 to R-050)
| ID | Closed In | ID | Closed In |
|---|---|---|---|
| R-001 | Sprint 30, Epic 30.1 | R-026 | Sprint 29, Task 29.6.2 |
| R-002 | Sprint 30, Epic 30.2 | R-027 | Sprint 29, Task 29.6.5 |
| R-003 | Sprint 30, Task 30.3.1 | R-028 | Sprint 29, Task 29.6.4 |
| R-004 | Sprint 30, Task 30.1.4 | R-029 | Sprint 29, Epic 29.7 |
| R-005 | Sprint 30, Task 30.4.1 | R-030 | Sprint 29, Task 29.4.2 |
| R-006 | Sprint 30, Task 30.3.3 | R-031 | Sprint 30, Task 30.5.1 |
| R-007 | Sprint 33, Epic 33.1 | R-032 | Sprint 30, Task 30.5.2 |
| R-008 | Sprint 29, Epic 29.8 | R-033 | Sprint 30, Task 30.5.3 |
| R-009 | Sprint 33, Epic 33.2 | R-034 | Sprint 30, Task 30.5.4 |
| R-010 | Sprint 30, Task 30.3.2 | R-035 | Sprint 30, Task 30.5.5 |
| R-011 | Sprint 29, Task 29.1.1 | R-036 | Sprint 30, Task 30.3.4 |
| R-012 | Sprint 29, Task 29.1.2 | R-037 | Sprint 30, Task 30.4.2 |
| R-013 | Sprint 29, Task 29.1.3 | R-038 | Sprint 31, Epic 31.1 |
| R-014 | Sprint 29, Task 29.2.1 | R-039 | Sprint 31, Epic 31.2 |
| R-015 | Sprint 29, Task 29.2.2 | R-040 | Sprint 31, Epic 31.3 |
| R-016 | Sprint 29, Task 29.2.3 | R-041 | Sprint 31, Epic 31.4 |
| R-017 | Sprint 29, Task 29.2.4 | R-042 | Sprint 32, Epic 32.1 |
| R-018 | Sprint 29, Task 29.2.5 | R-043 | Sprint 32, Tasks 32.2.1/32.2.2/32.2.4 |
| R-019 | Sprint 29, Epic 29.3 | R-044 | Sprint 32, Task 32.2.3 |
| R-020 | Sprint 29, Task 29.2.6 | R-045 | Sprint 32, Epic 32.3 |
| R-021 | Sprint 29, Task 29.5.3 | R-046 | Sprint 32, Task 32.4.1 |
| R-022 | Sprint 29, Task 29.5.2 | R-047 | Sprint 32, Task 32.4.2 |
| R-023 | Sprint 29, Task 29.5.6 | R-048 | Sprint 32, Task 32.4.3 |
| R-024 | Sprint 29, Task 29.5.5 | R-049 | Sprint 32, Task 32.4.4 |
| R-025 | Sprint 29, Task 29.5.1 | R-050 | Sprint 33, Epic 33.3 |

**Result: 100% of audit items (8 CG + 5 HC + 4 DB + 4 Doc + 8 Cloud Spec sub-items + 50 R-backlog items) mapped to an executable task with zero data loss.**

---

*Document generated from: `LaundryPro UAE — README.md` (Master Spec) + `LaundryPro UAE — Full & Final Production Audit, Correction & Implementation Roadmap` (v1.2.1+4).*
*Covers Sprints 29–33 in full depth, sprint-wise, task-wise, with a complete zero-loss traceability matrix.*

**End of full-final-complete-development-tasks.md**
