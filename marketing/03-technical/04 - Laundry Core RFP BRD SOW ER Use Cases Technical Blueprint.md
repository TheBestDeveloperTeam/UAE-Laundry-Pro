# LaundraCore Local

> **Project Name:** LaundraCore Local  
> **Project Type:** Offline-First Local Laundry Services CRM + Local ERP + Local CMS + Instant Sales + Service/Product Inventory  
> **Developed and Maintained By:** Magnificent Solution  
> **Client Profile:** UAE Local Laundry Service MSME Vendor  
> **Initial Deployment Area:** Dubai, UAE  
> **Expansion Path:** Abu Dhabi, Sharjah, Ajman, Umm Al Quwain, Fujairah, Ras Al Khaimah, other UAE Emirates, KSA-ready localization  
> **Primary Platform:** Flutter Windows Desktop Standalone  
> **Local Database:** MariaDB/MySQL under XAMPP  
> **Local API:** PHP REST API layer  
> **Architecture:** MVVM + Modular Domain Architecture + Local Microservice-Oriented Components + Repository Pattern + Event/Audit Pipeline  
> **Authentication:** OAuth 2.0 concepts + JWT session/access-token model for local API boundary  
> **API Documentation:** OpenAPI/Swagger  
> **Internet Dependency:** None for core business operation  
> **Payment Gateway:** Not required  
> **Initial Currency:** AED with sub-unit Fils  
> **Language:** English + Arabic  
> **Direction:** LTR/RTL dynamically controlled by JSON localization configuration  
> **UI Philosophy:** Dedicated desktop operator workstation, not a generic website and not a browser-dashboard imitation

---

## 0. EXECUTIVE DESIGN DECISION

LaundraCore Local shall be designed as a **local business operating system for a laundry MSME**, not as a web-like CRUD application. The system must optimize for fast counter operation, minimal mouse travel, keyboard/touch/scanner workflows, reliable offline operation, transaction recoverability, document traceability, bilingual operation, and gradual expansion without forcing cloud dependency.

The primary operator experience shall revolve around:

1. **Instant Sale / New Order**
2. **Customer Search / Walk-In Customer**
3. **Service + Product selection**
4. **Quantity/rate/discount/tax-free commercial calculation according to configuration**
5. **Order status and production movement**
6. **Payment collection / pending amount**
7. **Print / reprint invoice, memo, challan, receipt, label**
8. **Delivery / collection workflow**
9. **Inventory and adjustment control**
10. **Daily closing and operational reporting**

The architecture shall separate:

- UI presentation
- validation and application state
- business rules
- transactional orchestration
- persistence
- file storage
- printing
- backup/recovery
- localization
- licensing and hardware identity
- audit history

The system shall never depend on a remote API for core sales, stock, service status, invoice generation, or historical records.

---

# 1. RFP — REQUEST FOR PROPOSAL

## 1.1 RFP Objective

Magnificent Solution proposes to design, develop, test, deploy, document, and maintain a Windows desktop standalone solution for a UAE laundry MSME. The solution shall unify local customer management, vendor management, service catalog, product catalog, grouped service/product bundles, service-product relationships, instant sales, payments, receipts, challans, production/service status, inventory, procurement, employee management, attendance, leave, payroll, salary advances, operating expenses, reporting, local file management, backup, disaster recovery, licensing, and UMAC controls.

## 1.2 Business Problem

Typical local laundries commonly operate with fragmented notebooks, spreadsheets, standalone billing software, messaging applications, printed slips, manually tracked pending payments, and informal production status communication. Such fragmentation creates:

- duplicated customer records;
- unclear order status;
- forgotten collection dates;
- weak pending-payment tracking;
- service-rate inconsistency;
- stock leakage;
- difficulty reconciling cash and credit;
- weak employee accountability;
- manual payroll calculation;
- difficult vendor purchase tracking;
- inconsistent invoice printing;
- no controlled backup and restoration path;
- poor auditability;
- dependence on one operator's memory.

LaundraCore Local addresses those issues through a single transactional platform operating on the client's local machine/network.

## 1.3 RFP Scope

### Core Modules

- System Setup
- Business Profile
- Branch/Location readiness
- User and Role Management
- Licensing and UMAC
- Localization and Language
- Service Master
- Product Master
- Service Groups
- Product Groups
- Service/Product Relationships
- Modifiers
- Customer Master
- Vendor Master
- Sales / Instant Sale
- Orders / Work Orders
- Delivery and Collection
- Credit/Debit/Cash Payment
- Pending Invoices
- Credit Memo / Debit Memo
- Product Inventory
- Service Consumption / Operational Material Tracking
- Purchase and Vendor Transactions
- Stock Receipts
- Stock Adjustments
- Human Resources
- Attendance
- Leave
- Payroll
- Salary Advance
- Operating Expenses
- Print Templates
- Invoice/Receipt/Challan/Report formatting
- Notifications and Alerts
- Local File Management
- Import/Export
- Auto Backup
- Disaster Recovery
- Audit Trail
- Dashboard and Reports
- Shareable receipt assets
- Peripheral integration abstraction

## 1.4 Out of Scope at Initial Release

The initial release shall not require:

- cloud hosting;
- payment gateway integration;
- online marketplace;
- public customer website;
- mandatory mobile app;
- mandatory SMS gateway;
- mandatory WhatsApp API;
- foreign exchange live-rate API;
- bank API;
- biometric device vendor-specific SDK;
- external accounting package synchronization.

Architecture shall preserve extension points for those capabilities in later phases.

---

# 2. PROJECT NAME SELECTION

## Recommended Name: LaundraCore Local

### Rationale

`LaundraCore` communicates the idea of a core operating platform for laundry businesses. `Local` intentionally distinguishes the product from cloud-only POS products and communicates offline-first/local-control positioning.

### Product Family Strategy

- `LaundraCore Local` — offline/local desktop edition
- `LaundraCore Pro` — multi-terminal/local-network edition
- `LaundraCore Cloud` — future cloud edition
- `LaundraCore KSA` — future Saudi localization package
- `LaundraCore UAE` — UAE localization package

The product identifier should remain stable even if commercial packaging changes.

---

# 3. BRD — BUSINESS REQUIREMENTS DOCUMENT

## 3.1 Vision

Provide a fast, dependable, bilingual, offline-first business platform that allows a laundry owner to run daily operations from customer intake through service processing, inventory movement, payment collection, delivery/collection, payroll, expense control, and reporting.

## 3.2 Business Goals

### G1 — Fast Counter Operation

A trained cashier shall be able to create a normal laundry order without opening multiple unrelated screens.

### G2 — Accurate Commercial Calculation

Every line shall preserve quantity, rate, discount/modifier impacts, gross amount, net amount, payment allocation, and final balance with deterministic decimal arithmetic.

### G3 — Traceable Item Lifecycle

Laundry items/services shall move through clearly defined statuses.

### G4 — Stock Accountability

Product receipts, issues, adjustments, transfers, and closing balances shall be traceable.

### G5 — Employee Accountability

Employee attendance, leave, salary, advances, and operational responsibility shall be controlled.

### G6 — Offline Reliability

No business-critical transaction shall be blocked merely because the internet is unavailable.

### G7 — Bilingual Usability

Static labels and validations shall be JSON-controlled and rendered in English or Arabic with dynamic LTR/RTL UI direction.

### G8 — Deployment Control

The solution shall enforce license duration, unique physical address binding, and UMAC controls without weakening local business operation after legitimate license validation.

### G9 — Disaster Recovery

A practical non-technical operator shall be able to restore the system from a verified backup package.

### G10 — Maintainable Architecture

Magnificent Solution shall be able to add modules without rewriting the sales engine or database foundation.

---

# 4. STAKEHOLDERS

| Stakeholder | Primary Need | Authority |
|---|---|---|
| Owner | Revenue, profit, control, reports | Highest |
| Branch Manager | Daily operation | High |
| Cashier | Fast order and payment | Medium |
| Production Supervisor | Service progress | Medium/High |
| Storekeeper | Inventory accuracy | Medium |
| HR/Payroll Operator | Staff administration | Medium |
| Employee | Attendance/leave visibility | Low/Scoped |
| Auditor/Reviewer | Read-only traceability | Read-only |
| System Administrator | Configuration/security/backup | Highest technical |
| Magnificent Solution | Development/maintenance | Controlled support |

---

# 5. FUNCTIONAL REQUIREMENTS

## FR-001 System Initialization

The first-run wizard shall collect:

- business legal/trading name;
- logo;
- primary contact details;
- unique physical address;
- city/emirate;
- country;
- default language;
- default currency;
- opening date;
- default tax/charge configuration if used;
- document prefix configuration;
- admin account;
- backup location;
- printer defaults;
- terminal identity.

Initialization shall generate a unique `installation_id`.

## FR-002 Business Profile

Business profile supports:

- legal name;
- display name;
- trade name;
- registration information fields;
- phone;
- email;
- address;
- locality;
- emirate;
- country;
- logo;
- invoice footer;
- terms and conditions;
- social/contact text;
- print header;
- print footer;
- language defaults.

## FR-003 Customer Master

Customer master shall support:

### Personal

- customer code;
- title;
- first name;
- middle name;
- last name;
- preferred name;
- gender field if required by business configuration;
- date of birth optional;
- phone numbers;
- email;
- national/contact identifier fields as optional configurable fields;
- notes;
- preferred language.

### Professional

- company name;
- department;
- designation;
- professional phone;
- professional email;
- billing profile.

### Location

- address lines;
- building;
- area;
- city;
- emirate;
- country;
- postal code if applicable;
- latitude/longitude optional future field;
- delivery notes.

### Commercial

- default rate profile;
- credit limit;
- payment terms;
- opening balance;
- customer type;
- active/inactive;
- preferred pickup/delivery.

## FR-004 Vendor Master

Vendor shall mirror customer quality where practical, but include procurement-specific fields:

- vendor code;
- organization;
- contact person;
- phone;
- email;
- address;
- payment terms;
- credit/debit opening balance;
- supplied categories;
- bank/payment details optional;
- tax/registration fields optional;
- notes;
- active status.

## FR-005 Service Master

Service structure shall support:

- service code;
- parent service;
- service name;
- localized labels;
- category;
- Nth-level hierarchy;
- unit of measure;
- base selling rate;
- cost/estimated internal cost;
- active status;
- taxable/chargeable flags if configured;
- default duration;
- standard processing steps;
- service modifier support;
- image/icon;
- sort order;
- barcode/QR optional;
- notes.

Example hierarchy:

```text
Laundry
├── Wash
│   ├── Normal Wash
│   ├── Steam Wash
│   └── Premium Wash
├── Dry Clean
│   ├── Standard Dry Clean
│   └── Delicate Dry Clean
└── Iron
    ├── Normal Iron
    ├── Steam Iron
    └── Premium Press
```

## FR-006 Product Master

Product structure shall support the same Nth-level inheritance pattern as services.

Example:

```text
Garments
├── Upper Wear
│   ├── Shirt
│   ├── T-Shirt
│   ├── Jacket
│   └── Pullover
├── Lower Wear
│   ├── Trouser
│   ├── Pant
│   ├── Shalwar
│   └── Skirt
└── Home Textile
    ├── Blanket
    │   ├── Big Blanket
    │   └── Small Blanket
    ├── Bed Sheet
    │   ├── Single
    │   ├── Double
    │   ├── Queen
    │   └── King
    └── Curtain
```

Products shall support:

- SKU/product code;
- parent item;
- Nth-level hierarchy;
- product name;
- localized names;
- UOM;
- barcode(s);
- selling price;
- purchase rate;
- minimum stock;
- reorder level;
- current quantity derived from movement ledger;
- image;
- active status;
- modifiers;
- service relationships;
- stock tracking mode;
- notes.

## FR-007 Nth-Level Self Inheritance

