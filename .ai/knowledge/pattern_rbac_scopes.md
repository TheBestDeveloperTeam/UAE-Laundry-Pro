# Knowledge: pattern_rbac_scopes

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Role-Based Access Control with scopes. 6 roles: super_admin, owner, manager, cashier, operator, driver. Scopes: module:action format (e.g., orders:create, inventory:read). PermissionChecker middleware validates JWT scope claim against route requirement. Server-side enforcement only (client-side is convenience, not security). rbac_enforcer bot validates middleware presence.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |