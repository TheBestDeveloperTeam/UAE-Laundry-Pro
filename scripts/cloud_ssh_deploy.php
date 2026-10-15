<?php

declare(strict_types=1);

/**
 * Build cPanel package locally, upload via scp/Posh-SSH, run server apply_release.php.
 *
 * Usage:
 *   php scripts/cloud_ssh_deploy.php [--dry-run] [--skip-build] [--verify-only] [--skip-ssh-check]
 */

require_once __DIR__ . '/cloud_deploy/CredentialLoader.php';

use LaundryPro\Deploy\CredentialLoader;

$repoRoot = dirname(__DIR__);
$dryRun = in_array('--dry-run', $argv ?? [], true);
$skipBuild = in_array('--skip-build', $argv ?? [], true);
$verifyOnly = in_array('--verify-only', $argv ?? [], true);
$skipSshCheck = in_array('--skip-ssh-check', $argv ?? [], true);

$creds = CredentialLoader::load($repoRoot);
$host = $creds['host'];
$port = (int) $creds['port'];
$user = $creds['username'];
$password = $creds['password'];
$remoteHome = $creds['remote_home'];
$identity = $creds['identity_file'];
$healthUrl = $creds['health_url'];

$remoteSshPs1 = $repoRoot . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'cloud_deploy' . DIRECTORY_SEPARATOR . 'remote_ssh.ps1';

if ($verifyOnly) {
    runHealthCheck($healthUrl);
    $verifyIdentity = $identity !== null && $identity !== '' && is_file($identity);
    $verifyEncrypted = $verifyIdentity && isEncryptedOpenSshKey($identity);
    $verifyKey = $verifyIdentity && !$verifyEncrypted;
    $verifyPassword = ($password !== null && $password !== '') && !$verifyKey;
    if ($verifyPassword) {
        runRemoteLogsPassword($remoteSshPs1, $host, $port, $user, $password, $remoteHome, $dryRun);
    } elseif ($verifyKey) {
        runRemoteLogsOpenSsh($host, $port, $user, $identity, $remoteHome, $dryRun);
    }
    exit(0);
}

$hasIdentity = $identity !== null && $identity !== '' && is_file($identity);
$keyEncrypted = $hasIdentity && isEncryptedOpenSshKey($identity);
$hasPassword = $password !== null && $password !== '';
$useKeyAuth = $hasIdentity && !$keyEncrypted;
$usePasswordAuth = !$useKeyAuth && $hasPassword;
if ($keyEncrypted && $hasPassword) {
    fwrite(STDERR, "Note: SSH key is passphrase-protected; using password auth (Posh-SSH) for non-interactive deploy.\n");
} elseif ($keyEncrypted && !$hasPassword) {
    fwrite(STDERR, "SSH key is encrypted. Re-export OpenSSH key with empty passphrase or add password to .ssh-credentials-details.\n");
    exit(1);
}

if (!$dryRun && !$verifyOnly && !$skipSshCheck) {
    $testPs1 = $repoRoot . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'cloud_deploy' . DIRECTORY_SEPARATOR . 'test_connections.ps1';
    if (!is_file($testPs1)) {
        fwrite(STDERR, "Missing {$testPs1}\n");
        exit(1);
    }
    echo "Running SSH connectivity test ...\n";
    $testCmd = 'powershell -NoProfile -ExecutionPolicy Bypass -File ' . escapeshellarg($testPs1);
    passthru($testCmd, $testCode);
    if ($testCode !== 0) {
        printSshFailureChecklist();
        exit($testCode);
    }
}

$zipLocal = $repoRoot . DIRECTORY_SEPARATOR . 'dist' . DIRECTORY_SEPARATOR . 'cloud-cpanel-upload.zip';
$buildScript = $repoRoot . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'build_cloud_cpanel.ps1';

