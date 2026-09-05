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
    $orderId = (int) ($request->input('sales_order_id') ?? 0);
    $order = $this->sales->findById($orderId);
    if ($order === null) {
      $this->response->error($request, 'NOT_FOUND', 'portal.order_not_found', 404);
      return;
    }
    $token = $this->portal->createToken($orderId);
    $this->response->success($request, ['portal' => $token], 'PORTAL_TOKEN_CREATED', 'portal.token_created', 201);
  }

  public function orderStatus(Request $request, Container $container): void
  {
    $token = (string) ($request->query('token') ?? $request->route('token', ''));
    if ($token === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'portal.token_required', 422);
      return;
    }
    $data = $this->portal->findByToken($token);
    if ($data === null) {
      $this->response->error($request, 'NOT_FOUND', 'portal.invalid_token', 404);
      return;
    }
    $this->response->success($request, ['order' => $data], 'PORTAL_ORDER_STATUS', 'portal.status');
  }
}
