<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Database;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use PDO;

final class AdminPortalController
{
    private function startSession(): void
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }

    private function requireAuth(): array
    {
        $this->startSession();
        if (empty($_SESSION['cloud_super_admin_id'])) {
            Response::redirect('/admin/login');
        }
        return $_SESSION['cloud_super_admin_user'] ?? [];
    }

    public function loginView(Request $request): void
    {
        $this->startSession();
        if (!empty($_SESSION['cloud_super_admin_id'])) {
            Response::redirect('/admin');
        }
        $error = $_SESSION['flash_error'] ?? null;
        unset($_SESSION['flash_error']);

        Response::view('auth/login', [
            'pageTitle' => 'Super-Admin Login',
            'error' => $error,
        ], '');
    }

    public function handleLogin(Request $request): void
    {
        $this->startSession();
        $username = trim((string) $request->body('username', ''));
        $password = (string) $request->body('password', '');

        if ($username === '' || $password === '') {
            $_SESSION['flash_error'] = 'Please enter both username and password.';
            Response::redirect('/admin/login');
        }

        $pdo = Database::connect();
        if ($pdo === null) {
            // Fallback development credentials if DB is offline
            if ($username === 'superadmin' && $password === 'SuperAdmin@LaundryPro2026!') {
                $_SESSION['cloud_super_admin_id'] = 1;
                $_SESSION['cloud_super_admin_user'] = [
                    'id' => 1,
                    'username' => 'superadmin',
                    'full_name' => 'Master Super Administrator',
                    'role' => 'super_admin'
                ];
                Response::redirect('/admin');
            }
            $_SESSION['flash_error'] = 'Database connection failure.';
            Response::redirect('/admin/login');
        }

        $stmt = $pdo->prepare('SELECT * FROM cloud_super_admins WHERE username = :u AND is_active = 1 LIMIT 1');
        $stmt->execute(['u' => $username]);
        $user = $stmt->fetch();

        if ($user && password_verify($password, $user['password_hash'])) {
            $_SESSION['cloud_super_admin_id'] = (int) $user['id'];
            $_SESSION['cloud_super_admin_user'] = [
                'id' => (int) $user['id'],
                'username' => $user['username'],
                'full_name' => $user['full_name'],
                'role' => $user['role'],
            ];

            $upd = $pdo->prepare('UPDATE cloud_super_admins SET last_login_at = NOW() WHERE id = ?');
            $upd->execute([$user['id']]);

            $audit = $pdo->prepare('INSERT INTO cloud_audit_logs (super_admin_id, action, details, ip_address) VALUES (?, ?, ?, ?)');
            $audit->execute([$user['id'], 'SUPER_ADMIN_LOGIN', 'Successful login', $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1']);

            Response::redirect('/admin');
        }

        $_SESSION['flash_error'] = 'Invalid username or password.';
        Response::redirect('/admin/login');
    }

    public function logout(Request $request): void
    {
        $this->startSession();
        $_SESSION = [];
        session_destroy();
        Response::redirect('/admin/login');
    }

    public function dashboard(Request $request): void
    {
        $user = $this->requireAuth();
        $pdo = Database::connect();

        $stats = [
            'tenants_count' => 0,
            'active_licenses' => 0,
            'sync_records_count' => 0,
            'recent_tenants' => [],
            'recent_sync' => [],
        ];

        if ($pdo !== null) {
            $stats['tenants_count'] = (int) $pdo->query('SELECT COUNT(*) FROM businesses')->fetchColumn();
            $stats['active_licenses'] = (int) $pdo->query('SELECT COUNT(*) FROM cloud_licenses WHERE status = "active"')->fetchColumn();
            $stats['sync_records_count'] = (int) $pdo->query('SELECT COUNT(*) FROM sync_records')->fetchColumn();

            $tStmt = $pdo->query('SELECT * FROM businesses ORDER BY id DESC LIMIT 5');
            $stats['recent_tenants'] = $tStmt->fetchAll() ?: [];

            $sStmt = $pdo->query('SELECT s.*, b.name as business_name FROM sync_records s LEFT JOIN businesses b ON b.id = s.business_owner_id ORDER BY s.id DESC LIMIT 5');
            $stats['recent_sync'] = $sStmt->fetchAll() ?: [];
        }

        Response::view('dashboard/index', [
            'pageTitle' => 'Super-Admin Dashboard',
            'user' => $user,
            'stats' => $stats,
        ]);
    }

    public function tenants(Request $request): void
    {
        $user = $this->requireAuth();
        $pdo = Database::connect();
        $tenants = [];
        if ($pdo !== null) {
            $stmt = $pdo->query('SELECT b.*, (SELECT COUNT(*) FROM sync_records WHERE business_owner_id = b.id) as sync_count FROM businesses b ORDER BY b.id DESC');
            $tenants = $stmt->fetchAll() ?: [];
        }

        Response::view('tenants/index', [
            'pageTitle' => 'Tenant Workstations',
            'user' => $user,
            'tenants' => $tenants,
        ]);
    }

    public function licenses(Request $request): void
    {
        $user = $this->requireAuth();
        $pdo = Database::connect();
        $licenses = [];
        $tenants = [];
        if ($pdo !== null) {
            $licenses = $pdo->query('SELECT l.*, b.name as business_name FROM cloud_licenses l LEFT JOIN businesses b ON b.id = l.tenant_id ORDER BY l.id DESC')->fetchAll() ?: [];
            $tenants = $pdo->query('SELECT id, name FROM businesses ORDER BY name ASC')->fetchAll() ?: [];
        }

        Response::view('licenses/index', [
            'pageTitle' => 'Licenses & Anti-Tamper Keys',
            'user' => $user,
            'licenses' => $licenses,
            'tenants' => $tenants,
        ]);
    }

    public function issueLicense(Request $request): void
    {
        $user = $this->requireAuth();
        $tenantId = (int) $request->body('tenant_id');
        $planType = (string) $request->body('plan_type', 'standard');
        $umac = trim((string) $request->body('umac', ''));
        $days = (int) $request->body('valid_days', 365);

        $pdo = Database::connect();
        if ($pdo !== null && $tenantId > 0) {
            $config = require dirname(__DIR__, 2) . '/config/app.php';
            $masterSecret = $config['license_master_secret'];
            $licenseKey = 'UAE-LP-' . strtoupper(bin2hex(random_bytes(4))) . '-' . strtoupper(bin2hex(random_bytes(4)));
            $expiresAt = date('Y-m-d H:i:s', strtotime("+$days days"));

            // Compute cryptographic signature
            $signaturePayload = json_encode([
                'tenant_id' => $tenantId,
                'license_key' => $licenseKey,
                'umac' => $umac,
                'plan_type' => $planType,
                'expires_at' => $expiresAt,
            ]);
            $signature = hash_hmac('sha256', (string) $signaturePayload, (string) $masterSecret);

            $stmt = $pdo->prepare(
                'INSERT INTO cloud_licenses (tenant_id, license_key, umac_fingerprint, plan_type, status, expires_at, signature, issued_at)
                 VALUES (?, ?, ?, ?, "active", ?, ?, NOW())'
            );
            $stmt->execute([$tenantId, $licenseKey, $umac ?: null, $planType, $expiresAt, $signature]);

            // Update business
            $upd = $pdo->prepare('UPDATE businesses SET license_key = ?, status = "active" WHERE id = ?');
            $upd->execute([$licenseKey, $tenantId]);

            // Audit
            $audit = $pdo->prepare('INSERT INTO cloud_audit_logs (super_admin_id, tenant_id, action, details, ip_address) VALUES (?, ?, ?, ?, ?)');
            $audit->execute([$user['id'], $tenantId, 'LICENSE_ISSUED', "Issued $planType license: $licenseKey", $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1']);
        }

        Response::redirect('/admin/licenses');
    }

    public function revokeLicense(Request $request, array $params): void
    {
        $user = $this->requireAuth();
        $id = (int) ($params['id'] ?? 0);
        $pdo = Database::connect();
        if ($pdo !== null && $id > 0) {
            $stmt = $pdo->prepare('UPDATE cloud_licenses SET status = "revoked" WHERE id = ?');
            $stmt->execute([$id]);

            $audit = $pdo->prepare('INSERT INTO cloud_audit_logs (super_admin_id, action, details, ip_address) VALUES (?, ?, ?, ?)');
            $audit->execute([$user['id'], 'LICENSE_REVOKED', "Revoked license ID $id", $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1']);
        }
        Response::redirect('/admin/licenses');
    }

    public function syncInspector(Request $request): void
    {
        $user = $this->requireAuth();
        $pdo = Database::connect();
        $records = [];
        if ($pdo !== null) {
            $stmt = $pdo->query('SELECT s.*, b.name as business_name FROM sync_records s LEFT JOIN businesses b ON b.id = s.business_owner_id ORDER BY s.id DESC LIMIT 50');
            $records = $stmt->fetchAll() ?: [];
        }

        Response::view('sync/index', [
            'pageTitle' => 'Sync Telemetry & Inspector',
            'user' => $user,
            'records' => $records,
        ]);
    }

    public function audit(Request $request): void
    {
        $user = $this->requireAuth();
        $pdo = Database::connect();
        $logs = [];
        if ($pdo !== null) {
            $stmt = $pdo->query('SELECT a.*, u.username as admin_name, b.name as business_name FROM cloud_audit_logs a LEFT JOIN cloud_super_admins u ON u.id = a.super_admin_id LEFT JOIN businesses b ON b.id = a.tenant_id ORDER BY a.id DESC LIMIT 100');
            $logs = $stmt->fetchAll() ?: [];
        }

        Response::view('audit/index', [
            'pageTitle' => 'Security Audit Trail',
            'user' => $user,
            'logs' => $logs,
        ]);
    }
}
