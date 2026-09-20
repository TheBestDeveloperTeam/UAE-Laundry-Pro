# Bot: i18n_auditor

## Identity
- Bot ID: LP-BOT-I18N
- Codename: i18n_auditor
- Type: Sentinel Bot (always-on)
- Version: 1.0.0
- Status: active

## Trigger
Any hardcoded UI string in Dart widgets or any locale file modification

## Action
Verify every displayed string uses a locale key. Verify key exists in both en.json and ar.json. If violation: BLOCK.

## Rules
1. Scan Dart files for Text('...') with literal strings.
2. Check locale key exists in lib/l10n/en.json.
3. Check locale key exists in lib/l10n/ar.json.
4. If missing: emit HIGH alert with suggested key name.

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