# Knowledge: pattern_audit_logging

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

All state changes logged to audit_logs table. Fields: id, user_id, action (CREATE/UPDATE/DELETE/LOGIN/LOGOUT), entity_type, entity_id, old_values (JSON), new_values (JSON), ip_address, user_agent, created_at. Hash-chained for tamper evidence. audit_trail_validator bot enforces.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |