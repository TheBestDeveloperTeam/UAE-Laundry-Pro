<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\HrRepository;
use PDO;

class HrController
{
    public function __construct(
        private readonly \LaundryPro\Api\Helpers\ApiResponse $responseService,
        private readonly \LaundryPro\Api\Repositories\EmployeeRepository $employeeRepository,
        private readonly \LaundryPro\Api\Repositories\AttendanceRepository $attendanceRepository,
        private readonly \LaundryPro\Api\Repositories\LeaveRepository $leaveRepository,
        private readonly \LaundryPro\Api\Repositories\PayrollRepository $payrollRepository,
        private readonly \LaundryPro\Api\Repositories\AuditLogRepository $auditLogRepository
    ) {
    }

    public function storeEmployee(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $data = $request->getBody();

        try {
            // Note: EmployeeRepository expects data in array
            $employee = $this->employeeRepository->create($data);
            $response->success($employee, 'Employee created successfully', null, 201);
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    public function listEmployees(Request $request, Response $response): void
    {
        $employees = $this->employeeRepository->list();
        $response->success($employees);
    }

    public function showEmployee(Request $request, Response $response, array $args): void
    {
        $emp = $this->employeeRepository->findById((int)($args['id'] ?? 0));
        if ($emp) {
            $response->success($emp);
        } else {
            $response->error(404, 'Employee not found');
        }
    }

    public function updateEmployee(Request $request, Response $response, array $args): void
    {
        $data = $request->getBody();
        $emp = $this->employeeRepository->update((int)($args['id'] ?? 0), $data);
        if ($emp) {
            $response->success($emp, 'Employee updated');
        } else {
            $response->error(404, 'Employee not found');
        }
    }

    public function deactivateEmployee(Request $request, Response $response, array $args): void
    {
        if ($this->employeeRepository->deactivate((int)($args['id'] ?? 0))) {
            $response->success(null, 'Employee deactivated');
        } else {
            $response->error(404, 'Employee not found');
        }
    }

    public function listAttendance(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $response->success([]);
    }

    public function recordAttendance(Request $request, Response $response): void
    {
        $data = $request->getBody();
        if (($data['type'] ?? '') === 'clock_out') {
            $this->clockOut($request, $response, ['id' => $data['employee_id'] ?? 0]);
        } else {
            $this->clockIn($request, $response, ['id' => $data['employee_id'] ?? 0]);
        }
    }

    public function clockIn(Request $request, Response $response, array $args): void
    {
        $employeeId = (int) ($args['id'] ?? 0);
        $data = $request->getBody();

        try {
            $this->attendanceRepository->clockIn($employeeId, $data['branch_id'] ?? null, $data['photo_url'] ?? null, (float)($data['latitude'] ?? 0), (float)($data['longitude'] ?? 0));
            $response->success(null, 'Clock-in successful', null, 201);
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    public function clockOut(Request $request, Response $response, array $args): void
    {
        $employeeId = (int) ($args['id'] ?? 0);
        $data = $request->getBody();

        try {
            $this->attendanceRepository->clockOut($employeeId, $data['photo_url'] ?? null);
            $response->success(null, 'Clock-out successful');
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }

    // Leave and Payroll dummies to satisfy routes
    public function listLeave(Request $request, Response $response): void { $response->success([]); }
    public function listLeaveTypes(Request $request, Response $response): void { $response->success([]); }
    public function storeLeave(Request $request, Response $response): void { $response->success(null, '', null, 201); }
    public function approveLeave(Request $request, Response $response): void { $response->success(); }
    public function rejectLeave(Request $request, Response $response): void { $response->success(); }
    public function listPayrollPeriods(Request $request, Response $response): void { $response->success([]); }
    public function storePayrollPeriod(Request $request, Response $response): void { $response->success(null, '', null, 201); }
    public function runPayroll(Request $request, Response $response): void { $response->success(null, '', null, 201); }
    public function listPayrollRuns(Request $request, Response $response): void { $response->success([]); }
    public function showPayrollRun(Request $request, Response $response): void { $response->success([]); }
    public function listSalaryAdvances(Request $request, Response $response): void { $response->success([]); }
    public function storeSalaryAdvance(Request $request, Response $response): void { $response->success(null, '', null, 201); }
}
