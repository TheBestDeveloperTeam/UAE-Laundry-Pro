<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Money;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class HrRepository
{
    public function __construct(
        private readonly PDO $db
    ) {
    }

    /**
     * Create Employee
     */
    public function createEmployee(int $adminId, array $data): int
    {
        try {
            $this->db->beginTransaction();

            $sql = "INSERT INTO employees (uuid, admin_id, row_uuid, first_name, last_name, email, phone, dob, id_passport_number, visa_status, photo_url, role_id, branch_id, base_salary, status)
                    VALUES (:uuid, :admin_id, :row_uuid, :first_name, :last_name, :email, :phone, :dob, :id_passport_number, :visa_status, :photo_url, :role_id, :branch_id, :base_salary, :status)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => Uuid::v4(),
                'admin_id' => $adminId,
                'row_uuid' => Uuid::v4(),
                'first_name' => $data['first_name'],
                'last_name' => $data['last_name'],
                'email' => $data['email'] ?? null,
                'phone' => $data['phone'] ?? null,
                'dob' => $data['dob'] ?? null,
                'id_passport_number' => $data['id_passport_number'] ?? null,
                'visa_status' => $data['visa_status'] ?? null,
                'photo_url' => $data['photo_url'] ?? null,
                'role_id' => $data['role_id'],
                'branch_id' => $data['branch_id'] ?? null,
                'base_salary' => (new Money((string)($data['base_salary'] ?? '0.00')))->getAmount(),
                'status' => $data['status'] ?? 'active',
            ]);

            $employeeId = (int) $this->db->lastInsertId();
            $this->db->commit();

            return $employeeId;
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Employee creation failed: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Clock in
     */
    public function clockIn(int $adminId, int $employeeId, array $data): int
    {
        $stmt = $this->db->prepare("SELECT id FROM attendance WHERE employee_id = ? AND admin_id = ? AND clock_out_time IS NULL LIMIT 1");
        $stmt->execute([$employeeId, $adminId]);
        if ($stmt->fetchColumn()) {
            throw new InvalidArgumentException("Employee is already clocked in");
        }

        $sql = "INSERT INTO attendance (uuid, admin_id, row_uuid, employee_id, branch_id, clock_in_time, clock_in_photo_url, latitude, longitude, status)
                VALUES (:uuid, :admin_id, :row_uuid, :employee_id, :branch_id, NOW(), :photo_url, :latitude, :longitude, :status)";
        
        $insert = $this->db->prepare($sql);
        $insert->execute([
            'uuid' => Uuid::v4(),
            'admin_id' => $adminId,
            'row_uuid' => Uuid::v4(),
            'employee_id' => $employeeId,
            'branch_id' => $data['branch_id'] ?? null,
            'photo_url' => $data['photo_url'] ?? null,
            'latitude' => $data['latitude'] ?? null,
            'longitude' => $data['longitude'] ?? null,
            'status' => $data['status'] ?? 'present',
        ]);

        return (int) $this->db->lastInsertId();
    }

    /**
     * Clock out
     */
    public function clockOut(int $adminId, int $employeeId, array $data): void
    {
        $stmt = $this->db->prepare("SELECT id FROM attendance WHERE employee_id = ? AND admin_id = ? AND clock_out_time IS NULL ORDER BY id DESC LIMIT 1");
        $stmt->execute([$employeeId, $adminId]);
        $attendanceId = $stmt->fetchColumn();

        if (!$attendanceId) {
            throw new InvalidArgumentException("No active clock-in found for this employee");
        }

        $sql = "UPDATE attendance SET clock_out_time = NOW(), clock_out_photo_url = :photo_url WHERE id = :id";
        $upd = $this->db->prepare($sql);
        $upd->execute([
            'photo_url' => $data['photo_url'] ?? null,
            'id' => $attendanceId
        ]);
    }

    /**
     * Generate Payroll Record
     */
    public function generatePayroll(int $adminId, array $data): int
    {
        try {
            $this->db->beginTransaction();

            $base = new Money((string)$data['base_salary']);
            $allowances = new Money((string)($data['allowances'] ?? '0.00'));
            $deductions = new Money((string)($data['deductions'] ?? '0.00'));
            
            $netPay = $base->add($allowances)->subtract($deductions);

            $sql = "INSERT INTO payroll_records (uuid, admin_id, row_uuid, employee_id, period_start, period_end, base_salary, allowances, deductions, net_pay, status, notes)
                    VALUES (:uuid, :admin_id, :row_uuid, :employee_id, :period_start, :period_end, :base_salary, :allowances, :deductions, :net_pay, :status, :notes)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => Uuid::v4(),
                'admin_id' => $adminId,
                'row_uuid' => Uuid::v4(),
                'employee_id' => $data['employee_id'],
                'period_start' => $data['period_start'],
                'period_end' => $data['period_end'],
                'base_salary' => $base->getAmount(),
                'allowances' => $allowances->getAmount(),
                'deductions' => $deductions->getAmount(),
                'net_pay' => $netPay->getAmount(),
                'status' => 'draft',
                'notes' => $data['notes'] ?? null,
            ]);

            $payrollId = (int) $this->db->lastInsertId();
            $this->db->commit();

            return $payrollId;
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Payroll generation failed: " . $e->getMessage(), 0, $e);
        }
    }
}
