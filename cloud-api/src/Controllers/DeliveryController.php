<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class DeliveryController extends BaseController
{
    public function list(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'DELIVERY_TASKS_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT d.*, o.order_number, c.name as customer_name, c.phone as customer_phone 
            FROM tenant_delivery_tasks d 
            LEFT JOIN tenant_sales_orders o ON d.order_id = o.id 
            LEFT JOIN tenant_customers c ON o.customer_id = c.id 
            WHERE d.tenant_id = :tid ORDER BY d.id DESC LIMIT 50');
        $stmt->execute(['tid' => $tenantId]);
        $tasks = $stmt->fetchAll();

        $this->success($tasks, 'DELIVERY_TASKS_RETRIEVED');
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

        $stmt = $pdo->prepare('SELECT * FROM tenant_delivery_tasks WHERE id = :id AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'tid' => $tenantId]);
        $task = $stmt->fetch();

        if (!$task) {
            $this->error('Task not found', 'TASK_NOT_FOUND', 404);
            return;
        }

        $this->success($task, 'DELIVERY_TASK_RETRIEVED');
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

        $orderId = (int) ($body['order_id'] ?? 1);
        $driver = $body['driver_name'] ?? 'Assigned Driver';
        $type = $body['task_type'] ?? 'delivery';

        $stmt = $pdo->prepare('INSERT INTO tenant_delivery_tasks (tenant_id, order_id, driver_name, task_type, status) 
            VALUES (:tid, :oid, :driver, :type, "assigned")');
        $stmt->execute(['tid' => $tenantId, 'oid' => $orderId, 'driver' => $driver, 'type' => $type]);

        $this->success(['id' => (int) $pdo->lastInsertId(), 'created' => true], 'DELIVERY_TASK_CREATED', 201);
    }

    public function patch(Request $request, array $params = []): void
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

        $status = $body['status'] ?? 'out_for_delivery';
        $stmt = $pdo->prepare('UPDATE tenant_delivery_tasks SET status = :st WHERE id = :id AND tenant_id = :tid');
        $stmt->execute(['st' => $status, 'id' => $id, 'tid' => $tenantId]);

        $this->success(['id' => $id, 'status' => $status], 'DELIVERY_TASK_UPDATED');
    }

    public function complete(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('UPDATE tenant_delivery_tasks SET status = "delivered", completed_at = NOW() WHERE id = :id AND tenant_id = :tid');
        $stmt->execute(['id' => $id, 'tid' => $tenantId]);

        $this->success(['id' => $id, 'status' => 'delivered', 'completed_at' => date('Y-m-d H:i:s')], 'DELIVERY_TASK_COMPLETED');
    }
}
