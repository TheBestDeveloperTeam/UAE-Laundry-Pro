<?php

declare(strict_types=1);

namespace LaundryPro\Api\Security;

final class PasswordHasher
{
  public function hash(string $password): string
  {
    if (defined('PASSWORD_ARGON2ID')) {
      return password_hash($password, PASSWORD_ARGON2ID);
    }

    return password_hash($password, PASSWORD_BCRYPT);
  }

  public function verify(string $password, string $hash): bool
  {
    return password_verify($password, $hash);
  }
}
