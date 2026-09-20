# Failure Recovery — LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-AGENT-OPS-LEAD  
> **Last Updated:** 2026-09-20  
> **Purpose:** Defines recovery procedures for 8 failure modes that can affect the agent ecosystem.

---

## Overview

Failure recovery ensures the agent ecosystem remains operational even when individual components fail. Every failure mode has a detection mechanism, an automated recovery procedure, and a manual fallback.

---

## Failure Mode 1: Agent Crash

### Description
An agent fails to produce output within its SLA, throws an internal error, or produces output that fails validation.

### Detection
- `escalation_bot` detects SLA timeout (no output within allocated prompt-turns).
- Output validation detects malformed or incomplete artifacts.
- Agent reports `status: error` via its output channel.

### Automated Recovery
1. Log the failure to `.ai/logs/failures.log.md` with full context (task ID, agent ID, error details).
2. Attempt **one re-activation** of the failed agent with the same inputs.
3. If re-activation succeeds, resume normal flow.
4. If re-activation fails, escalate per `ESCALATION_MATRIX.md`.

### Manual Fallback
1. Developer reviews the failure log.
2. Developer manually provides the expected output.
3. System injects the manual output and resumes the chain.

### Prevention
- Agent files must include comprehensive `Failure Modes` tables.
- All agent outputs are validated against their `Outputs` specification before being accepted.

---

## Failure Mode 2: Bot Crash

### Description
A bot fails to execute its algorithm, crashes during processing, or produces invalid output.

### Detection
- Bot returns a non-zero exit code or error status.
- Bot output fails schema validation.
- Bot exceeds its execution time limit (1 prompt-turn).

### Automated Recovery
1. Log the failure to `.ai/logs/failures.log.md`.
2. Retry the bot **up to 3 times** with exponential backoff (1s, 2s, 4s).
3. If all retries fail, notify the owning agent.
4. The owning agent either:
   a. Proceeds without the bot's output (if the bot is non-critical), OR
   b. Escalates (if the bot is critical to the task).

### Manual Fallback
1. Developer manually runs the bot's algorithm and provides the output.
2. System injects the manual output and resumes.

### Bot Criticality Classification

| Bot | Critical? | Can Skip? |
|-----|-----------|-----------|
| prompt_router | Yes | No — task cannot proceed without classification |
| context_loader | Yes | No — agents cannot activate without context |
| memory_writer | Yes | No — but can degrade to emergency dump |
| audit_trail | Yes | No — but can degrade to console logging |
| escalation_bot | Yes | No — but can degrade to developer notification |
| lint_bot | No | Yes — proceed with warning |
| test_runner | No | Yes — proceed with warning |
| money_precision_guard | Yes (for financial tasks) | No for financial tasks; Yes for others |
| rbac_guard | Yes (for security tasks) | No for security tasks; Yes for others |
| All others | No | Yes — proceed with warning |

---

## Failure Mode 3: Corrupted Memory

### Description
A memory file (`.md` or `.json` sidecar) is corrupted — either unreadable, has invalid structure, or fails hash verification.

### Detection
- JSON sidecar parse failure.
- Markdown structure validation failure (missing required sections).
- SHA-256 hash mismatch on individual entries.
- File is zero bytes or truncated.

### Automated Recovery
1. Log the corruption to `.ai/logs/failures.log.md` with the affected file path.
2. Attempt to load the **backup** from `C:/LaundryPro/backups/ai_memory/`:
   a. Try the most recent daily backup.
   b. If that fails, try the previous daily backup.
   c. If that fails, try the weekly backup.
3. If a valid backup is found, restore the memory file.
4. Re-verify the restored file.
5. Continue with restored context.

### Manual Fallback
1. Developer is notified of the corruption.
2. Developer can manually reconstruct the memory file from `.ai/logs/` (audit logs contain all decisions and events).
3. If reconstruction is not possible, initialize an empty memory file with the correct structure.

### Prevention
- All memory writes use atomic write-temp-then-rename.
- JSON sidecars include per-entry hashes.
- Daily backups ensure a recovery point.

---

## Failure Mode 4: Missing Knowledge File

### Description
A knowledge file referenced in an agent's `Context Injection Contract` or in `CONTEXT_INJECTION.md` does not exist on disk.

### Detection
- `context_loader.bot` fails to read a file listed in the context manifest.
- File exists but is empty (zero bytes).

### Automated Recovery
1. Log the missing file to `.ai/logs/failures.log.md`.
2. Check `.ai/MANIFEST.md` to verify the file should exist.
3. If the file is listed in the manifest:
   a. Alert the developer that a knowledge file is missing.
   b. Proceed without the file, with a warning injected into the agent's context: `WARNING: Knowledge file <path> is missing. Outputs may be incomplete.`
4. If the file is NOT in the manifest, it may have been intentionally removed — proceed without it.

### Manual Fallback
1. Developer regenerates the missing knowledge file.
2. Developer updates `MANIFEST.md` if the file was intentionally removed.

### Prevention
- `MANIFEST.md` is the source of truth for which files should exist.
- A periodic integrity check (see `db_integrity.bot.md`) validates all manifest entries.

---

## Failure Mode 5: Routing Ambiguity

### Description
`prompt_router.bot` cannot classify a prompt into a single task category with confidence ≥ 0.7.

