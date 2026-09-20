# Bot: sync_watchdog

## Identity
- Bot ID: LP-BOT-SYNC
- Codename: sync_watchdog
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any sync outbox entry creation, push/pull operation, or conflict resolution

## Action
Verify idempotency key present, sequence number assigned, business_owner_id scoped, retry count within limits. If violation: BLOCK.

## Rules
1. Check sync entry has idempotency_key (UUID).
2. Check sync entry has sequence_number.
3. Check sync entry scoped to business_owner_id.
4. Check retry_count <= max_retries (default 10).
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