<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Database;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use PDO;

final class CloudApiController
{
    private string $storageDir;
    private string $businessesFile;
    private string $recordsFile;

    public function __construct()
    {
        $this->storageDir = dirname(__DIR__, 2) . '/storage';
        if (!is_dir($this->storageDir)) {
            @mkdir($this->storageDir, 0775, true);
        }
        $this->businessesFile = $this->storageDir . '/businesses.json';
        $this->recordsFile = $this->storageDir . '/sync_records.json';
    }

    public function health(Request $request): void
    {
        $pdo = Database::connect();
        $dbStatus = $pdo !== null ? 'ok' : 'fallback_json';
        Response::json([
            'success' => true,
            'code' => 'HEALTH_OK',
            'data' => [
                'status' => 'healthy',
                'service' => 'LaundryPro Central Cloud API',
                'database' => $dbStatus,
                'version' => '1.2.0',
                'timestamp' => gmdate('c'),
            ]
        ]);
    }

    public function registerBusiness(Request $request): void
    {
        $body = $request->body();
        $name = (string) ($body['name'] ?? 'LaundryPro Tenant');
        $licenseKey = $body['license_key'] ?? null;
        $cloudToken = bin2hex(random_bytes(32));

        $pdo = Database::connect();
        if ($pdo !== null) {
            try {
                $stmt = $pdo->prepare(
                    'INSERT INTO businesses (name, license_key, cloud_token, status, created_at)
                     VALUES (:name, :key, :token, "active", NOW())'
                );
                $stmt->execute([
                    'name' => $name,
                    'key' => $licenseKey,
                    'token' => $cloudToken,
                ]);
                $tenantId = (int) $pdo->lastInsertId();

                // Log audit
                $audit = $pdo->prepare('INSERT INTO cloud_audit_logs (tenant_id, action, details, ip_address) VALUES (?, ?, ?, ?)');
                $audit->execute([$tenantId, 'BUSINESS_REGISTERED', "Registered tenant: $name", $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1']);

                Response::json([
                    'success' => true,
                    'code' => 'BUSINESS_REGISTERED',
                    'data' => [
                        'business_owner_id' => $tenantId,
                        'cloud_token' => $cloudToken,
                    ],
                ]);
                return;
            } catch (\Throwable $e) {
                // fallback to JSON storage if db query failed
            }
        }

        // Fallback JSON storage mode
        $businesses = $this->loadJson($this->businessesFile);
        $id = count($businesses) + 1;
        $businesses[] = [
            'id' => $id,
            'name' => $name,
            'license_key' => $licenseKey,
            'cloud_token' => $cloudToken,
            'created_at' => gmdate('c'),
        ];
        $this->saveJson($this->businessesFile, $businesses);

        Response::json([
            'success' => true,
            'code' => 'BUSINESS_REGISTERED',
            'data' => [
                'business_owner_id' => $id,
                'cloud_token' => $cloudToken,
            ],
        ]);
    }

    public function syncPush(Request $request): void
    {
        $tenant = $this->authenticateTenant($request);
        $businessOwnerId = (int) $tenant['id'];
        $body = $request->body();
        if (!is_array($body)) {
            $body = [];
        }

        $pdo = Database::connect();
        if ($pdo !== null) {
            try {
                $stmt = $pdo->prepare(
                    'INSERT INTO sync_records (business_owner_id, entity_type, entity_local_id, operation, payload, created_at)
                     VALUES (:owner, :type, :local_id, :op, :payload, NOW())
                     ON DUPLICATE KEY UPDATE payload = VALUES(payload), operation = VALUES(operation), created_at = NOW()'
                );
                foreach ($body as $item) {
                    if (!is_array($item)) continue;
                    $stmt->execute([
                        'owner' => $businessOwnerId,
                        'type' => (string) ($item['entity_type'] ?? 'unknown'),
                        'local_id' => (int) ($item['entity_local_id'] ?? 0),
                        'op' => (string) ($item['operation'] ?? 'create'),
                        'payload' => json_encode($item['payload'] ?? []),
                    ]);
                }

                Response::json([
                    'success' => true,
                    'code' => 'SYNC_RECEIVED',
                    'data' => ['count' => count($body)],
                ]);
                return;
            } catch (\Throwable $e) {
                // Fallback to JSON below
            }
        }

        $records = $this->loadJson($this->recordsFile);
        foreach ($body as $record) {
            if (!is_array($record)) continue;
            $records[] = [
                'business_owner_id' => $businessOwnerId,
                'entity_type' => $record['entity_type'] ?? 'unknown',
                'entity_local_id' => (int) ($record['entity_local_id'] ?? 0),
                'operation' => $record['operation'] ?? 'create',
                'payload' => $record['payload'] ?? [],
                'created_at' => gmdate('c'),
            ];
        }
        $this->saveJson($this->recordsFile, $records);

        Response::json([
            'success' => true,
            'code' => 'SYNC_RECEIVED',
            'data' => ['count' => count($body)],
        ]);
    }

    public function syncPull(Request $request): void
    {
        $tenant = $this->authenticateTenant($request);
        $businessOwnerId = (int) $tenant['id'];
        $since = $request->query('since');

        $pdo = Database::connect();
        if ($pdo !== null) {
            try {
                if ($since !== null && $since !== '') {
                    $stmt = $pdo->prepare('SELECT entity_type, entity_local_id, operation, payload, created_at FROM sync_records WHERE business_owner_id = :owner AND created_at >= :since ORDER BY id ASC');
                    $stmt->execute(['owner' => $businessOwnerId, 'since' => $since]);
                } else {
                    $stmt = $pdo->prepare('SELECT entity_type, entity_local_id, operation, payload, created_at FROM sync_records WHERE business_owner_id = :owner ORDER BY id ASC');
                    $stmt->execute(['owner' => $businessOwnerId]);
                }
                $rows = $stmt->fetchAll() ?: [];
                $records = [];
                foreach ($rows as $row) {
                    $records[] = [
                        'business_owner_id' => $businessOwnerId,
                        'entity_type' => $row['entity_type'],
                        'entity_local_id' => (int) $row['entity_local_id'],
                        'operation' => $row['operation'],
                        'payload' => is_string($row['payload']) ? json_decode($row['payload'], true) : $row['payload'],
                        'created_at' => $row['created_at'],
                    ];
                }

                Response::json([
                    'success' => true,
                    'code' => 'SYNC_PULL',
                    'data' => ['records' => $records],
                ]);
                return;
            } catch (\Throwable $e) {
                // Fallback
            }
        }

        $records = $this->loadJson($this->recordsFile);
        $filtered = array_values(array_filter($records, function (array $r) use ($businessOwnerId, $since): bool {
            if ((int) ($r['business_owner_id'] ?? 0) !== $businessOwnerId) {
                return false;
            }
            if ($since !== null && $since !== '' && ($r['created_at'] ?? '') < $since) {
                return false;
            }
            return true;
        }));

        Response::json([
            'success' => true,
            'code' => 'SYNC_PULL',
            'data' => ['records' => $filtered],
        ]);
    }

    private function authenticateTenant(Request $request): array
    {
        $ownerId = $request->businessOwnerId();
        $bearer = $request->bearerToken() ?? '';

        if ($ownerId <= 0) {
            Response::json(['success' => false, 'code' => 'TENANT_REQUIRED', 'message' => 'Missing X-Business-Owner-Id header'], 401);
        }

        $pdo = Database::connect();
        if ($pdo !== null) {
            try {
                $stmt = $pdo->prepare('SELECT * FROM businesses WHERE id = :id LIMIT 1');
                $stmt->execute(['id' => $ownerId]);
                $tenant = $stmt->fetch();
                if (!$tenant) {
                    Response::json(['success' => false, 'code' => 'TENANT_NOT_FOUND', 'message' => 'Tenant not found'], 401);
                }
                if ($bearer === '' || !hash_equals((string) $tenant['cloud_token'], $bearer)) {
                    Response::json(['success' => false, 'code' => 'INVALID_TOKEN', 'message' => 'Invalid or expired cloud token'], 401);
                }
                return $tenant;
            } catch (\Throwable $e) {
                // fallback to JSON
            }
        }

        $businesses = $this->loadJson($this->businessesFile);
        $tenant = null;
        foreach ($businesses as $b) {
            if ((int) ($b['id'] ?? 0) === $ownerId) {
                $tenant = $b;
                break;
            }
        }

        if ($tenant === null) {
            Response::json(['success' => false, 'code' => 'TENANT_NOT_FOUND'], 401);
        }

        if ($bearer === '' || !hash_equals((string) ($tenant['cloud_token'] ?? ''), $bearer)) {
            Response::json(['success' => false, 'code' => 'INVALID_TOKEN'], 401);
        }

        return $tenant;
    }

    private function loadJson(string $file): array
    {
        if (!is_file($file)) return [];
        $data = json_decode((string) file_get_contents($file), true);
        return is_array($data) ? $data : [];
    }

    private function saveJson(string $file, array $data): void
    {
        file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
    }
}