if (!$skipBuild && !$dryRun) {
    echo "Building cloud-cpanel-upload.zip ...\n";
    $ps = 'powershell -NoProfile -ExecutionPolicy Bypass -File ' . escapeshellarg($buildScript);
    passthru($ps, $code);
    if ($code !== 0 || !is_file($zipLocal)) {
        fwrite(STDERR, "Build failed or zip missing at {$zipLocal}\n");
        exit(1);
    }
} elseif ($dryRun && !$skipBuild) {
    echo "[dry-run] powershell -File {$buildScript}\n";
} elseif (!is_file($zipLocal) && !$dryRun) {
    fwrite(STDERR, "Missing {$zipLocal}; run without --skip-build\n");
    exit(1);
}

$remoteStaging = CredentialLoader::toRemotePath($remoteHome, 'deploy_staging');
$remoteZip = CredentialLoader::toRemotePath($remoteHome, 'deploy_staging/cloud-cpanel-upload.zip');
$remoteApply = 'cd ' . escapeshellarg($remoteHome)
    . ' && php cloud-api/scripts/automation/apply_release.php'
    . ' --root=' . escapeshellarg($remoteHome)
    . ' --package=deploy_staging/cloud-cpanel-upload.zip';

if ($usePasswordAuth) {
    if (!is_file($remoteSshPs1)) {
        fwrite(STDERR, "Missing {$remoteSshPs1}\n");
        exit(1);
    }
    $steps = [
        ['mkdir', $remoteStaging, ''],
        ['upload', $remoteZip, $zipLocal],
        ['exec', '', $remoteApply],
    ];
    foreach ($steps as [$action, $remotePath, $localOrCmd]) {
        $label = "Posh-SSH {$action} {$remotePath}";
        echo ($dryRun ? '[dry-run] ' : '') . $label . "\n";
        if ($dryRun) {
            continue;
        }
        $psArgs = [
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $remoteSshPs1,
            '-Action', $action,
            '-HostName', $host,
            '-Port', (string) $port,
            '-UserName', $user,
            '-Password', $password,
        ];
        if ($action === 'mkdir') {
            $psArgs = array_merge($psArgs, ['-RemotePath', $remotePath]);
        } elseif ($action === 'upload') {
            $psArgs = array_merge($psArgs, ['-LocalPath', $localOrCmd, '-RemotePath', $remotePath]);
        } else {
            $psArgs = array_merge($psArgs, ['-RemoteCommand', $localOrCmd]);
        }
        $cmd = 'powershell ' . implode(' ', array_map('escapeshellarg', $psArgs));
        passthru($cmd, $exitCode);
        if ($exitCode !== 0) {
            fwrite(STDERR, "Command failed (exit {$exitCode})\n");
            exit($exitCode);
        }
    }
} elseif ($useKeyAuth) {
    $sshTarget = $user . '@' . $host;
    $sshBase = ['ssh', '-p', (string) $port, '-o', 'StrictHostKeyChecking=accept-new', '-i', $identity, '-o', 'BatchMode=yes'];
    $scpBase = ['scp', '-P', (string) $port, '-o', 'StrictHostKeyChecking=accept-new', '-i', $identity, '-o', 'BatchMode=yes'];

    $mkdirCmd = 'mkdir -p ' . escapeshellarg($remoteStaging);
    $scpTarget = CredentialLoader::scpTarget($sshTarget, $remoteHome, 'deploy_staging/cloud-cpanel-upload.zip');

    $steps = [
        array_merge($sshBase, [$sshTarget, $mkdirCmd]),
        array_merge($scpBase, [$zipLocal, $scpTarget]),
        array_merge($sshBase, [$sshTarget, $remoteApply]),
    ];
    foreach ($steps as $cmd) {
        $parts = array_map('escapeshellarg', $cmd);
        $line = implode(' ', $parts);
        echo ($dryRun ? '[dry-run] ' : '') . $line . "\n";
        if (!$dryRun) {
            passthru($line, $exitCode);
            if ($exitCode !== 0) {
                fwrite(STDERR, "Command failed (exit {$exitCode})\n");
                exit($exitCode);
            }
        }
    }
} else {
    fwrite(STDERR, "No SSH auth: set identity_file in credentials.ini or password in .ssh-credentials-details\n");
    exit(1);
}

