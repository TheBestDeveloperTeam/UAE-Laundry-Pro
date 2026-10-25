<?php
declare(strict_types=1);

require_once __DIR__ . '/CredentialLoader.php';

$repoRoot = dirname(__DIR__, 2);
$creds = LaundryPro\Deploy\CredentialLoader::load($repoRoot);
$ftp = $creds['ftp'];

$conn = ftp_connect($ftp['host'], $ftp['port'], 30);
ftp_login($conn, $ftp['username'], $ftp['password']);
ftp_pasv($conn, true);

// Create fresh database setup endpoint directly inside ./cloud-api/public/
$cleanScript = <<<'PHP'
<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$token = $_GET['token'] ?? $_POST['token'] ?? '';
$expectedToken = 'be26f838def26ae9dab013bebfc33d85bd13aeeced708429eef500ac3e75b231';

if (!hash_equals($expectedToken, $token)) {
    http_response_code(403);
    echo json_encode(['success' => false, 'error' => 'UNAUTHORIZED']);
    exit;
}

try {
    spl_autoload_register(function (string $class): void {
        $prefix = 'LaundryPro\\Cloud\\';
        $baseDir = dirname(__DIR__) . '/src/';
        $len = strlen($prefix);
        if (strncmp($prefix, $class, $len) !== 0) {
            return;
        }
        $relativeClass = substr($class, $len);
        $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';
        if (file_exists($file)) {
            require_once $file;
        }
    });

    $envCandidates = [
        dirname(__DIR__) . '/.env',
        dirname(__DIR__) . '/.env.production',
        dirname(__DIR__, 2) . '/.env',
        dirname(__DIR__, 2) . '/.env.production',
    ];
    foreach ($envCandidates as $envCandidate) {
        if (file_exists($envCandidate)) {
            \LaundryPro\Cloud\Core\Env::load($envCandidate);
            break;
        }
    }

    $dbConfig = require dirname(__DIR__) . '/config/database.php';
    $dsn = "mysql:host={$dbConfig['host']};port={$dbConfig['port']};dbname={$dbConfig['database']};charset={$dbConfig['charset']}";
    $pdo = new PDO($dsn, $dbConfig['username'], $dbConfig['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);

    $action = $_GET['action'] ?? 'status';

    if ($action === 'fresh_rebuild') {
        // 1. Disable Foreign Key Checks
        $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

        // 2. Drop all tables cleanly
        $tables = $pdo->query("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'")->fetchAll(PDO::FETCH_NUM);
        $dropped = [];
        foreach ($tables as $t) {
            $tableName = $t[0];
            $pdo->exec("DROP TABLE IF EXISTS `{$tableName}`;");
            $dropped[] = $tableName;
        }

        // 3. Run cloud migrations cleanly
        $migrationsDir = dirname(__DIR__) . '/database/migrations';
        $applied = [];
        if (is_dir($migrationsDir)) {
            $files = glob($migrationsDir . '/*.sql');
            sort($files);
            foreach ($files as $f) {
                $sql = file_get_contents($f);
                if (!empty(trim($sql))) {
                    $pdo->exec($sql);
                    $applied[] = basename($f);
                }
            }
        }

        // 4. Update super admin password
        $superAdminHash = password_hash('Admin@123456', PASSWORD_BCRYPT);
        $stmt = $pdo->prepare("UPDATE cloud_super_admins SET password_hash = ?, is_active = 1 WHERE username = 'superadmin'");
        $stmt->execute([$superAdminHash]);

        // 5. Seed Pilot Production Tenant
        $tokenGen = bin2hex(random_bytes(24));
        $stmtTenant = $pdo->prepare("INSERT INTO businesses (uuid, name, license_key, cloud_token, trade_license_no, contact_email, contact_phone, country_code, city, is_active, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'active')");
        $tenantUuid = 'd3b07384-d113-4a15-b778-1a2b3c4d5e6f';
        $stmtTenant->execute([
            $tenantUuid,
            'Al Rayan Laundry Pro Dubai (Production Pilot)',
            'UAE-LP-PILOT-2026',
            $tokenGen,
            'TRN-100234567800003',
            'ops@alrayanlaundry.ae',
            '+971501234567',
            'AE',
            'Dubai',
        ]);
        $tenantId = (int) $pdo->lastInsertId();

        // 6. Seed Pilot License
        $licenseKey = 'UAE-LP-PILOT-2026';
        $appConfig = require dirname(__DIR__) . '/config/app.php';
        $masterSecret = $appConfig['license_master_secret'] ?? 'master_secret';
        $expiresAt = date('Y-m-d H:i:s', strtotime('+365 days'));
        $sigPayload = json_encode([
            'tenant_id' => $tenantId,
            'license_key' => $licenseKey,
            'plan_type' => 'enterprise',
            'expires_at' => $expiresAt,
        ]);
        $sig = hash_hmac('sha256', (string)$sigPayload, (string)$masterSecret);

        $stmtLic = $pdo->prepare("INSERT INTO cloud_licenses (tenant_id, license_key, plan_type, status, expires_at, signature, issued_at) VALUES (?, ?, 'enterprise', 'active', ?, ?, NOW())");
        $stmtLic->execute([$tenantId, $licenseKey, $expiresAt, $sig]);

        // 7. Re-enable Foreign Key Checks
        $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

        echo json_encode([
            'success' => true,
            'action' => 'fresh_rebuild',
            'dropped_tables' => $dropped,
            'applied_migrations' => $applied,
            'super_admin' => 'superadmin (password updated to Admin@123456)',
            'seeded_pilot_tenant' => [
                'id' => $tenantId,
                'name' => 'Al Rayan Laundry Pro Dubai (Production Pilot)',
                'license_key' => $licenseKey,
                'cloud_token' => $tokenGen,
            ],
            'timestamp' => date('c'),
        ], JSON_PRETTY_PRINT);
        exit;
    }

    $tables = $pdo->query("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'")->fetchAll(PDO::FETCH_NUM);
    $tableCounts = [];
    foreach ($tables as $t) {
        $name = $t[0];
        $count = (int)$pdo->query("SELECT COUNT(*) FROM `{$name}`")->fetchColumn();
        $tableCounts[$name] = $count;
    }

    echo json_encode([
        'success' => true,
        'action' => 'status',
        'database' => $dbConfig['database'],
        'tables_count' => count($tableCounts),
        'tables' => $tableCounts,
        'timestamp' => date('c'),
    ], JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ], JSON_PRETTY_PRINT);
}
PHP;

$temp = tempnam(sys_get_temp_dir(), 'clean');
file_put_contents($temp, $cleanScript);

$uploadOk = ftp_put($conn, './cloud-api/public/lp_cloud_setup.php', $temp, FTP_BINARY);
unlink($temp);
echo "Re-uploaded lp_cloud_setup.php: " . ($uploadOk ? "SUCCESS" : "FAILED") . "\n";

ftp_close($conn);
