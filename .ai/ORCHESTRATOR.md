# Orchestrator â€” LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-AGENT-EXEC-CTO  
> **Last Updated:** 2026-09-20  
> **Status:** Active  

---

## Purpose

The Orchestrator is the **central coordination engine** for the LaundryPro UAE agent ecosystem. It defines the rules by which agents are selected, activated, composed, and deactivated for any given task. The Orchestrator itself is not an agent â€” it is a **protocol specification** that all agents and bots follow.

---

## Core Principles

1. **Single Responsibility:** Each agent handles exactly one domain; the Orchestrator composes them.
2. **Hierarchical Authority:** Leader agents can override department agents; department leads override specialists.
3. **Deterministic Routing:** Given a task category, the exact chain of agents is resolvable from `ROUTING_TABLE.md`.
4. **Idempotent Activation:** Every prompt triggers a full fresh load of the relevant agent chain.
5. **Traceable Execution:** Every decision is logged with agent ID, timestamp, input hash, output hash.
6. **Fail-Safe:** If an agent fails, the escalation path is followed; the system never silently drops a task.
7. **Composable:** Agents can spawn sub-agents, delegate to bots, and escalate to leaders.

---

## Orchestration Lifecycle

### Phase 1: Classification (prompt_router.bot)

When a prompt/task arrives, `prompt_router.bot` performs:

1. **Domain Classification:** Maps the prompt to one or more domains:
   - `sales`, `inventory`, `production`, `delivery`, `hr`, `payroll`, `finance`, `tax`, `licensing`, `security`, `sync`, `hardware`, `ui`, `api`, `database`, `reporting`, `backup`, `legal`, `marketing`, `localization`, `architecture`, `devops`, `testing`, `documentation`

2. **Risk Classification:**
   - `LOW` â€” Read-only, cosmetic, documentation
   - `MEDIUM` â€” Single-module write, non-financial
   - `HIGH` â€” Financial data, multi-module, security, sync engine
   - `CRITICAL` â€” Schema migration, licensing, disaster recovery, data loss risk

3. **Task Category:** Maps to one of the 20+ categories in `ROUTING_TABLE.md`.

4. **Output:** A structured classification object:
   ```json
   {
     "task_id": "LP-TASK-20260920-001",
     "domains": ["sales", "finance"],
     "risk": "HIGH",
     "category": "payment_workflow",
     "agent_chain": ["LP-AGENT-FIN-LEAD", "LP-AGENT-FIN-BILLING", "LP-AGENT-ENG-PHP"],
     "bots": ["LP-BOT-MONEY-GUARD", "LP-BOT-AUDIT-TRAIL"],
     "requires_leader_signoff": true,
     "leader": "LP-AGENT-EXEC-CFO"
   }
   ```

### Phase 2: Context Loading (context_loader.bot)

`context_loader.bot` loads the following files into the active context:

1. **Always loaded:**
   - `.ai/ORCHESTRATOR.md` (this file)
   - `.ai/ROUTING_TABLE.md`
   - `.ai/ESCALATION_MATRIX.md`
   - `.ai/memory/working.md`
   - `.ai/memory/short_term.md`

2. **Per-agent loaded:** Each agent's `Context Injection Contract` section specifies additional files.

3. **Domain-specific:** Knowledge files from `.ai/knowledge/` matching the classified domains.

### Phase 3: Agent Activation

1. All agents in the resolved chain are set to `status: active`.
2. Activation is logged to `.ai/logs/activation.log.md`.
3. A working memory session is opened via `memory_writer.bot`.
4. The audit trail session begins via `audit_trail.bot`.

### Phase 4: Delegation & Execution

Agents execute per `delegation.protocol.md`:

1. The **highest-tier agent** in the chain receives the task first.
2. If the task is within scope, the agent processes it.
3. If the task requires specialist work, the agent delegates downward.
4. Delegation creates a new sub-task linked to the parent task.
5. Sub-tasks execute and return results upward.
6. The delegating agent reviews and approves/rejects/requests revision.

### Phase 5: Monitoring

During execution, `escalation_bot` monitors for:

- **Timeout:** Agent has not responded within SLA (see `ESCALATION_MATRIX.md`).
- **Conflict:** Two agents produce contradictory outputs.
- **Block:** An agent cannot proceed due to missing input.
- **Failure:** An agent crashes or produces invalid output.

### Phase 6: Completion

1. All agents mark their sub-tasks as complete.
2. `memory_writer.bot` persists:
   - Episodic memory (what happened during this task)
   - Semantic memory (new facts learned)
   - Procedural memory (new procedures established)
3. `audit_trail.bot` closes the session with:
   - Final output hash
   - Duration
   - Agent chain summary
   - Decision log

