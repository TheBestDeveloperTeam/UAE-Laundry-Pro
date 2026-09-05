CREATE TABLE IF NOT EXISTS country_profiles (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code CHAR(2) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  currency_symbol VARCHAR(10) NOT NULL,
  timezone VARCHAR(64) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO country_profiles (code, name, currency_code, currency_symbol, timezone) VALUES
  ('AE', 'United Arab Emirates', 'AED', 'AED', 'Asia/Dubai'),
  ('SA', 'Saudi Arabia', 'SAR', 'SAR', 'Asia/Riyadh');
