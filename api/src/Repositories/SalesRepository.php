<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use RuntimeException;

final class SalesRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly CatalogRepository $catalog,
    private readonly InventoryRepository $inventory,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $paymentStatus = null, ?string $status = null, int $limit = 50, int $offset = 0): array
  {
    $sql = 'SELECT * FROM sales_orders WHERE business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($paymentStatus !== null && $paymentStatus !== '') {
      $sql .= ' AND payment_status = :payment_status';
      $params['payment_status'] = $paymentStatus;
    }

    if ($status !== null && $status !== '') {
      $sql .= ' AND status = :status';
      $params['status'] = $status;
    }

    $sql .= ' ORDER BY id DESC LIMIT :limit OFFSET :offset';
    $stmt = $this->pdo->prepare($sql);
    foreach ($params as $key => $value) {
      $stmt->bindValue(':' . $key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    return $stmt->fetchAll() ?: [];
  }

  public function updateStatus(int $id, string $status, ?int $userId = null, ?string $notes = null): ?array
  {
    $allowed = [
      'draft', 'confirmed', 'received', 'sorting', 'processing', 'quality_check',
      'packed', 'ready_for_collection', 'ready', 'out_for_delivery', 'delivered',
      'closed', 'cancelled', 'on_hold', 'rework_required',
    ];
    if (!in_array($status, $allowed, true)) {
      return null;
    }

    $order = $this->findById($id);
    if ($order === null) {
      return null;
    }

    $current = (string) $order['status'];
    if (!$this->canTransitionStatus($current, $status)) {
      return null;
    }

    if ($current === $status) {
      return $order;
    }

    $this->pdo->beginTransaction();
    try {
      $stmt = $this->pdo->prepare(
        'UPDATE sales_orders SET status = :status, updated_at = UTC_TIMESTAMP()
         WHERE id = :id AND business_owner_id = :owner'
      );
      $stmt->execute(['status' => $status, 'id' => $id, 'owner' => $this->businessOwnerId]);

      $hist = $this->pdo->prepare(
        'INSERT INTO order_status_history (sales_order_id, from_status, to_status, changed_by, notes, created_at)
         VALUES (:order, :from, :to, :user, :notes, UTC_TIMESTAMP())'
      );
      $hist->execute([
        'order' => $id,
        'from' => $current,
        'to' => $status,
        'user' => $userId,
        'notes' => $notes,
      ]);

      $this->pdo->commit();
    } catch (\Throwable) {
      $this->pdo->rollBack();

      return null;
    }

    return $this->findById($id);
  }

  /** @return array<int, array<string, mixed>> */
  public function getStatusHistory(int $id): array
  {
    $order = $this->findById($id);
    if ($order === null) {
      return [];
    }

    $stmt = $this->pdo->prepare(
      'SELECT h.*, u.full_name AS changed_by_name
       FROM order_status_history h
       LEFT JOIN users u ON u.id = h.changed_by
       WHERE h.sales_order_id = :id
       ORDER BY h.created_at ASC, h.id ASC'
    );
    $stmt->execute(['id' => $id]);

    return $stmt->fetchAll() ?: [];
  }

  /** @return array{throughput_by_status: array<string, int>, total_transitions: int} */
  public function productionThroughput(string $from, string $to): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT to_status, COUNT(*) AS cnt
       FROM order_status_history
       WHERE DATE(created_at) BETWEEN :from AND :to
         AND sales_order_id IN (SELECT id FROM sales_orders WHERE business_owner_id = :owner)
       GROUP BY to_status'
    );
    $stmt->execute(['from' => $from, 'to' => $to, 'owner' => $this->businessOwnerId]);
    $rows = $stmt->fetchAll() ?: [];

    $byStatus = [];
    $total = 0;
    foreach ($rows as $row) {
      $cnt = (int) $row['cnt'];
      $byStatus[(string) $row['to_status']] = $cnt;
      $total += $cnt;
    }

    return [
      'throughput_by_status' => $byStatus,
      'total_transitions' => $total,
    ];
  }

  private function canTransitionStatus(string $from, string $to): bool
  {
    if ($from === $to) {
      return true;
    }

    $transitions = [
      'draft' => ['confirmed', 'cancelled'],
      'confirmed' => ['received', 'sorting', 'processing', 'ready', 'ready_for_collection', 'on_hold', 'cancelled'],
      'received' => ['sorting', 'processing', 'ready', 'on_hold', 'cancelled'],
      'sorting' => ['processing', 'on_hold', 'cancelled'],
      'processing' => ['quality_check', 'on_hold', 'rework_required', 'cancelled'],
      'quality_check' => ['packed', 'rework_required', 'on_hold', 'cancelled'],
      'packed' => ['ready_for_collection', 'ready', 'out_for_delivery', 'on_hold', 'cancelled'],
      'ready_for_collection' => ['out_for_delivery', 'delivered', 'closed', 'cancelled'],
      'ready' => ['delivered', 'out_for_delivery', 'closed', 'cancelled'],
      'out_for_delivery' => ['delivered', 'cancelled'],
      'on_hold' => ['received', 'sorting', 'processing', 'quality_check', 'packed', 'ready_for_collection', 'cancelled'],
      'rework_required' => ['sorting', 'processing', 'cancelled'],
      'delivered' => ['closed'],
      'closed' => [],
      'cancelled' => [],
    ];

    return in_array($to, $transitions[$from] ?? [], true);
  }

  /** @return array{order_count: int, grand_total: float, amount_paid: float, balance_due: float} */
  public function summary(string $from, string $to): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(*) AS order_count,
              COALESCE(SUM(grand_total), 0) AS grand_total,
              COALESCE(SUM(amount_paid), 0) AS amount_paid,
              COALESCE(SUM(balance_due), 0) AS balance_due
       FROM sales_orders
       WHERE business_owner_id = :owner
         AND status != :draft
         AND DATE(created_at) BETWEEN :from AND :to'
    );
    $stmt->execute([
      'owner' => $this->businessOwnerId,
      'draft' => 'draft',
      'from' => $from,
      'to' => $to,
    ]);
    $row = $stmt->fetch() ?: [];

    return [
      'order_count' => (int) ($row['order_count'] ?? 0),
      'grand_total' => round((float) ($row['grand_total'] ?? 0), 2),
      'amount_paid' => round((float) ($row['amount_paid'] ?? 0), 2),
      'balance_due' => round((float) ($row['balance_due'] ?? 0), 2),
    ];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM sales_orders WHERE id = :id AND business_owner_id = :owner LIMIT 1');
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    $order = $stmt->fetch();
    if (!$order) {
      return null;
    }

    $order['lines'] = $this->lines((int) $order['id']);
    $order['payments'] = $this->payments((int) $order['id']);

    return $order;
  }

  /** @param array<string, mixed> $data */
  public function createDraft(array $data, int $userId): array
  {
    $localId = $this->nextLocalId();
    $orderNo = $this->nextOrderNo();
    $stmt = $this->pdo->prepare(
      'INSERT INTO sales_orders (uuid, business_owner_id, local_id, order_no, customer_id, status, payment_status, notes, created_by, created_at)
       VALUES (:uuid, :owner, :local_id, :order_no, :customer, :status, :pay_status, :notes, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'local_id' => $localId,
      'order_no' => $orderNo,
      'customer' => $data['customer_id'] ?? null,
      'status' => 'draft',
      'pay_status' => 'pending',
      'notes' => $data['notes'] ?? null,
      'user' => $userId,
    ]);

    $orderId = (int) $this->pdo->lastInsertId();
    $lines = $data['lines'] ?? [];
    if (is_array($lines)) {
      $this->replaceLines($orderId, $lines);
    }

    return $this->findById($orderId) ?? [];
  }

  public function confirm(int $id, int $userId): ?array
  {
    $order = $this->findById($id);
    if ($order === null || $order['status'] !== 'draft') {
      return null;
    }

    $lines = $order['lines'] ?? [];
    $totals = $this->calculateTotals($lines);
    $consumption = [];

    $this->pdo->beginTransaction();
    try {
      foreach ($lines as $line) {
        $lineId = (int) $line['id'];
        $itemType = (string) ($line['item_type'] ?? 'service');
        $itemId = (int) ($line['item_id'] ?? 0);
        $qty = (float) ($line['quantity'] ?? 1);

        $mods = $line['modifiers'] ?? null;
        if (is_string($mods)) {
          $mods = json_decode($mods, true);
        }
        if (is_array($mods) && $mods !== []) {
          $this->saveSnapshot($lineId, 'modifiers', $mods);
        }

        if ($itemType === 'service' && $itemId > 0) {
          $service = $this->catalog->findService($itemId);
          if ($service !== null && (int) ($service['is_group'] ?? 0) === 1) {
            $bundle = $this->catalog->getServiceProductMap($itemId);
            $this->saveSnapshot($lineId, 'bundle', $bundle);
            foreach ($bundle as $mapRow) {
              $consumption[] = [
                'product_id' => (int) $mapRow['product_id'],
                'quantity' => (float) $mapRow['default_qty'] * $qty,
              ];
            }
          }
        }
      }

      $this->inventory->consumeForSale($id, $consumption, $userId);

      $stmt = $this->pdo->prepare(
        'UPDATE sales_orders SET status = :status, subtotal = :sub, discount = :disc, tax = :tax,
         grand_total = :grand, balance_due = :balance, confirmed_at = UTC_TIMESTAMP(), updated_at = UTC_TIMESTAMP()
         WHERE id = :id AND business_owner_id = :owner'
      );
      $stmt->execute([
        'id' => $id,
        'owner' => $this->businessOwnerId,
        'status' => 'confirmed',
        'sub' => $totals['subtotal'],
        'disc' => $totals['discount'],
        'tax' => $totals['tax'],
        'grand' => $totals['grand_total'],
        'balance' => $totals['grand_total'] - (float) $order['amount_paid'],
      ]);

      $this->pdo->commit();
    } catch (RuntimeException $e) {
      $this->pdo->rollBack();
      if ($e->getMessage() === 'INSUFFICIENT_STOCK') {
        throw $e;
      }
      return null;
    } catch (\Throwable) {
      $this->pdo->rollBack();
      return null;
    }

    return $this->findById($id);
  }

  /** @param array<string, mixed> $payload */
  private function saveSnapshot(int $lineId, string $type, array $payload): void
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO sales_order_line_snapshots (sales_order_line_id, snapshot_type, snapshot_json, created_at)
       VALUES (:line, :type, :json, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'line' => $lineId,
      'type' => $type,
      'json' => json_encode($payload),
    ]);
  }

  /** @param array<string, mixed> $payment */
  public function addPayment(int $orderId, array $payment, int $userId): ?array
  {
    $order = $this->findById($orderId);
    if ($order === null) {
      return null;
    }

    $payableStatuses = [
      'confirmed', 'received', 'sorting', 'processing', 'quality_check', 'packed',
      'ready_for_collection', 'ready', 'out_for_delivery', 'delivered', 'closed', 'on_hold',
    ];
    if (!in_array($order['status'], $payableStatuses, true)) {
      return null;
    }

    $amount = (float) ($payment['amount'] ?? 0);
    if ($amount <= 0) {
      return null;
    }

    $balanceDue = (float) $order['balance_due'];
    if ($balanceDue <= 0) {
      return null;
    }

    if ($amount > $balanceDue) {
      $amount = $balanceDue;
    }

    $stmt = $this->pdo->prepare(
      'INSERT INTO payment_transactions (uuid, business_owner_id, sales_order_id, amount, payment_method, reference_number, received_by, created_at)
       VALUES (:uuid, :owner, :order, :amount, :method, :ref, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'order' => $orderId,
      'amount' => $amount,
      'method' => $payment['payment_method'] ?? 'cash',
      'ref' => $payment['reference_number'] ?? null,
      'user' => $userId,
    ]);

    $paid = (float) $order['amount_paid'] + $amount;
    $balance = max(0, (float) $order['grand_total'] - $paid);
    $payStatus = $balance <= 0 ? 'paid' : ($paid > 0 ? 'partial' : 'pending');

    $upd = $this->pdo->prepare(
      'UPDATE sales_orders SET amount_paid = :paid, balance_due = :balance, payment_status = :status, updated_at = UTC_TIMESTAMP()
       WHERE id = :id'
    );
    $upd->execute(['paid' => $paid, 'balance' => $balance, 'status' => $payStatus, 'id' => $orderId]);

    return $this->findById($orderId);
  }

  /** @param array<int, array<string, mixed>> $lines */
  private function replaceLines(int $orderId, array $lines): void
  {
    $del = $this->pdo->prepare('DELETE FROM sales_order_lines WHERE sales_order_id = :id');
    $del->execute(['id' => $orderId]);

    $lineNo = 1;
    $ins = $this->pdo->prepare(
      'INSERT INTO sales_order_lines (sales_order_id, line_no, item_type, item_id, description, quantity, rate, discount, amount, service_status, modifiers, created_at)
       VALUES (:order, :line, :type, :item, :desc, :qty, :rate, :disc, :amount, :status, :mods, UTC_TIMESTAMP())'
    );

    foreach ($lines as $line) {
      $qty = (float) ($line['quantity'] ?? 1);
      $rate = (float) ($line['rate'] ?? 0);
      $disc = (float) ($line['discount'] ?? 0);
      $amount = ($qty * $rate) - $disc;
      $ins->execute([
        'order' => $orderId,
        'line' => $lineNo++,
        'type' => $line['item_type'] ?? 'service',
        'item' => (int) ($line['item_id'] ?? 0),
        'desc' => (string) ($line['description'] ?? ''),
        'qty' => $qty,
        'rate' => $rate,
        'disc' => $disc,
        'amount' => $amount,
        'status' => $line['service_status'] ?? 'received',
        'mods' => isset($line['modifiers']) ? json_encode($line['modifiers']) : null,
      ]);
    }
  }

  /** @return array<int, array<string, mixed>> */
  private function lines(int $orderId): array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM sales_order_lines WHERE sales_order_id = :id ORDER BY line_no');
    $stmt->execute(['id' => $orderId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @return array<int, array<string, mixed>> */
  private function payments(int $orderId): array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM payment_transactions WHERE sales_order_id = :id ORDER BY id');
    $stmt->execute(['id' => $orderId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<int, array<string, mixed>> $lines */
  /** @return array{subtotal: float, discount: float, tax: float, grand_total: float} */
  private function calculateTotals(array $lines): array
  {
    $subtotal = 0.0;
    $discount = 0.0;
    foreach ($lines as $line) {
      $qty = (float) ($line['quantity'] ?? 1);
      $rate = (float) ($line['rate'] ?? 0);
      $lineDiscount = (float) ($line['discount'] ?? 0);
      $modifierExtra = 0.0;
      $mods = $line['modifiers'] ?? null;
      if (is_string($mods)) {
        $mods = json_decode($mods, true);
      }
      if (is_array($mods)) {
        foreach ($mods as $mod) {
          if (is_array($mod)) {
            $modifierExtra += (float) ($mod['extra_rate'] ?? 0);
          }
        }
      }
      $subtotal += $qty * ($rate + $modifierExtra);
      $discount += $lineDiscount;
    }
    $tax = 0.0;
    $grand = round($subtotal - $discount + $tax, 2);

    return [
      'subtotal' => round($subtotal, 2),
      'discount' => round($discount, 2),
      'tax' => $tax,
      'grand_total' => $grand,
    ];
  }

  private function nextLocalId(): int
  {
    $stmt = $this->pdo->prepare('SELECT COALESCE(MAX(local_id), 0) + 1 FROM sales_orders WHERE business_owner_id = :owner');
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return (int) $stmt->fetchColumn();
  }

  private function nextOrderNo(): string
  {
    $stmt = $this->pdo->prepare('SELECT COALESCE(MAX(id), 0) + 1 FROM sales_orders WHERE business_owner_id = :owner');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $n = (int) $stmt->fetchColumn();

    return 'SO-' . str_pad((string) $n, 6, '0', STR_PAD_LEFT);
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
