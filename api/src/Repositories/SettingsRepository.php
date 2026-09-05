<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class SettingsRepository
{
  public function __construct(
    private readonly PDO $pdo,
  ) {
  }

  /** @return array<string, mixed> */
  public function all(): array
  {
    $stmt = $this->pdo->query('SELECT setting_key, setting_value, scope FROM settings ORDER BY setting_key');
    $rows = $stmt->fetchAll();
    $settings = [];

    foreach ($rows as $row) {
      $settings[$row['setting_key']] = [
        'value' => json_decode($row['setting_value'], true),
        'scope' => $row['scope'],
      ];
    }

    return $settings;
  }

  public function upsert(string $key, mixed $value, string $scope = 'business'): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO settings (setting_key, setting_value, scope, updated_at)
       VALUES (:key, :value, :scope, UTC_TIMESTAMP())
       ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), scope = VALUES(scope), updated_at = UTC_TIMESTAMP()'
    );
    $stmt->execute([
      'key' => $key,
      'value' => json_encode($value, JSON_THROW_ON_ERROR),
      'scope' => $scope,
    ]);
  }
}
