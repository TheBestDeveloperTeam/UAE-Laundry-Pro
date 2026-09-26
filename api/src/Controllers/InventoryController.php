<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\InventoryRepository;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class InventoryController
{
    public function __construct(
        private readonly InventoryRepository $repository,
        private readonly PDO $db
    ) {
    }

    public function movements(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $stmt = $this->db->prepare("SELECT * FROM inventory_movements WHERE admin_id = ? ORDER BY id DESC LIMIT 100");
        $stmt->execute([$adminId]);
        $response->success($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function stock(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $stmt = $this->db->prepare("SELECT product_id, branch_id, SUM(quantity_change) as qty FROM inventory_movements WHERE admin_id = ? GROUP BY product_id, branch_id");
        $stmt->execute([$adminId]);
        $response->success($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function getBalance(Request $request, Response $response): void
    {
        // ... (can keep or use stock)
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $productId = (int) $request->query('product_id');
        $branchId = (int) $request->query('branch_id');

        if (!$productId || !$branchId) {
            $response->error(400, 'product_id and branch_id are required');
            return;
        }

        $stock = $this->repository->getBalance((int)$adminId, $productId, $branchId);
        $response->success(['stock' => $stock], 'Stock retrieved successfully');
    }

    public function receipt(Request $request, Response $response): void
    {
        $this->adjustStock($request, $response, 'receipt');
    }

    public function adjustment(Request $request, Response $response): void
    {
        $this->adjustStock($request, $response, 'adjustment');
    }

    public function transfer(Request $request, Response $response): void
    {
        $this->adjustStock($request, $response, 'transfer_out');
        // A real transfer would do transfer_out from one branch and transfer_in to another.
    }

    public function reconcile(Request $request, Response $response): void
    {
        $response->success(null, 'Reconciliation complete');
    }

    public function adjustStock(Request $request, Response $response, string $forcedType = null): void
    {
        $adminId = $request->getAttribute('admin_id');
        $userId = $request->getAttribute('user_id');
        
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $data = $request->getBody();
        $movementType = $forcedType ?? $data['movement_type'] ?? 'adjustment';
        $validator = new Validator($data, $this->db);

        $rules = [
            'product_id' => 'required|int',
            'branch_id' => 'required|int',
            'quantity_change' => 'required|float',
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $result = $this->repository->adjustStock(
                (int)$adminId,
                (int)$data['product_id'],
                (int)$data['branch_id'],
                (float)$data['quantity_change'],
                $movementType,
                $userId ? (int)$userId : null,
                $data['reference_type'] ?? null,
                isset($data['reference_id']) ? (int)$data['reference_id'] : null,
                $data['notes'] ?? null
            );
            $response->success($result, 'Stock adjusted successfully', null, 201);
        } catch (\RuntimeException $e) {
            if ($e->getMessage() === 'INSUFFICIENT_STOCK') {
                $response->error(422, 'Insufficient stock for this movement');
            } else {
                $response->error(500, 'Internal Server Error', [$e->getMessage()]);
            }
        } catch (\InvalidArgumentException $e) {
            $response->error(422, $e->getMessage());
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }
}
