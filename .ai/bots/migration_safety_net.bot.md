# Bot: migration_safety_net

## Identity
- Bot ID: LP-BOT-MIGRATE
- Codename: migration_safety_net
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any DDL statement or migration script execution

## Action
Verify pre-execution backup exists, rollback script defined, migration is idempotent (IF NOT EXISTS / IF EXISTS). If missing: BLOCK.

## Rules
1. Check backup timestamp < 1 hour old.
2. Check rollback script exists in migrations/rollback/.
3. Check DDL uses IF NOT EXISTS / IF EXISTS.
4. Check no DROP TABLE without explicit approval.
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