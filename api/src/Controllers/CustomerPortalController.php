<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use PDO;

class CustomerPortalController
{
    public function __construct(private readonly PDO $db)
    {
    }

    /**
     * Get consumer's orders
     */
    public function getMyOrders(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $customerId = $request->getAttribute('customer_id');

        if (!$adminId || !$customerId) {
            $response->error(401, 'Unauthorized consumer token required');
            return;
        }

        $stmt = $this->db->prepare("SELECT * FROM sales_orders WHERE admin_id = ? AND customer_id = ? ORDER BY created_at DESC");
        $stmt->execute([$adminId, $customerId]);
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $response->success($orders, 'Orders retrieved');
    }

    /**
     * Get consumer's invoices and ledger
     */
    public function getMyLedger(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $customerId = $request->getAttribute('customer_id');

        if (!$adminId || !$customerId) {
            $response->error(401, 'Unauthorized consumer token required');
            return;
        }

        $invStmt = $this->db->prepare("SELECT * FROM invoices WHERE admin_id = ? AND customer_id = ? ORDER BY created_at DESC");
        $invStmt->execute([$adminId, $customerId]);
        $invoices = $invStmt->fetchAll(PDO::FETCH_ASSOC);

        $ledgStmt = $this->db->prepare("SELECT * FROM customer_ledger WHERE admin_id = ? AND customer_id = ? ORDER BY id DESC LIMIT 50");
        $ledgStmt->execute([$adminId, $customerId]);
        $ledger = $ledgStmt->fetchAll(PDO::FETCH_ASSOC);

        $response->success([
            'invoices' => $invoices,
            'ledger' => $ledger
        ], 'Financials retrieved');
    }
}