Both services and products shall use adjacency-list hierarchy for simplicity and recursive CTE/reporting support where available.

Required fields:

```text
id
parent_id
root_id (optional denormalized optimization)
level_no
sort_order
name
status
```

Business rules:

- an item cannot be its own parent;
- parent cannot be one of its descendants;
- root items have null parent;
- hierarchy depth shall not be hardcoded;
- UI tree should lazy-load children;
- deletion shall be soft-delete by default;
- a parent with active children shall not be physically deleted.

## FR-008 Grouped Services

Multiple individual services may be combined into a single sellable grouped service.

Example:

```text
Premium Garment Care
= Wash + Steam Iron + Packaging
```

The group shall support:

- group service code;
- component services;
- component quantity/multiplier;
- component sequence;
- pricing mode;
- independent component display option;
- consolidated display option;
- component stock/operational implications;
- default production route.

## FR-009 Grouped Products

Multiple products may be combined as a sellable grouped product.

Example:

```text
Family Linen Pack
= 2 Pillow Covers + 1 Double Bed Sheet + 1 Table Cloth
```

The grouped product shall optionally affect stock as:

1. Sell assembled stock unit.
2. Explode bundle into component movements.
3. Non-stock informational group.

## FR-010 Service vs Product Many-to-Many

A service and product may have many-to-many relations.

Examples:

- Shirt -> Dry Clean
- Shirt -> Wash
- Shirt -> Iron
- Blanket -> Wash
- Blanket -> Steam Wash
- Carpet -> Deep Clean
- Suit -> Dry Clean + Press

Relationship fields:

```text
service_id
product_id
is_default
priority
price_override
duration_override
allowed_modifier
notes
active
```

## FR-011 Modifiers

Modifiers may be attached to either services or products.

Examples:

- express service;
- delicate handling;
- stain treatment;
- fragrance option;
- hanger packaging;
- folding;
- home delivery;
- heavy soil surcharge;
- special fabric handling;
- premium packaging.

Modifier pricing must support:

- fixed amount;
- per-unit amount;
- percentage;
- no-charge informational modifier.

## FR-012 Instant Sales

Instant Sales is the primary counter screen.

Recommended visual zones:

```text
+--------------------------------------------------------------------+
| CUSTOMER | ORDER # | STATUS | DATE | LANG | TERMINAL             |
+----------------------+---------------------------------------------+
| CUSTOMER SEARCH      | SELLABLE CATALOG / FAVORITES              |
| WALK-IN              |                                             |
| PHONE                | [SERVICE] [PRODUCT] [GROUP] [MODIFIER]   |
+----------------------+---------------------------------------------+
| CART / ITEM LINES                                                |
| Sr | Description | Qty | Rate | Disc | Modifier | Amount       |
+------------------------------------------------------------------+
| NOTES | PICKUP | DELIVERY | DUE DATE | STATUS                    |
+------------------------------------------------------------------+
| SUBTOTAL | DISCOUNT | OTHER | NET TOTAL | PAID | BALANCE         |
+------------------------------------------------------------------+
| SAVE | SAVE+PRINT | PAYMENT | HOLD | CANCEL | REPRINT | DELIVER    |
+------------------------------------------------------------------+
```

The screen shall support:

- keyboard-only operation;
- touch-friendly controls;
- barcode scanner input;
- fast favorites;
- recent customers;
- recent services;
- line editing without modal overload;
- quantity entry;
- direct rate override by permission;
- line-level discount by permission;
- order-level discount by permission;
- modifier selection;
- partial payment;
- full payment;
- credit/pending;
- cash;
- mixed payment allocations;
- re-open authorized held order;
- print/reprint;
- challan generation;
- delivery note;
- customer reminder setup.

## FR-013 Cash / Credit Memo

Memo lines shall preserve:

```text
SrNo
Description
Qty
Rate
Amount
Currency
Reference
```

Supported memo types:

- cash sale memo;
- credit memo;
- debit memo;
- adjustment memo;
- service correction memo.

## FR-014 Payments

Payment method types for initial release:

- cash;
- credit/pending;
- debit/adjustment;
- internal account adjustment.

Gateway integration shall not be required.

Payment records must be immutable after posting, with reversals/voids represented as separate adjustment transactions.

## FR-015 Pending Invoices

Pending invoice workspace shall show:

- invoice number;
- customer;
- invoice date;
- due date;
- total;
- paid;
- balance;
- aging bucket;
- latest reminder date;
- status;
- responsible operator.

Actions:

- receive payment;
- print statement;
- print receipt;
- add note;
- send/share receipt file manually through available local/social sharing path;
- mark follow-up;
- authorized adjustment.

## FR-016 Service Status

Suggested lifecycle:

```text
DRAFT
  -> CONFIRMED
  -> RECEIVED
  -> SORTING
  -> PROCESSING
  -> QUALITY_CHECK
  -> PACKED
  -> READY_FOR_COLLECTION
  -> OUT_FOR_DELIVERY
  -> DELIVERED
  -> CLOSED
```

Exception states:

```text
ON_HOLD
REWORK_REQUIRED
PARTIALLY_READY
LOST_DAMAGED_REVIEW
CANCELLED
```

Status transitions shall be permission-controlled and audit logged.

## FR-017 Notifications and Alerts

Initial local notifications shall support:

- order ready;
- collection overdue;
- delivery overdue;
- pending payment overdue;
- low stock;
- negative stock exception if enabled;
- backup failure;
- license expiry warning;
- database recovery warning;
- printer unavailable;
- scanner/input fault;
- payroll pending;
- attendance anomalies.

The local notification center shall be persistent and auditable.

## FR-018 Delivery and Collection

Each order may include:

- expected ready date;
- promised date;
- pickup date/time;
- delivery date/time;
- delivery address;
- delivery notes;
- assigned employee/driver if future role is enabled;
- collection confirmation;
- delivery confirmation;
- failed delivery reason.

## FR-019 Challans

A challan is a non-financial or operational document representing movement/hand-over.

Examples:

- service receipt challan;
- customer collection challan;
- vendor return challan;
- stock transfer challan;
- delivery challan.

Each challan must have its own sequential number and reference to source transaction.

## FR-020 Product Inventory

Inventory shall be movement-driven.

### Movement Types

```text
OPENING
PURCHASE_RECEIPT
PURCHASE_RETURN
SALE_ISSUE
SALE_RETURN
ADJUSTMENT_IN
ADJUSTMENT_OUT
TRANSFER_IN
TRANSFER_OUT
DAMAGE
LOSS
FOUND
BUNDLE_EXPLODE
BUNDLE_ASSEMBLE
MANUAL_CORRECTION
```

Current stock shall be calculated from the ledger or maintained as a carefully controlled snapshot with reconciliation.

## FR-021 Product Received Inventory

Goods receipt shall support:

- vendor;
- purchase reference;
- date;
- item lines;
- quantity;
- rate;
- amount;
- storage/location;
- received by;
- remarks;
- attachment;
- print goods receipt.

## FR-022 Inventory Adjustment Control

Adjustments require reason codes.

Example reason codes:

- damaged;
- expired;
- lost;
- found;
- count correction;
- opening correction;
- wrong unit conversion;
- bundle correction;
- other authorized reason.

High-impact adjustments require elevated permission.

## FR-023 Purchase and Vendor Inventory

Procurement flow:

```text
Purchase Request
    -> Purchase Order (optional phase)
    -> Goods Receipt
    -> Vendor Invoice/Memo
    -> Stock Receipt
    -> Vendor Payable
    -> Payment
```

## FR-024 Employee Master

Employee fields shall include:

- employee code;
- name;
- contact;
- address;
- joining date;
- role;
- department;
- salary basis;
- basic salary;
- allowance profiles;
- deduction profiles;
- active status;
- document metadata;
- emergency contact;
- bank/payment data if legally required and approved.

## FR-025 Attendance

Attendance shall support:

- present;
- absent;
- late;
- half-day;
- leave;
- holiday;
- overtime;
- off day;
- correction request.

## FR-026 Leave

Leave master/configuration:

- leave type;
- annual entitlement;
- carry-forward flag;
- paid/unpaid;
- approval required;
- active status.

Leave transaction:

- employee;
- start;
- end;
- duration;
- type;
- reason;
- status;
- approval;
- audit.

## FR-027 Payroll

Payroll shall support configurable salary calculation instead of assuming one legal regime.

Inputs:

- basic salary;
- allowances;
- overtime;
- unpaid leave;
- approved deductions;
- salary advance recovery;
- other configured adjustments.

Outputs:

- gross salary;
- total additions;
- total deductions;
- net payable;
- payment status;
- payroll period.

## FR-028 Salary Advance

Advance lifecycle:

```text
REQUESTED -> APPROVED -> PAID -> PARTIALLY_RECOVERED -> RECOVERED
```

Salary advance shall never be silently deducted. Every deduction must link to an advance transaction.

## FR-029 Expenses

Expense categories shall support:

- electricity;
- water;
- rent;
- maintenance;
- transport;
- office expense;
- software/local IT;
- cleaning supplies;
- packaging;
- marketing;
- other configurable expense categories.

Each expense shall preserve:

- date;
- category;
- amount;
- description;
- vendor/payee;
- payment method;
- reference;
- attachment;
- approval status.

## FR-030 Invoice and Memo Printing

Print engine shall support:

- thermal receipt;
- A4 invoice;
- A5 invoice;
- compact memo;
- challan;
- payment receipt;
- customer statement;
- vendor statement;
- inventory report;
- payroll report;
- expense report.

Templates shall be data-driven rather than hardcoded per screen.

## FR-031 Report Printing

Every important list/report shall have:

- preview;
- printer selection;
- paper size;
- orientation;
- margins;
- header/footer;
- page numbering;
- optional logo;
- optional signature block;
- language selection;
- PDF output;
- print history metadata.

---

# 6. NON-FUNCTIONAL REQUIREMENTS

## NFR-001 Offline Operation

Core sales, customer, service/product masters, status workflow, inventory, payment capture, printing, and local reports must remain functional without internet access.

## NFR-002 Local Performance

Common operator actions should feel immediate. Database queries shall be indexed and pagination shall be used for large lists.

## NFR-003 Reliability

Critical business transactions shall be atomic.

## NFR-004 Data Integrity

Financial amounts shall use fixed-precision decimal SQL types, never floating-point values for persisted currency.

## NFR-005 Security

- password hashing;
- token expiration;
- refresh/re-authentication flow;
- permission enforcement server-side;
- local API access control;
- audit logs;
- secret/config separation;
- encrypted sensitive local configuration where practical.

## NFR-006 Maintainability

Modules must be independently testable.

## NFR-007 Scalability

The data model shall support multiple branches/terminals later without requiring redesign of every table.

## NFR-008 Accessibility

- keyboard navigation;
- large touch hit targets;
- high readability;
- focus state;
- error summary;
- no color-only indication.

## NFR-009 Localization

No business label shall be embedded directly inside Flutter widgets where a localization key is expected.

## NFR-010 Recoverability

Backup integrity shall be tested and restore shall be documented.

---

# 7. SOW — STATEMENT OF WORK

## Phase 0 — Discovery and Foundation

### Deliverables

- approved requirements baseline;
- solution architecture;
- database ER model;
- role/permission matrix;
- navigation map;
- localization schema;
- license/UMAC specification;
- print-document catalog;
- backup/recovery policy;
- acceptance criteria framework.

## Phase 1 — Core Operational MVP

### Deliverables

- installation/bootstrap;
- business setup;
- user/roles;
- customer master;
- vendor master;
- service master;
- product master;
- hierarchy;
- grouped service/product;
- modifiers;
- service-product relationship;
- instant sale;
- payment;
- pending invoice;
- invoice/receipt printing;
- basic order status;
- stock receipt and adjustment;
- basic reports;
- backup/export/import;
- English/Arabic UI.

