<?php

declare(strict_types=1);

/**
 * FTP:21 upload + HTTPS deploy apply (no shell SSH).
 *
 * Usage: php scripts/cloud_ftp_deploy.php [--dry-run] [--skip-build] [--verify-only]
 */

require_once __DIR__ . '/cloud_deploy/CredentialLoader.php';
require_once __DIR__ . '/cloud_deploy/DeployPaths.php';

use LaundryPro\Deploy\CredentialLoader;
use LaundryPro\Deploy\DeployPaths;

$repoRoot = dirname(__DIR__);
$dryRun = in_array('--dry-run', $argv ?? [], true);
$skipBuild = in_array('--skip-build', $argv ?? [], true);
$verifyOnly = in_array('--verify-only', $argv ?? [], true);

$creds = CredentialLoader::load($repoRoot);
$ftp = $creds['ftp'];
$paths = $creds['deploy_paths'];
$token = $creds['deploy_automation_token'] ?? '';
$applyUrl = $creds['deploy_apply_url'] ?? '';
$logsUrl = $creds['deploy_logs_url'] ?? '';
$healthUrl = $creds['health_url'];
$bootstrapUrl = $paths->bootstrapApplyUrl($applyUrl);
$bootstrapFallbackUrl = $paths->bootstrapApplyUrlFallback($applyUrl);

if ($ftp['remote_path'] === '' && $paths->deployRoot() !== '') {
    $ftp['remote_path'] = $paths->deployRoot();
}

foreach ($paths->alignmentWarnings($ftp['remote_path'], $creds['remote_home']) as $warn) {
    fwrite(STDERR, "Path map warning: {$warn}\n");
}

$remoteFtpPs1 = $repoRoot . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'cloud_deploy' . DIRECTORY_SEPARATOR . 'remote_ftp.ps1';
$zipLocal = $repoRoot . DIRECTORY_SEPARATOR . 'dist' . DIRECTORY_SEPARATOR . 'cloud-cpanel-upload.zip';
$buildScript = $repoRoot . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'build_cloud_cpanel.ps1';
$packageRel = 'deploy_staging/cloud-cpanel-upload.zip';

if ($verifyOnly) {
    runPathAlignmentCheck($repoRoot, $paths, $healthUrl);
    if ($token !== '') {
        httpDeployLogs($logsUrl, $token);
    }
    exit(0);
}

if ($ftp['host'] === '' || $ftp['username'] === '' || $ftp['password'] === null || $ftp['password'] === '') {
    fwrite(STDERR, "FTP credentials missing (ftp_host, ftp_username, ftp_password in credentials.ini or FTP section of .ssh-credentials-details)\n");
    exit(1);
}

if ($token === '') {
    fwrite(STDERR, "Set deploy_automation_token in credentials.ini (must match DEPLOY_AUTOMATION_TOKEN in cloud-api/.env on server)\n");
    exit(1);
}

if (!$skipBuild && !$dryRun) {
    echo "Building cloud-cpanel-upload.zip ...\n";
    $ps = 'powershell -NoProfile -ExecutionPolicy Bypass -File ' . escapeshellarg($buildScript);
    passthru($ps, $code);
    if ($code !== 0 || !is_file($zipLocal)) {
        fwrite(STDERR, "Build failed or zip missing\n");
        exit(1);
    }
} elseif ($dryRun && !$skipBuild) {
    echo "[dry-run] powershell -File {$buildScript}\n";
} elseif (!is_file($zipLocal) && !$dryRun) {
    fwrite(STDERR, "Missing {$zipLocal}\n");
    exit(1);
}

$ftpArgs = [
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $remoteFtpPs1,
    '-Action', 'upload',
    '-HostName', $ftp['host'],
    '-Port', (string) ($ftp['port'] ?: 21),
    '-UserName', $ftp['username'],
    '-Password', $ftp['password'],
    '-RemoteBasePath', $ftp['remote_path'],
    '-LocalFile', $zipLocal,
    '-RemoteRelativePath', $packageRel,
];

echo ($dryRun ? '[dry-run] ' : '') . "FTP upload {$packageRel}\n";
if (!$dryRun) {
    passthru('powershell ' . implode(' ', array_map('escapeshellarg', $ftpArgs)), $ftpCode);
    if ($ftpCode !== 0) {
        fwrite(STDERR, "FTP upload failed (exit {$ftpCode})\n");
        exit($ftpCode);
    }
}

if (!$dryRun) {
    $envPatch = $repoRoot . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'cloud_deploy' . DIRECTORY_SEPARATOR . 'ftp_patch_server_env_impl.php';
    if (is_file($envPatch)) {
        fwrite(STDERR, "FTP patch cloud-api/.env (deploy token) ...\n");
        $phpBin = defined('PHP_BINARY') && PHP_BINARY !== '' ? PHP_BINARY : 'php';
        passthru(escapeshellarg($phpBin) . ' ' . escapeshellarg($envPatch), $envPatchCode);
        if ($envPatchCode !== 0) {
            fwrite(STDERR, "Warning: .env FTP patch failed (exit {$envPatchCode}); ensure DEPLOY_AUTOMATION_TOKEN on server.\n");
        }
    }
}

$payload = json_encode(['package' => $packageRel], JSON_THROW_ON_ERROR);
echo ($dryRun ? '[dry-run] ' : '') . "POST {$applyUrl}\n";
if (!$dryRun) {
    $applyResult = httpPostJson($applyUrl, $token, $payload);
    echo $applyResult['body'] . "\n";
    if (!httpApplySucceeded($applyResult)) {
        if ($applyResult['code'] === 401) {
            printHttpApplyHelp('401', 'Add DEPLOY_AUTOMATION_TOKEN to server cloud-api/.env (same as deploy_automation_token in credentials.ini).');
            exit(1);
        }
        if ($applyResult['code'] === 404 || responseLooksLikeHtml404($applyResult['body'])) {
            fwrite(STDERR, "API route missing; uploading bootstrap (.htaccess, lp_deploy_apply, ReleaseAutomation) ...\n");
            uploadBootstrapFiles($remoteFtpPs1, $ftp, $repoRoot, $paths);
            $applyResult = postBootstrapApply($bootstrapUrl, $bootstrapFallbackUrl, $token, $payload);
            echo $applyResult['body'] . "\n";
        }
        if (!httpApplySucceeded($applyResult)) {
            if ($applyResult['code'] === 401) {
                printHttpApplyHelp('401', 'Token missing or wrong in cloud-api/.env.');
            } elseif ($applyResult['code'] === 404 || responseLooksLikeHtml404($applyResult['body'])) {
                printHttpApplyHelp(
                    '404',
                    'Extract deploy_staging/cloud-cpanel-upload.zip in cPanel File Manager (subdomain root), or fix document root to {remote_home}/cloud-api/public so FTP and HTTP use the same tree. See deployment.md §12.'
                );
            } else {
                fwrite(STDERR, "Deploy apply HTTP {$applyResult['code']}\n");
            }
            exit(1);
        }
    }
}

if (!$dryRun) {
    httpDeployLogs($logsUrl, $token);
    $logDir = $repoRoot . DIRECTORY_SEPARATOR . 'dist' . DIRECTORY_SEPARATOR . 'cloud-logs';
    $dlArgs = [
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $remoteFtpPs1,
        '-Action', 'downloadLogs',
        '-HostName', $ftp['host'],
        '-Port', (string) ($ftp['port'] ?: 21),
        '-UserName', $ftp['username'],
        '-Password', $ftp['password'],
        '-RemoteBasePath', $ftp['remote_path'],
        '-LocalLogDir', $logDir,
    ];
    passthru('powershell ' . implode(' ', array_map('escapeshellarg', $dlArgs)), $dlCode);
    runPathAlignmentCheck($repoRoot, $paths, $healthUrl);
}

echo "\nWARNING: apply runs deploy.php --fresh (all cloud DB tables dropped).\n";

/** @param array{code:int,body:string} $result */
function httpApplySucceeded(array $result): bool
{
    if ($result['code'] < 200 || $result['code'] >= 300) {
        return false;
    }
    if (responseLooksLikeHtml404($result['body'])) {
        return false;
    }

    return true;
}

function responseLooksLikeHtml404(string $body): bool
{
    return str_contains($body, '<h1>404') || str_contains($body, 'Not Found</h1>');
}

function printHttpApplyHelp(string $code, string $hint): void
{
    fwrite(STDERR, "\nDeploy apply failed (HTTP {$code}). {$hint}\n");
}

/** @return array{code:int,body:string} */
function postBootstrapApply(string $primaryUrl, string $fallbackUrl, string $token, string $payload): array
{
    fwrite(STDERR, "POST {$primaryUrl}\n");
    $result = httpPostJson($primaryUrl, $token, $payload);
    if (httpApplySucceeded($result) || $result['code'] === 401) {
        return $result;
    }
    if ($fallbackUrl !== $primaryUrl) {
        fwrite(STDERR, "Bootstrap retry POST {$fallbackUrl}\n");
        $retry = httpPostJson($fallbackUrl, $token, $payload);
        if (httpApplySucceeded($retry) || $retry['code'] === 401) {
            return $retry;
        }

        return $retry['code'] >= $result['code'] ? $retry : $result;
    }

    return $result;
}

/** @return array{code:int,body:string} */
function httpPostJson(string $url, string $token, string $json): array
{
    $ctx = stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => "Content-Type: application/json\r\nX-LaundryPro-Deploy-Token: {$token}\r\n",
            'content' => $json,
            'timeout' => 600,
            'ignore_errors' => true,
        ],
        'ssl' => ['verify_peer' => true],
    ]);
    $body = (string) file_get_contents($url, false, $ctx);
    $code = 0;
    if (isset($http_response_header[0]) && preg_match('#\s(\d{3})\s#', $http_response_header[0], $m)) {
        $code = (int) $m[1];
    }

    return ['code' => $code, 'body' => $body];
}

function httpDeployLogs(string $logsUrl, string $token): void
{
    echo "\n--- Deploy logs (HTTP) ---\n";
    $ctx = stream_context_create([
        'http' => [
            'method' => 'GET',
            'header' => "X-LaundryPro-Deploy-Token: {$token}\r\n",
            'timeout' => 60,
            'ignore_errors' => true,
        ],
        'ssl' => ['verify_peer' => true],
    ]);
    $body = @file_get_contents($logsUrl . '?lines=80', false, $ctx);
    if ($body !== false) {
        echo $body . "\n";
    }
}

/** @param array{host:string,port:int,username:string,password:?string,remote_path:string} $ftp */
function uploadBootstrapFiles(string $remoteFtpPs1, array $ftp, string $repoRoot, DeployPaths $paths): void
{
    $deployRoot = $paths->deployRoot() !== '' ? $paths->deployRoot() : rtrim($ftp['remote_path'], '/');
    $publicBase = $paths->remotePublicRoot();
    $pairs = [
        [$repoRoot . DIRECTORY_SEPARATOR . 'lp_deploy_apply.php', $publicBase, 'lp_deploy_apply.php'],
        [
            $repoRoot . DIRECTORY_SEPARATOR . 'cloud-api' . DIRECTORY_SEPARATOR . 'public' . DIRECTORY_SEPARATOR . '.htaccess',
            $publicBase,
            'rewrite_rules.txt',
        ],
        [
            $repoRoot . DIRECTORY_SEPARATOR . 'cloud-api' . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'automation' . DIRECTORY_SEPARATOR . 'ReleaseAutomation.php',
            $deployRoot,
            'cloud-api/scripts/automation/ReleaseAutomation.php',
        ],
    ];
    if ($paths->isOptionB()) {
        $pairs[] = [$repoRoot . DIRECTORY_SEPARATOR . '.htaccess', $deployRoot, 'rewrite_rules.txt'];
    } else {
        fwrite(STDERR, "Bootstrap: Option A — skipping DEPLOY_ROOT .htaccess upload (docroot is cloud-api/public).\n");
    }
    foreach ($pairs as [$local, $remoteBase, $remoteRel]) {
        if (!is_file($local)) {
            continue;
        }
        ftpUploadFile($remoteFtpPs1, $ftp, $local, $remoteBase, $remoteRel);
    }
    if ($paths->isOptionB()) {
        ftpRenameIfPossible(
            $remoteFtpPs1,
            $ftp,
            $deployRoot,
            'rewrite_rules.txt',
            '.htaccess'
        );
    }
    ftpRenameIfPossible(
        $remoteFtpPs1,
        $ftp,
        $publicBase,
        'rewrite_rules.txt',
        '.htaccess'
    );
}

