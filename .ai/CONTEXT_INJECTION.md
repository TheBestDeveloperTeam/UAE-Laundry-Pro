# Context Injection — LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-BOT-CONTEXT-LOADER  
> **Last Updated:** 2026-09-20  
> **Purpose:** Defines exactly which files are loaded into context when each agent or bot activates.

---

## Overview

Context Injection ensures every agent has the knowledge it needs to execute correctly. Files are loaded in a specific order to establish a layered context: global rules first, then domain knowledge, then agent-specific contracts.

---

## Global Context (Always Loaded)

These files are loaded for **every** task, regardless of category:

| Priority | File | Purpose |
|----------|------|---------|
| 1 | `.ai/ORCHESTRATOR.md` | Core orchestration rules |
| 2 | `.ai/ROUTING_TABLE.md` | Task routing reference |
| 3 | `.ai/ESCALATION_MATRIX.md` | Escalation paths |
| 4 | `.ai/memory/working.md` | Current working memory |
| 5 | `.ai/memory/short_term.md` | Recent memory (7-day window) |

---

## Domain Context (Loaded Per Classification)

Based on the domains identified by `prompt_router.bot`, the following knowledge files are loaded:

| Domain | Knowledge Files |
|--------|----------------|
| sales | `knowledge/domain_laundry.md`, `knowledge/pattern_zero_float_money.md`, `knowledge/pattern_immutable_invoice.md` |
| inventory | `knowledge/domain_laundry.md`, `knowledge/pattern_zero_float_money.md` |
| production | `knowledge/domain_laundry.md`, `knowledge/domain_dry_cleaning.md` |
| delivery | `knowledge/domain_laundry.md` |
| hr | `knowledge/domain_uae_regulations.md` |
| payroll | `knowledge/domain_uae_regulations.md`, `knowledge/pattern_zero_float_money.md` |
| finance | `knowledge/pattern_zero_float_money.md`, `knowledge/pattern_immutable_invoice.md`, `knowledge/pattern_audit_logging.md` |
| tax | `knowledge/domain_uae_regulations.md`, `knowledge/pattern_zero_float_money.md` |
| licensing | `knowledge/pattern_umac_licensing.md` |
| security | `knowledge/pattern_rbac_scopes.md`, `knowledge/protocol_oauth2.md`, `knowledge/protocol_jwt.md` |
| sync | `knowledge/protocol_sync_outbox.md`, `knowledge/pattern_offline_first.md`, `knowledge/pattern_zero_data_loss.md` |
| hardware | `knowledge/protocol_escpos.md`, `knowledge/protocol_rfid_uhf.md` |
| ui | `knowledge/stack_flutter.md`, `knowledge/pattern_localization_ltr_rtl.md`, `knowledge/pattern_mvvm.md` |
| api | `knowledge/stack_php82.md`, `knowledge/pattern_clean_architecture.md` |
| database | `knowledge/stack_mariadb.md`, `knowledge/pattern_multi_tenant.md` |
| reporting | `knowledge/pattern_zero_float_money.md`, `knowledge/pattern_audit_logging.md` |
| backup | `knowledge/pattern_zero_data_loss.md` |
| legal | `knowledge/domain_uae_regulations.md`, `knowledge/domain_ksa_regulations.md` |
| marketing | `knowledge/domain_laundry.md` |
| localization | `knowledge/pattern_localization_ltr_rtl.md` |
| architecture | `knowledge/pattern_clean_architecture.md`, `knowledge/pattern_mvvm.md`, `knowledge/pattern_multi_tenant.md`, `knowledge/pattern_offline_first.md` |
| devops | `knowledge/stack_xampp.md`, `knowledge/stack_msix.md` |
| testing | `knowledge/stack_flutter.md`, `knowledge/stack_php82.md` |
| documentation | (no additional knowledge files) |

---

## Agent-Specific Context

Each agent has a `Context Injection Contract` section in its `.agent.md` file listing additional files to load. The following is a summary by department:

### Leaders

| Agent | Additional Context Files |
|-------|------------------------|
| CEO | All department README.md files, `registries/agent_registry.md`, `registries/capability_matrix.md` |
| CTO | All engineering agent files, `registries/skill_matrix.md`, `protocols/review.protocol.md` |
| CFO | All finance agent files, `knowledge/domain_uae_regulations.md`, `knowledge/pattern_zero_float_money.md` |
| COO | All operations agent files, `protocols/escalation.protocol.md` |
| CISO | All security agent files, `knowledge/pattern_rbac_scopes.md`, `knowledge/pattern_umac_licensing.md` |
| CDO | All data agent files, `knowledge/pattern_zero_data_loss.md` |
| CPO | All product agent files, `knowledge/pattern_localization_ltr_rtl.md` |
| CQO | All quality agent files, `protocols/review.protocol.md` |
| CHRO | All HR agent files, `knowledge/domain_uae_regulations.md` |
| CRO | All marketing agent files |
| Legal Counsel | All legal agent files, `knowledge/domain_uae_regulations.md`, `knowledge/domain_ksa_regulations.md` |
| Chief Architect | All knowledge/pattern_*.md files, all knowledge/stack_*.md files |
| Program Manager | `registries/agent_registry.md`, `registries/capability_matrix.md`, `memory/long_term.md` |
| Escalation Leader | `ESCALATION_MATRIX.md`, `protocols/escalation.protocol.md`, `protocols/conflict.protocol.md` |

