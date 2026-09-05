<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use RuntimeException;

final class PurchaseRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly InventoryRepository $inventory,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $status = null, int $limit = 50): array
  {
    $sql = 'SELECT po.*, v.name AS vendor_name FROM purchase_orders po
            JOIN vendors v ON v.id = po.vendor_id
            WHERE po.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($status !== null && $status !== '') {
      $sql .= ' AND po.status = :status';
      $params['status'] = $status;
    }

    $sql .= ' ORDER BY po.id DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll() ?: [];

    foreach ($rows as &$row) {
      $row['lines'] = $this->lines((int) $row['id']);
    }

    return $rows;
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT po.*, v.name AS vendor_name FROM purchase_orders po
       JOIN vendors v ON v.id = po.vendor_id
       WHERE po.id = :id AND po.business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();
    if (!$row) {
      return null;
    }
    $row['lines'] = $this->lines($id);

    return $row;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data, int $userId): array
  {
    $poNo = (string) ($data['po_no'] ?? $this->nextPoNo());

    $this->pdo->beginTransaction();
    try {
      $stmt = $this->pdo->prepare(
        'INSERT INTO purchase_orders (uuid, business_owner_id, po_no, vendor_id, status, order_date, expected_date, notes, created_by, created_at)
         VALUES (:uuid, :owner, :po_no, :vendor, :status, :order_date, :expected, :notes, :user, UTC_TIMESTAMP())'
      );
      $stmt->execute([
        'uuid' => $this->uuid(),
        'owner' => $this->businessOwnerId,
        'po_no' => $poNo,
        'vendor' => (int) ($data['vendor_id'] ?? 0),
        'status' => $data['status'] ?? 'draft',
        'order_date' => $data['order_date'] ?? gmdate('Y-m-d'),
        'expected' => $data['expected_date'] ?? null,
        'notes' => $data['notes'] ?? null,
        'user' => $userId,
      ]);
      $poId = (int) $this->pdo->lastInsertId();

      $lines = $data['lines'] ?? [];
      if (is_array($lines)) {
        $this->replaceLines($poId, $lines);
      }

      $this->pdo->commit();
    } catch (\Throwable $e) {
      $this->pdo->rollBack();
      throw $e;
    }

    return $this->findById($poId) ?? [];
  }

  /** @param array<string, mixed> $data */
  public function update(int $id, array $data): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null || !in_array($existing['status'], ['draft', 'ordered'], true)) {
      return null;
    }

    $this->pdo->beginTransaction();
    try {
      $stmt = $this->pdo->prepare(
        'UPDATE purchase_orders SET vendor_id = :vendor, status = :status, order_date = :order_date,
         expected_date = :expected, notes = :notes, updated_at = UTC_TIMESTAMP()
         WHERE id = :id AND business_owner_id = :owner'
      );
      $stmt->execute([
        'id' => $id,
        'owner' => $this->businessOwnerId,
        'vendor' => $data['vendor_id'] ?? $existing['vendor_id'],
        'status' => $data['status'] ?? $existing['status'],
        'order_date' => $data['order_date'] ?? $existing['order_date'],
        'expected' => $data['expected_date'] ?? $existing['expected_date'],
        'notes' => $data['notes'] ?? $existing['notes'],
      ]);

      if (isset($data['lines']) && is_array($data['lines'])) {
        $this->replaceLines($id, $data['lines']);
      }

      $this->pdo->commit();
    } catch (\Throwable $e) {
      $this->pdo->rollBack();
      throw $e;
    }

    return $this->findById($id);
  }

  /**
   * @param array<string, mixed> $data
   * @return array<string, mixed>|null
   */
  public function receive(int $poId, array $data, int $userId): ?array
  {
    $po = $this->findById($poId);
    if ($po === null || in_array($po['status'], ['cancelled', 'received'], true)) {
      return null;
    }

    $receiptLines = $data['lines'] ?? [];
    if (!is_array($receiptLines) || $receiptLines === []) {
      return null;
    }

    $receiptNo = (string) ($data['receipt_no'] ?? $this->nextReceiptNo());

    $this->pdo->beginTransaction();
    try {
      $grStmt = $this->pdo->prepare(
        'INSERT INTO goods_receipts (uuid, business_owner_id, purchase_order_id, receipt_no, notes, created_by, received_at)
         VALUES (:uuid, :owner, :po, :receipt_no, :notes, :user, UTC_TIMESTAMP())'
      );
      $grStmt->execute([
        'uuid' => $this->uuid(),
        'owner' => $this->businessOwnerId,
        'po' => $poId,
        'receipt_no' => $receiptNo,
        'notes' => $data['notes'] ?? null,
        'user' => $userId,
      ]);
      $grId = (int) $this->pdo->lastInsertId();

      $grLineStmt = $this->pdo->prepare(
        'INSERT INTO goods_receipt_lines (goods_receipt_id, purchase_order_line_id, product_id, quantity)
         VALUES (:gr, :pol, :product, :qty)'
      );
      $updPol = $this->pdo->prepare(
        'UPDATE purchase_order_lines SET quantity_received = quantity_received + :qty WHERE id = :id'
      );

      $inventoryItems = [];
      foreach ($receiptLines as $line) {
        $polId = (int) ($line['purchase_order_line_id'] ?? 0);
        $qty = (float) ($line['quantity'] ?? 0);
        if ($qty <= 0) {
          continue;
        }

        $pol = null;
        if ($polId > 0) {
          $pol = $this->findLine($polId, $poId);
        } elseif (isset($line['product_id'])) {
          $pol = $this->findLineByProduct($poId, (int) $line['product_id']);
        }

        if ($pol === null) {
          throw new RuntimeException('INVALID_LINE');
        }
        $polId = (int) $pol['id'];

        $grLineStmt->execute([
          'gr' => $grId,
          'pol' => $polId,
          'product' => (int) $pol['product_id'],
          'qty' => $qty,
        ]);
        $updPol->execute(['qty' => $qty, 'id' => $polId]);
        $inventoryItems[] = [
          'product_id' => (int) $pol['product_id'],
          'quantity' => $qty,
          'unit_cost' => (float) $pol['unit_cost'],
        ];
      }

      $this->inventory->receiveFromPurchase($grId, $inventoryItems, $userId);
      $this->refreshPoStatus($poId);

      $this->pdo->commit();
    } catch (\Throwable $e) {
      $this->pdo->rollBack();
      if ($e->getMessage() === 'INVALID_LINE') {
        return null;
      }
      throw $e;
    }

    return [
      'goods_receipt_id' => $grId,
      'receipt_no' => $receiptNo,
      'purchase_order' => $this->findById($poId),
    ];
  }

  private function refreshPoStatus(int $poId): void
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(*) AS total,
              SUM(CASE WHEN quantity_received >= quantity_ordered THEN 1 ELSE 0 END) AS fully_received
       FROM purchase_order_lines WHERE purchase_order_id = :po'
    );
    $stmt->execute(['po' => $poId]);
    $row = $stmt->fetch() ?: [];
    $total = (int) ($row['total'] ?? 0);
    $fully = (int) ($row['fully_received'] ?? 0);

    $status = 'partial';
    if ($total > 0 && $fully >= $total) {
      $status = 'received';
    }

    $upd = $this->pdo->prepare(
      'UPDATE purchase_orders SET status = :status, updated_at = UTC_TIMESTAMP() WHERE id = :id'
    );
    $upd->execute(['status' => $status, 'id' => $poId]);
  }

  /** @param array<int, array<string, mixed>> $lines */
  private function replaceLines(int $poId, array $lines): void
  {
    $del = $this->pdo->prepare('DELETE FROM purchase_order_lines WHERE purchase_order_id = :id');
    $del->execute(['id' => $poId]);

    $ins = $this->pdo->prepare(
      'INSERT INTO purchase_order_lines (purchase_order_id, line_no, product_id, quantity_ordered, unit_cost)
       VALUES (:po, :line, :product, :qty, :cost)'
    );
    $lineNo = 1;
    foreach ($lines as $line) {
      $ins->execute([
        'po' => $poId,
        'line' => $lineNo++,
        'product' => (int) ($line['product_id'] ?? 0),
        'qty' => (float) ($line['quantity_ordered'] ?? $line['quantity'] ?? 0),
        'cost' => (float) ($line['unit_cost'] ?? 0),
      ]);
    }
  }

  /** @return array<int, array<string, mixed>> */
  private function lines(int $poId): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT pol.*, p.name AS product_name FROM purchase_order_lines pol
       JOIN products p ON p.id = pol.product_id
       WHERE pol.purchase_order_id = :po ORDER BY pol.line_no'
    );
    $stmt->execute(['po' => $poId]);

    return $stmt->fetchAll() ?: [];
  }

  private function findLine(int $lineId, int $poId): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM purchase_order_lines WHERE id = :id AND purchase_order_id = :po LIMIT 1'
    );
    $stmt->execute(['id' => $lineId, 'po' => $poId]);

    return $stmt->fetch() ?: null;
  }

  private function findLineByProduct(int $poId, int $productId): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM purchase_order_lines WHERE purchase_order_id = :po AND product_id = :product LIMIT 1'
    );
    $stmt->execute(['po' => $poId, 'product' => $productId]);

    return $stmt->fetch() ?: null;
  }

  private function nextPoNo(): string
  {
    $stmt = $this->pdo->prepare('SELECT COALESCE(MAX(id), 0) + 1 FROM purchase_orders WHERE business_owner_id = :owner');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $n = (int) $stmt->fetchColumn();

    return 'PO-' . str_pad((string) $n, 6, '0', STR_PAD_LEFT);
  }

  private function nextReceiptNo(): string
  {
    $stmt = $this->pdo->prepare('SELECT COALESCE(MAX(id), 0) + 1 FROM goods_receipts WHERE business_owner_id = :owner');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $n = (int) $stmt->fetchColumn();

    return 'GR-' . str_pad((string) $n, 6, '0', STR_PAD_LEFT);
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
