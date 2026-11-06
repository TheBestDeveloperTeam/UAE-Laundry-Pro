# LaundryPro UAE — Enterprise Use Cases Specification
**Version:** 3.0.0 (Royal Futuristic Business OS)  
**Status:** Approved & Implemented  
**Compliance:** UAE VAT 5% (FTA Executive Regulation), UAE Wages Protection System (WPS), Offline-First Edge Protocol.

---

## 1. Executive Summary
This document codifies the exhaustive end-to-end use cases supported across all 33 operational, financial, logistics, and administrative screens of the LaundryPro UAE Business OS. Each use case is defined with its actor, triggers, pre-conditions, transactional flow, failure recovery paths, and ledger/audit trail logging.

---

## 2. Core Operational Use Cases

### UC-01: Express Walk-In POS Order Intake & Barcode Generation
- **Actor:** Cashier / Counter Operator
- **Screen:** `PosScreen` (`/pos`)
- **Pre-Conditions:** Register terminal authenticated (e.g. `T01`), local SQLite database connected.
- **Trigger:** Customer arrives with laundry bundles at branch front counter.
- **Flow:**
  1. Operator scans or selects service items from category grid (e.g. "Abaya Premium Care", "Dry Cleaning Suit").
  2. Operator enters/scans customer phone number (`05x xxx xxxx`). If missing, creates customer inline or defaults to Walk-In.
  3. System calculates line totals, applies order-level discounts, adds statutory 5% UAE VAT, and outputs total in AED (`DECIMAL(18,2)`).
  4. Operator presses `Confirm Order` (`F2`).
  5. System creates order atomically in local SQLite with status `received`, prints dual ESC/POS thermal receipt (Customer copy + Garment bundle tag with Code128 barcode).
- **Post-Conditions:** Order record queued in `sync_outbox` for cloud replication; real-time dashboard pipeline counter for `Received` increments.

### UC-02: Stage-Gated Garment Production Workflow
- **Actor:** Plant Supervisor / Dry Cleaning Specialist
- **Screen:** `ProductionScreen` (`/production`)
- **Trigger:** Garments arrive at central wash/dry facility.
- **Flow:**
  1. Operator scans garment tag barcode or selects order from `Received` Kanban column.
  2. Operator transitions order to `Washing` $\to$ assigns cycle parameters (temperature, solvent, detergent volume).
  3. On cycle finish, operator transitions order to `Finishing` (Ironing / QC Inspection / Bagging).
  4. Operator marks order `Ready`. Automated SMS/WhatsApp webhook triggers to notify the customer for collection.
- **Exception Path:** Stained/Damaged item logged with defect photo and customer approval flag before reprocessing.

### UC-03: Multi-Method POS Payment Settlement
- **Actor:** Cashier
- **Screen:** `PosScreen` (`/pos`) / `PendingInvoicesScreen` (`/pending`)
- **Flow:**
  1. Operator opens pending order via search or barcode scan.
  2. System presents payment modal supporting:
     - Cash (calculates exact change in AED).
     - Card / Contactless POS Terminal.
     - Customer Account Balance / Credit.
     - Split Tender (e.g., AED 50 Cash + AED 95 Card).
  3. On confirmation, system updates `orders.status = 'paid'`, generates immutable payment record, and logs audit record.

---

## 4. Financial & Compliance Use Cases

### UC-04: UAE FTA VAT Return Generation & Tax Audit Log
- **Actor:** Finance Manager / Certified Tax Agent
- **Screen:** `ReportsScreen` (`/reports`) / `AccountingScreen` (`/accounting`)
- **Pre-Conditions:** Orders, expenses, and invoices finalized for tax period.
- **Flow:**
  1. System aggregates all Standard Rated Supplies (Box 1a) with 5% VAT.
  2. System aggregates recoverable input tax on business expenses and chemical supplies.
  3. Outputs FTA-compliant Tax Invoice XML/PDF with mandatory TRN, Arabic tax invoice label (`فاتورة ضريبية`), and itemized VAT breakdown.

### UC-05: Wage Protection System (WPS) SIF File Export
- **Actor:** HR Manager / Payroll Accountant
- **Screen:** `PayrollScreen` (`/payroll`)
- **Flow:**
  1. System calculates net monthly salaries deducting advances, unpaid leaves, and adding approved overtime.
  2. Generates standard Ministry of Human Resources and Emiratisation (MOHRE) Salary Information File (`.SIF`).
  3. Validates 14-digit Employer Routing Code, Employee Labor Card Numbers, and IBAN formats.

---

## 5. Hardware & Edge Terminal Use Cases

### UC-06: Seamless Offline POS Operation & Reconnect Reconciliation
- **Actor:** System / Cashier
- **Screen:** Omnipresent / `AppShell`
- **Flow:**
  1. Network connection drops; hardware status strip illuminates amber (`Offline Mode`).
  2. System routes all sales, customer edits, and stock receipts directly to local SQLite database.
  3. Operations execute at full speed without network timeout lag.
  4. Upon network reconnection, `SyncEngine` initiates bidirectional synchronization:
     - Outbox push of local sales via idempotent UUIDs.
     - Pull of catalog updates with conflict resolution preferring server timestamps for pricing.
