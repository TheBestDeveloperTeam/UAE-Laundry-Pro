<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use PDO;

class AdminController
{
    public function __construct(private readonly PDO $db)
    {
    }

    public function dashboard(Request $request, Response $response): void
    {
        $adminId = 1;

        // 1. Orders and Sales today
        $stmtOrders = $this->db->prepare("SELECT COUNT(*), COALESCE(SUM(total_amount), 0), COALESCE(SUM(tax_amount), 0) FROM sales_orders WHERE admin_id = ? AND DATE(created_at) = CURDATE()");
        $stmtOrders->execute([$adminId]);
        $orderMetrics = $stmtOrders->fetch(PDO::FETCH_NUM);
        $newOrders = (int) ($orderMetrics[0] ?? 0);
        $todaySales = (float) ($orderMetrics[1] ?? 0.0);
        $todayVat = (float) ($orderMetrics[2] ?? 0.0);

        // 2. Customers count
        $stmtCust = $this->db->prepare("SELECT COUNT(*) FROM customers WHERE admin_id = ?");
        $stmtCust->execute([$adminId]);
        $totalCustomers = (int) $stmtCust->fetchColumn();

        // 3. Pending Sync Items
        $stmtSync = $this->db->prepare("SELECT COUNT(*) FROM sync_outbox WHERE admin_id = ? AND status = 'pending'");
        $stmtSync->execute([$adminId]);
        $pendingSync = (int) $stmtSync->fetchColumn();

        $stmtTotalSync = $this->db->prepare("SELECT COUNT(*) FROM sync_outbox WHERE admin_id = ?");
        $stmtTotalSync->execute([$adminId]);
        $totalSync = (int) $stmtTotalSync->fetchColumn();

        $syncStatus = 100;
        if ($totalSync > 0) {
            $synced = $totalSync - $pendingSync;
            $syncStatus = (int) round(($synced / $totalSync) * 100);
        }

        // Pass variables to view
        extract([
            'newOrders' => $newOrders,
            'todaySales' => $todaySales,
            'todayVat' => $todayVat,
            'totalCustomers' => $totalCustomers,
            'pendingSync' => $pendingSync,
            'syncStatus' => $syncStatus,
        ]);

        ob_start();
        require __DIR__ . '/../Views/dashboard.php';
        $html = ob_get_clean();

        header('Content-Type: text/html; charset=utf-8');
        echo $html;
        exit;
    }
}
