<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\ProductRepository;
use PDO;

class ProductController
{
    public function __construct(
        private readonly ProductRepository $repository,
        private readonly PDO $db
    ) {
    }

    public function index(Request $request, Response $response): void
    {
        // Assuming TenantMiddleware injects admin_id into the request user attributes
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $activeOnly = filter_var($request->getQuery('active_only', true), FILTER_VALIDATE_BOOLEAN);
        $products = $this->repository->getAll((int) $adminId, $activeOnly);

        $response->success($products, 'Products retrieved successfully');
    }

    public function create(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $data = $request->getBody();
        $validator = new Validator($data, $this->db);

        $rules = [
            'name' => 'required|string|max:150',
            'default_rate' => 'numeric|min:0',
            'stock_class' => 'enum:retail,consumable,asset',
            'is_active' => 'boolean',
            'details' => 'array'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        $details = $data['details'] ?? [];
        $result = $this->repository->create((int) $adminId, $data, $details);

        $response->success($result, 'Product created successfully', null, 201);
    }
}
