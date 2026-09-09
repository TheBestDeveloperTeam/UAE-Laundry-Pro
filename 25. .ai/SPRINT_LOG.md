# Sprint Log: LaundryPro UAE

## Sprint 01 — Architecture Hardening & Global Config
**Start:** 2026-09-09 | **Status:** COMPLETED

### Completed
- [x] Plugin issue fixed (broken telemetry hook disabled)
- [x] 25. .ai/ directory created with all AI context files
- [x] global_config_service.dart created (path management with validation and auto-directory creation)
- [x] implementation_plan.md generated (full 28-sprint roadmap)
- [x] Full README.md audit completed (1,881 lines)
- [x] Full codebase gap analysis completed
- [x] ARCHITECTURE.md, PROJECT_CONTEXT.md, HARDWARE_INTEGRATION.md created
- [x] Standalone global config admin UI (global_config_screen.dart)
- [x] BACKUP_PATH / INVOICE_PATH / IMAGE_PATH / LOG_PATH / EXPORT_PATH / TEMP_PATH / TEMPLATE_PATH editable by admin
- [x] C:/LaundryPro/ directory auto-creation on app startup (GlobalConfigService().init() in main.dart)
- [x] Ensure api/.env keys match global_config_service.dart defaults

### Sprint Summary
| Sprint | Name | Status | Key Deliverables |
| :--- | :--- | :--- | :--- |
| S01 | Foundation & Config | ✅ Done | Global path resolution, settings singleton, env sync |
| S02 | Auth & Security | ✅ Done | OAuth2 JWT, RBAC matrix, UMAC hardware lock, Account lockout |
| S03 | Catalog & Inventory | ⏳ Pending | Service/Product hierarchy, composite items, modifiers |
| S04 | Core Sales (POS) | ⏳ Pending | Drafts, order confirmation, cart, taxes |

---

## Active Sprint Details

### Sprint 02: Auth & Security (Completed)

#### Accomplished
1. Account Lockout: Added `failed_attempts` tracking to users table. Locks account for 15 minutes after 5 failures.
2. RBAC Enforcement: `RoleController` added for creating/updating roles with JSON permissions.
3. Role Editor UI: New Flutter UI `RoleEditorScreen` to manage 40+ system permissions.
4. Added migrations `029_account_lockout.sql` and `030_seed_roles.sql`.
5. Fixed async gaps in `RoleEditorScreen`.

### Next Sprint (S03) Priorities
1. Service & Product hierarchy models.
2. Catalog UI.
3. Inventory tracking logic.
