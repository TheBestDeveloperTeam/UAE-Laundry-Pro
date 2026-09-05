<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class ExpenseRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function listCategories(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM expense_categories WHERE business_owner_id = :owner AND is_active = 1 ORDER BY name'
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function createCategory(array $data): array
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO expense_categories (uuid, business_owner_id, name, created_at)
       VALUES (:uuid, :owner, :name, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'name' => $data['name'],
    ]);

    $id = (int) $this->pdo->lastInsertId();
    $stmt = $this->pdo->prepare('SELECT * FROM expense_categories WHERE id = :id');
    $stmt->execute(['id' => $id]);

    return $stmt->fetch() ?: [];
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $status = null, ?string $from = null, ?string $to = null, int $limit = 50): array
  {
    $sql = 'SELECT ex.*, ec.name AS category_name
            FROM expenses ex
            JOIN expense_categories ec ON ec.id = ex.category_id
            WHERE ex.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($status !== null && $status !== '') {
      $sql .= ' AND ex.status = :status';
      $params['status'] = $status;
    }
    if ($from !== null && $from !== '') {
      $sql .= ' AND ex.expense_date >= :from';
      $params['from'] = $from;
    }
    if ($to !== null && $to !== '') {
      $sql .= ' AND ex.expense_date <= :to';
      $params['to'] = $to;
    }

    $sql .= ' ORDER BY ex.expense_date DESC, ex.id DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT ex.*, ec.name AS category_name FROM expenses ex
       JOIN expense_categories ec ON ec.id = ex.category_id
       WHERE ex.id = :id AND ex.business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data, int $userId): array
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO expenses (uuid, business_owner_id, category_id, expense_date, amount, description, status, created_by, created_at)
       VALUES (:uuid, :owner, :category, :date, :amount, :desc, :status, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'category' => (int) ($data['category_id'] ?? 0),
      'date' => $data['expense_date'] ?? gmdate('Y-m-d'),
      'amount' => round((float) ($data['amount'] ?? 0), 2),
      'desc' => $data['description'] ?? null,
      'status' => $data['status'] ?? 'pending',
      'user' => $userId,
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  public function approve(int $id, int $userId): ?array
  {
    return $this->setApprovalStatus($id, 'approved', $userId);
  }

  public function reject(int $id, int $userId): ?array
  {
    return $this->setApprovalStatus($id, 'rejected', $userId);
  }

  /** @return array{expense_count: int, total_amount: float, approved_amount: float, pending_amount: float} */
  public function summary(string $from, string $to): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(*) AS expense_count,
              COALESCE(SUM(amount), 0) AS total_amount,
              COALESCE(SUM(CASE WHEN status = :approved THEN amount ELSE 0 END), 0) AS approved_amount,
              COALESCE(SUM(CASE WHEN status = :pending THEN amount ELSE 0 END), 0) AS pending_amount
       FROM expenses
       WHERE business_owner_id = :owner AND expense_date BETWEEN :from AND :to'
    );
    $stmt->execute([
      'owner' => $this->businessOwnerId,
      'from' => $from,
      'to' => $to,
      'approved' => 'approved',
      'pending' => 'pending',
    ]);
    $row = $stmt->fetch() ?: [];

    return [
      'expense_count' => (int) ($row['expense_count'] ?? 0),
      'total_amount' => round((float) ($row['total_amount'] ?? 0), 2),
      'approved_amount' => round((float) ($row['approved_amount'] ?? 0), 2),
      'pending_amount' => round((float) ($row['pending_amount'] ?? 0), 2),
    ];
  }

  private function setApprovalStatus(int $id, string $status, int $userId): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null || !in_array($existing['status'], ['pending', 'draft'], true)) {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'UPDATE expenses SET status = :status, approved_by = :user, approved_at = UTC_TIMESTAMP(), updated_at = UTC_TIMESTAMP()
       WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute(['status' => $status, 'user' => $userId, 'id' => $id, 'owner' => $this->businessOwnerId]);

    return $this->findById($id);
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
