<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Database;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use PDO;

final class CloudApiController
{
    public function health(Request $request): void
    {
        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
        }
        Response::json([
            'success' => true,
            'code' => 'HEALTH_OK',
            'data' => [
                'status' => 'healthy',
                'service' => 'LaundryPro Central Cloud API',
                'database' => 'ok',
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
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
        }
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

            $audit = $pdo->prepare('INSERT INTO cloud_audit_logs (tenant_id, action, details, ip_address) VALUES (?, ?, ?, ?)');
            $audit->execute([$tenantId, 'BUSINESS_REGISTERED', "Registered tenant: $name", $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1']);

            Response::json([
                'success' => true,
                'code' => 'BUSINESS_REGISTERED',
                'data' => [
                    'admin_id' => $tenantId,
                    'cloud_token' => $cloudToken,
                ],
            ]);
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'REGISTRATION_FAILED', 'message' => $e->getMessage()], 500);
        }
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
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
        }

        try {
            $stmt = $pdo->prepare(
                'INSERT INTO sync_records (admin_id, entity_type, entity_local_id, operation, payload, created_at)
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
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'SYNC_FAILED', 'message' => 'Database error'], 500);
        }
    }

    public function centralizedReports(Request $request): void
    {
        $tenant = $this->authenticateTenant($request);
        $ownerId = (int) $tenant['id'];
        
        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE'], 503);
        }
        
        $stmt = $pdo->prepare('SELECT entity_type, COUNT(*) as sync_count, MAX(created_at) as last_sync FROM sync_records WHERE admin_id = ? GROUP BY entity_type');
        $stmt->execute([$ownerId]);
        $aggregations = $stmt->fetchAll() ?: [];
        
        Response::json([
            'success' => true,
            'code' => 'REPORTS_AGGREGATION',
            'data' => [
                'tenant_name' => $tenant['name'],
                'metrics' => $aggregations
            ]
        ]);
    }

    public function uploadBackup(Request $request): void
    {
        $tenant = $this->authenticateTenant($request);
        $ownerId = (int) $tenant['id'];
        
        if (!isset($_FILES['backup']) || $_FILES['backup']['error'] !== UPLOAD_ERR_OK) {
            Response::json(['success' => false, 'code' => 'UPLOAD_ERROR', 'message' => 'No valid backup file provided'], 400);
        }
        
        $tmpPath = $_FILES['backup']['tmp_name'];
        $fileName = basename($_FILES['backup']['name']);
        
        $backupDir = dirname(__DIR__, 2) . '/storage/backups/tenant_' . $ownerId;
        if (!is_dir($backupDir)) {
            mkdir($backupDir, 0775, true);
        }
        
        $dest = $backupDir . '/' . time() . '_' . $fileName;
        if (move_uploaded_file($tmpPath, $dest)) {
            Response::json(['success' => true, 'code' => 'BACKUP_UPLOADED', 'data' => ['file' => $fileName]]);
        } else {
            Response::json(['success' => false, 'code' => 'UPLOAD_FAILED', 'message' => 'Failed to save backup'], 500);
        }
    }

    public function syncPull(Request $request): void
    {
        $tenant = $this->authenticateTenant($request);
        $businessOwnerId = (int) $tenant['id'];
        $since = $request->query('since');

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
        }

        try {
            if ($since !== null && $since !== '') {
                $sinceId = (int) $since;
                $stmt = $pdo->prepare('SELECT id, entity_type, entity_local_id, operation, payload, created_at FROM sync_records WHERE admin_id = :owner AND id > :since ORDER BY id ASC');
                $stmt->execute(['owner' => $businessOwnerId, 'since' => $sinceId]);
            } else {
                $stmt = $pdo->prepare('SELECT id, entity_type, entity_local_id, operation, payload, created_at FROM sync_records WHERE admin_id = :owner ORDER BY id ASC');
                $stmt->execute(['owner' => $businessOwnerId]);
            }
            $rows = $stmt->fetchAll() ?: [];
            $records = [];
            foreach ($rows as $row) {
                $records[] = [
                    'global_sequence' => (int) $row['id'],
                    'admin_id' => $businessOwnerId,
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
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'SYNC_PULL_FAILED', 'message' => 'Database error'], 500);
        }
    }

    private function authenticateTenant(Request $request): array
    {
        $ownerId = $request->businessOwnerId();
        $bearer = $request->bearerToken() ?? '';
        $licenseKey = $request->header('X-License-Key');
        $umac = $request->header('X-Device-UMAC');

        if ($ownerId <= 0) {
            Response::json(['success' => false, 'code' => 'TENANT_REQUIRED', 'message' => 'Missing X-Business-Owner-Id header'], 401);
        }
        
        if (empty($licenseKey)) {
            Response::json(['success' => false, 'code' => 'LICENSE_REQUIRED', 'message' => 'Missing X-License-Key header'], 401);
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
        }

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
            
            // Validate License
            $stmtLic = $pdo->prepare('SELECT * FROM cloud_licenses WHERE license_key = :key AND tenant_id = :id AND status = "active" LIMIT 1');
            $stmtLic->execute(['key' => $licenseKey, 'id' => $ownerId]);
            $license = $stmtLic->fetch();
            
            if (!$license) {
                Response::json(['success' => false, 'code' => 'INVALID_LICENSE', 'message' => 'Invalid or inactive license key'], 401);
            }
            if (!empty($license['expires_at']) && strtotime($license['expires_at']) < time()) {
                Response::json(['success' => false, 'code' => 'LICENSE_EXPIRED', 'message' => 'License has expired'], 401);
            }
            
            // Track and Enforce Branch/Device Limits via UMAC
            if (!empty($umac)) {
                $chk = $pdo->prepare('SELECT id FROM cloud_telemetry WHERE tenant_id = ? AND umac = ? LIMIT 1');
                $chk->execute([$ownerId, $umac]);
                if ($chk->fetch()) {
                    $upd = $pdo->prepare('UPDATE cloud_telemetry SET last_ping_at = NOW() WHERE tenant_id = ? AND umac = ?');
                    $upd->execute([$ownerId, $umac]);
                } else {
                    $ins = $pdo->prepare('INSERT INTO cloud_telemetry (tenant_id, umac, last_ping_at) VALUES (?, ?, NOW())');
                    $ins->execute([$ownerId, $umac]);
                }
                
                $cnt = $pdo->prepare('SELECT COUNT(DISTINCT umac) FROM cloud_telemetry WHERE tenant_id = ?');
                $cnt->execute([$ownerId]);
                $devices = (int) $cnt->fetchColumn();
                
                $maxDevices = $license['plan_type'] === 'enterprise' ? 999 : ($license['plan_type'] === 'premium' ? 5 : 1);
                if ($devices > $maxDevices) {
                    Response::json(['success' => false, 'code' => 'LICENSE_LIMIT_EXCEEDED', 'message' => "Device/branch limit exceeded. Max: $maxDevices"], 403);
                }
            }
            
            return $tenant;
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'AUTH_ERROR', 'message' => 'Database error'], 500);
        }
    }
}
