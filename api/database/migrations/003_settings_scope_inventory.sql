-- Add inventory scope for settings used by InventoryRepository (idempotent on fresh 001+).

ALTER TABLE settings
  MODIFY COLUMN scope ENUM('system', 'business', 'branch', 'terminal', 'inventory') NOT NULL DEFAULT 'business';

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'inventory.allow_negative_stock', JSON_QUOTE('false'), 'inventory'
WHERE NOT EXISTS (
  SELECT 1 FROM settings
  WHERE setting_key = 'inventory.allow_negative_stock' AND scope = 'inventory'
);
