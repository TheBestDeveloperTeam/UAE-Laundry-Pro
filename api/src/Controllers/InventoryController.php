<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\InventoryRepository;
use RuntimeException;

final class InventoryController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly InventoryRepository $inventory,
  ) {
  }

  public function movements(Request $request, Container $container): void
  {
    $productId = $request->query('product_id');
    $items = $this->inventory->listMovements($productId !== null ? (int) $productId : null);
    $this->response->success($request, ['movements' => $items], 'INVENTORY_MOVEMENTS', 'inventory.movements_list');
  }

  public function receipt(Request $request, Container $container): void
  {
    try {
      $userId = (int) $container->get('auth.user_id');
      $movement = $this->inventory->receipt($request->all(), $userId);
      $this->response->success($request, ['movement' => $movement], 'INVENTORY_RECEIPT', 'inventory.receipt_created', 201);
    } catch (RuntimeException $e) {
      $code = $e->getMessage();
      if ($code === 'NOT_FOUND') {
        $this->response->error($request, 'NOT_FOUND', 'inventory.product_not_found', 404);
        return;
      }
      $this->response->error($request, 'VALIDATION_ERROR', 'inventory.validation_failed', 422);
    }
  }

  public function adjustment(Request $request, Container $container): void
  {
    try {
      $userId = (int) $container->get('auth.user_id');
      $product = $this->inventory->adjustment($request->all(), $userId);
      $this->response->success($request, ['product' => $product], 'INVENTORY_ADJUSTED', 'inventory.adjusted');
    } catch (RuntimeException $e) {
      $code = $e->getMessage();
      if ($code === 'NOT_FOUND') {
        $this->response->error($request, 'NOT_FOUND', 'inventory.product_not_found', 404);
        return;
      }
      $this->response->error($request, 'VALIDATION_ERROR', 'inventory.validation_failed', 422);
    }
  }

  public function stock(Request $request, Container $container): void
  {
    $productId = $request->query('product_id');
    $items = $this->inventory->stock($productId !== null ? (int) $productId : null);
    $this->response->success($request, ['stock' => $items], 'INVENTORY_STOCK', 'inventory.stock_list');
  }

  public function reconcile(Request $request, Container $container): void
  {
    $confirm = $request->input('confirm') === true
      || $request->input('confirm') === 'true'
      || $request->input('confirm') === '1';
    $userId = (int) $container->get('auth.user_id');
    $result = $this->inventory->reconcile($confirm, $userId);
    $code = $confirm ? 'INVENTORY_RECONCILED' : 'INVENTORY_RECONCILE_PREVIEW';
    $this->response->success($request, $result, $code, 'inventory.reconciled');
  }
}
