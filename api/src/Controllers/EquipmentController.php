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
        private readonly ApiResponse $response,
        private readonly EquipmentRepository $repository
    ) {
    }

    public function listAll(Request $request): void
    {
        $equipment = $this->repository->getAllEquipment();
        $this->response->success($request, ['equipment' => $equipment], 'EQUIPMENT_LIST', 'equipment.list', 200);
    }

    public function logCalibration(Request $request, Container $container): void
    {
        $id = (int) $request->route('id');
        $payload = $request->all();

        if (!isset($payload['calibrated_at'], $payload['performed_by'], $payload['certificate_ref'], $payload['next_calibration_due'])) {
            $this->response->error($request, 'Missing required fields', 422, 'VALIDATION_ERROR');
            return;
        }

        $equipment = $this->repository->getEquipmentById($id);
        if (!$equipment) {
            $this->response->error($request, 'Equipment not found', 404, 'NOT_FOUND');
            return;
        }

        $logId = $this->repository->logCalibration(
            $id,
            $payload['calibrated_at'],
            $payload['performed_by'],
            $payload['certificate_ref'],
            $payload['next_calibration_due']
        );

        $this->response->success($request, ['id' => $logId], 'CALIBRATION_LOGGED', 'equipment.calibration_logged', 201);
    }

    public function setOutOfService(Request $request, Container $container): void
    {
        $id = (int) $request->route('id');
        $payload = $request->all();

        if (!isset($payload['out_of_service'])) {
            $this->response->error($request, 'Missing required fields', 422, 'VALIDATION_ERROR');
            return;
        }

        $equipment = $this->repository->getEquipmentById($id);
        if (!$equipment) {
            $this->response->error($request, 'Equipment not found', 404, 'NOT_FOUND');
            return;
        }

        $this->repository->setOutOfService($id, (bool) $payload['out_of_service']);

        $this->response->success($request, null, 'STATUS_UPDATED', 'equipment.status_updated', 200);
    }
}
