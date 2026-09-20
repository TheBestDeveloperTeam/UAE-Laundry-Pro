# Escalation Matrix — LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-AGENT-EXEC-ESCALATION  
> **Last Updated:** 2026-09-20  
> **Purpose:** Full matrix defining which agent escalates to whom, under what trigger, with what SLA, and what fallback applies.

---

## Overview

The Escalation Matrix is the definitive authority on how blocked, failed, or conflicting tasks are resolved. Every agent must follow this matrix when it encounters a condition it cannot handle within its own scope and authority.

---

## Escalation Principles

1. **Escalate Up:** Specialists escalate to Department Leads; Department Leads escalate to Leaders.
2. **Escalate Fast:** The SLA defines the maximum prompt-turns before escalation occurs.
3. **Escalate Once:** An agent escalates to exactly one target. If that target also cannot resolve, it escalates further per this matrix.
4. **Escalate with Context:** Every escalation includes the task ID, the reason, the attempted resolution, and the blocker description.
5. **Never Suppress:** An agent must never silently fail. If it cannot resolve, it must escalate.

---

## Escalation Trigger Categories

| Trigger | Code | Description |
|---------|------|-------------|
| Scope Exceeded | `ESC-SCOPE` | Task requires authority beyond the agent's scope |
| Conflict | `ESC-CONFLICT` | Two agents produce contradictory outputs |
| Block | `ESC-BLOCK` | Agent cannot proceed due to missing input or dependency |
| Timeout | `ESC-TIMEOUT` | Agent has not responded within SLA |
| Failure | `ESC-FAILURE` | Agent crashes or produces invalid output |
| Risk Upgrade | `ESC-RISK` | Task risk is higher than the agent's authority level |
| Financial Impact | `ESC-FINANCE` | Decision has financial implications beyond agent's limit |
| Legal Impact | `ESC-LEGAL` | Decision has legal implications |
| Security Impact | `ESC-SECURITY` | Decision has security implications |
| Cross-Department | `ESC-XDEPT` | Task requires coordination across departments |

---

## Full Escalation Matrix

### Engineering Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-ENG-FLUTTER | ESC-SCOPE, ESC-BLOCK | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-FLUTTER | ESC-CONFLICT | LP-AGENT-ENG-LEAD | 2 | LP-AGENT-EXEC-ARCH |
| LP-AGENT-ENG-PHP | ESC-SCOPE, ESC-BLOCK | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-PHP | ESC-SECURITY | LP-AGENT-SEC-LEAD | 2 | LP-AGENT-EXEC-CISO |
| LP-AGENT-ENG-DB | ESC-SCOPE | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-DB | ESC-RISK | LP-AGENT-EXEC-ARCH | 1 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-API | ESC-SCOPE, ESC-BLOCK | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-SYNC | ESC-FAILURE | LP-AGENT-ENG-LEAD | 1 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-SYNC | ESC-RISK | LP-AGENT-EXEC-CTO | 1 | LP-AGENT-EXEC-CEO |
| LP-AGENT-ENG-HW | ESC-BLOCK | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-DEVOPS | ESC-SCOPE | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-MSIX | ESC-BLOCK | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-PERF | ESC-SCOPE | LP-AGENT-ENG-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CTO | 2 | LP-AGENT-EXEC-CEO |
| LP-AGENT-ENG-LEAD | ESC-CONFLICT | LP-AGENT-EXEC-ARCH | 2 | LP-AGENT-EXEC-CTO |
| LP-AGENT-ENG-LEAD | ESC-RISK | LP-AGENT-EXEC-CTO | 1 | LP-AGENT-EXEC-CEO |

### Quality Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-QA-MANUAL | ESC-SCOPE | LP-AGENT-QA-LEAD | 3 | LP-AGENT-EXEC-CQO |
| LP-AGENT-QA-AUTO | ESC-FAILURE | LP-AGENT-QA-LEAD | 2 | LP-AGENT-EXEC-CQO |
| LP-AGENT-QA-REGRESS | ESC-BLOCK | LP-AGENT-QA-LEAD | 3 | LP-AGENT-EXEC-CQO |
| LP-AGENT-QA-EDGE | ESC-SCOPE | LP-AGENT-QA-LEAD | 3 | LP-AGENT-EXEC-CQO |
| LP-AGENT-QA-SECTEST | ESC-SECURITY | LP-AGENT-SEC-LEAD | 1 | LP-AGENT-EXEC-CISO |
| LP-AGENT-QA-A11Y | ESC-SCOPE | LP-AGENT-QA-LEAD | 3 | LP-AGENT-EXEC-CQO |
| LP-AGENT-QA-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CQO | 2 | LP-AGENT-EXEC-CTO |

