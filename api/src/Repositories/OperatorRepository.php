<?php
declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

class OperatorRepository
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function getCertifications(): array
    {
        $stmt = $this->pdo->query('
            SELECT oc.*, e.full_name, e.employee_no 
            FROM operator_certifications oc
            JOIN employees e ON oc.employee_id = e.id
            ORDER BY oc.expires_at ASC
        ');
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function certify(int $empId, string $certName, string $issued, string $expires): int
    {
        $stmt = $this->pdo->prepare('
            INSERT INTO operator_certifications (employee_id, certification_name, issued_at, expires_at, created_at)
            VALUES (:emp_id, :cert_name, :issued, :expires, UTC_TIMESTAMP())
        ');
        $stmt->execute([
            'emp_id' => $empId,
            'cert_name' => $certName,
            'issued' => $issued,
            'expires' => $expires
        ]);
        return (int) $this->pdo->lastInsertId();
    }
}
