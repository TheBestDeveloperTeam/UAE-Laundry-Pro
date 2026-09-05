<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class RefreshTokenRepository
{
  public function __construct(
    private readonly PDO $pdo,
  ) {
  }

  public function store(int $userId, string $tokenHash, string $expiresAt): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO refresh_tokens (user_id, token_hash, expires_at, created_at)
       VALUES (:user_id, :token_hash, :expires_at, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'user_id' => $userId,
      'token_hash' => $tokenHash,
      'expires_at' => $expiresAt,
    ]);
  }

  public function findValid(string $tokenHash): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM refresh_tokens
       WHERE token_hash = :token_hash
         AND revoked_at IS NULL
         AND expires_at > UTC_TIMESTAMP()
       LIMIT 1'
    );
    $stmt->execute(['token_hash' => $tokenHash]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  public function revoke(string $tokenHash): void
  {
    $stmt = $this->pdo->prepare(
      'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP() WHERE token_hash = :token_hash'
    );
    $stmt->execute(['token_hash' => $tokenHash]);
  }

  public function revokeAllForUser(int $userId): void
  {
    $stmt = $this->pdo->prepare(
      'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP()
       WHERE user_id = :user_id AND revoked_at IS NULL'
    );
    $stmt->execute(['user_id' => $userId]);
  }
}
