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
      'SELECT COUNT(*) FROM sync_outbox WHERE business_owner_id = :id AND synced_at IS NULL'
    );
    $stmt->execute(['id' => $businessOwnerId]);

    return (int) $stmt->fetchColumn();
  }

  /** @return array<int, array<string, mixed>> */
  public function pending(int $businessOwnerId, int $limit = 100): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM sync_outbox WHERE business_owner_id = :id AND synced_at IS NULL ORDER BY id ASC LIMIT :limit'
    );
    $stmt->bindValue('id', $businessOwnerId, PDO::PARAM_INT);
    $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
    $stmt->execute();

    return $stmt->fetchAll() ?: [];
  }

  public function markSynced(int $id): void
  {
    $stmt = $this->pdo->prepare('UPDATE sync_outbox SET synced_at = UTC_TIMESTAMP() WHERE id = :id');
    $stmt->execute(['id' => $id]);
  }

  /** @param array<string, mixed> $payload */
  public function enqueue(int $businessOwnerId, string $entityType, int $localId, string $operation, array $payload): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO sync_outbox (business_owner_id, entity_type, entity_local_id, operation, payload, created_at)
       VALUES (:owner, :type, :local_id, :op, :payload, UTC_TIMESTAMP())'
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
