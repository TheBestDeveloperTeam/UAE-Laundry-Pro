<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\DeliveryRepository;
use LaundryPro\Api\Repositories\ExpenseRepository;
use LaundryPro\Api\Repositories\InventoryRepository;
use LaundryPro\Api\Repositories\PayrollRepository;
use LaundryPro\Api\Repositories\PurchaseRepository;
use LaundryPro\Api\Repositories\SalesRepository;

final class ReportsController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly SalesRepository $sales,
    private readonly ExpenseRepository $expenses,
    private readonly PayrollRepository $payroll,
    private readonly InventoryRepository $inventory,
    private readonly DeliveryRepository $delivery,
    private readonly PurchaseRepository $purchasing,
  ) {
  }

  public function salesSummary(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-d');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');

    $summary = $this->sales->summary($fromStr, $toStr);
    $this->response->success($request, [
      'summary' => $summary,
      'from' => $fromStr,
      'to' => $toStr,
    ], 'SALES_SUMMARY', 'reports.sales_summary_success');
  }

  public function expensesSummary(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');

    $summary = $this->expenses->summary($fromStr, $toStr);
    $this->response->success($request, [
      'summary' => $summary,
      'from' => $fromStr,
      'to' => $toStr,
    ], 'EXPENSES_SUMMARY', 'reports.expenses_summary');
  }

  public function payrollSummary(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');

    $summary = $this->payroll->summary($fromStr, $toStr);
    $this->response->success($request, [
      'summary' => $summary,
      'from' => $fromStr,
      'to' => $toStr,
    ], 'PAYROLL_SUMMARY', 'reports.payroll_summary');
  }

  public function inventoryValuation(Request $request, Container $container): void
  {
    $valuation = $this->inventory->valuation();
    $this->response->success($request, ['valuation' => $valuation], 'INVENTORY_VALUATION', 'reports.inventory_valuation');
  }

  public function productionThroughput(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');

    $throughput = $this->sales->productionThroughput($fromStr, $toStr);
    $this->response->success($request, [
      'throughput' => $throughput,
      'from' => $fromStr,
      'to' => $toStr,
    ], 'PRODUCTION_THROUGHPUT', 'reports.production_throughput');
  }

  public function inventoryReport(Request $request, Container $container): void
  {
    $valuation = $this->inventory->valuation();
    $this->response->success($request, ['report' => $valuation, 'valuation' => $valuation], 'INVENTORY_REPORT', 'reports.inventory');
  }

  public function payrollReport(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');
    $summary = $this->payroll->summary($fromStr, $toStr);
    $this->response->success($request, ['report' => $summary, 'summary' => $summary, 'from' => $fromStr, 'to' => $toStr], 'PAYROLL_REPORT', 'reports.payroll');
  }

  public function expensesReport(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');
    $summary = $this->expenses->summary($fromStr, $toStr);
    $this->response->success($request, ['report' => $summary, 'summary' => $summary, 'from' => $fromStr, 'to' => $toStr], 'EXPENSE_REPORT', 'reports.expenses');
  }

  public function productionReport(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');
    $throughput = $this->sales->productionThroughput($fromStr, $toStr);
    $this->response->success($request, ['report' => $throughput, 'throughput' => $throughput, 'from' => $fromStr, 'to' => $toStr], 'PRODUCTION_REPORT', 'reports.production');
  }

  public function purchasingReport(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');
    $orders = $this->purchasing->list();
    $this->response->success($request, [
      'report' => ['purchase_orders' => $orders, 'order_count' => count($orders)],
      'from' => $fromStr,
      'to' => $toStr,
    ], 'PURCHASING_REPORT', 'reports.purchasing');
  }

  public function deliveryReport(Request $request, Container $container): void
  {
    $from = $request->query('from');
    $to = $request->query('to');
    $fromStr = is_string($from) && $from !== '' ? $from : gmdate('Y-m-01');
    $toStr = is_string($to) && $to !== '' ? $to : gmdate('Y-m-d');
    $tasks = $this->delivery->list();
    $this->response->success($request, [
      'report' => ['delivery_tasks' => $tasks, 'task_count' => count($tasks)],
      'from' => $fromStr,
      'to' => $toStr,
    ], 'DELIVERY_REPORT', 'reports.delivery');
  }
}
