<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class SyncOutboxRepository
{
  public function __construct(
    private readonly PDO $pdo,
  ) {
  }

  public function pendingCount(int $businessOwnerId): int
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(*) FROM sync_outbox WHERE business_owner_id = :id AND status = "pending" AND (next_retry_at IS NULL OR next_retry_at <= UTC_TIMESTAMP())'
    );
    $stmt->execute(['id' => $businessOwnerId]);

    return (int) $stmt->fetchColumn();
  }

  /** @return array<int, array<string, mixed>> */
  public function pending(int $businessOwnerId, int $limit = 100): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM sync_outbox WHERE business_owner_id = :id AND status = "pending" AND (next_retry_at IS NULL OR next_retry_at <= UTC_TIMESTAMP()) ORDER BY id ASC LIMIT :limit'
    );
    $stmt->bindValue('id', $businessOwnerId, PDO::PARAM_INT);
    $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
    $stmt->execute();

    return $stmt->fetchAll() ?: [];
  }

  public function markSynced(int $id): void
  {
    $stmt = $this->pdo->prepare('UPDATE sync_outbox SET status = "synced", synced_at = UTC_TIMESTAMP() WHERE id = :id');
    $stmt->execute(['id' => $id]);
  }

  public function markFailed(int $id, int $currentAttempts): void
  {
    $attempts = $currentAttempts + 1;
    if ($attempts >= 10) {
      $stmt = $this->pdo->prepare('UPDATE sync_outbox SET status = "failed", attempts = :attempts WHERE id = :id');
      $stmt->execute(['attempts' => $attempts, 'id' => $id]);
    } else {
      // Exponential backoff: min(300, 2^attempts * 5)
      $delay = min(300, pow(2, $attempts) * 5);
      $stmt = $this->pdo->prepare('UPDATE sync_outbox SET attempts = :attempts, next_retry_at = DATE_ADD(UTC_TIMESTAMP(), INTERVAL :delay SECOND) WHERE id = :id');
      $stmt->execute(['attempts' => $attempts, 'delay' => $delay, 'id' => $id]);
    }
  }

  /** @param array<string, mixed> $payload */
  public function enqueue(int $businessOwnerId, string $entityType, int $localId, string $operation, array $payload): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO sync_outbox (business_owner_id, entity_type, entity_local_id, operation, payload, status, attempts, created_at)
       VALUES (:owner, :type, :local_id, :op, :payload, "pending", 0, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'owner' => $businessOwnerId,
      'type' => $entityType,
      'local_id' => $localId,
      'op' => $operation,
      'payload' => json_encode($payload, JSON_THROW_ON_ERROR),
    ]);
  }
}
