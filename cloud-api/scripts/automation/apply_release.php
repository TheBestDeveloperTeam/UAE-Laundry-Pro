<?php

declare(strict_types=1);

/**
 * Apply uploaded cloud-cpanel package, prune stray files, run fresh deploy.
 *
 * Usage (from deploy root):
 *   php cloud-api/scripts/automation/apply_release.php --package=deploy_staging/cloud-cpanel-upload.zip
 */

require_once __DIR__ . '/ReleaseAutomation.php';

function deploy_root(): string
{
    foreach ($GLOBALS['argv'] ?? [] as $arg) {
        if (str_starts_with($arg, '--root=')) {
            return rtrim(substr($arg, 7), '/\\');
        }
    }

    return dirname(__DIR__, 3);
}

function parse_package_arg(): string
{
    foreach ($GLOBALS['argv'] ?? [] as $arg) {
        if (str_starts_with($arg, '--package=')) {
            return trim(substr($arg, 10));
        }
    }

    return 'deploy_staging/cloud-cpanel-upload.zip';
}

$root = deploy_root();
$packageRel = parse_package_arg();
$engine = new ReleaseAutomation(__DIR__);
$result = $engine->applyPackage($root, $packageRel);
echo $result['output'];
exit($result['exitCode']);
