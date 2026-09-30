<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class CatalogController extends BaseController
{
    // ===== Services =====
    public function listServices(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'SERVICES_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT id, uuid, category_id, name, service_code, price, turnaround_hours, is_active, created_at 
            FROM tenant_services WHERE tenant_id = :tid ORDER BY name ASC');
        $stmt->execute(['tid' => $tenantId]);
        $services = $stmt->fetchAll();

        $this->success($services, 'SERVICES_RETRIEVED');
    }

    public function getService(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_services WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $service = $stmt->fetch();

        if (!$service) {
            $this->error('Service not found', 'SERVICE_NOT_FOUND', 404);
            return;
        }

        $this->success($service, 'SERVICE_RETRIEVED');
    }

    public function createService(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();

        $name = trim((string) ($body['name'] ?? ''));
        $price = (string) ($body['price'] ?? '0.00');

        if ($name === '') {
            $this->error('Service name is required', 'VALIDATION_ERROR', 422);
            return;
        }

        $pdo = $this->db();
        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $uuid = $body['uuid'] ?? $this->generateUuid();
        $code = $body['service_code'] ?? ('SRV-' . strtoupper(substr($uuid, 0, 6)));
        $catId = $body['category_id'] ?? null;
        $turnaround = (int) ($body['turnaround_hours'] ?? 48);

        $stmt = $pdo->prepare('INSERT INTO tenant_services 
            (tenant_id, uuid, category_id, name, service_code, price, turnaround_hours, is_active) 
            VALUES (:tid, :uuid, :cat_id, :name, :code, :price, :turnaround, 1)');
        $stmt->execute([
            'tid' => $tenantId,
            'uuid' => $uuid,
            'cat_id' => $catId,
            'name' => $name,
            'code' => $code,
            'price' => $price,
            'turnaround' => $turnaround,
        ]);

        $this->success([
            'id' => (int) $pdo->lastInsertId(),
            'uuid' => $uuid,
            'name' => $name,
            'service_code' => $code,
            'price' => $price,
            'turnaround_hours' => $turnaround,
        ], 'SERVICE_CREATED', 201);
    }

    public function updateService(Request $request, array $params = []): void
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

        $stmt = $pdo->prepare('SELECT id FROM tenant_services WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $existing = $stmt->fetch();

        if (!$existing) {
            $this->error('Service not found', 'SERVICE_NOT_FOUND', 404);
            return;
        }

        $fields = [];
        $binds = ['id' => $existing['id'], 'tid' => $tenantId];

        foreach (['name', 'service_code', 'price', 'turnaround_hours', 'category_id', 'is_active'] as $col) {
            if (isset($body[$col])) {
                $fields[] = "{$col} = :{$col}";
                $binds[$col] = $body[$col];
            }
        }

        if (!empty($fields)) {
            $updateSql = 'UPDATE tenant_services SET ' . implode(', ', $fields) . ' WHERE id = :id AND tenant_id = :tid';
            $updateStmt = $pdo->prepare($updateSql);
            $updateStmt->execute($binds);
        }

        $this->success(['id' => (int) $existing['id'], 'updated' => true], 'SERVICE_UPDATED');
    }

    // ===== Products =====
    public function listProducts(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'PRODUCTS_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT id, uuid, name, sku, price, stock_quantity, is_active, created_at 
            FROM tenant_products WHERE tenant_id = :tid ORDER BY name ASC');
        $stmt->execute(['tid' => $tenantId]);
        $products = $stmt->fetchAll();

        $this->success($products, 'PRODUCTS_RETRIEVED');
    }

    public function getProduct(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_products WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $product = $stmt->fetch();

        if (!$product) {
            $this->error('Product not found', 'PRODUCT_NOT_FOUND', 404);
            return;
        }

        $this->success($product, 'PRODUCT_RETRIEVED');
    }

    public function createProduct(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();

        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            $this->error('Product name is required', 'VALIDATION_ERROR', 422);
            return;
        }

        $pdo = $this->db();
        if ($pdo === null) {
            $this->error('Database unavailable', 'DB_ERROR', 503);
            return;
        }

        $uuid = $body['uuid'] ?? $this->generateUuid();
        $sku = $body['sku'] ?? ('SKU-' . strtoupper(substr($uuid, 0, 6)));
        $price = (string) ($body['price'] ?? '0.00');
        $stock = (string) ($body['stock_quantity'] ?? '0.00');

        $stmt = $pdo->prepare('INSERT INTO tenant_products 
            (tenant_id, uuid, name, sku, price, stock_quantity, is_active) 
            VALUES (:tid, :uuid, :name, :sku, :price, :stock, 1)');
        $stmt->execute([
            'tid' => $tenantId,
            'uuid' => $uuid,
            'name' => $name,
            'sku' => $sku,
            'price' => $price,
            'stock' => $stock,
        ]);

        $this->success([
            'id' => (int) $pdo->lastInsertId(),
            'uuid' => $uuid,
            'name' => $name,
            'sku' => $sku,
            'price' => $price,
            'stock_quantity' => $stock,
        ], 'PRODUCT_CREATED', 201);
    }

    public function updateProduct(Request $request, array $params = []): void
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

        $stmt = $pdo->prepare('SELECT id FROM tenant_products WHERE (id = :id OR uuid = :uuid) AND tenant_id = :tid LIMIT 1');
        $stmt->execute(['id' => $id, 'uuid' => $id, 'tid' => $tenantId]);
        $existing = $stmt->fetch();

        if (!$existing) {
            $this->error('Product not found', 'PRODUCT_NOT_FOUND', 404);
            return;
        }

        $fields = [];
        $binds = ['id' => $existing['id'], 'tid' => $tenantId];

        foreach (['name', 'sku', 'price', 'stock_quantity', 'is_active'] as $col) {
            if (isset($body[$col])) {
                $fields[] = "{$col} = :{$col}";
                $binds[$col] = $body[$col];
            }
        }

        if (!empty($fields)) {
            $updateSql = 'UPDATE tenant_products SET ' . implode(', ', $fields) . ' WHERE id = :id AND tenant_id = :tid';
            $updateStmt = $pdo->prepare($updateSql);
            $updateStmt->execute($binds);
        }

        $this->success(['id' => (int) $existing['id'], 'updated' => true], 'PRODUCT_UPDATED');
    }

    // ===== Sub-resource / Association Endpoints =====
    public function serviceProducts(Request $request, array $params = []): void
    {
        $this->success([], 'SERVICE_PRODUCTS_RETRIEVED');
    }

    public function addServiceProduct(Request $request, array $params = []): void
    {
        $this->success(['attached' => true], 'SERVICE_PRODUCT_ATTACHED', 201);
    }

    public function removeServiceProduct(Request $request, array $params = []): void
    {
        $this->success(['detached' => true], 'SERVICE_PRODUCT_DETACHED');
    }

    public function serviceModifiers(Request $request, array $params = []): void
    {
        $this->success([], 'SERVICE_MODIFIERS_RETRIEVED');
    }

    public function addServiceModifier(Request $request, array $params = []): void
    {
        $this->success(['attached' => true], 'SERVICE_MODIFIER_ATTACHED', 201);
    }

    public function productModifiers(Request $request, array $params = []): void
    {
        $this->success([], 'PRODUCT_MODIFIERS_RETRIEVED');
    }

    public function addProductModifier(Request $request, array $params = []): void
    {
        $this->success(['attached' => true], 'PRODUCT_MODIFIER_ATTACHED', 201);
    }
}
