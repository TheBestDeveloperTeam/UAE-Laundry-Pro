<?php
declare(strict_types=1);

require_once __DIR__ . '/CredentialLoader.php';

$repoRoot = dirname(__DIR__, 2);
$creds = LaundryPro\Deploy\CredentialLoader::load($repoRoot);
$ftp = $creds['ftp'];

$conn = ftp_connect($ftp['host'], $ftp['port'], 30);
ftp_login($conn, $ftp['username'], $ftp['password']);
ftp_pasv($conn, true);

// Upload a probe directly into ./cloud-api/public/pilot_probe.txt
$probeContent = "PILOT_PROBE_OK_" . time();
$temp = tempnam(sys_get_temp_dir(), 'probe');
file_put_contents($temp, $probeContent);

$res = ftp_put($conn, './cloud-api/public/pilot_probe.txt', $temp, FTP_BINARY);
unlink($temp);
echo "Upload result to ./cloud-api/public/pilot_probe.txt: " . ($res ? "SUCCESS" : "FAILED") . "\n";

ftp_close($conn);
