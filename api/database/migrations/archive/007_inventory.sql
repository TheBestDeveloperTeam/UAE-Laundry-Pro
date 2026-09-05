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
