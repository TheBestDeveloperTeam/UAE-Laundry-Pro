# `.ai/` — LaundryPro UAE Agent & Bot Ecosystem

> **Version:** 1.0.0  
> **Owner:** Magnificent Solution  
> **Last Updated:** 2026-09-20  
> **Status:** Active  

---

## Purpose

This directory contains the **complete, self-contained, offline-capable agent and bot ecosystem** for the LaundryPro UAE project. It simulates an entire software company's organizational structure — from C-suite leadership to individual specialist agents and automated bots — all operating locally without any external AI API dependency.

Every agent and bot is:

- **Locally stored** as Markdown (`.md`) files
- **Hierarchically organized** (Leaders → Department Leads → Specialists → Bots)
- **Self-describing and self-referencing** with stable identifiers
- **Idempotently activated** on every prompt via the Activation Protocol
- **Domain-faithful** to LaundryPro UAE's constraints (offline-first, zero-float money, RBAC, sync outbox, UMAC, tenant isolation, LTR/RTL, MSIX, XAMPP, PHP 8.2, MariaDB 10.4, Flutter ≥3.3, Riverpod, SQLite local, SHA-256 backups)

---

## Directory Structure

```
.ai/
├── README.md                    ← You are here
├── MANIFEST.md                  ← Machine-readable file registry
├── ORCHESTRATOR.md              ← Central orchestration rules
├── ROUTING_TABLE.md             ← Task → agent chain → bot mapping
├── ACTIVATION_PROTOCOL.md       ← 9-step prompt activation sequence
├── CONTEXT_INJECTION.md         ← Files loaded per agent activation
├── MEMORY_PERSISTENCE.md        ← Memory file formats, retention, encryption
├── ESCALATION_MATRIX.md         ← Agent escalation paths and SLAs
├── FAILURE_RECOVERY.md          ← Recovery from 8 failure modes
├── AUDIT_LOG_SPEC.md            ← Log schema specification
│
├── leaders/                     ← C-suite and executive agents (14 agents)
│   ├── ceo.agent.md
│   ├── cto.agent.md
│   ├── cfo.agent.md
│   ├── coo.agent.md
│   ├── ciso.agent.md
│   ├── cdo.agent.md
│   ├── cpo.agent.md
│   ├── cqo.agent.md
│   ├── chro.agent.md
│   ├── cro.agent.md
│   ├── legal_counsel.agent.md
│   ├── chief_architect.agent.md
│   ├── program_manager.agent.md
│   └── escalation_leader.agent.md
│
├── departments/                 ← 12 departments, each with lead + specialists
│   ├── engineering/             (10 agents)
│   ├── quality/                 (7 agents)
│   ├── product/                 (6 agents)
│   ├── data/                    (6 agents)
│   ├── operations/              (6 agents)
│   ├── security/                (5 agents)
│   ├── hr/                      (3 agents)
│   ├── finance/                 (4 agents)
│   ├── marketing/               (5 agents)
│   ├── legal/                   (3 agents)
│   └── rnd/                     (4 agents)
│
├── bots/                        ← 25 automated bots
│   ├── lint_bot.bot.md
│   ├── test_runner.bot.md
│   ├── ... (25 total)
│   └── escalation_bot.bot.md
│
├── knowledge/                   ← 26 domain knowledge files
│   ├── domain_laundry.md
│   ├── stack_flutter.md
│   ├── pattern_zero_float_money.md
│   └── ... (26 total)
│
├── protocols/                   ← 10 operational protocol definitions
│   ├── activation.protocol.md
│   ├── delegation.protocol.md
│   └── ... (10 total)
│
├── memory/                      ← 6 memory persistence layers
│   ├── short_term.md
│   ├── long_term.md
│   └── ... (6 total)
│
├── registries/                  ← 6 capability/permission registries
│   ├── agent_registry.md
│   ├── bot_registry.md
│   └── ... (6 total)
│
└── logs/                        ← 5 structured log files
    ├── activation.log.md
    ├── decisions.log.md
    └── ... (5 total)
```

