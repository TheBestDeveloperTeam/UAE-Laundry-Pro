<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use RuntimeException;

final class InventoryRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  public function allowNegativeStock(): bool
  {
    $stmt = $this->pdo->prepare(
      'SELECT setting_value FROM settings WHERE setting_key = :key AND scope = :scope LIMIT 1'
    );
    $stmt->execute(['key' => 'inventory.allow_negative_stock', 'scope' => 'inventory']);
    $row = $stmt->fetch();
    if (!$row) {
      return false;
    }
    $val = json_decode((string) $row['setting_value'], true);

    return $val === true || $val === 'true' || $val === '1';
  }

  /** @return array<int, array<string, mixed>> */
  public function listMovements(?int $productId = null, int $limit = 50): array
  {
    $sql = 'SELECT m.*, p.name AS product_name FROM inventory_movements m
            JOIN products p ON p.id = m.product_id
            WHERE m.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];
    if ($productId !== null) {
      $sql .= ' AND m.product_id = :product';
      $params['product'] = $productId;
    }
    $sql .= ' ORDER BY m.id DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function receipt(array $data, int $userId): array
  {
    $productId = (int) ($data['product_id'] ?? 0);
    $qty = (float) ($data['quantity'] ?? 0);
    if ($productId <= 0 || $qty <= 0) {
      throw new RuntimeException('VALIDATION_ERROR');
    }

    $this->pdo->beginTransaction();
    try {
      $this->adjustStock($productId, $qty);
      $movement = $this->recordMovement($productId, 'receipt', $qty, $data['reference_type'] ?? null, isset($data['reference_id']) ? (int) $data['reference_id'] : null, $data['notes'] ?? null, $userId);
      $this->pdo->commit();

      return $movement;
    } catch (\Throwable $e) {
      $this->pdo->rollBack();
      throw $e;
    }
  }

  /** @param array<string, mixed> $data */
  public function adjustment(array $data, int $userId): array
  {
    $productId = (int) ($data['product_id'] ?? 0);
    $newQty = (float) ($data['quantity_after'] ?? -1);
    if ($productId <= 0 || $newQty < 0) {
      throw new RuntimeException('VALIDATION_ERROR');
    }

    $product = $this->findProduct($productId);
    if ($product === null) {
      throw new RuntimeException('NOT_FOUND');
    }

    $before = (float) $product['stock_quantity'];
    $delta = $newQty - $before;

    $this->pdo->beginTransaction();
    try {
      $stmt = $this->pdo->prepare(
        'UPDATE products SET stock_quantity = :qty, updated_at = UTC_TIMESTAMP()
         WHERE id = :id AND business_owner_id = :owner'
      );
      $stmt->execute(['qty' => $newQty, 'id' => $productId, 'owner' => $this->businessOwnerId]);

      $adjStmt = $this->pdo->prepare(
        'INSERT INTO inventory_adjustments (uuid, business_owner_id, product_id, quantity_before, quantity_after, reason, created_by, created_at)
         VALUES (:uuid, :owner, :product, :before, :after, :reason, :user, UTC_TIMESTAMP())'
      );
      $adjStmt->execute([
        'uuid' => $this->uuid(),
        'owner' => $this->businessOwnerId,
        'product' => $productId,
        'before' => $before,
        'after' => $newQty,
        'reason' => $data['reason'] ?? null,
        'user' => $userId,
      ]);

      if ($delta !== 0.0) {
        $this->recordMovement($productId, 'adjustment', abs($delta), 'adjustment', (int) $this->pdo->lastInsertId(), $data['reason'] ?? null, $userId);
      }

      $this->pdo->commit();

      return $this->findProduct($productId) ?? [];
    } catch (\Throwable $e) {
      $this->pdo->rollBack();
      throw $e;
    }
  }

  /** @param array<int, array{product_id: int, quantity: float}> $items */
  public function consumeForSale(int $orderId, array $items, int $userId): void
  {
    if ($items === []) {
      return;
    }

    $allowNegative = $this->allowNegativeStock();

    foreach ($items as $item) {
      $productId = (int) $item['product_id'];
      $qty = (float) $item['quantity'];
      if ($qty <= 0) {
        continue;
      }

      $product = $this->findProduct($productId);
      if ($product === null) {
        throw new RuntimeException('NOT_FOUND');
      }

      $stock = (float) $product['stock_quantity'];
      if (!$allowNegative && $stock < $qty) {
        throw new RuntimeException('INSUFFICIENT_STOCK');
      }

      $this->adjustStock($productId, -$qty);
      $this->recordMovement($productId, 'sale_consumption', $qty, 'sales_order', $orderId, null, $userId);
    }
  }

  private function adjustStock(int $productId, float $delta): void
  {
    $stmt = $this->pdo->prepare(
      'UPDATE products SET stock_quantity = stock_quantity + :delta, updated_at = UTC_TIMESTAMP()
       WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute(['delta' => $delta, 'id' => $productId, 'owner' => $this->businessOwnerId]);
  }

  /** @return array<string, mixed> */
  private function recordMovement(
    int $productId,
    string $type,
    float $qty,
    ?string $refType,
    ?int $refId,
    ?string $notes,
    int $userId,
  ): array {
    $stmt = $this->pdo->prepare(
      'INSERT INTO inventory_movements (uuid, business_owner_id, product_id, movement_type, quantity, reference_type, reference_id, notes, created_by, created_at)
       VALUES (:uuid, :owner, :product, :type, :qty, :ref_type, :ref_id, :notes, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'product' => $productId,
      'type' => $type,
      'qty' => $qty,
      'ref_type' => $refType,
      'ref_id' => $refId,
      'notes' => $notes,
      'user' => $userId,
    ]);

    return ['id' => (int) $this->pdo->lastInsertId(), 'product_id' => $productId, 'movement_type' => $type, 'quantity' => $qty];
  }

  public function findProduct(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM products WHERE id = :id AND business_owner_id = :owner LIMIT 1');
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @return array<int, array<string, mixed>> */
  public function stock(?int $productId = null): array
  {
    $sql = 'SELECT p.id, p.uuid, p.name, p.code, p.stock_quantity AS quantity_on_hand,
                   p.low_stock_threshold, p.cost AS cost_price,
                   COALESCE(mv.quantity_from_movements, 0) AS quantity_from_movements
            FROM products p
            LEFT JOIN (
              SELECT product_id,
                     SUM(CASE movement_type
                       WHEN :receipt THEN quantity
                       WHEN :sale THEN -quantity
                       WHEN :issue THEN -quantity
                       ELSE 0
                     END) AS quantity_from_movements
              FROM inventory_movements
              WHERE business_owner_id = :owner_mv
              GROUP BY product_id
            ) mv ON mv.product_id = p.id
            WHERE p.business_owner_id = :owner AND p.is_active = 1';
    $params = [
      'owner' => $this->businessOwnerId,
      'owner_mv' => $this->businessOwnerId,
      'receipt' => 'receipt',
      'sale' => 'sale_consumption',
      'issue' => 'issue',
    ];

    if ($productId !== null) {
      $sql .= ' AND p.id = :product';
      $params['product'] = $productId;
    }

    $sql .= ' ORDER BY p.name ASC';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll() ?: [];

    foreach ($rows as &$row) {
      $row['quantity_on_hand'] = round((float) $row['quantity_on_hand'], 3);
      $row['quantity_from_movements'] = round((float) $row['quantity_from_movements'], 3);
      $row['variance'] = round((float) $row['quantity_on_hand'] - (float) $row['quantity_from_movements'], 3);
    }

    return $rows;
  }

  /**
   * @return array{dry_run: bool, discrepancies: array<int, array<string, mixed>>, adjusted_count?: int}
   */
  public function reconcile(bool $confirm = false, int $userId = 0): array
  {
    $items = $this->stock();
    $discrepancies = [];
    foreach ($items as $item) {
      $variance = (float) $item['variance'];
      if (abs($variance) >= 0.001) {
        $discrepancies[] = [
          'product_id' => (int) $item['id'],
          'product_name' => $item['name'],
          'quantity_on_hand' => (float) $item['quantity_on_hand'],
          'quantity_from_movements' => (float) $item['quantity_from_movements'],
          'variance' => $variance,
        ];
      }
    }

    if (!$confirm || $discrepancies === []) {
      return ['dry_run' => !$confirm, 'discrepancies' => $discrepancies];
    }

    foreach ($discrepancies as $row) {
      $this->adjustment([
        'product_id' => $row['product_id'],
        'quantity_after' => $row['quantity_from_movements'],
        'reason' => 'Stock reconciliation',
      ], $userId);
    }

    return [
      'dry_run' => false,
      'discrepancies' => $discrepancies,
      'adjusted_count' => count($discrepancies),
    ];
  }

  /** @return array{total_value: float, product_count: int, items: array<int, array<string, mixed>>} */
  public function valuation(): array
  {
    $items = $this->stock();
    $total = 0.0;
    foreach ($items as &$item) {
      $value = round((float) $item['quantity_on_hand'] * (float) ($item['cost_price'] ?? 0), 2);
      $item['stock_value'] = $value;
      $total += $value;
    }

    return [
      'total_value' => round($total, 2),
      'product_count' => count($items),
      'items' => $items,
    ];
  }

  /** @param array<int, array{product_id: int, quantity: float, unit_cost?: float}> $items */
  public function receiveFromPurchase(int $goodsReceiptId, array $items, int $userId): void
  {
    foreach ($items as $item) {
      $productId = (int) $item['product_id'];
      $qty = (float) $item['quantity'];
      if ($productId <= 0 || $qty <= 0) {
        continue;
      }

      $this->adjustStock($productId, $qty);
      $this->recordMovement(
        $productId,
        'receipt',
        $qty,
        'goods_receipt',
        $goodsReceiptId,
        null,
        $userId,
      );
    }
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
