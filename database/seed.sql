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

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE batch_lots;
TRUNCATE TABLE batch_scan_events;
TRUNCATE TABLE sterilization_logs;
TRUNCATE TABLE process_logs;
TRUNCATE TABLE electronic_signatures;

INSERT IGNORE INTO equipment (id, asset_tag, equipment_type) VALUES (1, 'TAG-100', 'autoclave');
INSERT IGNORE INTO advanced_cycle_presets (id, service_id, cycle_name) VALUES (1, 1, 'Sterilization Default');
INSERT IGNORE INTO advanced_cycle_runs (id, uuid, sales_order_line_id, preset_id, equipment_id, operator_employee_id, status) VALUES (1, 'uuid-cycle-1', 1, 1, 1, 1, 'running');

SET FOREIGN_KEY_CHECKS = 1;

-- Default Super-Admin credentials:
-- Username: superadmin
-- Password: SuperAdmin@LaundryPro2026!
-- Hash generated via password_hash('SuperAdmin@LaundryPro2026!', PASSWORD_DEFAULT)

INSERT INTO cloud_super_admins (id, username, email, password_hash, full_name, role, is_active)
VALUES (
  1,
  'superadmin',
  'superadmin@magnificentsolution.co.in',
  '$2y$10$eE0oI9uL5O9B7zT7w7Nq6.H.w187QjXo2bWqC6cZyS85Ewh9bK87y',
  'Master Super Administrator',
  'super_admin',
  1
) ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- ========================================================
-- Complete Product & Service Catalog Seeds for UAE Market
-- ========================================================

-- Categories: Service
INSERT INTO categories (uuid, admin_id, type, name, sort_order, is_active)
SELECT UUID(), 1, 'service', 'Dry Cleaning', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Dry Cleaning' AND admin_id = 1);

INSERT INTO categories (uuid, admin_id, type, name, sort_order, is_active)
SELECT UUID(), 1, 'service', 'Wash & Fold', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Wash & Fold' AND admin_id = 1);

INSERT INTO categories (uuid, admin_id, type, name, sort_order, is_active)
SELECT UUID(), 1, 'service', 'Steam Pressing', 3, 1
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Steam Pressing' AND admin_id = 1);

INSERT INTO categories (uuid, admin_id, type, name, sort_order, is_active)
SELECT UUID(), 1, 'service', 'Curtains & Drapes', 4, 1
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Curtains & Drapes' AND admin_id = 1);

INSERT INTO categories (uuid, admin_id, type, name, sort_order, is_active)
SELECT UUID(), 1, 'service', 'Carpet & Rugs', 5, 1
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Carpet & Rugs' AND admin_id = 1);

-- Categories: Retail / Supply Products
INSERT INTO categories (uuid, admin_id, type, name, sort_order, is_active)
SELECT UUID(), 1, 'product', 'Retail Detergents & Softeners', 6, 1
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Retail Detergents & Softeners' AND admin_id = 1);

INSERT INTO categories (uuid, admin_id, type, name, sort_order, is_active)
SELECT UUID(), 1, 'product', 'Packaging & Hangers', 7, 1
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Packaging & Hangers' AND admin_id = 1);

-- Services: Common UAE Garments & Treatments
INSERT INTO services (uuid, admin_id, local_id, category_id, code, name, description, base_rate, cost, is_group, is_active)
SELECT UUID(), 1, 101, c.id, 'SRV-KAND-DC', 'Kandora / Dishdasha (Dry Clean)', 'Traditional Emirati garment dry clean & press', 18.00, 4.50, 0, 1
FROM categories c WHERE c.name = 'Dry Cleaning' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM services WHERE code = 'SRV-KAND-DC' AND admin_id = 1);

INSERT INTO services (uuid, admin_id, local_id, category_id, code, name, description, base_rate, cost, is_group, is_active)
SELECT UUID(), 1, 102, c.id, 'SRV-ABAYA-DC', 'Abaya Premium (Dry Clean)', 'Hand-finished silk/crepe abaya dry cleaning', 25.00, 6.00, 0, 1
FROM categories c WHERE c.name = 'Dry Cleaning' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM services WHERE code = 'SRV-ABAYA-DC' AND admin_id = 1);

