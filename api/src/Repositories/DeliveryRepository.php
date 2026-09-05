<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class DeliveryRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $status = null, ?int $salesOrderId = null, int $limit = 50): array
  {
    $sql = 'SELECT dt.*, so.order_no, e.full_name AS assigned_employee_name
            FROM delivery_tasks dt
            JOIN sales_orders so ON so.id = dt.sales_order_id
            LEFT JOIN employees e ON e.id = dt.assigned_employee_id
            WHERE dt.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($status !== null && $status !== '') {
      $sql .= ' AND dt.status = :status';
      $params['status'] = $status;
    }
    if ($salesOrderId !== null) {
      $sql .= ' AND dt.sales_order_id = :order';
      $params['order'] = $salesOrderId;
    }

    $sql .= ' ORDER BY dt.scheduled_at IS NULL, dt.scheduled_at ASC, dt.id DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT dt.*, so.order_no FROM delivery_tasks dt
       JOIN sales_orders so ON so.id = dt.sales_order_id
       WHERE dt.id = :id AND dt.business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @return array<int, array<string, mixed>> */
  public function listForOrder(int $salesOrderId): array
  {
    return $this->list(null, $salesOrderId);
  }

  /** @param array<string, mixed> $data */
  public function create(int $salesOrderId, array $data, int $userId): ?array
  {
    if (!$this->orderExists($salesOrderId)) {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'INSERT INTO delivery_tasks (uuid, business_owner_id, sales_order_id, task_type, scheduled_at, address, notes, assigned_employee_id, created_by, created_at)
       VALUES (:uuid, :owner, :order, :type, :scheduled, :address, :notes, :employee, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'order' => $salesOrderId,
      'type' => $data['task_type'] ?? 'delivery',
      'scheduled' => $data['scheduled_at'] ?? null,
      'address' => $data['address'] ?? null,
      'notes' => $data['notes'] ?? null,
      'employee' => isset($data['assigned_employee_id']) ? (int) $data['assigned_employee_id'] : null,
      'user' => $userId,
    ]);

    return $this->findById((int) $this->pdo->lastInsertId());
  }

  /** @param array<string, mixed> $data */
  public function update(int $id, array $data): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null) {
      return null;
    }

    $status = $data['status'] ?? $existing['status'];
    $completedAt = $existing['completed_at'];
    if ($status === 'completed' && $completedAt === null) {
      $completedAt = gmdate('Y-m-d H:i:s');
    }

    $stmt = $this->pdo->prepare(
      'UPDATE delivery_tasks SET task_type = :type, scheduled_at = :scheduled, address = :address, notes = :notes,
       assigned_employee_id = :employee, status = :status, completed_at = :completed, failed_reason = :failed, updated_at = UTC_TIMESTAMP()
       WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute([
      'id' => $id,
      'owner' => $this->businessOwnerId,
      'type' => $data['task_type'] ?? $existing['task_type'],
      'scheduled' => $data['scheduled_at'] ?? $existing['scheduled_at'],
      'address' => $data['address'] ?? $existing['address'],
      'notes' => $data['notes'] ?? $existing['notes'],
      'employee' => $data['assigned_employee_id'] ?? $existing['assigned_employee_id'],
      'status' => $status,
      'completed' => $completedAt,
      'failed' => $data['failed_reason'] ?? $existing['failed_reason'],
    ]);

    return $this->findById($id);
  }

  private function orderExists(int $salesOrderId): bool
  {
    $stmt = $this->pdo->prepare(
      'SELECT 1 FROM sales_orders WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $salesOrderId, 'owner' => $this->businessOwnerId]);

    return (bool) $stmt->fetchColumn();
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