## Phase 2 — Operational Control Expansion

- full production workflow;
- delivery/collection;
- challans;
- advanced inventory;
- purchase;
- employee master;
- attendance;
- leave;
- payroll;
- salary advance;
- expenses;
- advanced reporting;
- print designer options;
- stronger alert center;
- social/share-ready document assets.

## Phase 3 — Scale and Extension

- multi-terminal hardening;
- branch support;
- optional local-network service node;
- optional cloud synchronization framework;
- KSA localization package;
- accounting integration adapter;
- SMS/WhatsApp adapters;
- online storefront adapter;
- optional customer application;
- analytics layer.

---

# 8. ER — ENTITY RELATIONSHIP BLUEPRINT

## 8.1 Core Master Entities

```text
Business
  ├── Branch
  │     └── Terminal
  ├── User
  ├── Role
  ├── Permission
  ├── Customer
  ├── Vendor
  ├── Employee
  ├── Service
  └── Product
```

## 8.2 Sales Entities

```text
SalesOrder
  ├── SalesOrderLine
  │     ├── ServiceReference
  │     ├── ProductReference
  │     └── ModifierReference
  ├── PaymentAllocation
  ├── Document
  ├── StatusHistory
  └── DeliveryCollection
```

## 8.3 Inventory Entities

```text
InventoryItem
InventoryLocation
InventoryMovement
StockAdjustment
GoodsReceipt
GoodsReceiptLine
StockBalanceSnapshot
```

## 8.4 HR Entities

```text
Employee
Attendance
LeaveType
LeaveRequest
PayrollPeriod
PayrollRun
PayrollLine
SalaryAdvance
AdvanceRecovery
```

## 8.5 Expense Entities

```text
ExpenseCategory
Expense
ExpenseAttachment
ExpenseApproval
```

## 8.6 Platform Entities

```text
SystemSetting
LocalizationEntry
DocumentTemplate
Notification
AuditLog
BackupJob
BackupManifest
License
InstallationIdentity
UMACPolicy
HardwareProfile
ImportJob
ExportJob
```

---

# 9. PROPOSED DATABASE TABLES

## 9.1 Naming Standard

Use snake_case table/column names.

All tables should include, where relevant:

```text
id BIGINT UNSIGNED
uuid CHAR(36)
created_at DATETIME(6)
created_by BIGINT NULL
updated_at DATETIME(6)
updated_by BIGINT NULL
is_active TINYINT(1)
version_no BIGINT UNSIGNED
```

Soft-delete should use a separate lifecycle field where audit meaning is important, e.g. `record_status`, rather than using deletion timestamps as business truth.

## 9.2 Example Master Tables

```sql
business
branch
terminal
app_user
role
permission
role_permission
user_role
customer
customer_phone
customer_email
customer_address
customer_contact
vendor
vendor_phone
vendor_email
vendor_address
employee
employee_document
```

## 9.3 Service Tables

```sql
service
service_translation
service_category
service_modifier
service_bundle
service_bundle_line
service_product_map
service_process_step
```

## 9.4 Product Tables

```sql
product
product_translation
product_category
product_barcode
product_modifier
product_bundle
product_bundle_line
unit_of_measure
unit_conversion
```

## 9.5 Sales Tables

```sql
sales_order
sales_order_line
sales_order_line_modifier
sales_order_payment
payment_method
payment_transaction
credit_memo
credit_memo_line
debit_memo
debit_memo_line
order_status_history
challan
challan_line
delivery_task
collection_task
```

## 9.6 Inventory Tables

```sql
inventory_location
inventory_item
inventory_movement
inventory_balance
stock_adjustment
stock_adjustment_line
goods_receipt
goods_receipt_line
purchase_document
purchase_document_line
```

## 9.7 HR Tables

```sql
attendance
attendance_adjustment
leave_type
leave_policy
leave_request
payroll_period
payroll_run
payroll_line
salary_advance
salary_advance_recovery
```

## 9.8 Expense Tables

```sql
expense_category
expense
expense_attachment
expense_approval
```

## 9.9 Platform Tables

```sql
system_setting
localization_key
localization_translation
document_template
document_print_log
notification
notification_read
file_asset
file_link
audit_log
backup_job
backup_manifest
import_job
export_job
license
license_activation
installation_identity
umac_policy
hardware_identity
```

---

# 10. IMPORTANT DATABASE INDEXES

At minimum consider indexes for:

```text
customer(phone)
customer(customer_code)
customer(name)
vendor(vendor_code)
service(parent_id, is_active)
product(parent_id, is_active)
product_barcode(barcode)
sales_order(order_no)
sales_order(customer_id, created_at)
sales_order(status, promised_date)
sales_order_payment(order_id)
payment_transaction(reference_no)
inventory_movement(product_id, movement_date)
inventory_movement(reference_type, reference_id)
attendance(employee_id, attendance_date)
leave_request(employee_id, start_date, end_date)
payroll_line(payroll_run_id, employee_id)
audit_log(entity_type, entity_id, created_at)
notification(user_id, is_read, created_at)
```

Unique constraints shall be used for natural identifiers only where business rules require uniqueness.

---

# 11. TECHNICAL BLUEPRINT

## 11.1 High-Level Architecture

```text
+--------------------------------------------------------------+
|                    Flutter Windows Desktop                  |
|                                                              |
|  Views -> ViewModels -> Application Services -> Repositories |
|              |                 |                |             |
|              |                 |                |             |
|              +---------- Domain Rules ---------+             |
+----------------------------|---------------------------------+
                             |
                         Local REST API
                             |
+----------------------------|---------------------------------+
|                         PHP Layer                            |
|                                                              |
| Auth | Validation | Application Services | Audit | Files      |
| Print | Backup | License | UMAC | Import | Export | Reports  |
+----------------------------|---------------------------------+
                             |
                       MariaDB / MySQL
                             |
                 +-----------+-----------+
                 |                       |
           Local File Store        Backup Store
```

## 11.2 MVVM

### View

Flutter widgets should focus on:

- rendering;
- event binding;
- navigation;
- accessibility;
- keyboard/focus semantics.

### ViewModel

ViewModels own:

- screen state;
- user intent;
- loading/error state;
- command availability;
- validation message mapping;
- paging/sorting/filter state.

### Domain/Application Layer

Services own:

- business orchestration;
- calculations;
- workflow transitions;
- authorization checks;
- transaction boundaries.

### Repository

Repositories own persistence access and should not contain UI logic.

---

# 12. MICROservice-ORIENTED LOCAL COMPONENTS

Microservices in this project mean **separable service modules within the local API/runtime**, not mandatory network-deployed distributed services.

Suggested bounded modules:

```text
IdentityService
ConfigurationService
LocalizationService
CustomerService
VendorService
CatalogService
SalesService
PaymentService
OrderWorkflowService
InventoryService
ProcurementService
HRService
PayrollService
ExpenseService
DocumentService
PrintingService
NotificationService
FileService
BackupService
RestoreService
AuditService
LicenseService
UMACService
ReportingService
ImportExportService
```

This keeps the system modular while avoiding distributed-system complexity in a single-machine deployment.

---

# 13. API BLUEPRINT

## Base Route

```text
/api/v1
```

## Authentication

```text
POST /auth/login
POST /auth/refresh
POST /auth/logout
GET  /auth/me
```

## Customers

```text
GET    /customers
POST   /customers
GET    /customers/{id}
PUT    /customers/{id}
POST   /customers/{id}/merge
POST   /customers/{id}/deactivate
```

## Services

```text
GET    /services/tree
POST   /services
GET    /services/{id}
PUT    /services/{id}
POST   /services/{id}/children
POST   /services/{id}/modifiers
```

## Products

```text
GET    /products/tree
GET    /products/barcode/{code}
POST   /products
PUT    /products/{id}
POST   /products/{id}/bundle
```

## Sales

```text
POST   /sales/quote
POST   /sales/draft
POST   /sales/confirm
GET    /sales/{id}
POST   /sales/{id}/payment
POST   /sales/{id}/status
POST   /sales/{id}/cancel
POST   /sales/{id}/reprint
```

## Inventory

```text
POST   /inventory/goods-receipt
POST   /inventory/adjustment
GET    /inventory/stock
GET    /inventory/movements
POST   /inventory/reconcile
```

## HR

```text
GET    /employees
POST   /employees
POST   /attendance
POST   /leave-requests
POST   /payroll/run
POST   /salary-advances
```

## Backup

```text
POST   /backup/run
GET    /backup/history
POST   /backup/verify
POST   /backup/restore/validate
POST   /backup/restore/execute
```

All write endpoints shall expose deterministic error codes, not only human-readable messages.

---

# 14. API RESPONSE CONTRACT

Recommended shape:

```json
{
  "success": true,
  "code": "SALE_CREATED",
  "message_key": "sales.created",
  "data": {},
  "errors": [],
  "meta": {
    "request_id": "...",
    "server_time": "...",
    "version": "v1"
  }
}
```

Validation errors:

```json
{
  "success": false,
  "code": "VALIDATION_ERROR",
  "message_key": "common.validation_failed",
  "errors": [
    {
      "field": "customer_id",
      "code": "REQUIRED",
      "message_key": "customer.required"
    }
  ],
  "meta": {
    "request_id": "..."
  }
}
```

UI must translate `message_key`; API should not assume English is the final presentation language.

---

# 15. LOCALIZATION BLUEPRINT

## 15.1 JSON Structure

```json
{
  "locale": "en-AE",
  "direction": "ltr",
  "currency": "AED",
  "labels": {
    "sales.new_order": "New Order",
    "sales.customer": "Customer",
    "sales.total": "Total"
  },
  "validations": {
    "required": "This field is required",
    "invalid_phone": "Enter a valid phone number"
  }
}
```

Arabic counterpart:

```json
{
  "locale": "ar-AE",
  "direction": "rtl",
  "currency": "AED",
  "labels": {
    "sales.new_order": "طلب جديد",
    "sales.customer": "العميل",
    "sales.total": "الإجمالي"
  }
}
```

## 15.2 RTL Rules

When Arabic is selected:

- horizontal alignment changes;
- start/end semantics replace left/right assumptions;
- icon placement shall mirror where semantically appropriate;
- forms shall reorder visual alignment correctly;
- table numeric columns may remain visually numeric-oriented rather than blindly mirrored;
- invoice paper layout shall follow document-specific template direction;
- LTR content such as phone numbers, invoice numbers, codes, email, and URLs shall remain readable.

## 15.3 Localization Governance

Every user-visible text must have a key. Hardcoded operator-facing English strings are prohibited except controlled developer diagnostics.

---

# 16. CURRENCY ENGINE

Initial configuration:

```text
major_unit = AED
minor_unit_name = Fils
minor_digits = 2
```

Future configuration examples:

```text
INR + Paise
USD + Cent
SAR + Halala
```

The monetary engine shall not perform floating-point persistence.

Use decimal arithmetic:

```text
DECIMAL(18,2)
```

For quantities requiring fractional precision, e.g. kilograms or liters, configure independent precision:

```text
quantity_scale = 3 or 4
currency_scale = 2
```

Live exchange-rate functionality is explicitly not required.

---

# 17. SALES CALCULATION ENGINE

## 17.1 Canonical Calculation Order

```text
Line Gross
    = Quantity × Effective Rate

Line Modifier Total
    = Sum(Fixed + PerUnit + Percentage effects)

Line Discount
    = configured line discount

Line Net
    = Line Gross + Modifier Total - Line Discount

Order Subtotal
    = Sum(Line Net)

Order Discount
    = configured order-level discount

Other Charges
    = configured non-tax charges, if enabled

Grand Total
    = Order Subtotal - Order Discount + Other Charges

Balance
    = Grand Total - Posted Payments
```

No calculation path shall use a different rounding sequence without an explicit configuration.

## 17.2 Rounding Rule

