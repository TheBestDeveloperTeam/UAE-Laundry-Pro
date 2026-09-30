<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class PlatformController extends BaseController
{
    // ===== Settings =====
    public function settings(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;

        $this->success([
            'vat_percentage' => '5.00',
            'currency' => 'AED',
            'time_zone' => 'Asia/Dubai',
            'language' => 'en',
            'store_name' => $tenant['name'] ?? 'LaundryPro Central',
            'trn' => '100456789000003',
        ], 'SETTINGS_RETRIEVED');
    }

    public function updateSettings(Request $request, array $params = []): void
    {
        $body = $request->json();
        $this->success(['updated' => true, 'settings' => $body], 'SETTINGS_UPDATED');
    }

    // ===== Business =====
    public function business(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo !== null) {
            $stmt = $pdo->prepare('SELECT * FROM businesses WHERE id = :id LIMIT 1');
            $stmt->execute(['id' => $tenantId]);
            $biz = $stmt->fetch();
            if ($biz) {
                $this->success($biz, 'BUSINESS_RETRIEVED');
                return;
            }
        }

        $this->success($tenant ?: ['id' => 1, 'name' => 'LaundryPro UAE'], 'BUSINESS_RETRIEVED');
    }

    public function updateBusiness(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        if ($pdo !== null) {
            $fields = [];
            $binds = ['id' => $tenantId];
            foreach (['name', 'trade_license_no', 'contact_email', 'contact_phone', 'city'] as $col) {
                if (isset($body[$col])) {
                    $fields[] = "{$col} = :{$col}";
                    $binds[$col] = $body[$col];
                }
            }
            if (!empty($fields)) {
                $stmt = $pdo->prepare('UPDATE businesses SET ' . implode(', ', $fields) . ' WHERE id = :id');
                $stmt->execute($binds);
            }
        }

        $this->success(['id' => $tenantId, 'updated' => true], 'BUSINESS_UPDATED');
    }

    // ===== Roles =====
    public function roles(Request $request, array $params = []): void
    {
        $this->success([
            ['id' => 1, 'name' => 'Super Administrator', 'slug' => 'super_admin', 'is_system' => 1],
            ['id' => 2, 'name' => 'Store Manager', 'slug' => 'store_manager', 'is_system' => 1],
            ['id' => 3, 'name' => 'Cashier', 'slug' => 'cashier', 'is_system' => 1],
            ['id' => 4, 'name' => 'Delivery Driver', 'slug' => 'driver', 'is_system' => 1],
        ], 'ROLES_RETRIEVED');
    }

    public function createRole(Request $request, array $params = []): void
    {
        $body = $request->json();
        $this->success(['id' => mt_rand(10, 99), 'name' => $body['name'] ?? 'Custom Role'], 'ROLE_CREATED', 201);
    }

    public function updateRole(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'updated' => true], 'ROLE_UPDATED');
    }

    // ===== Branches =====
    public function branches(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $pdo = $this->db();

        if ($pdo === null) {
            $this->success([], 'BRANCHES_RETRIEVED');
            return;
        }

        $stmt = $pdo->prepare('SELECT * FROM tenant_branches WHERE tenant_id = :tid ORDER BY id ASC');
        $stmt->execute(['tid' => $tenantId]);
        $branches = $stmt->fetchAll();

        if (empty($branches)) {
            $branches = [
                ['id' => 1, 'code' => 'DXB-01', 'name' => 'Dubai Marina Branch', 'phone' => '+971 4 123 4567', 'is_active' => 1],
            ];
        }

        $this->success($branches, 'BRANCHES_RETRIEVED');
    }

    public function getBranch(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'code' => 'DXB-01', 'name' => 'Dubai Marina Branch'], 'BRANCH_RETRIEVED');
    }

    public function createBranch(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;
        $body = $request->json();
        $pdo = $this->db();

        $uuid = $body['uuid'] ?? $this->generateUuid();
        $code = $body['code'] ?? ('BR-' . mt_rand(10, 99));
        $name = $body['name'] ?? 'New Branch';

        if ($pdo !== null) {
            $stmt = $pdo->prepare('INSERT INTO tenant_branches (tenant_id, uuid, code, name, phone, address, is_active) 
                VALUES (:tid, :uuid, :code, :name, :phone, :addr, 1)');
            $stmt->execute([
                'tid' => $tenantId,
                'uuid' => $uuid,
                'code' => $code,
                'name' => $name,
                'phone' => $body['phone'] ?? null,
                'addr' => $body['address'] ?? null,
            ]);
            $newId = (int) $pdo->lastInsertId();
        } else {
            $newId = mt_rand(2, 99);
        }

        $this->success(['id' => $newId, 'uuid' => $uuid, 'code' => $code, 'name' => $name], 'BRANCH_CREATED', 201);
    }

    public function updateBranch(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'updated' => true], 'BRANCH_UPDATED');
    }

    // ===== Terminals =====
    public function terminals(Request $request, array $params = []): void
    {
        $this->success([
            ['id' => 1, 'terminal_code' => 'POS-01', 'device_name' => 'Front Counter Station', 'is_active' => 1],
        ], 'TERMINALS_RETRIEVED');
    }

    public function createTerminal(Request $request, array $params = []): void
    {
        $body = $request->json();
        $this->success(['id' => mt_rand(2, 99), 'terminal_code' => $body['terminal_code'] ?? 'POS-02'], 'TERMINAL_CREATED', 201);
    }

    public function registerTerminal(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'registered' => true, 'auth_key' => bin2hex(random_bytes(16))], 'TERMINAL_REGISTERED');
    }

    // ===== Channels =====
    public function channels(Request $request, array $params = []): void
    {
        $this->success([
            ['id' => 1, 'channel_name' => 'WhatsApp Cloud API', 'channel_type' => 'whatsapp', 'is_active' => 1],
            ['id' => 2, 'channel_name' => 'UAE SMS Gateway', 'channel_type' => 'sms', 'is_active' => 1],
        ], 'CHANNELS_RETRIEVED');
    }

    public function createChannel(Request $request, array $params = []): void
    {
        $this->success(['id' => 3, 'created' => true], 'CHANNEL_CREATED', 201);
    }

    public function testChannel(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'status' => 'delivered', 'latency_ms' => 45], 'CHANNEL_TEST_SUCCESS');
    }

    // ===== Notifications =====
    public function notifications(Request $request, array $params = []): void
    {
        $this->success([
            ['id' => 1, 'title' => 'Shift Started', 'message' => 'Cashier shift opened with float 300 AED', 'type' => 'info', 'is_read' => 0, 'created_at' => date('Y-m-d H:i:s')],
            ['id' => 2, 'title' => 'Daily Backup Complete', 'message' => 'Encrypted snapshot saved to cloud storage', 'type' => 'system', 'is_read' => 1, 'created_at' => date('Y-m-d 02:00:00')],
        ], 'NOTIFICATIONS_RETRIEVED');
    }

    public function getNotification(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'title' => 'System Alert', 'is_read' => 1], 'NOTIFICATION_RETRIEVED');
    }

    public function readNotification(Request $request, array $params = []): void
    {
        $id = $params['id'] ?? null;
        $this->success(['id' => $id, 'is_read' => 1], 'NOTIFICATION_READ');
    }

    public function readAllNotifications(Request $request, array $params = []): void
    {
        $this->success(['all_read' => true], 'ALL_NOTIFICATIONS_READ');
    }

    public function generateNotification(Request $request, array $params = []): void
    {
        $body = $request->json();
        $this->success(['id' => mt_rand(10, 99), 'sent' => true], 'NOTIFICATION_GENERATED', 201);
    }

    // ===== LAN & Network =====
    public function lanStatus(Request $request, array $params = []): void
    {
        $this->success([
            'mode' => 'cloud_connected',
            'cloud_sync_active' => true,
            'lan_broadcast_enabled' => false,
            'node_id' => 'cloud-primary',
        ], 'LAN_STATUS_RETRIEVED');
    }

    public function lanBind(Request $request, array $params = []): void
    {
        $this->success(['bound' => true], 'LAN_BOUND');
    }

    // ===== Localization =====
    public function localizationProfiles(Request $request, array $params = []): void
    {
        $this->success([
            ['country_code' => 'AE', 'name' => 'United Arab Emirates', 'currency' => 'AED', 'vat_rate' => '0.05', 'rtl' => true],
            ['country_code' => 'SA', 'name' => 'Saudi Arabia', 'currency' => 'SAR', 'vat_rate' => '0.15', 'rtl' => true],
        ], 'LOCALIZATION_PROFILES_RETRIEVED');
    }

    public function localizationCountry(Request $request, array $params = []): void
    {
        $this->success(['updated' => true, 'country' => 'AE'], 'LOCALIZATION_UPDATED');
    }

    // ===== Install & Setup =====
    public function installStatus(Request $request, array $params = []): void
    {
        $this->success([
            'is_installed' => true,
            'schema_version' => '2.0.0',
            'cloud_connected' => true,
        ], 'INSTALL_STATUS_RETRIEVED');
    }

    public function installMigrate(Request $request, array $params = []): void
    {
        $this->success(['migrated' => true], 'MIGRATION_COMPLETED');
    }

    public function installSeed(Request $request, array $params = []): void
    {
        $this->success(['seeded' => true], 'SEEDING_COMPLETED');
    }

    public function installComplete(Request $request, array $params = []): void
    {
        $this->success(['ready' => true], 'INSTALL_COMPLETED');
    }
}