/** @param array{host:string,port:int,username:string,password:?string,remote_path:string} $ftp */
function ftpUploadFile(string $remoteFtpPs1, array $ftp, string $local, string $remoteBase, string $remoteRel): void
{
    $args = [
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $remoteFtpPs1,
        '-Action', 'upload',
        '-HostName', $ftp['host'],
        '-Port', (string) ($ftp['port'] ?: 21),
        '-UserName', $ftp['username'],
        '-Password', (string) $ftp['password'],
        '-RemoteBasePath', $remoteBase,
        '-LocalFile', $local,
        '-RemoteRelativePath', $remoteRel,
    ];
    passthru('powershell ' . implode(' ', array_map('escapeshellarg', $args)), $code);
}

/** @param array{host:string,port:int,username:string,password:?string,remote_path:string} $ftp */
function ftpRenameIfPossible(string $remoteFtpPs1, array $ftp, string $remoteBase, string $from, string $to): void
{
    $args = [
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $remoteFtpPs1,
        '-Action', 'rename',
        '-HostName', $ftp['host'],
        '-Port', (string) ($ftp['port'] ?: 21),
        '-UserName', $ftp['username'],
        '-Password', (string) $ftp['password'],
        '-RemoteBasePath', $remoteBase,
        '-RemoteRelativePath', $from,
        '-RemoteRenameTo', $to,
    ];
    passthru('powershell ' . implode(' ', array_map('escapeshellarg', $args)), $code);
}

function runHealthCheck(string $healthUrl): void
{
    echo "\n--- Health check ---\n";
    $ctx = stream_context_create(['http' => ['timeout' => 60], 'ssl' => ['verify_peer' => true]]);
    $body = @file_get_contents($healthUrl, false, $ctx);
    if ($body === false) {
        fwrite(STDERR, "Health request failed\n");
        return;
    }
    echo $body . "\n";
}

function runPathAlignmentCheck(string $repoRoot, DeployPaths $paths, string $healthUrl): void
{
    echo "\n--- Path alignment (HTTP probes) ---\n";
    echo 'layout=' . $paths->layout() . ' deploy_root=' . $paths->deployRoot() . ' http_docroot=' . $paths->httpDocroot() . "\n";
    $origin = preg_replace('#/api/v1/health$#', '', $healthUrl) ?: $paths->siteOriginFromApplyUrl('');
    foreach ($paths->httpProbePaths() as $label => $rel) {
        $url = rtrim($origin, '/') . $rel;
        $result = httpGetProbe($url);
        echo sprintf("%s %s -> HTTP %d\n", $label, $url, $result['code']);
        if ($label === 'health_legacy_prefix' && $result['code'] === 301) {
            echo "  (legacy prefix redirect — expected for Option A after .htaccess deploy)\n";
        }
    }

    $verifyPs1 = $repoRoot . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'cloud_deploy' . DIRECTORY_SEPARATOR . 'verify_path_alignment.ps1';
    if (is_file($verifyPs1)) {
        passthru(
            'powershell -NoProfile -ExecutionPolicy Bypass -File ' . escapeshellarg($verifyPs1),
            $code
        );
        if ($code !== 0) {
            fwrite(STDERR, "verify_path_alignment.ps1 exit {$code} (config or health probe failed)\n");
        }
    }

    runHealthCheck($healthUrl);
}

/** @return array{code:int,body:string} */
function httpGetProbe(string $url): array
{
    $ctx = stream_context_create([
        'http' => ['method' => 'GET', 'timeout' => 45, 'ignore_errors' => true],
        'ssl' => ['verify_peer' => true],
    ]);
    $body = (string) @file_get_contents($url, false, $ctx);
    $code = 0;
    if (isset($http_response_header[0]) && preg_match('#\s(\d{3})\s#', $http_response_header[0], $m)) {
        $code = (int) $m[1];
    }

    return ['code' => $code, 'body' => $body];
}