Define one canonical rounding policy such as half-up at the currency scale, and apply it consistently at the designated boundary.

---

# 18. SALES TRANSACTION ALGORITHM

```text
START
  |
  v
Resolve Terminal + User + License + Business
  |
  v
Select Existing Customer OR Create Walk-In
  |
  v
Create Draft Order
  |
  v
Add Service/Product/Bundle Lines
  |
  v
Apply Modifiers
  |
  v
Calculate Totals
  |
  v
Validate Item Availability / Rules
  |
  +---- invalid ----> show structured validation -> return to edit
  |
  v
Confirm Order
  |
  v
Create financial/document transaction
  |
  v
Create status history
  |
  v
Create relevant inventory movements
  |
  v
Apply payment allocations
  |
  v
Generate document numbers
  |
  v
Write audit log
  |
  v
Commit transaction
  |
  +---- Print requested ----> generate document -> print/export
  |
  v
END
```

Everything from confirmation through audit should be inside one DB transaction where practical.

---

# 19. INVENTORY ALGORITHMS

## 19.1 Stock on Hand

```text
stock_on_hand(product_id)
    = SUM(all valid signed inventory movements)
```

A movement row shall contain a signed or direction field, but not both ambiguously.

Recommended fields:

```text
movement_direction = IN / OUT
quantity
unit_cost
extended_cost
```

## 19.2 Negative Stock Policy

Configuration:

```text
ALLOW_NEGATIVE_STOCK = false
```

If false, posting an outbound movement exceeding available stock shall fail atomically.

If enabled, the exception shall be clearly surfaced and reported.

## 19.3 Stock Adjustment

```text
Count Qty
- System Qty
= Adjustment Qty

Adjustment Qty > 0 => ADJUSTMENT_IN
Adjustment Qty < 0 => ADJUSTMENT_OUT
```

Reason is mandatory.

---

# 20. NTH-LEVEL HIERARCHY ALGORITHM

## Create Child

```text
validate parent exists
validate parent active
set child.parent_id = parent.id
set child.level_no = parent.level_no + 1
set child.root_id = parent.root_id or parent.id
commit
```

## Re-parent Item

Before re-parenting:

```text
reject if new_parent = current_item
reject if new_parent is descendant of current_item
validate permission
recalculate level for entire subtree
write audit record
```

Use recursive queries where supported or iterative traversal in application logic.

---

# 21. GROUPED SERVICE/PRODUCT ALGORITHM

```text
User selects group
      |
      v
Load active components
      |
      v
Validate each component
      |
      v
Resolve component rate/override
      |
      v
Create parent sellable line
      |
      +--> create component references as hidden/expanded detail
      |
      v
Calculate consolidated price
      |
      v
Store bundle snapshot
```

Important: historical sales must store a snapshot of the purchased structure. Future master changes must not rewrite old orders.

---

# 22. ORDER STATUS WORKFLOW RULE ENGINE

Each transition shall use:

```text
from_status
requested_to_status
actor_id
permission
business_rule
validation
timestamp
reason
```

Example rule:

```text
DRAFT -> CONFIRMED
allowed roles = cashier, manager
requires = at least one valid line
```

Example:

```text
READY_FOR_COLLECTION -> DELIVERED
requires = delivery/customer confirmation
requires = payment settled OR credit permission
```

No status should be changed by direct table update from UI.

---

# 23. PAYMENT ALLOCATION ALGORITHM

For order total `T` and posted payment `P`:

```text
balance = T - P
```

For multiple payment allocations:

```text
payment_sum = SUM(all posted allocations)
assert payment_sum <= allowed_settlement_limit
```

Overpayment should either be prohibited or explicitly handled by a configured customer advance/refund process.

Payment reversal:

```text
original payment stays immutable
new reversal transaction references original
balance recalculated from effective transactions
```

---

# 24. CUSTOMER MERGE ALGORITHM

Duplicate customers may be merged only by authorized users.

```text
select primary customer
select duplicate customer
preview impacted orders
preview balances
preview addresses
confirm merge
repoint non-conflicting references
preserve original ids in merge history
mark duplicate as MERGED
write audit
```

Financial history shall never be deleted during merge.

---

# 25. REPORTING BLUEPRINT

## Operational Reports

- Daily Sales
- Sales by Service
- Sales by Product
- Sales by Customer
- Pending Invoices
- Payment Summary
- Cashier Summary
- Order Status Aging
- Ready for Collection
- Delivered Orders
- Cancelled Orders
- Rework/Damage Review
- Daily Closing Summary

## Inventory Reports

- Stock on Hand
- Stock Valuation
- Stock Movement
- Low Stock
- Negative Stock
- Adjustments
- Purchase Summary
- Vendor Purchase History
- Slow Moving Items

## HR Reports

- Employee List
- Attendance Summary
- Absence Report
- Leave Balance
- Leave History
- Payroll Register
- Salary Advance
- Advance Recovery

## Expense Reports

- Expense Summary
- Category-wise Expense
- Monthly Expense
- Vendor/Payee Expense

## Financial-Operational Reports

- Gross Sales
- Discounts
- Collections
- Outstanding
- Daily Cash Summary
- Revenue by Service Category
- Revenue by Product Category
- Expense vs Revenue operational view

These reports are operational and do not constitute a full statutory accounting package unless a future accounting module is implemented.

---

# 26. DOCUMENT MANAGEMENT

## File Asset Types

```text
BUSINESS_LOGO
CUSTOMER_DOCUMENT
VENDOR_DOCUMENT
PRODUCT_IMAGE
SERVICE_IMAGE
PURCHASE_ATTACHMENT
EXPENSE_ATTACHMENT
PAYROLL_ATTACHMENT
INVOICE_PDF
RECEIPT_PDF
CHALLAN_PDF
REPORT_PDF
BACKUP_PACKAGE
IMPORT_FILE
EXPORT_FILE
```

## Local File Path Convention

Use an application-owned root:

```text
<AppData>/LaundraCore/
  config/
  data/
  files/
    customers/
    vendors/
    products/
    services/
    sales/
    expenses/
    payroll/
  documents/
  reports/
  backups/
  logs/
  temp/
```

Do not store user documents in the application installation directory.

Each file asset must have metadata:

```text
id
uuid
original_name
stored_name
mime_type
size_bytes
sha256
relative_path
entity_type
entity_id
created_at
```

---

# 27. BACKUP AND DISASTER RECOVERY

## 27.1 Backup Types

### Automatic Incremental/Logical Backup

- daily scheduled database backup;
- rolling retention;
- local secondary location where possible;
- optional removable drive copy.

### Full Package Backup

Package may include:

- database dump;
- configuration;
- localization;
- document templates;
- file metadata;
- referenced user files where selected;
- license metadata required for restore validation;
- backup manifest.

## 27.2 Backup Manifest

```json
{
  "product": "LaundraCore Local",
  "schema_version": "1.x",
  "created_at": "...",
  "business_uuid": "...",
  "installation_id": "...",
  "database_hash": "...",
  "file_manifest_hash": "...",
  "record_counts": {},
  "backup_type": "FULL"
}
```

## 27.3 Recovery Algorithm

```text
select backup
  -> verify package integrity
  -> validate schema compatibility
  -> validate backup manifest
  -> create pre-restore safety snapshot
  -> restore database to staging
  -> verify critical tables
  -> verify document references
  -> reconcile counts/hashes
  -> switch restored dataset into active state
  -> restart local services
  -> run smoke tests
  -> create recovery audit record
```

Never overwrite the only copy of the current database without making a safety backup first.

---

# 28. LICENSE AND UMAC CONTROL

## 28.1 Purpose

The product shall support controlled commercial deployment without making the customer's operational data hostage to internet connectivity.

## 28.2 Required License Inputs

- license key;
- customer/business identity;
- edition;
- start date;
- expiry date;
- licensed branch count;
- terminal count;
- feature flags;
- installation binding policy;
- physical-address binding hash;
- UMAC policy.

## 28.3 UMAC

`UMAC` shall be treated as a controlled **Unique Machine/Installation Authorization Control** mechanism.

The exact implementation must use privacy-conscious machine identity material and should avoid storing raw personal/system secrets in the license record.

Conceptual fingerprint input:

```text
installation_guid
+ normalized_business_address
+ terminal_id
+ machine_identity_components
+ license_salt
```

Derived value:

```text
UMAC = HMAC-SHA256(secret_or_license_bound_key, canonical_payload)
```

Do not use a simple unhashed concatenation as the license control token.

## 28.4 Physical Address Binding

The system shall preserve a normalized unique physical address.

Example normalized fields:

```text
country
emirate/state
city
area
street
building
shop/unit
postal/reference field
```

Store a canonical representation and derived verification hash.

Business requirement:

- a licensed deployment is associated with one approved physical business location;
- controlled relocation requires license re-authorization;
- address data should not be exposed in license keys in plaintext.

## 28.5 Expiry Behavior

Before expiry:

```text
30 days -> warning
14 days -> warning
7 days  -> critical warning
1 day   -> final warning
expired -> controlled license state
```

Expired behavior should preserve:

- read-only history access where commercially approved;
- export ability where policy permits;
- recovery/backup ability;
- support diagnostics;

rather than destroying or blocking access to business records.

## 28.6 Offline License Validation

A signed license artifact should be validated locally using an embedded public key. Private signing keys shall never ship inside the application.

Conceptual model:

```text
License Payload
     |
     +--> Signature
     |
     v
Local Public-Key Verification
     |
     v
Policy Evaluation
     |
     v
Activation Binding / UMAC Check
```

---

# 29. SECURITY BLUEPRINT

## Authentication

- salted password hashes;
- access token expiration;
- refresh token rotation where appropriate;
- account lockout/rate limiting for repeated failures;
- session revocation;
- operator identity on every mutation.

## Authorization

Permissions should be action-oriented:

```text
sales.create
sales.edit_draft
sales.override_rate
sales.discount_line
sales.discount_order
sales.cancel
sales.reprint
sales.receive_payment
inventory.adjust
inventory.reconcile
hr.payroll.run
expense.approve
backup.restore
license.manage
system.settings
```

## Audit

Audit event fields:

```text
id
request_id
actor_id
terminal_id
entity_type
entity_id
action
old_values_hash/new_values_hash or controlled delta
reason
created_at
```

Never place passwords, JWT secrets, or raw sensitive authentication material in the audit log.

---

# 30. HARDWARE ABSTRACTION BLUEPRINT

## Supported Device Classes

- Hand-held scanner
- Thermal printer
- Touch screen
- Inkjet printer
- Dot matrix printer
- Cashier counter box / cash drawer

## Design Rule

Hardware-specific implementation shall be isolated behind adapters.

```text
ScannerService
  -> HID Scanner Adapter

PrinterService
  -> Windows Spooler Adapter
  -> Raw/ESC-POS Adapter where supported
  -> Dot Matrix Compatibility Adapter

CashDrawerService
  -> printer pulse adapter or supported OS/vendor adapter

TouchService
  -> operating-system pointer/touch events
```

Application code shall call interfaces such as:

```text
scanService.read()
printerService.print(document)
cashDrawerService.open()
```

not manufacturer-specific SDK methods.

## Scanner Behavior

Most USB handheld scanners should act like keyboard/HID devices. The software should support:

- configurable suffix/terminator;
- barcode debounce;
- scanned text validation;
- fallback manual search;
- no assumption of one brand.

## Printer Strategy

Use a common print-document model and produce:

```text
PDF / vector print
OR
printer command stream
```

where required.

Printer profiles shall be configuration-driven.

---

# 31. PRINT TEMPLATE ENGINE

The print engine should render from structured data rather than screenshot-like UI capture.

## Template Model

```json
{
  "template_id": "invoice_a4_v1",
  "document_type": "INVOICE",
  "locale": "en-AE",
  "direction": "ltr",
  "paper": "A4",
  "sections": [
    "header",
    "customer",
    "lines",
    "totals",
    "payment",
    "terms",
    "footer"
  ]
}
```

