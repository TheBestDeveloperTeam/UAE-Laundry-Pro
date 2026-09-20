# Bot Registry - LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Sentinel Bots (10)
| Bot ID | Codename | Trigger Summary | Status |
|--------|----------|----------------|--------|
| LP-BOT-MONEY | money_precision_guard | FLOAT/DOUBLE near money | active |
| LP-BOT-TENANT | tenant_isolation_checker | SQL without business_owner_id | active |
| LP-BOT-I18N | i18n_auditor | Hardcoded UI strings | active |
| LP-BOT-SYNC | sync_watchdog | Sync outbox operations | active |
| LP-BOT-MIGRATE | migration_safety_net | DDL/migration execution | active |
| LP-BOT-RBAC | rbac_enforcer | API route without PermissionChecker | active |
| LP-BOT-AUDIT | audit_trail_validator | State changes without audit log | active |
| LP-BOT-VERSION | version_bumper | Release without version bump | active |
| LP-BOT-DEADCODE | dead_code_scanner | Code deletion/refactoring | active |
| LP-BOT-DEPS | dependency_auditor | Dependency changes | active |