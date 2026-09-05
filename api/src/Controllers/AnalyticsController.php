<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AnalyticsRepository;

final class AnalyticsController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly AnalyticsRepository $analytics,
  ) {
  }

  public function summary(Request $request, Container $container): void
  {
    $branchId = $request->query('branch_id');
    $metrics = $this->analytics->computeTodayMetrics(is_numeric($branchId) ? (int) $branchId : null);
    $this->response->success($request, ['summary' => $metrics], 'ANALYTICS_SUMMARY', 'analytics.summary');
  }

  public function trends(Request $request, Container $container): void
  {
    $metric = (string) ($request->query('metric') ?? 'sales_total');
    $from = (string) ($request->query('from') ?? date('Y-m-d', strtotime('-30 days')));
    $to = (string) ($request->query('to') ?? date('Y-m-d'));
    $branchId = $request->query('branch_id');
    $series = $this->analytics->trends($metric, $from, $to, is_numeric($branchId) ? (int) $branchId : null);
    $this->response->success($request, ['metric' => $metric, 'series' => $series], 'ANALYTICS_TRENDS', 'analytics.trends');
  }

  public function refresh(Request $request, Container $container): void
  {
    $today = date('Y-m-d');
    $metrics = $this->analytics->computeTodayMetrics();
    foreach ($metrics as $key => $value) {
      $this->analytics->upsertSnapshot($today, $key, (float) $value);
    }
    $this->response->success($request, ['refreshed' => $metrics], 'ANALYTICS_REFRESHED', 'analytics.refreshed');
  }
}
