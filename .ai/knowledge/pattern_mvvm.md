# Knowledge: pattern_mvvm

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Model-View-ViewModel pattern for Flutter. View: Stateless/Stateful Widget, renders UI, delegates events to ViewModel. ViewModel: Riverpod Notifier/AsyncNotifier, holds UI state, calls Repository methods, exposes state as immutable objects. Model: Data classes with fromJson/toJson, Equatable for comparison. Repository: Abstract interface + concrete implementation, bridges ViewModel to DataSource. DataSource: API client (remote) or SQLite DAO (local).

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |