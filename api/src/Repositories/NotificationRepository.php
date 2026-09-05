<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class NotificationRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?bool $unreadOnly = null, int $limit = 50): array
  {
    $sql = 'SELECT * FROM notifications WHERE business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($unreadOnly === true) {
      $sql .= ' AND is_read = 0';
    }

    $sql .= ' ORDER BY created_at DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM notifications WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  public function markRead(int $id, int $userId): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null) {
      return null;
    }

    $stmt = $this->pdo->prepare(
      'UPDATE notifications SET is_read = 1 WHERE id = :id AND business_owner_id = :owner'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    $readStmt = $this->pdo->prepare(
      'INSERT IGNORE INTO notification_reads (notification_id, user_id, read_at) VALUES (:notif, :user, UTC_TIMESTAMP())'
    );
    $readStmt->execute(['notif' => $id, 'user' => $userId]);

    return $this->findById($id);
  }

  public function markAllRead(int $userId): int
  {
    $stmt = $this->pdo->prepare(
      'UPDATE notifications SET is_read = 1 WHERE business_owner_id = :owner AND is_read = 0'
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $count = $stmt->rowCount();

    $ids = $this->pdo->prepare(
      'SELECT id FROM notifications WHERE business_owner_id = :owner'
    );
    $ids->execute(['owner' => $this->businessOwnerId]);
    $readStmt = $this->pdo->prepare(
      'INSERT IGNORE INTO notification_reads (notification_id, user_id, read_at) VALUES (:notif, :user, UTC_TIMESTAMP())'
    );
    foreach ($ids->fetchAll() ?: [] as $row) {
      $readStmt->execute(['notif' => $row['id'], 'user' => $userId]);
    }

    return $count;
  }

  /** Scan business conditions and create alert notifications. */
  public function generateAlerts(): array
  {
    $created = [];

    $created = array_merge($created, $this->alertLowStock());
    $created = array_merge($created, $this->alertPendingPayments());
    $created = array_merge($created, $this->alertOpenPayrollPeriods());
    $created = array_merge($created, $this->alertPendingExpenses());

    return $created;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data): array
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO notifications (uuid, business_owner_id, notification_type, title, message, severity, reference_type, reference_id, created_at)
       VALUES (:uuid, :owner, :type, :title, :message, :severity, :ref_type, :ref_id, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'type' => $data['notification_type'],
      'title' => $data['title'],
      'message' => $data['message'],
      'severity' => $data['severity'] ?? 'info',
      'ref_type' => $data['reference_type'] ?? null,
      'ref_id' => isset($data['reference_id']) ? (int) $data['reference_id'] : null,
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @return array<int, array<string, mixed>> */
  private function alertLowStock(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT id, name, stock_quantity, low_stock_threshold FROM products
       WHERE business_owner_id = :owner AND is_active = 1 AND low_stock_threshold > 0 AND stock_quantity <= low_stock_threshold'
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $products = $stmt->fetchAll() ?: [];
    $created = [];

    foreach ($products as $product) {
      if ($this->alertExists('low_stock', 'product', (int) $product['id'])) {
        continue;
      }
      $created[] = $this->create([
        'notification_type' => 'low_stock',
        'title' => 'Low stock: ' . $product['name'],
        'message' => sprintf('Product %s stock (%s) is at or below threshold (%s).', $product['name'], $product['stock_quantity'], $product['low_stock_threshold']),
        'severity' => 'warning',
        'reference_type' => 'product',
        'reference_id' => (int) $product['id'],
      ]);
    }

    return $created;
  }

  /** @return array<int, array<string, mixed>> */
  private function alertPendingPayments(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(*) AS cnt FROM sales_orders
       WHERE business_owner_id = :owner AND payment_status IN (:partial, :pending) AND status NOT IN (:draft, :cancelled)'
    );
    $stmt->execute([
      'owner' => $this->businessOwnerId,
      'partial' => 'partial',
      'pending' => 'pending',
      'draft' => 'draft',
      'cancelled' => 'cancelled',
    ]);
    $cnt = (int) $stmt->fetchColumn();
    if ($cnt <= 0 || $this->alertExists('pending_payment', null, null)) {
      return [];
    }

    return [$this->create([
      'notification_type' => 'pending_payment',
      'title' => 'Pending payments',
      'message' => sprintf('%d order(s) have outstanding payment balances.', $cnt),
      'severity' => 'info',
    ])];
  }

  /** @return array<int, array<string, mixed>> */
  private function alertOpenPayrollPeriods(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT pp.id, pp.period_start, pp.period_end FROM payroll_periods pp
       LEFT JOIN payroll_runs pr ON pr.payroll_period_id = pp.id AND pr.business_owner_id = pp.business_owner_id
       WHERE pp.business_owner_id = :owner AND pp.status = :open AND pr.id IS NULL
       ORDER BY pp.period_end ASC LIMIT 1'
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'open' => 'open']);
    $period = $stmt->fetch();
    if (!$period || $this->alertExists('payroll_pending', 'payroll_period', (int) $period['id'])) {
      return [];
    }

    return [$this->create([
      'notification_type' => 'payroll_pending',
      'title' => 'Payroll pending',
      'message' => sprintf('Payroll period %s to %s has not been run.', $period['period_start'], $period['period_end']),
      'severity' => 'warning',
      'reference_type' => 'payroll_period',
      'reference_id' => (int) $period['id'],
    ])];
  }

  /** @return array<int, array<string, mixed>> */
  private function alertPendingExpenses(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(*) AS cnt FROM expenses WHERE business_owner_id = :owner AND status = :pending'
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'pending' => 'pending']);
    $cnt = (int) $stmt->fetchColumn();
    if ($cnt <= 0 || $this->alertExists('expense_pending', null, null)) {
      return [];
    }

    return [$this->create([
      'notification_type' => 'expense_pending',
      'title' => 'Expenses awaiting approval',
      'message' => sprintf('%d expense(s) are pending approval.', $cnt),
      'severity' => 'info',
    ])];
  }

  private function alertExists(string $type, ?string $refType, ?int $refId): bool
  {
    $sql = 'SELECT 1 FROM notifications WHERE business_owner_id = :owner AND notification_type = :type AND is_read = 0';
    $params = ['owner' => $this->businessOwnerId, 'type' => $type];
    if ($refType !== null) {
      $sql .= ' AND reference_type = :ref_type';
      $params['ref_type'] = $refType;
    }
    if ($refId !== null) {
      $sql .= ' AND reference_id = :ref_id';
      $params['ref_id'] = $refId;
    }
    $sql .= ' LIMIT 1';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return (bool) $stmt->fetchColumn();
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
