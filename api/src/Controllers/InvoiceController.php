<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\InvoiceRepository;
use LaundryPro\Api\Repositories\AuditLogRepository;

final class InvoiceController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly InvoiceRepository $invoices,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $items = $this->invoices->list();
    $this->response->success($request, ['invoices' => $items], 'INVOICES_LIST', 'invoices.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $invoice = $this->invoices->findById($id);
    if ($invoice === null) {
      $this->response->error($request, 'NOT_FOUND', 'invoices.not_found', 404);
      return;
    }
    $this->response->success($request, ['invoice' => $invoice], 'INVOICE_DETAIL', 'invoices.detail');
  }

  public function post(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $invoice = $this->invoices->post($id, $userId);
    if ($invoice === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'invoices.post_failed', 422);
      return;
    }

    $this->audit->log($userId, 'invoices.post', 'invoice', $id, null);
    $this->response->success($request, ['invoice' => $invoice], 'INVOICE_POSTED', 'invoices.posted');
  }

  public function correction(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    
    try {
        $correction = $this->invoices->createCorrection($id, $request->all(), $userId);
    } catch (\RuntimeException $e) {
        $this->response->error($request, 'VALIDATION_ERROR', $e->getMessage(), 422);
        return;
    }

    $this->audit->log($userId, 'invoices.correction', 'invoice', (int)$correction['id'], null);
    $this->response->success($request, ['invoice' => $correction], 'INVOICE_CORRECTION_CREATED', 'invoices.correction_created', 201);
  }
}
