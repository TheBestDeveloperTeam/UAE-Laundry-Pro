# Bot: rbac_enforcer

## Identity
- Bot ID: LP-BOT-RBAC
- Codename: rbac_enforcer
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any API route registration or controller method addition

## Action
Verify PermissionChecker middleware is applied with correct scope. If missing: BLOCK.

## Rules
1. Scan route registration for middleware array.
2. Check PermissionChecker is included.
3. Check scope matches route's intended permission.
4. Exempt: /api/v1/auth/login, /api/v1/auth/refresh, /health.
5. If violation: emit CRITICAL alert.

## Alert Severity
- CRITICAL: Data integrity, security, or financial precision violation
- HIGH: Missing required pattern or convention
- LOW: Code quality or documentation issue

## Integration
- Runs on every prompt cycle during ORCHESTRATOR Step 5 (Bot Sweep)
- Results logged to `.ai/logs/decisions.log.md`
- Violations block the response until resolved or explicitly overridden by authorized leader

## Override Policy
- CRITICAL alerts: Can only be overridden by CTO or CEO with documented justification
- HIGH alerts: Can be overridden by department lead with documented justification
- LOW alerts: Can be acknowledged and deferred

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial bot definition |