INSERT INTO services (uuid, admin_id, local_id, category_id, code, name, description, base_rate, cost, is_group, is_active)
SELECT UUID(), 1, 103, c.id, 'SRV-SUIT-2PC', 'Suit 2-Piece (Dry Clean)', 'Jacket and trousers delicate solvent cleaning', 35.00, 8.50, 0, 1
FROM categories c WHERE c.name = 'Dry Cleaning' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM services WHERE code = 'SRV-SUIT-2PC' AND admin_id = 1);

INSERT INTO services (uuid, admin_id, local_id, category_id, code, name, description, base_rate, cost, is_group, is_active)
SELECT UUID(), 1, 104, c.id, 'SRV-SHIRT-PRS', 'Shirt / Blouse (Steam Press)', 'Automated steam mannequin pressing', 7.00, 1.50, 0, 1
FROM categories c WHERE c.name = 'Steam Pressing' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM services WHERE code = 'SRV-SHIRT-PRS' AND admin_id = 1);

INSERT INTO services (uuid, admin_id, local_id, category_id, code, name, description, base_rate, cost, is_group, is_active)
SELECT UUID(), 1, 105, c.id, 'SRV-WASH-KG', 'Wash & Fold (Per Kg)', 'Everyday laundry washed, conditioned, and folded', 12.00, 3.00, 0, 1
FROM categories c WHERE c.name = 'Wash & Fold' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM services WHERE code = 'SRV-WASH-KG' AND admin_id = 1);

INSERT INTO services (uuid, admin_id, local_id, category_id, code, name, description, base_rate, cost, is_group, is_active)
SELECT UUID(), 1, 106, c.id, 'SRV-DUVET-KNG', 'King Duvet / Comforter', 'Deep wash and thermal anti-dust-mite drying', 45.00, 12.00, 0, 1
FROM categories c WHERE c.name = 'Wash & Fold' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM services WHERE code = 'SRV-DUVET-KNG' AND admin_id = 1);

INSERT INTO services (uuid, admin_id, local_id, category_id, code, name, description, base_rate, cost, is_group, is_active)
SELECT UUID(), 1, 107, c.id, 'SRV-CARPET-SQM', 'Persian/Wool Carpet Cleaning (Sq.m)', 'Rotary deep shampoo and stain extraction per square meter', 30.00, 9.00, 0, 1
FROM categories c WHERE c.name = 'Carpet & Rugs' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM services WHERE code = 'SRV-CARPET-SQM' AND admin_id = 1);

-- Products: Retail & Supplies
INSERT INTO products (uuid, admin_id, local_id, category_id, code, name, description, barcode, base_rate, cost, stock_quantity, low_stock_threshold, is_active)
SELECT UUID(), 1, 201, c.id, 'PRD-LNX-SPRY', 'LaundryPro Fabric Freshener 500ml', 'Oud & Amber signature garment mist', '6291000100012', 25.00, 10.00, 150.000, 20.000, 1
FROM categories c WHERE c.name = 'Retail Detergents & Softeners' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM products WHERE code = 'PRD-LNX-SPRY' AND admin_id = 1);

INSERT INTO products (uuid, admin_id, local_id, category_id, code, name, description, barcode, base_rate, cost, stock_quantity, low_stock_threshold, is_active)
SELECT UUID(), 1, 202, c.id, 'PRD-SUIT-BAG', 'Breathable Non-Woven Suit Cover', 'Heavy duty zipper suit and kandora storage bag', '6291000100029', 15.00, 4.00, 300.000, 50.000, 1
FROM categories c WHERE c.name = 'Packaging & Hangers' AND c.admin_id = 1
  AND NOT EXISTS (SELECT 1 FROM products WHERE code = 'PRD-SUIT-BAG' AND admin_id = 1);

