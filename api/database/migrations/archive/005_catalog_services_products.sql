CREATE TABLE IF NOT EXISTS categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  parent_id INT UNSIGNED NULL,
  type ENUM('service', 'product') NOT NULL,
  name VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_category_parent (parent_id),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS services (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  parent_id INT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  base_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_group TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_service_local (business_owner_id, local_id),
  INDEX idx_service_parent (parent_id),
  CONSTRAINT fk_services_parent FOREIGN KEY (parent_id) REFERENCES services(id),
  CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  local_id INT UNSIGNED NOT NULL,
  parent_id INT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  barcode VARCHAR(100) NULL,
  base_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
  cost DECIMAL(18,2) NOT NULL DEFAULT 0,
  stock_quantity DECIMAL(18,3) NOT NULL DEFAULT 0,
  low_stock_threshold DECIMAL(18,3) NOT NULL DEFAULT 0,
  is_group TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_local (business_owner_id, local_id),
  INDEX idx_product_parent (parent_id),
  INDEX idx_product_barcode (barcode),
  CONSTRAINT fk_products_parent FOREIGN KEY (parent_id) REFERENCES products(id),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_product_map (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  service_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  default_qty DECIMAL(18,3) NOT NULL DEFAULT 1,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_service_product (service_id, product_id),
  CONSTRAINT fk_spm_service FOREIGN KEY (service_id) REFERENCES services(id),
  CONSTRAINT fk_spm_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
