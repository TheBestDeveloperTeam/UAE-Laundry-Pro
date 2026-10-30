# LaundryPro UAE — Screen-by-Screen Zero-Loss Re-Architecture Specifications
## Modules 12 through 22 (Purchasing, Financials, Industrial Telemetry & Human Resources)

---

### 5.12 Purchasing & Goods Receipt (`lib/views/purchasing_screen.dart`)

Enterprise procurement interface for detergent barrels, dry cleaning solvents, packaging films, and boiler chemicals.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Purchasing & Supplier Orders                 [ New PO ] [ Stock Audit ]│
├────────────────────────────────────────────────────────────────────────┤
│ [Search PO #, supplier, item...]          [All Statuses v] [Date Range]│
├────────────────────────────────────────────────────────────────────────┤
│ PO NUMBER  SUPPLIER         ITEMS   ORDER DATE  STATUS    TOTAL (AED)  │
│ PO-2026-08 Ecolab UAE Ltd     4     28 Oct 2026 Received    4,250.00   │
│ PO-2026-07 Al Safa Packaging  12    24 Oct 2026 In Transit  1,890.00   │
│ PO-2026-06 Sealed Air Gulf    2     15 Oct 2026 Closed        850.00   │
│ PO-2026-05 Dubai Chemical Co  5     02 Oct 2026 Draft       6,120.00   │
└────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Purchase Order Lifecycle:**
   - Statuses: `Draft` (gray), `Approved` (blue), `In Transit` (amber), `Received` (teal), `Closed` (emerald), `Cancelled` (red).
2. **Interactive Goods Receipt Modal:**
   - Multi-line comparison of Ordered Quantity vs Received Quantity with batch number recording, expiration date capture, and automatic inventory stock incrementing.

---

### 5.13 Operational Expenses & Petty Cash (`lib/views/expenses_screen.dart`)

Branch petty cash, utility payments (DEWA), equipment maintenance, and van fuel logging.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Operational Expenses & Petty Cash         [ Monthly Budget: AED 15,000 ]│
├─────────────────────────────────────────────────────────┬──────────────┤
│ [Search expenses, categories, vouchers...] [Date Range] │ [+ Record Exp]│
├─────────────────────────────────────────────────────────┴──────────────┤
│ VOUCHER ID CATEGORY     DESCRIPTION       DATE    METHOD   AMOUNT (AED)│
│ EXP-9041   Utilities    DEWA Electricity  29 Oct  Bank Trf    3,420.00 │
│ EXP-9040   Fuel & Fleet Van 02 Fueling    28 Oct  Petty Cash    180.00 │
│ EXP-9039   Maintenance  Boiler Steam Valve27 Oct  Card          650.00 │
│ EXP-9038   Staff WelfareDrinking Water Cans26 Oct Petty Cash     75.00 │
└────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Expense Breakdown Cards:**
   - 3 Summary Widgets: `Total Month Expenses`, `Petty Cash Balance Remaining`, `DEWA & Utilities Share (%)`.
2. **Expense Voucher Entry Dialog:**
   - Category selector, Payment Source (`Petty Cash Drawer`, `Company Bank Card`, `Owner Account`), FTA Tax Invoice Attachment/Receipt Photo upload, 5% Recoverable Input VAT toggle.

---

### 5.14 Bookkeeping, General Ledgers & Vouchers (`lib/views/accounting_screen.dart`)

Double-entry bookkeeping and accounting journal for the laundry operation.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Bookkeeping & General Ledger               [ Trial Balance ] [ P&L Stmt]│
├────────────────────────────────────────────────────────────────────────┤
│ ACCOUNT CODE ACCOUNT NAME          TYPE       DEBIT (AED)  CREDIT (AED)│
│ 1010         Cash in Drawer (POS)  Asset        14,850.00          0.00│
│ 1020         Emirates NBD Checking Asset       142,300.00          0.00│
│ 1200         Accounts Receivable   Asset         8,450.00          0.00│
│ 2010         Accounts Payable      Liability         0.00     12,400.00│
│ 2200         FTA VAT Payable (5%)  Liability         0.00      4,180.00│
│ 4010         Laundry Sales Revenue Revenue           0.00    149,020.00│
└────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Real-time Balance Validation:**
   - Bottom ledger totals showing total Debits and Credits with a green `Balanced` checkmark indicator.
2. **Journal Voucher Entry Screen:**
   - Add multiple debit/credit distribution lines with automatic balance parity enforcement before saving.

---

### 5.15 Commercial Dispatch Challans (`lib/views/challans_screen.dart`)

B2B institutional linen delivery challans for hotels, gyms, salons, and hospitals.

#### Detailed Architecture & State Specifications
1. **Challan Matrix:**
   - Challan ID, Contract Client (e.g. `Raffles Dubai`, `Fitness First Marina`), Delivery Vehicle, Total Pieces Count, Delivery Note Sign-off status.
2. **Item Count Reconciler:**
   - Compares incoming soiled counts against outgoing clean packed counts with automated discrepancy flagging.

---

### 5.16 Industrial Equipment Telemetry (`lib/views/equipment_screen.dart`)

Diagnostics and operating telemetry for heavy commercial washers, hydro-extractors, and tunnel dryers.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Industrial Equipment Telemetry               [ Refresh Telemetry ]     │
├──────────────┬──────────────┬──────────────┬──────────────┬────────────┤
│ WASHER #01   │ WASHER #02   │ DRYER #01    │ DRYER #02    │ STEAM PRESS│
│ Primus 24kg  │ Girbau 32kg  │ Huebsch 30kg │ Huebsch 30kg │ Pony Ironer│
│ STATUS: RUN  │ STATUS: IDLE │ STATUS: RUN  │ STATUS: MAINT│ STATUS: RUN│
│ Temp: 62°C   │ Temp: 24°C   │ Temp: 85°C   │ Temp: --     │ Steam: 6Bar│
│ RPM: 450     │ Water: Empty │ Airflow: OK  │ Sensor Fault │ Temp: 175°C│
│ Time: 14m rem│ Ready        │ Time: 22m rem│ Offline      │ Active     │
└──────────────┴──────────────┴──────────────┴──────────────┴────────────┘
```

#### Detailed Architecture & State Specifications
1. **Live State Indicators:**
   - Color-coded machine cards (`Running` = Green, `Idle` = Blue, `Maintenance` = Amber, `Fault` = Red).
2. **Telemetry Readings:**
   - Real-time display of water temperature, motor RPM, water inlet flow, steam line pressure, and cycle countdown timer.

---

### 5.17 Operator Certifications & Skills (`lib/views/operator_screen.dart`)

Worker qualifications, machine operation permissions, and chemical handling certifications.

#### Detailed Architecture & State Specifications
1. **Operator Matrix:**
   - Employee Name, Badge ID, Certified Machines (`Dry Cleaner`, `Barrier Washer`, `Steam Press`), Hazard Chemical Handling Certification Expiry Date.
2. **Safety & Machine Lockout:**
   - Machine lockout enforcement if operator lacks active certification.

---

### 5.18 RFID Garment & Linen Tracking (`lib/views/rfid_tracking_screen.dart`)

High-speed bulk linen scanning using fixed UHF RFID portals or handheld Zebra/Honeywell RFID wands.

```
┌────────────────────────────────────────────────────────────────────────┐
│ UHF RFID Bulk Linen Scanner               [ Antenna: ACTIVE | 30 dBm ] │
├───────────────────────────────────┬────────────────────────────────────┤
│ Scan Bucket (Scanned: 142 items)  │ Client Contract: Atlantis The Palm │
├───────────────────────────────────┼────────────────────────────────────┤
│ EPC TAG          ITEM TYPE  CYCLES│ Bath Towel White (Large)       60  │
│ E2801160600001   Bath Towel    42 │ Hand Towel White               40  │
│ E2801160600002   Bath Towel    42 │ King Bed Sheet White           30  │
│ E2801160600003   King Sheet    18 │ Pillow Case White              12  │
│ E2801160600004   Bath Mat      55 │ ────────────────────────────────── │
│                                   │ Total Items Reconciled:       142  │
│ [ Bulk Intake ] [ Dispatch Pack ] │ [ Print Challan & Associate PO ]   │
└───────────────────────────────────┴────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Live RFID Tag Ingestion:**
   - High-throughput tag buffer reading up to 200 tags per second from UHF RFID reader.
2. **Linen Lifetime Wear Counter:**
   - Tracks total wash cycles per individual linen piece and raises retirement warnings at >50 cycles.

---

### 5.19 Healthcare Thermal Sterilization (`lib/views/sterilization_screen.dart`)

Clinical laundry sterilization records compliance with UAE Ministry of Health and Prevention (MOHAP) hygiene guidelines.

#### Detailed Architecture & State Specifications
1. **Sterilization Log:**
   - Autoclave / Barrier Washer Batch ID, Hospital Client, Temperature Curve (Hold at 71°C for 3 min or 65°C for 10 min), Bio-Indicator verification, QC Officer Signature.
2. **Audit Certificate Generation:**
   - One-click PDF thermal compliance certificate export for healthcare clients.

---

### 5.20 Employees & Master HR Directory (`lib/views/employees_screen.dart`)

Complete staff directory and employment documentation.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Employees & Staff Directory               [ + Add Employee ] [ Export ]│
├────────────────────────────────────────────────────────────────────────┤
│ [Search by name, ID, role...]                     [All Departments v]  │
├────────────────────────────────────────────────────────────────────────┤
│ EMP ID   FULL NAME     ROLE         BRANCH  EMIRATES ID EXP BASIC WAGE │
│ EMP-0101 Muhammad Arif Master Press  Main    14 Dec 2027     AED 3,200 │
│ EMP-0102 Sunita Sharma Quality Check Main    08 Feb 2028     AED 2,800 │
│ EMP-0103 John Mwangi   Van Driver    Al Barsha22 May 2026    AED 3,000 │
│ EMP-0104 Bilal Tanveer Washer Oper   Main    19 Jan 2027     AED 2,500 │
└────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Emirates ID & Visa Expiry Radar:**
   - Automatic amber/red badges for staff whose UAE residency visa, Emirates ID, or occupational health card expires within 60/30 days.
2. **Compensation Breakdown Dossier:**
   - Basic Salary, Housing Allowance, Transport Allowance, Overtime Hourly Rate.

---

### 5.21 Staff Attendance & Biometrics (`lib/views/attendance_screen.dart`)

Daily clock-in/out, biometric terminal sync, and overtime calculation.

#### Detailed Architecture & State Specifications
1. **Daily Punch Log:**
   - Date, Employee Name, Shift (`Morning 8am-4pm`, `Evening 4pm-12am`), Clock-in, Clock-out, Total Hours, Late Arrival Minutes, Overtime Hours.
2. **One-Click Biometric Sync:**
   - Pulls punch data from ZKTeco / Anviz local TCP/IP time-clocks.

---

### 5.22 Staff Leave & Shift Coverage (`lib/views/leave_screen.dart`)

Annual leave, sick leave, and emergency leave requests per UAE Labour Law.

#### Detailed Architecture & State Specifications
1. **Leave Balance Cards:**
   - Annual Leave Accrued (30 days/year), Sick Leave Taken, Unpaid Leave Days.
2. **Approval Workflow:**
   - Pending leave requests with instant coverage impact view and Approve/Reject buttons.

