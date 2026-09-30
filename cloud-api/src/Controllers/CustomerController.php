<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class CustomerController extends BaseController
{
    public function list(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        $page = max(1, (int) ($request->query('page') ?? 1));
        $limit = min(100, max(1, (int) ($request->query('limit') ?? 25)));
        $offset = ($page - 1) * $limit;
        $q = trim((string) ($request->query('q') ?? ($request->query('search') ?? '')));

        if ($pdo === null) {
            $this->success(['items' => [], 'pagination' => ['page' => 1, 'limit' => $limit, 'total' => 0]], 'CUSTOMERS_RETRIEVED');
            return;
        }

        $sql = 'SELECT id, uuid, customer_code, name, phone, email, emirate, credit_limit, outstanding_balance, is_active, created_at 
                FROM tenant_customers WHERE tenant_id = :tid';
        $binds = ['tid' => $tenantId];

        if ($q !== '') {
            $sql .= ' AND (name LIKE :q OR phone LIKE :q OR customer_code LIKE :q)';
            $binds['q'] = '%' . $q . '%';
        }

        $sql .= ' ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($binds);
        $items = $stmt->fetchAll();

        $countStmt = $pdo->prepare('SELECT COUNT(*) FROM tenant_customers WHERE tenant_id = :tid' . ($q !== '' ? ' AND (name LIKE :q OR phone LIKE :q OR customer_code LIKE :q)' : ''));
        $countStmt->execute($binds);
        $total = (int) $countStmt->fetchColumn();

        $this->success([
            'items' => $items,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => ceil($total / $limit),
            ],
        ], 'CUSTOMERS_RETRIEVED');
    }

    public function get(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_customers WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $customer = $stmt->fetch();

        if (!$customer) {
            $this->error('Customer not found', 'CUSTOMER_NOT_FOUND', 404);
            return;
        }

        $this->success($customer, 'CUSTOMER_RETRIEVED');
    }

    public function create(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();

        $name = trim((string) ($body['name'] ?? ''));
        $phone = trim((string) ($body['phone'] ?? ''));

        if ($name === '' || $phone === '') {
            $this->error('Customer name and phone are required', 'VALIDATION_ERROR', 422);
            return;
        }

        $pdo = $this->db();
        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $uuid = $body['uuid'] ?? $this->generateUuid();
        $code = $body['customer_code'] ?? ('CUST-' . strtoupper(substr($uuid, 0, 8)));
        $email = $body['email'] ?? null;
        $emirate = $body['emirate'] ?? 'Dubai';
        $creditLimit = (string) ($body['credit_limit'] ?? '0.00');

        $stmt = $pdo->prepare('INSERT INTO tenant_customers 
            (tenant_id, uuid, customer_code, name, phone, email, emirate, credit_limit, is_active) 
            VALUES (:tid, :uuid, :code, :name, :phone, :email, :emirate, :credit, 1)');
        $stmt->execute([
            'tid' => $tenantId,
            'uuid' => $uuid,
            'code' => $code,
            'name' => $name,
            'phone' => $phone,
            'email' => $email,
            'emirate' => $emirate,
            'credit' => $creditLimit,
        ]);

        $newId = (int) $pdo->lastInsertId();

        $this->success([
            'id' => $newId,
            'uuid' => $uuid,
            'customer_code' => $code,
            'name' => $name,
            'phone' => $phone,
            'email' => $email,
            'emirate' => $emirate,
            'credit_limit' => $creditLimit,
            'outstanding_balance' => '0.00',
        ], 'CUSTOMER_CREATED', 201);
    }

    public function update(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT id FROM tenant_customers WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $existing = $stmt->fetch();

        if (!$existing) {
            $this->error('Customer not found', 'CUSTOMER_NOT_FOUND', 404);
            return;
        }

        $fields = [];
        $binds = ['id' => $existing['id'], 'tid' => $tenantId];

        foreach (['name', 'phone', 'email', 'emirate', 'credit_limit', 'outstanding_balance', 'is_active'] as $col) {
            if (isset($body[$col])) {
                $fields[] = "{$col} = :{$col}";
                $binds[$col] = $body[$col];
            }
        }

        if (!empty($fields)) {
            $updateSql = 'UPDATE tenant_customers SET ' . implode(', ', $fields) . ' WHERE id = :id AND tenant_id = :tid';
            $updateStmt = $pdo->prepare($updateSql);
            $updateStmt->execute($binds);
        }

        $this->success(['id' => (int) $existing['id'], 'updated' => true], 'CUSTOMER_UPDATED');
    }
}
