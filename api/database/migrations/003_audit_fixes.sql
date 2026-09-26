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
