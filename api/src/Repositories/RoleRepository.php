<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class RoleRepository
{
  public function __construct(
    private readonly PDO $pdo,
  ) {
  }

  public function findAll(): array
  {
    $stmt = $this->pdo->query('SELECT * FROM roles ORDER BY name ASC');
    return $stmt->fetchAll();
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM roles WHERE id = :id');
    $stmt->execute(['id' => $id]);
    return $stmt->fetch() ?: null;
  }

  public function create(string $name, array $permissions): int
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO roles (uuid, name, permissions) VALUES (UUID(), :name, :permissions)'
    );
    $stmt->execute([
      'name' => $name,
      'permissions' => json_encode($permissions),
    ]);
    return (int) $this->pdo->lastInsertId();
  }

  public function update(int $id, string $name, array $permissions): void
  {
    $stmt = $this->pdo->prepare(
      'UPDATE roles SET name = :name, permissions = :permissions WHERE id = :id'
    );
    $stmt->execute([
      'id' => $id,
      'name' => $name,
      'permissions' => json_encode($permissions),
    ]);
  }
}

