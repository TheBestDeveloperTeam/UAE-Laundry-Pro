<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use RuntimeException;

final class AdvancedCycleRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly SyncOutboxRepository $outbox
  ) {
  }

  public function getPresets(): array
  {
    $stmt = $this->pdo->query('SELECT id, code, name_en, name_ar, min_temperature, max_temperature, min_ph, max_ph, expected_duration_minutes, is_active FROM advanced_cycle_presets WHERE is_active = 1');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
  }

  public function checkEquipment(int $equipmentId): ?array
  {
    $stmt = $this->pdo->prepare('SELECT out_of_service, next_calibration_due FROM equipment WHERE id = :id');
    $stmt->execute(['id' => $equipmentId]);
    $res = $stmt->fetch(PDO::FETCH_ASSOC);
    return $res ?: null;
  }

  public function checkOperator(int $operatorId): ?array
  {
    $stmt = $this->pdo->prepare('SELECT MAX(expires_at) as certification_expires_at FROM operator_certifications WHERE employee_id = :id');
    $stmt->execute(['id' => $operatorId]);
    $res = $stmt->fetch(PDO::FETCH_ASSOC);
    return $res ?: null;
  }

  public function startCycle(int $businessOwnerId, int $equipmentId, int $operatorId, int $presetId, int $saleOrderId): int
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO advanced_cycle_runs (equipment_id, operator_id, preset_id, sale_order_id, status, started_at)
       VALUES (:eq, :op, :pr, :so, "running", UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'eq' => $equipmentId,
      'op' => $operatorId,
      'pr' => $presetId,
      'so' => $saleOrderId
    ]);
    
    $id = (int) $this->pdo->lastInsertId();
    $this->outbox->enqueue($businessOwnerId, 'advanced_cycle_run', $id, 'create', ['status' => 'running']);
    return $id;
  }

  public function completeCycle(int $businessOwnerId, int $cycleRunId): void
  {
    $stmt = $this->pdo->prepare('UPDATE advanced_cycle_runs SET status = "completed", completed_at = UTC_TIMESTAMP() WHERE id = :id AND status = "running"');
    $stmt->execute(['id' => $cycleRunId]);
    
    if ($stmt->rowCount() > 0) {
      $this->outbox->enqueue($businessOwnerId, 'advanced_cycle_run', $cycleRunId, 'update', ['status' => 'completed']);
    }
  }

  public function getCycleRun(int $cycleRunId): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM advanced_cycle_runs WHERE id = :id');
    $stmt->execute(['id' => $cycleRunId]);
    $res = $stmt->fetch(PDO::FETCH_ASSOC);
    return $res ?: null;
  }

  public function recordProcessLog(int $businessOwnerId, int $cycleRunId, string $metricType, string $readingValue, bool $passFail): int
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO process_logs (cycle_run_id, metric_type, reading_value, pass_fail, recorded_at)
       VALUES (:cr, :mt, :rv, :pf, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'cr' => $cycleRunId,
      'mt' => $metricType,
      'rv' => $readingValue,
      'pf' => $passFail ? 1 : 0
    ]);
    
    $logId = (int) $this->pdo->lastInsertId();
    $this->outbox->enqueue($businessOwnerId, 'process_log', $logId, 'create', []);
    
    if (!$passFail) {
      // Transition to exception
      $this->pdo->prepare('UPDATE advanced_cycle_runs SET status = "exception" WHERE id = :id AND status = "running"')->execute(['id' => $cycleRunId]);
      $this->outbox->enqueue($businessOwnerId, 'advanced_cycle_run', $cycleRunId, 'update', ['status' => 'exception']);
    }
    
    return $logId;
  }
}
