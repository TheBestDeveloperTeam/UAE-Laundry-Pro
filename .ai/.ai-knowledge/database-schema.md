# Database Schema Architecture

This document specifies the database schemas for both the **Local Workstation Database (laundrypro)** and the **Central Multi-Tenant Cloud Database (laundrypro_cloud)**.

---

## 1. Local Database: laundrypro (MariaDB/MySQL)

- **Default Engine:** InnoDB
- **Default Charset:** utf8mb4 / utf8mb4_unicode_ci (Full bilingual Arabic & Emoji support)
- **Baseline Migration:** pi/database/migrations/001_baseline.sql

### Core Table Groupings

`mermaid
erDiagram
    BUSINESS ||--o{ BRANCHES : owns
    BRANCHES ||--o{ TERMINALS : contains
    CUSTOMERS ||--o{ SALES_ORDERS : places
    SALES_ORDERS ||--|{ SALES_ORDER_LINES : contains
    SALES_ORDER_LINES ||--|| SALES_ORDER_LINE_SNAPSHOTS : freezes
    SALES_ORDERS ||--o{ PAYMENT_TRANSACTIONS : pays
    SALES_ORDERS ||--o{ DELIVERY_TASKS : dispatches
    SALES_ORDERS ||--o{ CHALLANS : transfers
    SERVICES ||--o{ SALES_ORDER_LINES : billed_in
    PRODUCTS ||--o{ SALES_ORDER_LINES : billed_in
    VENDORS ||--o{ PURCHASE_ORDERS : fulfills
    EMPLOYEES ||--o{ ATTENDANCE : records
    EMPLOYEES ||--o{ PAYROLL_LINES : receives
`

### Table Dictionary

| Table Name | Primary Purpose | Key Fields |
|---|---|---|
| usiness | Single-tenant business identity | id, 
ame, 	ax_number, currency, 	imezone |
| ranches | Multi-branch location master | id, code, 
ame, ddress, phone, is_active |
| 	erminals | Registered workstation POS counters | id, ranch_id, 
ame, device_fingerprint |
| users | Local operator accounts & credentials | id, username, password_hash, ole, status |
| customers | Client CRM directory & balances | id, 
ame, phone, email, 	rn, credit_limit |
| endors | Suppliers & purchase contacts | id, 
ame, phone, 	rn, payment_terms_days |
| categories | Catalog grouping hierarchy | id, parent_id, 
ame_en, 
ame_ar, sort_order |
| services | Laundry treatment masters | id, category_id, code, 
ame_en, 
ame_ar, ase_price |
| products | Retail goods masters (detergents/hangers) | id, sku, 
ame_en, 
ame_ar, unit_price, stock_qty |
| sales_orders | Header POS sales transaction | id, order_number, customer_id, status, gross_total |
| sales_order_lines | Detail line items of order | id, sales_order_id, item_type, unit_price, quantity |
| sales_order_line_snapshots| Immutable historical freeze | id, sales_order_line_id, snapshot_json, created_at |
| payment_transactions | Payment settlement records | id, sales_order_id, payment_method, mount, eference |
| challans | Factory / processing transfer slips | id, challan_number, ranch_id, status, line_count |
| delivery_tasks | Pickup and home delivery dispatcher | id, sales_order_id, driver_id, scheduled_at, status |
| purchase_orders | Supplier procurement orders | id, po_number, endor_id, 	otal_amount, status |
| employees | Staff identity and employment contracts| id, employee_code, irst_name, asic_salary, status |
| ttendance | Work shift punches and hours | id, employee_id, date, check_in, check_out |
| payroll_runs | Monthly salary batch runs | id, period_month, period_year, 	otal_net_payout |
| expenses | Operational expense vouchers | id, category_id, mount, payment_method, 	ax_deductible |
| sync_outbox | Local change queue for cloud push | id, entity_type, entity_id, payload, status |
| hardware_identity | Workstation hardware fingerprint | id, umac_code, egistered_at, last_validated_at |

---

## 2. Central Multi-Tenant Database: laundrypro_cloud (MariaDB/MySQL)

- **Baseline Schema:** cloud-api/database/001_cloud_schema.sql
- **Initial Seeds:** cloud-api/database/002_cloud_seeds.sql

`mermaid
erDiagram
    CLOUD_SUPER_ADMINS ||--o{ CLOUD_AUDIT_LOGS : actions
    BUSINESSES ||--o{ CLOUD_LICENSES : holds
    BUSINESSES ||--o{ SYNC_RECORDS : transmits
    BUSINESSES ||--o{ CLOUD_TELEMETRY : reports
`

### Table Dictionary

| Table Name | Primary Purpose | Key Fields |
|---|---|---|
| cloud_super_admins | Portal administrators | id, username, email, password_hash, ole |
| usinesses | Registered laundry tenant nodes | id, 
ame, 	rade_license_no, cloud_token, status |
| sync_records | Multi-tenant data lake | id, 	enant_id, entity_type, entity_local_id, payload |
| cloud_licenses | Issued cryptographic licenses | id, 	enant_id, license_key, umac_fingerprint, status |
| cloud_telemetry | Node uptime and telemetry | id, 	enant_id, workstation_ip, pp_version, last_ping |
| cloud_audit_logs | Security and audit trail | id, super_admin_id, 	enant_id, ction, ip_address |
