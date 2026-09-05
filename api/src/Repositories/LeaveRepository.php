<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class LeaveRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $status = null, ?int $employeeId = null, int $limit = 50): array
  {
    $sql = 'SELECT lr.*, e.full_name AS employee_name, e.employee_no, lt.name AS leave_type_name
            FROM leave_requests lr
            JOIN employees e ON e.id = lr.employee_id
            JOIN leave_types lt ON lt.id = lr.leave_type_id
            WHERE lr.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($status !== null && $status !== '') {
      $sql .= ' AND lr.status = :status';
      $params['status'] = $status;
    }
    if ($employeeId !== null) {
      $sql .= ' AND lr.employee_id = :employee';
      $params['employee'] = $employeeId;
    }

    $sql .= ' ORDER BY lr.created_at DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  /** @return array<int, array<string, mixed>> */
  public function listTypes(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM leave_types WHERE business_owner_id = :owner AND is_active = 1 ORDER BY name'
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT lr.*, e.full_name AS employee_name, lt.name AS leave_type_name
       FROM leave_requests lr
       JOIN employees e ON e.id = lr.employee_id
       JOIN leave_types lt ON lt.id = lr.leave_type_id
       WHERE lr.id = :id AND lr.business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data): array
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO leave_requests (uuid, business_owner_id, employee_id, leave_type_id, start_date, end_date, reason, created_at)
       VALUES (:uuid, :owner, :employee, :type, :start, :end, :reason, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'employee' => (int) ($data['employee_id'] ?? 0),
      'type' => (int) ($data['leave_type_id'] ?? 0),
      'start' => $data['start_date'],
      'end' => $data['end_date'],
      'reason' => $data['reason'] ?? null,
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  public function approve(int $id, int $userId): ?array
  {
    return $this->setStatus($id, 'approved', $userId);
  }

  public function reject(int $id, int $userId): ?array
  {
    return $this->setStatus($id, 'rejected', $userId);
  }

  private function setStatus(int $id, string $status, int $userId): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null || $existing['status'] !== 'pending') {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'UPDATE leave_requests SET status = :status, approved_by = :user, approved_at = UTC_TIMESTAMP()
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
