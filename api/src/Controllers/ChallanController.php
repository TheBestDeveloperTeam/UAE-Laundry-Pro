<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\ChallanRepository;

final class ChallanController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly ChallanRepository $challans,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $type = $request->query('challan_type');
    $items = $this->challans->list(is_string($type) ? $type : null);
    $this->response->success($request, ['challans' => $items], 'CHALLANS_LIST', 'challans.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->challans->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'challans.not_found', 404);
      return;
    }
    $this->response->success($request, ['challan' => $item], 'CHALLAN_DETAIL', 'challans.detail');
  }

  public function store(Request $request, Container $container): void
  {
    $type = $request->input('challan_type');
    if (!is_string($type) || trim($type) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'challans.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->challans->create($request->all(), $userId);
    $this->audit->log($userId, 'challans.create', 'challan', (int) $item['id'], json_encode(['challan_no' => $item['challan_no']]));
    $this->response->success($request, ['challan' => $item], 'CHALLAN_CREATED', 'challans.created', 201);
  }

  public function update(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->challans->update($id, $request->all());
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'challans.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'challans.update', 'challan', $id, null);
    $this->response->success($request, ['challan' => $item], 'CHALLAN_UPDATED', 'challans.updated');
  }

  public function cancel(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->challans->cancel($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'challans.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'challans.cancel', 'challan', $id, null);
    $this->response->success($request, ['challan' => $item], 'CHALLAN_CANCELLED', 'challans.cancelled');
  }
}
