# Database Schema

Database: `laundrypro` (utf8mb4)

## Phase 0–1 core
- `schema_migrations`, `roles`, `users`, `refresh_tokens`, `settings`, `audit_logs`, `license`
- `business`, `branches`, `terminals`
- `customers`, `vendors`
- `categories`, `services`, `products`, `service_product_map`, `service_modifiers`, `product_modifiers`
- `sales_orders`, `sales_order_lines`, `sales_order_line_snapshots`, `payment_transactions`
- `inventory_movements`, `inventory_adjustments`
- `sync_outbox`, `sync_state`
- `file_assets`, `document_templates`
- `umac_policy`, `hardware_identity`

## Phase 2 operations
- `order_status_history`
- `delivery_tasks`, `challans`, `challan_lines`, `challan_sequences`
- `purchase_orders`, `purchase_order_lines`, `goods_receipts`, `goods_receipt_lines`, `inventory_locations`
- `employees`, `attendance`, `leave_types`, `leave_requests`
- `payroll_periods`, `payroll_runs`, `payroll_lines`, `salary_advances`
- `expense_categories`, `expenses`, `expense_attachments`
- `notifications`, `notification_reads`

Migrations: `api/database/migrations/` (001–019)
