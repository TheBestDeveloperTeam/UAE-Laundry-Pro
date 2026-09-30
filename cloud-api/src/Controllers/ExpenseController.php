<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class ExpenseController extends BaseController
{
    public function categories(Request $request, array $params = []): void
    {
        $this->success([
            ['id' => 1, 'name' => 'Detergents & Chemicals', 'code' => 'CHEM'],
            ['id' => 2, 'name' => 'Utilities & Power', 'code' => 'UTIL'],
            ['id' => 3, 'name' => 'Rent & Facilities', 'code' => 'RENT'],
            ['id' => 4, 'name' => 'Vehicle & Fuel', 'code' => 'FUEL'],
            ['id' => 5, 'name' => 'Packaging Materials', 'code' => 'PACK'],
            ['id' => 6, 'name' => 'Miscellaneous', 'code' => 'MISC'],
        ], 'EXPENSE_CATEGORIES_RETRIEVED');
    }

    public function createCategory(Request $request, array $params = []): void
    {
        $body = $request->json();
        $name = $body['name'] ?? 'New Category';
        $this->success(['id' => mt_rand(10, 99), 'name' => $name], 'EXPENSE_CATEGORY_CREATED', 201);
    }

    public function list(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'EXPENSES_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_expenses WHERE tenant_id = :tid ORDER BY id DESC LIMIT 50');
        $stmt->execute(['tid' => $tenantId]);
        $expenses = $stmt->fetchAll();

        $this->success($expenses, 'EXPENSES_RETRIEVED');
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

        $stmt = $pdo->prepare('SELECT * FROM tenant_expenses WHERE id = :id AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'tid' => $tenantId]);
        $exp = $stmt->fetch();

        if (!$exp) {
            $this->error('Expense not found', 'EXPENSE_NOT_FOUND', 404);
            return;
        }

        $this->success($exp, 'EXPENSE_RETRIEVED');
    }

    public function create(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $cat = $body['category_name'] ?? 'General';
        $amt = (string) ($body['amount'] ?? '0.00');
        $payee = $body['payee'] ?? 'Vendor';
        $paidFrom = $body['paid_from'] ?? 'cash_drawer';
        $notes = $body['notes'] ?? null;

        $stmt = $pdo->prepare('INSERT INTO tenant_expenses (tenant_id, category_name, amount, payee, paid_from, notes) 
            VALUES (:tid, :cat, :amt, :payee, :pf, :notes)');
        $stmt->execute([
            'tid' => $tenantId,
            'cat' => $cat,
            'amt' => $amt,
            'payee' => $payee,
            'pf' => $paidFrom,
            'notes' => $notes,
        ]);

        $this->success([
            'id' => (int) $pdo->lastInsertId(),
            'category_name' => $cat,
            'amount' => $amt,
            'payee' => $payee,
        ], 'EXPENSE_CREATED', 201);
    }

    public function approve(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'approved' => true], 'EXPENSE_APPROVED');
    }

    public function reject(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'rejected' => true], 'EXPENSE_REJECTED');
    }

    public function attachments(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success([], 'EXPENSE_ATTACHMENTS_RETRIEVED');
    }
}