if (!$dryRun) {
    runHealthCheck($healthUrl);
    if ($usePasswordAuth) {
        runRemoteLogsPassword($remoteSshPs1, $host, $port, $user, $password, $remoteHome, false);
    } elseif ($useKeyAuth) {
        runRemoteLogsOpenSsh($host, $port, $user, $identity, $remoteHome, false);
    }
}

echo "\nVerify: {$healthUrl}\n";
echo "WARNING: Each apply runs deploy.php --fresh (all cloud DB tables dropped).\n";

function printSshFailureChecklist(): void
{
    fwrite(STDERR, "\nDeploy aborted: no working shell SSH.\n");
    fwrite(STDERR, "  1. cPanel → enable SSH Access for cloud-laudry-pro-ssh\n");
    fwrite(STDERR, "  2. Authorize .pub: scripts/cloud_deploy/generate_deploy_keys.ps1\n");
    fwrite(STDERR, "  3. Fix host/port in scripts/cloud_deploy/credentials.ini\n");
    fwrite(STDERR, "  4. Diagnose: scripts/cloud_deploy/test_connections.ps1\n");
    fwrite(STDERR, "  FTP/SFTP cannot run deploy.php --fresh; shell SSH is required.\n");
}

function isEncryptedOpenSshKey(string $path): bool
{
    $head = @file_get_contents($path, false, null, 0, 800);
    if ($head === false) {
        return false;
    }

    return str_contains($head, 'ENCRYPTED')
        || str_contains($head, 'aes256-ctr')
        || str_contains($head, 'bcrypt')
        || str_contains($head, 'YmNyeXB0');
}

function runHealthCheck(string $healthUrl): void
{
    echo "\n--- Health check ---\n";
    $ctx = stream_context_create(['http' => ['timeout' => 60], 'ssl' => ['verify_peer' => true]]);
    $body = @file_get_contents($healthUrl, false, $ctx);
    if ($body === false) {
        fwrite(STDERR, "Health request failed: {$healthUrl}\n");
        return;
    }
    echo $body . "\n";
}

function runRemoteLogsPassword(
    string $remoteSshPs1,
    string $host,
    int $port,
    string $user,
    string $password,
    string $remoteHome,
    bool $dryRun
): void {
    $tailCmd = 'cd ' . escapeshellarg($remoteHome)
        . ' && (tail -n 80 cloud-api/logs/*.log 2>/dev/null || ls -la cloud-api/logs 2>/dev/null || echo no_logs)';
    echo "\n--- Remote logs ---\n";
    if ($dryRun) {
        echo "[dry-run] Posh-SSH exec tail logs\n";
        return;
    }
    $psArgs = [
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $remoteSshPs1,
        '-Action', 'exec', '-HostName', $host, '-Port', (string) $port,
        '-UserName', $user, '-Password', $password, '-RemoteCommand', $tailCmd,
    ];
    passthru('powershell ' . implode(' ', array_map('escapeshellarg', $psArgs)), $code);
    if ($code !== 0) {
        fwrite(STDERR, "Log tail failed (exit {$code})\n");
    }
}

function runRemoteLogsOpenSsh(
    string $host,
    int $port,
    string $user,
    string $identity,
    string $remoteHome,
    bool $dryRun
): void {
    $tailCmd = 'cd ' . escapeshellarg($remoteHome)
        . ' && (tail -n 80 cloud-api/logs/*.log 2>/dev/null || ls -la cloud-api/logs 2>/dev/null || echo no_logs)';
    echo "\n--- Remote logs ---\n";
    $line = implode(' ', array_map('escapeshellarg', [
        'ssh', '-p', (string) $port, '-o', 'StrictHostKeyChecking=accept-new',
        '-i', $identity, '-o', 'BatchMode=yes', $user . '@' . $host, $tailCmd,
    ]));
    if ($dryRun) {
        echo "[dry-run] {$line}\n";
        return;
    }
    passthru($line, $code);
}
