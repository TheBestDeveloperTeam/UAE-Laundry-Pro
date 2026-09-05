CREATE TABLE IF NOT EXISTS expense_categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_exp_cat (business_owner_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  category_id INT UNSIGNED NOT NULL,
  expense_date DATE NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  description VARCHAR(255) NULL,
  status ENUM('draft', 'pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  created_by INT UNSIGNED NULL,
  approved_by INT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_exp_category FOREIGN KEY (category_id) REFERENCES expense_categories(id),
  CONSTRAINT fk_exp_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_exp_approver FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expense_attachments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  expense_id INT UNSIGNED NOT NULL,
  file_asset_id INT UNSIGNED NULL,
  file_path VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ea_expense FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO expense_categories (uuid, business_owner_id, name)
SELECT UUID(), 1, 'Utilities'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Utilities' AND business_owner_id = 1);

INSERT INTO expense_categories (uuid, business_owner_id, name)
SELECT UUID(), 1, 'Supplies'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Supplies' AND business_owner_id = 1);
