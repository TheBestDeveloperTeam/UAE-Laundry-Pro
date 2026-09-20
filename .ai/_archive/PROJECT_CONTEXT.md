# Project Context: LaundryPro UAE

**Developer / Maintainer:** Magnificent Solution
**Product:** LaundryPro UAE (LaundryPro Local — Offline-First Desktop ERP/POS)
**Platform:** Flutter Windows Desktop + PHP 8.x API + MariaDB + XAMPP
**Architecture:** MVVM + Modular Local Service Components · Offline-First · JWT/OAuth2

---

## Current Phase
**Phase 1 — Core Operational MVP** (In Progress)
**Active Sprint:** Sprint 01 — Architecture Hardening & Global Config

---

## User Personas

| Actor | Primary Need | Authority Level |
|-------|-------------|----------------|
| Owner/Manager | Revenue, profit, control, full reports and settings | Highest |
| Branch Manager | Daily operation oversight | High |
| Front-Desk / Cashier | Fast order creation and payment | Medium |
| Production Supervisor | Service processing and status updates | Medium/High |
| Storekeeper | Inventory accuracy, goods receipt | Medium |
| Accountant/HR | Payroll, expenses, vendor payments | Medium |
| Employee | Attendance/leave visibility | Low/Scoped |
| Auditor/Reviewer | Read-only traceability | Read-only |
| System Administrator | Config, security, backup, license | Highest technical |
| Magnificent Solution (Vendor) | Development, maintenance, licensing | Controlled support |

---

## Current State Summary (Gap Analysis)

### ✅ DONE
- Project structure: lib/, api/src/, migrations (28 archived)
- All screen stubs exist (views/)
- All API controllers and repositories exist
- Auth service, JWT, PermissionChecker skeleton
- BackupService, LicenseService, UmacService skeleton
- Peripherals module skeleton (peripherals/)
- Global config service (global_config_service.dart)

### 🔴 MISSING / INCOMPLETE
- Standalone global config admin UI (Sprint 01)
- Full POS Order Entry screen (Sprint 07 — CRITICAL)
- Payment processing full flow (Sprint 08)
- Thermal/inkjet/dot-matrix print pipeline all brands (Sprint 09)
- Context-aware scanner auto-search (Sprint 10)
- Cash drawer session management (Sprint 11)
- Hardware auto-discovery wizard (Sprint 12)
- Production Kanban board (Sprint 15)
- Delivery/collection workflow UI (Sprint 16)
- Backup/Restore full wizard UI (Sprint 22)
- Reports engine (30+ report types)

---

## Key Paths (Global Config)

| Key | Default Value |
|-----|--------------|
| BACKUP_PATH | C:/LaundryPro/backups/ |
| INVOICE_PATH | C:/LaundryPro/invoices/ |
| IMAGE_PATH | C:/LaundryPro/images/ |
| LOG_PATH | C:/LaundryPro/logs/ |
| EXPORT_PATH | C:/LaundryPro/exports/ |
| TEMP_PATH | C:/LaundryPro/temp/ |
| TEMPLATE_PATH | C:/LaundryPro/templates/ |

---

## Critical Business Rules
1. Monetary values: DECIMAL(18,2) only — never floating-point
2. Posted invoices: never update — use correction memos
3. Inventory movements: append-only — never delete
4. All status transitions: permission-controlled + audit-logged
5. Backup paths: from global config — never hardcoded
6. Hardware adapters: generic interfaces only — no manufacturer SDK in business logic
7. Arabic TRN on all tax invoices; UAE VAT 5%
8. Order numbers: server-side atomic generation (LP-YYYY-BRANCH-00001 format)
