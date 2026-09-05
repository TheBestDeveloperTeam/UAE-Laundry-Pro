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
  business_owner_id INT UNSIGNED NOT NULL UNIQUE,
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

INSERT INTO business (uuid, business_owner_id, legal_name, display_name, city, emirate, country)
SELECT '00000000-0000-4000-8000-000000000100', 1, 'LaundryPro UAE', 'LaundryPro UAE', 'Dubai', 'Dubai', 'AE'
WHERE NOT EXISTS (SELECT 1 FROM business WHERE business_owner_id = 1);

INSERT INTO branches (uuid, business_id, code, name)
SELECT '00000000-0000-4000-8000-000000000101', b.id, 'MAIN', 'Main Branch'
FROM business b WHERE b.business_owner_id = 1
  AND NOT EXISTS (SELECT 1 FROM branches WHERE code = 'MAIN' AND business_id = b.id);

INSERT INTO terminals (uuid, branch_id, code, name)
SELECT '00000000-0000-4000-8000-000000000102', br.id, 'T01', 'Counter 1'
FROM branches br
INNER JOIN business b ON b.id = br.business_id AND b.business_owner_id = 1
WHERE br.code = 'MAIN'
  AND NOT EXISTS (SELECT 1 FROM terminals WHERE code = 'T01' AND branch_id = br.id);

