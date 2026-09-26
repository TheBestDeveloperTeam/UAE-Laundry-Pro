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
        // For local admin, we might just use admin_id = 1 for now if no auth is in place for views
        $adminId = 1;

        // Fetch Metrics
        // 1. New Orders today
        $stmtOrders = $this->db->prepare("SELECT COUNT(*) FROM sales_orders WHERE admin_id = ? AND DATE(created_at) = CURDATE()");
        $stmtOrders->execute([$adminId]);
        $newOrders = (int) $stmtOrders->fetchColumn();

        // 2. Pending Sync Items
        $stmtSync = $this->db->prepare("SELECT COUNT(*) FROM sync_outbox WHERE admin_id = ? AND status = 'pending'");
        $stmtSync->execute([$adminId]);
        $pendingSync = (int) $stmtSync->fetchColumn();
        
        $stmtTotalSync = $this->db->prepare("SELECT COUNT(*) FROM sync_outbox WHERE admin_id = ?");
        $stmtTotalSync->execute([$adminId]);
        $totalSync = (int) $stmtTotalSync->fetchColumn();
        
        $syncStatus = 100;
        if ($totalSync > 0) {
            $synced = $totalSync - $pendingSync;
            $syncStatus = round(($synced / $totalSync) * 100);
        }

        // Pass variables to view
        extract([
            'newOrders' => $newOrders,
            'syncStatus' => $syncStatus,
        ]);

        ob_start();
        require __DIR__ . '/../Views/dashboard.php';
        $html = ob_get_clean();

        // Render HTML response manually since our Response class sends JSON
        header('Content-Type: text/html; charset=utf-8');
        echo $html;
        exit;
    }
}
