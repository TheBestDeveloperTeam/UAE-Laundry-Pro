# Operational Use Cases & Workflow Blueprints

**Product:** LaundryPro UAE / LaundraCore Local  
**Standard:** Enterprise POS/ERP Operational Standard  
**Version:** 1.2.1+4 · PHP 8.2 · MariaDB  

---

## 1. Primary Use-Case Index

| Use Case ID | Name | Primary Actor | Success Criteria |
|---|---|---|---|
| **UC-01** | Splash Screen Self-Healing Boot | Workstation / Cashier | Environment checked, migrations auto-applied, login ready |
| **UC-02** | Walk-In Instant Sale & Payment | Front-Desk Cashier | Customer billed, receipt printed, cash drawer opened, outbox queued |
| **UC-03** | Existing Customer Phone Search | Front-Desk Cashier | History and balances retrieved under 300 ms |
| **UC-04** | Express Surcharge & Garment Modifiers | Front-Desk Cashier | Dynamic line calculation with 50% urgency premium |
| **UC-05** | Production Status Movement | Laundry Operator | Order transitions from Received ? Processing ? Ready |
| **UC-06** | Factory Challan Batch Transfer | Plant Dispatcher | Batch transfer slip printed with item count verification |
| **UC-07** | Driver Dispatch & Delivery Handover | Driver / Cashier | Task dispatched, cash on delivery collected, order marked Delivered |
| **UC-08** | Staff Shift Clock-In & WPS Payroll | Employee / HR | Shifts captured, monthly WPS statement generated with UAE Labour Law |
| **UC-09** | Hardware UMAC Anti-Tamper & Lockout | System Guard | Hardware mismatch or clock rollback immediately halted |
| **UC-10** | Offline-to-Cloud Delta Sync | Background Daemon | Delta outbox pushed to central cloud when connection is active |
| **UC-11** | Split Payment Workflow | Cashier | Process Cash + Card seamlessly |
| **UC-12** | Refund & Correction Memo | Manager | Immutable correction memo generated |
| **UC-13** | Daily Shift Close | Cashier | Z-Report printed and variance logged |
| **UC-14** | Low-Stock Reorder | System | Alert triggered and PO generated |
| **UC-15** | Client Onboarding Wizard | Admin | 8-step initialization completed |
| **UC-11** | Split Payment (Multi-Tender) | Front-Desk Cashier | Invoice settled across = 2 tender types, change calculated correctly, single receipt issued |
| **UC-12** | Refund / Correction Memo | Cashier / Manager | Credit memo raised against original invoice; original invoice never mutated; ledger balanced |
| **UC-13** | Shift Close / Cash Reconciliation | Shift Supervisor | Declared cash vs. system cash variance logged; Z-Report printed; drawer sealed |
| **UC-14** | Inventory Low-Stock Reorder | Store Manager / System | Consumable stock falls below threshold; PO draft auto-generated; supplier notified |
| **UC-15** | 8-Step Onboarding Wizard | Super-Admin / New Tenant | New branch node fully configured: business profile, hardware, license, services, and first test order |

---

## 2. Detailed Workflow Diagrams & Logic Sequences

### UC-01: Splash Screen Self-Healing Boot Sequence

```mermaid
sequenceDiagram
    autonumber
    actor User as Cashier / Operator
    participant App as Flutter Desktop
    participant Guard as SystemGuardService
    participant LocalAPI as Local PHP API (http://laundrypro-localapi)
    participant CloudAPI as Central Cloud API

    User->>App: Launch laundrypro_uae.exe
    App->>App: Render SplashScreen UI (Animated Brand + Progress Bar)
    App->>Guard: Verify Registry Pulse & Hardware UMAC
    alt System Clock Tampered or Invalid
        Guard-->>App: Return EvaluationStatus::TAMPERED
        App->>User: Display Security Alert & Halts POS
    else Hardware Valid
        App->>LocalAPI: GET /api/v1/health
        alt Local API / MySQL Down
            LocalAPI-->>App: Connection Refused
            App->>User: Display Non-Technical Fix Instructions (Check XAMPP)
            User->>App: Click Exit Application or Retry
        else Local API Healthy
            App->>LocalAPI: GET /api/v1/install/status
            opt Migrations Pending
                App->>LocalAPI: POST /api/v1/install/migrate
                LocalAPI-->>App: 200 OK (Migrations applied)
            end
            App->>CloudAPI: Background Async Ping (non-blocking)
            App->>App: Navigate to Login / Dashboard
        end
    end
```

