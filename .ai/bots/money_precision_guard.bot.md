# Bot: money_precision_guard

## Identity
- Bot ID: LP-BOT-MONEY
- Codename: money_precision_guard
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any code containing FLOAT, DOUBLE, float, double near monetary/price/amount/cost/salary/total/subtotal/tax/discount/balance/payment context

## Action
BLOCK the change. Require DECIMAL(18,2) in MariaDB, bcmath in PHP, and proper Dart decimal handling. Alert: CFO, ENG-DB.

## Rules
1. Scan all SQL for FLOAT/DOUBLE on monetary columns.
2. Scan PHP for float arithmetic on money.
3. Scan Dart for double on monetary display.
4. If found: emit CRITICAL alert with file, line, column.
5. Suggest fix: DECIMAL(18,2) / bcmath / Decimal package.

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