-- Parity with local api/database/migrations/003_settings_scope_inventory.sql (tenant_settings model on cloud).

INSERT INTO tenant_settings (tenant_id, setting_key, setting_value, category)
SELECT b.id, 'inventory.allow_negative_stock', 'false', 'inventory'
FROM businesses b
WHERE NOT EXISTS (
  SELECT 1 FROM tenant_settings ts
  WHERE ts.tenant_id = b.id AND ts.setting_key = 'inventory.allow_negative_stock'
);
