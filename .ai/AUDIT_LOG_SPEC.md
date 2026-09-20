# Audit Log Specification — LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-AGENT-SEC-AUDIT  
> **Last Updated:** 2026-09-20  
> **Purpose:** Defines the schema for every log file in `.ai/logs/`, ensuring traceable, tamper-evident audit trails.

---

## Overview

The audit log system captures every significant event in the agent ecosystem: activations, decisions, escalations, failures, and general audit events. All logs are append-only Markdown files with structured entries and companion JSON sidecars.

---

## Log File Inventory

| File | Purpose | Retention |
|------|---------|-----------|
| `logs/activation.log.md` | Records every agent/bot activation and deactivation | 90 days |
| `logs/decisions.log.md` | Records every decision made by an agent | Unlimited |
| `logs/escalations.log.md` | Records every escalation event | Unlimited |
| `logs/failures.log.md` | Records every failure and recovery attempt | Unlimited |
| `logs/audits.log.md` | Records every audit session (open/close) | Unlimited |

---

## Universal Log Entry Schema

Every log entry, regardless of log file, must include these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `entry_id` | string | Yes | Unique identifier: `LOG-{TYPE}-{YYYYMMDD}-{SEQ}` |
| `timestamp` | ISO 8601 | Yes | Event time in `Asia/Dubai` timezone (UTC+4) |
| `actor_id` | string | Yes | Agent ID (`LP-AGENT-*`) or Bot ID (`LP-BOT-*`) |
| `actor_type` | enum | Yes | `agent` or `bot` |
| `action` | string | Yes | Verb describing what happened |
| `task_id` | string | Yes | Associated task ID (`LP-TASK-*`) |
| `chain_id` | string | Yes | Associated chain ID (`LP-CHAIN-*`) |
| `input_hash` | string | Yes | SHA-256 of the input that triggered this action |
| `output_hash` | string | Conditional | SHA-256 of the output produced (required for decisions) |
| `parent_task_id` | string | Optional | Parent task if this is a sub-task |
| `result` | enum | Yes | `SUCCESS`, `PARTIAL`, `FAILED`, `ESCALATED`, `SKIPPED` |
| `duration_ms` | integer | Optional | Duration of the action in milliseconds |
| `metadata` | object | Optional | Additional key-value pairs specific to the log type |

---

## Log-Specific Schemas

### activation.log.md

Additional fields for activation entries:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `activation_type` | enum | Yes | `activate` or `deactivate` |
| `trigger_match` | string | Yes | The trigger condition that matched |
| `context_files_loaded` | array | Yes | List of files loaded into context |
| `context_total_size_kb` | integer | Yes | Total size of loaded context in KB |

**Entry Format:**

```markdown
### LOG-ACT-20260920-001
- **Timestamp:** 2026-09-20T23:00:01+04:00
- **Actor:** LP-AGENT-FIN-LEAD
- **Actor Type:** agent
- **Action:** activate
- **Task ID:** LP-TASK-20260920-001
- **Chain ID:** LP-CHAIN-20260920-001-01
- **Input Hash:** sha256:a1b2c3d4...
- **Trigger Match:** category=payment_workflow
- **Context Files:** [ORCHESTRATOR.md, ROUTING_TABLE.md, knowledge/pattern_zero_float_money.md]
- **Context Size:** 45KB
- **Result:** SUCCESS
```

### decisions.log.md

Additional fields for decision entries:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `decision_type` | enum | Yes | `approve`, `reject`, `delegate`, `override`, `defer` |
| `rationale` | string | Yes | Why this decision was made |
| `alternatives_considered` | array | Optional | Other options that were evaluated |
| `impact` | enum | Yes | `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` |
| `reversible` | boolean | Yes | Whether this decision can be undone |

**Entry Format:**

```markdown
### LOG-DEC-20260920-001
- **Timestamp:** 2026-09-20T23:05:00+04:00
- **Actor:** LP-AGENT-FIN-BILLING
- **Actor Type:** agent
- **Action:** decision
- **Task ID:** LP-TASK-20260920-001
- **Chain ID:** LP-CHAIN-20260920-001-01
- **Input Hash:** sha256:e5f6g7h8...
- **Output Hash:** sha256:i9j0k1l2...
- **Decision Type:** approve
- **Rationale:** Payment amount uses DECIMAL(18,2), VAT calculated at 5%, correction memo not required
- **Impact:** HIGH
- **Reversible:** false
- **Result:** SUCCESS
- **Duration:** 250ms
```

### escalations.log.md

Additional fields for escalation entries:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `trigger_code` | enum | Yes | From ESCALATION_MATRIX.md trigger codes |
| `from_agent` | string | Yes | Agent that initiated the escalation |
| `to_agent` | string | Yes | Agent receiving the escalation |
| `blocker` | string | Yes | Description of what blocked progress |
| `attempted_resolution` | string | Yes | What the agent tried before escalating |
| `sla_remaining` | integer | Yes | Prompt-turns remaining before fallback |

**Entry Format:**