The same logical document should be renderable as:

- A4;
- A5;
- thermal 58mm;
- thermal 80mm;
- compact memo.

---

# 32. SHAREABLE RECEIPT DESIGN

The application may generate a compact, square or portrait receipt image/PDF for manual sharing through local operating-system applications.

Required variants:

```text
THERMAL_RECEIPT
A4_INVOICE
SQUARE_SOCIAL_RECEIPT
PORTRAIT_RECEIPT
PAYMENT_RECEIPT
ORDER_READY_NOTICE
```

The system shall not require direct social media API integration in Phase 1.

---

# 33. UI/UX BLUEPRINT

## 33.1 Visual Positioning

The interface shall resemble a professional POS/operations terminal, not a generic admin website.

Avoid:

- oversized marketing hero sections;
- irrelevant cards everywhere;
- browser-style navigation patterns;
- excessive white space that wastes counter-screen area;
- modal-heavy CRUD flows.

Prefer:

- dense but readable operational layouts;
- persistent context header;
- quick action strip;
- command palette;
- keyboard shortcuts;
- split views;
- compact grids;
- status chips;
- clear financial hierarchy;
- full-screen transaction workspace;
- touch-safe controls where needed.

## 33.2 Recommended Application Shell

```text
+--------------------------------------------------------------------------------+
| Brand | Branch | Terminal | User | Date/Time | License | Language | Alerts     |
+--------------------------------------------------------------------------------+
| NAV | Main Work Area                                               | Quick     |
|     |                                                               | Context   |
| Home|                                                               | Panel     |
| Sales                                                               |           |
| Orders                                                              |           |
| Customers                                                           |           |
| Services                                                            |           |
| Products                                                            |           |
| Inventory                                                           |           |
| Purchasing                                                          |           |
| HR                                                                  |           |
| Expenses                                                            |           |
| Reports                                                             |           |
| Setup                                                               |           |
+--------------------------------------------------------------------------------+
| Status | DB Connected | Backup OK | Printer | Scanner | Version | Support     |
+--------------------------------------------------------------------------------+
```

## 33.3 Home Dashboard

Dashboard should be operational, not decorative.

Recommended widgets:

- today's sales;
- cash collected;
- pending amount;
- orders received;
- processing;
- ready;
- overdue;
- low stock;
- employees present;
- pending approvals;
- backup status.

Widgets must open the source list.

---

# 34. KEYBOARD-FIRST DESIGN

Suggested shortcuts:

```text
Ctrl+N         New Transaction
Ctrl+S         Save Draft
Ctrl+Enter     Confirm Transaction
Ctrl+P         Print
Ctrl+Shift+P   Payment
Ctrl+F         Search
F2             Edit Selected Line
F4             Customer Search
F6             Product/Service Search
F8             Hold Order
F9             Collect Payment
F12            Quick Save+Print
Esc            Close Panel / Cancel Current Action
```

Shortcuts must be configurable and context-safe.

---

# 35. WORKFLOWS

## 35.1 Customer Walk-In Workflow

```text
Cashier selects New Sale
  -> phone/search
  -> existing customer found?
      YES -> load profile
      NO  -> create minimum walk-in record
  -> select item/service
  -> add quantity
  -> choose modifier
  -> confirm promised date
  -> calculate
  -> accept payment
  -> print receipt
  -> order enters RECEIVED
```

## 35.2 Service Processing Workflow

```text
RECEIVED
 -> SORTING
 -> PROCESSING
 -> QUALITY_CHECK
 -> PACKED
 -> READY_FOR_COLLECTION
```

Quality failure:

```text
QUALITY_CHECK -> REWORK_REQUIRED -> PROCESSING -> QUALITY_CHECK
```

## 35.3 Collection Workflow

```text
READY_FOR_COLLECTION
 -> identify customer/order
 -> verify amount/payment status
 -> collect remaining amount if applicable
 -> issue collection receipt
 -> mark CLOSED
```

## 35.4 Delivery Workflow

```text
READY_FOR_COLLECTION
 -> schedule delivery
 -> assign responsible staff
 -> OUT_FOR_DELIVERY
 -> customer confirmation
 -> DELIVERED
 -> close if financial conditions satisfied
```

## 35.5 Purchase Workflow

```text
Purchase Entry
 -> receive stock
 -> validate quantities
 -> post inventory movement
 -> vendor payable
 -> print receipt
```

## 35.6 Daily Closing Workflow

```text
Start Closing
 -> validate no unfinished critical transaction
 -> summarize cash
 -> summarize payments
 -> summarize outstanding
 -> summarize cancellations/adjustments
 -> operator confirms
 -> closing snapshot generated
 -> backup check
 -> close shift
```

---

# 36. USE CASES

## UC-001 Login

**Actor:** Cashier/User  
**Precondition:** Active user exists.  
**Main Flow:** Enter credentials -> validate -> create session -> load permissions -> open workstation.  
**Alternative:** Invalid credentials -> error -> throttle after repeated failures.  
**Postcondition:** Authenticated session exists.

## UC-002 Create Customer

**Actor:** Cashier/Manager  
**Flow:** Search -> no match -> create -> validate phone/name -> save -> return to sale.  
**Acceptance:** New customer available immediately.

## UC-003 Create Service

**Actor:** Manager/Admin  
**Flow:** Setup -> Services -> New -> parent -> pricing -> translations -> modifier rules -> save.

## UC-004 Create Product

**Actor:** Manager/Storekeeper  
**Flow:** Product -> category -> UOM -> barcode -> pricing -> stock controls -> save.

## UC-005 Create Grouped Service

**Actor:** Manager  
**Flow:** New Group -> select components -> quantities -> pricing -> save -> preview.

## UC-006 Create Grouped Product

**Actor:** Manager/Storekeeper  
**Flow:** New Bundle -> select products -> quantity -> bundle mode -> save.

## UC-007 Create Sale

**Actor:** Cashier  
**Flow:** Customer -> line items -> modifier -> calculate -> payment -> confirm -> print.

## UC-008 Collect Pending Payment

**Actor:** Cashier/Manager  
**Flow:** Pending list -> select invoice -> payment -> allocate -> receipt -> update balance.

## UC-009 Change Order Status

**Actor:** Authorized staff  
**Flow:** Open order -> valid next status -> reason if needed -> confirm -> audit.

## UC-010 Receive Stock

**Actor:** Storekeeper  
**Flow:** Vendor -> goods receipt -> lines -> post -> stock movement -> print.

## UC-011 Inventory Adjustment

**Actor:** Authorized storekeeper/manager  
**Flow:** choose item -> current stock -> actual stock -> reason -> approve -> post.

## UC-012 Record Expense

**Actor:** Authorized user  
**Flow:** category -> amount -> payee -> payment method -> attachment -> save.

## UC-013 Attendance

**Actor:** HR/Manager  
**Flow:** choose date -> mark staff -> save -> audit.

## UC-014 Payroll Run

**Actor:** Payroll-authorized user  
**Flow:** select period -> load attendance/leave/advances -> calculate -> preview -> approve -> finalize.

## UC-015 Backup

**Actor:** System/Administrator  
**Flow:** schedule/run -> lock critical backup snapshot -> dump -> file manifest -> verify -> finalize.

## UC-016 Restore

**Actor:** Administrator  
**Flow:** select backup -> validate -> safety backup -> restore staging -> validate -> switch -> smoke test.

## UC-017 License Activation

**Actor:** Administrator/Magnificent Solution support workflow  
**Flow:** input license -> verify signature -> check address binding -> check UMAC -> activate -> audit.

---

# 37. ACCEPTANCE CRITERIA

## AC-001 Offline Sale

Given the database and local API are healthy and the internet is disconnected, the cashier can create, confirm, print, and retrieve a sale.

## AC-002 Payment Integrity

Given a posted invoice, payment updates balance without modifying original invoice values.

## AC-003 Hierarchy Integrity

The system rejects circular service/product parent relationships.

## AC-004 Bundle Snapshot

Changing a group composition after a sale does not alter the historical sale snapshot.

## AC-005 Stock Integrity

A confirmed stock-out transaction creates the correct inventory movement and cannot exceed stock when negative stock is disabled.

## AC-006 Arabic RTL

Changing language to Arabic changes the application direction and localized labels throughout supported screens.

## AC-007 Document Consistency

The same invoice data renders consistently across A4 and thermal formats.

## AC-008 Backup Verification

A successful backup produces a manifest and verification result.

## AC-009 Restore Verification

A verified backup can be restored into a test/staging environment with integrity checks.

## AC-010 Permission Control

An unauthorized user cannot perform restricted rate override, discount, stock adjustment, payroll finalization, or restore actions through direct API calls.

## AC-011 License Expiry

License policy is enforced locally according to configured expiry behavior without corrupting existing business data.

## AC-012 Audit

Critical changes identify who, when, what entity, what action, and why where reason is required.

---

# 38. TEST PLAN

## Test Layers

```text
Unit Tests
Application Service Tests
Repository Tests
API Tests
Database Constraint Tests
Workflow Tests
Widget Tests
Integration Tests
Print Snapshot Tests
Localization Tests
RTL Tests
Backup/Restore Tests
Security Tests
Hardware Adapter Tests
Acceptance Tests
```

## Critical Test Categories

### Sales

- empty cart;
- zero quantity;
- decimal quantity;
- rate override;
- discount permission;
- mixed payment;
- overpayment;
- cancellation;
- reprint;
- partial ready order.

### Inventory

- stock receipt;
- stock issue;
- adjustment;
- concurrent terminal entry;
- negative-stock policy;
- bundle explosion.

### Localization

- English;
- Arabic;
- mixed numeric/RTL strings;
- PDF direction;
- thermal print direction where supported.

### Recovery

- corrupt backup file;
- incomplete backup;
- incompatible schema;
- restore failure rollback.

---

# 39. CODING GUIDELINES

## 39.1 General

- Prefer explicit naming over clever abstractions.
- Keep domain rules testable.
- Never place financial rules directly in widgets.
- Never trust client-provided totals; server/application service recalculates.
- Never trust client-provided permissions.
- Never perform silent database writes from view models.
- Never directly edit posted financial records; use reversal/adjustment logic.

## 39.2 Flutter

Recommended project structure:

```text
lib/
  app/
    app.dart
    router/
    theme/
    localization/
  core/
    errors/
    result/
    utils/
    constants/
    security/
  features/
    auth/
    dashboard/
    customers/
    vendors/
    services/
    products/
    sales/
    orders/
    inventory/
    purchasing/
    hr/
    payroll/
    expenses/
    reports/
    settings/
  shared/
    widgets/
    models/
    services/
```

Avoid a giant `utils.dart` or `common.dart` file.

## 39.3 PHP

Suggested structure:

```text
api/
  public/
  routes/
  middleware/
  controllers/
  services/
  domain/
  repositories/
  validators/
  policies/
  serializers/
  database/
  jobs/
  reports/
  printing/
  backup/
  licensing/
  umac/
```

## 39.4 DTO Rules

Use separate DTOs for:

- create;
- update;
- response;
- filter/query;
- print view model.

Do not expose raw database rows as public API contracts.

## 39.5 Error Handling

Use stable machine-readable codes:

```text
AUTH_INVALID_CREDENTIALS
AUTH_SESSION_EXPIRED
VALIDATION_ERROR
CUSTOMER_DUPLICATE
SERVICE_PARENT_CYCLE
PRODUCT_PARENT_CYCLE
SALE_EMPTY
SALE_TOTAL_MISMATCH
PAYMENT_EXCEEDS_BALANCE
STOCK_INSUFFICIENT
STATUS_TRANSITION_INVALID
LICENSE_EXPIRED
UMAC_MISMATCH
BACKUP_VERIFICATION_FAILED
RESTORE_VALIDATION_FAILED
PRINTER_UNAVAILABLE
```

