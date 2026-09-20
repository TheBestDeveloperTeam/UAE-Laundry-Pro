# Memory Persistence — LaundryPro UAE Agent Ecosystem

> **Version:** 1.0.0  
> **Owner:** LP-BOT-MEMORY-WRITER  
> **Last Updated:** 2026-09-20  
> **Purpose:** Defines file formats, retention policy, conflict resolution, encryption, backup, and zero-data-loss guarantees for all memory layers.

---

## Overview

The memory system provides agents with persistent context across sessions. It is structured in six layers, each serving a distinct purpose:

| Layer | File | Purpose | Retention |
|-------|------|---------|-----------|
| Working | `memory/working.md` | Current task context | Session-scoped (flushed on task completion) |
| Short-Term | `memory/short_term.md` | Recent context across tasks | 7-day rolling window |
| Long-Term | `memory/long_term.md` | Permanent facts and decisions | Unlimited (append-only) |
| Episodic | `memory/episodic.md` | What happened (event log) | 90-day rolling window |
| Semantic | `memory/semantic.md` | What is known (fact store) | Unlimited (append-only) |
| Procedural | `memory/procedural.md` | How to do things (process store) | Unlimited (append-only) |

---

## File Formats

### Primary Format: Markdown

All memory files use Markdown with structured sections. Each entry follows this format:

```markdown
### Entry: <ENTRY-ID>
- **Task ID:** LP-TASK-YYYYMMDD-NNN
- **Timestamp:** YYYY-MM-DDTHH:MM:SS+04:00
- **Agent:** <agent-id>
- **Domain:** <domain>
- **Type:** fact | decision | event | procedure | observation
- **Content:** <the actual memory content>
- **References:** [list of related entries or files]
- **Confidence:** high | medium | low
- **Expiry:** <date or "never">
```

### Sidecar Format: JSON

Each memory Markdown file has a companion JSON sidecar (`.json` extension) for machine-readable access:

```json
{
  "file": "memory/short_term.md",
  "version": "1.0.0",
  "last_updated": "2026-09-20T23:00:00+04:00",
  "entry_count": 42,
  "entries": [
    {
      "id": "MEM-ST-20260920-001",
      "task_id": "LP-TASK-20260920-001",
      "timestamp": "2026-09-20T23:00:00+04:00",
      "agent": "LP-AGENT-FIN-BILLING",
      "domain": "finance",
      "type": "fact",
      "content": "UAE VAT rate is 5%, applied on subtotal after line discounts",
      "references": ["knowledge/domain_uae_regulations.md"],
      "confidence": "high",
      "expiry": "never",
      "hash": "sha256:abc123..."
    }
  ]
}
```

---

## Retention Policy

| Layer | Retention Period | Archival | Deletion |
|-------|-----------------|----------|----------|
| Working | Current session only | Flushed to short-term on session close | Cleared on session close |
| Short-Term | 7 calendar days | Entries older than 7 days move to long-term (if confidence ≥ medium) or are deleted (if confidence = low) | Automatic on memory_writer cycle |
| Long-Term | Unlimited | Never archived | Never deleted (append-only) |
| Episodic | 90 calendar days | Entries older than 90 days are summarized and moved to long-term | Originals deleted after summarization |
| Semantic | Unlimited | Never archived | Never deleted; superseded facts marked as `superseded_by: <new-entry-id>` |
| Procedural | Unlimited | Never archived | Never deleted; outdated procedures marked as `deprecated_by: <new-entry-id>` |

### Retention Triggers

Memory cleanup runs at:
1. **Session close:** Working → Short-term flush.
2. **Daily (midnight Asia/Dubai):** Short-term → Long-term migration for entries > 7 days.
3. **Weekly (Sunday midnight):** Episodic summarization for entries > 90 days.

---

## Conflict Resolution

### Write Conflicts

When two agents write to the same memory file concurrently:

1. **Last-Write-Wins (LWW)** for working memory (session-scoped, single developer).
2. **Append-Only** for all other layers (no conflicts possible — entries are appended, never overwritten).

### Semantic Conflicts

When two entries contain contradictory facts:

1. `conflict_resolver.bot` detects the contradiction.
2. The entry from the **higher-authority agent** takes precedence:
   - Leader > Department Lead > Specialist
3. The overridden entry is marked as `superseded_by: <winning-entry-id>`.
4. Both entries are preserved for audit.
5. The conflict is logged to `.ai/logs/decisions.log.md`.

### Merge Rules

When migrating short-term to long-term:

1. Deduplicate entries with identical content (keep the earliest timestamp).
2. Merge entries with similar content (>80% similarity) into a single consolidated entry.
3. Preserve all references from merged entries.
4. Update the JSON sidecar atomically.

