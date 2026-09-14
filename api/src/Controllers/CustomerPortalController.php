<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;

final class CustomerPortalController
{
  public function __construct(
    private readonly ApiResponse $response
  ) {}

  public function getOrders(Request $request, Container $container): void
  {
     $this->response->success($request, ['orders' => []], 'PORTAL_ORDERS', 'portal.orders');
  }

  public function createToken(Request $request, Container $container): void
  {
     $this->response->success($request, ['token' => 'mock_token'], 'PORTAL_TOKEN_CREATED', 'portal.token_created', 201);
  }

  public function orderStatus(Request $request, Container $container): void
  {
     $this->response->success($request, ['status' => 'processing'], 'PORTAL_ORDER_STATUS', 'portal.order_status');
  }
}