### Phase 7: Deactivation

1. All agents in the chain are set to `status: standby`.
2. Working memory is flushed to short-term memory.
3. The task is archived.

---

## Agent Composition Rules

### Spawning Sub-Agents

Any agent can spawn a sub-agent when:
- The task crosses into another agent's domain.
- The task requires a skill the current agent does not possess (per `skill_matrix.md`).
- The task risk level exceeds the current agent's authority.

Spawning rules:
- Sub-agent inherits the parent task's `chain_id`.
- Sub-agent's output is returned to the spawning agent.
- Sub-agent cannot escalate past the spawning agent's leader without going through the escalation protocol.

### Bot Invocation

Agents invoke bots for:
- Deterministic checks (linting, money precision, RBAC validation).
- Automated processes (migration, backup, sync watchdog).
- Data collection (hardware probing, performance metrics).

Bot invocation rules:
- Bots execute synchronously within the agent's task.
- Bot output is appended to the agent's working memory.
- Bot failures trigger the agent's failure mode handling.

### Leader Override

Leaders can intervene at any point when:
- The task risk is `CRITICAL`.
- An escalation reaches them via `ESCALATION_MATRIX.md`.
- A cross-department conflict requires resolution.
- A decision has financial, legal, or security implications.

Leader override rules:
- Leader's decision is final for the current task.
- Leader's decision is logged with rationale.
- Affected agents acknowledge the override.

---

## Task State Machine

```
RECEIVED â†’ CLASSIFYING â†’ ROUTING â†’ ACTIVATING â†’ EXECUTING â†’ MONITORING
    â†“                                                           â†“
    â†“                                                    â”Œâ”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”
    â†“                                                    â†“             â†“
    â†“                                              COMPLETING    ESCALATING
    â†“                                                    â†“             â†“
    â†“                                              DEACTIVATING   RECOVERING
    â†“                                                    â†“             â†“
    â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ FAILED â†â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                             â†“
                          ARCHIVED
```

### State Descriptions

| State | Description | Actor |
|-------|-------------|-------|
| RECEIVED | Prompt/task has been received | System |
| CLASSIFYING | `prompt_router.bot` is classifying the task | prompt_router.bot |
| ROUTING | Task is being matched to agent chain | prompt_router.bot |
| ACTIVATING | Agents and context are being loaded | context_loader.bot |
| EXECUTING | Agents are processing the task | Agent chain |
| MONITORING | `escalation_bot` is watching for issues | escalation_bot |
| COMPLETING | Agents are finalizing outputs | Agent chain |
| ESCALATING | An issue has been escalated | escalation_bot |
| RECOVERING | A failure is being recovered | Per FAILURE_RECOVERY.md |
| DEACTIVATING | Agents are being stood down | System |
| FAILED | Task could not be completed | System |
| ARCHIVED | Task is complete and archived | audit_trail.bot |

---

## Cross-Cutting Concerns

### Multi-Tenancy

All agent outputs that touch data must include `business_owner_id` context. No agent may produce output that could leak data between tenants.

### Offline-First

All agents must assume no internet connectivity. Knowledge is local. Memory is local. Logs are local. No agent may make external network calls.

### Zero-Float Money

Any agent dealing with monetary values must reference `.ai/knowledge/pattern_zero_float_money.md` and ensure all values use `DECIMAL(18,2)`.

### Localization

All user-facing outputs must support both English (LTR) and Arabic (RTL). Agents producing UI specifications must reference `.ai/knowledge/pattern_localization_ltr_rtl.md`.

### Immutable Financials

No agent may approve or produce output that modifies a posted invoice. Corrections use correction memos only.

### Audit Trail

Every agent decision, delegation, escalation, and completion must be logged via `audit_trail.bot`.

---

## Configuration

### Timeouts

| Agent Tier | Default SLA (prompt-turns) | Max SLA |
|------------|---------------------------|---------|
| Leader | 1 | 3 |
| Department Lead | 2 | 5 |
| Specialist | 3 | 7 |
| Bot | 1 | 1 |

### Concurrency

- Maximum concurrent agent chains: 1 (single-developer mode)
- Maximum bots per chain: 5
- Maximum delegation depth: 4

### Memory Limits

- Working memory: 50 entries per session
- Short-term memory: 200 entries, rolling 7-day window
- Long-term memory: unlimited, append-only

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial orchestrator specification |

---

## Addendum: Offline Mandate (Added 2026-09-21)
> **CRITICAL**: Before processing any prompt, verify compliance with `.ai/OFFLINE_MANDATE.md`.
> All agent activations, bot sweeps, and memory operations MUST be local file operations only.
> Zero external API calls. Zero cloud tokens. Zero internet dependency for agent/bot operation.