<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\DeliveryRepository;

final class DeliveryController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly DeliveryRepository $delivery,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $status = $request->query('status');
    $orderId = $request->query('sales_order_id');
    $items = $this->delivery->list(
      is_string($status) ? $status : null,
      $orderId !== null ? (int) $orderId : null,
    );
    $this->response->success($request, ['delivery_tasks' => $items], 'DELIVERY_TASKS', 'delivery.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->delivery->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'delivery.not_found', 404);
      return;
    }
    $this->response->success($request, ['delivery_task' => $item], 'DELIVERY_TASK', 'delivery.detail');
  }

  public function update(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->delivery->update($id, $request->all());
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'delivery.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'delivery.update', 'delivery_task', $id, json_encode(['status' => $item['status']]));
    $this->response->success($request, ['task' => $item, 'delivery_task' => $item], 'DELIVERY_UPDATED', 'delivery.updated');
  }

  public function complete(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->delivery->update($id, [
      'status' => 'completed',
      'notes' => $request->input('notes'),
    ]);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'delivery.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'delivery.complete', 'delivery_task', $id, null);
    $this->response->success($request, ['task' => $item, 'delivery_task' => $item], 'DELIVERY_TASK_COMPLETED', 'delivery.completed');
  }

  public function store(Request $request, Container $container): void
  {
    $orderId = (int) ($request->input('sales_order_id') ?? 0);
    if ($orderId <= 0) {
      $this->response->error($request, 'VALIDATION_ERROR', 'delivery.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $task = $this->delivery->create($orderId, $request->all(), $userId);
    if ($task === null) {
      $this->response->error($request, 'NOT_FOUND', 'delivery.order_not_found', 404);
      return;
    }

    $this->audit->log($userId, 'delivery.create', 'delivery_task', (int) $task['id'], null);
    $this->response->success($request, ['task' => $task, 'delivery_task' => $task], 'DELIVERY_TASK_SCHEDULED', 'delivery.scheduled', 201);
  }
}
