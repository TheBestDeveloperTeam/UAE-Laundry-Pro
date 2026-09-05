<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\BranchRepository;

final class BranchController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly BranchRepository $branches,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $items = $this->branches->list();
    $this->response->success($request, ['branches' => $items], 'BRANCHES_LIST', 'branches.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->branches->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'branches.not_found', 404);
      return;
    }
    $this->response->success($request, ['branch' => $item], 'BRANCH_DETAIL', 'branches.detail');
  }

  public function store(Request $request, Container $container): void
  {
    $code = $request->input('code');
    $name = $request->input('name');
    if (!is_string($code) || !is_string($name) || trim($code) === '' || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'branches.validation_failed', 422);
      return;
    }
    $userId = (int) $container->get('auth.user_id');
    $item = $this->branches->create($request->all());
    $this->audit->log($userId, 'branches.create', 'branch', (int) $item['id'], null);
    $this->response->success($request, ['branch' => $item], 'BRANCH_CREATED', 'branches.created', 201);
  }

  public function update(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->branches->update($id, $request->all());
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'branches.not_found', 404);
      return;
    }
    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'branches.update', 'branch', $id, null);
    $this->response->success($request, ['branch' => $item], 'BRANCH_UPDATED', 'branches.updated');
  }
}
