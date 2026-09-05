<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class AuditLogRepository
{
  public function __construct(
    private readonly PDO $pdo,
  ) {
  }

  public function log(
    ?int $userId,
    string $action,
    string $entityType,
    ?int $entityId,
    ?string $payload = null,
  ): void {
    $stmt = $this->pdo->prepare(
      'INSERT INTO audit_logs (user_id, action, entity_type, entity_id, payload, created_at)
       VALUES (:user_id, :action, :entity_type, :entity_id, :payload, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'user_id' => $userId,
      'action' => $action,
      'entity_type' => $entityType,
      'entity_id' => $entityId,
      'payload' => $payload,
    ]);
  }
}
