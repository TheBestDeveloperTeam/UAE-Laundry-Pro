# Bots - LaundryPro UAE Agent Ecosystem
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Overview
Bots are autonomous, always-on sentinel agents that monitor system invariants and fire alerts when violations are detected. Unlike agents (reactive, prompt-driven), bots run passively on every applicable context.

## Bot Roster
| Bot ID | Trigger | Purpose |
|--------|---------|---------|
| money_precision_guard | Any FLOAT/DOUBLE near monetary context | Enforce DECIMAL(18,2) |
| tenant_isolation_checker | Any query/mutation on data tables | Verify business_owner_id present |
| i18n_auditor | Any UI string addition or modification | Verify locale key exists in en.json and ar.json |
| sync_watchdog | Any sync outbox or push/pull operation | Verify idempotency, sequence, tenant isolation |
| migration_safety_net | Any DDL or migration script | Verify backup exists, rollback defined, idempotent |
| rbac_enforcer | Any API route addition or modification | Verify PermissionChecker middleware applied |
| audit_trail_validator | Any state-changing operation | Verify audit log entry created |
| version_bumper | Any release or packaging task | Verify SemVer bump applied |
| dead_code_scanner | Any code deletion or refactor | Detect orphaned code and unused imports |
| dependency_auditor | Any dependency addition or update | Verify lock file updated, no known vulnerabilities |