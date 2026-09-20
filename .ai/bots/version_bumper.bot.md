# Bot: version_bumper

## Identity
- Bot ID: LP-BOT-VERSION
- Codename: version_bumper
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any release, packaging, or MSIX build task

## Action
Verify version has been bumped in pubspec.yaml, msix_config.yaml, and CHANGELOG.md. If not bumped: BLOCK.

## Rules
1. Compare current version to last release tag.
2. Check pubspec.yaml version field.
3. Check msix_config.yaml version field.
4. Check CHANGELOG.md has entry for new version.
5. If not bumped: emit HIGH alert.

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