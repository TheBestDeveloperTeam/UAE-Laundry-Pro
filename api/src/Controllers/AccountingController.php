<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AccountingRepository;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Services\AccountingExportService;

final class AccountingController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly AccountingRepository $accounting,
    private readonly AccountingExportService $exportService,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $items = $this->accounting->listBatches();
    $this->response->success($request, ['batches' => $items], 'ACCOUNTING_BATCHES_LIST', 'accounting.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $batch = $this->accounting->findBatch($id);
    if ($batch === null) {
      $this->response->error($request, 'NOT_FOUND', 'accounting.not_found', 404);
      return;
    }
    $lines = $this->accounting->batchLines($id);
    $this->response->success($request, ['batch' => $batch, 'lines' => $lines], 'ACCOUNTING_BATCH_DETAIL', 'accounting.detail');
  }

  public function export(Request $request, Container $container): void
  {
    $start = $request->input('period_start');
    $end = $request->input('period_end');
    if (!is_string($start) || !is_string($end)) {
      $this->response->error($request, 'VALIDATION_ERROR', 'accounting.period_required', 422);
      return;
    }
    $userId = (int) $container->get('auth.user_id');
    $result = $this->exportService->createExport($request->all(), $userId);
    $this->audit->log($userId, 'accounting.export', 'accounting_batch', (int) $result['batch']['id'], null);
    $this->response->success($request, $result, 'ACCOUNTING_EXPORT_CREATED', 'accounting.exported', 201);
  }
}
