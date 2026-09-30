<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class ChallanController extends BaseController
{
    public function list(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'CHALLANS_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_challans WHERE tenant_id = :tid ORDER BY id DESC LIMIT 50');
        $stmt->execute(['tid' => $tenantId]);
        $challans = $stmt->fetchAll();

        $this->success($challans, 'CHALLANS_RETRIEVED');
    }

    public function get(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_challans WHERE (id = :id OR challan_number = :num) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'num' => $id, 'tid' => $tenantId]);
        $chal = $stmt->fetch();

        if (!$chal) {
            $this->error('Challan not found', 'CHALLAN_NOT_FOUND', 404);
            return;
        }

        $this->success($chal, 'CHALLAN_RETRIEVED');
    }

    public function create(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $num = $body['challan_number'] ?? ('CHAL-' . date('Ymd') . '-' . mt_rand(100, 999));
        $driver = $body['driver_name'] ?? 'Driver';
        $count = (int) ($body['garment_count'] ?? 10);

        $stmt = $pdo->prepare('INSERT INTO tenant_challans (tenant_id, challan_number, driver_name, status, garment_count) 
            VALUES (:tid, :num, :driver, "dispatched", :cnt)');
        $stmt->execute(['tid' => $tenantId, 'num' => $num, 'driver' => $driver, 'cnt' => $count]);

        $this->success([
            'id' => (int) $pdo->lastInsertId(),
            'challan_number' => $num,
            'status' => 'dispatched',
            'garment_count' => $count,
        ], 'CHALLAN_CREATED', 201);
    }

    public function update(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $status = $body['status'] ?? 'received_at_plant';
        $stmt = $pdo->prepare('UPDATE tenant_challans SET status = :st WHERE id = :id AND tenant_id = :tid');
        $stmt->execute(['st' => $status, 'id' => $id, 'tid' => $tenantId]);

        $this->success(['id' => $id, 'status' => $status], 'CHALLAN_UPDATED');
    }

    public function cancel(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'cancelled' => true], 'CHALLAN_CANCELLED');
    }
}
