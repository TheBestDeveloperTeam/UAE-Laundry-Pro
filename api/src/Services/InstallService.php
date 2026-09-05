<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use LaundryPro\Api\Core\PdoFactory;
use LaundryPro\Api\Security\PasswordHasher;
use PDO;
use Throwable;

final class InstallService
{
  public function __construct(
    private readonly string $lockPath,
    private readonly string $installSecret,
    private readonly string $appVersion,
    private readonly string $migrationsPath,
    private readonly string $seedsPath,
    private readonly PasswordHasher $hasher,
  ) {
  }

  public function isLocked(): bool
  {
    return is_file($this->lockPath);
  }

  public function validateToken(?string $token): bool
  {
    if ($this->installSecret === '' || $token === null || $token === '') {
      return false;
    }

    return hash_equals($this->installSecret, $token);
  }

  /** @return array<string, mixed> */
  public function status(): array
  {
    $locked = $this->isLocked();
    $dbConnected = false;
    $migrationStatus = ['applied' => [], 'pending' => [], 'executed' => []];

    try {
      $pdo = $this->pdo();
      $dbConnected = true;
      $migration = new MigrationService($pdo, $this->migrationsPath);
      $migrationStatus = $migration->status();
    } catch (Throwable) {
      $dbConnected = false;
    }

    $lockData = null;
    if ($locked) {
      $raw = file_get_contents($this->lockPath);
      $decoded = is_string($raw) ? json_decode($raw, true) : null;
      if (is_array($decoded)) {
        $lockData = $decoded;
      }
    }

    return [
      'installed' => $locked,
      'locked' => $locked,
      'db_connected' => $dbConnected,
      'migrations_pending' => count($migrationStatus['pending']),
      'migrations_applied' => count($migrationStatus['applied']),
      'version' => $this->appVersion,
      'lock' => $lockData,
    ];
  }

  /** @return array<string, mixed> */
  public function migrate(): array
  {
    $this->assertUnlocked();
    $migration = new MigrationService($this->pdo(), $this->migrationsPath);

    return $migration->runPending();
  }

  /** @return array<string, mixed> */
  public function seed(?string $adminPassword = null): array
  {
    $this->assertUnlocked();
    $seed = new SeedService($this->pdo(), $this->seedsPath, $this->hasher);

    return $seed->run($adminPassword);
  }

  /** @return array<string, mixed> */
  public function complete(): array
  {
    $this->assertUnlocked();
    $migration = new MigrationService($this->pdo(), $this->migrationsPath);
    $status = $migration->status();

    if (count($status['pending']) > 0) {
      throw new \RuntimeException('MIGRATIONS_PENDING');
    }

    $payload = [
      'installed_at' => gmdate('c'),
      'version' => $this->appVersion,
      'migration_count' => count($status['applied']),
    ];

    $dir = dirname($this->lockPath);
    if (!is_dir($dir)) {
      mkdir($dir, 0775, true);
    }

    file_put_contents($this->lockPath, json_encode($payload, JSON_PRETTY_PRINT));

    return $payload;
  }

  private function assertUnlocked(): void
  {
    if ($this->isLocked()) {
      throw new \RuntimeException('INSTALL_LOCKED');
    }
  }

  private function pdo(): PDO
  {
    $config = require API_ROOT . '/config/database.php';

    return PdoFactory::create($config);
  }
}
