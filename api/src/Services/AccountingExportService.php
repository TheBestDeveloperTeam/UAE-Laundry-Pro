<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use LaundryPro\Api\Repositories\AccountingRepository;
use PDO;

final class AccountingExportService
{
  public function __construct(
    private readonly AccountingRepository $accounting,
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @param array<string, mixed> $data */
  public function createExport(array $data, int $userId): array
  {
    $batch = $this->accounting->createBatch($data, $userId);
    $batchId = (int) $batch['id'];
    $lines = $this->buildLines((string) $data['period_start'], (string) $data['period_end']);
    $this->accounting->addLines($batchId, $lines);
    $this->accounting->markExported($batchId, 'export_' . $batch['uuid'] . '.csv');

    return [
      'batch' => $this->accounting->findBatch($batchId),
      'lines' => $this->accounting->batchLines($batchId),
    ];
  }

  /** @return list<array<string, mixed>> */
  private function buildLines(string $start, string $end): array
  {
    $stmt = $this->pdo->prepare(
      "SELECT COALESCE(SUM(grand_total), 0) AS total FROM sales_orders
       WHERE business_owner_id = :owner AND status != 'cancelled'
       AND DATE(created_at) BETWEEN :start AND :end"
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'start' => $start, 'end' => $end]);
    $sales = (float) $stmt->fetchColumn();

    $stmt = $this->pdo->prepare(
      "SELECT COALESCE(SUM(amount), 0) AS total FROM expenses
       WHERE business_owner_id = :owner AND status = 'approved'
       AND expense_date BETWEEN :start AND :end"
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'start' => $start, 'end' => $end]);
    $expenses = (float) $stmt->fetchColumn();

    return [
      ['account_code' => '4000', 'description' => 'Sales revenue', 'debit' => 0, 'credit' => $sales],
      ['account_code' => '5000', 'description' => 'Operating expenses', 'debit' => $expenses, 'credit' => 0],
    ];
  }
}
