<?php
declare(strict_types=1);

require_once __DIR__ . '/CredentialLoader.php';

$repoRoot = dirname(__DIR__, 2);
$creds = LaundryPro\Deploy\CredentialLoader::load($repoRoot);
$ftp = $creds['ftp'];

$conn = ftp_connect($ftp['host'], $ftp['port'], 30);
ftp_login($conn, $ftp['username'], $ftp['password']);
ftp_pasv($conn, true);

echo "Initial FTP PWD: " . ftp_pwd($conn) . "\n";
echo "Initial Root Listing:\n";
print_r(ftp_nlist($conn, '.'));

ftp_close($conn);
