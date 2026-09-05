<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\ExpenseRepository;

final class ExpenseController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly ExpenseRepository $expenses,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function listCategories(Request $request, Container $container): void
  {
    $items = $this->expenses->listCategories();
    $this->response->success($request, ['categories' => $items], 'EXPENSE_CATEGORIES_LIST', 'expenses.categories');
  }

  public function storeCategory(Request $request, Container $container): void
  {
    $name = $request->input('name');
    if (!is_string($name) || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'expenses.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->expenses->createCategory($request->all());
    $this->audit->log($userId, 'expenses.category.create', 'expense_category', (int) $item['id'], null);
    $this->response->success($request, ['category' => $item], 'EXPENSE_CATEGORY_CREATED', 'expenses.category_created', 201);
  }

  public function index(Request $request, Container $container): void
  {
    $status = $request->query('status');
    $from = $request->query('from');
    $to = $request->query('to');
    $items = $this->expenses->list(
      is_string($status) ? $status : null,
      is_string($from) ? $from : null,
      is_string($to) ? $to : null,
    );
    $this->response->success($request, ['expenses' => $items], 'EXPENSES_LIST', 'expenses.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->expenses->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'expenses.not_found', 404);
      return;
    }
    $this->response->success($request, ['expense' => $item], 'EXPENSE_DETAIL', 'expenses.detail');
  }

  public function store(Request $request, Container $container): void
  {
    $amount = (float) ($request->input('amount') ?? 0);
    $categoryId = (int) ($request->input('category_id') ?? 0);
    if ($amount <= 0 || $categoryId <= 0) {
      $this->response->error($request, 'VALIDATION_ERROR', 'expenses.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->expenses->create($request->all(), $userId);
    $this->audit->log($userId, 'expenses.create', 'expense', (int) $item['id'], null);
    $this->response->success($request, ['expense' => $item], 'EXPENSE_CREATED', 'expenses.created', 201);
  }

  public function approve(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $item = $this->expenses->approve($id, $userId);
    if ($item === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'expenses.approve_failed', 422);
      return;
    }
    $this->audit->log($userId, 'expenses.approve', 'expense', $id, null);
    $this->response->success($request, ['expense' => $item], 'EXPENSE_APPROVED', 'expenses.approved');
  }

  public function reject(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $item = $this->expenses->reject($id, $userId);
    if ($item === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'expenses.reject_failed', 422);
      return;
    }
    $this->audit->log($userId, 'expenses.reject', 'expense', $id, null);
    $this->response->success($request, ['expense' => $item], 'EXPENSE_REJECTED', 'expenses.rejected');
  }
}
