<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class AttendanceRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?int $employeeId = null, ?string $from = null, ?string $to = null, int $limit = 100): array
  {
    $sql = 'SELECT a.*, e.full_name AS employee_name, e.employee_no
            FROM attendance a
            JOIN employees e ON e.id = a.employee_id
            WHERE a.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($employeeId !== null) {
      $sql .= ' AND a.employee_id = :employee';
      $params['employee'] = $employeeId;
    }
    if ($from !== null && $from !== '') {
      $sql .= ' AND a.attendance_date >= :from';
      $params['from'] = $from;
    }
    if ($to !== null && $to !== '') {
      $sql .= ' AND a.attendance_date <= :to';
      $params['to'] = $to;
    }

    $sql .= ' ORDER BY a.attendance_date DESC, a.id DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT a.*, e.full_name AS employee_name FROM attendance a
       JOIN employees e ON e.id = a.employee_id
       WHERE a.id = :id AND a.business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @param array<string, mixed> $data */
  public function record(array $data, int $userId): array
  {
    $employeeId = (int) ($data['employee_id'] ?? 0);
    $date = (string) ($data['attendance_date'] ?? gmdate('Y-m-d'));
    $status = (string) ($data['status'] ?? 'present');
    $allowed = ['present', 'absent', 'half_day', 'leave'];
    if (!in_array($status, $allowed, true)) {
      $status = 'present';
    }

    $existing = $this->findByEmployeeDate($employeeId, $date);
    if ($existing !== null) {
      $stmt = $this->pdo->prepare(
        'UPDATE attendance SET status = :status, check_in = :in, check_out = :out, notes = :notes, created_by = :user
         WHERE id = :id'
      );
      $stmt->execute([
        'id' => $existing['id'],
        'status' => $status,
        'in' => $data['check_in'] ?? $existing['check_in'],
        'out' => $data['check_out'] ?? $existing['check_out'],
        'notes' => $data['notes'] ?? $existing['notes'],
        'user' => $userId,
      ]);

      return $this->findById((int) $existing['id']) ?? [];
    }

    $stmt = $this->pdo->prepare(
      'INSERT INTO attendance (uuid, business_owner_id, employee_id, attendance_date, status, check_in, check_out, notes, created_by, created_at)
       VALUES (:uuid, :owner, :employee, :date, :status, :in, :out, :notes, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'employee' => $employeeId,
      'date' => $date,
      'status' => $status,
      'in' => $data['check_in'] ?? null,
      'out' => $data['check_out'] ?? null,
      'notes' => $data['notes'] ?? null,
      'user' => $userId,
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  private function findByEmployeeDate(int $employeeId, string $date): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM attendance WHERE employee_id = :employee AND attendance_date = :date AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['employee' => $employeeId, 'date' => $date, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
