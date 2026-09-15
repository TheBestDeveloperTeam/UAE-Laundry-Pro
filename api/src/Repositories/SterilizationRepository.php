<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use RuntimeException;

class SterilizationRepository
{
    private PDO $pdo;

    public function __construct(PDO $pdo)
    {
        $this->pdo = $pdo;
    }

    public function createBatchLot(string $lotNumber, string $expiryDate, int $originSalesOrderId): int
    {
        $stmt = $this->pdo->prepare("INSERT INTO batch_lots (lot_number, expiry_date, origin_sales_order_id, status) VALUES (?, ?, ?, 'active')");
        $stmt->execute([$lotNumber, $expiryDate, $originSalesOrderId]);
        return (int) $this->pdo->lastInsertId();
    }

    public function scanBatch(int $batchLotId, string $scanType, string $deviceId): int
    {
        $stmt = $this->pdo->prepare('INSERT INTO batch_scan_events (batch_lot_id, scan_type, device_id) VALUES (?, ?, ?)');
        $stmt->execute([$batchLotId, $scanType, $deviceId]);
        return (int) $this->pdo->lastInsertId();
    }

    public function logSterilization(int $cycleRunId, string $autoclaveProgram, float $pressureKpa, float $temperatureC, int $durationMinutes, string $validationResult): int
    {
        $stmt = $this->pdo->prepare('INSERT INTO sterilization_logs (cycle_run_id, autoclave_program, pressure_kpa, temperature_c, duration_minutes, validation_result) VALUES (?, ?, ?, ?, ?, ?)');
        $stmt->execute([$cycleRunId, $autoclaveProgram, $pressureKpa, $temperatureC, $durationMinutes, $validationResult]);
        $id = (int) $this->pdo->lastInsertId();

        if ($validationResult === 'rejected') {
            $updateStmt = $this->pdo->prepare("UPDATE advanced_cycle_runs SET status = 'exception' WHERE id = ?");
            $updateStmt->execute([$cycleRunId]);
        }

        return $id;
    }

    public function signElectronic(int $cycleRunId, int $userId, string $signatureHash, string $meaning): int
    {
        $stmt = $this->pdo->prepare('INSERT INTO electronic_signatures (cycle_run_id, user_id, signature_hash, meaning) VALUES (?, ?, ?, ?)');
        $stmt->execute([$cycleRunId, $userId, $signatureHash, $meaning]);
        return (int) $this->pdo->lastInsertId();
    }

    public function getLogsByCycleRun(int $cycleRunId): array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM sterilization_logs WHERE cycle_run_id = ? ORDER BY created_at DESC');
        $stmt->execute([$cycleRunId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
