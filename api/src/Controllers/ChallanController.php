<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\ChallanRepository;
use PDO;

class ChallanController
{
    public function __construct(
        private readonly ChallanRepository $repository,
        private readonly PDO $db
    ) {
    }

    public function create(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $userId = $request->getAttribute('user_id');

        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $data = $request->getBody();
        $validator = new Validator($data, $this->db);

        $rules = [
            'source_branch_id' => 'required|int',
            'destination_branch_id' => 'required|int',
            'order_ids' => 'required|array'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $challan = $this->repository->createDraft(
                (int)$adminId,
                $data,
                $data['order_ids'],
                $userId ? (int)$userId : null
            );
            $response->success($challan, 'Challan created successfully', null, 201);
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    public function dispatch(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        $userId = $request->getAttribute('user_id');

        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $challanId = (int) ($args['id'] ?? 0);

        try {
            $this->repository->dispatch(
                (int)$adminId,
                $challanId,
                $userId ? (int)$userId : null
            );
            $response->success(null, 'Challan dispatched successfully');
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    public function receive(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        $userId = $request->getAttribute('user_id');

        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $challanId = (int) ($args['id'] ?? 0);

        try {
            $this->repository->receive(
                (int)$adminId,
                $challanId,
                $userId ? (int)$userId : null
            );
            $response->success(null, 'Challan received successfully');
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }
}