**Business Rules**

- Hardware UMAC check runs before any network call; a mismatch blocks all POS operations.
- Clock rollback of > 5 minutes triggers `EvaluationStatus::TAMPERED` and halts login.
- Migration script is idempotent; running it on an up-to-date schema is a no-op.

---

### UC-02: Walk-In Instant Sale & Payment Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Cashier as Cashier
    participant UI as POS Cart Screen
    participant Peripherals as Thermal Printer & Drawer
    participant API as Local PHP API
    participant DB as MariaDB

    Cashier->>UI: Select Items (e.g., 2x Kandora Dry Clean, 1x Suit Steam Press)
    UI->>UI: Calculate Line Totals + 5% UAE VAT
    Cashier->>UI: Click Checkout (Total: 73.50 AED)
    Cashier->>UI: Input Tender (100.00 AED Cash)
    UI->>UI: Calculate Change (26.50 AED)
    Cashier->>UI: Confirm Transaction
    UI->>API: POST /api/v1/sales/orders (Lines, Customer, Payment)
    API->>DB: Begin Transaction
    API->>DB: INSERT sales_orders & freeze price snapshots
    API->>DB: INSERT payment_transactions
    API->>DB: INSERT sync_outbox (status='pending')
    API->>DB: COMMIT
    API-->>UI: 200 OK (Order LP-2026-00109 Created)
    UI->>Peripherals: Send Raw ESC/POS Stream
    Peripherals->>Peripherals: Print 80 mm Receipt
    Peripherals->>Peripherals: Send Pin-2 Drawer Pulse (Drawer Opens)
    UI->>UI: Clear Cart for Next Customer
```

**Business Rules**

- Price snapshots are stored at order time; subsequent service price changes never retroactively alter historical invoices.
- VAT is calculated at 5% on the taxable subtotal using bcmath to avoid floating-point rounding errors.
- The sync_outbox record ensures cloud replication even when the network is unavailable at sale time.

---

### UC-03: Existing Customer Phone Search

```mermaid
sequenceDiagram
    autonumber
    actor Cashier as Cashier
    participant UI as Customer Search Bar
    participant API as Local PHP API
    participant DB as MariaDB

    Cashier->>UI: Type "+971 50 123 4567" (or partial "123 4567")
    UI->>API: GET /api/v1/customers?search=0501234567 (debounced 200 ms)
    API->>DB: SELECT with LIKE on mobile_normalized
    DB-->>API: Customer record (id, name, balance, loyalty_points)
    API-->>UI: 200 OK (JSON customer list)
    UI->>UI: Render customer card with order history badge
    Cashier->>UI: Select customer ? auto-attach to active cart
```

**Business Rules**

- Search is normalised (leading zeros, country prefix stripped) before querying.
- Response target: = 300 ms on local MariaDB; index on `mobile_normalized` column is mandatory.
- Walk-in customers use a system placeholder record (id = 1); no personal data stored.

---

### UC-04: Express Surcharge & Garment Modifiers

```mermaid
sequenceDiagram
    autonumber
    actor Cashier as Cashier
    participant UI as POS Line Editor
    participant API as Local PHP API

    Cashier->>UI: Add "Kandora - Dry Clean" @ 35.00 AED
    Cashier->>UI: Toggle "Express Service" modifier
    UI->>UI: Apply +50% surcharge ? line total 52.50 AED
    Cashier->>UI: Toggle "Fragrance" add-on @ +2.00 AED flat
    UI->>UI: Recalculate line: 52.50 + 2.00 = 54.50 AED
    UI->>UI: Recalculate cart VAT (5%) and grand total
    Cashier->>UI: Confirm Checkout
    UI->>API: POST /api/v1/sales/orders (lines with modifier metadata)
    API-->>UI: 200 OK
