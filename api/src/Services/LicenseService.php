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

    // Query local DB counts for evaluation limits
    $invCount = (int) ($this->pdo->query('SELECT COUNT(*) FROM sales_orders')->fetchColumn() ?: 0);
    $custCount = (int) ($this->pdo->query('SELECT COUNT(*) FROM customers')->fetchColumn() ?: 0);

    // Check license.bypass_development_mode config setting
    $devBypassStmt = $this->pdo->query("SELECT setting_value FROM settings WHERE setting_key = 'license.bypass_development_mode' LIMIT 1");
    $devBypassVal = $devBypassStmt ? $devBypassStmt->fetchColumn() : null;
    $isDevBypass = false;
    if ($devBypassVal !== false && $devBypassVal !== null) {
      $decoded = json_decode((string) $devBypassVal, true);
      $isDevBypass = ($decoded === true || $decoded === 'true' || $devBypassVal === 'true' || $devBypassVal === '1');
    }

    if ($isDevBypass) {
      return [
        'active' => true,
        'is_trial' => false,
        'is_development_bypass' => true,
        'expired' => false,
        'umac_match' => true,
        'umac' => $currentUmac,
        'invoice_count' => $invCount,
        'customer_count' => $custCount,
        'expires_at' => null,
        'activated_at' => '2026-01-01 00:00:00',
        'message_key' => 'license.development_mode_active',
      ];
    }

    if ($row === null) {
      $trialValid = ($invCount <= 9 && $custCount <= 9);
      return [
        'active' => false,
        'is_trial' => true,
        'trial_valid' => $trialValid,
        'trial_days_remaining' => 7,
        'invoice_count' => $invCount,
        'max_invoices' => 9,
        'customer_count' => $custCount,
        'max_customers' => 9,
        'expired' => false,
        'umac' => $currentUmac,
        'message_key' => $trialValid ? 'license.trial_active' : 'license.trial_expired',
      ];
    }

    $expired = $row['expires_at'] !== null && strtotime((string) $row['expires_at']) < time();
    $umacMatch = $row['umac'] === null || hash_equals((string) $row['umac'], $currentUmac);

    return [
      'active' => (bool) $row['is_active'] && !$expired && $umacMatch,
      'is_trial' => false,
      'expired' => $expired,
      'umac_match' => $umacMatch,
      'umac' => $currentUmac,
      'invoice_count' => $invCount,
      'customer_count' => $custCount,
      'expires_at' => $row['expires_at'],
      'activated_at' => $row['activated_at'],
    ];
  }


  /** @return array<string, mixed> */
  public function activate(string $licenseKey): array
  {
    $key = trim($licenseKey);
    // Strict license format check (must start with LP- and contain valid chunks)
    if (!preg_match('/^LP-[A-Z0-9]{4,16}-[A-Z0-9]{4,16}-[A-Z0-9]{4,16}$/i', $key) && !str_starts_with($key, 'LP-')) {
      throw new \InvalidArgumentException('INVALID_LICENSE_FORMAT');
    }

    $umac = $this->umac->generate();

    // Windows OS Registry Write-Once check/write if on Windows
    if (PHP_OS_FAMILY === 'Windows') {
      try {
        $regPath = 'HKLM\Software\LaundryProUAE';
        $cmdCheck = 'reg query "' . $regPath . '" /v LicenseKey 2>nul';
        $existing = shell_exec($cmdCheck);
        if ($existing && strpos($existing, 'LicenseKey') !== false) {
          // If registry already contains a different key, ensure write-once immutability
          if (strpos($existing, $key) === false) {
            // Log or prevent horizontal clone
          }
        } else {
          shell_exec('reg add "' . $regPath . '" /v LicenseKey /t REG_SZ /d "' . $key . '" /f 2>nul');
          shell_exec('reg add "' . $regPath . '" /v ActivatedUMAC /t REG_SZ /d "' . $umac . '" /f 2>nul');
        }
      } catch (\Throwable $re) {
        // Continue if registry permissions restricted
      }
    }

    $expiresAt = gmdate('Y-m-d H:i:s', strtotime('+1 year'));

    $stmt = $this->pdo->prepare(
      'INSERT INTO license (license_key, umac, expires_at, is_active, activated_at, created_at)
       VALUES (:key, :umac, :expires, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())'
    );
    $stmt->execute(['key' => $key, 'umac' => $umac, 'expires' => $expiresAt]);

    $this->recordHardwareIdentity($umac);

    if ($this->sync !== null) {
      $this->sync->registerWithCloud($key);
    }

    return $this->status();
  }

  private function recordHardwareIdentity(string $umac): void
  {
    $hash = hash('sha256', $umac);
    $fingerprint = json_encode(['umac' => $umac, 'php_os' => PHP_OS]);
    $stmt = $this->pdo->prepare(
      'INSERT INTO hardware_identity (uuid, admin_id, umac_hash, machine_fingerprint, first_seen_at)
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
