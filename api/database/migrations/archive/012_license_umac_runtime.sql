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