```

**Business Rules**

- Express surcharge is always 50% of the base service rate, never compounded on other modifiers.
- Flat add-on modifiers (Fragrance, Starch, Stain Treatment) are added after the percentage surcharge.
- All modifier choices are stored in `order_line_modifiers` for audit and reporting.

---

### UC-05: Production Status Movement

```mermaid
sequenceDiagram
    autonumber
    actor Op as Laundry Operator
    participant UI as Order Board
    participant API as Local PHP API
    participant DB as MariaDB

    Op->>UI: Open Order #LP-2026-00109 (Status: Received)
    Op->>UI: Click "Move to Processing"
    UI->>API: PUT /api/v1/orders/109/status {status: "processing"}
    API->>DB: UPDATE sales_orders SET status='processing', updated_at=NOW()
    API->>DB: INSERT order_status_history (order_id, from, to, changed_by, changed_at)
    API-->>UI: 200 OK
    UI->>UI: Refresh order card to "In Processing" badge
    Op->>UI: Click "Mark Ready for Pickup"
    UI->>API: PUT /api/v1/orders/109/status {status: "ready"}
    API->>DB: UPDATE & INSERT history
    API-->>UI: 200 OK
```

**Business Rules**

- Status transitions are enforced server-side: `received ? processing ? ready ? delivered`.
- Skipping a state (e.g., `received ? delivered`) is rejected with HTTP 422.
- Every transition is logged in `order_status_history` with operator identity and timestamp.

---

### UC-06: Factory Challan Batch Transfer

```mermaid
sequenceDiagram
    autonumber
    actor Disp as Plant Dispatcher
    participant UI as Challan Screen
    participant API as Local PHP API
    participant Printer as Thermal Printer

    Disp->>UI: Select orders for factory run (tick checkboxes)
    UI->>API: POST /api/v1/challans {order_ids: [109, 110, 111]}
    API->>API: Validate all orders are in "processing" status
    API->>API: Generate Challan #CH-2026-0042 with item count
    API-->>UI: 200 OK (challan_id, item_count: 14, barcode)
    UI->>Printer: Print Challan slip (80 mm) with barcode
    Disp->>UI: Confirm physical handover to transport driver
    UI->>API: PUT /api/v1/challans/42/confirm
    API-->>UI: 200 OK (status: dispatched)
```

**Business Rules**

- A Challan can only include orders in `processing` status; mixing statuses is rejected.
- Item count on the printed slip must match the digital count; driver verifies and signs.
- Challans are immutable once confirmed; corrections require a new Challan with a note referencing the prior one.

---

### UC-07: Driver Dispatch & Delivery Handover Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Driver as Driver
    actor Customer as Customer
    participant App as Workstation / Tablet
    participant API as Local PHP API

    Driver->>Customer: Arrive at Residence with Packaged Laundry
    Customer->>Driver: Inspect Garments & Pay 150 AED Cash
    Driver->>App: Mark Order #LP-1082 Delivered
    App->>API: PUT /api/v1/delivery/tasks/45/complete (collected: 150 AED)
    API->>API: Update sales_orders status to 'delivered'
    API->>API: Insert payment record
    API-->>App: 200 OK
    Driver->>Customer: Provide Printed or Digital Receipt
```

**Business Rules**

- Cash-on-delivery amount collected must equal the outstanding invoice balance; partial payments trigger a credit-note workflow (see UC-12).
- Delivery tasks are assigned to a named driver record; anonymous delivery is not permitted.
- GPS timestamp is recorded (if device location service is active) for proof of delivery.

---

### UC-08: Staff Shift Clock-In & WPS Payroll

```mermaid
sequenceDiagram
    autonumber
    actor Staff as Employee
    actor HR as HR Manager
    participant UI as Attendance Screen
    participant API as Local PHP API
    participant DB as MariaDB

    Staff->>UI: Select profile / scan employee barcode
    UI->>API: POST /api/v1/attendance/clock-in {employee_id, timestamp}
    API->>DB: INSERT attendance_records (clock_in=NOW())
    API-->>UI: 200 OK (session started)
    Note over Staff,UI: Shift ends
    Staff->>UI: Tap Clock Out
    UI->>API: POST /api/v1/attendance/clock-out {employee_id}
    API->>DB: UPDATE attendance_records SET clock_out=NOW(), hours_worked=TIMEDIFF(...)
    API-->>UI: 200 OK (hours: 8.5)
    HR->>UI: Navigate to Payroll > Generate WPS Statement (month)
    UI->>API: GET /api/v1/payroll/wps?month=2026-09
    API->>DB: Aggregate attendance + salary rates
    API-->>UI: WPS-compliant CSV/PDF
```

