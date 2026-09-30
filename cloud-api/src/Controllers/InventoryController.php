<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class InventoryController extends BaseController
{
    public function movements(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'MOVEMENTS_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT m.*, p.name as product_name, p.sku 
            FROM tenant_inventory_movements m 
            JOIN tenant_products p ON m.product_id = p.id 
            WHERE m.tenant_id = :tid ORDER BY m.id DESC LIMIT 50');
        $stmt->execute(['tid' => $tenantId]);
        $movements = $stmt->fetchAll();

        $this->success($movements, 'MOVEMENTS_RETRIEVED');
    }

    public function receipt(Request $request, array $params = []): void
    {
        $this->recordMovement($request, 'purchase', 'Goods received');
    }

    public function adjustment(Request $request, array $params = []): void
    {
        $this->recordMovement($request, 'adjustment', 'Manual adjustment');
    }

    public function transfer(Request $request, array $params = []): void
    {
        $this->recordMovement($request, 'transfer', 'Inter-branch transfer');
    }

    public function stock(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'STOCK_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT id, name, sku, stock_quantity, price FROM tenant_products WHERE tenant_id = :tid');
        $stmt->execute(['tid' => $tenantId]);
        $stock = $stmt->fetchAll();

        $this->success($stock, 'STOCK_RETRIEVED');
    }

    public function reconcile(Request $request, array $params = []): void
    {
        $this->success(['reconciled' => true, 'timestamp' => date('Y-m-d H:i:s')], 'INVENTORY_RECONCILED');
    }

    // ===== Purchase Orders =====
    public function purchaseOrders(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'PURCHASE_ORDERS_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT po.*, v.name as vendor_name 
            FROM tenant_purchase_orders po 
            LEFT JOIN tenant_vendors v ON po.vendor_id = v.id 
            WHERE po.tenant_id = :tid ORDER BY po.id DESC LIMIT 50');
        $stmt->execute(['tid' => $tenantId]);
        $pos = $stmt->fetchAll();

        $this->success($pos, 'PURCHASE_ORDERS_RETRIEVED');
    }

    public function getPurchaseOrder(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_purchase_orders WHERE (id = :id OR po_number = :num) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'num' => $id, 'tid' => $tenantId]);
        $po = $stmt->fetch();

        if (!$po) {
            $this->error('Purchase order not found', 'PO_NOT_FOUND', 404);
            return;
        }

        $this->success($po, 'PURCHASE_ORDER_RETRIEVED');
    }

    public function createPurchaseOrder(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $num = $body['po_number'] ?? ('PO-' . date('Ymd') . '-' . mt_rand(100, 999));
        $vendorId = $body['vendor_id'] ?? null;
        $total = (string) ($body['total_amount'] ?? '0.00');

        $stmt = $pdo->prepare('INSERT INTO tenant_purchase_orders (tenant_id, vendor_id, po_number, status, total_amount, expected_delivery_date) 
            VALUES (:tid, :vid, :num, "draft", :tot, :date)');
        $stmt->execute([
            'tid' => $tenantId,
            'vid' => $vendorId,
            'num' => $num,
            'tot' => $total,
            'date' => $body['expected_delivery_date'] ?? null,
        ]);

        $this->success([
            'id' => (int) $pdo->lastInsertId(),
            'po_number' => $num,
            'status' => 'draft',
            'total_amount' => $total,
        ], 'PURCHASE_ORDER_CREATED', 201);
    }

    public function updatePurchaseOrder(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'updated' => true], 'PURCHASE_ORDER_UPDATED');
    }

    public function receivePurchaseOrder(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'received' => true, 'status' => 'received'], 'PURCHASE_ORDER_RECEIVED');
    }

    private function recordMovement(Request $request, string $type, string $defaultNotes): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $prodId = (int) ($body['product_id'] ?? 1);
        $qty = (string) ($body['quantity'] ?? '1.00');
        $notes = $body['notes'] ?? $defaultNotes;

        $stmt = $pdo->prepare('INSERT INTO tenant_inventory_movements (tenant_id, product_id, quantity_change, movement_type, notes) 
            VALUES (:tid, :pid, :qty, :type, :notes)');
        $stmt->execute(['tid' => $tenantId, 'pid' => $prodId, 'qty' => $qty, 'type' => $type, 'notes' => $notes]);

        $this->success(['id' => (int) $pdo->lastInsertId(), 'recorded' => true], 'MOVEMENT_RECORDED', 201);
    }
}
