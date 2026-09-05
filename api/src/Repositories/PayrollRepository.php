<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class PayrollRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function listPeriods(int $limit = 24): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM payroll_periods WHERE business_owner_id = :owner ORDER BY period_start DESC LIMIT ' . (int) $limit
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function createPeriod(array $data): array
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO payroll_periods (uuid, business_owner_id, period_start, period_end, created_at)
       VALUES (:uuid, :owner, :start, :end, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'start' => $data['period_start'],
      'end' => $data['period_end'],
    ]);

    return $this->findPeriodById((int) $this->pdo->lastInsertId()) ?? [];
  }

  public function findPeriodById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM payroll_periods WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  public function findPeriodByDates(string $start, string $end): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM payroll_periods
       WHERE business_owner_id = :owner AND period_start = :start AND period_end = :end
       LIMIT 1'
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'start' => $start, 'end' => $end]);

    return $stmt->fetch() ?: null;
  }

  public function findOrCreatePeriod(string $start, string $end): array
  {
    $existing = $this->findPeriodByDates($start, $end);
    if ($existing !== null) {
      return $existing;
    }

    return $this->createPeriod(['period_start' => $start, 'period_end' => $end]);
  }

  /** @return array<int, array<string, mixed>> */
  public function listRuns(int $limit = 50): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT pr.*, pp.period_start, pp.period_end
       FROM payroll_runs pr
       JOIN payroll_periods pp ON pp.id = pr.payroll_period_id
       WHERE pr.business_owner_id = :owner
       ORDER BY pr.id DESC LIMIT ' . (int) $limit
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  /** Idempotent: returns existing run if period already has a posted run. */
  /** @param array<int, int>|null $employeeIds */
  public function run(int $periodId, int $userId, ?array $employeeIds = null): ?array
  {
    $period = $this->findPeriodById($periodId);
    if ($period === null) {
      return null;
    }

    $existing = $this->findRunByPeriod($periodId);
    if ($existing !== null) {
      $existing['lines'] = $this->runLines((int) $existing['id']);

      return $existing;
    }

    $employees = $this->activeEmployees($employeeIds);
    if ($employees === []) {
      return null;
    }

    $this->pdo->beginTransaction();
    try {
      $total = 0.0;
      $lines = [];
      foreach ($employees as $emp) {
        $base = (float) $emp['base_salary'];
        $advance = $this->openAdvanceTotal((int) $emp['id']);
        $deduction = min($advance, $base);
        $net = round($base - $deduction, 2);
        $total += $net;
        $lines[] = [
          'employee_id' => (int) $emp['id'],
          'base_salary' => $base,
          'advance_deduction' => $deduction,
          'net_pay' => $net,
        ];
      }

      $runNo = $this->nextRunNo();
      $runStmt = $this->pdo->prepare(
        'INSERT INTO payroll_runs (uuid, business_owner_id, payroll_period_id, run_no, total_amount, status, created_by, created_at)
         VALUES (:uuid, :owner, :period, :run_no, :total, :status, :user, UTC_TIMESTAMP())'
      );
      $runStmt->execute([
        'uuid' => $this->uuid(),
        'owner' => $this->businessOwnerId,
        'period' => $periodId,
        'run_no' => $runNo,
        'total' => round($total, 2),
        'status' => 'posted',
        'user' => $userId,
      ]);
      $runId = (int) $this->pdo->lastInsertId();

      $lineStmt = $this->pdo->prepare(
        'INSERT INTO payroll_lines (payroll_run_id, employee_id, base_salary, advance_deduction, net_pay)
         VALUES (:run, :employee, :base, :deduction, :net)'
      );
      foreach ($lines as $line) {
        $lineStmt->execute([
          'run' => $runId,
          'employee' => $line['employee_id'],
          'base' => $line['base_salary'],
          'deduction' => $line['advance_deduction'],
          'net' => $line['net_pay'],
        ]);
        if ($line['advance_deduction'] > 0) {
          $this->recoverAdvance((int) $line['employee_id'], (float) $line['advance_deduction']);
        }
      }

      $this->pdo->commit();
    } catch (\Throwable) {
      $this->pdo->rollBack();

      return null;
    }

    $run = $this->findRunById($runId);
    if ($run !== null) {
      $run['lines'] = $this->runLines($runId);
    }

    return $run;
  }

  public function findRunById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT pr.*, pp.period_start, pp.period_end
       FROM payroll_runs pr
       JOIN payroll_periods pp ON pp.id = pr.payroll_period_id
       WHERE pr.id = :id AND pr.business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @return array<int, array<string, mixed>> */
  public function listSalaryAdvances(?int $employeeId = null): array
  {
    $sql = 'SELECT sa.*, e.full_name AS employee_name, e.employee_no
            FROM salary_advances sa
            JOIN employees e ON e.id = sa.employee_id
            WHERE sa.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];
    if ($employeeId !== null) {
      $sql .= ' AND sa.employee_id = :employee';
      $params['employee'] = $employeeId;
    }
    $sql .= ' ORDER BY sa.created_at DESC';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function createSalaryAdvance(array $data, int $userId): array
  {
    $amount = round((float) ($data['amount'] ?? 0), 2);
    $stmt = $this->pdo->prepare(
      'INSERT INTO salary_advances (uuid, business_owner_id, employee_id, amount, balance_remaining, notes, created_by, created_at)
       VALUES (:uuid, :owner, :employee, :amount, :balance, :notes, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'employee' => (int) ($data['employee_id'] ?? 0),
      'amount' => $amount,
      'balance' => $amount,
      'notes' => $data['notes'] ?? null,
      'user' => $userId,
    ]);

    $id = (int) $this->pdo->lastInsertId();
    $stmt = $this->pdo->prepare('SELECT sa.*, e.full_name AS employee_name FROM salary_advances sa JOIN employees e ON e.id = sa.employee_id WHERE sa.id = :id');
    $stmt->execute(['id' => $id]);

    return $stmt->fetch() ?: [];
  }

  /** @return array{run_count: int, total_paid: float, employee_count: int} */
  public function summary(string $from, string $to): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(DISTINCT pr.id) AS run_count,
              COALESCE(SUM(pr.total_amount), 0) AS total_paid,
              COALESCE(SUM((SELECT COUNT(*) FROM payroll_lines pl WHERE pl.payroll_run_id = pr.id)), 0) AS line_count
       FROM payroll_runs pr
       JOIN payroll_periods pp ON pp.id = pr.payroll_period_id
       WHERE pr.business_owner_id = :owner
         AND pp.period_start >= :from AND pp.period_end <= :to'
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'from' => $from, 'to' => $to]);
    $row = $stmt->fetch() ?: [];

    return [
      'run_count' => (int) ($row['run_count'] ?? 0),
      'total_paid' => round((float) ($row['total_paid'] ?? 0), 2),
      'employee_count' => (int) ($row['line_count'] ?? 0),
    ];
  }

  private function findRunByPeriod(int $periodId): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM payroll_runs WHERE payroll_period_id = :period AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['period' => $periodId, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  /** @return array<int, array<string, mixed>> */
  public function runLines(int $runId): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT pl.*, e.full_name AS employee_name, e.employee_no
       FROM payroll_lines pl
       JOIN employees e ON e.id = pl.employee_id
       WHERE pl.payroll_run_id = :run ORDER BY e.full_name'
    );
    $stmt->execute(['run' => $runId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<int, int>|null $employeeIds */
  /** @return array<int, array<string, mixed>> */
  private function activeEmployees(?array $employeeIds = null): array
  {
    $sql = 'SELECT id, base_salary FROM employees WHERE business_owner_id = :owner AND is_active = 1';
    $params = ['owner' => $this->businessOwnerId];
    if ($employeeIds !== null && $employeeIds !== []) {
      $placeholders = [];
      foreach ($employeeIds as $idx => $employeeId) {
        $key = 'emp' . $idx;
        $placeholders[] = ':' . $key;
        $params[$key] = $employeeId;
      }
      $sql .= ' AND id IN (' . implode(', ', $placeholders) . ')';
    }
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  private function openAdvanceTotal(int $employeeId): float
  {
    $stmt = $this->pdo->prepare(
      'SELECT COALESCE(SUM(balance_remaining), 0) FROM salary_advances
       WHERE employee_id = :employee AND business_owner_id = :owner AND status = :status'
    );
    $stmt->execute(['employee' => $employeeId, 'owner' => $this->businessOwnerId, 'status' => 'open']);

    return (float) $stmt->fetchColumn();
  }

  private function recoverAdvance(int $employeeId, float $amount): void
  {
    $remaining = $amount;
    $stmt = $this->pdo->prepare(
      'SELECT id, balance_remaining FROM salary_advances
       WHERE employee_id = :employee AND business_owner_id = :owner AND status = :status AND balance_remaining > 0
       ORDER BY created_at ASC'
    );
    $stmt->execute(['employee' => $employeeId, 'owner' => $this->businessOwnerId, 'status' => 'open']);
    $advances = $stmt->fetchAll() ?: [];

    $upd = $this->pdo->prepare(
      'UPDATE salary_advances SET balance_remaining = :balance, status = :status WHERE id = :id'
    );
    foreach ($advances as $adv) {
      if ($remaining <= 0) {
        break;
      }
      $bal = (float) $adv['balance_remaining'];
      $deduct = min($bal, $remaining);
      $newBal = round($bal - $deduct, 2);
      $upd->execute([
        'balance' => $newBal,
        'status' => $newBal <= 0 ? 'recovered' : 'open',
        'id' => $adv['id'],
      ]);
      $remaining -= $deduct;
    }
  }

  private function nextRunNo(): string
  {
    $stmt = $this->pdo->prepare('SELECT COALESCE(MAX(id), 0) + 1 FROM payroll_runs WHERE business_owner_id = :owner');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    $n = (int) $stmt->fetchColumn();

    return 'PR-' . str_pad((string) $n, 6, '0', STR_PAD_LEFT);
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
