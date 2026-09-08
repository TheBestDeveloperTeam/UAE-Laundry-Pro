-- LaundryPro UAE Central Cloud Schema (Multi-Tenant & Super-Admin)
-- Compatible with MariaDB / MySQL 5.7+ / 8.0+

CREATE TABLE IF NOT EXISTS cloud_super_admins (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(191) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(128) NOT NULL DEFAULT 'Super Administrator',
  role VARCHAR(32) NOT NULL DEFAULT 'super_admin',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS businesses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_owner_id INT UNSIGNED NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_local_id INT UNSIGNED NOT NULL,
  operation VARCHAR(20) NOT NULL,
  payload JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_sync_entity (business_owner_id, entity_type, entity_local_id),
  INDEX idx_sync_owner (business_owner_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_licenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  license_key VARCHAR(128) NOT NULL UNIQUE,
  umac_fingerprint VARCHAR(128) NULL,
  plan_type VARCHAR(50) NOT NULL DEFAULT 'standard',
  max_invoices INT NOT NULL DEFAULT 999999,
  max_customers INT NOT NULL DEFAULT 999999,
  status ENUM('active', 'revoked', 'expired') NOT NULL DEFAULT 'active',
  expires_at DATETIME NULL,
  signature TEXT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tenant_lic (tenant_id),
  INDEX idx_lic_key (license_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_telemetry (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT UNSIGNED NOT NULL,
  workstation_ip VARCHAR(64) NULL,
  app_version VARCHAR(32) NULL,
  os_version VARCHAR(64) NULL,
  umac VARCHAR(128) NULL,
  status_payload JSON NULL,
  last_ping_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_telemetry_tenant (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cloud_audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  super_admin_id INT UNSIGNED NULL,
  tenant_id INT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  details TEXT NULL,
  ip_address VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
