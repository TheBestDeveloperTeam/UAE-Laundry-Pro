<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use PDO;

final class MigrationService
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly string $migrationsPath,
  ) {
  }

  /** @return array{applied: array<int, string>, pending: array<int, string>, executed: array<int, string>} */
  public function status(): array
  {
    $this->ensureMigrationsTable();
    $applied = $this->appliedMigrations();
    $pending = [];

    foreach ($this->migrationFiles() as $file) {
      $name = basename($file);
      if (!in_array($name, $applied, true)) {
        $pending[] = $name;
      }
    }

    return [
      'applied' => $applied,
      'pending' => $pending,
      'executed' => [],
    ];
  }

  /** @return array{applied: array<int, string>, pending: array<int, string>, executed: array<int, string>} */
  public function runPending(): array
  {
    $status = $this->status();

    foreach ($this->migrationFiles() as $file) {
      $name = basename($file);
      if (!in_array($name, $status['pending'], true)) {
        continue;
      }

      $sql = file_get_contents($file);
      if ($sql === false) {
        throw new \RuntimeException("Unable to read migration {$name}");
      }

      $this->pdo->exec($sql);
      $insert = $this->pdo->prepare('INSERT INTO schema_migrations (migration) VALUES (:migration)');
      $insert->execute(['migration' => $name]);
      $status['executed'][] = $name;
    }

    $status['applied'] = $this->appliedMigrations();
    $status['pending'] = array_values(array_diff(
      array_map('basename', $this->migrationFiles()),
      $status['applied']
    ));

    return $status;
  }

  private function ensureMigrationsTable(): void
  {
    $this->pdo->exec(
      'CREATE TABLE IF NOT EXISTS schema_migrations (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        migration VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
    );
  }

  /** @return array<int, string> */
  private function appliedMigrations(): array
  {
    $stmt = $this->pdo->query('SELECT migration FROM schema_migrations ORDER BY id');
    $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_COLUMN) : [];

    return is_array($rows) ? $rows : [];
  }

  /** @return array<int, string> */
  private function migrationFiles(): array
  {
    $files = glob(rtrim($this->migrationsPath, '/\\') . '/*.sql');
    if ($files === false) {
      return [];
    }
    sort($files);

    return $files;
  }
}
