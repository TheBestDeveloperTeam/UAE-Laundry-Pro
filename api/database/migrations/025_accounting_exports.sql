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
