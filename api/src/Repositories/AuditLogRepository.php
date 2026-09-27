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
    try {
        $this->pdo->beginTransaction();

        // Get the previous hash signature
        $stmt = $this->pdo->query('SELECT hash_signature FROM audit_logs ORDER BY id DESC LIMIT 1 FOR UPDATE');
        $prevLog = $stmt->fetch(PDO::FETCH_ASSOC);
        $prevHash = $prevLog ? $prevLog['hash_signature'] : 'GENESIS';

        // Create the new hash signature
        $dataToHash = implode('|', [
            $prevHash,
            $userId ?? 'null',
            $action,
            $entityType,
            $entityId ?? 'null',
            $payload ?? 'null',
            microtime(true)
        ]);

        $newHash = hash('sha256', $dataToHash);

        $stmt = $this->pdo->prepare(
          'INSERT INTO audit_logs (user_id, action, entity_type, entity_id, payload, hash_signature, created_at)
           VALUES (:user_id, :action, :entity_type, :entity_id, :payload, :hash_signature, UTC_TIMESTAMP())'
        );
        $stmt->execute([
          'user_id' => $userId,
          'action' => $action,
          'entity_type' => $entityType,
          'entity_id' => $entityId,
          'payload' => $payload,
          'hash_signature' => $newHash,
        ]);

        $this->pdo->commit();
    } catch (\Exception $e) {
        if ($this->pdo->inTransaction()) {
            $this->pdo->rollBack();
        }
        // Still throw or handle depending on requirements
        throw $e;
    }
  }
}
