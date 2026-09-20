# Knowledge: pattern_clean_architecture

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Clean Architecture layers: Presentation (widgets, view models) -> Domain (entities, use cases, repository interfaces) -> Data (repository implementations, data sources, DTOs). Dependency rule: outer layers depend on inner layers, never reverse. Use cases encapsulate single business operations. Entities are pure business objects without framework dependencies.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |