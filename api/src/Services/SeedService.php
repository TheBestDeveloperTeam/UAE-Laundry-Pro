<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use LaundryPro\Api\Security\PasswordHasher;
use PDO;

final class SeedService
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly string $seedsPath,
    private readonly PasswordHasher $hasher,
  ) {
  }

  /** @return array<string, mixed> */
  public function run(?string $adminPassword = null): array
  {
    $executed = [];
    $files = glob(rtrim($this->seedsPath, '/\\') . '/*.sql');
    if ($files !== false) {
      sort($files);
      foreach ($files as $file) {
        $sql = file_get_contents($file);
        if ($sql !== false && trim($sql) !== '') {
          $this->pdo->exec($sql);
          $executed[] = basename($file);
        }
      }
    }

    $password = $adminPassword ?? 'admin123';
    $hash = $this->hasher->hash($password);
    $stmt = $this->pdo->prepare('UPDATE users SET password_hash = :hash WHERE username = :username');
    $stmt->execute(['hash' => $hash, 'username' => 'admin']);

    $cashierHash = $this->hasher->hash('cashier123');
    $stmt->execute(['hash' => $cashierHash, 'username' => 'cashier']);

    return [
      'seed_files' => $executed,
      'admin_updated' => true,
      'cashier_updated' => true,
    ];
  }
}
