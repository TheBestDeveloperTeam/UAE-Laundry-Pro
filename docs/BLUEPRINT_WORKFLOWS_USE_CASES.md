# Operational Use Cases & Workflow Blueprints

**Product:** LaundryPro UAE / LaundraCore Local  
**Standard:** Enterprise POS/ERP Operational Standard  

---

## 1. Primary Use-Case Index

| Use Case ID | Name | Primary Actor | Success Criteria |
|---|---|---|---|
| **UC-01** | Splash Screen Self-Healing Boot | Workstation / Cashier | Environment checked, migrations auto-applied, login ready |
| **UC-02** | Walk-In Instant Sale & Payment | Front-Desk Cashier | Customer billed, receipt printed, cash drawer opened, outbox queued |
| **UC-03** | Existing Customer Phone Search | Front-Desk Cashier | History and balances retrieved under 300ms |
| **UC-04** | Express Surcharge & Garment Modifiers | Front-Desk Cashier | Dynamic line calculation with 50% urgency premium |
| **UC-05** | Production Status Movement | Laundry Operator | Order transitions from Received -> Processing -> Ready |
| **UC-06** | Factory Challan Batch Transfer | Plant Dispatcher | Batch transfer slip printed with item count verification |
| **UC-07** | Driver Dispatch & Delivery Handover | Driver / Cashier | Task dispatched, cash on delivery collected, order marked Delivered |
| **UC-08** | Staff Shift Clock-In & WPS Payroll | Employee / HR | Shifts captured, monthly WPS statement generated with UAE Labour Law |
| **UC-09** | Hardware UMAC Anti-Tamper & Lockout | System Guard | Hardware mismatch or clock rollback immediately halted |
| **UC-10** | Offline-to-Cloud Delta Sync | Background Daemon | Delta outbox pushed to central cloud when connection is active |

---

## 2. Detailed Workflow Diagrams & Logic Sequences

### UC-01: Splash Screen Self-Healing Boot Sequence

`mermaid
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
            App->>User: Display Non-Technical Fix Instructions ( Check XAMPP)
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
`

---

### UC-02: Walk-In Instant Sale & Payment Workflow

`mermaid
sequenceDiagram
    autonumber
    actor Cashier as Cashier
    participant UI as POS Cart Screen
    participant Peripherals as Thermal Printer & Drawer
    participant API as Local PHP API
    participant DB as MySQL DB

    Cashier->>UI: Select Items (e.g., 2x Kandora Dry Clean, 1x Suit Steam Press)
    UI->>UI: Calculate Line Totals + 5% UAE VAT
    Cashier->>UI: Click Checkout (Total: 73.50 AED)
    Cashier->>UI: Input Tender (100.00 AED Cash)
    UI->>UI: Calculate Change (26.50 AED)
    Cashier->>UI: Confirm Transaction
    UI->>API: POST /api/v1/sales/orders (Lines, Customer, Payment)
    API->>DB: Begin Transaction
    API->>DB: INSERT sales_orders & freeze snapshots
    API->>DB: INSERT payment_transactions
    API->>DB: INSERT sync_outbox (pending)
    API->>DB: Commit
    API-->>UI: 200 OK (Order LP-2026-00109 Created)
    UI->>Peripherals: Send Raw ESC/POS Stream
    Peripherals->>Peripherals: Print 80mm Receipt
    Peripherals->>Peripherals: Send Pin-2 Drawer Pulse (Drawer Opens)
    UI->>UI: Clear Cart for Next Customer
`

---

### UC-07: Driver Delivery Handover Sequence

`mermaid
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
`

---

### UC-10: Offline-to-Cloud Delta Sync Sequence

`mermaid
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
`