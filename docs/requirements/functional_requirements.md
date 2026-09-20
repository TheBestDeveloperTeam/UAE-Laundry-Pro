# Functional Requirements - LaundryPro UAE
> **Version:** 1.0.0

## Module: Authentication & Authorization
- FR-AUTH-001: System shall support username/password login.
- FR-AUTH-002: System shall enforce RBAC with 6 defined roles.
- FR-AUTH-003: System shall issue JWT access tokens (15-min expiry).
- FR-AUTH-004: System shall support token refresh (7-day refresh token).
- FR-AUTH-005: System shall support session management and logout.
- FR-AUTH-006: System shall enforce machine-bound licensing (UMAC).

## Module: Order Management
- FR-ORD-001: System shall support walk-in, pickup, and corporate order intake.
- FR-ORD-002: System shall assign sequential order numbers (ORD-YYYY-NNNNNN).
- FR-ORD-003: System shall support barcode and RFID garment tagging.
- FR-ORD-004: System shall track order status (received, processing, ready, delivered).
- FR-ORD-005: System shall support express, same-day, next-day, and standard turnaround.
- FR-ORD-006: System shall calculate pricing per-item, per-kg, or per-piece.
- FR-ORD-007: System shall support line-item discounts and order-level discounts.
- FR-ORD-008: System shall support order notes and special instructions.

## Module: Point of Sale
- FR-POS-001: System shall display service catalog with prices.
- FR-POS-002: System shall support barcode scanner input for item lookup.
- FR-POS-003: System shall calculate subtotal, discount, VAT, and total.
- FR-POS-004: System shall support cash, card, and split payment methods.
- FR-POS-005: System shall print receipt on thermal printer.
- FR-POS-006: System shall open cash drawer after cash payment.

## Module: Inventory
- FR-INV-001: System shall track supply inventory (detergent, hangers, bags, etc.).
- FR-INV-002: System shall support stock-in and stock-out transactions.
- FR-INV-003: System shall alert when stock falls below minimum threshold.
- FR-INV-004: System shall track garment inventory by status and location.

## Module: Production
- FR-PRD-001: System shall track garment production stages.
- FR-PRD-002: System shall support quality check pass/fail.
- FR-PRD-003: System shall support rewash/reclean workflow.
- FR-PRD-004: System shall track production by operator for performance.

## Module: Delivery
- FR-DEL-001: System shall support route planning with address management.
- FR-DEL-002: System shall track delivery status (assigned, en-route, delivered).
- FR-DEL-003: System shall support delivery confirmation with signature/photo.
- FR-DEL-004: System shall support driver assignment and reassignment.

## Module: Customer Management
- FR-CUS-001: System shall maintain customer profiles with contact info.
- FR-CUS-002: System shall track customer order history.
- FR-CUS-003: System shall support corporate accounts with billing.
- FR-CUS-004: System shall support customer preferences and notes.

## Module: HR & Payroll
- FR-HR-001: System shall manage employee records.
- FR-HR-002: System shall track attendance (check-in/check-out).
- FR-HR-003: System shall calculate payroll with UAE overtime rules.
- FR-HR-004: System shall export SIF files for WPS compliance.
- FR-HR-005: System shall track leave entitlements and balances.

## Module: Finance & Invoicing
- FR-FIN-001: System shall generate invoices with TRN and VAT.
- FR-FIN-002: System shall enforce immutable posted invoices.
- FR-FIN-003: System shall support correction memos for invoice amendments.
- FR-FIN-004: System shall generate financial reports (daily, weekly, monthly).
- FR-FIN-005: System shall track all payments and outstanding balances.

## Module: Reports & Analytics
- FR-RPT-001: System shall generate sales reports by period, branch, employee.
- FR-RPT-002: System shall generate production reports by operator, service type.
- FR-RPT-003: System shall generate financial reports (P&L, cash flow, aging).
- FR-RPT-004: System shall support report export (PDF, CSV).
- FR-RPT-005: System shall display dashboard KPIs.

## Module: Settings & Configuration
- FR-SET-001: System shall support multi-branch configuration.
- FR-SET-002: System shall support service catalog management.
- FR-SET-003: System shall support price list management.
- FR-SET-004: System shall support hardware configuration (printers, scanners).
- FR-SET-005: System shall support backup and restore.