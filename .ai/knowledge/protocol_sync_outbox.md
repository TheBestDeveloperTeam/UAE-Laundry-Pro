# Knowledge: protocol_sync_outbox

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Protocol

## Reference

Sync outbox pattern: append-only table (sync_outbox) stores all local write operations. Fields: id, sequence_number, idempotency_key (UUID), table_name, row_id, operation (INSERT/UPDATE/DELETE), payload (JSON), business_owner_id, status (pending/synced/failed/dead), retry_count, created_at, synced_at. Push: POST /api/v1/sync/push with batch of entries. Pull: GET /api/v1/sync/pull?since={last_sequence}.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |