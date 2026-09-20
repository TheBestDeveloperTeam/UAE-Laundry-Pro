# Activation Protocol — LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-AGENT-EXEC-CTO  
> **Last Updated:** 2026-09-20  
> **Purpose:** Defines the exact 9-step sequence that occurs when ANY prompt/task arrives.

---

## Overview

The Activation Protocol is the **entry point** for every interaction with the agent ecosystem. It guarantees deterministic, traceable, and idempotent activation of the correct agents and bots for any given task. No agent activates outside this protocol.

---

## Prerequisites

Before the Activation Protocol runs, the following must be true:

1. The `.ai/` directory is intact and all files are present (verified by `MANIFEST.md`).
2. The local orchestrator process is running.
3. Memory files are readable and writable.
4. Log files are writable.

If any prerequisite fails, the system enters **FAILURE_RECOVERY** mode (see `FAILURE_RECOVERY.md`).

---

## The 9 Steps

### Step 1: Prompt Reception

**Actor:** System  
**Input:** Raw prompt text from the developer  
**Output:** Prompt envelope  

The system wraps the raw prompt in a structured envelope:

```json
{
  "task_id": "LP-TASK-{YYYYMMDD}-{SEQ}",
  "timestamp": "2026-09-20T23:00:00+04:00",
  "prompt_text": "<raw prompt>",
  "prompt_hash": "<SHA-256 of prompt_text>",
  "source": "developer",
  "session_id": "<current session id>"
}
```

**Rules:**
- Task ID is generated atomically (no duplicates).
- Timestamp is in `Asia/Dubai` timezone (UTC+4).
- Prompt hash is SHA-256 of the exact prompt text (for deduplication and audit).

---

### Step 2: Prompt Classification (prompt_router.bot)

**Actor:** `LP-BOT-PROMPT-ROUTER`  
**Input:** Prompt envelope  
**Output:** Classification object  

`prompt_router.bot` analyzes the prompt and produces:

```json
{
  "task_id": "LP-TASK-20260920-001",
  "domains": ["sales", "finance"],
  "risk": "HIGH",
  "category": "payment_workflow",
  "confidence": 0.95,
  "ambiguity_flag": false,
  "multi_domain": true
}
```

**Classification Rules:**

1. **Domain Detection:** Scan for domain keywords and patterns:
   - Financial terms (invoice, payment, VAT, refund) → `finance`
   - Schema terms (table, column, migration, index) → `database`
   - UI terms (screen, widget, layout, button) → `ui`
   - (Full keyword → domain mapping in `prompt_router.bot.md`)

2. **Risk Assessment:**
   - Contains "delete", "drop", "migrate", "license" → minimum `HIGH`
   - Contains "money", "payment", "invoice", "tax" → minimum `HIGH`
   - Contains "sync", "backup", "restore" → minimum `HIGH`
   - Contains "security", "permission", "role" → minimum `MEDIUM`
   - Read-only or documentation → `LOW`
   - Schema change or disaster recovery → `CRITICAL`

3. **Category Matching:** Map to one of 20+ categories in `ROUTING_TABLE.md`.

4. **Ambiguity Handling:** If confidence < 0.7 or multiple categories match equally, set `ambiguity_flag: true` and route to Program Manager.

---

### Step 3: Agent Chain Resolution (context_loader.bot)

**Actor:** `LP-BOT-CONTEXT-LOADER`  
**Input:** Classification object  
**Output:** Resolved agent chain + file manifest  

`context_loader.bot` performs:

1. **Look up `ROUTING_TABLE.md`** using the classification's `category`.
2. **Resolve the agent chain:** Map agent IDs to their `.agent.md` file paths.
3. **Resolve bot list:** Map bot IDs to their `.bot.md` file paths.
4. **Build the context manifest:** A list of all files to load:

```json
{
  "always_load": [
    ".ai/ORCHESTRATOR.md",
    ".ai/ROUTING_TABLE.md",
    ".ai/ESCALATION_MATRIX.md",
    ".ai/memory/working.md",
    ".ai/memory/short_term.md"
  ],
  "agent_files": [
    ".ai/departments/finance/dept_lead.agent.md",
    ".ai/departments/finance/billing.agent.md",
    ".ai/departments/engineering/backend_php.agent.md"
  ],
  "bot_files": [
    ".ai/bots/money_precision_guard.bot.md",
    ".ai/bots/audit_trail.bot.md"
  ],
  "knowledge_files": [
    ".ai/knowledge/pattern_zero_float_money.md",
    ".ai/knowledge/domain_uae_regulations.md"
  ],
  "protocol_files": [
    ".ai/protocols/delegation.protocol.md"
  ]
}
```

5. **Load all files** into the active context.
6. **Verify integrity:** Check that all listed files exist and are non-empty.

---

### Step 4: Agent Activation

**Actor:** System  
**Input:** Resolved agent chain  
**Output:** Activated agent set  

For each agent in the chain:

1. Set the agent's `Status` field to `active`.
2. Load the agent's `Context Injection Contract` files.
3. Load the agent's `Memory Contract` read files.
4. Verify the agent's `Trigger Conditions` match the current task.
5. Record activation in `.ai/logs/activation.log.md`:

```markdown
| Timestamp | Task ID | Agent ID | Status | Trigger Match |
|-----------|---------|----------|--------|---------------|
| 2026-09-20T23:00:01+04:00 | LP-TASK-20260920-001 | LP-AGENT-FIN-LEAD | active | category=payment_workflow |
```

