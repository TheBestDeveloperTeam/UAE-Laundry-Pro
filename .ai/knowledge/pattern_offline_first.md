# Knowledge: pattern_offline_first

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Offline-first architecture: all operations succeed locally first, then sync to cloud when connectivity available. Local SQLite is the source of truth for the user. Sync outbox queues all write operations. Push protocol sends outbox entries to cloud API. Pull protocol fetches cloud changes since last checkpoint. Conflict resolution: last-write-wins by updated_at, with manual fallback for unresolvable conflicts.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |