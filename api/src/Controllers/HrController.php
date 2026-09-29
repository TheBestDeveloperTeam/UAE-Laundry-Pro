<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AttendanceRepository;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\EmployeeRepository;
use LaundryPro\Api\Repositories\LeaveRepository;
use LaundryPro\Api\Repositories\PayrollRepository;

final class HrController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly EmployeeRepository $employees,
    private readonly AttendanceRepository $attendance,
    private readonly LeaveRepository $leave,
    private readonly PayrollRepository $payroll,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function listEmployees(Request $request, Container $container): void
  {
    $search = $request->query('q');
    $items = $this->employees->list(is_string($search) ? $search : null);
    $this->response->success($request, ['employees' => $items], 'EMPLOYEES_LIST', 'hr.employees_list');
  }

  public function showEmployee(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->employees->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'hr.employee_not_found', 404);
      return;
    }
    $this->response->success($request, ['employee' => $item], 'EMPLOYEE_DETAIL', 'hr.employee_detail');
  }

  public function storeEmployee(Request $request, Container $container): void
  {
    $name = $request->input('full_name');
    if (!is_string($name) || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->employees->create($request->all());
    $this->audit->log($userId, 'hr.employee.create', 'employee', (int) $item['id'], json_encode(['name' => $name]));
    $this->response->success($request, ['employee' => $item], 'EMPLOYEE_CREATED', 'hr.employee_created', 201);
  }

  public function updateEmployee(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->employees->update($id, $request->all());
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'hr.employee_not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'hr.employee.update', 'employee', $id, null);
    $this->response->success($request, ['employee' => $item], 'EMPLOYEE_UPDATED', 'hr.employee_updated');
  }

  public function deactivateEmployee(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    if (!$this->employees->deactivate($id)) {
      $this->response->error($request, 'NOT_FOUND', 'hr.employee_not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'hr.employee.deactivate', 'employee', $id, null);
    $this->response->success($request, [], 'EMPLOYEE_DEACTIVATED', 'hr.employee_deactivated');
  }

  public function listAttendance(Request $request, Container $container): void
  {
    $employeeId = $request->query('employee_id');
    $from = $request->query('from');
    $to = $request->query('to');
    $items = $this->attendance->list(
      $employeeId !== null ? (int) $employeeId : null,
      is_string($from) ? $from : null,
      is_string($to) ? $to : null,
    );
    $this->response->success($request, ['attendance' => $items], 'ATTENDANCE_LIST', 'hr.attendance_list');
  }

  public function recordAttendance(Request $request, Container $container): void
  {
    $employeeId = (int) ($request->input('employee_id') ?? 0);
    if ($employeeId <= 0) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->attendance->record($request->all(), $userId);
    $this->audit->log($userId, 'hr.attendance.record', 'attendance', (int) $item['id'], null);
    $this->response->success($request, ['attendance' => $item], 'ATTENDANCE_RECORDED', 'hr.attendance_recorded', 201);
  }

  public function listLeave(Request $request, Container $container): void
  {
    $status = $request->query('status');
    $employeeId = $request->query('employee_id');
    $items = $this->leave->list(
      is_string($status) ? $status : null,
      $employeeId !== null ? (int) $employeeId : null,
    );
    $this->response->success($request, ['leave_requests' => $items], 'LEAVE_LIST', 'hr.leave_list');
  }

  public function listLeaveTypes(Request $request, Container $container): void
  {
    $items = $this->leave->listTypes();
    $this->response->success($request, ['leave_types' => $items], 'LEAVE_TYPES_LIST', 'hr.leave_types');
  }

  public function storeLeave(Request $request, Container $container): void
  {
    $start = $request->input('start_date');
    $end = $request->input('end_date');
    if (!is_string($start) || !is_string($end)) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->leave->create($request->all());
    $this->audit->log($userId, 'hr.leave.create', 'leave_request', (int) $item['id'], null);
    $this->response->success($request, ['leave_request' => $item], 'LEAVE_REQUEST_CREATED', 'hr.leave_created', 201);
  }

  public function approveLeave(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $item = $this->leave->approve($id, $userId);
    if ($item === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.leave_approve_failed', 422);
      return;
    }
    $this->audit->log($userId, 'hr.leave.approve', 'leave_request', $id, null);
    $this->response->success($request, ['leave_request' => $item], 'LEAVE_REQUEST_APPROVED', 'hr.leave_approved');
  }

  public function rejectLeave(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $item = $this->leave->reject($id, $userId);
    if ($item === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.leave_reject_failed', 422);
      return;
    }
    $this->audit->log($userId, 'hr.leave.reject', 'leave_request', $id, null);
    $this->response->success($request, ['leave_request' => $item], 'LEAVE_REJECTED', 'hr.leave_rejected');
  }

  public function listPayrollPeriods(Request $request, Container $container): void
  {
    $items = $this->payroll->listPeriods();
    $this->response->success($request, ['periods' => $items], 'PAYROLL_PERIODS', 'hr.payroll_periods');
  }

  public function storePayrollPeriod(Request $request, Container $container): void
  {
    $start = $request->input('period_start');
    $end = $request->input('period_end');
    if (!is_string($start) || !is_string($end)) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->payroll->createPeriod($request->all());
    $this->audit->log($userId, 'hr.payroll.period.create', 'payroll_period', (int) $item['id'], null);
    $this->response->success($request, ['period' => $item], 'PAYROLL_PERIOD_CREATED', 'hr.payroll_period_created', 201);
  }

  public function runPayroll(Request $request, Container $container): void
  {
    $periodId = (int) ($request->input('payroll_period_id') ?? $request->route('id', 0));
    $periodStart = $request->input('period_start');
    $periodEnd = $request->input('period_end');

    if ($periodId <= 0 && is_string($periodStart) && $periodStart !== '' && is_string($periodEnd) && $periodEnd !== '') {
      $period = $this->payroll->findOrCreatePeriod($periodStart, $periodEnd);
      $periodId = (int) $period['id'];
    }

    if ($periodId <= 0) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.validation_failed', 422);
      return;
    }

    $employeeIds = null;
    $rawEmployeeIds = $request->input('employee_ids');
    if (is_array($rawEmployeeIds) && $rawEmployeeIds !== []) {
      $employeeIds = array_map(static fn ($id): int => (int) $id, $rawEmployeeIds);
    }

    $userId = (int) $container->get('auth.user_id');
    $run = $this->payroll->run($periodId, $userId, $employeeIds);
    if ($run === null) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.payroll_run_failed', 422);
      return;
    }

    $this->audit->log($userId, 'hr.payroll.run', 'payroll_run', (int) $run['id'], null);
    $this->response->success($request, ['payroll_run' => $run], 'PAYROLL_RUN_CREATED', 'hr.payroll_run', 201);
  }

  public function listPayrollRuns(Request $request, Container $container): void
  {
    $items = $this->payroll->listRuns();
    foreach ($items as &$item) {
      $item['lines'] = $this->payroll->runLines((int) $item['id']);
    }
    unset($item);
    $this->response->success($request, ['payroll_runs' => $items], 'PAYROLL_RUNS', 'hr.payroll_runs');
  }

  public function showPayrollRun(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $run = $this->payroll->findRunById($id);
    if ($run === null) {
      $this->response->error($request, 'NOT_FOUND', 'hr.payroll_run_not_found', 404);
      return;
    }
    $run['lines'] = $this->payroll->runLines($id);
    $this->response->success($request, ['payroll_run' => $run], 'PAYROLL_RUN_DETAIL', 'hr.payroll_run_detail');
  }

  public function listSalaryAdvances(Request $request, Container $container): void
  {
    $employeeId = $request->query('employee_id');
    $items = $this->payroll->listSalaryAdvances($employeeId !== null ? (int) $employeeId : null);
    $this->response->success($request, ['salary_advances' => $items], 'SALARY_ADVANCES', 'hr.salary_advances');
  }

  public function storeSalaryAdvance(Request $request, Container $container): void
  {
    $amount = (float) ($request->input('amount') ?? 0);
    $employeeId = (int) ($request->input('employee_id') ?? 0);
    if ($amount <= 0 || $employeeId <= 0) {
      $this->response->error($request, 'VALIDATION_ERROR', 'hr.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $item = $this->payroll->createSalaryAdvance($request->all(), $userId);
    $this->audit->log($userId, 'hr.salary_advance.create', 'salary_advance', (int) $item['id'], null);
    $this->response->success($request, ['salary_advance' => $item, 'advance' => $item], 'SALARY_ADVANCE_CREATED', 'hr.salary_advance_created', 201);
  }
}
