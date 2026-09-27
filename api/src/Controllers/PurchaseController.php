<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\PurchaseRepository;
use PDO;

class PurchaseController
{
    public function __construct(
        private readonly PurchaseRepository $repository,
        private readonly PDO $db
    ) {
    }

    public function createPO(Request $request, Response $response): void
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
            'vendor_id' => 'required|int',
            'lines' => 'required|array'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $po = $this->repository->createPO(
                (int)$adminId,
                $data,
                $data['lines'],
                $userId ? (int)$userId : null
            );
            $response->success($po, 'Purchase order created successfully', null, 201);
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    public function receivePO(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        $userId = $request->getAttribute('user_id');

        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $poId = (int) ($args['id'] ?? 0);
        $data = $request->getBody();
        $validator = new Validator($data, $this->db);

        $rules = [
            'lines' => 'required|array'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $status = $this->repository->receivePO(
                (int)$adminId,
                $poId,
                $data['lines'],
                $userId ? (int)$userId : null
            );
            $response->success($status, 'Purchase order received successfully');
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }
}
