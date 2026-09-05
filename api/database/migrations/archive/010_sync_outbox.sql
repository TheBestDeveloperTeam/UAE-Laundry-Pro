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
