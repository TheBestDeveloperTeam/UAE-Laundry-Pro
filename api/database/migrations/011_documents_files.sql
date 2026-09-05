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