---

## Encryption at Rest

### Encryption Specification

| Property | Value |
|----------|-------|
| Algorithm | AES-256-GCM |
| Key Derivation | PBKDF2-HMAC-SHA256, 100,000 iterations |
| Key Source | UMAC license key (machine-bound) |
| IV | 96-bit, randomly generated per encryption operation |
| Authentication Tag | 128-bit |

### What is Encrypted

| File Type | Encrypted | Rationale |
|-----------|-----------|-----------|
| Memory files (`.md`) | Yes (optional, configurable) | May contain business-sensitive decisions |
| JSON sidecars | Yes (optional, configurable) | Machine-readable index of memory |
| Log files | No | Logs are append-only and need rapid access |
| Knowledge files | No | Static reference material, no PII |
| Agent/bot files | No | Protocol definitions, no PII |

### Key Management

1. The encryption key is derived from the UMAC license key bound to the machine's physical address hash.
2. The key is never stored on disk — it is derived at runtime.
3. If the UMAC license changes, all encrypted memory files must be re-encrypted with the new key.
4. Key rotation procedure:
   a. Derive new key from new UMAC.
   b. Decrypt all memory files with old key.
   c. Re-encrypt with new key.
   d. Verify integrity (compare hashes before/after).
   e. Delete old ciphertext.

---

## Backup Integration

### Backup Path

All memory files are backed up to `C:/LaundryPro/backups/ai_memory/` (configurable via global config `BACKUP_PATH`).

### Backup Schedule

| Frequency | What | Format |
|-----------|------|--------|
| Every session close | `memory/working.md` snapshot | `working_YYYYMMDD_HHMMSS.md` |
| Daily | All memory files | `memory_backup_YYYYMMDD.tar.gz` |
| Weekly | Full `.ai/` directory | `ai_full_backup_YYYYMMDD.tar.gz` |

### Backup Integrity

1. Each backup file has a SHA-256 hash stored in `backup_manifest.json`.
2. Before restoring, verify the hash matches.
3. If hash mismatch, the backup is considered corrupted — fall back to the next oldest backup.

### Backup Verification Command

```bash
# Verify a backup's integrity
sha256sum memory_backup_20260920.tar.gz
# Compare with entry in backup_manifest.json
```

---

## Zero-Data-Loss Guarantees

### Guarantee 1: No Silent Write Failures

Every memory write operation follows this sequence:
1. Write to a temporary file (`.tmp` suffix).
2. Compute SHA-256 hash of the temporary file.
3. Rename temporary file to target file (atomic on Windows NTFS).
4. Verify the target file hash matches.
5. If verification fails, retry 3 times.
6. If all retries fail, write to `memory/emergency_dump.md` and alert developer.

### Guarantee 2: No Data Loss on Crash

1. Working memory is flushed to disk after every entry (not just on session close).
2. JSON sidecars are written atomically (write-temp-then-rename).
3. If the process crashes mid-write, the previous version of the file is preserved (the temp file is discarded on next startup).

### Guarantee 3: No Data Loss on Disk Full

1. Before every write, check available disk space.
2. If disk space < 100MB, emit a `DISK_LOW` warning and continue.
3. If disk space < 10MB, enter emergency mode:
   a. Stop all non-critical memory writes.
   b. Write only to `.ai/memory/emergency_dump.md`.
   c. Alert developer with specific error: "Disk full — memory persistence degraded".

### Guarantee 4: No Data Loss on Corruption

1. JSON sidecars include per-entry SHA-256 hashes.
2. On load, verify each entry's hash.
3. Corrupted entries are logged and excluded from context.
4. Attempt recovery from the most recent backup.

---

## Memory Entry ID Format

| Layer | ID Format | Example |
|-------|-----------|---------|
| Working | `MEM-WK-{YYYYMMDD}-{SEQ}` | `MEM-WK-20260920-001` |
| Short-Term | `MEM-ST-{YYYYMMDD}-{SEQ}` | `MEM-ST-20260920-001` |
| Long-Term | `MEM-LT-{YYYYMMDD}-{SEQ}` | `MEM-LT-20260920-001` |
| Episodic | `MEM-EP-{YYYYMMDD}-{SEQ}` | `MEM-EP-20260920-001` |
| Semantic | `MEM-SM-{YYYYMMDD}-{SEQ}` | `MEM-SM-20260920-001` |
| Procedural | `MEM-PR-{YYYYMMDD}-{SEQ}` | `MEM-PR-20260920-001` |

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-20 | Initial memory persistence specification |
