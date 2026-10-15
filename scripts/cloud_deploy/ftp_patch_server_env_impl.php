<?php

declare(strict_types=1);

require_once __DIR__ . '/CredentialLoader.php';

$c = LaundryPro\Deploy\CredentialLoader::load(dirname(__DIR__, 2));
$f = $c['ftp'];
$token = trim((string) ($c['deploy_automation_token'] ?? ''));
if ($token === '') {
    fwrite(STDERR, "Missing deploy_automation_token in credentials.ini\n");
    exit(1);
}

$ps1 = __DIR__ . '/remote_ftp.ps1';
$paths = $c['deploy_paths'];
$root = $paths->deployRoot() !== '' ? $paths->deployRoot() : rtrim($f['remote_path'], '/');
$remoteRel = 'cloud-api/env_patch.txt';
$localDl = dirname(__DIR__, 2) . '/dist/ftp-probe/server_env';
$localPatch = dirname(__DIR__, 2) . '/dist/ftp-probe/env_patch.txt';

$run = static function (array $args) use ($ps1): int {
    $cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -File ' . escapeshellarg($ps1);
    foreach ($args as $k => $v) {
        if ($v === null || $v === '') {
            continue;
        }
        $cmd .= ' -' . $k . ' ' . escapeshellarg((string) $v);
    }
    passthru($cmd, $code);

    return (int) $code;
};

// Try download existing .env
$code = $run([
    'Action' => 'download',
    'HostName' => $f['host'],
    'Port' => (string) (int) $f['port'],
    'UserName' => $f['username'],
    'Password' => (string) $f['password'],
    'RemoteBasePath' => $root,
    'RemoteRelativePath' => 'cloud-api/.env',
    'LocalFile' => $localDl,
]);

$envBody = '';
if ($code === 0 && is_file($localDl)) {
    $envBody = (string) file_get_contents($localDl);
    echo "Downloaded existing cloud-api/.env (" . strlen($envBody) . " bytes)\n";
} else {
    echo "No downloadable .env (code {$code}); will create patch lines only\n";
    if (is_file($root . '/cloud-api/.env.production.example')) {
        // noop
    }
}

$lines = $envBody === '' ? [] : preg_split("/\r\n|\n|\r/", $envBody);
$out = [];
$seenToken = false;
$seenHttp = false;
foreach ($lines as $line) {
    if (str_starts_with(trim($line), 'DEPLOY_AUTOMATION_TOKEN=')) {
        $out[] = 'DEPLOY_AUTOMATION_TOKEN=' . $token;
        $seenToken = true;
        continue;
    }
    if (str_starts_with(trim($line), 'DEPLOY_HTTP_ENABLED=')) {
        $out[] = 'DEPLOY_HTTP_ENABLED=true';
        $seenHttp = true;
        continue;
    }
    $out[] = $line;
}
if (!$seenToken) {
    $out[] = 'DEPLOY_AUTOMATION_TOKEN=' . $token;
}
if (!$seenHttp) {
    $out[] = 'DEPLOY_HTTP_ENABLED=true';
}
$patch = rtrim(implode("\n", $out)) . "\n";
file_put_contents($localPatch, $patch);

$uploadCode = $run([
    'Action' => 'upload',
    'HostName' => $f['host'],
    'Port' => (string) (int) $f['port'],
    'UserName' => $f['username'],
    'Password' => (string) $f['password'],
    'RemoteBasePath' => $root . '/cloud-api',
    'LocalFile' => $localPatch,
    'RemoteRelativePath' => 'env_patch.txt',
]);
if ($uploadCode !== 0) {
    exit($uploadCode);
}

$renameCode = $run([
    'Action' => 'rename',
    'HostName' => $f['host'],
    'Port' => (string) (int) $f['port'],
    'UserName' => $f['username'],
    'Password' => (string) $f['password'],
    'RemoteBasePath' => $root . '/cloud-api',
    'RemoteRelativePath' => 'env_patch.txt',
    'RemoteRenameTo' => '.env',
]);
if ($renameCode !== 0) {
    fwrite(STDERR, "Rename to .env failed; token may remain in env_patch.txt — rename manually in File Manager.\n");
    exit($renameCode);
}
echo "Server cloud-api/.env updated (DEPLOY_AUTOMATION_TOKEN + DEPLOY_HTTP_ENABLED).\n";
exit(0);