---

# 40. TRANSACTION AND CONCURRENCY GUIDELINES

All critical workflows must use DB transactions.

Recommended transaction pattern:

```text
BEGIN
  validate preconditions
  lock required business rows where appropriate
  insert/update transactional entities
  insert immutable ledger movements
  insert audit record
  COMMIT
```

On error:

```text
ROLLBACK
return stable error code
```

For multi-terminal future deployment, use optimistic versioning and/or appropriate row locks.

---

# 41. AUDITABLE LEDGER PRINCIPLES

Financial and inventory history must be append-oriented.

For a posted sale:

```text
Sales document is immutable
Payment transaction is immutable
Inventory movement is immutable
Status history is append-only
Audit is append-only
```

Corrections create linked corrective transactions.

This is critical for reliable reconciliation.

---

# 42. DATA MIGRATION STRATEGY

Every schema release shall have:

```text
migration_id
previous_schema
new_schema
up_script
down_strategy_or_documented_irreversible_flag
validation_script
```

Never manually change production schema without a recorded migration.

Maintain `schema_version` in the database.

---

# 43. CONFIGURATION ENGINE

Configuration must be classified as:

### Global Static

- UI labels;
- localization keys;
- standard permission definitions.

### Business Configuration

- currency;
- document prefixes;
- numbering rules;
- default workflow;
- inventory policy;
- discount limits;
- payment terms.

### Terminal Configuration

- printer;
- scanner profile;
- cash drawer mode;
- default paper size;
- keyboard shortcuts.

### License Configuration

- edition;
- expiry;
- terminal limits;
- feature flags.

Configuration precedence:

```text
System Default
    < Business Override
    < Branch Override
    < Terminal Override
```

Only permitted keys may be overridden at each scope.

---

# 44. CUSTOMIZED SALES FLAVORS

The product must support configurable sales flavors so individual laundry vendors can customize workflows without forks in the codebase.

## Example Flavor A — Walk-In Laundry

- customer phone optional;
- quick catalog;
- immediate receipt;
- promised date;
- payment at intake.

## Flavor B — Corporate Account Laundry

- mandatory customer company;
- purchase/reference number;
- credit terms;
- monthly statement;
- invoice aging.

## Example Flavor C — Pickup & Delivery Laundry

- pickup address;
- delivery address;
- scheduled window;
- route status;
- driver/employee assignment;
- delivery proof.

## Example Flavor D — Premium Garment Care

- inspection checklist;
- stain notes;
- special handling modifier;
- quality check;
- damage review.

## Flavor Configuration Schema

```json
{
  "sales_flavor": "PICKUP_DELIVERY",
  "features": {
    "show_company_fields": true,
    "require_customer_phone": true,
    "require_promised_date": true,
    "allow_credit": true,
    "allow_partial_payment": true,
    "allow_delivery": true,
    "inspection_checklist": true,
    "quality_check": true
  }
}
```

The UI should dynamically activate configured fields while preserving a stable domain model.

---

# 45. FEATURE FLAG ENGINE

Feature flags shall not be scattered as hardcoded booleans in widgets.

Example:

```text
FeatureFlagService.isEnabled("sales.delivery")
```

Flags shall be categorized:

```text
CORE
BUSINESS
TERMINAL
LICENSE
EXPERIMENTAL
```

Critical controls should fail closed.

---

# 46. LOGGING

Log levels:

```text
ERROR
WARN
INFO
DEBUG
TRACE
```

Production default:

```text
INFO + WARN + ERROR
```

Sensitive data must be redacted.

Good log:

```text
SALE_CONFIRMATION_FAILED request_id=... order_id=... code=STOCK_INSUFFICIENT
```

Bad log:

```text
password=...
jwt=...
customer full private profile...
```

---

# 47. OBSERVABILITY WITHOUT CLOUD DEPENDENCY

Local observability shall include:

- health endpoint;
- database health;
- API health;
- backup status;
- print status;
- file store status;
- disk-space warning;
- application error log;
- request correlation id.

A local support diagnostic export should generate a bundle containing non-sensitive technical diagnostics.

---

# 48. DISK-SPACE MANAGEMENT

The application shall monitor:

- database storage;
- file storage;
- backup storage;
- temp directory.

Threshold examples:

```text
<20% free -> warning
<10% free -> critical
<5% free -> restrict backup-dependent actions as necessary and warn operator
```

Thresholds shall be configurable.

---

# 49. STARTUP HEALTH CHECK

On application launch:

```text
Check installation identity
 -> Check license
 -> Check local API
 -> Check database
 -> Check schema version
 -> Check migration status
 -> Check critical folders
 -> Check printer/scanner profiles
 -> Check backup health
 -> Check disk space
 -> Load localization
 -> Load user session
 -> Open workstation
```

Failures shall be classified as:

```text
BLOCKING
WARNING
INFORMATIONAL
```

---

# 50. MIGRATION AND VERSION COMPATIBILITY

Application must detect:

```text
app_version
api_version
schema_version
license_schema_version
```

Rules:

- application cannot silently operate against unknown newer schema;
- migration runs only when explicitly supported;
- failed migration triggers rollback or safe recovery path;
- migration result logged.

---

# 51. PERFORMANCE GUIDELINES

## UI

- avoid rebuilding large trees unnecessarily;
- lazy-load lists;
- debounce search;
- virtualize long tables;
- cache master metadata carefully;
- release heavy image resources.

## Database

- index real query patterns;
- avoid N+1 queries;
- page large lists;
- use projections for list screens;
- use summary queries for dashboards;
- archive only with controlled retention policy.

## API

- paginate;
- validate before DB writes;
- avoid repeated master lookups within a transaction;
- use request correlation ids.

---

# 52. RELIABILITY ENGINEERING

The product should prefer deterministic failure over silent corruption.

Examples:

```text
Printer unavailable -> save successful transaction, show print retry
Backup unavailable -> business operation may continue with visible critical warning according to policy
Database unavailable -> block write transaction, preserve draft locally where safe
License verification unavailable -> use offline signed verification policy
File attachment failure -> prevent posting only if attachment is mandatory
```

The system should distinguish **transaction success** from **document printing success**. A printer failure must not accidentally duplicate the sale.

---

# 53. IDEMPOTENCY

Write APIs that may be retried should accept an idempotency key where appropriate.

Example:

```text
X-Idempotency-Key: terminal_uuid + transaction_uuid
```

A duplicate confirmation request should return the original successful result rather than create a second invoice.

---

# 54. DOCUMENT NUMBERING

Document number configuration:

```text
INV-2026-000001
REC-2026-000001
CHL-2026-000001
CM-2026-000001
DM-2026-000001
GRN-2026-000001
```

Numbering must be generated server-side and committed atomically.

Avoid using timestamps as invoice numbers.

---

# 55. DRAFT RECOVERY

A cashier who closes the application during a draft transaction should not lose the draft if autosave is enabled.

Draft model:

```text
DRAFT
  -> local temporary snapshot
  -> server-side draft record when saved
  -> recover on next startup
```

Drafts must not generate financial or stock effects until confirmed.

---

# 56. DATA QUALITY RULES

Mandatory data should be minimal at the counter. Do not force operators to complete a full CRM profile for a simple walk-in transaction unless configured.

Use progressive enrichment:

```text
Minimum Sale Customer
 -> name/phone
 -> optional address
 -> professional profile later
```

Master duplicates should be detected by configurable similarity rules such as normalized phone or email.

---

# 57. SEARCH ENGINE FOR LOCAL DESKTOP

Search should support:

- exact customer phone;
- partial name;
- invoice number;
- barcode;
- service code;
- product code;
- customer code;
- order status;
- date range.

Search result ranking:

```text
exact code
exact phone
exact invoice
prefix match
contains match
```

Do not run unrestricted `%term%` scans across every large table.

---

# 58. REPORT FILTER STANDARD

Every report should expose consistent filter controls:

```text
Date From
Date To
Branch
Terminal
User
Customer
Vendor
Status
Category
Service
Product
Payment Method
```

A report definition should declare which filters are supported.

---

# 59. DASHBOARD KPI DEFINITIONS

## Today's Sales

```text
SUM(confirmed sales net totals for business date)
```

## Today's Collection

```text
SUM(posted payment transactions on business date)
```

## Outstanding

```text
SUM(invoice total - effective payments)
```

## Ready Orders

```text
COUNT(orders with READY_FOR_COLLECTION)
```

KPI SQL and definitions must be centralized to avoid different screens showing different values.

---

# 60. BUSINESS DATE VS SYSTEM DATE

The system must distinguish:

- system timestamp;
- business date;
- transaction date;
- promised date;
- delivery date.

This is critical around midnight and daily closing.

---

# 61. TIME ZONE

Initial default:

```text
Asia/Dubai
```

Store timestamps consistently according to product policy and convert for UI display. Avoid assuming the Windows machine's timezone is always correct for business reporting.

Future KSA configuration shall support:

```text
Asia/Riyadh
```

---

# 62. UAE-FIRST, KSA-READY LOCALIZATION

Architecture should avoid hardcoded assumptions about:

- emirate only;
- UAE postal conventions;
- AED only;
- Arabic dialect-specific labels;
- document numbering.

Country profile should define:

```text
country_code
currency
currency_fraction
timezone
default_locale
region_label
address_schema
```

KSA-ready design shall permit future SAR/halala configuration without rewriting the monetary engine.

---

# 63. UOM DESIGN

Units may include:

```text
PCS
PAIR
KG
GRAM
METER
SET
BUNDLE
LITER
BOX
PACK
DOZEN
```

Conversions should be explicit and configurable.

Example:

```text
1 dozen = 12 pcs
1 kg = 1000 g
```

Avoid implicit conversion by naming convention.

---

# 64. SERVICE PRICING MODEL

Pricing may be:

```text
FIXED
PER_ITEM
PER_WEIGHT
PER_AREA
PER_LENGTH
PER_BUNDLE
CUSTOM_QUOTE
```

The initial release may expose only required modes but domain design should not preclude future pricing.

For laundry, common implementation:

```text
per piece
per pair
per kg
bundle
```

---

# 65. SERVICE PROCESS TEMPLATE

A service can optionally have process steps:

```text
Receive
Inspect
Sort
Wash
Dry
Iron
Fold
Pack
QC
Ready
```

Each step may have:

- sequence;
- role;
- expected duration;
- required checklist;
- status.

This creates a reusable operations blueprint without forcing every laundry to use the same path.

---

# 66. QUALITY CHECKLIST

Optional checklist fields:

```text
item_condition_at_receipt
stains_present
missing_buttons
zip_condition
color_bleeding_risk
customer_special_instruction
post_service_condition
packaging_condition
```

Checklist templates should be configurable per service type/product type.

---

# 67. DAMAGE/LOSS CONTROL

A laundry business may need controlled exceptions.

Damage/loss record:

```text
order_id
order_line_id
product_id
reported_by
reported_at
incident_type
notes
photo_attachment
status
resolution_type
compensation_amount
approval
```

Compensation shall not modify original invoice history directly.

---

# 68. CUSTOMER REMINDERS

Reminder records may include:

- due payment;
- ready collection;
- delayed order;
- delivery scheduled.

Initial implementation should store reminder status and prepare printable/shareable assets. External messaging integration remains optional.

---

# 69. IMPORT/EXPORT

Supported import/export examples:

```text
Customer CSV
Vendor CSV
Service CSV
Product CSV
Opening Stock CSV
Price List CSV
Employee CSV
```

Exports:

```text
CSV
XLSX if implemented
JSON
PDF reports
```

Import must use staging tables.

```text
Upload
 -> parse
 -> validate
 -> preview
 -> resolve errors
 -> commit
 -> log
```

Never import directly into production tables line by line without validation staging.

