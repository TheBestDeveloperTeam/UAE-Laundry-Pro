<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\SalesRepository;
use PDO;

class SalesController
{
    public function __construct(
        private readonly SalesRepository $repository,
        private readonly PDO $db
    ) {
    }

    public function create(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $userId = $request->getAttribute('user_id'); // From AuthMiddleware
        
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $data = $request->getBody();
        $validator = new Validator($data, $this->db);

        $rules = [
            'status' => 'enum:draft,confirmed,paid',
            'lines' => 'required|array',
            'payments' => 'array'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $order = $this->repository->createOrder(
                (int)$adminId, 
                $data, 
                $data['lines'], 
                $data['payments'] ?? [],
                $userId ? (int)$userId : null
            );
            $response->success($order, 'Sales order created successfully', null, 201);
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    public function index(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $stmt = $this->db->prepare("SELECT * FROM sales_orders WHERE admin_id = ? ORDER BY id DESC LIMIT 100");
        $stmt->execute([$adminId]);
        $response->success($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function show(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        $orderId = (int) ($args['id'] ?? 0);
        $order = $this->repository->getOrder((int)$adminId, $orderId);

        if (!$order) {
            $response->error(404, 'Order not found');
            return;
        }

        $response->success($order, 'Order retrieved successfully');
    }

    public function draft(Request $request, Response $response): void
    {
        $this->create($request, $response);
    }

    public function confirm(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        $orderId = (int) ($args['id'] ?? 0);
        $stmt = $this->db->prepare("UPDATE sales_orders SET status = 'confirmed' WHERE admin_id = ? AND id = ?");
        $stmt->execute([$adminId, $orderId]);
        $response->success(null, 'Order confirmed');
    }

    public function payment(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        $orderId = (int) ($args['id'] ?? 0);
        $data = $request->getBody();
        
        $stmt = $this->db->prepare("UPDATE sales_orders SET payment_status = 'paid', status = 'closed' WHERE admin_id = ? AND id = ?");
        $stmt->execute([$adminId, $orderId]);
        $response->success(null, 'Payment posted');
    }

    public function updateStatus(Request $request, Response $response, array $args): void
    {
        $adminId = $request->getAttribute('admin_id');
        $orderId = (int) ($args['id'] ?? 0);
        $data = $request->getBody();
        $status = $data['status'] ?? 'pending';
        
        $stmt = $this->db->prepare("UPDATE sales_orders SET status = ? WHERE admin_id = ? AND id = ?");
        $stmt->execute([$status, $adminId, $orderId]);
        $response->success(null, 'Status updated');
    }

    public function statusHistory(Request $request, Response $response, array $args): void
    {
        $response->success([]);
    }

    public function listDeliveryTasks(Request $request, Response $response, array $args): void
    {
        $response->success([]);
    }

    public function storeDeliveryTask(Request $request, Response $response, array $args): void
    {
        $response->success(null, '', null, 201);
    }
}
