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
  public function all(?int $branchId = null, ?int $terminalId = null): array
  {
    // Retrieve base settings
    $stmt = $this->pdo->prepare('SELECT setting_key, setting_value, scope FROM settings WHERE scope = "business" ORDER BY setting_key');
    $stmt->execute();
    $rows = $stmt->fetchAll();
    
    $settings = [];
    foreach ($rows as $row) {
      $settings[$row['setting_key']] = [
        'value' => json_decode($row['setting_value'], true),
        'scope' => $row['scope'],
      ];
    }

    // Branch overrides
    if ($branchId) {
      $bStmt = $this->pdo->prepare('SELECT setting_key, setting_value FROM settings WHERE scope = "branch" AND reference_id = :ref');
      $bStmt->execute(['ref' => $branchId]);
      foreach ($bStmt->fetchAll() as $row) {
        $settings[$row['setting_key']] = [
          'value' => json_decode($row['setting_value'], true),
          'scope' => 'branch',
        ];
      }
    }

    // Terminal overrides
    if ($terminalId) {
      $tStmt = $this->pdo->prepare('SELECT setting_key, setting_value FROM settings WHERE scope = "terminal" AND reference_id = :ref');
      $tStmt->execute(['ref' => $terminalId]);
      foreach ($tStmt->fetchAll() as $row) {
        $settings[$row['setting_key']] = [
          'value' => json_decode($row['setting_value'], true),
          'scope' => 'terminal',
        ];
      }
    }

    return $settings;
  }

  public function upsert(string $key, mixed $value, string $scope = 'business', ?int $referenceId = null): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO settings (setting_key, setting_value, scope, reference_id, updated_at)
       VALUES (:key, :value, :scope, :ref, UTC_TIMESTAMP())
       ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_at = UTC_TIMESTAMP()'
    );
    $stmt->execute([
      'key' => $key,
      'value' => json_encode($value, JSON_THROW_ON_ERROR),
      'scope' => $scope,
      'ref' => $referenceId,
    ]);
  }
}
