<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class BranchRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return list<array<string, mixed>> */
  public function list(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT br.* FROM branches br
       INNER JOIN business b ON b.id = br.business_id AND b.business_owner_id = :owner
       ORDER BY br.code'
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT br.* FROM branches br
       INNER JOIN business b ON b.id = br.business_id AND b.business_owner_id = :owner
       WHERE br.id = :id LIMIT 1'
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'id' => $id]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data): array
  {
    $businessId = $this->businessId();
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO branches (uuid, business_id, code, name, is_active) VALUES (:uuid, :bid, :code, :name, 1)'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'bid' => $businessId,
      'code' => strtoupper((string) $data['code']),
      'name' => (string) $data['name'],
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @param array<string, mixed> $data */
  public function update(int $id, array $data): ?array
  {
    if ($this->findById($id) === null) {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'UPDATE branches SET name = :name, is_active = :active, updated_at = UTC_TIMESTAMP() WHERE id = :id'
    );
    $stmt->execute([
      'id' => $id,
      'name' => $data['name'] ?? '',
      'active' => !empty($data['is_active']) ? 1 : 0,
    ]);

    return $this->findById($id);
  }

  private function businessId(): int
  {
    $stmt = $this->pdo->prepare('SELECT id FROM business WHERE business_owner_id = :owner LIMIT 1');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();

    return (int) ($row['id'] ?? 1);
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
