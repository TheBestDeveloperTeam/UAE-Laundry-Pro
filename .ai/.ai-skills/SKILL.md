---
name: laundrypro-ecosystem-guide
description: Developer and AI Assistant operational guide for maintaining, extending, and debugging the dual-layer LaundryPro UAE ecosystem (Flutter Desktop + Local PHP API + Cloud API + Super-Admin Portal).
---

# LaundryPro UAE Operational Skills & Engineering Guide

This skill guide equips developers and AI agents with the conventions, commands, and rules required to work on LaundryPro UAE.

---

## 1. Architectural Principles

1. **No Runtime Frameworks in PHP:** Both api/ and cloud-api/ must remain pure PHP 8.2 with PDO. Do NOT introduce Composer packages or external PHP frameworks into runtime code.
2. **Offline-First Resilience:** The Flutter desktop workstation must never block or crash if an internet connection or the central cloud is unavailable.
3. **Database Migrations:**
   - Local DB migrations live in api/database/migrations/.
   - Never edit historical migrations in production. Always write new numbered scripts (e.g., 020_*.sql).
   - Run migrations locally via: php api/database/migrate.php
4. **Bilingual Localization:**
   - Every user-facing string must be translated in both assets/lang/en.json and assets/lang/ar.json.
   - When viewing Arabic, the application dynamically flips to RTL.
5. **Peripheral Integrity:**
   - Thermal receipt building must strictly format text to 48 columns (80mm) or 32 columns (58mm) and terminate with ESC/POS paper cut.

---

## 2. Standard Engineering Quality Gates

Always run the quality gate command before staging any commits:
powershell -ExecutionPolicy Bypass -File scripts\dev.ps1 gate

This runs:
1. powershell scripts\dev.ps1 lint (PHP 8.2 syntax checks)
2. powershell scripts\dev.ps1 test-api (Local PHP API declarative integration test suite)
3. powershell scripts\dev.ps1 analyze (Flutter static analysis: must have 0 errors)
4. powershell scripts\dev.ps1 test (Flutter widget and unit tests: 116 tests must pass)

---

## 3. Local Node Setup Commands

To configure a fresh Windows machine for production laundry client deployment:
powershell -ExecutionPolicy Bypass -File scripts\setup-client-node.ps1

This configures:
- C:\Windows\System32\drivers\etc\hosts entry: 127.0.0.1 laundrypro-localapi
- Apache VirtualHost in XAMPP httpd-vhosts.conf
- Restarts Apache web server service

---

## 4. Super-Admin Portal Credentials & Access

- **Portal URL:** http://localhost/cloud-api/public/admin or http://cloud-api/admin
- **Default Username:** superadmin
- **Default Password:** SuperAdmin@LaundryPro2026!
- **Database Name:** laundrypro_cloud