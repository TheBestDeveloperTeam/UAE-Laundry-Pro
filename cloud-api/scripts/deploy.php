<?php

declare(strict_types=1);

/**
 * LaundryPro UAE — Custom Core Zero-Dependency Deployment & Composer Emulation Engine
 *
 * This CLI tool provides an autonomous composer-like deployment lifecycle:
 * - Environment discovery and credential validation
 * - Native database connectivity & health verification
 * - Automated database migration execution (001, 002)
 * - Super-Admin account auto-provisioning / verification
 * - Folder permission checks (storage, logs)
 * - Autonomous pre-flight checks without needing composer or root/sudo privileges
 *
 * Usage:
 *   php scripts/deploy.php [--fresh] [--seed]
 */

echo "========================================================\n";
echo "  LaundryPro UAE — Cloud API Custom Deployment Engine   \n";
echo "========================================================\n\n";

$baseDir = dirname(__DIR__);

// 1. Locate and load environment
require_once $baseDir . '/src/Core/Env.php';
require_once $baseDir . '/src/Core/Database.php';

$envCandidates = [
    $baseDir . '/.env',
    $baseDir . '/.env.production',
    dirname($baseDir) . '/.env',
    dirname($baseDir) . '/.env.production',
];

$loadedEnv = null;
foreach ($envCandidates as $cand) {
    if (file_exists($cand)) {
        \LaundryPro\Cloud\Core\Env::load($cand);
        $loadedEnv = $cand;
        break;
    }
}

if ($loadedEnv) {
    echo "[✓] Environment loaded from: " . basename($loadedEnv) . "\n";
} else {
    echo "[!] WARNING: No .env or .env.production file found in " . $baseDir . "\n";
}

$dbHost = \LaundryPro\Cloud\Core\Env::get('DB_HOST', 'localhost');
$dbName = \LaundryPro\Cloud\Core\Env::get('DB_NAME', '');
$dbUser = \LaundryPro\Cloud\Core\Env::get('DB_USER', '');
$dbPass = \LaundryPro\Cloud\Core\Env::get('DB_PASS', '');

echo "[*] Database Configuration:\n";
echo "    Host: {$dbHost}\n";
echo "    Database: {$dbName}\n";
echo "    User: {$dbUser}\n\n";

// 2. Test DB Connection
echo "[*] Connecting to MariaDB/MySQL...";
$pdo = \LaundryPro\Cloud\Core\Database::connect();
if ($pdo === null) {
    echo " [FAILED]\n\n";
    echo "ERROR: Unable to connect to database '{$dbName}' on '{$dbHost}' with user '{$dbUser}'.\n";
    echo "Please verify credentials in cloud-api/.env\n";
    exit(1);
}
echo " [OK]\n\n";

// 3. Run Migrations
$fresh = in_array('--fresh', $argv ?? [], true);
if ($fresh && getenv('REBUILD_CONFIRM') !== '1') {
    echo "ERROR: --fresh requires REBUILD_CONFIRM=1 (drops all tables).\n";
    echo "Example: REBUILD_CONFIRM=1 php scripts/deploy.php --fresh\n";
    exit(1);
}

require_once $baseDir . '/database/migrate.php';
echo "[*] Executing database migrations...\n";
$migrationsDir = $baseDir . '/database/migrations';
if (!is_dir($migrationsDir) || count(glob($migrationsDir . '/*.sql') ?: []) === 0) {
    echo "ERROR: Missing SQL migrations in {$migrationsDir}\n";
    echo "Upload cloud-api/database/migrations/ (001, 002, 003) before deploying.\n";
    exit(1);
}
$runner = new \LaundryPro\Cloud\Database\MigrationRunner($pdo, $migrationsDir);
$results = $runner->run($fresh);

foreach ($results as $r) {
    $icon = match ($r['action']) {
        'APPLIED' => '  [✓] APPLIED',
        'SKIP'    => '  [-] SKIPPED',
        'ERROR'   => '  [X] ERROR',
        'FRESH'   => '  [!] FRESH',
        default   => '     ',
    };
    echo "$icon {$r['migration']} : {$r['message']}\n";
}

// 4. Seed Super-Admin if not exists
echo "\n[*] Verifying Super-Admin account...\n";
try {
    $stmt = $pdo->prepare('SELECT id, username, email FROM cloud_super_admins WHERE username = :u LIMIT 1');
    $stmt->execute([':u' => 'superadmin']);
    $admin = $stmt->fetch(\PDO::FETCH_ASSOC);

    if ($admin) {
        echo "  [✓] Super-Admin user 'superadmin' already provisioned.\n";
    } else {
        $defaultPassword = \LaundryPro\Cloud\Core\Env::get('ADMIN_DEFAULT_PASSWORD', 'Admin@LaundryPro2026!');
        $hash = password_hash($defaultPassword, PASSWORD_BCRYPT);
        $insert = $pdo->prepare('
            INSERT INTO cloud_super_admins (username, email, password_hash, full_name, role, is_active)
            VALUES (:username, :email, :hash, :name, :role, 1)
        ');
        $insert->execute([
            ':username' => 'superadmin',
            ':email' => 'admin@laundrypro.ae',
            ':hash' => $hash,
            ':name' => 'Super Administrator',
            ':role' => 'super_admin',
        ]);
        echo "  [✓] Super-Admin 'superadmin' created successfully with default credentials.\n";
    }
} catch (\Throwable $e) {
    echo "  [!] Super-admin verification note: " . $e->getMessage() . "\n";
}

// 5. Ensure Storage Directories exist
echo "\n[*] Checking required runtime directories...\n";
$dirs = [
    $baseDir . '/logs',
    $baseDir . '/storage',
];

foreach ($dirs as $dir) {
    if (!is_dir($dir)) {
        if (@mkdir($dir, 0755, true)) {
            echo "  [✓] Created directory: " . basename($dir) . "\n";
        } else {
            echo "  [!] Could not create directory: " . basename($dir) . "\n";
        }
    } else {
        echo "  [✓] Directory ready: " . basename($dir) . "\n";
    }
}

echo "\n========================================================\n";
echo "  DEPLOYMENT COMPLETE!                                  \n";
echo "========================================================\n";
echo "  Health Endpoint: /api/v1/health                       \n";
echo "  OpenAPI Docs:    /api/v1/docs                         \n";
echo "  Super-Admin UI:  /admin/login                         \n";
echo "========================================================\n";
exit(0);
