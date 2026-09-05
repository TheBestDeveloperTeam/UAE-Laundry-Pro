<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class CustomerRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $search = null, int $limit = 50, int $offset = 0): array
  {
    $sql = 'SELECT * FROM customers WHERE business_owner_id = :owner AND is_active = 1';
    $params = ['owner' => $this->businessOwnerId];

    if ($search !== null && $search !== '') {
      $sql .= ' AND (name LIKE :q OR phone LIKE :q OR customer_code LIKE :q)';
      $params['q'] = '%' . $search . '%';
    }

    $sql .= ' ORDER BY name ASC LIMIT :limit OFFSET :offset';
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
      'SELECT * FROM customers WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data): array
  {
    $localId = $this->nextLocalId();
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO customers (uuid, business_owner_id, local_id, customer_code, name, phone, email, address_line1, city, emirate, customer_type, credit_limit, notes, created_at)
       VALUES (:uuid, :owner, :local_id, :code, :name, :phone, :email, :address, :city, :emirate, :type, :credit, :notes, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'owner' => $this->businessOwnerId,
      'local_id' => $localId,
      'code' => $data['customer_code'] ?? null,
      'name' => $data['name'],
      'phone' => $data['phone'] ?? null,
      'email' => $data['email'] ?? null,
      'address' => $data['address_line1'] ?? null,
      'city' => $data['city'] ?? null,
      'emirate' => $data['emirate'] ?? null,
      'type' => $data['customer_type'] ?? 'personal',
      'credit' => $data['credit_limit'] ?? 0,
      'notes' => $data['notes'] ?? null,
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @param array<string, mixed> $data */
  public function update(int $id, array $data): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null) {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'UPDATE customers SET name = :name, phone = :phone, email = :email, address_line1 = :address,
       city = :city, emirate = :emirate, customer_type = :type, credit_limit = :credit, notes = :notes, updated_at = UTC_TIMESTAMP()
       WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute([
      'id' => $id,
      'owner' => $this->businessOwnerId,
      'name' => $data['name'] ?? $existing['name'],
      'phone' => $data['phone'] ?? $existing['phone'],
      'email' => $data['email'] ?? $existing['email'],
      'address' => $data['address_line1'] ?? $existing['address_line1'],
      'city' => $data['city'] ?? $existing['city'],
      'emirate' => $data['emirate'] ?? $existing['emirate'],
      'type' => $data['customer_type'] ?? $existing['customer_type'],
      'credit' => $data['credit_limit'] ?? $existing['credit_limit'],
      'notes' => $data['notes'] ?? $existing['notes'],
    ]);

    return $this->findById($id);
  }

  public function deactivate(int $id): bool
  {
    $stmt = $this->pdo->prepare(
      'UPDATE customers SET is_active = 0, updated_at = UTC_TIMESTAMP() WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->rowCount() > 0;
  }

  private function nextLocalId(): int
  {
    $stmt = $this->pdo->prepare('SELECT COALESCE(MAX(local_id), 0) + 1 FROM customers WHERE business_owner_id = :owner');
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return (int) $stmt->fetchColumn();
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
