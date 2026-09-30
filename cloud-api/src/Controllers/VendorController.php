<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class VendorController extends BaseController
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
            $this->success(['items' => [], 'pagination' => ['page' => 1, 'limit' => $limit, 'total' => 0]], 'VENDORS_RETRIEVED');
            return;
        }

        $sql = 'SELECT id, uuid, name, contact_person, phone, email, trn, is_active, created_at 
                FROM tenant_vendors WHERE tenant_id = :tid';
        $binds = ['tid' => $tenantId];

        if ($q !== '') {
            $sql .= ' AND (name LIKE :q OR phone LIKE :q OR trn LIKE :q)';
            $binds['q'] = '%' . $q . '%';
        }

        $sql .= ' ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($binds);
        $items = $stmt->fetchAll();

        $countStmt = $pdo->prepare('SELECT COUNT(*) FROM tenant_vendors WHERE tenant_id = :tid' . ($q !== '' ? ' AND (name LIKE :q OR phone LIKE :q OR trn LIKE :q)' : ''));
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
        ], 'VENDORS_RETRIEVED');
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

        $stmt = $pdo->prepare('SELECT * FROM tenant_vendors WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $vendor = $stmt->fetch();

        if (!$vendor) {
            $this->error('Vendor not found', 'VENDOR_NOT_FOUND', 404);
            return;
        }

        $this->success($vendor, 'VENDOR_RETRIEVED');
    }

    public function create(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();

        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            $this->error('Vendor name is required', 'VALIDATION_ERROR', 422);
            return;
        }

        $pdo = $this->db();
        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $uuid = $body['uuid'] ?? $this->generateUuid();
        $contactPerson = $body['contact_person'] ?? null;
        $phone = $body['phone'] ?? null;
        $email = $body['email'] ?? null;
        $trn = $body['trn'] ?? null;

        $stmt = $pdo->prepare('INSERT INTO tenant_vendors 
            (tenant_id, uuid, name, contact_person, phone, email, trn, is_active) 
            VALUES (:tid, :uuid, :name, :contact, :phone, :email, :trn, 1)');
        $stmt->execute([
            'tid' => $tenantId,
            'uuid' => $uuid,
            'name' => $name,
            'contact' => $contactPerson,
            'phone' => $phone,
            'email' => $email,
            'trn' => $trn,
        ]);

        $this->success([
            'id' => (int) $pdo->lastInsertId(),
            'uuid' => $uuid,
            'name' => $name,
            'contact_person' => $contactPerson,
            'phone' => $phone,
            'email' => $email,
            'trn' => $trn,
        ], 'VENDOR_CREATED', 201);
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

        $stmt = $pdo->prepare('SELECT id FROM tenant_vendors WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $existing = $stmt->fetch();

        if (!$existing) {
            $this->error('Vendor not found', 'VENDOR_NOT_FOUND', 404);
            return;
        }

        $fields = [];
        $binds = ['id' => $existing['id'], 'tid' => $tenantId];

        foreach (['name', 'contact_person', 'phone', 'email', 'trn', 'is_active'] as $col) {
            if (isset($body[$col])) {
                $fields[] = "{$col} = :{$col}";
                $binds[$col] = $body[$col];
            }
        }

        if (!empty($fields)) {
            $updateSql = 'UPDATE tenant_vendors SET ' . implode(', ', $fields) . ' WHERE id = :id AND tenant_id = :tid';
            $updateStmt = $pdo->prepare($updateSql);
            $updateStmt->execute($binds);
        }

        $this->success(['id' => (int) $existing['id'], 'updated' => true], 'VENDOR_UPDATED');
    }
}
