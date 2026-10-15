<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

$cloudRoot = dirname(__DIR__, 2) . '/cloud-api';
$files = [
    $cloudRoot . '/src/Controllers/DeployAutomationController.php',
    $cloudRoot . '/scripts/automation/ReleaseAutomation.php',
    $cloudRoot . '/database/migrations/003_tenant_settings_inventory_defaults.sql',
];

foreach ($files as $file) {
    if (!is_file($file)) {
        fwrite(STDERR, "Missing expected deploy artifact: {$file}\n");
        exit(1);
    }
}

require_once $cloudRoot . '/scripts/automation/ReleaseAutomation.php';
$engine = new ReleaseAutomation($cloudRoot . '/scripts/automation');
if (!method_exists($engine, 'applyPackage')) {
    fwrite(STDERR, "ReleaseAutomation::applyPackage missing\n");
    exit(1);
}

echo "Deploy automation smoke OK\n";
exit(0);
