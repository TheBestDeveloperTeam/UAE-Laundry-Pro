<?php
declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

class OperatorRepository
{
    public function __construct(private readonly PDO )
    {
    }

    public function getCertifications(): array
    {
         = ->pdo->query('
            SELECT oc.*, e.full_name, e.employee_no 
            FROM operator_certifications oc
            JOIN employees e ON oc.employee_id = e.id
            ORDER BY oc.expires_at ASC
        ');
        return ->fetchAll(PDO::FETCH_ASSOC);
    }

    public function certify(int , string , string , string ): int
    {
         = ->pdo->prepare('
            INSERT INTO operator_certifications (employee_id, certification_name, issued_at, expires_at, created_at)
            VALUES (:emp_id, :cert_name, :issued, :expires, UTC_TIMESTAMP())
        ');
        ->execute([
            'emp_id' => ,
            'cert_name' => ,
            'issued' => ,
            'expires' => 
        ]);
        return (int) ->pdo->lastInsertId();
    }
}

