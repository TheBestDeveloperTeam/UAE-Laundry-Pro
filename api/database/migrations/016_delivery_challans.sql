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
