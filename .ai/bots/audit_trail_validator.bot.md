# Bot: audit_trail_validator

## Identity
- Bot ID: LP-BOT-AUDIT
- Codename: audit_trail_validator
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any INSERT, UPDATE, DELETE, or state-changing API call

## Action
Verify corresponding audit_logs entry is created with: user_id, action, entity, entity_id, old_value, new_value, ip_address, timestamp.

## Rules
1. Check audit_logs INSERT follows state change.
2. Check all required fields populated.
3. Check timestamp is UTC.
4. If missing: emit HIGH alert.

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