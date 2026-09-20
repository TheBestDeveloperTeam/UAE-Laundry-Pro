# Knowledge: pattern_umac_licensing

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

UMAC (Unique Machine Authentication Code): machine-bound licensing. License key tied to hardware hash (CPU ID + disk serial + MAC address). Validation: local first, cloud verify on connectivity. Grace period: 30 days offline before read-only mode. Tamper detection: hash verification on each launch. License tiers: trial (30 days), standard, premium, enterprise.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |