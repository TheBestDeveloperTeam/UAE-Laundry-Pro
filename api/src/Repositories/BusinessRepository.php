<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class BusinessRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  public function getProfile(): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM business WHERE business_owner_id = :owner LIMIT 1');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  /** @param array<string, mixed> $data */
  public function updateProfile(array $data): ?array
  {
    $profile = $this->getProfile();
    if ($profile === null) {
      return null;
    }

    $fields = [
      'legal_name' => $data['legal_name'] ?? $profile['legal_name'],
      'display_name' => $data['display_name'] ?? $profile['display_name'],
      'phone' => $data['phone'] ?? $profile['phone'],
      'email' => $data['email'] ?? $profile['email'],
      'address_line1' => $data['address_line1'] ?? $profile['address_line1'],
      'city' => $data['city'] ?? $profile['city'],
      'emirate' => $data['emirate'] ?? $profile['emirate'],
      'country' => $data['country'] ?? $profile['country'],
    ];

    $stmt = $this->pdo->prepare(
      'UPDATE business SET legal_name = :legal_name, display_name = :display_name, phone = :phone,
       email = :email, address_line1 = :address_line1, city = :city, emirate = :emirate,
       country = :country, updated_at = UTC_TIMESTAMP()
       WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute([
      'id' => $profile['id'],
      'owner' => $this->businessOwnerId,
      ...$fields,
    ]);

    return $this->getProfile();
  }
}
