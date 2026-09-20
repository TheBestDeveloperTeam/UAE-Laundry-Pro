# Business Requirements - LaundryPro UAE
> **Version:** 1.0.0

## Business Objectives
1. Provide a complete ERP/CRM/POS solution for UAE laundry businesses.
2. Support offline-first operation (internet not required for daily operations).
3. Support multi-tenant deployment (multiple business owners, multiple branches).
4. Support bilingual interface (English LTR + Arabic RTL).
5. Comply with UAE regulations (VAT, FTA, WPS, PDPL).
6. Support all common laundry hardware (printers, scanners, cash drawers, RFID).
7. Enable data synchronization when connectivity is available.
8. Protect against piracy with machine-bound licensing (UMAC).

## Business Constraints
- Must run on Windows 10/11 desktop (MSIX distribution).
- Must work without internet (offline-first).
- Must use local XAMPP server (no cloud dependency for core operations).
- Must support existing laundry hardware ecosystem in UAE.
- Must comply with UAE Federal Tax Authority (FTA) requirements.
- All monetary calculations must use DECIMAL precision (zero floating-point).

## Target Users
1. **Business Owners** - Financial oversight, reports, multi-branch management
2. **Branch Managers** - Daily operations, staff management, inventory
3. **Cashiers** - POS operations, order intake, payments
4. **Production Operators** - Garment processing, quality checks
5. **Delivery Drivers** - Route management, delivery confirmation
6. **System Administrators** - System configuration, user management

## Success Criteria
- Cashier can process order in < 30 seconds.
- System operates for 30+ days without internet.
- VAT calculation matches FTA requirements exactly.
- All data syncs correctly after connectivity restoration.
- Zero data loss during offline/online transitions.