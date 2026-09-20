# Routing Table — LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-BOT-PROMPT-ROUTER  
> **Last Updated:** 2026-09-20  
> **Purpose:** Deterministic mapping from task category to agent chain and bot invocations.

---

## How to Use This Table

1. `prompt_router.bot` classifies incoming prompt into a **Task Category**.
2. Look up the category in the table below.
3. The **Primary Agent Chain** is activated in order (first = lead, last = executor).
4. The **Bots Invoked** are activated concurrently alongside the agent chain.
5. The **Leader Sign-off** column indicates whether a leader must approve before the task is considered complete.
6. The **Risk Level** determines the escalation SLA.

---

## Master Routing Table

| # | Task Category | Risk | Primary Agent Chain | Bots Invoked | Leader Sign-off | Notes |
|---|--------------|------|---------------------|-------------|----------------|-------|
| 1 | Feature Request | MEDIUM | CPO → PROD-LEAD → PROD-PO → PROD-BA → ENG-LEAD → (relevant specialist) | doc_generator, changelog_bot | CPO | BA writes spec, ENG implements |
| 2 | Bug Report | MEDIUM | CTO → ENG-LEAD → (relevant specialist) → QA-LEAD | error_triage, test_runner, lint_bot | CTO (if HIGH) | Specialist depends on bug domain |
| 3 | Database Migration | HIGH | CTO → ARCH → ENG-LEAD → ENG-DB → DATA-LEAD → DATA-MIGRATE | migration_bot, db_integrity, backup_bot | CTO + ARCH | Always backup before migrate |
| 4 | API Change | MEDIUM | CTO → ARCH → ENG-LEAD → ENG-API → ENG-PHP | lint_bot, test_runner, doc_generator | ARCH | Must update API docs |
| 5 | UI/UX Change | MEDIUM | CPO → PROD-LEAD → PROD-UXD → PROD-UID → ENG-LEAD → ENG-FLUTTER | i18n_auditor, lint_bot | CPO | Must handle LTR/RTL |
| 6 | Localization Change | LOW | CPO → PROD-LEAD → PROD-UID → ENG-FLUTTER | i18n_auditor | CPO | Validate all locale files |
| 7 | Security Review | HIGH | CISO → SEC-LEAD → SEC-APPSEC → (relevant dept lead) | rbac_guard, dependency_auditor, lint_bot | CISO | Cross-department scan |
| 8 | License/UMAC Change | CRITICAL | CEO → CISO → SEC-LEAD → SEC-UMAC → ENG-LEAD → ENG-PHP | license_guard, db_integrity | CEO + CISO | Business-critical; dual sign-off |
| 9 | Sync Engine Change | HIGH | CTO → ARCH → ENG-LEAD → ENG-SYNC → ENG-DB | sync_watchdog, db_integrity, test_runner | CTO + ARCH | Data loss risk |
| 10 | Hardware Integration Change | MEDIUM | CTO → ENG-LEAD → ENG-HW → QA-LEAD → QA-MANUAL | printer_probe, scanner_probe, hardware_health | CTO | Must test with real hardware |
| 11 | Report Change | MEDIUM | CFO → DATA-LEAD → DATA-REPORT → DATA-ANALYTICS → ENG-PHP | money_precision_guard, test_runner | CFO | Financial accuracy required |
| 12 | Payroll/HR Change | HIGH | COO → CHRO → HR-LEAD → HR-PAYROLL → HR-ATTEND → FIN-LEAD | money_precision_guard, audit_trail | CFO + CHRO | UAE labour law compliance |
| 13 | Finance/Tax Change | CRITICAL | CFO → FIN-LEAD → FIN-VAT → FIN-BILLING → SEC-COMPLY | money_precision_guard, audit_trail, db_integrity | CEO + CFO | FTA compliance required |
| 14 | Legal/Contract Change | HIGH | CEO → LEGAL → LEG-LEAD → LEG-CONTRACTS | audit_trail, doc_generator | CEO | Legal review mandatory |
| 15 | Marketing/Positioning Change | LOW | CRO → MKT-LEAD → MKT-BRAND → MKT-CONTENT | doc_generator | CRO | Brand consistency check |
| 16 | Documentation Change | LOW | CPO → PROD-LEAD → PROD-BA | doc_generator, changelog_bot | None | Self-service for specialists |
| 17 | Release/Packaging | HIGH | CTO → ENG-LEAD → ENG-DEVOPS → ENG-MSIX → QA-LEAD → QA-REGRESS | version_bumper, changelog_bot, test_runner, lint_bot, backup_bot | CTO + CEO | Full regression before release |
| 18 | Incident Response | CRITICAL | CEO → COO → OPS-LEAD → OPS-L1 → OPS-L2 → OPS-L3 | error_triage, audit_trail, backup_bot | CEO + COO | Follow incident_playbook |
| 19 | Disaster Recovery | CRITICAL | CEO → COO → OPS-LEAD → DATA-LEAD → DATA-BACKUP → ENG-DB | backup_bot, db_integrity, sync_watchdog | CEO + COO + CTO | Follow disaster_playbook |
| 20 | Multi-Tenant Onboarding | HIGH | CEO → COO → OPS-LEAD → OPS-DEPLOY → SEC-LEAD → SEC-UMAC → ENG-DB | license_guard, db_integrity, backup_bot | CEO + COO | New business_owner_id provisioning |

