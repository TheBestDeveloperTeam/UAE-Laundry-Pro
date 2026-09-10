CREATE TABLE IF NOT EXISTS `settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `scope` VARCHAR(50) NOT NULL,
  `key_name` VARCHAR(100) NOT NULL,
  `value` TEXT,
  `reference_id` INT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `sync_outbox` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `entity_type` VARCHAR(50) NOT NULL,
  `entity_local_id` INT NOT NULL,
  `operation` VARCHAR(20) NOT NULL,
  `payload` JSON,
  `status` VARCHAR(20) DEFAULT 'pending',
  `attempts` INT DEFAULT 0,
  `next_retry_at` DATETIME DEFAULT NULL,
  `synced_at` DATETIME DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `schema_migrations` (
  `migration` VARCHAR(255) PRIMARY KEY
);
