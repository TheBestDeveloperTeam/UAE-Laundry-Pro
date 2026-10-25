<?php
declare(strict_types=1);

require_once __DIR__ . '/CredentialLoader.php';

$repoRoot = dirname(__DIR__, 2);
$creds = LaundryPro\Deploy\CredentialLoader::load($repoRoot);
$ftp = $creds['ftp'];

$conn = ftp_connect($ftp['host'], $ftp['port'], 30);
if (!$conn) {
    die("Failed to connect to {$ftp['host']}:{$ftp['port']}\n");
}

if (!ftp_login($conn, $ftp['username'], $ftp['password'])) {
    die("FTP login failed for {$ftp['username']}\n");
}

ftp_pasv($conn, true);
echo "FTP Connected successfully!\n";

$remotePath = $ftp['remote_path'];
echo "Listing {$remotePath}:\n";
$list = ftp_nlist($conn, $remotePath);
if ($list === false) {
    echo "ftp_nlist returned false, trying '.'\n";
    $list = ftp_nlist($conn, '.');
}
print_r($list);

ftp_close($conn);
