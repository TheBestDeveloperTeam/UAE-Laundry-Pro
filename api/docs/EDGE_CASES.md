# Edge Case Verification Matrix

**Last verified:** 2026-09-04  
**Automated:** `api/tests/cases/*.json` (182 cases) + `test/*.dart` (80+ tests)  
**Runner:** `powershell scripts\quality-gate.ps1`

## Summary

| Layer | Cases | Passed | Notes |
|-------|-------|--------|-------|
| API automated | 94 | 88 | 6 skipped (cloud optional / install locked) |
| Flutter unit/widget | 41 | 41 | POS, license, receipt, i18n, models |
| **Total automated** | **135** | **129** | |

## Sales edge fixes (2026-09-04)

| Issue | Fix |
|-------|-----|
| Payment on draft order | Blocked unless status is confirmed+ |
| Draft → ready status jump | Transition map enforces valid paths only |
| Double-discount in totals | `calculateTotals()` uses qty×rate for subtotal |
| Overpayment | Capped at `balance_due` |
| Zero/negative payment | Returns 422 |
| Insufficient stock on confirm | Returns 422 `INSUFFICIENT_STOCK` |

## Auth middleware fix (2026-09-04)

`AuthMiddleware` no longer catches downstream handler exceptions (e.g. missing `ZipArchive`). Those now surface as 500 `SERVER_ERROR`. Enable `extension=zip` in PHP and restart Apache for backup endpoints.

## API edge cases covered

### Platform / Identity
- Business GET without auth → 401
- Refresh after logout → 401 (refresh token revoked)
- Install migrate when locked → 403 (skipped if install not locked)

### CRM / Catalog
- Customer create missing name → 422
- Customer GET not found → 404
- Service create empty name → 422
- Products unknown barcode → 200 empty list
- Hierarchy cycle → 422 `HIERARCHY_CYCLE`
- Service-product map attach/list
- Service modifiers create/list

### Inventory
- Stock receipt + movements list
- Sale confirm blocked when stock insufficient

### Backup (P1C-05)
- `POST /backup/run` → 200 manifest
- `POST /backup/verify` → 200 verified manifest
- `POST /backup/restore/validate` → 200 dry-run

### RBAC (AC-010)
- Cashier `POST /sales/draft` → 200
- Cashier `POST /backup/run` → 403
- Cashier `PUT /settings` → 403

### Sales
- Payment on draft → 422
- Draft status → ready → 422
- Confirm already confirmed → 422
- Payment zero → 422
- Partial payment → partial status, balance 30.00
- Overpay capped → paid, balance 0.00
- GET/confirm/status not found → 404/422
- Invalid status string → 422
- List partial filter → 200

### Sync / License / Reports
- License activate empty key → 422
- Sync pull with since → 200
- Sync push → 200
- Sales summary future dates → order_count 0
- Cloud tenant isolation → optional (skip when cloud-api not deployed)

## Flutter edge cases covered

| Case | Test |
|------|------|
| Empty cart disables confirm | `POS shows empty cart message and disabled confirm` |
| Pay hidden before confirm | same test (`pos_pay_btn` absent) |
| Inactive license state | `AuthProvider reflects inactive license` |
| API down bypasses license | `AuthProvider bypasses license when API unhealthy` |
| Receipt thermal + PDF same totals | `thermal and PDF share same totals` |
| Arabic RTL | `Arabic locale enables RTL` |
| en/ar key parity | `i18n_test.dart` (12 keys) |

## Manual acceptance checklist

| AC | Steps | Result | Date |
|----|-------|--------|------|
| AC-001 | Local API only; POS service → confirm → pay → receipt | PASS (automated chain + POS UI) | 2026-09-04 |
| AC-002 | Partial pay 20 of 50; verify partial/balance | PASS (`sales_payment_partial` assert) | 2026-09-04 |
| AC-003 | Hierarchy cycles rejected | PASS (`service_cycle_rejected`) | 2026-09-04 |
| AC-004 | Bundle snapshot on confirm | PASS (catalog_depth + sales confirm) | 2026-09-04 |
| AC-005 | Stock integrity | PASS (`stock_sale_confirm_blocked`) | 2026-09-04 |
| AC-006 | Arabic RTL on POS/Pending/License/Sync | PASS (LocaleProvider + ar.json parity) | 2026-09-04 |
| AC-007 | Document consistency thermal + PDF | PASS (`receipt_test.dart`) | 2026-09-04 |
| AC-008 | Backup verification | PASS (`backup_verify`) | 2026-09-04 |
| AC-009 | Restore validation dry-run | PASS (`backup_restore_validate`) | 2026-09-04 |
| AC-010 | Permission control API | PASS (`rbac.json` cashier 403) | 2026-09-04 |
| AC-011 | License gate | PASS (license API + AuthProvider tests) | 2026-09-04 |
| AC-012 | Audit on critical changes | PASS (audit middleware on sales confirm/payment) | 2026-09-04 |
| AC-013 | Full production status transitions enforced | PASS (`production_workflow.json`) | 2026-09-05 |
| AC-014 | Delivery scheduled → completed with audit | PASS (`delivery.json`) | 2026-09-05 |
| AC-015 | Challan sequential numbering + print | PASS (`challans.json` + `DocumentRenderer` PDF test) | 2026-09-05 |
| AC-016 | PO receive increases stock | PASS (`purchasing.json`) | 2026-09-05 |
| AC-017 | Payroll run for period with advance recovery | PASS (`payroll.json`) | 2026-09-05 |
| AC-018 | Expense approval workflow | PASS (`expenses.json`) | 2026-09-05 |
| AC-019 | Advanced reports return correct aggregates | PASS (`reports_phase2.json`) | 2026-09-05 |
| AC-020 | Notification center shows triggered alerts | PASS (`notifications.json`) | 2026-09-05 |
| AC-021 | Terminal registration + branch scoping | PASS (`phase3_branches.json`) | 2026-09-05 |
| AC-022 | Terminal device limit enforced | PASS (`p3_terminal_register`) | 2026-09-05 |
| AC-023 | Branch-scoped analytics | PASS (`p3_analytics_summary`) | 2026-09-05 |
| AC-024 | Sync entity registry | PASS (`p3_sync_entities`) | 2026-09-05 |
| AC-025 | KSA profile switch AE↔SA | PASS (`phase3_analytics.json`) | 2026-09-05 |
| AC-026 | Accounting export batch | PASS (`p3_accounting_export`) | 2026-09-05 |
| AC-027 | SMS/WhatsApp test logged | PASS (`p3_channel_test`) | 2026-09-05 |
| AC-028 | Analytics trends match snapshots | PASS (`p3_analytics_*`) | 2026-09-05 |
| AC-029 | Storefront order intake | PASS (`phase3_storefront.json`) | 2026-09-05 |
| AC-030 | Customer portal order status | PASS (`p3_portal_order_status`) | 2026-09-05 |

## Prerequisites

- XAMPP Apache + MySQL running
- PHP `extension=zip` enabled (required for backup zip)
- `powershell scripts\migrate.ps1` applied
- API base: `http://localhost/laundrypro-api/public/api/v1`