### Product Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-PROD-PO | ESC-SCOPE | LP-AGENT-PROD-LEAD | 3 | LP-AGENT-EXEC-CPO |
| LP-AGENT-PROD-BA | ESC-BLOCK | LP-AGENT-PROD-LEAD | 3 | LP-AGENT-EXEC-CPO |
| LP-AGENT-PROD-UXR | ESC-SCOPE | LP-AGENT-PROD-LEAD | 3 | LP-AGENT-EXEC-CPO |
| LP-AGENT-PROD-UXD | ESC-CONFLICT | LP-AGENT-PROD-LEAD | 2 | LP-AGENT-EXEC-CPO |
| LP-AGENT-PROD-UID | ESC-SCOPE | LP-AGENT-PROD-LEAD | 3 | LP-AGENT-EXEC-CPO |
| LP-AGENT-PROD-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CPO | 2 | LP-AGENT-EXEC-CEO |

### Data Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-DATA-MODEL | ESC-SCOPE | LP-AGENT-DATA-LEAD | 3 | LP-AGENT-EXEC-CDO |
| LP-AGENT-DATA-ANALYTICS | ESC-BLOCK | LP-AGENT-DATA-LEAD | 3 | LP-AGENT-EXEC-CDO |
| LP-AGENT-DATA-REPORT | ESC-FINANCE | LP-AGENT-FIN-LEAD | 2 | LP-AGENT-EXEC-CFO |
| LP-AGENT-DATA-MIGRATE | ESC-RISK | LP-AGENT-DATA-LEAD | 1 | LP-AGENT-EXEC-CTO |
| LP-AGENT-DATA-BACKUP | ESC-FAILURE | LP-AGENT-DATA-LEAD | 1 | LP-AGENT-EXEC-CTO |
| LP-AGENT-DATA-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CDO | 2 | LP-AGENT-EXEC-CTO |

### Operations Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-OPS-L1 | ESC-SCOPE | LP-AGENT-OPS-L2 | 2 | LP-AGENT-OPS-LEAD |
| LP-AGENT-OPS-L2 | ESC-SCOPE | LP-AGENT-OPS-L3 | 2 | LP-AGENT-OPS-LEAD |
| LP-AGENT-OPS-L3 | ESC-SCOPE | LP-AGENT-OPS-LEAD | 2 | LP-AGENT-EXEC-COO |
| LP-AGENT-OPS-DEPLOY | ESC-FAILURE | LP-AGENT-OPS-LEAD | 1 | LP-AGENT-EXEC-COO |
| LP-AGENT-OPS-TRAIN | ESC-SCOPE | LP-AGENT-OPS-LEAD | 3 | LP-AGENT-EXEC-COO |
| LP-AGENT-OPS-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-COO | 2 | LP-AGENT-EXEC-CEO |

### Security Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-SEC-APPSEC | ESC-SCOPE | LP-AGENT-SEC-LEAD | 2 | LP-AGENT-EXEC-CISO |
| LP-AGENT-SEC-UMAC | ESC-RISK | LP-AGENT-SEC-LEAD | 1 | LP-AGENT-EXEC-CISO |
| LP-AGENT-SEC-AUDIT | ESC-SCOPE | LP-AGENT-SEC-LEAD | 2 | LP-AGENT-EXEC-CISO |
| LP-AGENT-SEC-COMPLY | ESC-LEGAL | LP-AGENT-EXEC-LEGAL | 1 | LP-AGENT-EXEC-CEO |
| LP-AGENT-SEC-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CISO | 2 | LP-AGENT-EXEC-CEO |

### HR Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-HR-PAYROLL | ESC-FINANCE | LP-AGENT-FIN-LEAD | 2 | LP-AGENT-EXEC-CFO |
| LP-AGENT-HR-PAYROLL | ESC-LEGAL | LP-AGENT-EXEC-LEGAL | 1 | LP-AGENT-EXEC-CEO |
| LP-AGENT-HR-ATTEND | ESC-SCOPE | LP-AGENT-HR-LEAD | 3 | LP-AGENT-EXEC-CHRO |
| LP-AGENT-HR-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CHRO | 2 | LP-AGENT-EXEC-CEO |

