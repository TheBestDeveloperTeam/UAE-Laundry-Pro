<?php
declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\EquipmentRepository;
use LaundryPro\Api\Core\Container;

final class EquipmentController
{
    public function __construct(
        private readonly ApiResponse ,
        private readonly EquipmentRepository 
    ) {
    }

    public function listAll(Request ): void
    {
         = ->repository->getAllEquipment();
        ->response->success(, ['equipment' => ], 'EQUIPMENT_LIST', 'equipment.list', 200);
    }

    public function logCalibration(Request , Container ): void
    {
         = (int) ->route('id');
         = ->all();

        if (!isset(['calibrated_at'], ['performed_by'], ['certificate_ref'], ['next_calibration_due'])) {
            ->response->error(, 'Missing required fields', 422, 'VALIDATION_ERROR');
            return;
        }

         = ->repository->getEquipmentById();
        if (!) {
            ->response->error(, 'Equipment not found', 404, 'NOT_FOUND');
            return;
        }

         = ->repository->logCalibration(
            ,
            ['calibrated_at'],
            ['performed_by'],
            ['certificate_ref'],
            ['next_calibration_due']
        );

        ->response->success(, ['id' => ], 'CALIBRATION_LOGGED', 'equipment.calibration_logged', 201);
    }

    public function setOutOfService(Request , Container ): void
    {
         = (int) ->route('id');
         = ->all();

        if (!isset(['out_of_service'])) {
            ->response->error(, 'Missing required fields', 422, 'VALIDATION_ERROR');
            return;
        }

         = ->repository->getEquipmentById();
        if (!) {
            ->response->error(, 'Equipment not found', 404, 'NOT_FOUND');
            return;
        }

        ->repository->setOutOfService(, (bool) ['out_of_service']);

        ->response->success(, null, 'STATUS_UPDATED', 'equipment.status_updated', 200);
    }
}

