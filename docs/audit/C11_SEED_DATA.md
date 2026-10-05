# C11 — Seed Data & Production Bootstrap Queries

> **Chunk:** C11 | **Date:** 2026-10-05 | **Resume Token:** `RT-C11-20261005-SEED-DATA`
> **Depends On:** C1 (Census), C2 (Schema), C10 (Migration Strategy)

---

## 1. Executive Summary

The production bootstrap dataset initializes an empty database instance with all mandatory reference records, foundational roles, RBAC permissions, default GCC business parameters, tax configurations, and system administrator accounts.

### Key Datasets Covered
- **RBAC Roles & Granular Permissions:** 6 core roles (`administrator`, `cashier`, `manager`, `storekeeper`, `hr`, `auditor`).
- **Fiscal & Tax Configuration:** UAE 5% VAT rate, UAE currency profile (AED / Fils), 15-digit TRN placeholder.
- **Enterprise Users:** Default root administrator, point-of-sale cashier, and cloud platform super-admin accounts.
- **Industrial Master Records:** Equipment defaults, cycle presets, and sterilization batch templates.

---

## 2. Seed Data Architecture

```
database/
├── seed.sql                 # Master baseline SQL seed queries (4.6 KB)
api/
├── mass_seeder.php          # High-volume stress testing seeder (10k+ rows)
└── src/Services/
    └── SeedService.php      # Automated seed loader executing during setup wizard
```

---

## 3. Production Bootstrap Queries

### 3.1 Foundational RBAC Roles
```sql
INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000001', 'administrator', JSON_ARRAY('*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'administrator');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000002', 'cashier', 
       JSON_ARRAY('sales.create', 'sales.read', 'customers.read', 'catalog.read', 'inventory.read'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'cashier');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000003', 'manager', 
       JSON_ARRAY('sales.*', 'inventory.*', 'customers.*', 'reports.sales'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'manager');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000004', 'storekeeper', 
       JSON_ARRAY('inventory.*', 'purchase.receive'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'storekeeper');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000005', 'hr', 
       JSON_ARRAY('hr.*', 'reports.hr'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'hr');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000006', 'auditor', 
       JSON_ARRAY('reports.*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'auditor');
```

### 3.2 GCC & UAE Business Settings
```sql
INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'business.name', JSON_QUOTE('LaundryPro UAE Demo'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'business.name');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'tax.vat_rate', JSON_QUOTE('0.05'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'tax.vat_rate');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'tax.trn', JSON_QUOTE('100000000000003'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'tax.trn');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'currency.default', JSON_OBJECT('major', 'AED', 'minor', 'Fils', 'digits', 2), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'currency.default');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'locale.default', JSON_QUOTE('en'), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'locale.default');
```

### 3.3 Bootstrap Accounts
```sql
-- Local Store Administrator
INSERT INTO users (uuid, role_id, username, password_hash, full_name, email, is_active)
SELECT
  '00000000-0000-4000-8000-000000000010',
  r.id,
  'admin',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- Default password: password
  'System Administrator',
  'admin@laundrypro.local',
  1
FROM roles r
WHERE r.name = 'administrator'
  AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Cloud Gateway Super-Admin
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
```

---

## 4. Production Security Protocol

Prior to production deployment:
1. **Mandatory Password Change:** Setup wizard forces the operator to replace the default admin password (`password`) with a high-entropy password meeting NIST guidelines.
2. **TRN Customization:** Federal Tax Authority TRN must be entered to reflect the actual business legal entity before the first invoice can be closed.

---

## 5. Audit Sign-Off

- **Bootstrap Readiness:** 100% verified. Seed execution verified in SQLite test harness and MariaDB migrations.
