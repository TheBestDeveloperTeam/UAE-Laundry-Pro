<?php
declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

class EquipmentRepository
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function getAllEquipment(): array
    {
        $stmt = $this->pdo->query('SELECT * FROM equipment ORDER BY asset_tag ASC');
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getEquipmentById(int $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM equipment WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    public function logCalibration(int $id, string $calibrated_at, string $performed_by, string $certificate_ref, string $next_calibration_due): int
    {
        $this->pdo->beginTransaction();
        try {
            // Insert calibration record
            $stmt = $this->pdo->prepare('
                INSERT INTO calibration_records (equipment_id, calibrated_at, performed_by, certificate_ref, created_at)
                VALUES (:eq_id, :cal_date, :perf_by, :cert, UTC_TIMESTAMP())
            ');
            $stmt->execute([
                'eq_id' => $id,
                'cal_date' => $calibrated_at,
                'perf_by' => $performed_by,
                'cert' => $certificate_ref
            ]);
            $insertId = (int) $this->pdo->lastInsertId();

            // Update equipment last and next dates
            $update = $this->pdo->prepare('
                UPDATE equipment 
                SET last_calibration_date = :last_date, next_calibration_due = :next_date, out_of_service = 0
                WHERE id = :eq_id
            ');
            $update->execute([
                'last_date' => $calibrated_at,
                'next_date' => $next_calibration_due,
                'eq_id' => $id
            ]);

            $this->pdo->commit();
            return $insertId;
        } catch (\Exception $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    public function setOutOfService(int $id, bool $out_of_service): void
    {
        $stmt = $this->pdo->prepare('UPDATE equipment SET out_of_service = :oos WHERE id = :id');
        $stmt->execute([
            'oos' => $out_of_service ? 1 : 0,
            'id' => $id
        ]);
    }
}