### Engineering Department

| Agent | Additional Context Files |
|-------|------------------------|
| Dept Lead | All engineering agent files within the department |
| Flutter | `knowledge/stack_flutter.md`, `knowledge/pattern_mvvm.md` |
| PHP | `knowledge/stack_php82.md`, `knowledge/pattern_clean_architecture.md` |
| Database | `knowledge/stack_mariadb.md`, `knowledge/pattern_multi_tenant.md` |
| API Design | `knowledge/stack_php82.md`, `knowledge/protocol_jwt.md` |
| Sync Engine | `knowledge/protocol_sync_outbox.md`, `knowledge/pattern_offline_first.md` |
| Hardware | `knowledge/protocol_escpos.md`, `knowledge/protocol_rfid_uhf.md` |
| DevOps | `knowledge/stack_xampp.md`, `knowledge/stack_msix.md` |
| MSIX Packaging | `knowledge/stack_msix.md`, `knowledge/stack_flutter.md` |
| Performance | `knowledge/stack_flutter.md`, `knowledge/stack_php82.md`, `knowledge/stack_mariadb.md` |

### Quality Department

| Agent | Additional Context Files |
|-------|------------------------|
| Dept Lead | All quality agent files within the department |
| QA Manual | `protocols/review.protocol.md` |
| QA Automation | `knowledge/stack_flutter.md`, `knowledge/stack_php82.md` |
| Regression | `memory/long_term.md` (regression history) |
| Edge Case Hunter | `memory/episodic.md` (past edge cases) |
| Security Tester | `knowledge/pattern_rbac_scopes.md`, `knowledge/protocol_oauth2.md` |
| Accessibility | `knowledge/pattern_localization_ltr_rtl.md` |

### Finance Department

| Agent | Additional Context Files |
|-------|------------------------|
| Dept Lead | All finance agent files within the department |
| Billing | `knowledge/pattern_zero_float_money.md`, `knowledge/pattern_immutable_invoice.md` |
| VAT/Tax | `knowledge/domain_uae_regulations.md`, `knowledge/pattern_zero_float_money.md` |
| Multi-Currency | `knowledge/pattern_zero_float_money.md` |

### Security Department

| Agent | Additional Context Files |
|-------|------------------------|
| Dept Lead | All security agent files within the department |
| AppSec | `knowledge/pattern_rbac_scopes.md`, `knowledge/protocol_oauth2.md`, `knowledge/protocol_jwt.md` |
| License/UMAC | `knowledge/pattern_umac_licensing.md` |
| Audit | `knowledge/pattern_audit_logging.md` |
| UAE Compliance | `knowledge/domain_uae_regulations.md`, `knowledge/domain_ksa_regulations.md` |

---

## Context Loading Order

Files are loaded in this exact order to ensure proper context layering:

1. **Global context** (ORCHESTRATOR, ROUTING_TABLE, ESCALATION_MATRIX)
2. **Memory files** (working, short_term)
3. **Knowledge files** (domain-specific, from `Domain Context` table above)
4. **Protocol files** (from `ROUTING_TABLE.md` for the current category)
5. **Agent files** (from the resolved agent chain, in chain order)
6. **Bot files** (from the resolved bot list)
7. **Agent-specific context** (from each agent's `Context Injection Contract`)

---

## Context Size Limits

| Context Layer | Max Files | Max Total Size |
|--------------|-----------|---------------|
| Global | 5 | 50KB |
| Memory | 2 | 100KB |
| Knowledge | 10 | 200KB |
| Protocols | 3 | 30KB |
| Agents | 10 | 200KB |
| Bots | 5 | 50KB |
| Agent-specific | 10 | 100KB |
| **Total** | **45** | **730KB** |

If context exceeds limits, `context_loader.bot` applies these rules:
1. Global and memory files are never trimmed.
2. Knowledge files are prioritized by domain relevance (primary domain first).
3. Agent files are prioritized by chain position (lead first).
4. Bot files are prioritized by mandatory status.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial context injection specification |
