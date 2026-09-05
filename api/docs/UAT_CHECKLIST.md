# UAT Checklist — Phase 1 Production Package

## Prerequisites

- [ ] XAMPP Apache + MySQL running
- [ ] `powershell scripts\migrate.ps1` completed
- [ ] API health: `GET http://localhost/laundrypro-api/public/api/v1/health`
- [ ] Admin login: `admin` / `admin123`
- [ ] Cashier login: `cashier` / `cashier123`

## Install & bootstrap

- [ ] Fresh DB: migrations 001–014 applied
- [ ] Install status shows `db_connected: true`
- [ ] Setup wizard shows migration/lock status

## Core sale loop (AC-001, AC-002)

- [ ] POS: add service → confirm → pay → receipt
- [ ] Partial payment updates balance, not original totals
- [ ] Pending invoices: pay balance + status update

## Catalog & inventory (AC-003–005)

- [ ] Service hierarchy cycle rejected (API)
- [ ] Service-product map attach/list
- [ ] Modifiers on service
- [ ] Stock receipt increases quantity
- [ ] Group sale blocks when insufficient stock

## Documents (AC-007)

- [ ] Thermal receipt string matches PDF totals

## Backup (AC-008, AC-009)

- [ ] Run backup from Settings
- [ ] Verify returns manifest + checksum
- [ ] Restore validate dry-run returns compatible

## RBAC (AC-010)

- [ ] Cashier can create sale draft
- [ ] Cashier blocked from backup/settings

## License (AC-011)

- [ ] License gate on startup when inactive

## Arabic RTL (AC-006)

- [ ] Switch to Arabic — RTL on dashboard, POS, settings

## Quality gate

- [ ] `powershell scripts\quality-gate.ps1` — all pass
- [ ] 90+ API tests, 20+ Flutter tests

## Packaging (M7)

- [ ] `powershell scripts\package.ps1` produces MSIX
- [ ] Unsigned MSIX installs on test machine (dev mode)
