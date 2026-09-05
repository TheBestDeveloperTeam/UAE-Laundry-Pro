<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class AccountingRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return list<array<string, mixed>> */
  public function listBatches(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM accounting_export_batches WHERE business_owner_id = :owner ORDER BY created_at DESC LIMIT 50'
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  public function findBatch(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM accounting_export_batches WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  /** @return list<array<string, mixed>> */
  public function batchLines(int $batchId): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM accounting_export_lines WHERE batch_id = :id ORDER BY line_no'
    );
    $stmt->execute(['id' => $batchId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function createBatch(array $data, int $userId): array
  {
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO accounting_export_batches (uuid, business_owner_id, adapter, period_start, period_end, status, created_by)
       VALUES (:uuid, :owner, :adapter, :start, :end, :status, :user)'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'owner' => $this->businessOwnerId,
      'adapter' => $data['adapter'] ?? 'csv',
      'start' => $data['period_start'],
      'end' => $data['period_end'],
      'status' => 'draft',
      'user' => $userId,
    ]);
    $id = (int) $this->pdo->lastInsertId();

    return $this->findBatch($id) ?? [];
  }

  /** @param list<array<string, mixed>> $lines */
  public function addLines(int $batchId, array $lines): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO accounting_export_lines (batch_id, line_no, account_code, description, debit, credit)
       VALUES (:batch, :line, :code, :desc, :debit, :credit)'
    );
    foreach ($lines as $i => $line) {
      $stmt->execute([
        'batch' => $batchId,
        'line' => $i + 1,
        'code' => $line['account_code'],
        'desc' => $line['description'],
        'debit' => $line['debit'] ?? 0,
        'credit' => $line['credit'] ?? 0,
      ]);
    }
  }

  public function markExported(int $batchId, string $filePath): void
  {
    $stmt = $this->pdo->prepare(
      'UPDATE accounting_export_batches SET status = :status, file_path = :path WHERE id = :id'
    );
    $stmt->execute(['status' => 'exported', 'path' => $filePath, 'id' => $batchId]);
  }

  private function uuid(): string
  {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
      random_int(0, 0xffff), random_int(0, 0xffff),
      random_int(0, 0xffff),
      random_int(0, 0x0fff) | 0x4000,
      random_int(0, 0x3fff) | 0x8000,
      random_int(0, 0xffff), random_int(0, 0xffff), random_int(0, 0xffff)
    );
  }
}
