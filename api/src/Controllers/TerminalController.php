<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\BranchRepository;
use LaundryPro\Api\Repositories\TerminalRepository;

final class TerminalController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly TerminalRepository $terminals,
    private readonly BranchRepository $branches,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $branchId = $request->query('branch_id');
    $items = $this->terminals->list(is_numeric($branchId) ? (int) $branchId : null);
    $this->response->success($request, ['terminals' => $items], 'TERMINALS_LIST', 'terminals.list');
  }

  public function store(Request $request, Container $container): void
  {
    $branchId = (int) ($request->input('branch_id') ?? 0);
    $code = $request->input('code');
    $name = $request->input('name');
    if ($branchId <= 0 || $this->branches->findById($branchId) === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'terminals.invalid_branch', 422);
      return;
    }
    if (!is_string($code) || !is_string($name) || trim($code) === '' || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'terminals.validation_failed', 422);
      return;
    }
    $userId = (int) $container->get('auth.user_id');
    $item = $this->terminals->create($request->all());
    $this->audit->log($userId, 'terminals.create', 'terminal', (int) $item['id'], null);
    $this->response->success($request, ['terminal' => $item], 'TERMINAL_CREATED', 'terminals.created', 201);
  }

  public function register(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $terminal = $this->terminals->findById($id);
    if ($terminal === null) {
      $this->response->error($request, 'NOT_FOUND', 'terminals.not_found', 404);
      return;
    }
    if ($this->terminals->activeSessionCount($id) >= 3) {
      $this->response->error($request, 'TERMINAL_LIMIT', 'terminals.device_limit', 409);
      return;
    }
    $session = $this->terminals->registerSession($id, $request->all());
    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'terminals.register', 'terminal', $id, null);
    $this->response->success($request, ['session' => $session], 'TERMINAL_REGISTERED', 'terminals.registered', 201);
  }
}
