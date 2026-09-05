<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class LocalizationRepository
{
  public function __construct(private readonly PDO $pdo)
  {
  }

  /** @return list<array<string, mixed>> */
  public function listProfiles(): array
  {
    $stmt = $this->pdo->query('SELECT * FROM country_profiles WHERE is_active = 1 ORDER BY code');

    return $stmt->fetchAll() ?: [];
  }

  public function findByCode(string $code): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM country_profiles WHERE code = :code LIMIT 1');
    $stmt->execute(['code' => strtoupper($code)]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  public function setBusinessCountry(string $code): ?array
  {
    $profile = $this->findByCode($code);
    if ($profile === null) {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'UPDATE business SET country = :code, updated_at = UTC_TIMESTAMP() WHERE business_owner_id = 1'
    );
    $stmt->execute(['code' => $profile['code']]);

    return $profile;
  }
}
