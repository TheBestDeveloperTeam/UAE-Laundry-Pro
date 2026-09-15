<?php
declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

class EquipmentRepository
{
    public function __construct(private readonly PDO )
    {
    }

    public function getAllEquipment(): array
    {
         = ->pdo->query('SELECT * FROM equipment ORDER BY asset_tag ASC');
        return ->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getEquipmentById(int ): ?array
    {
         = ->pdo->prepare('SELECT * FROM equipment WHERE id = :id');
        ->execute(['id' => ]);
         = ->fetch(PDO::FETCH_ASSOC);
        return  ?: null;
    }

    public function logCalibration(int , string , string , string , string ): int
    {
        ->pdo->beginTransaction();
        try {
            // Insert calibration record
             = ->pdo->prepare('
                INSERT INTO calibration_records (equipment_id, calibrated_at, performed_by, certificate_ref, created_at)
                VALUES (:eq_id, :cal_date, :perf_by, :cert, UTC_TIMESTAMP())
            ');
            ->execute([
                'eq_id' => ,
                'cal_date' => ,
                'perf_by' => ,
                'cert' => 
            ]);
             = (int) ->pdo->lastInsertId();

            // Update equipment last and next dates
             = ->pdo->prepare('
                UPDATE equipment 
                SET last_calibration_date = :last_date, next_calibration_due = :next_date, out_of_service = 0
                WHERE id = :eq_id
            ');
            ->execute([
                'last_date' => ,
                'next_date' => ,
                'eq_id' => 
            ]);

            ->pdo->commit();
            return ;
        } catch (\Exception ) {
            ->pdo->rollBack();
            throw ;
        }
    }

    public function setOutOfService(int , bool ): void
    {
         = ->pdo->prepare('UPDATE equipment SET out_of_service = :oos WHERE id = :id');
        ->execute([
            'oos' =>  ? 1 : 0,
            'id' => 
        ]);
    }
}

