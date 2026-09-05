<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class EmployeeRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $search = null, bool $activeOnly = true, int $limit = 50, int $offset = 0): array
  {
    $sql = 'SELECT * FROM employees WHERE business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($activeOnly) {
      $sql .= ' AND is_active = 1';
    }

    if ($search !== null && $search !== '') {
      $sql .= ' AND (full_name LIKE :q OR employee_no LIKE :q OR phone LIKE :q)';
      $params['q'] = '%' . $search . '%';
    }

    $sql .= ' ORDER BY full_name ASC LIMIT :limit OFFSET :offset';
    $stmt = $this->pdo->prepare($sql);
    foreach ($params as $k => $v) {
      $stmt->bindValue($k, $v);
    }
    $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue('offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM employees WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data): array
  {
    $employeeNo = (string) ($data['employee_no'] ?? $this->nextEmployeeNo());
    $existing = $this->findByEmployeeNo($employeeNo);
    if ($existing !== null) {
      return $existing;
    }

    $stmt = $this->pdo->prepare(
      'INSERT INTO employees (uuid, business_owner_id, employee_no, full_name, phone, email, job_title, base_salary, created_at)
       VALUES (:uuid, :owner, :no, :name, :phone, :email, :title, :salary, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'no' => $employeeNo,
      'name' => $data['full_name'],
      'phone' => $data['phone'] ?? null,
      'email' => $data['email'] ?? null,
      'title' => $data['job_title'] ?? null,
      'salary' => $data['base_salary'] ?? 0,
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  public function findByEmployeeNo(string $employeeNo): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM employees WHERE employee_no = :no AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['no' => $employeeNo, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @param array<string, mixed> $data */
  public function update(int $id, array $data): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null) {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'UPDATE employees SET full_name = :name, phone = :phone, email = :email, job_title = :title,
       base_salary = :salary, updated_at = UTC_TIMESTAMP()
       WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute([
      'id' => $id,
      'owner' => $this->businessOwnerId,
      'name' => $data['full_name'] ?? $existing['full_name'],
      'phone' => $data['phone'] ?? $existing['phone'],
      'email' => $data['email'] ?? $existing['email'],
      'title' => $data['job_title'] ?? $existing['job_title'],
      'salary' => $data['base_salary'] ?? $existing['base_salary'],
    ]);

    return $this->findById($id);
  }

  public function deactivate(int $id): bool
  {
    $stmt = $this->pdo->prepare(
      'UPDATE employees SET is_active = 0, updated_at = UTC_TIMESTAMP() WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->rowCount() > 0;
  }

  private function nextEmployeeNo(): string
  {
    $stmt = $this->pdo->prepare('SELECT COALESCE(MAX(id), 0) + 1 FROM employees WHERE business_owner_id = :owner');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $n = (int) $stmt->fetchColumn();

    return 'EMP-' . str_pad((string) $n, 5, '0', STR_PAD_LEFT);
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
