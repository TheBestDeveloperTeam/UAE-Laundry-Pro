<?php

declare(strict_types=1);

/**
 * LaundryPro Background Sync Daemon
 * Designed to run every 60s via cron or Windows Task Scheduler
 */

require_once __DIR__ . '/vendor/autoload.php';

use LaundryPro\Api\Core\Database;
use LaundryPro\Api\Repositories\SyncOutboxRepository;

// Load environment configuration
$db = (new Database())->getConnection();
$outboxRepo = new SyncOutboxRepository($db);

// Configuration
$batchSize = 100;
$cloudEndpoint = getenv('CLOUD_SYNC_ENDPOINT') ?: 'https://cloud.laundrypro.ae/api/sync/push';
$cloudApiKey = getenv('CLOUD_API_KEY') ?: 'demo-key';

try {
    $batch = $outboxRepo->getPendingBatch($batchSize);

    if (empty($batch)) {
        echo "No pending sync tasks.\n";
        exit(0);
    }

    echo "Found " . count($batch) . " pending tasks. Syncing...\n";

    // Build payload for cloud
    $payload = [
        'batch' => []
    ];

    foreach ($batch as $item) {
        $payload['batch'][] = [
            'uuid' => $item['uuid'],
            'terminal_id' => $item['terminal_id'],
            'entity_type' => $item['entity_type'],
            'row_uuid' => json_decode($item['payload'], true)['row_uuid'] ?? $item['uuid'],
            'operation' => $item['operation'],
            'payload' => json_decode($item['payload'], true),
        ];
    }

    // Call Cloud API
    $ch = curl_init($cloudEndpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $cloudApiKey
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200 && $response) {
        $result = json_decode($response, true);
        $accepted = $result['data']['accepted'] ?? [];
        $rejected = $result['data']['rejected'] ?? [];

        // Process accepted
        foreach ($batch as $item) {
            if (in_array($item['uuid'], $accepted)) {
                $outboxRepo->markSynced((int)$item['id']);
            }
        }

        // Process rejected
        foreach ($rejected as $rej) {
            foreach ($batch as $item) {
                if ($item['uuid'] === $rej['uuid']) {
                    $outboxRepo->markFailed((int)$item['id'], (int)$item['attempts'], $rej['error']);
                }
            }
        }

        echo "Sync complete: " . count($accepted) . " accepted, " . count($rejected) . " rejected.\n";
    } else {
        throw new \RuntimeException("Cloud API returned HTTP {$httpCode}: {$response}");
    }

} catch (\Exception $e) {
    echo "Sync failed: " . $e->getMessage() . "\n";
    
    // Fallback mark everything as failed in this batch if there was a network error
    if (!empty($batch)) {
        foreach ($batch as $item) {
            $outboxRepo->markFailed((int)$item['id'], (int)$item['attempts'], $e->getMessage());
        }
    }
    
    exit(1);
}