-- ===== 004_customers_vendors.sql =====
CREATE TABLE IF NOT EXISTS customers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  UNIQUE KEY uq_customer_local (business_owner_id, local_id),
  INDEX idx_customer_phone (phone),
  INDEX idx_customer_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS vendors (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  UNIQUE KEY uq_vendor_local (business_owner_id, local_id),
  INDEX idx_vendor_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 005_catalog_services_products.sql =====
CREATE TABLE IF NOT EXISTS categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  UNIQUE KEY uq_service_local (business_owner_id, local_id),
  INDEX idx_service_parent (parent_id),
  CONSTRAINT fk_services_parent FOREIGN KEY (parent_id) REFERENCES services(id),
  CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  UNIQUE KEY uq_product_local (business_owner_id, local_id),
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  UNIQUE KEY uq_order_local (business_owner_id, local_id),
  UNIQUE KEY uq_order_no (business_owner_id, order_no),
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  INDEX idx_inv_owner (business_owner_id),
  CONSTRAINT fk_inv_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_inv_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventory_adjustments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_no VARCHAR(50) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) NULL,
  email VARCHAR(150) NULL,
  job_title VARCHAR(100) NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_no (business_owner_id, employee_no),
  INDEX idx_emp_owner (business_owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS attendance (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_paid TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_requests (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status ENUM('open', 'closed') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_payroll_period (business_owner_id, period_start, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_runs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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

INSERT INTO leave_types (uuid, business_owner_id, name, is_paid)
SELECT UUID(), 1, 'Annual Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Annual Leave' AND business_owner_id = 1);

INSERT INTO leave_types (uuid, business_owner_id, name, is_paid)
SELECT UUID(), 1, 'Sick Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Sick Leave' AND business_owner_id = 1);

-- ===== 009_expenses.sql =====
CREATE TABLE IF NOT EXISTS expense_categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_exp_cat (business_owner_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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

INSERT INTO expense_categories (uuid, business_owner_id, name)
SELECT UUID(), 1, 'Utilities'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Utilities' AND business_owner_id = 1);

INSERT INTO expense_categories (uuid, business_owner_id, name)
SELECT UUID(), 1, 'Supplies'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Supplies' AND business_owner_id = 1);

-- ===== 010_sync_outbox.sql =====
CREATE TABLE IF NOT EXISTS sync_state (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_owner_id INT UNSIGNED NOT NULL UNIQUE,
  last_push_at TIMESTAMP NULL,
  last_pull_at TIMESTAMP NULL,
  cloud_api_url VARCHAR(500) NULL,
  cloud_token_hash VARCHAR(64) NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_outbox (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_owner_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation ENUM('create', 'update', 'delete') NOT NULL,
  payload JSON NOT NULL,
  synced_at TIMESTAMP NULL,
  sync_attempts INT UNSIGNED NOT NULL DEFAULT 0,
  last_error VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_outbox_pending (business_owner_id, synced_at, created_at),
  INDEX idx_outbox_entity (entity_type, entity_local_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO sync_state (business_owner_id, is_enabled)
SELECT 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sync_state WHERE business_owner_id = 1);

-- ===== 011_documents_files.sql =====
CREATE TABLE IF NOT EXISTS file_assets (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INT UNSIGNED NULL,
  file_path VARCHAR(500) NOT NULL,
  checksum_sha256 CHAR(64) NULL,
  mime_type VARCHAR(100) NULL,
  size_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_file_entity (entity_type, entity_id),
  INDEX idx_file_owner (business_owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS document_templates (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  template_key VARCHAR(50) NOT NULL,
  format ENUM('thermal', 'a4') NOT NULL,
  schema_json JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_template (business_owner_id, template_key, format)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO document_templates (uuid, business_owner_id, template_key, format, schema_json)
SELECT '00000000-0000-4000-8000-000000000101', 1, 'receipt', 'thermal',
  JSON_OBJECT('version', 1, 'width', 48, 'fields', JSON_ARRAY('order_no', 'lines', 'totals', 'payments'))
WHERE NOT EXISTS (SELECT 1 FROM document_templates WHERE template_key = 'receipt' AND format = 'thermal');

INSERT INTO document_templates (uuid, business_owner_id, template_key, format, schema_json)
SELECT '00000000-0000-4000-8000-000000000102', 1, 'receipt', 'a4',
  JSON_OBJECT('version', 1, 'page', 'A4', 'fields', JSON_ARRAY('order_no', 'lines', 'totals', 'payments'))
WHERE NOT EXISTS (SELECT 1 FROM document_templates WHERE template_key = 'receipt' AND format = 'a4');

-- ===== 012_license_umac_runtime.sql =====
CREATE TABLE IF NOT EXISTS umac_policy (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  policy_key VARCHAR(50) NOT NULL,
  policy_value JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_umac_policy (business_owner_id, policy_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS hardware_identity (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  umac_hash CHAR(64) NOT NULL,
  machine_fingerprint TEXT NOT NULL,
  first_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_hw_umac (business_owner_id, umac_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO umac_policy (uuid, business_owner_id, policy_key, policy_value)
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  challan_no VARCHAR(50) NOT NULL,
  challan_type ENUM('delivery', 'collection', 'stock_transfer', 'vendor_return', 'service_receipt') NOT NULL,
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  status ENUM('draft', 'issued', 'cancelled') NOT NULL DEFAULT 'issued',
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_challan_no (business_owner_id, challan_type, challan_no),
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  challan_type VARCHAR(50) NOT NULL,
  last_number INT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY uk_ch_seq (business_owner_id, challan_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 017_purchasing.sql =====
CREATE TABLE IF NOT EXISTS purchase_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  po_no VARCHAR(50) NOT NULL,
  vendor_id INT UNSIGNED NOT NULL,
  status ENUM('draft', 'ordered', 'partial', 'received', 'cancelled') NOT NULL DEFAULT 'draft',
  order_date DATE NOT NULL,
  expected_date DATE NULL,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_po_no (business_owner_id, po_no),
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  purchase_order_id INT UNSIGNED NOT NULL,
  receipt_no VARCHAR(50) NOT NULL,
  received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT NULL,
  created_by INT UNSIGNED NULL,
  UNIQUE KEY uk_gr_no (business_owner_id, receipt_no),
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_loc_name (business_owner_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO inventory_locations (uuid, business_owner_id, name, is_default)
SELECT UUID(), 1, 'Main Store', 1
WHERE NOT EXISTS (SELECT 1 FROM inventory_locations WHERE business_owner_id = 1 AND is_default = 1);

-- ===== 018_notifications.sql =====
CREATE TABLE IF NOT EXISTS notifications (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  notification_type VARCHAR(50) NOT NULL,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  severity ENUM('info', 'warning', 'error') NOT NULL DEFAULT 'info',
  reference_type VARCHAR(50) NULL,
  reference_id INT UNSIGNED NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notif_owner (business_owner_id),
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
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id,
  ADD COLUMN terminal_id INT UNSIGNED NULL AFTER branch_id;

ALTER TABLE inventory_movements
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id;

ALTER TABLE employees
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id;

ALTER TABLE expenses
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id;

UPDATE sales_orders SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;
UPDATE employees SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;

-- ===== 021_terminal_sessions.sql =====
CREATE TABLE IF NOT EXISTS terminal_sessions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  branch_id INT UNSIGNED NULL,
  snapshot_date DATE NOT NULL,
  metric_key VARCHAR(50) NOT NULL,
  metric_value DECIMAL(18,4) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_analytics_day (business_owner_id, branch_id, snapshot_date, metric_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 027_storefront.sql =====
CREATE TABLE IF NOT EXISTS storefront_tokens (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  token_hash VARCHAR(128) NOT NULL UNIQUE,
  label VARCHAR(100) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS storefront_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
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
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  sales_order_id INT UNSIGNED NOT NULL,
  access_token VARCHAR(128) NOT NULL UNIQUE,
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cpt_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

