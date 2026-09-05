<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class UserRepository
{
  public function __construct(
    private readonly PDO $pdo,
  ) {
  }

  public function findByUsername(string $username): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT u.*, r.name AS role_name, r.permissions
       FROM users u
       INNER JOIN roles r ON r.id = u.role_id
       WHERE u.username = :username AND u.is_active = 1
       LIMIT 1'
    );
    $stmt->execute(['username' => $username]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT u.*, r.name AS role_name, r.permissions
       FROM users u
       INNER JOIN roles r ON r.id = u.role_id
       WHERE u.id = :id AND u.is_active = 1
       LIMIT 1'
    );
    $stmt->execute(['id' => $id]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  public function updateLastLogin(int $userId): void
  {
    $stmt = $this->pdo->prepare('UPDATE users SET last_login_at = UTC_TIMESTAMP() WHERE id = :id');
    $stmt->execute(['id' => $userId]);
  }
}
