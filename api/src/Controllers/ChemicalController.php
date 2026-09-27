<?php
declare(strict_types=1);
namespace LaundryPro\Api\Controllers;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Repositories\InventoryRepository;

class ChemicalController
{
    public function __construct(
        private readonly InventoryRepository $inventory
    ) {}

    public function logUsage(Request $request): Response
    {
        $body = $request->getParsedBody();
        $items = $body['items'] ?? [];
        $orderId = (int)($body['sale_id'] ?? 0);

        if (empty($items) || $orderId <= 0) {
            return Response::json(['success' => false, 'error' => 'Invalid payload'], 400);
        }

        $userId = $request->getAttribute('user_id') ?? 1;
        $this->inventory->consumeForSale($orderId, $items, (int)$userId);

        return Response::json(['success' => true, 'data' => ['message' => 'Chemical usage logged']], 201);
    }
}
