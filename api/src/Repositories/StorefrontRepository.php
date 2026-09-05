<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class StorefrontRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @param array<string, mixed> $data */
  public function createOrder(array $data): array
  {
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO storefront_orders (uuid, business_owner_id, customer_name, customer_phone, notes, payload_json)
       VALUES (:uuid, :owner, :name, :phone, :notes, :payload)'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'owner' => $this->businessOwnerId,
      'name' => $data['customer_name'],
      'phone' => $data['customer_phone'],
      'notes' => $data['notes'] ?? null,
      'payload' => json_encode($data['items'] ?? []),
    ]);
    $id = (int) $this->pdo->lastInsertId();

    return $this->findOrder($id) ?? [];
  }

  public function findOrder(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM storefront_orders WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  /** @return list<array<string, mixed>> */
  public function listOrders(?string $status = null): array
  {
    $sql = 'SELECT * FROM storefront_orders WHERE business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];
    if ($status !== null) {
      $sql .= ' AND status = :status';
      $params['status'] = $status;
    }
    $sql .= ' ORDER BY created_at DESC LIMIT 100';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  public function convertToSalesOrder(int $orderId, int $salesOrderId): ?array
  {
    $stmt = $this->pdo->prepare(
      'UPDATE storefront_orders SET status = :status, sales_order_id = :sales WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute([
      'status' => 'converted',
      'sales' => $salesOrderId,
      'id' => $orderId,
      'owner' => $this->businessOwnerId,
    ]);

    return $this->findOrder($orderId);
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
