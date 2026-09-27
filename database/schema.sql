-- LaundryPro UAE baseline schema (P1 + P2 + P3)
-- Generated for greenfield installs v1.2.1
-- Incremental migrations archived under migrations/archive/
-- Do not edit by hand; regenerate from archive when schema changes.
-- ===== 001_initial_schema.sql =====
CREATE TABLE IF NOT EXISTS schema_migrations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  migration VARCHAR(255) NOT NULL UNIQUE,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL UNIQUE,
  permissions JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  role_id INT UNSIGNED NOT NULL,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS settings (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(150) NOT NULL,
  setting_value JSON NOT NULL,
  scope ENUM('system', 'business', 'branch', 'terminal') NOT NULL DEFAULT 'business',
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_settings_key_scope (setting_key, scope)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  action VARCHAR(255) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_id INT UNSIGNED NULL,
  payload JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_entity (entity_type, entity_id, created_at),
  INDEX idx_audit_user (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS license (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  license_key VARCHAR(255) NOT NULL,
  umac VARCHAR(255) NULL,
  physical_address_hash VARCHAR(255) NULL,
  expires_at TIMESTAMP NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  activated_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 002_seed_roles.sql =====
INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000001', 'administrator', JSON_ARRAY('*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'administrator');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000002', 'cashier', JSON_ARRAY('sales.create', 'sales.read', 'customers.read'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'cashier');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'business.name', JSON_QUOTE('LaundryPro UAE'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'business.name' AND scope = 'business');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'locale.default', JSON_QUOTE('en'), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'locale.default' AND scope = 'system');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'currency.default', JSON_OBJECT('major', 'AED', 'minor', 'Fils', 'digits', 2), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'currency.default' AND scope = 'system');

-- Default admin user: username=admin password=admin123 (change immediately in production)
INSERT INTO users (uuid, role_id, username, password_hash, full_name, email, is_active)
SELECT
  '00000000-0000-4000-8000-000000000010',
  r.id,
  'admin',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'System Administrator',
  'admin@laundrypro.local',
  1
FROM roles r
WHERE r.name = 'administrator'
  AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- ===== 003_business_branch_terminal.sql =====
CREATE TABLE IF NOT EXISTS business (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL UNIQUE,
  legal_name VARCHAR(255) NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  address_line1 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  emirate VARCHAR(100) NULL,
  country VARCHAR(100) NOT NULL DEFAULT 'AE',
  physical_address_hash VARCHAR(64) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS branches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_id INT UNSIGNED NOT NULL,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_branch_code (business_id, code),
  CONSTRAINT fk_branches_business FOREIGN KEY (business_id) REFERENCES business(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS terminals (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  branch_id INT UNSIGNED NOT NULL,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_terminal_code (branch_id, code),
  CONSTRAINT fk_terminals_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO business (uuid, admin_id, legal_name, display_name, city, emirate, country)
SELECT '00000000-0000-4000-8000-000000000100', 1, 'LaundryPro UAE', 'LaundryPro UAE', 'Dubai', 'Dubai', 'AE'
WHERE NOT EXISTS (SELECT 1 FROM business WHERE admin_id = 1);

INSERT INTO branches (uuid, business_id, code, name)
SELECT '00000000-0000-4000-8000-000000000101', b.id, 'MAIN', 'Main Branch'
FROM business b WHERE b.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM branches WHERE code = 'MAIN' AND business_id = b.id);

INSERT INTO terminals (uuid, branch_id, code, name)
SELECT '00000000-0000-4000-8000-000000000102', br.id, 'T01', 'Counter 1'
FROM branches br
INNER JOIN business b ON b.id = br.business_id AND b.admin_id = 1
WHERE br.code = 'MAIN'
  AND NOT EXISTS (SELECT 1 FROM terminals WHERE code = 'T01' AND branch_id = br.id);

-- ===== 004_customers_vendors.sql =====
CREATE TABLE IF NOT EXISTS customers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  customer_code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  address_line1 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  emirate VARCHAR(100) NULL,
  customer_type ENUM('personal', 'professional', 'walk_in') NOT NULL DEFAULT 'personal',
  credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0,
  outstanding_balance DECIMAL(18,2) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_customer_local (admin_id, local_id),
  INDEX idx_customer_phone (phone),
  INDEX idx_customer_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS vendors (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  vendor_code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(150) NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  address_line1 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  notes TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_vendor_local (admin_id, local_id),
  INDEX idx_vendor_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 005_catalog_services_products.sql =====
CREATE TABLE IF NOT EXISTS categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  parent_id INT UNSIGNED NULL,
  type ENUM('service', 'product') NOT NULL,
  name VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_category_parent (parent_id),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS services (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  parent_id INT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  base_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_group TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_service_local (admin_id, local_id),
  INDEX idx_service_parent (parent_id),
  CONSTRAINT fk_services_parent FOREIGN KEY (parent_id) REFERENCES services(id),
  CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  parent_id INT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  barcode VARCHAR(100) NULL,
  base_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  stock_quantity DECIMAL(18,3) NOT NULL DEFAULT 0,
  low_stock_threshold DECIMAL(18,3) NOT NULL DEFAULT 0,
  is_group TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_local (admin_id, local_id),
  INDEX idx_product_parent (parent_id),
  INDEX idx_product_barcode (barcode),
  CONSTRAINT fk_products_parent FOREIGN KEY (parent_id) REFERENCES products(id),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_product_map (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  service_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  default_qty DECIMAL(18,3) NOT NULL DEFAULT 1,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_service_product (service_id, product_id),
  CONSTRAINT fk_spm_service FOREIGN KEY (service_id) REFERENCES services(id),
  CONSTRAINT fk_spm_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 006_sales_payments.sql =====
CREATE TABLE IF NOT EXISTS sales_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  order_no VARCHAR(50) NOT NULL,
  customer_id INT UNSIGNED NULL,
  status ENUM('draft', 'confirmed', 'received', 'processing', 'ready', 'delivered', 'closed', 'cancelled') NOT NULL DEFAULT 'draft',
  payment_status ENUM('pending', 'partial', 'paid') NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
  discount DECIMAL(18,2) NOT NULL DEFAULT 0,
  tax DECIMAL(18,2) NOT NULL DEFAULT 0,
  grand_total DECIMAL(18,2) NOT NULL DEFAULT 0,
  amount_paid DECIMAL(18,2) NOT NULL DEFAULT 0,
  balance_due DECIMAL(18,2) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  confirmed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_order_local (admin_id, local_id),
  UNIQUE KEY uq_order_no (admin_id, order_no),
  INDEX idx_sales_customer (customer_id),
  CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_sales_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sales_order_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sales_order_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  item_type ENUM('service', 'product', 'group') NOT NULL,
  item_id INT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(18,3) NOT NULL DEFAULT 1,
  rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  discount DECIMAL(18,2) NOT NULL DEFAULT 0,
  amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  service_status ENUM('received', 'in_process', 'ready', 'delivered', 'cancelled') NOT NULL DEFAULT 'received',
  modifiers JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_order_line (sales_order_id, line_no),
  CONSTRAINT fk_lines_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payment_transactions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  sales_order_id INT UNSIGNED NOT NULL,
  payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  amount DECIMAL(18,2) NOT NULL,
  payment_method ENUM('cash', 'credit', 'debit', 'cheque', 'adjustment') NOT NULL DEFAULT 'cash',
  reference_number VARCHAR(100) NULL,
  received_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_payment_order (sales_order_id),
  CONSTRAINT fk_payment_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_payment_user FOREIGN KEY (received_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 007_inventory.sql =====
CREATE TABLE IF NOT EXISTS inventory_movements (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  product_id INT UNSIGNED NOT NULL,
  movement_type ENUM('receipt', 'issue', 'adjustment', 'sale_consumption') NOT NULL,
  quantity DECIMAL(18,3) NOT NULL,
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_inv_product (product_id),
  INDEX idx_inv_type (movement_type),
  INDEX idx_inv_owner (admin_id),
  CONSTRAINT fk_inv_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_inv_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventory_adjustments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  product_id INT UNSIGNED NOT NULL,
  quantity_before DECIMAL(18,3) NOT NULL,
  quantity_after DECIMAL(18,3) NOT NULL,
  reason VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_adj_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_adj_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'inventory.allow_negative_stock', JSON_QUOTE('false'), 'inventory'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'inventory.allow_negative_stock' AND scope = 'inventory');

-- ===== 008_hr_payroll.sql =====
CREATE TABLE IF NOT EXISTS employees (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_no VARCHAR(50) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) NULL,
  email VARCHAR(150) NULL,
  job_title VARCHAR(100) NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_no (admin_id, employee_no),
  INDEX idx_emp_owner (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS attendance (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  attendance_date DATE NOT NULL,
  status ENUM('present', 'absent', 'half_day', 'leave') NOT NULL DEFAULT 'present',
  check_in TIME NULL,
  check_out TIME NULL,
  notes VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_attendance_day (employee_id, attendance_date),
  CONSTRAINT fk_att_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_att_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_types (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_paid TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_requests (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  leave_type_id INT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  reason TEXT NULL,
  approved_by INT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_leave_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_leave_type FOREIGN KEY (leave_type_id) REFERENCES leave_types(id),
  CONSTRAINT fk_leave_approver FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_periods (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status ENUM('open', 'closed') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_payroll_period (admin_id, period_start, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_runs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  payroll_period_id INT UNSIGNED NOT NULL,
  run_no VARCHAR(50) NOT NULL,
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  status ENUM('draft', 'posted') NOT NULL DEFAULT 'posted',
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pr_period FOREIGN KEY (payroll_period_id) REFERENCES payroll_periods(id),
  CONSTRAINT fk_pr_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payroll_run_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NOT NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0,
  advance_deduction DECIMAL(18,2) NOT NULL DEFAULT 0,
  net_pay DECIMAL(18,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_pl_run FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
  CONSTRAINT fk_pl_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS salary_advances (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  balance_remaining DECIMAL(18,2) NOT NULL,
  status ENUM('open', 'recovered', 'cancelled') NOT NULL DEFAULT 'open',
  notes VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sa_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_sa_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO leave_types (uuid, admin_id, name, is_paid)
SELECT UUID(), 1, 'Annual Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Annual Leave' AND admin_id = 1);

INSERT INTO leave_types (uuid, admin_id, name, is_paid)
SELECT UUID(), 1, 'Sick Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Sick Leave' AND admin_id = 1);

-- ===== 009_expenses.sql =====
CREATE TABLE IF NOT EXISTS expense_categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_exp_cat (admin_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  category_id INT UNSIGNED NOT NULL,
  expense_date DATE NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  description VARCHAR(255) NULL,
  status ENUM('draft', 'pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  created_by INT UNSIGNED NULL,
  approved_by INT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_exp_category FOREIGN KEY (category_id) REFERENCES expense_categories(id),
  CONSTRAINT fk_exp_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_exp_approver FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expense_attachments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  expense_id INT UNSIGNED NOT NULL,
  file_asset_id INT UNSIGNED NULL,
  file_path VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ea_expense FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO expense_categories (uuid, admin_id, name)
SELECT UUID(), 1, 'Utilities'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Utilities' AND admin_id = 1);

INSERT INTO expense_categories (uuid, admin_id, name)
SELECT UUID(), 1, 'Supplies'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Supplies' AND admin_id = 1);

-- ===== 010_sync_outbox.sql =====
CREATE TABLE IF NOT EXISTS sync_state (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL UNIQUE,
  last_push_at TIMESTAMP NULL,
  last_pull_at TIMESTAMP NULL,
  cloud_api_url VARCHAR(500) NULL,
  cloud_token_hash VARCHAR(64) NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_outbox (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation ENUM('create', 'update', 'delete') NOT NULL,
  payload JSON NOT NULL,
  synced_at TIMESTAMP NULL,
  sync_attempts INT UNSIGNED NOT NULL DEFAULT 0,
  last_error VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_outbox_pending (admin_id, synced_at, created_at),
  INDEX idx_outbox_entity (entity_type, entity_local_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO sync_state (admin_id, is_enabled)
SELECT 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sync_state WHERE admin_id = 1);

-- ===== 011_documents_files.sql =====
CREATE TABLE IF NOT EXISTS file_assets (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INT UNSIGNED NULL,
  file_path VARCHAR(500) NOT NULL,
  checksum_sha256 CHAR(64) NULL,
  mime_type VARCHAR(100) NULL,
  size_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_file_entity (entity_type, entity_id),
  INDEX idx_file_owner (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS document_templates (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  template_key VARCHAR(50) NOT NULL,
  format ENUM('thermal', 'a4') NOT NULL,
  schema_json JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_template (admin_id, template_key, format)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO document_templates (uuid, admin_id, template_key, format, schema_json)
SELECT '00000000-0000-4000-8000-000000000101', 1, 'receipt', 'thermal',
  JSON_OBJECT('version', 1, 'width', 48, 'fields', JSON_ARRAY('order_no', 'lines', 'totals', 'payments'))
WHERE NOT EXISTS (SELECT 1 FROM document_templates WHERE template_key = 'receipt' AND format = 'thermal');

INSERT INTO document_templates (uuid, admin_id, template_key, format, schema_json)
SELECT '00000000-0000-4000-8000-000000000102', 1, 'receipt', 'a4',
  JSON_OBJECT('version', 1, 'page', 'A4', 'fields', JSON_ARRAY('order_no', 'lines', 'totals', 'payments'))
WHERE NOT EXISTS (SELECT 1 FROM document_templates WHERE template_key = 'receipt' AND format = 'a4');

-- ===== 012_license_umac_runtime.sql =====
CREATE TABLE IF NOT EXISTS umac_policy (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  policy_key VARCHAR(50) NOT NULL,
  policy_value JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_umac_policy (admin_id, policy_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS hardware_identity (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  umac_hash CHAR(64) NOT NULL,
  machine_fingerprint TEXT NOT NULL,
  first_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_hw_umac (admin_id, umac_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO umac_policy (uuid, admin_id, policy_key, policy_value)
SELECT '00000000-0000-4000-8000-000000000201', 1, 'bind_to_hardware', JSON_OBJECT('enabled', true, 'max_devices', 1)
WHERE NOT EXISTS (SELECT 1 FROM umac_policy WHERE policy_key = 'bind_to_hardware');

-- ===== 013_modifiers.sql =====
CREATE TABLE IF NOT EXISTS service_modifiers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  service_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  extra_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_svc_mod_service (service_id),
  CONSTRAINT fk_svc_mod_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS product_modifiers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  product_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  extra_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_prod_mod_product (product_id),
  CONSTRAINT fk_prod_mod_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sales_order_line_snapshots (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sales_order_line_id INT UNSIGNED NOT NULL,
  snapshot_type ENUM('bundle', 'modifiers') NOT NULL,
  snapshot_json JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_snapshot_line (sales_order_line_id),
  CONSTRAINT fk_snapshot_line FOREIGN KEY (sales_order_line_id) REFERENCES sales_order_lines(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 014_sync_cloud_token.sql =====
ALTER TABLE sync_state ADD COLUMN cloud_token VARCHAR(255) NULL AFTER cloud_token_hash;

-- ===== 015_production_workflow.sql =====
CREATE TABLE IF NOT EXISTS order_status_history (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sales_order_id INT UNSIGNED NOT NULL,
  from_status VARCHAR(50) NULL,
  to_status VARCHAR(50) NOT NULL,
  changed_by INT UNSIGNED NULL,
  notes VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_osh_order (sales_order_id),
  CONSTRAINT fk_osh_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_osh_user FOREIGN KEY (changed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE sales_orders
  ADD COLUMN expected_ready_date DATE NULL,
  ADD COLUMN promised_date DATE NULL,
  ADD COLUMN delivery_address TEXT NULL,
  ADD COLUMN delivery_notes TEXT NULL;

-- ===== 016_delivery_challans.sql =====
CREATE TABLE IF NOT EXISTS delivery_tasks (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  sales_order_id INT UNSIGNED NOT NULL,
  task_type ENUM('delivery', 'collection') NOT NULL DEFAULT 'delivery',
  scheduled_at DATETIME NULL,
  address TEXT NULL,
  notes TEXT NULL,
  assigned_employee_id INT UNSIGNED NULL,
  status ENUM('scheduled', 'in_progress', 'completed', 'failed', 'cancelled') NOT NULL DEFAULT 'scheduled',
  completed_at TIMESTAMP NULL,
  failed_reason VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_dt_order (sales_order_id),
  CONSTRAINT fk_dt_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_dt_employee FOREIGN KEY (assigned_employee_id) REFERENCES employees(id),
  CONSTRAINT fk_dt_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS challans (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  challan_no VARCHAR(50) NOT NULL,
  challan_type ENUM('delivery', 'collection', 'stock_transfer', 'vendor_return', 'service_receipt') NOT NULL,
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  status ENUM('draft', 'issued', 'cancelled') NOT NULL DEFAULT 'issued',
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_challan_no (admin_id, challan_type, challan_no),
  CONSTRAINT fk_ch_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS challan_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  challan_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(18,3) NOT NULL DEFAULT 1,
  unit VARCHAR(20) NULL,
  CONSTRAINT fk_cl_challan FOREIGN KEY (challan_id) REFERENCES challans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS challan_sequences (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  challan_type VARCHAR(50) NOT NULL,
  last_number INT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY uk_ch_seq (admin_id, challan_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 017_purchasing.sql =====
CREATE TABLE IF NOT EXISTS purchase_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  po_no VARCHAR(50) NOT NULL,
  vendor_id INT UNSIGNED NOT NULL,
  status ENUM('draft', 'ordered', 'partial', 'received', 'cancelled') NOT NULL DEFAULT 'draft',
  order_date DATE NOT NULL,
  expected_date DATE NULL,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_po_no (admin_id, po_no),
  CONSTRAINT fk_po_vendor FOREIGN KEY (vendor_id) REFERENCES vendors(id),
  CONSTRAINT fk_po_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchase_order_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity_ordered DECIMAL(18,3) NOT NULL,
  quantity_received DECIMAL(18,3) NOT NULL DEFAULT 0,
  unit_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_pol_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_pol_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS goods_receipts (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  purchase_order_id INT UNSIGNED NOT NULL,
  receipt_no VARCHAR(50) NOT NULL,
  received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  UNIQUE KEY uk_gr_no (admin_id, receipt_no),
  CONSTRAINT fk_gr_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  CONSTRAINT fk_gr_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS goods_receipt_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  goods_receipt_id INT UNSIGNED NOT NULL,
  purchase_order_line_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity DECIMAL(18,3) NOT NULL,
  CONSTRAINT fk_grl_gr FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipts(id) ON DELETE CASCADE,
  CONSTRAINT fk_grl_pol FOREIGN KEY (purchase_order_line_id) REFERENCES purchase_order_lines(id),
  CONSTRAINT fk_grl_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventory_locations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_loc_name (admin_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO inventory_locations (uuid, admin_id, name, is_default)
SELECT UUID(), 1, 'Main Store', 1
WHERE NOT EXISTS (SELECT 1 FROM inventory_locations WHERE admin_id = 1 AND is_default = 1);

-- ===== 018_notifications.sql =====
CREATE TABLE IF NOT EXISTS notifications (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  notification_type VARCHAR(50) NOT NULL,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  severity ENUM('info', 'warning', 'error') NOT NULL DEFAULT 'info',
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notif_owner (admin_id),
  INDEX idx_notif_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification_reads (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  notification_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_notif_user (notification_id, user_id),
  CONSTRAINT fk_nr_notif FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
  CONSTRAINT fk_nr_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 019_sales_status_enum.sql =====
ALTER TABLE sales_orders
  MODIFY COLUMN status ENUM(
    'draft', 'confirmed', 'received', 'sorting', 'processing', 'quality_check',
    'packed', 'ready', 'ready_for_collection', 'out_for_delivery', 'delivered',
    'on_hold', 'rework_required', 'closed', 'cancelled'
  ) NOT NULL DEFAULT 'draft';

-- ===== 020_branch_terminal_context.sql =====
ALTER TABLE sales_orders
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id,
  ADD COLUMN terminal_id INT UNSIGNED NULL AFTER branch_id;

ALTER TABLE inventory_movements
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id;

ALTER TABLE employees
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id;

ALTER TABLE expenses
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id;

UPDATE sales_orders SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;
UPDATE employees SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;

-- ===== 021_terminal_sessions.sql =====
CREATE TABLE IF NOT EXISTS terminal_sessions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  terminal_id INT UNSIGNED NOT NULL,
  session_token VARCHAR(128) NOT NULL UNIQUE,
  device_fingerprint VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_seen_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ts_terminal (terminal_id),
  CONSTRAINT fk_ts_terminal FOREIGN KEY (terminal_id) REFERENCES terminals(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 022_sync_entity_registry.sql =====
CREATE TABLE IF NOT EXISTS sync_entity_types (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entity_type VARCHAR(50) NOT NULL UNIQUE,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO sync_entity_types (entity_type) VALUES
  ('customer'), ('vendor'), ('sales_order'), ('employee'), ('expense'),
  ('challan'), ('purchase_order'), ('notification'), ('payroll_run');

-- ===== 023_ksa_profile.sql =====
CREATE TABLE IF NOT EXISTS country_profiles (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code CHAR(2) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  currency_symbol VARCHAR(10) NOT NULL,
  timezone VARCHAR(64) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO country_profiles (code, name, currency_code, currency_symbol, timezone) VALUES
  ('AE', 'United Arab Emirates', 'AED', 'AED', 'Asia/Dubai'),
  ('SA', 'Saudi Arabia', 'SAR', 'SAR', 'Asia/Riyadh');

-- ===== 024_notification_channels.sql =====
CREATE TABLE IF NOT EXISTS notification_channels (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  channel_type ENUM('sms', 'whatsapp', 'email') NOT NULL,
  provider VARCHAR(50) NOT NULL DEFAULT 'stub',
  config_json JSON NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification_messages (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  channel_id INT UNSIGNED NOT NULL,
  recipient VARCHAR(100) NOT NULL,
  template_key VARCHAR(50) NOT NULL,
  body TEXT NOT NULL,
  status ENUM('queued', 'sent', 'failed') NOT NULL DEFAULT 'queued',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_nm_channel FOREIGN KEY (channel_id) REFERENCES notification_channels(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 025_accounting_exports.sql =====
CREATE TABLE IF NOT EXISTS accounting_export_batches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  adapter VARCHAR(50) NOT NULL DEFAULT 'csv',
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status ENUM('draft', 'exported', 'failed') NOT NULL DEFAULT 'draft',
  file_path VARCHAR(500) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS accounting_export_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  batch_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  account_code VARCHAR(50) NOT NULL,
  description VARCHAR(255) NOT NULL,
  debit DECIMAL(18,2) NOT NULL DEFAULT 0,
  credit DECIMAL(18,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_ael_batch FOREIGN KEY (batch_id) REFERENCES accounting_export_batches(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 026_analytics_snapshots.sql =====
CREATE TABLE IF NOT EXISTS analytics_daily_snapshots (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  branch_id INT UNSIGNED NULL,
  snapshot_date DATE NOT NULL,
  metric_key VARCHAR(50) NOT NULL,
  metric_value DECIMAL(18,4) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_analytics_day (admin_id, branch_id, snapshot_date, metric_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 027_storefront.sql =====
CREATE TABLE IF NOT EXISTS storefront_tokens (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  token_hash VARCHAR(128) NOT NULL UNIQUE,
  label VARCHAR(100) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS storefront_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  customer_name VARCHAR(150) NOT NULL,
  customer_phone VARCHAR(50) NOT NULL,
  notes TEXT NULL,
  status ENUM('pending', 'converted', 'cancelled') NOT NULL DEFAULT 'pending',
  sales_order_id INT UNSIGNED NULL,
  payload_json JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 028_customer_portal.sql =====
CREATE TABLE IF NOT EXISTS customer_portal_tokens (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  sales_order_id INT UNSIGNED NOT NULL,
  access_token VARCHAR(128) NOT NULL UNIQUE,
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cpt_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 029_account_lockout.sql =====
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS failed_attempts INT UNSIGNED NOT NULL DEFAULT 0 AFTER is_active,
  ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP NULL DEFAULT NULL AFTER failed_attempts;

-- ===== 030_seed_roles.sql =====
INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000003', 'manager', JSON_ARRAY('sales.*', 'inventory.*', 'customers.*', 'reports.sales'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'manager');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000004', 'storekeeper', JSON_ARRAY('inventory.*', 'purchase.receive'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'storekeeper');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000005', 'hr', JSON_ARRAY('hr.*', 'reports.hr'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'hr');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000006', 'auditor', JSON_ARRAY('reports.*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'auditor');

-- ===== 031_performance_indexes.sql =====
ALTER TABLE customers
  ADD INDEX IF NOT EXISTS idx_customer_code (customer_code);

ALTER TABLE vendors
  ADD INDEX IF NOT EXISTS idx_vendor_code (vendor_code);

ALTER TABLE services
  ADD INDEX IF NOT EXISTS idx_svc_parent_active (parent_id, is_active);

ALTER TABLE products
  ADD INDEX IF NOT EXISTS idx_prod_parent_active_bc (parent_id, is_active, barcode);

ALTER TABLE sales_orders
  ADD INDEX IF NOT EXISTS idx_sales_cust_created (customer_id, created_at),
  ADD INDEX IF NOT EXISTS idx_sales_status_promised (status, promised_date);

ALTER TABLE inventory_movements
  ADD INDEX IF NOT EXISTS idx_inv_prod_created (product_id, created_at);

ALTER TABLE notifications
  ADD INDEX IF NOT EXISTS idx_notif_created (created_at);


CREATE TABLE IF NOT EXISTS businesses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  license_key VARCHAR(255) NULL,
  cloud_token VARCHAR(64) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation VARCHAR(20) NOT NULL,
  payload JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_sync_entity (admin_id, entity_type, entity_local_id),
  INDEX idx_sync_owner (admin_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- LaundryPro UAE Central Cloud Schema (Multi-Tenant & Super-Admin)
-- Compatible with MariaDB / MySQL 5.7+ / 8.0+

CREATE TABLE IF NOT EXISTS cloud_super_admins (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(191) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(128) NOT NULL DEFAULT 'Super Administrator',
  role VARCHAR(32) NOT NULL DEFAULT 'super_admin',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS businesses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  license_key VARCHAR(255) NULL,
  cloud_token VARCHAR(64) NOT NULL UNIQUE,
  trade_license_no VARCHAR(100) NULL,
  contact_email VARCHAR(191) NULL,
  contact_phone VARCHAR(50) NULL,
  country_code VARCHAR(10) NOT NULL DEFAULT 'AE',
  city VARCHAR(100) NOT NULL DEFAULT 'Dubai',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('active', 'suspended', 'trial', 'expired') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation VARCHAR(20) NOT NULL,
  payload JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_sync_entity (admin_id, entity_type, entity_local_id),
  INDEX idx_sync_owner (admin_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_licenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  license_key VARCHAR(128) NOT NULL UNIQUE,
  umac_fingerprint VARCHAR(128) NULL,
  plan_type VARCHAR(50) NOT NULL DEFAULT 'standard',
  max_invoices INT NOT NULL DEFAULT 999999,
  max_customers INT NOT NULL DEFAULT 999999,
  status ENUM('active', 'revoked', 'expired') NOT NULL DEFAULT 'active',
  expires_at DATETIME NULL,
  signature TEXT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tenant_lic (tenant_id),
  INDEX idx_lic_key (license_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_telemetry (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  workstation_ip VARCHAR(64) NULL,
  app_version VARCHAR(32) NULL,
  os_version VARCHAR(64) NULL,
  umac VARCHAR(128) NULL,
  status_payload JSON NULL,
  last_ping_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_telemetry_tenant (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  super_admin_id INT UNSIGNED NULL,
  tenant_id INT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  details TEXT NULL,
  ip_address VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 001_initial_schema.sql
-- Establishes the foundational schema for the local offline-first environment

CREATE TABLE IF NOT EXISTS `schema_migrations` (
  `migration` VARCHAR(255) PRIMARY KEY,
  `applied_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- BASE COLUMN SET TEMPLATE (For Reference in future migrations)
-- All business tables MUST include:
-- `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
-- `uuid` CHAR(36) NOT NULL,
-- `admin_id` BIGINT UNSIGNED NOT NULL,
-- `row_uuid` CHAR(36) NOT NULL UNIQUE,
-- `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
-- `sync_attempts` TINYINT DEFAULT 0,
-- `last_sync_at` DATETIME NULL,
-- `origin` ENUM('local', 'cloud') DEFAULT 'local',
-- `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
-- `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
-- `deleted_at` DATETIME NULL,
-- INDEX(`admin_id`), INDEX(`sync_status`), INDEX(`uuid`)
-- ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS `settings` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  -- Core business columns
  `scope` VARCHAR(50) NOT NULL,
  `key_name` VARCHAR(100) NOT NULL,
  `value` TEXT,
  `reference_id` BIGINT UNSIGNED DEFAULT NULL,

  -- Sync tracking columns
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_settings_admin` (`admin_id`),
  INDEX `idx_settings_sync` (`sync_status`),
  INDEX `idx_settings_uuid` (`uuid`),
  UNIQUE KEY `uk_settings_scope_key` (`admin_id`, `scope`, `key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sync_outbox` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `terminal_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `entity_type` VARCHAR(100) NOT NULL,
  `entity_id` CHAR(36) NOT NULL, -- references the row_uuid of the mutated row
  `operation` ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  `payload` JSON,
  
  `status` ENUM('pending', 'synced', 'failed', 'dead_letter') DEFAULT 'pending',
  `attempts` TINYINT DEFAULT 0,
  `last_error` TEXT,
  
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `synced_at` DATETIME NULL,
  
  INDEX `idx_outbox_status` (`status`),
  INDEX `idx_outbox_entity` (`entity_type`, `entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Core users table to establish initial Super-Admin / Admin structure
CREATE TABLE IF NOT EXISTS `users` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `name` VARCHAR(150) NOT NULL,
  `email` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(50) DEFAULT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `is_active` BOOLEAN DEFAULT TRUE,
  
  -- Sync tracking columns
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_users_admin` (`admin_id`),
  INDEX `idx_users_sync` (`sync_status`),
  INDEX `idx_users_uuid` (`uuid`),
  UNIQUE KEY `uk_users_email` (`admin_id`, `email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Core roles table
CREATE TABLE IF NOT EXISTS `roles` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  
  -- Sync tracking columns
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_roles_admin` (`admin_id`),
  INDEX `idx_roles_sync` (`sync_status`),
  INDEX `idx_roles_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Laundry Pro Desktop � Advanced Module Additive Schema
-- Sprint 2: Data Model Extension
CREATE TABLE IF NOT EXISTS advanced_cycle_presets (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id INT UNSIGNED NOT NULL,
    cycle_name VARCHAR(150) NOT NULL,
    temperature_c DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    duration_minutes INT NOT NULL DEFAULT 0,
    detergent_ratio DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    spin_speed_rpm INT NOT NULL DEFAULT 0,
    chemical_dosage_map JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cycle_preset_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS equipment (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    asset_tag VARCHAR(100) NOT NULL UNIQUE,
    equipment_type VARCHAR(100) NOT NULL,
    last_calibration_date DATE NULL,
    next_calibration_due DATE NULL,
    out_of_service TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS advanced_cycle_runs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    sales_order_line_id INT UNSIGNED NOT NULL,
    preset_id INT UNSIGNED NOT NULL,
    equipment_id INT UNSIGNED NOT NULL,
    operator_employee_id INT UNSIGNED NOT NULL,
    status ENUM('running', 'exception', 'completed') NOT NULL DEFAULT 'running',
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    CONSTRAINT fk_cycle_run_sol FOREIGN KEY (sales_order_line_id) REFERENCES sales_order_lines(id),
    CONSTRAINT fk_cycle_run_preset FOREIGN KEY (preset_id) REFERENCES advanced_cycle_presets(id),
    CONSTRAINT fk_cycle_run_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(id),
    CONSTRAINT fk_cycle_run_operator FOREIGN KEY (operator_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS process_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    metric_type ENUM('ph', 'temperature') NOT NULL,
    reading_value DECIMAL(18,2) NOT NULL,
    threshold_min DECIMAL(18,2) NOT NULL,
    threshold_max DECIMAL(18,2) NOT NULL,
    pass_fail TINYINT(1) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_process_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sterilization_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    autoclave_program VARCHAR(150) NOT NULL,
    pressure_kpa DECIMAL(18,2) NOT NULL,
    temperature_c DECIMAL(18,2) NOT NULL,
    duration_minutes INT NOT NULL,
    validation_result ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sterilization_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS chemical_usage_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL,
    cycle_run_id INT UNSIGNED NOT NULL,
    lot_number VARCHAR(100) NOT NULL,
    expiry_date DATE NOT NULL,
    quantity_used DECIMAL(18,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chemical_log_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_chemical_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS batch_lots (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    lot_number VARCHAR(100) NOT NULL UNIQUE,
    expiry_date DATE NOT NULL,
    origin_sales_order_id INT UNSIGNED NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_lot_order FOREIGN KEY (origin_sales_order_id) REFERENCES sales_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS batch_scan_events (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_lot_id INT UNSIGNED NOT NULL,
    scan_type ENUM('in', 'out') NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    scanned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_scan_lot FOREIGN KEY (batch_lot_id) REFERENCES batch_lots(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS calibration_records (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipment_id INT UNSIGNED NOT NULL,
    calibrated_at DATE NOT NULL,
    performed_by VARCHAR(150) NOT NULL,
    certificate_ref VARCHAR(150) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_calibration_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS operator_certifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    certification_name VARCHAR(150) NOT NULL,
    issued_at DATE NOT NULL,
    expires_at DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_operator_cert_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS electronic_signatures (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    signature_hash CHAR(64) NOT NULL,
    meaning VARCHAR(150) NOT NULL,
    signed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_esign_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id),
    CONSTRAINT fk_esign_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS controlled_garments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    garment_tag VARCHAR(100) NOT NULL UNIQUE,
    iso_class VARCHAR(50) NOT NULL,
    wash_cycle_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cg_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS gowning_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    controlled_garment_id INT UNSIGNED NOT NULL,
    employee_id INT UNSIGNED NOT NULL,
    event_type ENUM('gowning', 'degowning') NOT NULL,
    event_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gl_garment FOREIGN KEY (controlled_garment_id) REFERENCES controlled_garments(id),
    CONSTRAINT fk_gl_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS cloud_agent (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    cloud_agent_id CHAR(36) NOT NULL UNIQUE,
    agent_secret_hash VARCHAR(255) NOT NULL,
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_handshake_at TIMESTAMP NULL,
    CONSTRAINT fk_cloud_agent_business FOREIGN KEY (business_id) REFERENCES business(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS loyalty_ledger (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    points_delta INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ll_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE sync_outbox ADD COLUMN status ENUM('pending', 'synced', 'failed') NOT NULL DEFAULT 'pending', ADD COLUMN next_retry_at TIMESTAMP NULL DEFAULT NULL;
-- Default Super-Admin credentials:
-- Username: superadmin
-- Password: SuperAdmin@LaundryPro2026!
-- Hash generated via password_hash('SuperAdmin@LaundryPro2026!', PASSWORD_DEFAULT)

INSERT INTO cloud_super_admins (id, username, email, password_hash, full_name, role, is_active)
VALUES (
  1,
  'superadmin',
  'superadmin@magnificentsolution.co.in',
  '$2y$10$eE0oI9uL5O9B7zT7w7Nq6.H.w187QjXo2bWqC6cZyS85Ewh9bK87y',
  'Master Super Administrator',
  'super_admin',
  1
) ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
-- Migration 002_rbac_schema.sql
-- Establishes the permissions and RBAC mapping

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL UNIQUE, -- e.g., sales.create, inventory.adjust
  `description` VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `role_permissions` (
  `role_id` BIGINT UNSIGNED NOT NULL,
  `permission_id` BIGINT UNSIGNED NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  
  -- Sync tracking columns for role modifications per tenant
  `uuid` CHAR(36) NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`role_id`, `permission_id`, `admin_id`),
  INDEX `idx_rp_admin` (`admin_id`),
  INDEX `idx_rp_sync` (`sync_status`),
  INDEX `idx_rp_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert core permissions if not present
INSERT IGNORE INTO `permissions` (`name`, `description`) VALUES 
('sales.create', 'Create new sales orders'),
('sales.view', 'View sales orders'),
('sales.refund', 'Refund sales orders'),
('inventory.adjust', 'Adjust inventory stock'),
('hr.payroll.run', 'Run monthly payroll'),
('customers.manage', 'Manage customer profiles'),
('settings.manage', 'Manage application settings');
-- ===== 003_audit_fixes.sql =====

-- AUD-001: Triggers for electronic_signatures to enforce append-only immutability
DELIMITER //
CREATE TRIGGER trg_electronic_signatures_before_update
BEFORE UPDATE ON electronic_signatures
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Electronic signatures are immutable and cannot be updated (21 CFR Part 11)';
END//

CREATE TRIGGER trg_electronic_signatures_before_delete
BEFORE DELETE ON electronic_signatures
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Electronic signatures are immutable and cannot be deleted (21 CFR Part 11)';
END//
DELIMITER ;

-- AUD-004: Composite index on advanced_cycle_runs
CREATE INDEX idx_adv_cycle_status_started ON advanced_cycle_runs (status, started_at);

-- PRF-001: Missing composite indexes
CREATE INDEX idx_sales_orders_owner_status ON sales_orders (admin_id, status);
CREATE INDEX idx_customers_phone ON customers (phone);

-- SEC-008: Add previous_hash column to audit_logs
ALTER TABLE audit_logs ADD COLUMN previous_hash CHAR(64) NULL AFTER payload;

-- PHP-016: Create idempotency_keys table
CREATE TABLE IF NOT EXISTS idempotency_keys (
  id_key VARCHAR(100) PRIMARY KEY,
  response_code INT NOT NULL,
  response_body JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  INDEX idx_idemp_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 003_catalog_schema.sql
-- Establishes the dynamic master-detail catalog schema

CREATE TABLE IF NOT EXISTS `categories` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `parent_id` BIGINT UNSIGNED DEFAULT NULL,
  `name` VARCHAR(150) NOT NULL,
  
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_cat_admin` (`admin_id`),
  INDEX `idx_cat_sync` (`sync_status`),
  INDEX `idx_cat_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `services` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `category_id` BIGINT UNSIGNED DEFAULT NULL,
  `name` VARCHAR(150) NOT NULL,
  `base_price` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT '5.00',
  `is_active` BOOLEAN DEFAULT TRUE,
  
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_srv_admin` (`admin_id`),
  INDEX `idx_srv_sync` (`sync_status`),
  INDEX `idx_srv_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `service_details` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `service_id` BIGINT UNSIGNED NOT NULL,
  `field_key` VARCHAR(100) NOT NULL,
  `field_value` TEXT,
  
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_srvdet_admin` (`admin_id`),
  INDEX `idx_srvdet_sync` (`sync_status`),
  INDEX `idx_srvdet_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `products` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `category_id` BIGINT UNSIGNED DEFAULT NULL,
  `name` VARCHAR(150) NOT NULL,
  `default_rate` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `stock_class` ENUM('retail', 'consumable', 'asset') DEFAULT 'retail',
  `is_active` BOOLEAN DEFAULT TRUE,
  
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_prod_admin` (`admin_id`),
  INDEX `idx_prod_sync` (`sync_status`),
  INDEX `idx_prod_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_details` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `product_id` BIGINT UNSIGNED NOT NULL,
  `field_key` VARCHAR(100) NOT NULL,
  `field_value` TEXT,
  
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_proddet_admin` (`admin_id`),
  INDEX `idx_proddet_sync` (`sync_status`),
  INDEX `idx_proddet_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `service_product_map` (
  `service_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  
  `uuid` CHAR(36) NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`service_id`, `product_id`, `admin_id`),
  INDEX `idx_spm_admin` (`admin_id`),
  INDEX `idx_spm_sync` (`sync_status`),
  INDEX `idx_spm_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 004_sales_schema.sql
-- Establishes the Sales and POS Engine tables

CREATE TABLE IF NOT EXISTS `sales_orders` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `order_number` VARCHAR(50) NOT NULL,
  `consumer_id` BIGINT UNSIGNED DEFAULT NULL, -- 1 for Walk-In, or references consumers.id
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  `status` ENUM('draft', 'confirmed', 'in_production', 'ready', 'delivered', 'paid', 'void', 'refunded') DEFAULT 'draft',
  
  -- Financial totals (bcmath 2-decimal scale)
  `subtotal` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `discount_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `grand_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `paid_amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  -- Metadata
  `hold_note` VARCHAR(255) DEFAULT NULL,
  `created_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_so_admin` (`admin_id`),
  INDEX `idx_so_sync` (`sync_status`),
  INDEX `idx_so_uuid` (`uuid`),
  INDEX `idx_so_number` (`order_number`),
  INDEX `idx_so_consumer` (`consumer_id`),
  INDEX `idx_so_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sales_order_lines` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `order_id` BIGINT UNSIGNED NOT NULL,
  `service_id` BIGINT UNSIGNED DEFAULT NULL,
  `product_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Snapshot of names/prices at time of sale
  `item_name` VARCHAR(150) NOT NULL,
  `quantity` DECIMAL(10,2) NOT NULL DEFAULT '1.00',
  `unit_price` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT '0.00',
  
  -- Line totals
  `line_subtotal` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `line_tax` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `line_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_sol_admin` (`admin_id`),
  INDEX `idx_sol_sync` (`sync_status`),
  INDEX `idx_sol_uuid` (`uuid`),
  INDEX `idx_sol_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `payment_transactions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `order_id` BIGINT UNSIGNED NOT NULL,
  `tender_type` ENUM('cash', 'card', 'account_credit', 'voucher') NOT NULL,
  `amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `reference_code` VARCHAR(100) DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_pt_admin` (`admin_id`),
  INDEX `idx_pt_sync` (`sync_status`),
  INDEX `idx_pt_uuid` (`uuid`),
  INDEX `idx_pt_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- For Walk-In fallback if consumer management (Phase 1.7) isn't fully ready yet,
-- ensure consumers table exists so we can map ID=1
CREATE TABLE IF NOT EXISTS `consumers` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `type` ENUM('individual','hotel','industry','pharma','chemical_factory','restaurant','corporate','other') DEFAULT 'individual',
  `name` VARCHAR(150) NOT NULL,
  `mobile_normalized` VARCHAR(50) DEFAULT NULL,
  `outstanding_balance` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_cons_admin` (`admin_id`),
  INDEX `idx_cons_sync` (`sync_status`),
  INDEX `idx_cons_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 005_inventory_schema.sql
-- Establishes Inventory Movements

CREATE TABLE IF NOT EXISTS `inventory_movements` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `product_id` BIGINT UNSIGNED NOT NULL,
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  `movement_type` ENUM('receipt', 'sale', 'adjustment', 'transfer_in', 'transfer_out', 'spoilage') NOT NULL,
  
  `quantity_change` DECIMAL(10,2) NOT NULL,
  `balance_after` DECIMAL(10,2) NOT NULL,
  
  `reference_type` VARCHAR(50) DEFAULT NULL, -- 'sales_order', 'purchase_order', 'challan'
  `reference_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `notes` VARCHAR(255) DEFAULT NULL,
  `created_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_inv_admin` (`admin_id`),
  INDEX `idx_inv_sync` (`sync_status`),
  INDEX `idx_inv_uuid` (`uuid`),
  INDEX `idx_inv_prod` (`product_id`),
  INDEX `idx_inv_branch` (`branch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add stock columns to products table if not exists (already has stock_class, adding actual quantity)
-- Actually, the best practice is keeping current stock in products or inventory_balances table.
CREATE TABLE IF NOT EXISTS `inventory_balances` (
  `product_id` BIGINT UNSIGNED NOT NULL,
  `branch_id` BIGINT UNSIGNED NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  
  `uuid` CHAR(36) NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `current_stock` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `reorder_point` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `reorder_quantity` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`product_id`, `branch_id`, `admin_id`),
  INDEX `idx_invbal_admin` (`admin_id`),
  INDEX `idx_invbal_sync` (`sync_status`),
  INDEX `idx_invbal_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 006_refunds_schema.sql
-- Establishes Refunds and Correction Memos tables

CREATE TABLE IF NOT EXISTS `credit_memos` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `memo_number` VARCHAR(50) NOT NULL,
  `ref_order_id` BIGINT UNSIGNED NOT NULL, -- references sales_orders.id
  `consumer_id` BIGINT UNSIGNED DEFAULT NULL,
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `status` ENUM('draft', 'approved', 'applied', 'void') DEFAULT 'draft',
  
  -- Financial totals (bcmath 2-decimal scale)
  `subtotal` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `grand_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  `reason` VARCHAR(255) DEFAULT NULL,
  `created_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_cm_admin` (`admin_id`),
  INDEX `idx_cm_sync` (`sync_status`),
  INDEX `idx_cm_uuid` (`uuid`),
  INDEX `idx_cm_order` (`ref_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `credit_memo_lines` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `memo_id` BIGINT UNSIGNED NOT NULL,
  `ref_order_line_id` BIGINT UNSIGNED DEFAULT NULL,
  `product_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `item_name` VARCHAR(150) NOT NULL,
  `quantity_refunded` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `unit_price` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT '0.00',
  
  -- Line totals
  `line_subtotal` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `line_tax` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `line_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  `return_to_stock` BOOLEAN DEFAULT FALSE,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_cml_admin` (`admin_id`),
  INDEX `idx_cml_sync` (`sync_status`),
  INDEX `idx_cml_uuid` (`uuid`),
  INDEX `idx_cml_memo` (`memo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 007_purchasing_schema.sql
-- Establishes Vendors and Purchase Orders tables

CREATE TABLE IF NOT EXISTS `vendors` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `name` VARCHAR(150) NOT NULL,
  `contact_person` VARCHAR(100) DEFAULT NULL,
  `phone` VARCHAR(50) DEFAULT NULL,
  `email` VARCHAR(150) DEFAULT NULL,
  `address` TEXT DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL,

  INDEX `idx_vendor_admin` (`admin_id`),
  INDEX `idx_vendor_sync` (`sync_status`),
  INDEX `idx_vendor_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `purchase_orders` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `po_number` VARCHAR(50) NOT NULL,
  `vendor_id` BIGINT UNSIGNED NOT NULL,
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `status` ENUM('draft', 'sent', 'partially_received', 'received', 'cancelled') DEFAULT 'draft',
  
  -- Financial totals (bcmath 2-decimal scale)
  `subtotal` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `grand_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  `notes` VARCHAR(255) DEFAULT NULL,
  `created_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_po_admin` (`admin_id`),
  INDEX `idx_po_sync` (`sync_status`),
  INDEX `idx_po_uuid` (`uuid`),
  INDEX `idx_po_vendor` (`vendor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `purchase_order_lines` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `po_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  
  `item_name` VARCHAR(150) NOT NULL,
  `quantity_ordered` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `quantity_received` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `unit_price` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT '0.00',
  
  -- Line totals
  `line_subtotal` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `line_tax` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `line_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_pol_admin` (`admin_id`),
  INDEX `idx_pol_sync` (`sync_status`),
  INDEX `idx_pol_uuid` (`uuid`),
  INDEX `idx_pol_po` (`po_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 008_production_challan_schema.sql
-- Establishes Order Status History and Challans tables

CREATE TABLE IF NOT EXISTS `order_status_history` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `order_id` BIGINT UNSIGNED NOT NULL,
  `from_status` VARCHAR(50) NOT NULL,
  `to_status` VARCHAR(50) NOT NULL,
  
  `changed_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_osh_admin` (`admin_id`),
  INDEX `idx_osh_sync` (`sync_status`),
  INDEX `idx_osh_uuid` (`uuid`),
  INDEX `idx_osh_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `challans` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `challan_number` VARCHAR(50) NOT NULL,
  
  `source_branch_id` BIGINT UNSIGNED NOT NULL,
  `destination_branch_id` BIGINT UNSIGNED NOT NULL,
  
  `status` ENUM('draft', 'dispatched', 'received', 'void') DEFAULT 'draft',
  
  `dispatched_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  `received_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  `dispatched_at` DATETIME NULL,
  `received_at` DATETIME NULL,
  
  `notes` VARCHAR(255) DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_challan_admin` (`admin_id`),
  INDEX `idx_challan_sync` (`sync_status`),
  INDEX `idx_challan_uuid` (`uuid`),
  INDEX `idx_challan_number` (`challan_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `challan_lines` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `challan_id` BIGINT UNSIGNED NOT NULL,
  `order_id` BIGINT UNSIGNED NOT NULL, -- references sales_orders.id
  
  `item_count` INT NOT NULL DEFAULT 1,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_challan_lines_admin` (`admin_id`),
  INDEX `idx_challan_lines_sync` (`sync_status`),
  INDEX `idx_challan_lines_uuid` (`uuid`),
  INDEX `idx_challan_lines_challan` (`challan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 009_delivery_schema.sql
-- Establishes Pickups and Deliveries tables

CREATE TABLE IF NOT EXISTS `delivery_tasks` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `task_type` ENUM('pickup', 'delivery') NOT NULL,
  `order_id` BIGINT UNSIGNED DEFAULT NULL, -- references sales_orders.id, optional for new pickup requests
  
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `driver_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `scheduled_date` DATE NOT NULL,
  `scheduled_time_slot` VARCHAR(50) DEFAULT NULL,
  `address` TEXT NOT NULL,
  `latitude` DECIMAL(10, 8) DEFAULT NULL,
  `longitude` DECIMAL(11, 8) DEFAULT NULL,
  
  `status` ENUM('pending', 'assigned', 'in_transit', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
  
  `failure_reason` VARCHAR(255) DEFAULT NULL,
  `completed_at` DATETIME NULL,
  `notes` TEXT DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_dt_admin` (`admin_id`),
  INDEX `idx_dt_sync` (`sync_status`),
  INDEX `idx_dt_uuid` (`uuid`),
  INDEX `idx_dt_order` (`order_id`),
  INDEX `idx_dt_driver` (`driver_id`),
  INDEX `idx_dt_date` (`scheduled_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `delivery_task_lines` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `task_id` BIGINT UNSIGNED NOT NULL,
  `item_description` VARCHAR(150) NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_dtl_admin` (`admin_id`),
  INDEX `idx_dtl_sync` (`sync_status`),
  INDEX `idx_dtl_uuid` (`uuid`),
  INDEX `idx_dtl_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 010_invoicing_schema.sql
-- Establishes Invoicing and Customer Ledger tables

CREATE TABLE IF NOT EXISTS `invoices` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `invoice_number` VARCHAR(50) NOT NULL,
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `status` ENUM('draft', 'sent', 'partially_paid', 'paid', 'void') DEFAULT 'draft',
  
  -- Financial totals (bcmath 2-decimal scale)
  `subtotal` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `grand_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `paid_amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  `due_date` DATE DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  
  `created_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_invoice_admin` (`admin_id`),
  INDEX `idx_invoice_sync` (`sync_status`),
  INDEX `idx_invoice_uuid` (`uuid`),
  INDEX `idx_invoice_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `invoice_lines` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `invoice_id` BIGINT UNSIGNED NOT NULL,
  `delivery_task_id` BIGINT UNSIGNED DEFAULT NULL, -- ties back to completed delivery
  `order_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `description` VARCHAR(150) NOT NULL,
  `amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `tax_amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `line_total` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_invoiceline_admin` (`admin_id`),
  INDEX `idx_invoiceline_sync` (`sync_status`),
  INDEX `idx_invoiceline_uuid` (`uuid`),
  INDEX `idx_invoiceline_invoice` (`invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `customer_ledger` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `transaction_type` ENUM('invoice', 'payment', 'credit_note', 'adjustment') NOT NULL,
  
  `reference_id` BIGINT UNSIGNED DEFAULT NULL, -- links to invoice.id or payment_transactions.id
  
  `debit_amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `credit_amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `running_balance` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  `description` VARCHAR(255) DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_cl_admin` (`admin_id`),
  INDEX `idx_cl_sync` (`sync_status`),
  INDEX `idx_cl_uuid` (`uuid`),
  INDEX `idx_cl_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 011_hr_schema.sql
-- Establishes Employees, Attendance, and Payroll tables

CREATE TABLE IF NOT EXISTS `employees` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(150) UNIQUE DEFAULT NULL,
  `phone` VARCHAR(50) DEFAULT NULL,
  `dob` DATE DEFAULT NULL,
  `id_passport_number` VARCHAR(100) DEFAULT NULL,
  `visa_status` VARCHAR(50) DEFAULT NULL,
  `photo_url` VARCHAR(255) DEFAULT NULL,
  
  `role_id` BIGINT UNSIGNED NOT NULL, -- references roles.id
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `base_salary` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  `status` ENUM('active', 'on_leave', 'terminated') DEFAULT 'active',
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_emp_admin` (`admin_id`),
  INDEX `idx_emp_sync` (`sync_status`),
  INDEX `idx_emp_uuid` (`uuid`),
  INDEX `idx_emp_role` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attendance` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `employee_id` BIGINT UNSIGNED NOT NULL,
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `clock_in_time` DATETIME NOT NULL,
  `clock_out_time` DATETIME DEFAULT NULL,
  
  `clock_in_photo_url` VARCHAR(255) DEFAULT NULL,
  `clock_out_photo_url` VARCHAR(255) DEFAULT NULL,
  `latitude` DECIMAL(10, 8) DEFAULT NULL,
  `longitude` DECIMAL(11, 8) DEFAULT NULL,
  
  `status` ENUM('present', 'absent', 'late', 'half_day') DEFAULT 'present',
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_att_admin` (`admin_id`),
  INDEX `idx_att_sync` (`sync_status`),
  INDEX `idx_att_uuid` (`uuid`),
  INDEX `idx_att_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `payroll_records` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `employee_id` BIGINT UNSIGNED NOT NULL,
  
  `period_start` DATE NOT NULL,
  `period_end` DATE NOT NULL,
  
  `base_salary` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `allowances` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `deductions` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `net_pay` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  
  `status` ENUM('draft', 'approved', 'paid') DEFAULT 'draft',
  
  `payment_date` DATE DEFAULT NULL,
  `payment_reference` VARCHAR(100) DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_pr_admin` (`admin_id`),
  INDEX `idx_pr_sync` (`sync_status`),
  INDEX `idx_pr_uuid` (`uuid`),
  INDEX `idx_pr_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 012_expenses_leaves_schema.sql
-- Establishes Expenses, Leaves, and Salary Advances tables

CREATE TABLE IF NOT EXISTS `leaves` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `employee_id` BIGINT UNSIGNED NOT NULL,
  
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `leave_type` ENUM('annual', 'sick', 'unpaid') DEFAULT 'annual',
  
  `status` ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  `reject_reason` VARCHAR(255) DEFAULT NULL,
  
  `approved_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_leave_admin` (`admin_id`),
  INDEX `idx_leave_sync` (`sync_status`),
  INDEX `idx_leave_uuid` (`uuid`),
  INDEX `idx_leave_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `salary_advances` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `employee_id` BIGINT UNSIGNED NOT NULL,
  
  `amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `status` ENUM('pending', 'approved', 'disbursed', 'rejected') DEFAULT 'pending',
  `reject_reason` VARCHAR(255) DEFAULT NULL,
  
  `approved_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_adv_admin` (`admin_id`),
  INDEX `idx_adv_sync` (`sync_status`),
  INDEX `idx_adv_uuid` (`uuid`),
  INDEX `idx_adv_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `expenses` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `branch_id` BIGINT UNSIGNED DEFAULT NULL,
  `category` VARCHAR(100) NOT NULL,
  
  `amount` DECIMAL(18,2) NOT NULL DEFAULT '0.00',
  `description` VARCHAR(255) DEFAULT NULL,
  `expense_date` DATE NOT NULL,
  
  `recorded_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `idx_exp_admin` (`admin_id`),
  INDEX `idx_exp_sync` (`sync_status`),
  INDEX `idx_exp_uuid` (`uuid`),
  INDEX `idx_exp_branch` (`branch_id`),
  INDEX `idx_exp_date` (`expense_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 013_sync_schema.sql
-- Establishes Sync Engine tables

CREATE TABLE IF NOT EXISTS `sync_outbox` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `terminal_id` VARCHAR(50) DEFAULT 'local',
  
  `entity_type` VARCHAR(100) NOT NULL,
  `entity_id` BIGINT UNSIGNED DEFAULT NULL,
  `operation` ENUM('insert', 'update', 'delete') NOT NULL,
  `payload` JSON NOT NULL,
  
  `status` ENUM('pending', 'processing', 'synced', 'failed', 'dead_letter') DEFAULT 'pending',
  `attempts` TINYINT DEFAULT 0,
  `last_error` TEXT DEFAULT NULL,
  
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `synced_at` DATETIME NULL,
  `next_retry_at` DATETIME NULL,

  INDEX `idx_outbox_admin` (`admin_id`),
  INDEX `idx_outbox_status` (`status`, `next_retry_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sync_inbox` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `source_terminal_id` VARCHAR(50) NOT NULL,
  
  `entity_type` VARCHAR(100) NOT NULL,
  `row_uuid` CHAR(36) NOT NULL,
  `operation` ENUM('insert', 'update', 'delete') NOT NULL,
  `payload` JSON NOT NULL,
  
  `status` ENUM('pending', 'applied', 'conflict', 'failed') DEFAULT 'pending',
  `error_details` TEXT DEFAULT NULL,
  
  `received_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `applied_at` DATETIME NULL,

  INDEX `idx_inbox_admin` (`admin_id`),
  INDEX `idx_inbox_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sync_conflicts` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  
  `entity_type` VARCHAR(100) NOT NULL,
  `row_uuid` CHAR(36) NOT NULL,
  
  `local_state` JSON NOT NULL,
  `remote_state` JSON NOT NULL,
  
  `resolution_strategy` ENUM('server_wins', 'client_wins', 'manual') NOT NULL,
  `resolved_at` DATETIME NULL,
  `resolved_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_conflict_admin` (`admin_id`),
  INDEX `idx_conflict_unresolved` (`resolved_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Migration 014_notifications_schema.sql
-- Establishes Notifications and FCM Tokens tables

CREATE TABLE IF NOT EXISTS `notifications` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) NOT NULL,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `row_uuid` CHAR(36) NOT NULL UNIQUE,
  
  `user_id` BIGINT UNSIGNED NOT NULL, -- references users.id
  `title` VARCHAR(255) NOT NULL,
  `body` TEXT NOT NULL,
  `type` VARCHAR(50) DEFAULT 'system', -- 'order', 'delivery', 'system', 'alert'
  `related_entity_type` VARCHAR(100) DEFAULT NULL,
  `related_entity_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `is_read` BOOLEAN NOT NULL DEFAULT 0,
  
  -- Sync tracking
  `sync_status` ENUM('pending', 'synced', 'failed', 'conflict') DEFAULT 'pending',
  `sync_attempts` TINYINT DEFAULT 0,
  `last_sync_at` DATETIME NULL,
  `origin` ENUM('local', 'cloud') DEFAULT 'local',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,

  INDEX `idx_notif_admin` (`admin_id`),
  INDEX `idx_notif_sync` (`sync_status`),
  INDEX `idx_notif_uuid` (`uuid`),
  INDEX `idx_notif_user` (`user_id`),
  INDEX `idx_notif_read` (`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fcm_tokens` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `admin_id` BIGINT UNSIGNED NOT NULL,
  
  `user_id` BIGINT UNSIGNED NOT NULL,
  `device_id` VARCHAR(100) NOT NULL,
  `fcm_token` VARCHAR(255) NOT NULL,
  
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY `uk_device` (`admin_id`, `user_id`, `device_id`),
  INDEX `idx_fcm_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- LaundryPro UAE baseline schema (P1 + P2 + P3)
-- Generated for greenfield installs v1.2.1
-- Incremental migrations archived under migrations/archive/
-- Do not edit by hand; regenerate from archive when schema changes.
-- ===== 001_initial_schema.sql =====
CREATE TABLE IF NOT EXISTS schema_migrations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  migration VARCHAR(255) NOT NULL UNIQUE,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL UNIQUE,
  permissions JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  role_id INT UNSIGNED NOT NULL,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS settings (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(150) NOT NULL,
  setting_value JSON NOT NULL,
  scope ENUM('system', 'business', 'branch', 'terminal') NOT NULL DEFAULT 'business',
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_settings_key_scope (setting_key, scope)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  action VARCHAR(255) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_id INT UNSIGNED NULL,
  payload JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_entity (entity_type, entity_id, created_at),
  INDEX idx_audit_user (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS license (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  license_key VARCHAR(255) NOT NULL,
  umac VARCHAR(255) NULL,
  physical_address_hash VARCHAR(255) NULL,
  expires_at TIMESTAMP NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  activated_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 002_seed_roles.sql =====
INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000001', 'administrator', JSON_ARRAY('*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'administrator');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000002', 'cashier', JSON_ARRAY('sales.create', 'sales.read', 'customers.read'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'cashier');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'business.name', JSON_QUOTE('LaundryPro UAE'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'business.name' AND scope = 'business');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'locale.default', JSON_QUOTE('en'), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'locale.default' AND scope = 'system');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'currency.default', JSON_OBJECT('major', 'AED', 'minor', 'Fils', 'digits', 2), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'currency.default' AND scope = 'system');

-- Default admin user: username=admin password=admin123 (change immediately in production)
INSERT INTO users (uuid, role_id, username, password_hash, full_name, email, is_active)
SELECT
  '00000000-0000-4000-8000-000000000010',
  r.id,
  'admin',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'System Administrator',
  'admin@laundrypro.local',
  1
FROM roles r
WHERE r.name = 'administrator'
  AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- ===== 003_business_branch_terminal.sql =====
CREATE TABLE IF NOT EXISTS business (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL UNIQUE,
  legal_name VARCHAR(255) NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  address_line1 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  emirate VARCHAR(100) NULL,
  country VARCHAR(100) NOT NULL DEFAULT 'AE',
  physical_address_hash VARCHAR(64) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS branches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_id INT UNSIGNED NOT NULL,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_branch_code (business_id, code),
  CONSTRAINT fk_branches_business FOREIGN KEY (business_id) REFERENCES business(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS terminals (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  branch_id INT UNSIGNED NOT NULL,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_terminal_code (branch_id, code),
  CONSTRAINT fk_terminals_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO business (uuid, admin_id, legal_name, display_name, city, emirate, country)
SELECT '00000000-0000-4000-8000-000000000100', 1, 'LaundryPro UAE', 'LaundryPro UAE', 'Dubai', 'Dubai', 'AE'
WHERE NOT EXISTS (SELECT 1 FROM business WHERE admin_id = 1);

INSERT INTO branches (uuid, business_id, code, name)
SELECT '00000000-0000-4000-8000-000000000101', b.id, 'MAIN', 'Main Branch'
FROM business b WHERE b.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM branches WHERE code = 'MAIN' AND business_id = b.id);

INSERT INTO terminals (uuid, branch_id, code, name)
SELECT '00000000-0000-4000-8000-000000000102', br.id, 'T01', 'Counter 1'
FROM branches br
INNER JOIN business b ON b.id = br.business_id AND b.admin_id = 1
WHERE br.code = 'MAIN'
  AND NOT EXISTS (SELECT 1 FROM terminals WHERE code = 'T01' AND branch_id = br.id);

-- ===== 004_customers_vendors.sql =====
CREATE TABLE IF NOT EXISTS customers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  customer_code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  address_line1 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  emirate VARCHAR(100) NULL,
  customer_type ENUM('personal', 'professional', 'walk_in') NOT NULL DEFAULT 'personal',
  credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0,
  outstanding_balance DECIMAL(18,2) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_customer_local (admin_id, local_id),
  INDEX idx_customer_phone (phone),
  INDEX idx_customer_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS vendors (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  vendor_code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(150) NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  address_line1 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  notes TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_vendor_local (admin_id, local_id),
  INDEX idx_vendor_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 005_catalog_services_products.sql =====
CREATE TABLE IF NOT EXISTS categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  parent_id INT UNSIGNED NULL,
  type ENUM('service', 'product') NOT NULL,
  name VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_category_parent (parent_id),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS services (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  parent_id INT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  base_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_group TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_service_local (admin_id, local_id),
  INDEX idx_service_parent (parent_id),
  CONSTRAINT fk_services_parent FOREIGN KEY (parent_id) REFERENCES services(id),
  CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  parent_id INT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  barcode VARCHAR(100) NULL,
  base_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  stock_quantity DECIMAL(18,3) NOT NULL DEFAULT 0,
  low_stock_threshold DECIMAL(18,3) NOT NULL DEFAULT 0,
  is_group TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_local (admin_id, local_id),
  INDEX idx_product_parent (parent_id),
  INDEX idx_product_barcode (barcode),
  CONSTRAINT fk_products_parent FOREIGN KEY (parent_id) REFERENCES products(id),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_product_map (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  service_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  default_qty DECIMAL(18,3) NOT NULL DEFAULT 1,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_service_product (service_id, product_id),
  CONSTRAINT fk_spm_service FOREIGN KEY (service_id) REFERENCES services(id),
  CONSTRAINT fk_spm_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 006_sales_payments.sql =====
CREATE TABLE IF NOT EXISTS sales_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  order_no VARCHAR(50) NOT NULL,
  customer_id INT UNSIGNED NULL,
  status ENUM('draft', 'confirmed', 'received', 'processing', 'ready', 'delivered', 'closed', 'cancelled') NOT NULL DEFAULT 'draft',
  payment_status ENUM('pending', 'partial', 'paid') NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
  discount DECIMAL(18,2) NOT NULL DEFAULT 0,
  tax DECIMAL(18,2) NOT NULL DEFAULT 0,
  grand_total DECIMAL(18,2) NOT NULL DEFAULT 0,
  amount_paid DECIMAL(18,2) NOT NULL DEFAULT 0,
  balance_due DECIMAL(18,2) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  confirmed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_order_local (admin_id, local_id),
  UNIQUE KEY uq_order_no (admin_id, order_no),
  INDEX idx_sales_customer (customer_id),
  CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_sales_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sales_order_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sales_order_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  item_type ENUM('service', 'product', 'group') NOT NULL,
  item_id INT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(18,3) NOT NULL DEFAULT 1,
  rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  discount DECIMAL(18,2) NOT NULL DEFAULT 0,
  amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  service_status ENUM('received', 'in_process', 'ready', 'delivered', 'cancelled') NOT NULL DEFAULT 'received',
  modifiers JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_order_line (sales_order_id, line_no),
  CONSTRAINT fk_lines_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payment_transactions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  sales_order_id INT UNSIGNED NOT NULL,
  payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  amount DECIMAL(18,2) NOT NULL,
  payment_method ENUM('cash', 'credit', 'debit', 'cheque', 'adjustment') NOT NULL DEFAULT 'cash',
  reference_number VARCHAR(100) NULL,
  received_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_payment_order (sales_order_id),
  CONSTRAINT fk_payment_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_payment_user FOREIGN KEY (received_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 007_inventory.sql =====
CREATE TABLE IF NOT EXISTS inventory_movements (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  product_id INT UNSIGNED NOT NULL,
  movement_type ENUM('receipt', 'issue', 'adjustment', 'sale_consumption') NOT NULL,
  quantity DECIMAL(18,3) NOT NULL,
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_inv_product (product_id),
  INDEX idx_inv_type (movement_type),
  INDEX idx_inv_owner (admin_id),
  CONSTRAINT fk_inv_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_inv_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventory_adjustments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  product_id INT UNSIGNED NOT NULL,
  quantity_before DECIMAL(18,3) NOT NULL,
  quantity_after DECIMAL(18,3) NOT NULL,
  reason VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_adj_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_adj_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'inventory.allow_negative_stock', JSON_QUOTE('false'), 'inventory'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'inventory.allow_negative_stock' AND scope = 'inventory');

-- ===== 008_hr_payroll.sql =====
CREATE TABLE IF NOT EXISTS employees (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_no VARCHAR(50) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) NULL,
  email VARCHAR(150) NULL,
  job_title VARCHAR(100) NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_no (admin_id, employee_no),
  INDEX idx_emp_owner (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS attendance (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  attendance_date DATE NOT NULL,
  status ENUM('present', 'absent', 'half_day', 'leave') NOT NULL DEFAULT 'present',
  check_in TIME NULL,
  check_out TIME NULL,
  notes VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_attendance_day (employee_id, attendance_date),
  CONSTRAINT fk_att_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_att_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_types (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_paid TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_requests (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  leave_type_id INT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  reason TEXT NULL,
  approved_by INT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_leave_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_leave_type FOREIGN KEY (leave_type_id) REFERENCES leave_types(id),
  CONSTRAINT fk_leave_approver FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_periods (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status ENUM('open', 'closed') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_payroll_period (admin_id, period_start, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_runs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  payroll_period_id INT UNSIGNED NOT NULL,
  run_no VARCHAR(50) NOT NULL,
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  status ENUM('draft', 'posted') NOT NULL DEFAULT 'posted',
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pr_period FOREIGN KEY (payroll_period_id) REFERENCES payroll_periods(id),
  CONSTRAINT fk_pr_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payroll_run_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NOT NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0,
  advance_deduction DECIMAL(18,2) NOT NULL DEFAULT 0,
  net_pay DECIMAL(18,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_pl_run FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
  CONSTRAINT fk_pl_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS salary_advances (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  balance_remaining DECIMAL(18,2) NOT NULL,
  status ENUM('open', 'recovered', 'cancelled') NOT NULL DEFAULT 'open',
  notes VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sa_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_sa_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO leave_types (uuid, admin_id, name, is_paid)
SELECT UUID(), 1, 'Annual Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Annual Leave' AND admin_id = 1);

INSERT INTO leave_types (uuid, admin_id, name, is_paid)
SELECT UUID(), 1, 'Sick Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Sick Leave' AND admin_id = 1);

-- ===== 009_expenses.sql =====
CREATE TABLE IF NOT EXISTS expense_categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_exp_cat (admin_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  category_id INT UNSIGNED NOT NULL,
  expense_date DATE NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  description VARCHAR(255) NULL,
  status ENUM('draft', 'pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  created_by INT UNSIGNED NULL,
  approved_by INT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_exp_category FOREIGN KEY (category_id) REFERENCES expense_categories(id),
  CONSTRAINT fk_exp_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_exp_approver FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expense_attachments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  expense_id INT UNSIGNED NOT NULL,
  file_asset_id INT UNSIGNED NULL,
  file_path VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ea_expense FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO expense_categories (uuid, admin_id, name)
SELECT UUID(), 1, 'Utilities'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Utilities' AND admin_id = 1);

INSERT INTO expense_categories (uuid, admin_id, name)
SELECT UUID(), 1, 'Supplies'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Supplies' AND admin_id = 1);

-- ===== 010_sync_outbox.sql =====
CREATE TABLE IF NOT EXISTS sync_state (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL UNIQUE,
  last_push_at TIMESTAMP NULL,
  last_pull_at TIMESTAMP NULL,
  cloud_api_url VARCHAR(500) NULL,
  cloud_token_hash VARCHAR(64) NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_outbox (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation ENUM('create', 'update', 'delete') NOT NULL,
  payload JSON NOT NULL,
  synced_at TIMESTAMP NULL,
  sync_attempts INT UNSIGNED NOT NULL DEFAULT 0,
  last_error VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_outbox_pending (admin_id, synced_at, created_at),
  INDEX idx_outbox_entity (entity_type, entity_local_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO sync_state (admin_id, is_enabled)
SELECT 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sync_state WHERE admin_id = 1);

-- ===== 011_documents_files.sql =====
CREATE TABLE IF NOT EXISTS file_assets (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INT UNSIGNED NULL,
  file_path VARCHAR(500) NOT NULL,
  checksum_sha256 CHAR(64) NULL,
  mime_type VARCHAR(100) NULL,
  size_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_file_entity (entity_type, entity_id),
  INDEX idx_file_owner (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS document_templates (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  template_key VARCHAR(50) NOT NULL,
  format ENUM('thermal', 'a4') NOT NULL,
  schema_json JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_template (admin_id, template_key, format)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO document_templates (uuid, admin_id, template_key, format, schema_json)
SELECT '00000000-0000-4000-8000-000000000101', 1, 'receipt', 'thermal',
  JSON_OBJECT('version', 1, 'width', 48, 'fields', JSON_ARRAY('order_no', 'lines', 'totals', 'payments'))
WHERE NOT EXISTS (SELECT 1 FROM document_templates WHERE template_key = 'receipt' AND format = 'thermal');

INSERT INTO document_templates (uuid, admin_id, template_key, format, schema_json)
SELECT '00000000-0000-4000-8000-000000000102', 1, 'receipt', 'a4',
  JSON_OBJECT('version', 1, 'page', 'A4', 'fields', JSON_ARRAY('order_no', 'lines', 'totals', 'payments'))
WHERE NOT EXISTS (SELECT 1 FROM document_templates WHERE template_key = 'receipt' AND format = 'a4');

-- ===== 012_license_umac_runtime.sql =====
CREATE TABLE IF NOT EXISTS umac_policy (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  policy_key VARCHAR(50) NOT NULL,
  policy_value JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_umac_policy (admin_id, policy_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS hardware_identity (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  umac_hash CHAR(64) NOT NULL,
  machine_fingerprint TEXT NOT NULL,
  first_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_hw_umac (admin_id, umac_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO umac_policy (uuid, admin_id, policy_key, policy_value)
SELECT '00000000-0000-4000-8000-000000000201', 1, 'bind_to_hardware', JSON_OBJECT('enabled', true, 'max_devices', 1)
WHERE NOT EXISTS (SELECT 1 FROM umac_policy WHERE policy_key = 'bind_to_hardware');

-- ===== 013_modifiers.sql =====
CREATE TABLE IF NOT EXISTS service_modifiers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  service_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  extra_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_svc_mod_service (service_id),
  CONSTRAINT fk_svc_mod_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS product_modifiers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  product_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  extra_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_prod_mod_product (product_id),
  CONSTRAINT fk_prod_mod_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sales_order_line_snapshots (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sales_order_line_id INT UNSIGNED NOT NULL,
  snapshot_type ENUM('bundle', 'modifiers') NOT NULL,
  snapshot_json JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_snapshot_line (sales_order_line_id),
  CONSTRAINT fk_snapshot_line FOREIGN KEY (sales_order_line_id) REFERENCES sales_order_lines(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 014_sync_cloud_token.sql =====
ALTER TABLE sync_state ADD COLUMN cloud_token VARCHAR(255) NULL AFTER cloud_token_hash;

-- ===== 015_production_workflow.sql =====
CREATE TABLE IF NOT EXISTS order_status_history (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sales_order_id INT UNSIGNED NOT NULL,
  from_status VARCHAR(50) NULL,
  to_status VARCHAR(50) NOT NULL,
  changed_by INT UNSIGNED NULL,
  notes VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_osh_order (sales_order_id),
  CONSTRAINT fk_osh_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_osh_user FOREIGN KEY (changed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE sales_orders
  ADD COLUMN expected_ready_date DATE NULL,
  ADD COLUMN promised_date DATE NULL,
  ADD COLUMN delivery_address TEXT NULL,
  ADD COLUMN delivery_notes TEXT NULL;

-- ===== 016_delivery_challans.sql =====
CREATE TABLE IF NOT EXISTS delivery_tasks (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  sales_order_id INT UNSIGNED NOT NULL,
  task_type ENUM('delivery', 'collection') NOT NULL DEFAULT 'delivery',
  scheduled_at DATETIME NULL,
  address TEXT NULL,
  notes TEXT NULL,
  assigned_employee_id INT UNSIGNED NULL,
  status ENUM('scheduled', 'in_progress', 'completed', 'failed', 'cancelled') NOT NULL DEFAULT 'scheduled',
  completed_at TIMESTAMP NULL,
  failed_reason VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_dt_order (sales_order_id),
  CONSTRAINT fk_dt_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_dt_employee FOREIGN KEY (assigned_employee_id) REFERENCES employees(id),
  CONSTRAINT fk_dt_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS challans (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  challan_no VARCHAR(50) NOT NULL,
  challan_type ENUM('delivery', 'collection', 'stock_transfer', 'vendor_return', 'service_receipt') NOT NULL,
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  status ENUM('draft', 'issued', 'cancelled') NOT NULL DEFAULT 'issued',
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_challan_no (admin_id, challan_type, challan_no),
  CONSTRAINT fk_ch_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS challan_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  challan_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(18,3) NOT NULL DEFAULT 1,
  unit VARCHAR(20) NULL,
  CONSTRAINT fk_cl_challan FOREIGN KEY (challan_id) REFERENCES challans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS challan_sequences (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  challan_type VARCHAR(50) NOT NULL,
  last_number INT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY uk_ch_seq (admin_id, challan_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 017_purchasing.sql =====
CREATE TABLE IF NOT EXISTS purchase_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  po_no VARCHAR(50) NOT NULL,
  vendor_id INT UNSIGNED NOT NULL,
  status ENUM('draft', 'ordered', 'partial', 'received', 'cancelled') NOT NULL DEFAULT 'draft',
  order_date DATE NOT NULL,
  expected_date DATE NULL,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_po_no (admin_id, po_no),
  CONSTRAINT fk_po_vendor FOREIGN KEY (vendor_id) REFERENCES vendors(id),
  CONSTRAINT fk_po_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchase_order_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity_ordered DECIMAL(18,3) NOT NULL,
  quantity_received DECIMAL(18,3) NOT NULL DEFAULT 0,
  unit_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_pol_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_pol_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS goods_receipts (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  purchase_order_id INT UNSIGNED NOT NULL,
  receipt_no VARCHAR(50) NOT NULL,
  received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  UNIQUE KEY uk_gr_no (admin_id, receipt_no),
  CONSTRAINT fk_gr_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  CONSTRAINT fk_gr_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS goods_receipt_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  goods_receipt_id INT UNSIGNED NOT NULL,
  purchase_order_line_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity DECIMAL(18,3) NOT NULL,
  CONSTRAINT fk_grl_gr FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipts(id) ON DELETE CASCADE,
  CONSTRAINT fk_grl_pol FOREIGN KEY (purchase_order_line_id) REFERENCES purchase_order_lines(id),
  CONSTRAINT fk_grl_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventory_locations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_loc_name (admin_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO inventory_locations (uuid, admin_id, name, is_default)
SELECT UUID(), 1, 'Main Store', 1
WHERE NOT EXISTS (SELECT 1 FROM inventory_locations WHERE admin_id = 1 AND is_default = 1);

-- ===== 018_notifications.sql =====
CREATE TABLE IF NOT EXISTS notifications (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  notification_type VARCHAR(50) NOT NULL,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  severity ENUM('info', 'warning', 'error') NOT NULL DEFAULT 'info',
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notif_owner (admin_id),
  INDEX idx_notif_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification_reads (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  notification_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_notif_user (notification_id, user_id),
  CONSTRAINT fk_nr_notif FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
  CONSTRAINT fk_nr_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 019_sales_status_enum.sql =====
ALTER TABLE sales_orders
  MODIFY COLUMN status ENUM(
    'draft', 'confirmed', 'received', 'sorting', 'processing', 'quality_check',
    'packed', 'ready', 'ready_for_collection', 'out_for_delivery', 'delivered',
    'on_hold', 'rework_required', 'closed', 'cancelled'
  ) NOT NULL DEFAULT 'draft';

-- ===== 020_branch_terminal_context.sql =====
ALTER TABLE sales_orders
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id,
  ADD COLUMN terminal_id INT UNSIGNED NULL AFTER branch_id;

ALTER TABLE inventory_movements
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id;

ALTER TABLE employees
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id;

ALTER TABLE expenses
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER admin_id;

UPDATE sales_orders SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;
UPDATE employees SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;

-- ===== 021_terminal_sessions.sql =====
CREATE TABLE IF NOT EXISTS terminal_sessions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  terminal_id INT UNSIGNED NOT NULL,
  session_token VARCHAR(128) NOT NULL UNIQUE,
  device_fingerprint VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_seen_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ts_terminal (terminal_id),
  CONSTRAINT fk_ts_terminal FOREIGN KEY (terminal_id) REFERENCES terminals(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 022_sync_entity_registry.sql =====
CREATE TABLE IF NOT EXISTS sync_entity_types (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entity_type VARCHAR(50) NOT NULL UNIQUE,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO sync_entity_types (entity_type) VALUES
  ('customer'), ('vendor'), ('sales_order'), ('employee'), ('expense'),
  ('challan'), ('purchase_order'), ('notification'), ('payroll_run');

-- ===== 023_ksa_profile.sql =====
CREATE TABLE IF NOT EXISTS country_profiles (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code CHAR(2) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  currency_symbol VARCHAR(10) NOT NULL,
  timezone VARCHAR(64) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO country_profiles (code, name, currency_code, currency_symbol, timezone) VALUES
  ('AE', 'United Arab Emirates', 'AED', 'AED', 'Asia/Dubai'),
  ('SA', 'Saudi Arabia', 'SAR', 'SAR', 'Asia/Riyadh');

-- ===== 024_notification_channels.sql =====
CREATE TABLE IF NOT EXISTS notification_channels (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  channel_type ENUM('sms', 'whatsapp', 'email') NOT NULL,
  provider VARCHAR(50) NOT NULL DEFAULT 'stub',
  config_json JSON NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification_messages (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  channel_id INT UNSIGNED NOT NULL,
  recipient VARCHAR(100) NOT NULL,
  template_key VARCHAR(50) NOT NULL,
  body TEXT NOT NULL,
  status ENUM('queued', 'sent', 'failed') NOT NULL DEFAULT 'queued',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_nm_channel FOREIGN KEY (channel_id) REFERENCES notification_channels(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 025_accounting_exports.sql =====
CREATE TABLE IF NOT EXISTS accounting_export_batches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  adapter VARCHAR(50) NOT NULL DEFAULT 'csv',
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status ENUM('draft', 'exported', 'failed') NOT NULL DEFAULT 'draft',
  file_path VARCHAR(500) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS accounting_export_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  batch_id INT UNSIGNED NOT NULL,
  line_no INT UNSIGNED NOT NULL,
  account_code VARCHAR(50) NOT NULL,
  description VARCHAR(255) NOT NULL,
  debit DECIMAL(18,2) NOT NULL DEFAULT 0,
  credit DECIMAL(18,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_ael_batch FOREIGN KEY (batch_id) REFERENCES accounting_export_batches(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 026_analytics_snapshots.sql =====
CREATE TABLE IF NOT EXISTS analytics_daily_snapshots (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  branch_id INT UNSIGNED NULL,
  snapshot_date DATE NOT NULL,
  metric_key VARCHAR(50) NOT NULL,
  metric_value DECIMAL(18,4) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_analytics_day (admin_id, branch_id, snapshot_date, metric_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 027_storefront.sql =====
CREATE TABLE IF NOT EXISTS storefront_tokens (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  token_hash VARCHAR(128) NOT NULL UNIQUE,
  label VARCHAR(100) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS storefront_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  customer_name VARCHAR(150) NOT NULL,
  customer_phone VARCHAR(50) NOT NULL,
  notes TEXT NULL,
  status ENUM('pending', 'converted', 'cancelled') NOT NULL DEFAULT 'pending',
  sales_order_id INT UNSIGNED NULL,
  payload_json JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 028_customer_portal.sql =====
CREATE TABLE IF NOT EXISTS customer_portal_tokens (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  admin_id INT UNSIGNED NOT NULL DEFAULT 1,
  sales_order_id INT UNSIGNED NOT NULL,
  access_token VARCHAR(128) NOT NULL UNIQUE,
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cpt_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 029_account_lockout.sql =====
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS failed_attempts INT UNSIGNED NOT NULL DEFAULT 0 AFTER is_active,
  ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP NULL DEFAULT NULL AFTER failed_attempts;

-- ===== 030_seed_roles.sql =====
INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000003', 'manager', JSON_ARRAY('sales.*', 'inventory.*', 'customers.*', 'reports.sales'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'manager');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000004', 'storekeeper', JSON_ARRAY('inventory.*', 'purchase.receive'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'storekeeper');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000005', 'hr', JSON_ARRAY('hr.*', 'reports.hr'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'hr');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000006', 'auditor', JSON_ARRAY('reports.*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'auditor');

-- ===== 031_performance_indexes.sql =====
ALTER TABLE customers
  ADD INDEX IF NOT EXISTS idx_customer_code (customer_code);

ALTER TABLE vendors
  ADD INDEX IF NOT EXISTS idx_vendor_code (vendor_code);

ALTER TABLE services
  ADD INDEX IF NOT EXISTS idx_svc_parent_active (parent_id, is_active);

ALTER TABLE products
  ADD INDEX IF NOT EXISTS idx_prod_parent_active_bc (parent_id, is_active, barcode);

ALTER TABLE sales_orders
  ADD INDEX IF NOT EXISTS idx_sales_cust_created (customer_id, created_at),
  ADD INDEX IF NOT EXISTS idx_sales_status_promised (status, promised_date);

ALTER TABLE inventory_movements
  ADD INDEX IF NOT EXISTS idx_inv_prod_created (product_id, created_at);

ALTER TABLE notifications
  ADD INDEX IF NOT EXISTS idx_notif_created (created_at);


-- Laundry Pro Desktop � Advanced Module Additive Schema
-- Sprint 2: Data Model Extension
CREATE TABLE IF NOT EXISTS advanced_cycle_presets (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id INT UNSIGNED NOT NULL,
    cycle_name VARCHAR(150) NOT NULL,
    temperature_c DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    duration_minutes INT NOT NULL DEFAULT 0,
    detergent_ratio DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    spin_speed_rpm INT NOT NULL DEFAULT 0,
    chemical_dosage_map JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cycle_preset_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS equipment (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    asset_tag VARCHAR(100) NOT NULL UNIQUE,
    equipment_type VARCHAR(100) NOT NULL,
    last_calibration_date DATE NULL,
    next_calibration_due DATE NULL,
    out_of_service TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS advanced_cycle_runs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    sales_order_line_id INT UNSIGNED NOT NULL,
    preset_id INT UNSIGNED NOT NULL,
    equipment_id INT UNSIGNED NOT NULL,
    operator_employee_id INT UNSIGNED NOT NULL,
    status ENUM('running', 'exception', 'completed') NOT NULL DEFAULT 'running',
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    CONSTRAINT fk_cycle_run_sol FOREIGN KEY (sales_order_line_id) REFERENCES sales_order_lines(id),
    CONSTRAINT fk_cycle_run_preset FOREIGN KEY (preset_id) REFERENCES advanced_cycle_presets(id),
    CONSTRAINT fk_cycle_run_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(id),
    CONSTRAINT fk_cycle_run_operator FOREIGN KEY (operator_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS process_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    metric_type ENUM('ph', 'temperature') NOT NULL,
    reading_value DECIMAL(18,2) NOT NULL,
    threshold_min DECIMAL(18,2) NOT NULL,
    threshold_max DECIMAL(18,2) NOT NULL,
    pass_fail TINYINT(1) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_process_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sterilization_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    autoclave_program VARCHAR(150) NOT NULL,
    pressure_kpa DECIMAL(18,2) NOT NULL,
    temperature_c DECIMAL(18,2) NOT NULL,
    duration_minutes INT NOT NULL,
    validation_result ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sterilization_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS chemical_usage_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL,
    cycle_run_id INT UNSIGNED NOT NULL,
    lot_number VARCHAR(100) NOT NULL,
    expiry_date DATE NOT NULL,
    quantity_used DECIMAL(18,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chemical_log_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_chemical_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS batch_lots (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    lot_number VARCHAR(100) NOT NULL UNIQUE,
    expiry_date DATE NOT NULL,
    origin_sales_order_id INT UNSIGNED NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_lot_order FOREIGN KEY (origin_sales_order_id) REFERENCES sales_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS batch_scan_events (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_lot_id INT UNSIGNED NOT NULL,
    scan_type ENUM('in', 'out') NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    scanned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_scan_lot FOREIGN KEY (batch_lot_id) REFERENCES batch_lots(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS calibration_records (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipment_id INT UNSIGNED NOT NULL,
    calibrated_at DATE NOT NULL,
    performed_by VARCHAR(150) NOT NULL,
    certificate_ref VARCHAR(150) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_calibration_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS operator_certifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    certification_name VARCHAR(150) NOT NULL,
    issued_at DATE NOT NULL,
    expires_at DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_operator_cert_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS electronic_signatures (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    signature_hash CHAR(64) NOT NULL,
    meaning VARCHAR(150) NOT NULL,
    signed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_esign_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id),
    CONSTRAINT fk_esign_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS controlled_garments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    garment_tag VARCHAR(100) NOT NULL UNIQUE,
    iso_class VARCHAR(50) NOT NULL,
    wash_cycle_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cg_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS gowning_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    controlled_garment_id INT UNSIGNED NOT NULL,
    employee_id INT UNSIGNED NOT NULL,
    event_type ENUM('gowning', 'degowning') NOT NULL,
    event_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gl_garment FOREIGN KEY (controlled_garment_id) REFERENCES controlled_garments(id),
    CONSTRAINT fk_gl_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS cloud_agent (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    cloud_agent_id CHAR(36) NOT NULL UNIQUE,
    agent_secret_hash VARCHAR(255) NOT NULL,
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_handshake_at TIMESTAMP NULL,
    CONSTRAINT fk_cloud_agent_business FOREIGN KEY (business_id) REFERENCES business(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS loyalty_ledger (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    points_delta INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ll_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE sync_outbox ADD COLUMN status ENUM('pending', 'synced', 'failed') NOT NULL DEFAULT 'pending', ADD COLUMN next_retry_at TIMESTAMP NULL DEFAULT NULL;
-- ===== 003_audit_fixes.sql =====

-- AUD-001: Triggers for electronic_signatures to enforce append-only immutability
DELIMITER //
CREATE TRIGGER trg_electronic_signatures_before_update
BEFORE UPDATE ON electronic_signatures
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Electronic signatures are immutable and cannot be updated (21 CFR Part 11)';
END//

CREATE TRIGGER trg_electronic_signatures_before_delete
BEFORE DELETE ON electronic_signatures
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Electronic signatures are immutable and cannot be deleted (21 CFR Part 11)';
END//
DELIMITER ;

-- AUD-004: Composite index on advanced_cycle_runs
CREATE INDEX idx_adv_cycle_status_started ON advanced_cycle_runs (status, started_at);

-- PRF-001: Missing composite indexes
CREATE INDEX idx_sales_orders_owner_status ON sales_orders (admin_id, status);
CREATE INDEX idx_customers_phone ON customers (phone);

-- SEC-008: Add previous_hash column to audit_logs
ALTER TABLE audit_logs ADD COLUMN previous_hash CHAR(64) NULL AFTER payload;

-- PHP-016: Create idempotency_keys table
CREATE TABLE IF NOT EXISTS idempotency_keys (
  id_key VARCHAR(100) PRIMARY KEY,
  response_code INT NOT NULL,
  response_body JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  INDEX idx_idemp_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- LaundryPro UAE Central Cloud Schema (Multi-Tenant & Super-Admin)
-- Compatible with MariaDB / MySQL 5.7+ / 8.0+

CREATE TABLE IF NOT EXISTS cloud_super_admins (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(191) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(128) NOT NULL DEFAULT 'Super Administrator',
  role VARCHAR(32) NOT NULL DEFAULT 'super_admin',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS businesses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  license_key VARCHAR(255) NULL,
  cloud_token VARCHAR(64) NOT NULL UNIQUE,
  trade_license_no VARCHAR(100) NULL,
  contact_email VARCHAR(191) NULL,
  contact_phone VARCHAR(50) NULL,
  country_code VARCHAR(10) NOT NULL DEFAULT 'AE',
  city VARCHAR(100) NOT NULL DEFAULT 'Dubai',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('active', 'suspended', 'trial', 'expired') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation VARCHAR(20) NOT NULL,
  payload JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_sync_entity (admin_id, entity_type, entity_local_id),
  INDEX idx_sync_owner (admin_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_licenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  license_key VARCHAR(128) NOT NULL UNIQUE,
  umac_fingerprint VARCHAR(128) NULL,
  plan_type VARCHAR(50) NOT NULL DEFAULT 'standard',
  max_invoices INT NOT NULL DEFAULT 999999,
  max_customers INT NOT NULL DEFAULT 999999,
  status ENUM('active', 'revoked', 'expired') NOT NULL DEFAULT 'active',
  expires_at DATETIME NULL,
  signature TEXT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tenant_lic (tenant_id),
  INDEX idx_lic_key (license_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_telemetry (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  workstation_ip VARCHAR(64) NULL,
  app_version VARCHAR(32) NULL,
  os_version VARCHAR(64) NULL,
  umac VARCHAR(128) NULL,
  status_payload JSON NULL,
  last_ping_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_telemetry_tenant (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  super_admin_id INT UNSIGNED NULL,
  tenant_id INT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  details TEXT NULL,
  ip_address VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS businesses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  license_key VARCHAR(255) NULL,
  cloud_token VARCHAR(64) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation VARCHAR(20) NOT NULL,
  payload JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_sync_entity (admin_id, entity_type, entity_local_id),
  INDEX idx_sync_owner (admin_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
