<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\InvoiceRepository;
use PDO;

class InvoiceController
{
    public function __construct(
        private readonly InvoiceRepository $repository,
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
            'customer_id' => 'required|int',
            'lines' => 'required|array'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $invoice = $this->repository->createInvoice(
                (int)$adminId, 
                $data, 
                $data['lines'], 
                $userId ? (int)$userId : null
            );
            $response->success($invoice, 'Invoice created successfully', null, 201);
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }
}
