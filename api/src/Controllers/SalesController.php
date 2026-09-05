<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\DeliveryRepository;
use LaundryPro\Api\Repositories\SalesRepository;
use LaundryPro\Api\Services\SyncService;

final class SalesController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly SalesRepository $sales,
    private readonly DeliveryRepository $delivery,
    private readonly AuditLogRepository $audit,
    private readonly SyncService $sync,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $paymentStatus = $request->query('payment_status');
    $status = $request->query('status');
    $limit = (int) ($request->query('limit') ?? 50);
    $offset = (int) ($request->query('offset') ?? 0);

    $orders = $this->sales->list(
      is_string($paymentStatus) ? $paymentStatus : null,
      is_string($status) ? $status : null,
      max(1, min($limit, 200)),
      max(0, $offset),
    );

    $this->response->success($request, ['orders' => $orders], 'SALES_LIST', 'sales.list_success');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $order = $this->sales->findById($id);
    if ($order === null) {
      $this->response->error($request, 'NOT_FOUND', 'sales.not_found', 404);
      return;
    }
    $this->response->success($request, ['order' => $order], 'SALE_DETAIL', 'sales.detail_success');
  }

  public function draft(Request $request, Container $container): void
  {
    $userId = (int) $container->get('auth.user_id');
    $order = $this->sales->createDraft($request->all(), $userId);
    $this->audit->log($userId, 'sales.draft', 'sales_order', (int) $order['id'], null);
    $this->response->success($request, ['order' => $order], 'SALE_DRAFT_CREATED', 'sales.draft_created', 201);
  }

  public function confirm(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    try {
      $order = $this->sales->confirm($id, $userId);
    } catch (\RuntimeException $e) {
      if ($e->getMessage() === 'INSUFFICIENT_STOCK') {
        $this->response->error($request, 'INSUFFICIENT_STOCK', 'sales.insufficient_stock', 422);
        return;
      }
      throw $e;
    }
    if ($order === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'sales.confirm_failed', 422);
      return;
    }

    $this->sync->enqueue('sales_order', (int) $order['local_id'], 'create', $order);
    $this->audit->log($userId, 'sales.confirm', 'sales_order', $id, null);
    $this->response->success($request, ['order' => $order], 'SALE_CONFIRMED', 'sales.confirmed');
  }

  public function updateStatus(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $status = $request->input('status');
    if (!is_string($status) || trim($status) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'sales.status_required', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $notes = $request->input('notes');
    $order = $this->sales->updateStatus(
      $id,
      trim($status),
      $userId,
      is_string($notes) ? $notes : null,
    );
    if ($order === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'sales.status_update_failed', 422);
      return;
    }

    $this->audit->log($userId, 'sales.status', 'sales_order', $id, json_encode(['status' => $status]));
    $this->response->success($request, ['order' => $order], 'SALE_STATUS_UPDATED', 'sales.status_updated');
  }

  public function payment(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $order = $this->sales->addPayment($id, $request->all(), $userId);
    if ($order === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'sales.payment_failed', 422);
      return;
    }

    $this->audit->log($userId, 'sales.payment', 'sales_order', $id, json_encode(['amount' => $request->input('amount')]));
    $this->response->success($request, ['order' => $order], 'SALE_PAYMENT_POSTED', 'sales.payment_posted');
  }

  public function statusHistory(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $order = $this->sales->findById($id);
    if ($order === null) {
      $this->response->error($request, 'NOT_FOUND', 'sales.not_found', 404);
      return;
    }

    $history = $this->sales->getStatusHistory($id);
    $this->response->success($request, ['history' => $history], 'SALE_STATUS_HISTORY', 'sales.status_history');
  }

  public function listDeliveryTasks(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $order = $this->sales->findById($id);
    if ($order === null) {
      $this->response->error($request, 'NOT_FOUND', 'sales.not_found', 404);
      return;
    }

    $tasks = $this->delivery->listForOrder($id);
    $this->response->success($request, ['delivery_tasks' => $tasks], 'SALE_DELIVERY_TASKS', 'sales.delivery_tasks');
  }

  public function storeDeliveryTask(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $task = $this->delivery->create($id, $request->all(), $userId);
    if ($task === null) {
      $this->response->error($request, 'NOT_FOUND', 'sales.not_found', 404);
      return;
    }

    $this->audit->log($userId, 'sales.delivery.create', 'delivery_task', (int) $task['id'], json_encode(['sales_order_id' => $id]));
    $this->response->success($request, ['delivery_task' => $task], 'DELIVERY_TASK_SCHEDULED', 'sales.delivery_created', 201);
  }
}
