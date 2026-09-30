-- ============================================================================
-- LaundryPro UAE — Cloud Database Schema
-- Central multi-tenant database for cloud-api
-- Compatible with MariaDB 10.6+ / MySQL 8.0+
-- ============================================================================
-- IMPORTANT: This schema is for the CLOUD database ONLY.
-- For the local per-workstation database, see ../local/schema.sql
-- ============================================================================

-- Migration tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  migration VARCHAR(255) NOT NULL UNIQUE,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Super-Admin Authentication =====
CREATE TABLE IF NOT EXISTS cloud_super_admins (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(191) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(128) NOT NULL DEFAULT 'Super Administrator',
  role VARCHAR(32) NOT NULL DEFAULT 'super_admin',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  failed_login_attempts INT UNSIGNED NOT NULL DEFAULT 0,
  locked_until DATETIME NULL,
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Tenant Businesses =====
CREATE TABLE IF NOT EXISTS businesses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
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
  max_branches INT UNSIGNED NOT NULL DEFAULT 1,
  max_devices INT UNSIGNED NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_business_status (status),
  INDEX idx_business_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Sync Records (Inbound from Local APIs) =====
CREATE TABLE IF NOT EXISTS sync_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_uuid CHAR(36) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  payload JSON NOT NULL,
  entity_version INT UNSIGNED NOT NULL DEFAULT 1,
  source_umac VARCHAR(128) NULL,
  received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_sync_entity (tenant_id, entity_type, entity_uuid),
  INDEX idx_sync_tenant_time (tenant_id, received_at),
  INDEX idx_sync_entity_type (tenant_id, entity_type),
  CONSTRAINT fk_sync_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Sync Inbox (Outbound to Local APIs on Pull) =====
CREATE TABLE IF NOT EXISTS sync_inbox (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_uuid CHAR(36) NOT NULL,
  operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  payload JSON NOT NULL,
  source ENUM('cloud_admin', 'cross_branch', 'system') NOT NULL DEFAULT 'cloud_admin',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_inbox_tenant (tenant_id, created_at),
  CONSTRAINT fk_inbox_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Sync Conflicts (Dead-Letter Queue) =====
CREATE TABLE IF NOT EXISTS sync_conflicts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  sync_record_id BIGINT UNSIGNED NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_uuid CHAR(36) NOT NULL,
  local_payload JSON NOT NULL,
  cloud_payload JSON NOT NULL,
  resolution_status ENUM('pending', 'auto_resolved', 'manual_resolved', 'discarded') NOT NULL DEFAULT 'pending',
  resolved_by INT UNSIGNED NULL,
  resolved_at DATETIME NULL,
  resolution_notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_conflict_tenant (tenant_id, resolution_status),
  CONSTRAINT fk_conflict_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== License Management =====
CREATE TABLE IF NOT EXISTS cloud_licenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  license_key VARCHAR(128) NOT NULL UNIQUE,
  umac_fingerprint VARCHAR(128) NULL,
  plan_type ENUM('trial', 'standard', 'premium', 'enterprise') NOT NULL DEFAULT 'standard',
  max_invoices INT NOT NULL DEFAULT 999999,
  max_customers INT NOT NULL DEFAULT 999999,
  max_branches INT NOT NULL DEFAULT 1,
  max_devices INT NOT NULL DEFAULT 1,
  status ENUM('active', 'revoked', 'expired', 'suspended') NOT NULL DEFAULT 'active',
  expires_at DATETIME NULL,
  activated_at DATETIME NULL,
  signature TEXT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at DATETIME NULL,
  revoked_reason VARCHAR(255) NULL,
  INDEX idx_tenant_lic (tenant_id),
  INDEX idx_lic_status (status),
  CONSTRAINT fk_license_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Device Telemetry & UMAC Tracking =====
CREATE TABLE IF NOT EXISTS cloud_telemetry (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  umac VARCHAR(128) NOT NULL,
  workstation_name VARCHAR(100) NULL,
  workstation_ip VARCHAR(64) NULL,
  app_version VARCHAR(32) NULL,
  os_version VARCHAR(64) NULL,
  branch_code VARCHAR(50) NULL,
  status_payload JSON NULL,
  first_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_ping_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tenant_umac (tenant_id, umac),
  INDEX idx_telemetry_tenant (tenant_id),
  CONSTRAINT fk_telemetry_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Cloud Agent (API-to-API Authentication) =====
CREATE TABLE IF NOT EXISTS cloud_agents (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  agent_id CHAR(36) NOT NULL UNIQUE,
  agent_secret_hash VARCHAR(255) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_handshake_at TIMESTAMP NULL,
  CONSTRAINT fk_agent_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Audit Logs =====
CREATE TABLE IF NOT EXISTS cloud_audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  super_admin_id INT UNSIGNED NULL,
  tenant_id INT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100) NULL,
  entity_id VARCHAR(100) NULL,
  details TEXT NULL,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_time (created_at),
  INDEX idx_audit_tenant (tenant_id, created_at),
  INDEX idx_audit_admin (super_admin_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== CSRF Tokens for Portal =====
CREATE TABLE IF NOT EXISTS cloud_csrf_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  token_hash CHAR(64) NOT NULL UNIQUE,
  session_id VARCHAR(128) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_csrf_session (session_id),
  INDEX idx_csrf_expiry (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Session Management =====
CREATE TABLE IF NOT EXISTS cloud_sessions (
  id VARCHAR(128) PRIMARY KEY,
  super_admin_id INT UNSIGNED NULL,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(255) NULL,
  payload TEXT NULL,
  last_activity TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_session_admin (super_admin_id),
  INDEX idx_session_activity (last_activity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Sync Health Metrics =====
CREATE TABLE IF NOT EXISTS sync_health_snapshots (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  snapshot_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  pending_push_count INT UNSIGNED NOT NULL DEFAULT 0,
  pending_pull_count INT UNSIGNED NOT NULL DEFAULT 0,
  conflict_count INT UNSIGNED NOT NULL DEFAULT 0,
  last_push_at DATETIME NULL,
  last_pull_at DATETIME NULL,
  avg_push_latency_ms INT UNSIGNED NULL,
  INDEX idx_health_tenant (tenant_id, snapshot_time),
  CONSTRAINT fk_health_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Multi-Tenant Domain Entities (Tenant Scoped) =====

CREATE TABLE IF NOT EXISTS tenant_users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  username VARCHAR(64) NOT NULL,
  email VARCHAR(191) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'cashier',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tuser_tenant (tenant_id),
  CONSTRAINT fk_tuser_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_customers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  customer_code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  email VARCHAR(191) NULL,
  address TEXT NULL,
  emirate VARCHAR(100) NOT NULL DEFAULT 'Dubai',
  credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  outstanding_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tcust_tenant (tenant_id, phone),
  CONSTRAINT fk_tcust_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_vendors (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(150) NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(191) NULL,
  trn VARCHAR(50) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tvend_tenant (tenant_id),
  CONSTRAINT fk_tvend_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tcat_tenant (tenant_id),
  CONSTRAINT fk_tcat_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_services (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  category_id INT UNSIGNED NULL,
  name VARCHAR(255) NOT NULL,
  service_code VARCHAR(50) NOT NULL,
  price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  turnaround_hours INT UNSIGNED NOT NULL DEFAULT 48,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tserv_tenant (tenant_id, service_code),
  CONSTRAINT fk_tserv_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_products (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(100) NULL,
  price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  stock_quantity DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tprod_tenant (tenant_id),
  CONSTRAINT fk_tprod_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_sales_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  order_number VARCHAR(100) NOT NULL,
  customer_id INT UNSIGNED NULL,
  status ENUM('draft', 'confirmed', 'in_process', 'ready', 'delivered', 'cancelled') NOT NULL DEFAULT 'confirmed',
  payment_status ENUM('unpaid', 'partially_paid', 'paid', 'refunded') NOT NULL DEFAULT 'unpaid',
  subtotal DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  vat_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  source_branch VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_torder_tenant (tenant_id, order_number),
  INDEX idx_torder_status (tenant_id, status),
  CONSTRAINT fk_torder_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_sales_order_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  order_id INT UNSIGNED NOT NULL,
  service_id INT UNSIGNED NULL,
  item_name VARCHAR(255) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  vat_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  notes TEXT NULL,
  INDEX idx_tline_order (tenant_id, order_id),
  CONSTRAINT fk_tline_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE,
  CONSTRAINT fk_tline_order FOREIGN KEY (order_id) REFERENCES tenant_sales_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_payment_transactions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  order_id INT UNSIGNED NOT NULL,
  tender_type ENUM('cash', 'card', 'store_credit', 'corporate_ledger') NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  reference_no VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tpay_tenant (tenant_id, order_id),
  CONSTRAINT fk_tpay_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE,
  CONSTRAINT fk_tpay_order FOREIGN KEY (order_id) REFERENCES tenant_sales_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_inventory_movements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity_change DECIMAL(18,2) NOT NULL,
  movement_type ENUM('purchase', 'sale', 'adjustment', 'waste', 'transfer') NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tmov_tenant (tenant_id, product_id),
  CONSTRAINT fk_tmov_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_delivery_tasks (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  order_id INT UNSIGNED NOT NULL,
  driver_name VARCHAR(150) NULL,
  task_type ENUM('pickup', 'delivery') NOT NULL,
  status ENUM('pending', 'assigned', 'out_for_delivery', 'delivered', 'failed') NOT NULL DEFAULT 'pending',
  scheduled_at DATETIME NULL,
  completed_at DATETIME NULL,
  INDEX idx_tdel_tenant (tenant_id, status),
  CONSTRAINT fk_tdel_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_challans (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  challan_number VARCHAR(100) NOT NULL,
  driver_name VARCHAR(150) NULL,
  status ENUM('dispatched', 'in_transit', 'received_at_plant', 'returned_to_branch') NOT NULL DEFAULT 'dispatched',
  garment_count INT UNSIGNED NOT NULL DEFAULT 0,
  dispatched_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  received_at DATETIME NULL,
  INDEX idx_tchal_tenant (tenant_id, challan_number),
  CONSTRAINT fk_tchal_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_employees (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  employee_code VARCHAR(50) NULL,
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(50) NULL,
  job_title VARCHAR(100) NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_temp_tenant (tenant_id),
  CONSTRAINT fk_temp_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_attendance (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NOT NULL,
  work_date DATE NOT NULL,
  clock_in DATETIME NOT NULL,
  clock_out DATETIME NULL,
  INDEX idx_tatt_tenant (tenant_id, work_date),
  CONSTRAINT fk_tatt_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE,
  CONSTRAINT fk_tatt_emp FOREIGN KEY (employee_id) REFERENCES tenant_employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_expenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  category_name VARCHAR(100) NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  payee VARCHAR(150) NOT NULL,
  paid_from ENUM('cash_drawer', 'bank_account') NOT NULL DEFAULT 'cash_drawer',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_texp_tenant (tenant_id, created_at),
  CONSTRAINT fk_texp_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_branches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(50) NULL,
  address TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tbranch_tenant (tenant_id),
  CONSTRAINT fk_tbranch_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_terminals (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  branch_id INT UNSIGNED NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  terminal_code VARCHAR(50) NOT NULL,
  device_name VARCHAR(100) NOT NULL,
  umac VARCHAR(128) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tterm_tenant (tenant_id),
  CONSTRAINT fk_tterm_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_roles (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(50) NOT NULL,
  permissions JSON NULL,
  is_system TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_trole_tenant (tenant_id),
  CONSTRAINT fk_trole_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_settings (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  setting_key VARCHAR(100) NOT NULL,
  setting_value TEXT NULL,
  category VARCHAR(50) NOT NULL DEFAULT 'general',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tset_key (tenant_id, setting_key),
  CONSTRAINT fk_tset_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_invoices (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  order_id INT UNSIGNED NOT NULL,
  invoice_number VARCHAR(100) NOT NULL,
  invoice_date DATE NOT NULL,
  subtotal DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  vat_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  status ENUM('draft', 'posted', 'corrected', 'cancelled') NOT NULL DEFAULT 'posted',
  qr_data TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tinv_tenant (tenant_id, invoice_number),
  CONSTRAINT fk_tinv_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_purchase_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  vendor_id INT UNSIGNED NULL,
  po_number VARCHAR(100) NOT NULL,
  status ENUM('draft', 'submitted', 'received', 'cancelled') NOT NULL DEFAULT 'draft',
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  expected_delivery_date DATE NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tpo_tenant (tenant_id, po_number),
  CONSTRAINT fk_tpo_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_leave_requests (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NOT NULL,
  leave_type VARCHAR(50) NOT NULL DEFAULT 'annual',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days_count INT UNSIGNED NOT NULL DEFAULT 1,
  status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  reason TEXT NULL,
  approved_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tleave_tenant (tenant_id, employee_id),
  CONSTRAINT fk_tleave_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_payroll_runs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  period_name VARCHAR(100) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_gross DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  total_deductions DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  total_net DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  status ENUM('draft', 'processing', 'completed', 'cancelled') NOT NULL DEFAULT 'draft',
  processed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tpayrun_tenant (tenant_id),
  CONSTRAINT fk_tpayrun_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_salary_advances (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  deduction_month VARCHAR(20) NOT NULL,
  status ENUM('requested', 'approved', 'deducted', 'rejected') NOT NULL DEFAULT 'requested',
  reason TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tsaladv_tenant (tenant_id, employee_id),
  CONSTRAINT fk_tsaladv_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_notifications (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'system',
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tnotif_tenant (tenant_id, is_read),
  CONSTRAINT fk_tnotif_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_channels (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  channel_name VARCHAR(100) NOT NULL,
  channel_type ENUM('whatsapp', 'sms', 'email', 'webhook') NOT NULL,
  config JSON NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tchan_tenant (tenant_id),
  CONSTRAINT fk_tchan_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_equipment (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  name VARCHAR(150) NOT NULL,
  model VARCHAR(100) NULL,
  serial_number VARCHAR(100) NULL,
  status ENUM('operational', 'maintenance', 'offline') NOT NULL DEFAULT 'operational',
  last_calibrated_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tequip_tenant (tenant_id),
  CONSTRAINT fk_tequip_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_operators (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NOT NULL,
  certification_name VARCHAR(150) NOT NULL,
  certified_at DATE NOT NULL,
  expires_at DATE NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'valid',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_top_tenant (tenant_id, employee_id),
  CONSTRAINT fk_top_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_advanced_cycles (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  preset_name VARCHAR(100) NOT NULL,
  parameters JSON NULL,
  status ENUM('running', 'completed', 'aborted') NOT NULL DEFAULT 'running',
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  INDEX idx_tcycle_tenant (tenant_id, status),
  CONSTRAINT fk_tcycle_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_sterilization_batches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  batch_number VARCHAR(100) NOT NULL,
  cycle_type VARCHAR(50) NOT NULL,
  status ENUM('pending', 'in_cycle', 'passed', 'failed') NOT NULL DEFAULT 'pending',
  logged_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  signed_by INT UNSIGNED NULL,
  INDEX idx_tster_tenant (tenant_id, batch_number),
  CONSTRAINT fk_tster_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_storefront_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  order_reference VARCHAR(100) NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  customer_phone VARCHAR(50) NOT NULL,
  items JSON NOT NULL,
  status ENUM('new', 'converted', 'rejected') NOT NULL DEFAULT 'new',
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tstore_tenant (tenant_id, order_reference),
  CONSTRAINT fk_tstore_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_accounting_batches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  batch_number VARCHAR(100) NOT NULL,
  batch_type VARCHAR(50) NOT NULL DEFAULT 'journal',
  total_debit DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  total_credit DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  status ENUM('draft', 'posted', 'reconciled') NOT NULL DEFAULT 'draft',
  period_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tacc_tenant (tenant_id, batch_number),
  CONSTRAINT fk_tacc_tenant FOREIGN KEY (tenant_id) REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Seed Data =====

-- Default Super-Admin (password must be changed on first login in production)
-- The password hash below is for development ONLY. Generate a new hash in production.
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

-- Record migrations
INSERT INTO schema_migrations (migration) VALUES ('001_cloud_initial_schema') ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
INSERT INTO schema_migrations (migration) VALUES ('002_tenant_full_domain_schema') ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
