<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\CustomerRepository;
use LaundryPro\Api\Services\SyncService;

final class CustomerController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly CustomerRepository $customers,
    private readonly AuditLogRepository $audit,
    private readonly SyncService $sync,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $search = $request->query('q');
    $items = $this->customers->list(is_string($search) ? $search : null);
    $this->response->success($request, ['customers' => $items], 'CUSTOMERS_LIST', 'customers.list_success');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->customers->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'customers.not_found', 404);
      return;
    }
    $this->response->success($request, ['customer' => $item], 'CUSTOMER_DETAIL', 'customers.detail_success');
  }

  public function store(Request $request, Container $container): void
  {
    $name = $request->input('name');
    if (!is_string($name) || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'customers.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->customers->create($request->all());
    $this->sync->enqueue('customer', (int) $item['local_id'], 'create', $item);
    $this->audit->log($userId, 'customers.create', 'customer', (int) $item['id'], json_encode(['name' => $name]));
    $this->response->success($request, ['customer' => $item], 'CUSTOMER_CREATED', 'customers.created', 201);
  }

  public function update(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->customers->update($id, $request->all());
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'customers.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->sync->enqueue('customer', (int) $item['local_id'], 'update', $item);
    $this->audit->log($userId, 'customers.update', 'customer', $id, null);
    $this->response->success($request, ['customer' => $item], 'CUSTOMER_UPDATED', 'customers.updated');
  }
}
