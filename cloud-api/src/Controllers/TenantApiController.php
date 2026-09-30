<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Database;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use LaundryPro\Cloud\Middleware\TenantScopeMiddleware;
use PDO;

final class TenantApiController
{
    private function getAuthenticatedTenant(Request $request): ?array
    {
        return TenantScopeMiddleware::authenticate($request);
    }

    private function generateUuid(): string
    {
        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );
    }

    public function profile(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT id, uuid, name, license_key, trade_license_no, contact_email, contact_phone, country_code, city, status, max_branches, max_devices, created_at FROM businesses WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $tenant['id']]);
        $profile = $stmt->fetch();

        Response::json([
            'success' => true,
            'code' => 'TENANT_PROFILE',
            'data' => $profile ?: $tenant,
        ]);
    }

    public function listCustomers(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $q = trim((string) ($request->query('q') ?? ''));
        $page = max(1, (int) ($request->query('page') ?? 1));
        $limit = min(100, max(1, (int) ($request->query('limit') ?? 25)));
        $offset = ($page - 1) * $limit;

        $sql = 'SELECT id, uuid, customer_code, name, phone, email, emirate, credit_limit, outstanding_balance, is_active, created_at FROM tenant_customers WHERE tenant_id = :tenant_id';
        $params = ['tenant_id' => $tenant['id']];

        if ($q !== '') {
            $sql .= ' AND (name LIKE :q OR phone LIKE :q OR customer_code LIKE :q)';
            $params['q'] = '%' . $q . '%';
        }

        $sql .= ' ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $customers = $stmt->fetchAll();

        // Count total
        $countSql = 'SELECT COUNT(*) FROM tenant_customers WHERE tenant_id = :tenant_id';
        $countParams = ['tenant_id' => $tenant['id']];
        if ($q !== '') {
            $countSql .= ' AND (name LIKE :q OR phone LIKE :q OR customer_code LIKE :q)';
            $countParams['q'] = '%' . $q . '%';
        }
        $countStmt = $pdo->prepare($countSql);
        $countStmt->execute($countParams);
        $total = (int) $countStmt->fetchColumn();

        Response::json([
            'success' => true,
            'code' => 'CUSTOMERS_RETRIEVED',
            'data' => [
                'items' => $customers,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $total,
                    'pages' => ceil($total / $limit),
                ],
            ],
        ]);
    }

    public function createCustomer(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $body = $request->body();
        $name = trim((string) ($body['name'] ?? ''));
        $phone = trim((string) ($body['phone'] ?? ''));
        $email = trim((string) ($body['email'] ?? ''));
        $address = (string) ($body['address'] ?? '');
        $emirate = trim((string) ($body['emirate'] ?? 'Dubai'));
        $creditLimit = (float) ($body['credit_limit'] ?? 0.0);

        if ($name === '' || $phone === '') {
            Response::json([
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Customer name and phone number are required',
                'errors' => ['Name and phone must not be empty'],
            ], 422);
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $uuid = $this->generateUuid();
        $customerCode = 'CUST-' . strtoupper(substr(uniqid(), -6));

        try {
            $stmt = $pdo->prepare(
                'INSERT INTO tenant_customers (tenant_id, uuid, customer_code, name, phone, email, address, emirate, credit_limit, outstanding_balance, is_active, created_at)
                 VALUES (:tenant_id, :uuid, :code, :name, :phone, :email, :address, :emirate, :credit_limit, 0.00, 1, NOW())'
            );
            $stmt->execute([
                'tenant_id' => $tenant['id'],
                'uuid' => $uuid,
                'code' => $customerCode,
                'name' => $name,
                'phone' => $phone,
                'email' => $email !== '' ? $email : null,
                'address' => $address !== '' ? $address : null,
                'emirate' => $emirate,
                'credit_limit' => $creditLimit,
            ]);

            $id = (int) $pdo->lastInsertId();

            Response::json([
                'success' => true,
                'code' => 'CUSTOMER_CREATED',
                'message' => 'Customer successfully registered in cloud database',
                'data' => [
                    'id' => $id,
                    'uuid' => $uuid,
                    'customer_code' => $customerCode,
                    'name' => $name,
                    'phone' => $phone,
                ],
            ], 201);
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'CUSTOMER_CREATION_FAILED', 'message' => $e->getMessage()], 500);
        }
    }

    public function listServices(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $stmt = $pdo->prepare('SELECT id, uuid, category_id, name, service_code, price, turnaround_hours, is_active FROM tenant_services WHERE tenant_id = :tenant_id AND is_active = 1 ORDER BY name ASC');
        $stmt->execute(['tenant_id' => $tenant['id']]);
        $services = $stmt->fetchAll();

        Response::json([
            'success' => true,
            'code' => 'SERVICES_RETRIEVED',
            'data' => $services,
        ]);
    }

    public function createService(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $body = $request->body();
        $name = trim((string) ($body['name'] ?? ''));
        $code = trim((string) ($body['service_code'] ?? ''));
        $price = (float) ($body['price'] ?? 0.0);
        $turnaround = max(1, (int) ($body['turnaround_hours'] ?? 48));

        if ($name === '') {
            Response::json(['success' => false, 'code' => 'VALIDATION_ERROR', 'message' => 'Service name is required'], 422);
            return;
        }
        if ($code === '') {
            $code = 'SRV-' . strtoupper(substr(uniqid(), -5));
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $uuid = $this->generateUuid();

        try {
            $stmt = $pdo->prepare('INSERT INTO tenant_services (tenant_id, uuid, name, service_code, price, turnaround_hours, is_active) VALUES (:tenant_id, :uuid, :name, :code, :price, :turnaround, 1)');
            $stmt->execute([
                'tenant_id' => $tenant['id'],
                'uuid' => $uuid,
                'name' => $name,
                'code' => $code,
                'price' => $price,
                'turnaround' => $turnaround,
            ]);

            Response::json([
                'success' => true,
                'code' => 'SERVICE_CREATED',
                'data' => [
                    'id' => (int) $pdo->lastInsertId(),
                    'uuid' => $uuid,
                    'name' => $name,
                    'service_code' => $code,
                    'price' => $price,
                ],
            ], 201);
        } catch (\Throwable $e) {
            Response::json(['success' => false, 'code' => 'SERVICE_CREATION_FAILED', 'message' => $e->getMessage()], 500);
        }
    }

    public function listOrders(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $status = trim((string) ($request->query('status') ?? ''));
        $page = max(1, (int) ($request->query('page') ?? 1));
        $limit = min(100, max(1, (int) ($request->query('limit') ?? 25)));
        $offset = ($page - 1) * $limit;

        $sql = 'SELECT o.*, c.name as customer_name, c.phone as customer_phone 
                FROM tenant_sales_orders o 
                LEFT JOIN tenant_customers c ON c.id = o.customer_id 
                WHERE o.tenant_id = :tenant_id';
        $params = ['tenant_id' => $tenant['id']];

        if ($status !== '') {
            $sql .= ' AND o.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY o.id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $orders = $stmt->fetchAll();

        Response::json([
            'success' => true,
            'code' => 'ORDERS_RETRIEVED',
            'data' => [
                'items' => $orders,
                'page' => $page,
                'limit' => $limit,
            ],
        ]);
    }

    public function createOrder(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $body = $request->body();
        $customerId = isset($body['customer_id']) ? (int) $body['customer_id'] : null;
        $items = isset($body['items']) && is_array($body['items']) ? $body['items'] : [];

        if (empty($items)) {
            Response::json(['success' => false, 'code' => 'VALIDATION_ERROR', 'message' => 'Order must contain at least one line item'], 422);
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $orderNumber = 'ORD-' . date('ymd') . '-' . strtoupper(substr(uniqid(), -4));
        $uuid = $this->generateUuid();

        // Calculate totals with UAE 5% VAT
        $subtotal = 0.0;
        $vatRate = 0.05;

        $processedLines = [];
        foreach ($items as $item) {
            $itemName = trim((string) ($item['item_name'] ?? 'Laundry Item'));
            $quantity = max(1, (int) ($item['quantity'] ?? 1));
            $unitPrice = (float) ($item['unit_price'] ?? 0.0);
            $serviceId = isset($item['service_id']) ? (int) $item['service_id'] : null;

            $lineSubtotal = round($unitPrice * $quantity, 2);
            $lineVat = round($lineSubtotal * $vatRate, 2);
            $lineTotal = round($lineSubtotal + $lineVat, 2);

            $subtotal += $lineSubtotal;
            $processedLines[] = [
                'service_id' => $serviceId,
                'item_name' => $itemName,
                'quantity' => $quantity,
                'unit_price' => $unitPrice,
                'vat_amount' => $lineVat,
                'total_amount' => $lineTotal,
                'notes' => (string) ($item['notes'] ?? ''),
            ];
        }

        $vatAmount = round($subtotal * $vatRate, 2);
        $totalAmount = round($subtotal + $vatAmount, 2);

        try {
            $pdo->beginTransaction();

            $stmt = $pdo->prepare(
                'INSERT INTO tenant_sales_orders (tenant_id, uuid, order_number, customer_id, status, payment_status, subtotal, vat_amount, total_amount, source_branch, created_at)
                 VALUES (:tenant_id, :uuid, :order_number, :customer_id, :status, :payment_status, :subtotal, :vat_amount, :total_amount, :branch, NOW())'
            );
            $stmt->execute([
                'tenant_id' => $tenant['id'],
                'uuid' => $uuid,
                'order_number' => $orderNumber,
                'customer_id' => $customerId,
                'status' => 'confirmed',
                'payment_status' => 'unpaid',
                'subtotal' => $subtotal,
                'vat_amount' => $vatAmount,
                'total_amount' => $totalAmount,
                'branch' => (string) ($body['source_branch'] ?? 'Main Store'),
            ]);

            $orderId = (int) $pdo->lastInsertId();

            $lineStmt = $pdo->prepare(
                'INSERT INTO tenant_sales_order_lines (tenant_id, order_id, service_id, item_name, quantity, unit_price, vat_amount, total_amount, notes)
                 VALUES (:tenant_id, :order_id, :service_id, :item_name, :quantity, :unit_price, :vat_amount, :total_amount, :notes)'
            );

            foreach ($processedLines as $line) {
                $lineStmt->execute([
                    'tenant_id' => $tenant['id'],
                    'order_id' => $orderId,
                    'service_id' => $line['service_id'],
                    'item_name' => $line['item_name'],
                    'quantity' => $line['quantity'],
                    'unit_price' => $line['unit_price'],
                    'vat_amount' => $line['vat_amount'],
                    'total_amount' => $line['total_amount'],
                    'notes' => $line['notes'] !== '' ? $line['notes'] : null,
                ]);
            }

            $pdo->commit();

            Response::json([
                'success' => true,
                'code' => 'ORDER_CREATED',
                'message' => 'Sales order created successfully',
                'data' => [
                    'order_id' => $orderId,
                    'uuid' => $uuid,
                    'order_number' => $orderNumber,
                    'subtotal' => $subtotal,
                    'vat_amount' => $vatAmount,
                    'total_amount' => $totalAmount,
                ],
            ], 201);
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            Response::json(['success' => false, 'code' => 'ORDER_CREATION_FAILED', 'message' => $e->getMessage()], 500);
        }
    }

    public function reportsSummary(Request $request): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        if ($tenant === null) {
            return;
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            Response::json(['success' => false, 'code' => 'SERVICE_UNAVAILABLE', 'message' => 'Database offline'], 503);
            return;
        }

        $tenantId = (int) $tenant['id'];

        $custStmt = $pdo->prepare('SELECT COUNT(*) FROM tenant_customers WHERE tenant_id = ?');
        $custStmt->execute([$tenantId]);
        $customerCount = (int) $custStmt->fetchColumn();

        $orderStmt = $pdo->prepare('SELECT COUNT(*), COALESCE(SUM(total_amount), 0), COALESCE(SUM(vat_amount), 0) FROM tenant_sales_orders WHERE tenant_id = ?');
        $orderStmt->execute([$tenantId]);
        $orderMetrics = $orderStmt->fetch(PDO::FETCH_NUM);

        Response::json([
            'success' => true,
            'code' => 'REPORTS_SUMMARY',
            'data' => [
                'tenant_name' => $tenant['name'],
                'customer_count' => $customerCount,
                'order_count' => (int) ($orderMetrics[0] ?? 0),
                'total_revenue_aed' => (float) ($orderMetrics[1] ?? 0.0),
                'vat_collected_aed' => (float) ($orderMetrics[2] ?? 0.0),
            ],
        ]);
    }
}
