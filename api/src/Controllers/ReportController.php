<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Repositories\ReportRepository;

class ReportController
{
    public function __construct(private readonly ReportRepository $repository)
    {
    }

    public function getSalesSummary(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized tenant access');
            return;
        }

        $branchId = isset($_GET['branch_id']) ? (int)$_GET['branch_id'] : null;
        $dateFrom = $_GET['date_from'] ?? date('Y-m-01 00:00:00');
        $dateTo = $_GET['date_to'] ?? date('Y-m-t 23:59:59');

        try {
            $data = $this->repository->getSalesSummary((int)$adminId, $branchId, $dateFrom, $dateTo);
            $response->success($data, 'Sales summary retrieved');
        } catch (\Exception $e) {
            $response->error(500, 'Server Error', [$e->getMessage()]);
        }
    }

    public function getPaymentBreakdown(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized');
            return;
        }

        $branchId = isset($_GET['branch_id']) ? (int)$_GET['branch_id'] : null;
        $dateFrom = $_GET['date_from'] ?? date('Y-m-01 00:00:00');
        $dateTo = $_GET['date_to'] ?? date('Y-m-t 23:59:59');

        try {
            $data = $this->repository->getPaymentBreakdown((int)$adminId, $branchId, $dateFrom, $dateTo);
            $response->success($data, 'Payment breakdown retrieved');
        } catch (\Exception $e) {
            $response->error(500, 'Server Error', [$e->getMessage()]);
        }
    }

    public function getArAging(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized');
            return;
        }

        try {
            $data = $this->repository->getArAging((int)$adminId);
            $response->success($data, 'AR Aging retrieved');
        } catch (\Exception $e) {
            $response->error(500, 'Server Error', [$e->getMessage()]);
        }
    }

    public function getPnL(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized');
            return;
        }

        $branchId = isset($_GET['branch_id']) ? (int)$_GET['branch_id'] : null;
        $dateFrom = $_GET['date_from'] ?? date('Y-m-01 00:00:00');
        $dateTo = $_GET['date_to'] ?? date('Y-m-t 23:59:59');

        try {
            $data = $this->repository->getPnL((int)$adminId, $branchId, $dateFrom, $dateTo);
            $response->success($data, 'P&L retrieved');
        } catch (\Exception $e) {
            $response->error(500, 'Server Error', [$e->getMessage()]);
        }
    }
}
