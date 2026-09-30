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
            return;
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

    public function openapiJson(Request $request): void
    {
        $specPath = dirname(__DIR__, 2) . '/docs/swagger/cloud-api.json';
        if (!file_exists($specPath)) {
            $specPath = dirname(__DIR__, 2) . '/api/docs/openapi.json';
        }
        if (file_exists($specPath)) {
            header('Content-Type: application/json; charset=utf-8');
            echo file_get_contents($specPath);
            exit;
        }
        Response::json([
            'openapi' => '3.0.3',
            'info' => ['title' => 'LaundryPro Cloud API', 'version' => '2.0.0'],
            'paths' => new \stdClass(),
        ]);
    }

    public function docs(Request $request): void
    {
        header('Content-Type: text/html; charset=utf-8');
        echo '<!DOCTYPE html><html><head><title>LaundryPro Cloud API Docs</title><link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css"></head><body><div id="swagger-ui"></div><script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script><script>SwaggerUIBundle({url:"/api/v1/docs/openapi.json",dom_id:"#swagger-ui"});</script></body></html>';
        exit;
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
                'INSERT INTO businesses (uuid, name, license_key, cloud_token, status, created_at)
                 VALUES (:uuid, :name, :key, :token, "active", NOW())'
            );
            $stmt->execute([
                'uuid' => $uuid = $this->generateUuid(),
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
                    'tenant_uuid' => $uuid,
                    'cloud_token' => $cloudToken,
                ],
            ]);
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'REGISTRATION_FAILED', 'message' => $e->getMessage()], 500);
        }
    }

    public function validateLicense(Request $request): void
    {
        $body = $request->body();
        $licenseKey = trim((string) ($body['license_key'] ?? $request->header('X-License-Key') ?? ''));
        $umac = trim((string) ($body['umac'] ?? $request->header('X-Device-UMAC') ?? ''));
        $workstationName = (string) ($body['workstation_name'] ?? '');
        $appVersion = (string) ($body['app_version'] ?? '');

        if ($licenseKey === '') {
            Response::json(['success' => false, 'code' => 'LICENSE_KEY_REQUIRED', 'message' => 'License key is required'], 400);
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
            return;
        }

        try {
            $stmt = $pdo->prepare('SELECT l.*, b.name as tenant_name, b.status as tenant_status FROM cloud_licenses l JOIN businesses b ON b.id = l.tenant_id WHERE l.license_key = :key LIMIT 1');
            $stmt->execute(['key' => $licenseKey]);
            $license = $stmt->fetch();

            if (!$license) {
                Response::json(['success' => false, 'code' => 'LICENSE_NOT_FOUND', 'message' => 'Invalid or unissued license key'], 404);
                return;
            }

            if ($license['status'] !== 'active') {
                Response::json(['success' => false, 'code' => 'LICENSE_INACTIVE', 'message' => 'License is ' . $license['status']], 403);
                return;
            }

            if (!empty($license['expires_at']) && strtotime((string) $license['expires_at']) < time()) {
                Response::json(['success' => false, 'code' => 'LICENSE_EXPIRED', 'message' => 'License has expired'], 403);
                return;
            }

            $tenantId = (int) $license['tenant_id'];

            // Telemetry & Hardware registration
            if ($umac !== '') {
                $tel = $pdo->prepare('INSERT INTO cloud_telemetry (tenant_id, umac, workstation_name, app_version, last_ping_at) VALUES (?, ?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE workstation_name = VALUES(workstation_name), app_version = VALUES(app_version), last_ping_at = NOW()');
                $tel->execute([$tenantId, $umac, $workstationName, $appVersion]);
            }

            $payload = json_encode([
                'license_key' => $licenseKey,
                'umac' => $umac,
                'plan_type' => $license['plan_type'],
                'expires_at' => $license['expires_at'],
            ]);
            $sig = hash_hmac('sha256', (string) $payload, 'LaundryProCloudSecret2026');

            Response::json([
                'success' => true,
                'code' => 'LICENSE_VALID',
                'data' => [
                    'valid' => true,
                    'tenant_id' => $tenantId,
                    'tenant_name' => $license['tenant_name'],
                    'plan_type' => $license['plan_type'],
                    'max_branches' => (int) $license['max_branches'],
                    'max_devices' => (int) $license['max_devices'],
                    'expires_at' => $license['expires_at'],
                    'signature' => $sig,
                ]
            ]);
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'SERVER_ERROR', 'message' => $e->getMessage()], 500);
        }
    }

    private function generateUuid(): string
    {
        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );
    }

    public function syncPush(Request $request): void
    {
        $tenant = $this->authenticateTenant($request);
        $tenantId = (int) $tenant['id'];
        $body = $request->body();
        if (!is_array($body)) {
            $body = [];
        }

        // Support either direct array of records or {"batch": [...]}
        $batch = isset($body['batch']) && is_array($body['batch']) ? $body['batch'] : $body;

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
            return;
        }

        $accepted = [];
        $rejected = [];
        $umac = (string) ($request->header('X-Device-UMAC') ?? '');

        try {
            $stmt = $pdo->prepare(
                'INSERT INTO sync_records (tenant_id, entity_type, entity_uuid, entity_local_id, operation, payload, entity_version, source_umac, received_at)
                 VALUES (:tenant, :type, :uuid, :local_id, :op, :payload, :version, :umac, NOW())
                 ON DUPLICATE KEY UPDATE payload = VALUES(payload), operation = VALUES(operation), entity_version = VALUES(entity_version), received_at = NOW()'
            );

            foreach ($batch as $item) {
                if (!is_array($item)) continue;

                $entityType = (string) ($item['entity_type'] ?? 'unknown');
                $entityUuid = (string) ($item['entity_uuid'] ?? '');
                if ($entityUuid === '') {
                    $entityUuid = sprintf(
                        '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                        mt_rand(0, 0xffff),
                        mt_rand(0, 0x0fff) | 0x4000,
                        mt_rand(0, 0x3fff) | 0x8000,
                        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
                    );
                }

                $localId = (int) ($item['entity_local_id'] ?? 0);
                $op = strtoupper((string) ($item['operation'] ?? 'INSERT'));
                if (!in_array($op, ['INSERT', 'UPDATE', 'DELETE'], true)) {
                    $op = 'INSERT';
                }

                $version = (int) ($item['entity_version'] ?? 1);
                $payloadData = $item['payload'] ?? [];
                $payloadJson = is_string($payloadData) ? $payloadData : json_encode($payloadData);

                try {
                    $stmt->execute([
                        'tenant' => $tenantId,
                        'type' => $entityType,
                        'uuid' => $entityUuid,
                        'local_id' => $localId,
                        'op' => $op,
                        'payload' => $payloadJson,
                        'version' => $version,
                        'umac' => $umac,
                    ]);

                    // Materialize into tenant domain tables
                    $this->projectTenantEntity($pdo, $tenantId, $entityType, $entityUuid, $op, $payloadData);

                    $accepted[] = $entityUuid;
                } catch (\Throwable $itemErr) {
                    $rejected[] = [
                        'uuid' => $entityUuid,
                        'error' => $itemErr->getMessage(),
                    ];
                }
            }

            Response::json([
                'success' => true,
                'code' => 'SYNC_RECEIVED',
                'data' => [
                    'accepted_count' => count($accepted),
                    'rejected_count' => count($rejected),
                    'accepted' => $accepted,
                    'rejected' => $rejected,
                ],
            ]);
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'SYNC_FAILED', 'message' => $e->getMessage()], 500);
        }
    }

    public function centralizedReports(Request $request): void
    {
        $tenant = $this->authenticateTenant($request);
        $tenantId = (int) $tenant['id'];

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE'], 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT entity_type, COUNT(*) as sync_count, MAX(received_at) as last_sync FROM sync_records WHERE tenant_id = ? GROUP BY entity_type');
        $stmt->execute([$tenantId]);
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
        $tenantId = (int) $tenant['id'];
        $since = $request->query('since');

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database connection failed'], 503);
            return;
        }

        try {
            if ($since !== null && $since !== '') {
                $sinceId = (int) $since;
                $stmt = $pdo->prepare('SELECT id, entity_type, entity_uuid, entity_local_id, operation, payload, entity_version, received_at FROM sync_records WHERE tenant_id = :tenant AND id > :since ORDER BY id ASC LIMIT 500');
                $stmt->execute(['tenant' => $tenantId, 'since' => $sinceId]);
            } else {
                $stmt = $pdo->prepare('SELECT id, entity_type, entity_uuid, entity_local_id, operation, payload, entity_version, received_at FROM sync_records WHERE tenant_id = :tenant ORDER BY id ASC LIMIT 500');
                $stmt->execute(['tenant' => $tenantId]);
            }
            $rows = $stmt->fetchAll() ?: [];
            $records = [];
            foreach ($rows as $row) {
                $records[] = [
                    'global_sequence' => (int) $row['id'],
                    'tenant_id' => $tenantId,
                    'entity_type' => $row['entity_type'],
                    'entity_uuid' => $row['entity_uuid'],
                    'entity_local_id' => (int) $row['entity_local_id'],
                    'operation' => $row['operation'],
                    'payload' => is_string($row['payload']) ? json_decode($row['payload'], true) : $row['payload'],
                    'entity_version' => (int) ($row['entity_version'] ?? 1),
                    'received_at' => $row['received_at'],
                ];
            }

            Response::json([
                'success' => true,
                'code' => 'SYNC_PULL',
                'data' => [
                    'count' => count($records),
                    'records' => $records,
                ],
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

    private function projectTenantEntity(PDO $pdo, int $tenantId, string $entityType, string $entityUuid, string $op, $payload): void
    {
        if (!is_array($payload)) {
            return;
        }

        $normalizedType = strtolower(trim($entityType));

        try {
            if (in_array($normalizedType, ['customer', 'customers'], true)) {
                $name = (string) ($payload['name'] ?? $payload['full_name'] ?? '');
                $phone = (string) ($payload['phone'] ?? $payload['mobile'] ?? '');
                if ($name !== '' || $phone !== '') {
                    $code = (string) ($payload['customer_code'] ?? $payload['code'] ?? ('CUST-' . substr($entityUuid, 0, 6)));
                    $email = isset($payload['email']) ? (string) $payload['email'] : null;
                    $address = isset($payload['address']) ? (string) $payload['address'] : null;
                    $emirate = (string) ($payload['emirate'] ?? 'Dubai');
                    $credit = (float) ($payload['credit_limit'] ?? 0.0);
                    $balance = (float) ($payload['outstanding_balance'] ?? $payload['balance'] ?? 0.0);

                    $stmt = $pdo->prepare(
                        'INSERT INTO tenant_customers (tenant_id, uuid, customer_code, name, phone, email, address, emirate, credit_limit, outstanding_balance, is_active)
                         VALUES (:t, :u, :c, :n, :p, :e, :a, :em, :cl, :ob, 1)
                         ON DUPLICATE KEY UPDATE name = VALUES(name), phone = VALUES(phone), email = VALUES(email), address = VALUES(address), outstanding_balance = VALUES(outstanding_balance)'
                    );
                    $stmt->execute([
                        't' => $tenantId, 'u' => $entityUuid, 'c' => $code, 'n' => $name, 'p' => $phone,
                        'e' => $email, 'a' => $address, 'em' => $emirate, 'cl' => $credit, 'ob' => $balance
                    ]);
                }
            } elseif (in_array($normalizedType, ['service', 'services'], true)) {
                $name = (string) ($payload['name'] ?? '');
                if ($name !== '') {
                    $code = (string) ($payload['service_code'] ?? $payload['code'] ?? ('SRV-' . substr($entityUuid, 0, 6)));
                    $price = (float) ($payload['price'] ?? 0.0);
                    $turnaround = (int) ($payload['turnaround_hours'] ?? 48);

                    $stmt = $pdo->prepare(
                        'INSERT INTO tenant_services (tenant_id, uuid, name, service_code, price, turnaround_hours, is_active)
                         VALUES (:t, :u, :n, :c, :p, :th, 1)
                         ON DUPLICATE KEY UPDATE name = VALUES(name), price = VALUES(price), turnaround_hours = VALUES(turnaround_hours)'
                    );
                    $stmt->execute(['t' => $tenantId, 'u' => $entityUuid, 'n' => $name, 'c' => $code, 'p' => $price, 'th' => $turnaround]);
                }
            } elseif (in_array($normalizedType, ['order', 'orders', 'sales_orders'], true)) {
                $orderNumber = (string) ($payload['order_number'] ?? $payload['invoice_number'] ?? ('ORD-' . substr($entityUuid, 0, 8)));
                $status = (string) ($payload['status'] ?? 'confirmed');
                $payStatus = (string) ($payload['payment_status'] ?? 'unpaid');
                $subtotal = (float) ($payload['subtotal'] ?? 0.0);
                $vatAmount = (float) ($payload['vat_amount'] ?? 0.0);
                $totalAmount = (float) ($payload['total_amount'] ?? ($subtotal + $vatAmount));
                $branch = (string) ($payload['source_branch'] ?? $payload['branch'] ?? 'Main Store');

                $stmt = $pdo->prepare(
                    'INSERT INTO tenant_sales_orders (tenant_id, uuid, order_number, status, payment_status, subtotal, vat_amount, total_amount, source_branch)
                     VALUES (:t, :u, :on, :s, :ps, :sub, :vat, :tot, :b)
                     ON DUPLICATE KEY UPDATE status = VALUES(status), payment_status = VALUES(payment_status), total_amount = VALUES(total_amount)'
                );
                $stmt->execute([
                    't' => $tenantId, 'u' => $entityUuid, 'on' => $orderNumber, 's' => $status,
                    'ps' => $payStatus, 'sub' => $subtotal, 'vat' => $vatAmount, 'tot' => $totalAmount, 'b' => $branch
                ]);
            }
        } catch (\Throwable $e) {
            // Non-blocking projection error
        }
    }
}

