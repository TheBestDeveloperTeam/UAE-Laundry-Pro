<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\Uuid;
use PDO;

class SyncOutboxRepository
{
    public function __construct(private readonly PDO $db)
    {
    }

    /**
     * Enqueue a new event to outbox
     */
    public function enqueue(int $adminId, string $entityType, ?int $entityId, string $operation, array $payload, string $terminalId = 'local'): void
    {
        $sql = "INSERT INTO sync_outbox (uuid, admin_id, terminal_id, entity_type, entity_id, operation, payload, next_retry_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            Uuid::v4(),
            $adminId,
            $terminalId,
            $entityType,
            $entityId,
            $operation,
            json_encode($payload)
        ]);
    }

    /**
     * Fetch pending batch for syncing (max 100)
     */
    public function getPendingBatch(int $limit = 100): array
    {
        $sql = "SELECT * FROM sync_outbox
                WHERE status IN ('pending', 'failed')
                  AND (next_retry_at IS NULL OR next_retry_at <= NOW())
                ORDER BY created_at ASC
                LIMIT ?";
        $stmt = $this->db->prepare($sql);
        $stmt->bindValue(1, $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Mark sync success
     */
    public function markSynced(int $id): void
    {
        $sql = "UPDATE sync_outbox SET status = 'synced', synced_at = NOW() WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
    }

    /**
     * Mark sync failure and apply exponential backoff
     */
    public function markFailed(int $id, int $currentAttempts, string $error): void
    {
        $attempts = $currentAttempts + 1;
        if ($attempts >= 10) {
            $status = 'dead_letter';
            $nextRetry = null;
        } else {
            $status = 'failed';
            // Exponential backoff: min(2^attempt * base, max)
            $baseDelay = 60; // 1 minute
            $maxDelay = 86400; // 24 hours
            $delay = min(pow(2, $attempts) * $baseDelay, $maxDelay);
            $nextRetry = date('Y-m-d H:i:s', time() + $delay);
        }

        $sql = "UPDATE sync_outbox SET status = ?, attempts = ?, last_error = ?, next_retry_at = ? WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$status, $attempts, $error, $nextRetry, $id]);
    }
}
