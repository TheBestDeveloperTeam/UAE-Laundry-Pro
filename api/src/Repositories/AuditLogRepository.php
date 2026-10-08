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

        $insertId = (int) $this->pdo->lastInsertId();

        // Enqueue to sync_outbox for central cloud visibility
        try {
          $outboxStmt = $this->pdo->prepare(
            "INSERT INTO sync_outbox (business_owner_id, admin_id, entity_type, entity_local_id, operation, payload, status, sync_attempts, created_at)
             VALUES (1, 1, 'audit_log', :local_id, 'INSERT', :payload, 'pending', 0, UTC_TIMESTAMP())"
          );
          $outboxStmt->execute([
            'local_id' => $insertId,
            'payload' => json_encode([
              'user_id' => $userId,
              'action' => $action,
              'entity_type' => $entityType,
              'entity_id' => $entityId,
              'payload' => $payload,
              'hash_signature' => $newHash,
            ]),
          ]);
        } catch (\Throwable $oe) {
          // Non-blocking outbox failure
        }

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
