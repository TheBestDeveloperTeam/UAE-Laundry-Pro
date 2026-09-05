<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\PurchaseRepository;

final class PurchaseController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly PurchaseRepository $purchases,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $status = $request->query('status');
    $items = $this->purchases->list(is_string($status) ? $status : null);
    $this->response->success($request, ['purchase_orders' => $items], 'PURCHASE_ORDERS', 'purchasing.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->purchases->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'purchasing.not_found', 404);
      return;
    }
    $this->response->success($request, ['purchase_order' => $item], 'PURCHASE_ORDER', 'purchasing.detail');
  }

  public function store(Request $request, Container $container): void
  {
    $vendorId = (int) ($request->input('vendor_id') ?? 0);
    if ($vendorId <= 0) {
      $this->response->error($request, 'VALIDATION_ERROR', 'purchasing.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->purchases->create($request->all(), $userId);
    $this->audit->log($userId, 'purchasing.create', 'purchase_order', (int) $item['id'], json_encode(['po_no' => $item['po_no']]));
    $this->response->success($request, ['purchase_order' => $item], 'PURCHASE_ORDER_CREATED', 'purchasing.created', 201);
  }

  public function update(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->purchases->update($id, $request->all());
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'purchasing.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'purchasing.update', 'purchase_order', $id, null);
    $this->response->success($request, ['purchase_order' => $item], 'PURCHASE_ORDER_UPDATED', 'purchasing.updated');
  }

  public function receive(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $result = $this->purchases->receive($id, $request->all(), $userId);
    if ($result === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'purchasing.receive_failed', 422);
      return;
    }

    $this->audit->log($userId, 'purchasing.receive', 'purchase_order', $id, json_encode(['receipt_no' => $result['receipt_no']]));
    $this->response->success($request, $result, 'PURCHASE_ORDER_RECEIVED', 'purchasing.received');
  }
}
