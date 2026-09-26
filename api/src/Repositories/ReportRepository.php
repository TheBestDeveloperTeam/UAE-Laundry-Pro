<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

class ReportRepository
{
    public function __construct(private readonly PDO $db)
    {
    }

    public function getSalesSummary(int $adminId, ?int $branchId, string $dateFrom, string $dateTo): array
    {
        $params = [$adminId, $dateFrom, $dateTo];
        $branchQuery = "";
        if ($branchId) {
            $branchQuery = " AND branch_id = ?";
            $params[] = $branchId;
        }

        $sql = "SELECT DATE(created_at) as sale_date, COUNT(id) as order_count, SUM(grand_total) as total_revenue
                FROM sales_orders
                WHERE admin_id = ? AND status != 'void' AND created_at BETWEEN ? AND ?
                $branchQuery
                GROUP BY DATE(created_at)
                ORDER BY sale_date ASC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getPaymentBreakdown(int $adminId, ?int $branchId, string $dateFrom, string $dateTo): array
    {
        $params = [$adminId, $dateFrom, $dateTo];
        $branchQuery = "";
        if ($branchId) {
            $branchQuery = " AND branch_id = ?";
            $params[] = $branchId;
        }

        $sql = "SELECT payment_method, COUNT(id) as transaction_count, SUM(amount) as total_amount
                FROM payment_transactions
                WHERE admin_id = ? AND status = 'success' AND transaction_date BETWEEN ? AND ?
                $branchQuery
                GROUP BY payment_method";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getArAging(int $adminId): array
    {
        $sql = "SELECT c.id, c.first_name, c.last_name, c.outstanding_balance,
                       SUM(CASE WHEN DATEDIFF(NOW(), i.due_date) BETWEEN 0 AND 30 THEN i.grand_total - i.paid_amount ELSE 0 END) as '0_30_days',
                       SUM(CASE WHEN DATEDIFF(NOW(), i.due_date) BETWEEN 31 AND 60 THEN i.grand_total - i.paid_amount ELSE 0 END) as '31_60_days',
                       SUM(CASE WHEN DATEDIFF(NOW(), i.due_date) BETWEEN 61 AND 90 THEN i.grand_total - i.paid_amount ELSE 0 END) as '61_90_days',
                       SUM(CASE WHEN DATEDIFF(NOW(), i.due_date) > 90 THEN i.grand_total - i.paid_amount ELSE 0 END) as '90_plus_days'
                FROM consumers c
                LEFT JOIN invoices i ON c.id = i.customer_id AND i.admin_id = c.admin_id AND i.status NOT IN ('paid', 'void')
                WHERE c.admin_id = ? AND c.outstanding_balance > 0
                GROUP BY c.id";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([$adminId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getPnL(int $adminId, ?int $branchId, string $dateFrom, string $dateTo): array
    {
        // Revenue from Sales
        $params = [$adminId, $dateFrom, $dateTo];
        $branchQueryRev = $branchId ? " AND branch_id = ?" : "";
        if ($branchId) $params[] = $branchId;

        $revSql = "SELECT SUM(grand_total) FROM sales_orders WHERE admin_id = ? AND status != 'void' AND created_at BETWEEN ? AND ? $branchQueryRev";
        $revStmt = $this->db->prepare($revSql);
        $revStmt->execute($params);
        $revenue = (float)$revStmt->fetchColumn() ?: 0.0;

        // Expenses
        $paramsExp = [$adminId, $dateFrom, $dateTo];
        $branchQueryExp = $branchId ? " AND branch_id = ?" : "";
        if ($branchId) $paramsExp[] = $branchId;

        $expSql = "SELECT category, SUM(amount) as total FROM expenses WHERE admin_id = ? AND expense_date BETWEEN ? AND ? $branchQueryExp GROUP BY category";
        $expStmt = $this->db->prepare($expSql);
        $expStmt->execute($paramsExp);
        $expenses = $expStmt->fetchAll(PDO::FETCH_ASSOC);

        $totalExpenses = 0.0;
        foreach ($expenses as $e) {
            $totalExpenses += (float)$e['total'];
        }

        return [
            'revenue' => $revenue,
            'expenses_breakdown' => $expenses,
            'total_expenses' => $totalExpenses,
            'net_profit' => $revenue - $totalExpenses
        ];
    }
}
