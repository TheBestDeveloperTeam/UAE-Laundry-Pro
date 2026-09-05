CREATE TABLE IF NOT EXISTS sync_entity_types (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entity_type VARCHAR(50) NOT NULL UNIQUE,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO sync_entity_types (entity_type) VALUES
  ('customer'), ('vendor'), ('sales_order'), ('employee'), ('expense'),
  ('challan'), ('purchase_order'), ('notification'), ('payroll_run');