---

# 70. DATA IMPORT ERROR REPORT

Example:

```text
Row | Field | Value | Error Code | Message Key
12  | phone | ...   | DUPLICATE  | customer.duplicate
21  | rate  | -5    | INVALID    | rate.must_be_nonnegative
34  | parent_id | 9 | CYCLE      | hierarchy.cycle
```

Allow corrected re-import without forcing manual recreation.

---

# 71. LOCAL API PROCESS MANAGEMENT

XAMPP/PHP should run as a local application service boundary.

The desktop launcher should check:

- Apache/PHP availability;
- MariaDB availability;
- port availability;
- required extension availability;
- application API health endpoint.

The product shall not assume a developer has manually configured XAMPP correctly after installation.

Installer/deployment documentation must specify supported XAMPP configuration and startup sequence.

---

# 72. LOCAL SECURITY BOUNDARY

The local API should listen only on the required interface by default.

Default stance:

```text
localhost-only
```

If future LAN multi-terminal support is enabled:

```text
controlled private LAN binding
firewall guidance
terminal authentication
```

Do not expose the local API to the public internet by default.

---

# 73. API SWAGGER STANDARD

OpenAPI shall document:

- endpoint;
- method;
- auth requirement;
- request schema;
- response schema;
- error codes;
- examples;
- idempotency expectations;
- permission requirement.

Example tag set:

```text
Auth
Configuration
Customers
Vendors
Services
Products
Sales
Orders
Payments
Inventory
Purchasing
HR
Payroll
Expenses
Reports
Documents
Backup
License
```

---

# 74. USER/ROLE MATRIX — STARTER

| Permission | Admin | Manager | Cashier | Storekeeper | HR | Auditor |
|---|---:|---:|---:|---:|---:|---:|
| Sales Create | Y | Y | Y | N | N | N |
| Sales Discount | Y | Y | Limited | N | N | N |
| Rate Override | Y | Y | Limited | N | N | N |
| Payment Receive | Y | Y | Y | N | N | N |
| Inventory Adjust | Y | Y | N | Y | N | N |
| Purchase Receive | Y | Y | N | Y | N | N |
| Payroll Run | Y | Limited | N | N | Y | R |
| Expense Approve | Y | Y | N | N | Limited | R |
| Backup | Y | Limited | N | N | N | N |
| Restore | Y | N | N | N | N | N |
| License Manage | Y | N | N | N | N | N |
| Reports | Y | Y | Limited | Limited | Limited | R |

`Limited` must be further decomposed into explicit permissions in production.

---

# 75. USER EXPERIENCE FOR TOUCH SCREEN

Touch mode should support:

- larger primary buttons;
- bigger line-item tap areas;
- numeric keypad;
- swipe-friendly lists where appropriate;
- no hover-only functionality;
- visible selected state;
- easy cancel/back.

The product shall work on ordinary Windows touch hardware without proprietary touchscreen software.

---

# 76. CASH DRAWER CONTROL

The application shall model a cash drawer as a device capability.

Functions:

```text
openDrawer()
getStatus() // if supported
recordManualOpen()
```

Manual drawer opening must be auditable if the hardware cannot report status directly.

---

# 77. CASH RECONCILIATION

At closing:

```text
Expected Cash
= Opening Float
+ Cash Receipts
- Cash Refunds
+/- Cash Adjustments
```

Physical cash count entered by operator.

```text
Difference = Physical Cash - Expected Cash
```

Difference above threshold requires explanation/approval.

---

# 78. REFUND / REVERSAL DESIGN

Never delete a completed sale.

Use:

```text
refund transaction
credit memo
debit memo
payment reversal
inventory reversal
```

All reversal records reference original transactions.

---

# 79. REPORT SNAPSHOT PRINCIPLE

Reports requiring historical commercial values must use posted transaction snapshots rather than current master data.

Example:

A service rate changed from AED 10 to AED 12. Historical invoices remain at AED 10.

---

# 80. PRICE PROFILE DESIGN

Future-ready price profiles:

```text
STANDARD
CORPORATE
PREMIUM
WALK_IN
SEASONAL
CUSTOMER_SPECIFIC
```

A sale line stores the effective rate used at posting.

---

# 81. DOCUMENT STATUS MACHINE

Documents should have a status separate from business workflow where needed.

Example invoice:

```text
DRAFT
POSTED
PARTIALLY_PAID
PAID
VOIDED
ADJUSTED
```

Order:

```text
DRAFT
RECEIVED
PROCESSING
READY
DELIVERED
CLOSED
CANCELLED
```

Do not overload one status field to mean both financial and operational state.

---

# 82. FILE INTEGRITY

Every managed file should store SHA-256 hash.

On backup/restore:

```text
calculate hash
compare manifest
flag mismatch
```

This detects silent corruption or incomplete copies.

---

# 83. BACKUP RETENTION

Example default policy:

```text
Daily local backups: 14 days
Weekly backups: 8 weeks
Monthly backups: 12 months
```

Actual retention must be configurable.

The backup engine should never delete the most recent known-good backup merely because a new backup failed.

---

# 84. SOFTWARE UPDATE STRATEGY

Future update system should support:

```text
Version Check
 -> Download/update package if available
 -> Verify signature/hash
 -> Backup database
 -> Put application in maintenance state
 -> Run migration
 -> Smoke test
 -> Mark successful
```

Never deploy unsigned binaries from arbitrary URLs.

---

# 85. SUPPORT MODE

A controlled support mode may generate:

- app version;
- schema version;
- API health;
- license state;
- OS info;
- printer profile;
- backup status;
- sanitized error logs.

Do not automatically transmit customer business data.

---

# 86. INSTALLATION DELIVERABLES

Installer package should include:

- Flutter Windows application;
- local PHP API service/runtime instructions;
- MariaDB/XAMPP setup instructions;
- database initialization script;
- migration runner;
- sample printer profiles;
- backup utility;
- user manual;
- administrator manual;
- restore manual;
- troubleshooting guide;
- license activation guide.

---

# 87. DOCUMENT PACKAGE DELIVERABLES

Magnificent Solution should deliver:

```text
01-RFP.md
02-BRD.md
03-SOW.md
04-ERD.md
05-USE-CASES.md
06-API-SPEC.md
07-UI-UX-SPEC.md
08-WORKFLOWS.md
09-TEST-CASES.md
10-ACCEPTANCE-CRITERIA.md
11-DEPLOYMENT.md
12-BACKUP-RECOVERY.md
13-LICENSE-UMAC.md
14-PRINT-TEMPLATES.md
15-CODING-STANDARDS.md
16-CHANGELOG.md
```

This master document consolidates those concerns into one implementation baseline.

---

# 88. FEATURE LIST — COMPLETE BASELINE

## Platform

- [x] Windows desktop
- [x] Offline-first
- [x] Local API
- [x] Local MySQL/MariaDB
- [x] MVVM
- [x] Modular local microservice-oriented architecture
- [x] OAuth2/JWT boundary
- [x] Swagger/OpenAPI
- [x] Audit trail
- [x] Config engine
- [x] Feature flags
- [x] Import/export
- [x] Backup/recovery
- [x] File management
- [x] License
- [x] UMAC
- [x] Physical-address binding

## Localization

- [x] English
- [x] Arabic
- [x] JSON labels
- [x] JSON validation messages
- [x] RTL/LTR
- [x] UAE locale
- [x] KSA extension path

## CRM

- [x] Customer master
- [x] Personal profile
- [x] Professional profile
- [x] Location profile
- [x] Vendor master
- [x] Customer merge
- [x] Vendor merge strategy

## Catalog

- [x] Service master
- [x] Product master
- [x] Nth-level hierarchy
- [x] Grouped service
- [x] Grouped product
- [x] Service-product M:N
- [x] Modifiers
- [x] UOM
- [x] Barcode
- [x] Images
- [x] Price profiles

## Sales

- [x] Instant sales
- [x] Memo
- [x] Invoice
- [x] Credit memo
- [x] Debit memo
- [x] Cash payment
- [x] Credit/pending payment
- [x] Payment allocation
- [x] Order hold
- [x] Reprint
- [x] Partial payment
- [x] Status workflow
- [x] Delivery
- [x] Collection
- [x] Challan
- [x] Reminder

## Inventory

- [x] Goods receipt
- [x] Stock movement
- [x] Stock adjustment
- [x] Stock reporting
- [x] Vendor purchase
- [x] Purchase return structure
- [x] Negative stock policy
- [x] Low stock alerts

## HR

- [x] Employee master
- [x] Attendance
- [x] Leave
- [x] Payroll
- [x] Advance salary
- [x] Advance recovery

## Expenses

- [x] Expense categories
- [x] Expense entries
- [x] Attachments
- [x] Approval

## Documents

- [x] Invoice PDF
- [x] Receipt
- [x] Challan
- [x] Memo
- [x] Report print
- [x] A4
- [x] A5
- [x] Thermal
- [x] Social-share asset
- [x] Template engine

## Hardware

- [x] Handheld scanner abstraction
- [x] Thermal printer abstraction
- [x] Inkjet printer abstraction
- [x] Dot matrix abstraction
- [x] Touch support
- [x] Cash drawer abstraction

---

# 89. PHASED DELIVERY ACCEPTANCE

## Phase 0 Exit

Documentation baseline is complete and internally consistent.

## Phase 1 Exit

Core business transactions function offline and survive application restart.

## Phase 2 Exit

Operational workflow, HR, payroll, expenses, delivery, inventory, and reporting are operational.

## Phase 3 Exit

Expansion interfaces and localization adapters are validated without destabilizing the core.

---

# 90. DEVELOPMENT GOVERNANCE

## Change Request Principle

Any new requirement after baseline approval should be classified:

```text
BUG
CLARIFICATION
SMALL CHANGE
NEW FEATURE
ARCHITECTURAL CHANGE
```

A change should document:

- rationale;
- impacted modules;
- database impact;
- UI impact;
- test impact;
- delivery impact;
- backward compatibility.

## No Scope Ambiguity

A phrase such as `and many more` shall never become automatic scope. New items should be added as explicit feature records.

---

# 91. DEFINITION OF DONE

A feature is Done only when:

```text
Requirement implemented
+ business rules implemented
+ permission enforced
+ API implemented
+ persistence implemented
+ audit implemented where applicable
+ localization implemented
+ RTL verified where applicable
+ validation implemented
+ unit/integration tests passed
+ print/report impact reviewed
+ backup/restore impact reviewed
+ documentation updated
```

---

# 92. CRITICAL ANTI-PATTERNS TO PROHIBIT

1. Storing totals as floating-point.
2. Updating posted invoices in place to correct them.
3. Deleting inventory movements.
4. Hardcoding service/product hierarchy depth.
5. Hardcoding English UI text.
6. Client-only authorization.
7. Putting SQL directly into widgets.
8. Creating manufacturer-specific hardware logic in business services.
9. Coupling printing success to transaction commit.
10. Making cloud connectivity mandatory for local sales.
11. Using raw machine serial values directly in visible license strings.
12. Restoring backups without a safety snapshot.
13. Duplicating calculation formulas across multiple screens.
14. Using current master price to display historical invoice prices.
15. Creating every feature as an independent modal dialog.

---

# 93. RECOMMENDED SOURCE CONTROL STRATEGY

```text
main
  |
  +-- develop
       |
       +-- feature/sales-instant-sale
       +-- feature/catalog-services
       +-- feature/catalog-products
       +-- feature/inventory
       +-- feature/hr
       +-- feature/backup
```

Use semantic commit messages:

```text
feat(sales): add mixed payment allocation
fix(inventory): prevent negative stock race
refactor(print): introduce document renderer interface
```

---

# 94. RELEASE VERSIONING

Use semantic versioning:

```text
MAJOR.MINOR.PATCH
```

Example:

