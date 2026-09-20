# Sync Data Flow - LaundryPro UAE
> **Version:** 1.0.0

## Push Flow (Local -> Cloud)
```
Local Write -> sync_outbox INSERT -> Connectivity Check ->
IF online: POST /api/v1/sync/push (batch) ->
  Cloud validates idempotency_key ->
  Cloud applies changes ->
  Cloud returns success/conflict ->
  Local marks entries as synced ->
IF offline: Entries remain in outbox (FIFO queue)
```

## Pull Flow (Cloud -> Local)
```
Connectivity Check ->
IF online: GET /api/v1/sync/pull?since={last_sequence} ->
  Cloud returns new entries since checkpoint ->
  Local applies changes (LWW conflict resolution) ->
  Local updates last_sequence checkpoint ->
IF offline: No pull (local state is authoritative)
```