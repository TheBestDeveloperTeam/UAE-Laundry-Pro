# Edge Case Verification Matrix

**Last verified:** 2026-09-05  
**Automated:** `api/tests/cases/*.json` (182 cases, 4 suites) + `test/*.dart` (116 tests)  
**Runner:** `powershell scripts\dev.ps1 gate` (or `scripts\quality-gate.ps1`)

## Summary

| Layer | Cases | Passed | Notes |
|-------|-------|--------|-------|
| API automated | 182 | 173 | 9 skipped (cloud optional / install locked / branch create env) |
| Flutter unit/widget | 116 | 116 | POS, peripherals, license, receipt, i18n, models |
| **Total automated** | **298** | **289** | |

## Sales edge fixes (2026-09-04)

| Issue | Fix |
|-------|-----|
| Payment on draft order | Blocked unless status is confirmed+ |
| Draft → ready status jump | Transition map enforces valid paths only |
| Double-discount in totals | `calculateTotals()` uses qty×rate for subtotal |
| Overpayment | Capped at `balance_due` |
| Zero/negative payment | Returns 422 |
| Insufficient stock on confirm | Returns 422 `INSUFFICIENT_STOCK` |

## Peripherals / POS (2026-09-05)

| Case | Behavior |
|------|----------|
| No printer selected | Hardware print returns error; PDF fallback available |
| Scanner unknown barcode | Snackbar `pos_scan_not_found`; no cart change |
| Scanner service code match | Adds service line to cart |
| Scanner product barcode | `GET /products?barcode=` lookup; adds product line |
| Cash payment | Optional drawer pulse via ESC/POS on selected printer |
| Remote SQL tab | Admin diagnostic only; bypasses API auth — trusted LAN |

## Auth middleware fix (2026-09-04)

`AuthMiddleware` no longer catches downstream handler exceptions (e.g. missing `ZipArchive`). Those now surface as 500 `SERVER_ERROR`. Enable `extension=zip` in PHP and restart Apache for backup endpoints.

## API edge cases covered

### Platform / Identity
- Business GET without auth → 401
- Refresh after logout → 401 (refresh token revoked)
- Install migrate when locked → 403 (skipped if install not locked)
- Legacy DB upgrade → `001_baseline.sql` auto-marked when incremental migrations exist

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
| Receipt → PosReceiptBuilder markup | `peripheral_print_service_test.dart` |
| Arabic RTL | `Arabic locale enables RTL` |
| en/ar key parity | `i18n_test.dart` |

## Manual acceptance checklist

| AC | Steps | Result | Date |
|----|-------|--------|------|
| AC-001 | Local API only; POS service → confirm → pay → receipt | PASS | 2026-09-04 |
| AC-002 | Partial pay 20 of 50; verify partial/balance | PASS | 2026-09-04 |
| AC-003 | Hierarchy cycles rejected | PASS | 2026-09-04 |
| AC-004 | Bundle snapshot on confirm | PASS | 2026-09-04 |
| AC-005 | Stock integrity | PASS | 2026-09-04 |
| AC-006 | Arabic RTL on POS/Pending/License/Sync | PASS | 2026-09-04 |
| AC-007 | Document consistency thermal + PDF | PASS | 2026-09-04 |
| AC-008 | Backup verification | PASS | 2026-09-04 |
| AC-009 | Restore validation dry-run | PASS | 2026-09-04 |
| AC-010 | Permission control API | PASS | 2026-09-04 |
| AC-011 | License gate | PASS | 2026-09-04 |
| AC-012 | Audit on critical changes | PASS | 2026-09-04 |
| AC-013 | Full production status transitions enforced | PASS | 2026-09-05 |
| AC-014 | Delivery scheduled → completed with audit | PASS | 2026-09-05 |
| AC-015 | Challan sequential numbering + print | PASS | 2026-09-05 |
| AC-016 | PO receive increases stock | PASS | 2026-09-05 |
| AC-017 | Payroll run with advance recovery | PASS | 2026-09-05 |
| AC-018 | Expense approval workflow | PASS | 2026-09-05 |
| AC-019 | Advanced reports aggregates | PASS | 2026-09-05 |
| AC-020 | Notification center alerts | PASS | 2026-09-05 |
| AC-021 | Terminal registration + branch scoping | PASS | 2026-09-05 |
| AC-022 | Terminal device limit enforced | PASS | 2026-09-05 |
| AC-023 | Branch-scoped analytics | PASS | 2026-09-05 |
| AC-024 | Sync entity registry | PASS | 2026-09-05 |
| AC-025 | KSA profile switch AE↔SA | PASS | 2026-09-05 |
| AC-026 | Accounting export batch | PASS | 2026-09-05 |
| AC-027 | SMS/WhatsApp test logged | PASS | 2026-09-05 |
| AC-028 | Analytics trends match snapshots | PASS | 2026-09-05 |
| AC-029 | Storefront order intake | PASS | 2026-09-05 |
| AC-030 | Customer portal order status | PASS | 2026-09-05 |
| AC-031 | Receipt → PosReceiptBuilder markup | PASS | 2026-09-05 |
| AC-032 | Hardware print graceful fallback | PASS | 2026-09-05 |
| AC-033 | Scanner wedge cart add | PASS | 2026-09-05 |
| AC-034 | Cash drawer pulse on cash pay | PASS | 2026-09-05 |
| AC-035 | Peripheral unit tests | PASS | 2026-09-05 |

## Prerequisites

- XAMPP Apache + MySQL running
- PHP `extension=zip` enabled (required for backup zip)
- `powershell scripts\dev.ps1 migrate` (or `migrate.ps1`)
- API base: `http://localhost/laundrypro-api/public/api/v1`
- POS hardware: printer selected in Settings → Peripherals