### Detection
- `prompt_router.bot` sets `ambiguity_flag: true` in its classification output.
- `prompt_router.bot` returns multiple categories with equal confidence scores.
- `prompt_router.bot` returns no matching category.

### Automated Recovery
1. Log the ambiguity to `.ai/logs/decisions.log.md`.
2. Route the task to **LP-AGENT-EXEC-PM** (Program Manager) for manual classification.
3. PM examines the prompt and selects the correct category.
4. If PM cannot classify, PM escalates to **LP-AGENT-EXEC-CTO**.
5. The selected category is fed back into the routing pipeline.
6. The ambiguity and resolution are recorded in `.ai/memory/procedural.md` for future reference.

### Manual Fallback
1. Developer is asked to clarify the prompt or specify the task category.

### Prevention
- `prompt_router.bot` maintains a keyword index that is updated when new procedural memories are created.
- New categories can be added to `ROUTING_TABLE.md` when recurring ambiguities are detected.

---

## Failure Mode 6: Deadlock Between Agents

### Description
Two or more agents are waiting on each other's output, creating a circular dependency that prevents progress.

### Detection
- `escalation_bot` detects that two agents have been in `EXECUTING` state for more than the combined SLA without producing output.
- `escalation_bot` detects a circular reference in the delegation chain (Agent A delegates to Agent B, which delegates to Agent A).

### Automated Recovery
1. Log the deadlock to `.ai/logs/failures.log.md` with the involved agents and tasks.
2. `conflict_resolver.bot` is activated.
3. `conflict_resolver.bot` determines which agent should proceed first based on:
   a. Task priority (CRITICAL > HIGH > MEDIUM > LOW).
   b. Agent tier (Leader > Dept Lead > Specialist).
   c. If still tied, the agent activated first proceeds.
4. The other agent is set to `standby` until the first agent completes.
5. Once the first agent completes, the second agent is re-activated with the first agent's output.

### Manual Fallback
1. Developer breaks the deadlock by providing the missing input to one of the agents.

### Prevention
- Agents must not delegate to agents that are already in their delegation chain (checked by `context_loader.bot`).
- Maximum delegation depth is 4 (enforced by the orchestrator).

---

## Failure Mode 7: Offline Sync Failure

### Description
A task involves sync operations, but the sync engine cannot complete because:
- The cloud endpoint is unreachable (expected in offline-first mode).
- The sync outbox is corrupted.
- A conflict cannot be auto-resolved.

### Detection
- `sync_watchdog.bot` detects outbox growth without successful pushes.
- `sync_watchdog.bot` detects outbox entries older than the configured retry window.
- `sync_watchdog.bot` detects a conflict that the auto-resolver rejected.

### Automated Recovery
1. Log the sync failure to `.ai/logs/failures.log.md`.
2. If the cloud is unreachable:
   a. This is expected behavior in offline-first mode.
   b. Entries remain in the outbox for retry.
   c. No escalation needed unless the outbox exceeds 10,000 entries.
3. If the outbox is corrupted:
   a. `db_integrity.bot` runs a consistency check.
   b. Attempt to rebuild the outbox from the sync_events table.
   c. If rebuild fails, escalate to LP-AGENT-ENG-SYNC.
4. If a conflict cannot be auto-resolved:
   a. The conflict is logged to `memory/episodic.md`.
   b. The conflicting entries are presented to the developer for manual resolution.
   c. The resolution is recorded in `memory/procedural.md` for future auto-resolution.

### Manual Fallback
1. Developer manually resolves sync conflicts.
2. Developer manually triggers outbox flush.

---

## Failure Mode 8: License Validation Failure

### Description
The UMAC license check fails — either the license is expired, the machine hash doesn't match, or the license file is corrupted.

### Detection
- `license_guard.bot` detects license expiry.
- `license_guard.bot` detects machine hash mismatch.
- License file is unreadable or has invalid format.

### Automated Recovery
1. Log the license failure to `.ai/logs/failures.log.md`.
2. If the license is expired:
   a. System enters **read-only mode** (per licensing/read_only_mode spec).
   b. All write operations are blocked.
   c. Agent ecosystem continues in read-only mode.
   d. Developer is notified with renewal instructions.
3. If the machine hash doesn't match:
   a. This indicates a hardware change or piracy attempt.
   b. System enters **locked mode** (no operations permitted).
   c. Developer must re-activate the license.
4. If the license file is corrupted:
   a. Attempt to restore from backup.
   b. If backup exists and is valid, restore and re-validate.
   c. If no valid backup, enter locked mode.

### Manual Fallback
1. Developer contacts Magnificent Solution for license re-activation.
2. Developer provides machine hash for re-binding.

---

## Recovery Log Format

All recovery events are logged to `.ai/logs/failures.log.md` with this format:

```markdown
### Failure: <FAILURE-ID>
- **Timestamp:** <ISO 8601>
- **Mode:** <1-8 from this document>
- **Affected Component:** <file path or agent/bot ID>
- **Detection Method:** <how it was detected>
- **Recovery Action:** <what was done>
- **Result:** RECOVERED | DEGRADED | MANUAL_REQUIRED | HALTED
- **Duration:** <time to recover>
- **Task ID:** <affected task>
- **Chain ID:** <affected chain>
```

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial failure recovery specification — 8 failure modes defined |
