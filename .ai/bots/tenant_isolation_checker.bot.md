# Bot: tenant_isolation_checker

## Identity
- Bot ID: LP-BOT-TENANT
- Codename: tenant_isolation_checker
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any SQL query or mutation on data tables (SELECT, INSERT, UPDATE, DELETE)

## Action
Verify WHERE clause includes business_owner_id filter (or table is system-scoped). If missing: BLOCK and alert SEC-LEAD.

## Rules
1. Parse SQL for data table references.
2. Check if business_owner_id is in WHERE clause.
3. Exempt system tables: system_settings, migrations, audit_logs_global.
4. If missing: emit CRITICAL alert.

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