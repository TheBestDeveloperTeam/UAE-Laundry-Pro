<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use LaundryPro\Api\Security\UmacService;
use PDO;

final class LicenseService
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly UmacService $umac,
    private readonly ?SyncService $sync = null,
  ) {
  }

  /** @return array<string, mixed> */
  public function status(): array
  {
    $stmt = $this->pdo->query('SELECT * FROM license WHERE is_active = 1 ORDER BY id DESC LIMIT 1');
    $row = $stmt->fetch() ?: null;
    $currentUmac = $this->umac->generate();

    if ($row === null) {
      return [
        'active' => false,
        'expired' => false,
        'umac' => $currentUmac,
        'message_key' => 'license.not_activated',
      ];
    }

    $expired = $row['expires_at'] !== null && strtotime((string) $row['expires_at']) < time();
    $umacMatch = $row['umac'] === null || hash_equals((string) $row['umac'], $currentUmac);

    return [
      'active' => (bool) $row['is_active'] && !$expired && $umacMatch,
      'expired' => $expired,
      'umac_match' => $umacMatch,
      'umac' => $currentUmac,
      'expires_at' => $row['expires_at'],
      'activated_at' => $row['activated_at'],
    ];
  }

  /** @return array<string, mixed> */
  public function activate(string $licenseKey): array
  {
    $umac = $this->umac->generate();
    $expiresAt = gmdate('Y-m-d H:i:s', strtotime('+1 year'));

    $stmt = $this->pdo->prepare(
      'INSERT INTO license (license_key, umac, expires_at, is_active, activated_at, created_at)
       VALUES (:key, :umac, :expires, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())'
    );
    $stmt->execute(['key' => $licenseKey, 'umac' => $umac, 'expires' => $expiresAt]);

    $this->recordHardwareIdentity($umac);

    if ($this->sync !== null) {
      $this->sync->registerWithCloud($licenseKey);
    }

    return $this->status();
  }

  private function recordHardwareIdentity(string $umac): void
  {
    $hash = hash('sha256', $umac);
    $fingerprint = json_encode(['umac' => $umac, 'php_os' => PHP_OS]);
    $stmt = $this->pdo->prepare(
      'INSERT INTO hardware_identity (uuid, business_owner_id, umac_hash, machine_fingerprint, first_seen_at)
       VALUES (:uuid, 1, :hash, :fp, UTC_TIMESTAMP())
       ON DUPLICATE KEY UPDATE last_seen_at = UTC_TIMESTAMP(), is_active = 1'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'hash' => $hash,
      'fp' => $fingerprint,
    ]);
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
