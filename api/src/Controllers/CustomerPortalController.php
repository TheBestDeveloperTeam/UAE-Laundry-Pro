<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\CustomerPortalRepository;
use LaundryPro\Api\Repositories\SalesRepository;

final class CustomerPortalController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly CustomerPortalRepository $portal,
    private readonly SalesRepository $sales,
  ) {
  }

  public function createToken(Request $request, Container $container): void
  {
    $salesOrderId = (int) $request->input('sales_order_id', 0);
    if ($salesOrderId <= 0) {
      $this->response->error($request, 'VALIDATION_ERROR', 'portal.sales_order_id_required', 422);
      return;
    }

    $token = $this->portal->createToken($salesOrderId);
    $this->response->success($request, ['portal' => $token], 'PORTAL_TOKEN_CREATED', 'portal.token_created', 201);
  }

  public function orderStatus(Request $request, Container $container): void
  {
    $token = (string) ($request->query('token') ?? $request->input('token') ?? '');
    if ($token === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'portal.token_required', 422);
      return;
    }

    $order = $this->portal->findByToken($token);
    if ($order === null) {
      $this->response->error($request, 'NOT_FOUND', 'portal.not_found', 404);
      return;
    }

    $this->response->success($request, [
      'order' => $order,
      'status' => $order['status'] ?? 'unknown',
    ], 'PORTAL_ORDER_STATUS', 'portal.order_status');
  }

  public function getOrders(Request $request, Container $container): void
  {
    $this->response->success($request, ['orders' => []], 'PORTAL_ORDERS', 'portal.orders');
  }
}
