<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\SterilizationRepository;

final class SterilizationController
{
    public function __construct(
        private readonly ApiResponse $response,
        private readonly SterilizationRepository $repository
    ) {
    }

    public function batchCreate(Request $request): void
    {
        $data = $request->all();
        if (!isset($data["lot_number"], $data["expiry_date"], $data["origin_sales_order_id"])) {
            $this->response->error($request, "Missing required fields", 422, "VALIDATION_ERROR");
            return;
        }
        
        $id = $this->repository->createBatchLot(
            $data["lot_number"],
            $data["expiry_date"],
            (int) $data["origin_sales_order_id"]
        );
        
        $this->response->success($request, ["id" => $id], "BATCH_CREATED", "sterilization.batch_created", 201);
    }

    public function batchScan(Request $request): void
    {
        $data = $request->all();
        if (!isset($data["batch_lot_id"], $data["scan_type"], $data["device_id"])) {
            $this->response->error($request, "Missing required fields", 422, "VALIDATION_ERROR");
            return;
        }

        $id = $this->repository->scanBatch(
            (int) $data["batch_lot_id"],
            $data["scan_type"],
            $data["device_id"]
        );

        $this->response->success($request, ["id" => $id], "BATCH_SCANNED", "sterilization.batch_scanned", 201);
    }

    public function logSterilization(Request $request): void
    {
        $data = $request->all();
        if (!isset($data["cycle_run_id"], $data["autoclave_program"], $data["pressure_kpa"], $data["temperature_c"], $data["duration_minutes"], $data["validation_result"])) {
            $this->response->error($request, "Missing required fields", 422, "VALIDATION_ERROR");
            return;
        }

        $id = $this->repository->logSterilization(
            (int) $data["cycle_run_id"],
            $data["autoclave_program"],
            (float) $data["pressure_kpa"],
            (float) $data["temperature_c"],
            (int) $data["duration_minutes"],
            $data["validation_result"]
        );

        $this->response->success($request, ["id" => $id], "LOG_CREATED", "sterilization.log_created", 201);
    }

    public function signElectronic(Request $request, \LaundryPro\Api\Core\Container $container): void
    {
        $data = $request->all();
        if (!isset($data["cycle_run_id"], $data["signature_hash"], $data["meaning"])) {
            $this->response->error($request, "Missing required fields", 422, "VALIDATION_ERROR");
            return;
        }
        $userId = $container->has('auth.user_id') ? $container->get('auth.user_id') : 1;

        $id = $this->repository->signElectronic(
            (int) $data["cycle_run_id"],
            (int) $userId,
            $data["signature_hash"],
            $data["meaning"]
        );

        $this->response->success($request, ["id" => $id], "SIGNED", "sterilization.signed", 201);
    }

    public function listLogs(Request $request, \LaundryPro\Api\Core\Container $container): void
    {
        $cycleRunId = $request->route('cycleRunId');
        $logs = $this->repository->getLogsByCycleRun((int) $cycleRunId);
        $this->response->success($request, ["logs" => $logs], "LOGS_LIST", "sterilization.logs_list", 200);
    }
}

