<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Repositories\SyncOutboxRepository;
use PDO;

class SyncController
{
    public function __construct(
        private readonly SyncOutboxRepository $outboxRepo,
        private readonly PDO $db
    ) {
    }

    /**
     * Push batch of changes from local to cloud
     */
    public function push(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $data = $request->getBody();
        $batch = $data['batch'] ?? [];

        if (!is_array($batch)) {
            $response->error(400, 'Batch must be an array');
            return;
        }

        $accepted = [];
        $rejected = [];

        foreach ($batch as $item) {
            try {
                // Here the cloud processes the payload.
                // In an actual multi-node setup, this applies idempotent inserts/updates
                // by row_uuid, handling updated_at conflicts.
                // For now, we simulate accepting them into sync_inbox.

                $sql = "INSERT INTO sync_inbox (uuid, admin_id, source_terminal_id, entity_type, row_uuid, operation, payload)
                        VALUES (UUID(), ?, ?, ?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE payload = VALUES(payload), status = 'pending'";
                $stmt = $this->db->prepare($sql);
                $stmt->execute([
                    $adminId,
                    $item['terminal_id'] ?? 'local',
                    $item['entity_type'],
                    $item['row_uuid'],
                    $item['operation'],
                    json_encode($item['payload'])
                ]);

                $accepted[] = $item['uuid'];
            } catch (\Exception $e) {
                $rejected[] = [
                    'uuid' => $item['uuid'] ?? null,
                    'error' => $e->getMessage()
                ];
            }
        }

        $response->success(['accepted' => $accepted, 'rejected' => $rejected], 'Sync push processed');
    }

    /**
     * Pull changes from cloud to local
     */
    public function pull(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        // Simulates pulling changes for the local node
        // Requires a cursor (last sync timestamp)
        $cursor = $_GET['cursor'] ?? '1970-01-01 00:00:00';

        // Select items modified on cloud since cursor
        // For demonstration, we'll return empty. The actual implementation queries cloud DB.
        
        $newCursor = date('Y-m-d H:i:s');
        $changes = [];

        $response->success([
            'changes' => $changes,
            'new_cursor' => $newCursor
        ], 'Sync pull processed');
    }

    /**
     * Status of local outbox
     */
    public function status(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $stmt = $this->db->prepare("SELECT status, COUNT(*) as count FROM sync_outbox WHERE admin_id = ? GROUP BY status");
        $stmt->execute([$adminId]);
        $stats = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);

        $response->success([
            'pending' => $stats['pending'] ?? 0,
            'failed' => $stats['failed'] ?? 0,
            'dead_letter' => $stats['dead_letter'] ?? 0,
        ], 'Sync status retrieved');
    }
}
