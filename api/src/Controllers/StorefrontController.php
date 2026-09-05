<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\CatalogRepository;
use LaundryPro\Api\Repositories\SalesRepository;
use LaundryPro\Api\Repositories\StorefrontRepository;

final class StorefrontController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly StorefrontRepository $storefront,
    private readonly CatalogRepository $catalog,
    private readonly SalesRepository $sales,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function catalog(Request $request, Container $container): void
  {
    $services = $this->catalog->listServices();
    $products = $this->catalog->listProducts();
    $this->response->success($request, ['services' => $services, 'products' => $products], 'STOREFRONT_CATALOG', 'storefront.catalog');
  }

  public function submitOrder(Request $request, Container $container): void
  {
    $name = $request->input('customer_name');
    $phone = $request->input('customer_phone');
    $nameStr = is_string($name) ? trim($name) : '';
    $phoneStr = is_string($phone) ? trim($phone) : (is_int($phone) || is_float($phone) ? (string) $phone : '');
    if ($nameStr === '' || $phoneStr === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'storefront.validation_failed', 422);
      return;
    }
    $data = $request->all();
    $data['customer_name'] = $nameStr;
    $data['customer_phone'] = $phoneStr;
    $order = $this->storefront->createOrder($data);
    $this->response->success($request, ['order' => $order], 'STOREFRONT_ORDER_CREATED', 'storefront.order_created', 201);
  }

  public function listOrders(Request $request, Container $container): void
  {
    $status = $request->query('status');
    $items = $this->storefront->listOrders(is_string($status) ? $status : null);
    $this->response->success($request, ['orders' => $items], 'STOREFRONT_ORDERS_LIST', 'storefront.orders');
  }

  public function convert(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $order = $this->storefront->findOrder($id);
    if ($order === null) {
      $this->response->error($request, 'NOT_FOUND', 'storefront.not_found', 404);
      return;
    }
    $userId = (int) $container->get('auth.user_id');
    $draft = $this->sales->createDraft(['notes' => 'Storefront order #' . $id], $userId);
    $converted = $this->storefront->convertToSalesOrder($id, (int) $draft['id']);
    $this->audit->log($userId, 'storefront.convert', 'storefront_order', $id, null);
    $this->response->success($request, ['order' => $converted, 'sales_order' => $draft], 'STOREFRONT_CONVERTED', 'storefront.converted');
  }
}