---

## How It Works

### Activation Flow (Every Prompt)

1. **`prompt_router.bot`** classifies the incoming prompt (domain, risk tier, category)
2. **`context_loader.bot`** loads `ORCHESTRATOR.md`, `ROUTING_TABLE.md`, and the matched agent chain
3. All matched agents are marked `active` for the task duration
4. **`memory_writer.bot`** opens a working memory session
5. **`audit_trail.bot`** begins logging
6. Agents execute per `delegation.protocol.md`
7. **`escalation_bot`** monitors for blocks or failures
8. On completion, `memory_writer.bot` persists episodic + semantic memory
9. `audit_trail.bot` closes the session with final hashes

### Agent Hierarchy

```
CEO ─────────────────────────────── Ultimate authority
├── CTO ──── Engineering, Quality, Data, R&D
├── CFO ──── Finance
├── COO ──── Operations
├── CISO ─── Security
├── CDO ──── Data (shared with CTO)
├── CPO ──── Product
├── CQO ──── Quality (shared with CTO)
├── CHRO ─── HR
├── CRO ──── Marketing (Revenue)
├── Legal Counsel ── Legal
├── Chief Architect ── cross-cutting technical authority
├── Program Manager ── cross-cutting delivery authority
└── Escalation Leader ── cross-cutting conflict resolution
```

### Key Identifiers

- **Agent IDs**: `LP-AGENT-{DEPT}-{ROLE}` (e.g., `LP-AGENT-ENG-LEAD`)
- **Bot IDs**: `LP-BOT-{NAME}` (e.g., `LP-BOT-LINT`)
- **Task IDs**: `LP-TASK-{YYYYMMDD}-{SEQ}` (e.g., `LP-TASK-20260920-001`)
- **Chain IDs**: `LP-CHAIN-{TASK_ID}-{SEQ}` (e.g., `LP-CHAIN-20260920-001-01`)

---

## Domain Rules (Inherited by All Agents)

Every agent and bot in this ecosystem inherits these immutable domain rules:

| Rule | Enforcement |
|------|------------|
| Zero-float money | All monetary values use `DECIMAL(18,2)` — never floating-point |
| Immutable invoices | Posted invoices are never updated — use correction memos |
| Append-only inventory | Inventory movements are never deleted — soft-delete only |
| Offline-first | Local MariaDB is source of truth; cloud sync is optional |
| RBAC enforcement | All permissions checked server-side by PHP middleware |
| Sync outbox | All writes go to sync outbox table for eventual cloud push |
| UMAC licensing | Machine-bound licensing via physical address hash |
| Tenant isolation | All data scoped by `business_owner_id` — no cross-tenant leaks |
| LTR/RTL support | All UI supports English (LTR) and Arabic (RTL) |
| Audit logging | Every state transition is permission-controlled and logged |
| Idempotency | All write APIs accept `X-Idempotency-Key` header |
| Document numbering | All document numbers are server-side atomic (never client-generated) |

---

## Quick Reference

| Need | Go To |
|------|-------|
| Understand the orchestration | [ORCHESTRATOR.md](ORCHESTRATOR.md) |
| Route a task to agents | [ROUTING_TABLE.md](ROUTING_TABLE.md) |
| Understand activation | [ACTIVATION_PROTOCOL.md](ACTIVATION_PROTOCOL.md) |
| Find an agent | [registries/agent_registry.md](registries/agent_registry.md) |
| Find a bot | [registries/bot_registry.md](registries/bot_registry.md) |
| Learn domain rules | [knowledge/](knowledge/) |
| Read protocols | [protocols/](protocols/) |
| Check memory state | [memory/](memory/) |
| Review logs | [logs/](logs/) |
| Escalate an issue | [ESCALATION_MATRIX.md](ESCALATION_MATRIX.md) |
| Recover from failure | [FAILURE_RECOVERY.md](FAILURE_RECOVERY.md) |

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial generation of complete .ai/ ecosystem |