**Business Rules**

- Overtime (> 8 h/day) is calculated at 1.25× base rate per UAE Labour Law Article 67.
- WPS file format follows the UAE Central Bank SIF specification.
- Clock-in without a preceding clock-out on the same calendar day triggers an HR alert.

---

### UC-09: Hardware UMAC Anti-Tamper & Lockout

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter Desktop
    participant Guard as SystemGuardService
    participant Registry as Windows Registry
    participant API as Local PHP API

    App->>Guard: Evaluate() on every boot
    Guard->>Registry: Read stored UMAC hash
    Guard->>Guard: Compute live UMAC from network adapters
    alt Hash mismatch (hardware changed)
        Guard-->>App: EvaluationStatus::HARDWARE_MISMATCH
        App->>App: Block login, display lockout screen
    else Clock rollback detected
        Guard-->>App: EvaluationStatus::CLOCK_TAMPERED
        App->>App: Block login, display security alert
    else All checks pass
        Guard-->>App: EvaluationStatus::VALID
        App->>API: Continue boot sequence
    end
```

**Business Rules**

- UMAC is derived from the primary network adapter MAC + Windows machine GUID; both must match the stored hash.
- System clock must be within ±5 minutes of the last recorded timestamp stored in the Registry.
- After 3 consecutive lockout events, a flag is set in `system_events` and a cloud notification is sent to the super-admin.

---

### UC-10: Offline-to-Cloud Delta Sync Sequence

```mermaid
sequenceDiagram
    autonumber
    participant LocalOutbox as sync_outbox Table
    participant Daemon as sync_scheduler.php
    participant Cloud as Central Cloud Gateway (cloud-api)
    participant CloudDB as laundrypro_cloud

    loop Every 60 Seconds
        Daemon->>LocalOutbox: SELECT * WHERE status='pending' LIMIT 50
        alt Has Pending Records
            Daemon->>Cloud: POST /api/v1/sync/push (Batch + Bearer Token)
            alt Cloud Ingest Successful
                Cloud->>CloudDB: INSERT INTO sync_records (tenant_id, entity, payload)
                Cloud-->>Daemon: 200 OK (synced_ids: [1, 2, 3...])
                Daemon->>LocalOutbox: UPDATE status='synced', synced_at=NOW()
            else Network Error / Offline
                Daemon->>LocalOutbox: Increment retry_count, sleep with exponential backoff
            end
        end
    end
```

**Business Rules**

- Batch size is capped at 50 records per cycle to avoid cloud gateway timeouts.
- Exponential back-off starts at 60 s and caps at 30 minutes after 5 consecutive failures.
- Records that fail > 20 retries are flagged `status='dead_letter'` and trigger an admin alert.

---

### UC-11: Split Payment (Multi-Tender)

```mermaid
sequenceDiagram
    autonumber
    actor Cashier as Cashier
    participant UI as POS Payment Screen
    participant API as Local PHP API
    participant DB as MariaDB
    participant Printer as Thermal Printer & Drawer

    Cashier->>UI: Confirm cart (Total: 210.00 AED)
    Cashier->>UI: Click "Split Payment"
    Cashier->>UI: Enter Cash tender: 100.00 AED
    UI->>UI: Remaining balance: 110.00 AED
    Cashier->>UI: Select "Card / Terminal" for remaining 110.00 AED
    Cashier->>UI: Confirm card approved on terminal
    UI->>UI: Validate: sum of tenders = 210.00 AED (no gap, no overpay on card)
    Cashier->>UI: Click "Finalize Split Payment"
    UI->>API: POST /api/v1/sales/orders (lines + split_payments array)
    API->>DB: BEGIN TRANSACTION
    API->>DB: INSERT sales_orders (total: 210.00)
    API->>DB: INSERT payment_transactions (method: cash, amount: 100.00)
    API->>DB: INSERT payment_transactions (method: card, amount: 110.00)
    API->>DB: INSERT sync_outbox (pending)
    API->>DB: COMMIT
    API-->>UI: 200 OK (Order LP-2026-00241 Created)
    UI->>Printer: Print single consolidated receipt (both tender lines shown)
    Printer->>Printer: Cash drawer pulse (cash portion only)
    UI->>UI: Clear Cart
