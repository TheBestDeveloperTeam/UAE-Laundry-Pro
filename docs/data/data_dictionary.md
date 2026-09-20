# Data Dictionary - LaundryPro UAE
> **Version:** 1.0.0

## Naming Conventions
- Tables: snake_case, plural (e.g., orders, order_items)
- Columns: snake_case (e.g., business_owner_id, created_at)
- PKs: id (BIGINT UNSIGNED AUTO_INCREMENT)
- FKs: {referenced_table_singular}_id (e.g., order_id, customer_id)
- Booleans: is_{adjective} (e.g., is_active, is_paid)
- Timestamps: {action}_at (e.g., created_at, deleted_at)
- Money: DECIMAL(18,2) with descriptive name (e.g., unit_price, total_amount)

## Core Tables
| Table | Description | Tenant-Scoped |
|-------|-------------|:---:|
| business_owners | Tenant registration and profile | No (is tenant) |
| branches | Branch locations per tenant | Yes |
| users | System users (employees) | Yes |
| roles | RBAC role definitions | No (global) |
| permissions | RBAC permission definitions | No (global) |
| role_permissions | Role-permission mapping | No (global) |
| customers | Customer profiles | Yes |
| services | Service catalog (wash, dry-clean, etc.) | Yes |
| price_lists | Pricing tiers and schedules | Yes |
| orders | Order headers | Yes |
| order_items | Order line items | Yes |
| order_status_history | Order status transitions | Yes |
| invoices | Invoice headers | Yes |
| invoice_items | Invoice line items | Yes |
| payments | Payment transactions | Yes |
| inventory_items | Supply inventory | Yes |
| inventory_transactions | Stock in/out records | Yes |
| employees | Employee master records | Yes |
| attendance | Check-in/check-out records | Yes |
| payroll | Payroll calculation records | Yes |
| deliveries | Delivery assignments | Yes |
| delivery_items | Items in a delivery | Yes |
| garment_tags | Barcode/RFID tag assignments | Yes |
| production_stages | Garment processing stages | Yes |
| audit_logs | All state change audit entries | Yes |
| sync_outbox | Offline sync queue | Yes |
| machine_licenses | UMAC license bindings | No (system) |
| system_settings | Global system configuration | No (system) |
| migrations | Schema migration tracking | No (system) |

## Standard Columns (all tenant-scoped tables)
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED AUTO_INCREMENT | Primary key |
| business_owner_id | BIGINT UNSIGNED FK | Tenant isolation |
| created_at | DATETIME DEFAULT CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | DATETIME ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| created_by | BIGINT UNSIGNED FK (users) | Creator user |
| updated_by | BIGINT UNSIGNED FK (users) | Last updater user |
| is_active | TINYINT(1) DEFAULT 1 | Soft delete flag |
| deleted_at | DATETIME NULL | Soft delete timestamp |