```text
1.0.0  Initial production
1.1.0  New business feature
1.1.1  Bug fix
2.0.0  Breaking architectural/product change
```

Database schema versioning shall be independent but related.

---

# 95. PERFORMANCE ACCEPTANCE TARGETS

These are engineering targets, not guarantees:

```text
Local login response: typically < 1 second
Common customer search: typically < 500 ms
Add cart item: typically < 200 ms UI response
Open recent orders: typically < 1 second for paged result
Confirm ordinary sale: typically < 2 seconds excluding printer hardware latency
Dashboard load: typically < 2 seconds under normal local dataset size
```

Targets must be measured with realistic datasets rather than synthetic empty databases.

---

# 96. DATA VOLUME READINESS

Design should remain comfortable with approximately:

```text
Customers: 100,000+
Orders: 1,000,000+
Order lines: 5,000,000+
Inventory movements: 5,000,000+
Audit records: 10,000,000+
```

Actual performance depends on hardware, indexing, query patterns, archival strategy, and report complexity.

Reports that scan massive histories should use optimized summary tables or controlled date filters rather than loading all records into Flutter memory.

---

# 97. LOCAL MULTI-TERMINAL READINESS

Although the initial product is standalone, database architecture should allow future local network mode.

Future shape:

```text
Terminal A ----+
Terminal B ----+--> Local API Server --> MariaDB
Terminal C ----+
```

Terminal identity becomes important for:

- numbering;
- audit;
- cashier control;
- hardware profiles;
- license count;
- shift closing.

Do not bake `single_terminal` assumptions into the schema.

---

# 98. MULTI-BRANCH READINESS

Every operational transaction should be structurally capable of carrying:

```text
business_id
branch_id
terminal_id
```

Even if initial deployment uses one branch.

This reduces future migration complexity.

---

# 99. KSA EXTENSION CHECKLIST

Future KSA package should review:

- currency SAR;
- halala precision;
- timezone;
- Arabic-first option;
- Saudi address fields;
- local payroll rules if required;
- local statutory/tax requirements if later requested;
- document localization;
- local reporting requirements.

Do not assume UAE rules automatically transfer to KSA.

---

# 100. PROJECT RISKS

## Risk — Scope Expansion

Mitigation: feature register + change request process.

## Risk — Hardware Variation

Mitigation: adapter interfaces + certified printer/scanner profile tests.

## Risk — Data Corruption

Mitigation: transactions + append-only ledgers + backup verification.

## Risk — Wrong RTL Implementation

Mitigation: direction-aware layout primitives + Arabic UI test suite.

## Risk — License Lockout

Mitigation: signed offline license + grace/read-only policy + safe recovery/export rules.

## Risk — Printer Failure

Mitigation: transaction/document separation and reprint functionality.

## Risk — Large Dataset Slowdown

Mitigation: indexing + paging + summary queries.

## Risk — Payroll Legal Assumptions

Mitigation: configurable calculation engine and explicit jurisdiction module.

## Risk — Local API Exposure

Mitigation: localhost binding by default and controlled LAN enablement.

---

# 101. FINAL RECOMMENDED MODULE MAP

```text
LaundraCore Local
│
├── Platform
│   ├── Licensing
│   ├── UMAC
│   ├── Identity
│   ├── Configuration
│   ├── Localization
│   ├── Audit
│   ├── Backup
│   ├── Restore
│   ├── File Management
│   └── Support Diagnostics
│
├── CRM
│   ├── Customers
│   └── Vendors
│
├── Catalog
│   ├── Services
│   ├── Products
│   ├── Groups
│   ├── Modifiers
│   ├── UOM
│   └── Price Profiles
│
├── Sales
│   ├── Instant Sale
│   ├── Invoices
│   ├── Memos
│   ├── Payments
│   ├── Orders
│   ├── Challans
│   ├── Delivery
│   └── Collection
│
├── Operations
│   ├── Service Status
│   ├── Quality Check
│   ├── Rework
│   └── Damage/Loss
│
├── Inventory
│   ├── Stock
│   ├── Goods Receipt
│   ├── Adjustments
│   ├── Purchasing
│   └── Vendor Payables View
│
├── HR
│   ├── Employees
│   ├── Attendance
│   ├── Leave
│   ├── Payroll
│   └── Salary Advances
│
├── Expenses
│   └── Operating Expenses
│
├── Documents
│   ├── Templates
│   ├── Invoices
│   ├── Receipts
│   ├── Challans
│   └── Reports
│
└── Reports
    ├── Sales
    ├── Collections
    ├── Outstanding
    ├── Operations
    ├── Inventory
    ├── HR
    └── Expenses
```

---

# 102. MASTER TRANSACTION WORKFLOW

```text
                         +-------------------+
                         | CUSTOMER / WALKIN |
                         +---------+---------+
                                   |
                                   v
                         +-------------------+
                         | INSTANT SALE      |
                         +---------+---------+
                                   |
                    +--------------+--------------+
                    |                             |
                    v                             v
              SERVICE LINE                 PRODUCT LINE
                    |                             |
                    +--------------+--------------+
                                   |
                                   v
                             MODIFIERS
                                   |
                                   v
                           GROUP/BUNDLE RULES
                                   |
                                   v
                            PRICE ENGINE
                                   |
                                   v
                             ORDER CONFIRM
                                   |
                +------------------+------------------+
                |                  |                  |
                v                  v                  v
           PAYMENT             INVENTORY        STATUS HISTORY
                |                  |                  |
                +------------------+------------------+
                                   |
                                   v
                               DOCUMENT
                                   |
             +---------------------+---------------------+
             |                     |                     |
             v                     v                     v
          RECEIPT               CHALLAN              INVOICE
             |                     |                     |
             +---------------------+---------------------+
                                   |
                                   v
                               PROCESSING
                                   |
                                   v
                                  QC
                                   |
                            +------+------+
                            |             |
                            v             v
                         REWORK         READY
                            |             |
                            +------> PROCESS
                                          |
                                          v
                               COLLECTION / DELIVERY
                                          |
                                          v
                                        CLOSED
```

---

# 103. POSTED TRANSACTION INTEGRITY MODEL

A confirmed transaction should create a consistent cross-module record set:

```text
SALES_ORDER
    |
    +-- SALES_ORDER_LINE
    |
    +-- PAYMENT_TRANSACTION (0..n)
    |
    +-- INVENTORY_MOVEMENT (0..n)
    |
    +-- ORDER_STATUS_HISTORY (1..n)
    |
    +-- DOCUMENT
    |
    +-- AUDIT_LOG
```

The database should not reach a state where the invoice is posted but the payment is posted against a missing order, unless the system explicitly supports orphan-safe repair, which is discouraged.

---

# 104. RECONCILIATION ENGINE

Daily automated checks shall detect:

```text
Invoice total != line total
Payment total > invoice allowed balance
Negative balance without configured overpayment mode
Inventory movement sum != stored balance snapshot
Posted transaction missing audit
Document missing source transaction
Duplicate document number
Missing customer on mandatory transaction
Broken file asset reference
```

Result:

```text
PASS
WARNING
FAIL
```

Reconciliation failures should be visible in an administrative diagnostics screen.

---

# 105. FINAL QUALITY GATE

Before production deployment, the following gates must pass:

```text
[ ] BRD approved
[ ] Scope baseline approved
[ ] ERD reviewed
[ ] Database migration tested
[ ] API Swagger complete
[ ] Auth/permission tests passed
[ ] Sales end-to-end passed
[ ] Payment end-to-end passed
[ ] Inventory reconciliation passed
[ ] Order status tests passed
[ ] Arabic RTL tests passed
[ ] Print templates passed
[ ] Scanner test passed
[ ] Thermal printer test passed
[ ] Inkjet printer test passed
[ ] Dot matrix test passed
[ ] Cash drawer test passed where supported
[ ] Backup verified
[ ] Restore verified
[ ] License activation verified
[ ] UMAC verification verified
[ ] Disk-space warnings tested
[ ] App restart recovery tested
[ ] Data migration tested
[ ] Support diagnostic export tested
[ ] Acceptance test sign-off completed
```

---

# 106. IMPLEMENTATION ORDER

Recommended development order:

```text
1. Project bootstrap
2. Database schema + migrations
3. Local API foundation
4. Authentication + permissions
5. Configuration + localization
6. Business profile + terminal identity
7. Customer/vendor
8. Service/product hierarchy
9. UOM + modifiers + groups
10. Sales domain + calculation engine
11. Payment domain
12. Order status workflow
13. Printing/document engine
14. Inventory
15. Purchase
16. Delivery/collection
17. Notifications
18. HR
19. Attendance/leave
20. Payroll/advances
21. Expenses
22. Reports
23. Backup/restore hardening
24. License/UMAC hardening
25. Hardware testing
26. Performance testing
27. Security testing
28. Acceptance testing
29. Production packaging
```

---

# 107. MINIMUM PRODUCTION VIABLE RELEASE

A release should not be called production-ready until it can perform the complete business loop:

```text
Customer
 -> Service/Product
 -> Sale
 -> Payment or Pending
 -> Receipt/Invoice
 -> Service Status
 -> Ready
 -> Collection/Delivery
 -> Closed
 -> Daily Report
 -> Backup
```

And the master operational loop:

```text
Vendor
 -> Purchase/Receipt
 -> Inventory
 -> Sale Consumption
 -> Stock Reconciliation
```

And the employee loop:

```text
Employee
 -> Attendance
 -> Leave
 -> Payroll
 -> Advance Recovery
```

---

# 108. FINAL ARCHITECTURAL POSITION

LaundraCore Local shall be built as a **transaction-first, offline-first, modular desktop ERP/CRM/CMS platform** with a strong domain core.

The most important architectural principle is:

```text
UI is replaceable.
API is replaceable.
Printer is replaceable.
Database adapter is replaceable.
Cloud integration is optional.
Business rules and transaction history are the core.
```

The product must therefore avoid accidental coupling between:

- widget and SQL;
- print output and sales commit;
- internet and business transaction validity;
- current master price and historical invoices;
- machine identity and sensitive customer information;
- localization text and domain logic.

The target result is a dependable local operating platform for the client's laundry business that remains useful with no internet, supports bilingual UAE operation, works with mainstream Windows-compatible peripherals, and can evolve into multi-terminal, multi-branch, UAE-wide, and KSA-ready editions without replacing the underlying transaction model.

---

# 109. SIGN-OFF BASELINE

```text
PROJECT: LaundraCore Local
DEVELOPER/MAINTAINER: Magnificent Solution
CLIENT PROFILE: UAE Laundry Service MSME
INITIAL MARKET: Dubai
PRIMARY CURRENCY: AED + Fils
PRIMARY LOCALE: en-AE
SECONDARY LOCALE: ar-AE
PRIMARY PLATFORM: Flutter Windows Desktop
LOCAL DATA: MariaDB/MySQL
LOCAL API: PHP under XAMPP
ARCHITECTURE: MVVM + Modular Local Service Components
AUTH: OAuth2 Concepts + JWT Session Model
DOCS: Swagger/OpenAPI
CORE MODE: Offline
PAYMENT GATEWAY: Not Required
FX LIVE RATE: Not Required
LICENSE: Duration + Physical Address + UMAC
```

## Approval Sections

```text
Business Requirements Approved By: ____________________
Date: _______________________________________________

Technical Architecture Approved By: __________________
Date: _______________________________________________

UI/UX Direction Approved By: _________________________
Date: _______________________________________________

Acceptance Criteria Approved By: _____________________
Date: _______________________________________________
```

---

# 110. CHANGE LOG TEMPLATE

```text
Version | Date | Change | Author | Approved By
--------|------|--------|--------|------------
0.1.0   |      | Initial master baseline | Magnificent Solution | 
```

---

# END OF MASTER RFP / BRD / SOW / ER / USE-CASE / TECHNICAL BLUEPRINT
