# Knowledge: pattern_multi_tenant

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Multi-tenant isolation via business_owner_id on all data tables. Every SELECT must include WHERE business_owner_id = ?. Every INSERT must include business_owner_id. tenant_isolation_checker bot validates at code review. System tables (migrations, global settings) are exempt. JWT token contains business_owner_id claim for server-side enforcement.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |