CREATE TABLE IF NOT EXISTS business (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL UNIQUE,
  legal_name VARCHAR(255) NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  address_line1 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  emirate VARCHAR(100) NULL,
  country VARCHAR(100) NOT NULL DEFAULT 'AE',
  physical_address_hash VARCHAR(64) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS branches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_id INT UNSIGNED NOT NULL,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_branch_code (business_id, code),
  CONSTRAINT fk_branches_business FOREIGN KEY (business_id) REFERENCES business(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS terminals (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  branch_id INT UNSIGNED NOT NULL,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_terminal_code (branch_id, code),
  CONSTRAINT fk_terminals_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO business (uuid, business_owner_id, legal_name, display_name, city, emirate, country)
SELECT '00000000-0000-4000-8000-000000000100', 1, 'LaundryPro UAE', 'LaundryPro UAE', 'Dubai', 'Dubai', 'AE'
WHERE NOT EXISTS (SELECT 1 FROM business WHERE business_owner_id = 1);

INSERT INTO branches (uuid, business_id, code, name)
SELECT '00000000-0000-4000-8000-000000000101', b.id, 'MAIN', 'Main Branch'
FROM business b WHERE b.business_owner_id = 1
  AND NOT EXISTS (SELECT 1 FROM branches WHERE code = 'MAIN' AND business_id = b.id);

INSERT INTO terminals (uuid, branch_id, code, name)
SELECT '00000000-0000-4000-8000-000000000102', br.id, 'T01', 'Counter 1'
FROM branches br
INNER JOIN business b ON b.id = br.business_id AND b.business_owner_id = 1
WHERE br.code = 'MAIN'
  AND NOT EXISTS (SELECT 1 FROM terminals WHERE code = 'T01' AND branch_id = br.id);
