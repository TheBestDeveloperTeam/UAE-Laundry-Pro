<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class AnalyticsRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return list<array<string, mixed>> */
  public function trends(string $metricKey, string $from, string $to, ?int $branchId = null): array
  {
    $sql = 'SELECT snapshot_date, metric_value FROM analytics_daily_snapshots
            WHERE business_owner_id = :owner AND metric_key = :key
            AND snapshot_date BETWEEN :from AND :to';
    $params = ['owner' => $this->businessOwnerId, 'key' => $metricKey, 'from' => $from, 'to' => $to];
    if ($branchId !== null) {
      $sql .= ' AND branch_id = :branch';
      $params['branch'] = $branchId;
    } else {
      $sql .= ' AND branch_id IS NULL';
    }
    $sql .= ' ORDER BY snapshot_date';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  public function upsertSnapshot(string $date, string $metricKey, float $value, ?int $branchId = null): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO analytics_daily_snapshots (business_owner_id, branch_id, snapshot_date, metric_key, metric_value)
       VALUES (:owner, :branch, :date, :key, :val)
       ON DUPLICATE KEY UPDATE metric_value = :val2'
    );
    $stmt->execute([
      'owner' => $this->businessOwnerId,
      'branch' => $branchId,
      'date' => $date,
      'key' => $metricKey,
      'val' => $value,
      'val2' => $value,
    ]);
  }

  /** @return array<string, float> */
  public function computeTodayMetrics(?int $branchId = null): array
  {
    $today = date('Y-m-d');
    $branchFilter = $branchId !== null ? ' AND branch_id = ' . (int) $branchId : '';

    $salesStmt = $this->pdo->prepare(
      "SELECT COALESCE(SUM(grand_total), 0) FROM sales_orders
       WHERE business_owner_id = :owner AND DATE(created_at) = :today AND status != 'cancelled'{$branchFilter}"
    );
    $salesStmt->execute(['owner' => $this->businessOwnerId, 'today' => $today]);
    $sales = (float) $salesStmt->fetchColumn();

    $ordersStmt = $this->pdo->prepare(
      "SELECT COUNT(*) FROM sales_orders
       WHERE business_owner_id = :owner AND DATE(created_at) = :today{$branchFilter}"
    );
    $ordersStmt->execute(['owner' => $this->businessOwnerId, 'today' => $today]);
    $orders = (float) $ordersStmt->fetchColumn();

    return ['sales_total' => $sales, 'order_count' => $orders];
  }
}
