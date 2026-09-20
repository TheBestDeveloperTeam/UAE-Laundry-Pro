# Memory System - LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Overview
6-layer memory architecture for persistent context across prompt cycles.

## Layers
| Layer | File | Retention | Purpose |
|-------|------|-----------|---------|
| Working | working.md | Current prompt cycle | Active task context |
| Short-Term | short_term.md | Last 5 prompt cycles | Recent decisions and context |
| Long-Term | long_term.md | Permanent | Architectural decisions, patterns established |
| Episodic | episodic.md | Permanent | Past incidents, debugging sessions, lessons learned |
| Semantic | semantic.md | Permanent | Domain knowledge refinements, business rules |
| Procedural | procedural.md | Permanent | Learned procedures, workflow optimizations |

## Persistence Rules
- Write via atomic temp-file-then-rename pattern.
- Encrypt sensitive data with AES-256-GCM.
- Each write appends, never overwrites (append-only log within each file).