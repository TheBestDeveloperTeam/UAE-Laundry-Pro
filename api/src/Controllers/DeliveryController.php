<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\DeliveryRepository;
use PDO;

class DeliveryController
{
    public function __construct(
        private readonly DeliveryRepository $repository,
        private readonly PDO $db
    ) {
    }

    public function schedule(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $data = $request->getBody();
        $validator = new Validator($data, $this->db);

        $rules = [
            'task_type' => 'required|enum:pickup,delivery',
            'customer_id' => 'required|int',
            'scheduled_date' => 'required',
            'address' => 'required'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $task = $this->repository->scheduleTask(
                (int)$adminId, 
                $data, 
                $data['lines'] ?? []
            );
            $response->success($task, 'Task scheduled successfully', null, 201);
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    public function updateStatus(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $taskId = (int) ($args['id'] ?? 0);
        $data = $request->getBody();
        
        $status = $data['status'] ?? null;
        if (!$status) {
            $response->error(400, 'Status is required');
            return;
        }

        try {
            $this->repository->updateStatus(
                (int)$adminId, 
                $taskId, 
                $status,
                $data['failure_reason'] ?? null
            );
            $response->success(null, 'Task status updated successfully');
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }
}
