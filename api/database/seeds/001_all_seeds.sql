-- LaundryPro UAE consolidated seed data (roles, users, phase-2 permissions)
-- Applied by SeedService / run_dev_seed.php

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000001', 'administrator', JSON_ARRAY('*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'administrator');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000002', 'cashier', JSON_ARRAY('sales.create', 'sales.read', 'customers.read', 'catalog.read', 'inventory.read'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'cashier');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000003', 'manager', JSON_ARRAY('sales.*', 'inventory.*', 'customers.*', 'reports.sales'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'manager');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000004', 'storekeeper', JSON_ARRAY('inventory.*', 'purchase.receive'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'storekeeper');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000005', 'hr', JSON_ARRAY('hr.*', 'reports.hr'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'hr');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000006', 'auditor', JSON_ARRAY('reports.*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'auditor');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'business.name', JSON_QUOTE('LaundryPro UAE'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'business.name' AND scope = 'business');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'locale.default', JSON_QUOTE('en'), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'locale.default' AND scope = 'system');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'currency.default', JSON_OBJECT('major', 'AED', 'minor', 'Fils', 'digits', 2), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'currency.default' AND scope = 'system');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'tax.vat_rate', JSON_QUOTE('0.05'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'tax.vat_rate' AND scope = 'business');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'tax.trn', JSON_QUOTE('100000000000003'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'tax.trn' AND scope = 'business');

INSERT INTO users (uuid, role_id, username, password_hash, full_name, email, is_active)
SELECT
  '00000000-0000-4000-8000-000000000010',
  r.id,
  'admin',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'System Administrator',
  'admin@laundrypro.local',
  1
FROM roles r
WHERE r.name = 'administrator'
  AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

INSERT INTO users (uuid, role_id, username, password_hash, full_name, email, is_active)
SELECT
  '00000000-0000-4000-8000-000000000011',
  r.id,
  'cashier',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'POS Cashier',
  'cashier@laundrypro.local',
  1
FROM roles r
WHERE r.name = 'cashier'
  AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'cashier');