### Finance Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-FIN-BILLING | ESC-SCOPE | LP-AGENT-FIN-LEAD | 2 | LP-AGENT-EXEC-CFO |
| LP-AGENT-FIN-VAT | ESC-LEGAL | LP-AGENT-EXEC-LEGAL | 1 | LP-AGENT-EXEC-CEO |
| LP-AGENT-FIN-CURRENCY | ESC-SCOPE | LP-AGENT-FIN-LEAD | 3 | LP-AGENT-EXEC-CFO |
| LP-AGENT-FIN-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CFO | 2 | LP-AGENT-EXEC-CEO |

### Marketing Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-MKT-BRAND | ESC-SCOPE | LP-AGENT-MKT-LEAD | 3 | LP-AGENT-EXEC-CRO |
| LP-AGENT-MKT-CONTENT | ESC-SCOPE | LP-AGENT-MKT-LEAD | 3 | LP-AGENT-EXEC-CRO |
| LP-AGENT-MKT-SEO | ESC-SCOPE | LP-AGENT-MKT-LEAD | 3 | LP-AGENT-EXEC-CRO |
| LP-AGENT-MKT-ADVOCATE | ESC-SCOPE | LP-AGENT-MKT-LEAD | 3 | LP-AGENT-EXEC-CRO |
| LP-AGENT-MKT-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CRO | 2 | LP-AGENT-EXEC-CEO |

### Legal Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-LEG-CONTRACTS | ESC-SCOPE | LP-AGENT-LEG-LEAD | 2 | LP-AGENT-EXEC-LEGAL |
| LP-AGENT-LEG-PRIVACY | ESC-SCOPE | LP-AGENT-LEG-LEAD | 2 | LP-AGENT-EXEC-LEGAL |
| LP-AGENT-LEG-LEAD | ESC-SCOPE | LP-AGENT-EXEC-LEGAL | 1 | LP-AGENT-EXEC-CEO |

### R&D Department

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-RND-INNOVATE | ESC-SCOPE | LP-AGENT-RND-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-RND-CLOUD | ESC-SCOPE | LP-AGENT-RND-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-RND-MOBILE | ESC-SCOPE | LP-AGENT-RND-LEAD | 3 | LP-AGENT-EXEC-CTO |
| LP-AGENT-RND-LEAD | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CTO | 2 | LP-AGENT-EXEC-CEO |

### Leaders

| Agent | Trigger | Escalates To | SLA (turns) | Fallback |
|-------|---------|-------------|-------------|----------|
| LP-AGENT-EXEC-CTO | ESC-SCOPE, ESC-XDEPT | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-CFO | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-COO | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-CISO | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-CDO | ESC-SCOPE | LP-AGENT-EXEC-CTO | 1 | LP-AGENT-EXEC-CEO |
| LP-AGENT-EXEC-CPO | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-CQO | ESC-SCOPE | LP-AGENT-EXEC-CTO | 1 | LP-AGENT-EXEC-CEO |
| LP-AGENT-EXEC-CHRO | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-CRO | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-LEGAL | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-ARCH | ESC-CONFLICT | LP-AGENT-EXEC-CTO | 1 | LP-AGENT-EXEC-CEO |
| LP-AGENT-EXEC-PM | ESC-SCOPE | LP-AGENT-EXEC-CEO | 1 | LP-AGENT-EXEC-ESCALATION |
| LP-AGENT-EXEC-CEO | ESC-SCOPE | LP-AGENT-EXEC-ESCALATION | 1 | HALT (developer intervention) |
| LP-AGENT-EXEC-ESCALATION | (terminal) | HALT | 0 | Developer intervention required |

---

## Escalation Message Format

Every escalation must include:

```markdown
## Escalation: <ESCALATION-ID>
- **From:** <agent-id>
- **To:** <target-agent-id>
- **Task ID:** <task-id>
- **Chain ID:** <chain-id>
- **Trigger:** <trigger-code>
- **Reason:** <free-text explanation>
- **Attempted Resolution:** <what the agent tried before escalating>
- **Blocker:** <specific blocker description>
- **Timestamp:** <ISO 8601>
- **SLA Remaining:** <prompt-turns before fallback>
```

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial escalation matrix — all agents covered |