---

## Secondary Routing Rules

### Multi-Domain Tasks

When a task spans multiple categories, the Orchestrator:

1. Identifies the **highest-risk** category as the primary route.
2. Activates **all** agent chains for all matched categories.
3. Designates the **highest-tier leader** across all chains as the task owner.
4. Uses `conflict_resolver.bot` if agent chains produce contradictory outputs.

### Ambiguous Classification

When `prompt_router.bot` cannot determine a single category:

1. Classify as risk `MEDIUM` (default).
2. Route to `LP-AGENT-EXEC-PM` (Program Manager) for manual classification.
3. PM re-routes to the correct category.
4. If PM cannot classify, escalate to `LP-AGENT-EXEC-CTO`.

### Unrecognized Tasks

When a task matches no category:

1. Route to `LP-AGENT-EXEC-PM`.
2. PM determines if this is a new category (create entry in routing table) or an edge case of an existing category.
3. Log to `.ai/logs/decisions.log.md` with rationale.

---

## Domain → Agent Mapping Quick Reference

| Domain | Primary Agent | Department |
|--------|--------------|------------|
| sales | LP-AGENT-FIN-BILLING | Finance |
| inventory | LP-AGENT-ENG-PHP | Engineering |
| production | LP-AGENT-ENG-PHP | Engineering |
| delivery | LP-AGENT-OPS-DEPLOY | Operations |
| hr | LP-AGENT-HR-LEAD | HR |
| payroll | LP-AGENT-HR-PAYROLL | HR |
| finance | LP-AGENT-FIN-LEAD | Finance |
| tax | LP-AGENT-FIN-VAT | Finance |
| licensing | LP-AGENT-SEC-UMAC | Security |
| security | LP-AGENT-SEC-LEAD | Security |
| sync | LP-AGENT-ENG-SYNC | Engineering |
| hardware | LP-AGENT-ENG-HW | Engineering |
| ui | LP-AGENT-ENG-FLUTTER | Engineering |
| api | LP-AGENT-ENG-API | Engineering |
| database | LP-AGENT-ENG-DB | Engineering |
| reporting | LP-AGENT-DATA-REPORT | Data |
| backup | LP-AGENT-DATA-BACKUP | Data |
| legal | LP-AGENT-LEG-LEAD | Legal |
| marketing | LP-AGENT-MKT-LEAD | Marketing |
| localization | LP-AGENT-PROD-UID | Product |
| architecture | LP-AGENT-EXEC-ARCH | Leadership |
| devops | LP-AGENT-ENG-DEVOPS | Engineering |
| testing | LP-AGENT-QA-LEAD | Quality |
| documentation | LP-AGENT-PROD-BA | Product |

---

## Bot Activation Rules

| Bot | Activated When | Mandatory For |
|-----|---------------|---------------|
| prompt_router | Every prompt | All tasks |
| context_loader | Every prompt | All tasks |
| memory_writer | Every prompt | All tasks |
| audit_trail | Every prompt | All tasks |
| escalation_bot | Risk ≥ MEDIUM | All MEDIUM+ tasks |
| lint_bot | Code change detected | Engineering tasks |
| test_runner | Code change detected | Engineering tasks |
| money_precision_guard | Financial data touched | Finance, Sales, Payroll |
| rbac_guard | Permission change detected | Security tasks |
| license_guard | License data touched | Licensing tasks |
| db_integrity | Schema change detected | Database tasks |
| backup_bot | Before destructive operations | Migration, Recovery |
| sync_watchdog | Sync-related change | Sync tasks |
| i18n_auditor | UI string change detected | Localization, UI tasks |
| migration_bot | Schema change requested | Database migration |
| printer_probe | Printer config change | Hardware tasks |
| scanner_probe | Scanner config change | Hardware tasks |
| hardware_health | Hardware status check | Hardware tasks |
| changelog_bot | Any change merged | All completed tasks |
| version_bumper | Release requested | Release tasks |
| doc_generator | Documentation change | Documentation tasks |
| dependency_auditor | Dependency change | Security review |
| performance_probe | Performance concern | Performance tasks |
| error_triage | Error reported | Bug reports, Incidents |
| conflict_resolver | Agent conflict detected | Multi-domain tasks |

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial routing table with 20 task categories |