---

### Step 5: Working Memory Session Open (memory_writer.bot)

**Actor:** `LP-BOT-MEMORY-WRITER`  
**Input:** Task ID, activated agent set  
**Output:** Working memory session  

`memory_writer.bot` performs:

1. Create a new session block in `.ai/memory/working.md`:

```markdown
## Session: LP-TASK-20260920-001
- Started: 2026-09-20T23:00:02+04:00
- Agents: LP-AGENT-FIN-LEAD, LP-AGENT-FIN-BILLING, LP-AGENT-ENG-PHP
- Status: OPEN
- Entries: []
```

2. Pre-load relevant entries from `.ai/memory/short_term.md` (last 7 days of related domain entries).

---

### Step 6: Audit Session Open (audit_trail.bot)

**Actor:** `LP-BOT-AUDIT-TRAIL`  
**Input:** Task ID, prompt hash, agent chain  
**Output:** Audit session header  

`audit_trail.bot` creates a session entry in `.ai/logs/audits.log.md`:

```markdown
## Audit Session: LP-TASK-20260920-001
- Chain ID: LP-CHAIN-20260920-001-01
- Started: 2026-09-20T23:00:03+04:00
- Prompt Hash: sha256:abc123...
- Classification: { category: "payment_workflow", risk: "HIGH" }
- Agent Chain: [LP-AGENT-FIN-LEAD, LP-AGENT-FIN-BILLING, LP-AGENT-ENG-PHP]
- Bots: [LP-BOT-MONEY-GUARD, LP-BOT-AUDIT-TRAIL]
- Status: OPEN
```

---

### Step 7: Delegation & Execution

**Actor:** Agent chain (per `delegation.protocol.md`)  
**Input:** Task + context  
**Output:** Agent outputs  

Agents execute according to their roles:

1. **Lead agent** receives the task, reviews scope, and delegates.
2. **Specialist agents** execute their domain-specific work.
3. **Bots** run their checks concurrently.
4. Each agent logs decisions to `.ai/logs/decisions.log.md`.
5. `escalation_bot` monitors the chain for blocks, conflicts, or failures.

Execution rules:
- Each agent produces artifacts per its `Outputs` specification.
- Each agent follows its `Decision Rules` for if/then logic.
- Each agent respects its `Authorities` (can approve, can block, can escalate).
- Peer interaction follows each agent's `Interaction Protocol`.

---

### Step 8: Memory Persistence (memory_writer.bot)

**Actor:** `LP-BOT-MEMORY-WRITER`  
**Input:** Working memory session entries  
**Output:** Persisted memories  

On task completion, `memory_writer.bot`:

1. **Episodic memory** → Append to `.ai/memory/episodic.md`:
   - What happened (task summary, decisions made, outcomes).
   - Linked to task ID and chain ID.

2. **Semantic memory** → Append to `.ai/memory/semantic.md`:
   - New facts learned (e.g., "Customer model requires `business_owner_id`").
   - Indexed by domain.

3. **Procedural memory** → Append to `.ai/memory/procedural.md`:
   - New procedures established (e.g., "Always run backup before migration").
   - Indexed by task category.

4. **Short-term memory** → Update `.ai/memory/short_term.md`:
   - Move working entries to short-term with timestamp.
   - Apply 7-day rolling window (older entries archived to long-term).

5. **Close working session:**
   ```markdown
   - Status: CLOSED
   - Ended: 2026-09-20T23:15:00+04:00
   - Entries: 12
   - Persisted To: episodic, semantic
   ```

---

### Step 9: Audit Session Close (audit_trail.bot)

**Actor:** `LP-BOT-AUDIT-TRAIL`  
**Input:** Task completion data  
**Output:** Closed audit session  

`audit_trail.bot` finalizes the audit entry:

```markdown
- Status: CLOSED
- Ended: 2026-09-20T23:15:01+04:00
- Duration: 15m 1s
- Output Hash: sha256:def456...
- Result: SUCCESS | PARTIAL | FAILED | ESCALATED
- Decision Count: 5
- Escalation Count: 0
- Artifacts Produced: [list of output files]
```

---

## Error Handling During Activation

| Step | Failure | Recovery |
|------|---------|----------|
| 1 | Invalid prompt format | Return error to developer; do not activate |
| 2 | Classification ambiguity | Route to Program Manager (LP-AGENT-EXEC-PM) |
| 3 | Missing agent file | Log to failures.log.md; skip agent; escalate to CTO |
| 4 | Agent activation failure | Log to failures.log.md; attempt re-activation once; escalate |
| 5 | Memory file locked/corrupt | Enter FAILURE_RECOVERY; attempt memory repair |
| 6 | Log file not writable | Create new log file; alert developer |
| 7 | Agent execution failure | Follow ESCALATION_MATRIX.md |
| 8 | Memory persistence failure | Retry 3 times; if failed, dump to emergency `.ai/memory/emergency_dump.md` |
| 9 | Audit close failure | Retry; if failed, mark audit as INCOMPLETE |

---

## Activation Invariants

These must be true at all times during activation:

1. **At least one agent is active** for any in-progress task.
2. **`audit_trail.bot` is always active** for any in-progress task.
3. **`memory_writer.bot` is always active** for any in-progress task.
4. **No agent activates without a valid task ID**.
5. **No bot runs without an owning agent in the active chain**.
6. **Working memory session is open before any agent executes**.
7. **Audit session is open before any agent executes**.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial activation protocol — 9 steps defined |