```markdown
### LOG-ESC-20260920-001
- **Timestamp:** 2026-09-20T23:10:00+04:00
- **Actor:** LP-AGENT-ENG-SYNC
- **Actor Type:** agent
- **Action:** escalation
- **Task ID:** LP-TASK-20260920-002
- **Chain ID:** LP-CHAIN-20260920-002-01
- **Trigger Code:** ESC-RISK
- **From Agent:** LP-AGENT-ENG-SYNC
- **To Agent:** LP-AGENT-EXEC-CTO
- **Blocker:** Sync outbox schema change affects tenant isolation
- **Attempted Resolution:** Reviewed pattern_multi_tenant.md; determined change requires architecture review
- **SLA Remaining:** 1
- **Input Hash:** sha256:m3n4o5p6...
- **Result:** ESCALATED
```

### failures.log.md

Additional fields for failure entries:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `failure_mode` | integer | Yes | 1-8 from FAILURE_RECOVERY.md |
| `failure_description` | string | Yes | Human-readable description |
| `affected_component` | string | Yes | File path or agent/bot ID |
| `detection_method` | string | Yes | How the failure was detected |
| `recovery_action` | string | Yes | What recovery was attempted |
| `recovery_result` | enum | Yes | `RECOVERED`, `DEGRADED`, `MANUAL_REQUIRED`, `HALTED` |

**Entry Format:**

```markdown
### LOG-FAIL-20260920-001
- **Timestamp:** 2026-09-20T23:12:00+04:00
- **Actor:** LP-BOT-MEMORY-WRITER
- **Actor Type:** bot
- **Action:** failure
- **Task ID:** LP-TASK-20260920-001
- **Chain ID:** LP-CHAIN-20260920-001-01
- **Failure Mode:** 3 (Corrupted Memory)
- **Failure Description:** JSON sidecar for short_term.md failed parse — unexpected EOF at byte 4096
- **Affected Component:** .ai/memory/short_term.json
- **Detection Method:** JSON.parse exception on load
- **Recovery Action:** Restored from daily backup (memory_backup_20260919.tar.gz)
- **Recovery Result:** RECOVERED
- **Input Hash:** sha256:q7r8s9t0...
- **Result:** PARTIAL
- **Duration:** 3200ms
```

### audits.log.md

Additional fields for audit session entries:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `session_type` | enum | Yes | `open` or `close` |
| `agent_chain` | array | Yes | List of agents in the chain |
| `bots_invoked` | array | Yes | List of bots invoked |
| `classification` | object | Yes | The prompt classification from prompt_router.bot |
| `decision_count` | integer | Conditional | Number of decisions made (on close) |
| `escalation_count` | integer | Conditional | Number of escalations (on close) |
| `artifacts_produced` | array | Conditional | List of output files (on close) |
| `final_output_hash` | string | Conditional | SHA-256 of final output (on close) |

---

## Tamper Detection

### Hash Chain

Each log file maintains a running hash chain for tamper detection:

1. The first entry's `entry_hash` = SHA-256(entry content).
2. Each subsequent entry's `entry_hash` = SHA-256(previous_entry_hash + entry content).
3. The current chain head hash is stored at the top of the log file.

### Chain Header Format

```markdown
# Audit Log: <log-type>
- **Chain Head:** sha256:xyz789...
- **Entry Count:** 42
- **Last Updated:** 2026-09-20T23:15:00+04:00
```

### Verification

To verify log integrity:
1. Start from the first entry.
2. Compute the hash chain forward.
3. Compare the final hash with the chain head.
4. If they match, the log has not been tampered with.
5. If they don't match, the log is compromised — alert developer and escalate to LP-AGENT-SEC-AUDIT.

---

## Storage Rules

1. **Append-Only:** Log entries are never modified or deleted.
2. **Atomic Writes:** Each entry is written atomically (write-temp-then-append).
3. **Size Limits:** Each log file is rotated when it exceeds 10MB. Rotated files are named `<logname>_YYYYMMDD.log.md` and moved to `logs/archive/`.
4. **Backup:** Log files are included in the daily and weekly backups per `MEMORY_PERSISTENCE.md`.
5. **JSON Sidecars:** Each log file has a `.json` companion for machine-readable access with the same schema.

---

## Log Entry ID Formats

| Log Type | ID Format | Example |
|----------|-----------|---------|
| Activation | `LOG-ACT-{YYYYMMDD}-{SEQ}` | `LOG-ACT-20260920-001` |
| Decision | `LOG-DEC-{YYYYMMDD}-{SEQ}` | `LOG-DEC-20260920-001` |
| Escalation | `LOG-ESC-{YYYYMMDD}-{SEQ}` | `LOG-ESC-20260920-001` |
| Failure | `LOG-FAIL-{YYYYMMDD}-{SEQ}` | `LOG-FAIL-20260920-001` |
| Audit | `LOG-AUD-{YYYYMMDD}-{SEQ}` | `LOG-AUD-20260920-001` |

---

## Compliance

The audit log system satisfies:

- **UAE FTA requirements:** Sequential, immutable, tamper-evident.
- **ISO 27001:** Comprehensive logging of access and changes.
- **SOC 2:** Traceable decision chain with hash verification.
- **PDPL UAE:** PII access is logged with user and purpose.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial audit log specification — 5 log types defined |
