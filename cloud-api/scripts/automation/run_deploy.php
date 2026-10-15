<?php

declare(strict_types=1);

/**
 * Always-fresh cloud DB deploy (destructive). Invoked by apply_release.php after file sync.
 */

putenv('REBUILD_CONFIRM=1');
$cloudApi = dirname(__DIR__, 2);
$deployScript = $cloudApi . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'deploy.php';

if (!is_file($deployScript)) {
    fwrite(STDERR, "Missing deploy.php at {$deployScript}\n");
    exit(1);
}

$php = PHP_BINARY ?: 'php';
$cmd = escapeshellarg($php) . ' ' . escapeshellarg($deployScript) . ' --fresh';
echo "Running: {$cmd}\n";
passthru($cmd, $exitCode);
exit($exitCode);
