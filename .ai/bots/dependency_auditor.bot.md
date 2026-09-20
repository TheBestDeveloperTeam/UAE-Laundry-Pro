# Bot: dependency_auditor

## Identity
- Bot ID: LP-BOT-DEPS
- Codename: dependency_auditor
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any pubspec.yaml or composer.json modification

## Action
Verify lock file regenerated, check for known vulnerabilities, verify version constraints are pinned.

## Rules
1. Check lock file updated after dependency change.
2. Run vulnerability scan on new dependencies.
3. Check version uses pinned or caret constraint.
4. If vulnerability found: emit HIGH alert.

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