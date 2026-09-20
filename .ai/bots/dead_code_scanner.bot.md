# Bot: dead_code_scanner

## Identity
- Bot ID: LP-BOT-DEADCODE
- Codename: dead_code_scanner
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any code deletion, refactoring, or file removal

## Action
Scan for orphaned imports, unused variables, unreferenced classes, and dead code paths. Report findings.

## Rules
1. Run static analysis for unused imports.
2. Check for unreferenced public classes.
3. Check for TODO/FIXME markers older than 2 sprints.
4. Report as LOW severity unless blocking build.

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