```

**Business Rules**

- The sum of all split tender amounts must equal the invoice total exactly; the API rejects any discrepancy with HTTP 422.
- Cash-over-tender (change) applies only to the cash leg; card amounts are exact.
- A single receipt is printed showing every payment leg; the receipt header reads "Split Payment – 2 Methods".
- Split tenders are stored as separate rows in `payment_transactions` all linked to the same `sales_order_id`.
- Credit (Account) can be one leg of a split; the credit limit check fires before the transaction is committed.

---

### UC-12: Refund / Correction Memo

> **Policy:** Original invoices are immutable. All corrections use a Credit Memo (negative invoice) that references the original order number.

```mermaid
sequenceDiagram
    autonumber
    actor Manager as Manager / Cashier
    participant UI as Order Detail Screen
    participant API as Local PHP API
    participant DB as MariaDB
    participant Printer as Thermal Printer

    Manager->>UI: Open original Order #LP-2026-00109
    Manager->>UI: Click "Issue Refund / Correction Memo"
    UI->>UI: Display refund dialog (full or partial line selection)
    Manager->>UI: Select lines to refund (e.g., 1x Kandora @ 52.50 AED)
    Manager->>UI: Enter reason: "Garment returned unsatisfactory"
    Manager->>UI: Confirm
    UI->>API: POST /api/v1/credit-memos {original_order_id: 109, lines: [...], reason: "..."}
    API->>DB: BEGIN TRANSACTION
    API->>DB: INSERT credit_memos (ref_order_id=109, total=-52.50, reason, created_by)
    API->>DB: INSERT credit_memo_lines (negative quantities)
    API->>DB: UPDATE customer_ledger (credit += 52.50) OR INSERT refund payment record
    API->>DB: INSERT sync_outbox (entity: credit_memo, pending)
    API->>DB: COMMIT
    API-->>UI: 200 OK (Credit Memo #CM-2026-00019 created)
    UI->>Printer: Print Credit Memo receipt (headed "CORRECTION MEMO - NOT AN INVOICE")
    Manager->>Manager: Return cash to customer or apply as account credit
```

**Business Rules**

- `sales_orders` rows are never updated or deleted for correction purposes; the original record is the immutable source of truth.
- Credit memos carry a negative total and reference `ref_order_id`; financial reports net them against gross sales.
- A memo can be full (entire invoice) or partial (selected lines only); quantity refunded cannot exceed quantity originally sold.
- Refund method choices: **Cash Return**, **Account Credit**, or **Voucher**; method is stored on the memo record.
- Manager-level role (`role >= manager`) is required to issue a credit memo; cashier-only accounts are blocked.
- Every memo creation is logged in `audit_log` with operator ID, original order ID, and refund amount.

---

### UC-13: Shift Close / Cash Reconciliation

```mermaid
sequenceDiagram
    autonumber
    actor Supervisor as Shift Supervisor
    participant UI as Shift Close Screen
    participant API as Local PHP API
    participant DB as MariaDB
    participant Printer as Thermal Printer

    Supervisor->>UI: Navigate to Reports > Shift Close
    UI->>API: GET /api/v1/reports/shift-summary?shift_date=2026-09-10&cashier_id=7
    API->>DB: Aggregate cash transactions, opening float, card totals for shift
    API-->>UI: Summary (System Cash: 4,250.00 AED, Card: 1,800.00 AED)
    Supervisor->>UI: Enter physically counted cash: 4,220.00 AED
    UI->>UI: Compute variance: -30.00 AED (short)
    Supervisor->>UI: Enter variance reason: "Customer change error"
    Supervisor->>UI: Click "Close Shift & Print Z-Report"
    UI->>API: POST /api/v1/shifts/close {declared_cash, variance, reason, cashier_id}
    API->>DB: INSERT shift_closures (system_cash, declared_cash, variance, closed_by, closed_at)
    API->>DB: INSERT audit_log (action: shift_close, details)
    API->>DB: INSERT sync_outbox (entity: shift_closure, pending)
    API-->>UI: 200 OK (Shift #SC-2026-0087 closed)
    UI->>Printer: Print Z-Report (totals, variance, supervisor signature line)
    UI->>UI: Lock POS for current shift; prompt for new shift opening float
```

**Business Rules**

- A shift cannot be closed if any order remains in `pending_payment` status.
- Variance within ±5 AED auto-flags as "Minor"; variance > 50 AED requires a mandatory reason comment.
- Z-Report is the authoritative end-of-shift document; it cannot be reprinted or modified after closure.
- Opening float for the next shift must be declared before the first sale of the new shift can proceed.
- Shift closure record syncs to cloud so that franchise head office can monitor branch variances in real-time.

---

### UC-14: Inventory Low-Stock Reorder

```mermaid
sequenceDiagram
    autonumber
    participant Cron as Inventory Monitor (cron / scheduled task)
    participant DB as MariaDB
    participant API as Local PHP API
    participant UI as Notifications Panel
    participant WhatsApp as WhatsApp Business API

    loop Every 6 Hours
        Cron->>DB: SELECT items WHERE qty_on_hand <= reorder_point
        alt Low-stock items found
            Cron->>API: POST /api/v1/purchase-orders/draft (supplier_id, items)
            API->>DB: INSERT purchase_orders (status='draft', items, created_at)
            API->>DB: INSERT notifications (type='low_stock', severity='warning')
            API-->>Cron: 200 OK (PO #PO-2026-0031 drafted)
            Cron->>WhatsApp: Send template message to supplier (item list, quantities)
        end
    end
    UI->>API: GET /api/v1/notifications?unread=true
    API-->>UI: Notification list with PO link
    UI->>UI: Display badge on Inventory nav item
```

**Business Rules**

- Reorder point and reorder quantity are configurable per inventory item in the stock master.
- Draft POs require manager approval before converting to confirmed orders sent to suppliers.
- The WhatsApp notification is non-blocking; if the API call fails the PO draft is still created locally.
- Consumables tracked include: plastic bags, hangers, garment covers, detergents, dry-clean solvent (Perc).
- Stock quantities are decremented automatically when a sales order is confirmed (if item-to-service mapping exists).

---

### UC-15: 8-Step Onboarding Wizard

```mermaid
sequenceDiagram
    autonumber
    actor SA as Super-Admin
    actor Tenant as New Tenant Owner
    participant Wizard as Onboarding Wizard (Flutter)
    participant LocalAPI as Local PHP API
    participant CloudAPI as Central Cloud API

    SA->>CloudAPI: Create Tenant record (business name, trade license, contact)
    CloudAPI-->>SA: Tenant ID + Bearer token
    Tenant->>Wizard: Step 1 - Enter Bearer token (from SA)
    Wizard->>LocalAPI: POST /api/v1/setup/token-verify
    LocalAPI-->>Wizard: Token valid - proceed
    Tenant->>Wizard: Step 2 - Business Profile (name, address, TRN, logo upload)
    Tenant->>Wizard: Step 3 - Hardware Registration (UMAC auto-read)
    Wizard->>CloudAPI: POST /api/v1/licenses/request {umac, tenant_id}
    CloudAPI-->>Wizard: License key LP-XXXX-XXXX
    Wizard->>LocalAPI: POST /api/v1/setup/license-activate
    LocalAPI-->>Wizard: License active
    Tenant->>Wizard: Step 4 - Printer & Drawer Setup (test print)
    Tenant->>Wizard: Step 5 - Service Price Catalogue (import CSV or manual entry)
    Tenant->>Wizard: Step 6 - Staff & Role Creation (add at least 1 cashier)
    Tenant->>Wizard: Step 7 - Opening Float Declaration (cash in drawer)
    Tenant->>Wizard: Step 8 - Test Order (guided walk-through of first sale)
    Wizard->>LocalAPI: POST /api/v1/setup/complete
    LocalAPI-->>Wizard: Onboarding flag set; redirect to live Dashboard
```

**Business Rules**

- Steps must be completed in sequence; the wizard enforces linear progression with back-navigation allowed.
- Step 3 (Hardware Registration) auto-reads the UMAC from the local machine; manual entry is available for edge cases only.
- Step 5 supports bulk import via a CSV template (downloadable from the wizard); individual manual entry is capped at 200 services for wizard performance.
- Step 8 test order is flagged `is_test=true` and excluded from all financial reports; it can be voided without a credit memo.
- Wizard completion sets `onboarding_complete=1` in `system_settings`; subsequent boots skip the wizard entirely.
- Incomplete onboarding (steps 1-6 done, steps 7-8 not) allows limited read-only access; POS transactions are blocked until the wizard is fully completed.


