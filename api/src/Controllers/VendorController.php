<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\VendorRepository;
use LaundryPro\Api\Services\SyncService;

final class VendorController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly VendorRepository $vendors,
    private readonly AuditLogRepository $audit,
    private readonly SyncService $sync,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $search = $request->query('q');
    $items = $this->vendors->list(is_string($search) ? $search : null);
    $this->response->success($request, ['vendors' => $items], 'VENDORS_LIST', 'vendors.list_success');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->vendors->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'vendors.not_found', 404);
      return;
    }
    $this->response->success($request, ['vendor' => $item], 'VENDOR_DETAIL', 'vendors.detail_success');
  }

  public function store(Request $request, Container $container): void
  {
    $name = $request->input('name');
    if (!is_string($name) || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'vendors.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->vendors->create($request->all());
    $this->sync->enqueue('vendor', (int) $item['local_id'], 'create', $item);
    $this->audit->log($userId, 'vendors.create', 'vendor', (int) $item['id'], json_encode(['name' => $name]));
    $this->response->success($request, ['vendor' => $item], 'VENDOR_CREATED', 'vendors.created', 201);
  }

  public function update(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->vendors->update($id, $request->all());
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'vendors.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->sync->enqueue('vendor', (int) $item['local_id'], 'update', $item);
    $this->audit->log($userId, 'vendors.update', 'vendor', $id, null);
    $this->response->success($request, ['vendor' => $item], 'VENDOR_UPDATED', 'vendors.updated');
  }
}
