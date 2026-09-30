<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class SalesController extends BaseController
{
    public function list(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        $page = max(1, (int) ($request->query('page') ?? 1));
        $limit = min(100, max(1, (int) ($request->query('limit') ?? 25)));
        $offset = ($page - 1) * $limit;
        $status = $request->query('status');

        if ($pdo === null) {
            $this->success(['items' => [], 'pagination' => ['page' => 1, 'limit' => $limit, 'total' => 0]], 'ORDERS_RETRIEVED');
            return;
        }

        $sql = 'SELECT o.*, c.name as customer_name, c.phone as customer_phone 
                FROM tenant_sales_orders o 
                LEFT JOIN tenant_customers c ON o.customer_id = c.id 
                WHERE o.tenant_id = :tid';
        $binds = ['tid' => $tenantId];

        if ($status !== null && $status !== '') {
            $sql .= ' AND o.status = :status';
            $binds['status'] = $status;
        }

        $sql .= ' ORDER BY o.id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($binds);
        $orders = $stmt->fetchAll();

        $countStmt = $pdo->prepare('SELECT COUNT(*) FROM tenant_sales_orders WHERE tenant_id = :tid' . ($status !== null && $status !== '' ? ' AND status = :status' : ''));
        $countStmt->execute($binds);
        $total = (int) $countStmt->fetchColumn();

        $this->success([
            'items' => $orders,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => ceil($total / $limit),
            ],
        ], 'ORDERS_RETRIEVED');
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

        $stmt = $pdo->prepare('SELECT o.*, c.name as customer_name, c.phone as customer_phone 
            FROM tenant_sales_orders o 
            LEFT JOIN tenant_customers c ON o.customer_id = c.id 
            WHERE (o.id = :id OR o.uuid = :uuid OR o.order_number = :num) AND o.tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'num' => $id, 'tid' => $tenantId]);
        $order = $stmt->fetch();

        if (!$order) {
            $this->error('Order not found', 'ORDER_NOT_FOUND', 404);
            return;
        }

        // Fetch lines
        $lineStmt = $pdo->prepare('SELECT * FROM tenant_sales_order_lines WHERE order_id = :oid AND tenant_id = :tid');
        $lineStmt->execute(['oid' => $order['id'], 'tid' => $tenantId]);
        $order['lines'] = $lineStmt->fetchAll();

        // Fetch payments
        $payStmt = $pdo->prepare('SELECT * FROM tenant_payment_transactions WHERE order_id = :oid AND tenant_id = :tid');
        $payStmt->execute(['oid' => $order['id'], 'tid' => $tenantId]);
        $order['payments'] = $payStmt->fetchAll();

        $this->success($order, 'ORDER_RETRIEVED');
    }

    public function draft(Request $request, array $params = []): void
    {
        $this->createOrderWithStatus($request, 'draft');
    }

    public function confirm(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('UPDATE tenant_sales_orders SET status = "confirmed" WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);

        $this->success(['id' => $id, 'status' => 'confirmed'], 'ORDER_CONFIRMED');
    }

    public function payment(Request $request, array $params = []): void
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

        $stmt = $pdo->prepare('SELECT id, total_amount FROM tenant_sales_orders WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $order = $stmt->fetch();

        if (!$order) {
            $this->error('Order not found', 'ORDER_NOT_FOUND', 404);
            return;
        }

        $amount = (string) ($body['amount'] ?? $order['total_amount']);
        $tender = (string) ($body['tender_type'] ?? 'cash');
        $ref = $body['reference_no'] ?? null;

        $payStmt = $pdo->prepare('INSERT INTO tenant_payment_transactions (tenant_id, order_id, tender_type, amount, reference_no) 
            VALUES (:tid, :oid, :tender, :amount, :ref)');
        $payStmt->execute([
            'tid' => $tenantId,
            'oid' => $order['id'],
            'tender' => $tender,
            'amount' => $amount,
            'ref' => $ref,
        ]);

        $updateOrder = $pdo->prepare('UPDATE tenant_sales_orders SET payment_status = "paid" WHERE id = :id');
        $updateOrder->execute(['id' => $order['id']]);

        $this->success(['order_id' => $order['id'], 'paid' => true, 'amount' => $amount], 'PAYMENT_RECORDED', 201);
    }

    public function updateStatus(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $newStatus = (string) ($body['status'] ?? 'in_process');
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('UPDATE tenant_sales_orders SET status = :st WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid');
        $stmt->execute(['st' => $newStatus, 'id' => $id, 'uuid' => $id, 'tid' => $tenantId]);

        $this->success(['id' => $id, 'status' => $newStatus], 'ORDER_STATUS_UPDATED');
    }

    public function statusHistory(Request $request, array $params = []): void
    {
        $this->success([
            ['status' => 'draft', 'created_at' => date('Y-m-d H:i:s', time() - 3600)],
            ['status' => 'confirmed', 'created_at' => date('Y-m-d H:i:s')],
        ], 'ORDER_HISTORY_RETRIEVED');
    }

    public function deliveryTasks(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'DELIVERY_TASKS_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_delivery_tasks WHERE order_id = :oid AND tenant_id = :tid');
        $stmt->execute(['oid' => $id, 'tid' => $tenantId]);
        $tasks = $stmt->fetchAll();

        $this->success($tasks, 'DELIVERY_TASKS_RETRIEVED');
    }

    public function createDeliveryTask(Request $request, array $params = []): void
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

        $driver = $body['driver_name'] ?? 'Driver 1';
        $type = $body['task_type'] ?? 'delivery';

        $stmt = $pdo->prepare('INSERT INTO tenant_delivery_tasks (tenant_id, order_id, driver_name, task_type, status) 
            VALUES (:tid, :oid, :driver, :type, "pending")');
        $stmt->execute(['tid' => $tenantId, 'oid' => $id, 'driver' => $driver, 'type' => $type]);

        $this->success(['id' => (int) $pdo->lastInsertId(), 'created' => true], 'DELIVERY_TASK_CREATED', 201);
    }

    // ===== Invoices =====
    public function invoices(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'INVOICES_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_invoices WHERE tenant_id = :tid ORDER BY id DESC LIMIT 50');
        $stmt->execute(['tid' => $tenantId]);
        $invoices = $stmt->fetchAll();

        $this->success($invoices, 'INVOICES_RETRIEVED');
    }

    public function getInvoice(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_invoices WHERE (id = :id OR invoice_number = :num) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'num' => $id, 'tid' => $tenantId]);
        $inv = $stmt->fetch();

        if (!$inv) {
            $this->error('Invoice not found', 'INVOICE_NOT_FOUND', 404);
            return;
        }

        $this->success($inv, 'INVOICE_RETRIEVED');
    }

    public function postInvoice(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'posted' => true], 'INVOICE_POSTED');
    }

    public function correctInvoice(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'corrected' => true], 'INVOICE_CORRECTED');
    }

    private function createOrderWithStatus(Request $request, string $status): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $uuid = $body['uuid'] ?? $this->generateUuid();
        $orderNumber = $body['order_number'] ?? ('ORD-' . date('Ymd') . '-' . mt_rand(1000, 9999));
        $customerId = $body['customer_id'] ?? null;
        $lines = $body['lines'] ?? [];

        $subtotal = '0.00';
        foreach ($lines as $line) {
            $qty = (string) ($line['quantity'] ?? '1');
            $unitPrice = (string) ($line['unit_price'] ?? '0.00');
            $lineSub = bcmul($qty, $unitPrice, 2);
            $subtotal = bcadd($subtotal, $lineSub, 2);
        }

        $tax = $this->calculateVat5($subtotal);

        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare('INSERT INTO tenant_sales_orders 
                (tenant_id, uuid, order_number, customer_id, status, payment_status, subtotal, vat_amount, total_amount, source_branch) 
                VALUES (:tid, :uuid, :num, :cid, :status, "unpaid", :subtotal, :vat, :total, :branch)');
            $stmt->execute([
                'tid' => $tenantId,
                'uuid' => $uuid,
                'num' => $orderNumber,
                'cid' => $customerId,
                'status' => $status,
                'subtotal' => $tax['subtotal'],
                'vat' => $tax['vat'],
                'total' => $tax['total'],
                'branch' => $body['source_branch'] ?? 'Main Branch',
            ]);

            $orderId = (int) $pdo->lastInsertId();

            if (!empty($lines)) {
                $lineStmt = $pdo->prepare('INSERT INTO tenant_sales_order_lines 
                    (tenant_id, order_id, service_id, item_name, quantity, unit_price, vat_amount, total_amount, notes) 
                    VALUES (:tid, :oid, :sid, :name, :qty, :price, :vat, :total, :notes)');

                foreach ($lines as $line) {
                    $qty = (int) ($line['quantity'] ?? 1);
                    $price = (string) ($line['unit_price'] ?? '0.00');
                    $lineTotal = bcmul((string) $qty, $price, 2);
                    $lineVat = bcmul($lineTotal, '0.05', 2);
                    $lineGross = bcadd($lineTotal, $lineVat, 2);

                    $lineStmt->execute([
                        'tid' => $tenantId,
                        'oid' => $orderId,
                        'sid' => $line['service_id'] ?? null,
                        'name' => $line['item_name'] ?? 'Laundry Service',
                        'qty' => $qty,
                        'price' => $price,
                        'vat' => $lineVat,
                        'total' => $lineGross,
                        'notes' => $line['notes'] ?? null,
                    ]);
                }
            }

            // Create Invoice Record
            $invStmt = $pdo->prepare('INSERT INTO tenant_invoices 
                (tenant_id, order_id, invoice_number, invoice_date, subtotal, vat_amount, total_amount, status) 
                VALUES (:tid, :oid, :num, CURDATE(), :sub, :vat, :tot, "posted")');
            $invStmt->execute([
                'tid' => $tenantId,
                'oid' => $orderId,
                'num' => 'INV-' . $orderNumber,
                'sub' => $tax['subtotal'],
                'vat' => $tax['vat'],
                'tot' => $tax['total'],
            ]);

            $pdo->commit();

            $this->success([
                'id' => $orderId,
                'uuid' => $uuid,
                'order_number' => $orderNumber,
                'status' => $status,
                'subtotal' => $tax['subtotal'],
                'vat_amount' => $tax['vat'],
                'total_amount' => $tax['total'],
                'currency' => 'AED',
            ], 'ORDER_CREATED', 201);
        } catch (\Throwable $e) {
            $pdo->rollBack();
            $this->error('Failed to create order: ' . $e->getMessage(), 'ORDER_CREATE_FAILED', 500);
        }
    }
}
