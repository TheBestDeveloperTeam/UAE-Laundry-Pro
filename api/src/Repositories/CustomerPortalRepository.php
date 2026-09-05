<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class CustomerPortalRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  public function createToken(int $salesOrderId): array
  {
    $token = bin2hex(random_bytes(32));
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO customer_portal_tokens (uuid, business_owner_id, sales_order_id, access_token, expires_at)
       VALUES (:uuid, :owner, :order, :token, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 30 DAY))'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'owner' => $this->businessOwnerId,
      'order' => $salesOrderId,
      'token' => $token,
    ]);

    return ['access_token' => $token, 'sales_order_id' => $salesOrderId];
  }

  public function findByToken(string $token): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT cpt.*, so.order_no, so.status, so.grand_total, so.customer_id
       FROM customer_portal_tokens cpt
       INNER JOIN sales_orders so ON so.id = cpt.sales_order_id
       WHERE cpt.access_token = :token AND cpt.business_owner_id = :owner
       AND (cpt.expires_at IS NULL OR cpt.expires_at > UTC_TIMESTAMP())
       LIMIT 1'
    );
    $stmt->execute(['token' => $token, 'owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  private function uuid(): string
  {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
      random_int(0, 0xffff), random_int(0, 0xffff),
      random_int(0, 0xffff),
      random_int(0, 0x0fff) | 0x4000,
      random_int(0, 0x3fff) | 0x8000,
      random_int(0, 0xffff), random_int(0, 0xffff), random_int(0, 0xffff)
    );
  }
}
