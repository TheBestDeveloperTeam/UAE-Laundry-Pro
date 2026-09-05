<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

final class BackupService
{
  public function __construct(
    private readonly string $backupDir,
    private readonly string $dbName,
    private readonly string $dbUser,
    private readonly string $dbPass,
    private readonly string $dbHost,
  ) {
  }

  /** @return array<string, mixed> */
  public function run(): array
  {
    if (!is_dir($this->backupDir)) {
      mkdir($this->backupDir, 0775, true);
    }

    $timestamp = gmdate('Ymd_His');
    $sqlFile = rtrim($this->backupDir, '/\\') . DIRECTORY_SEPARATOR . "db_{$timestamp}.sql";
    $zipFile = rtrim($this->backupDir, '/\\') . DIRECTORY_SEPARATOR . "db_{$timestamp}.zip";

    $mysqldump = $this->resolveMysqldump();
    $passArg = $this->dbPass !== '' ? '-p' . escapeshellarg($this->dbPass) : '';
    $cmd = sprintf(
      '%s -h %s -u %s %s %s > %s',
      escapeshellarg($mysqldump),
      escapeshellarg($this->dbHost),
      escapeshellarg($this->dbUser),
      $passArg,
      escapeshellarg($this->dbName),
      escapeshellarg($sqlFile),
    );

    exec($cmd, $output, $code);
    if ($code !== 0 || !is_file($sqlFile)) {
      throw new \RuntimeException('BACKUP_FAILED');
    }

    $checksum = hash_file('sha256', $sqlFile);
    $manifest = $this->buildManifest($sqlFile);

    $zip = new \ZipArchive();
    if ($zip->open($zipFile, \ZipArchive::CREATE) !== true) {
      throw new \RuntimeException('BACKUP_FAILED');
    }
    $zip->addFile($sqlFile, basename($sqlFile));
    $zip->addFromString('manifest.json', json_encode($manifest, JSON_THROW_ON_ERROR));
    $zip->close();
    unlink($sqlFile);

    return [
      'file' => basename($zipFile),
      'path' => $zipFile,
      'created_at' => gmdate('c'),
      'verified' => is_file($zipFile),
      'checksum_sha256' => $checksum,
      'manifest' => $manifest,
    ];
  }

  /** @return array<int, array<string, mixed>> */
  public function history(): array
  {
    if (!is_dir($this->backupDir)) {
      return [];
    }

    $files = glob(rtrim($this->backupDir, '/\\') . DIRECTORY_SEPARATOR . 'db_*.zip') ?: [];
    rsort($files);
    $history = [];
    foreach (array_slice($files, 0, 30) as $file) {
      $history[] = [
        'file' => basename($file),
        'size_bytes' => filesize($file),
        'created_at' => gmdate('c', (int) filemtime($file)),
      ];
    }

    return $history;
  }

  /** @return array<string, mixed> */
  public function verify(?string $file = null): array
  {
    $path = $this->resolveFile($file);
    $zip = new \ZipArchive();
    if ($zip->open($path) !== true) {
      throw new \RuntimeException('BACKUP_INVALID');
    }

    $sqlName = null;
    for ($i = 0; $i < $zip->numFiles; $i++) {
      $name = $zip->getNameIndex($i);
      if (is_string($name) && str_ends_with($name, '.sql')) {
        $sqlName = $name;
        break;
      }
    }

    if ($sqlName === null) {
      $zip->close();
      throw new \RuntimeException('BACKUP_INVALID');
    }

    $sql = $zip->getFromName($sqlName);
    $zip->close();
    if (!is_string($sql) || !str_contains($sql, 'CREATE TABLE')) {
      throw new \RuntimeException('BACKUP_INVALID');
    }

    $manifest = $this->buildManifestFromSql($sql);
    $checksum = hash('sha256', $sql);

    return [
      'file' => basename($path),
      'verified' => true,
      'checksum_sha256' => $checksum,
      'manifest' => $manifest,
    ];
  }

  /** @return array<string, mixed> */
  public function restoreValidate(?string $file = null): array
  {
    $path = $this->resolveFile($file);
    $zip = new \ZipArchive();
    if ($zip->open($path) !== true) {
      throw new \RuntimeException('BACKUP_INVALID');
    }

    $sql = null;
    for ($i = 0; $i < $zip->numFiles; $i++) {
      $name = $zip->getNameIndex($i);
      if (is_string($name) && str_ends_with($name, '.sql')) {
        $sql = $zip->getFromName($name);
        break;
      }
    }
    $zip->close();

    if (!is_string($sql)) {
      throw new \RuntimeException('BACKUP_INVALID');
    }

    $statements = $this->countStatements($sql);
    $manifest = $this->buildManifestFromSql($sql);

    return [
      'file' => basename($path),
      'dry_run' => true,
      'statement_count' => $statements,
      'manifest' => $manifest,
      'compatible' => $statements > 0,
    ];
  }

  /** @return array<string, mixed> */
  public function restore(?string $file, bool $confirm): array
  {
    if (!$confirm) {
      throw new \RuntimeException('CONFIRM_REQUIRED');
    }

    $path = $this->resolveFile($file);
    $zip = new \ZipArchive();
    if ($zip->open($path) !== true) {
      throw new \RuntimeException('BACKUP_INVALID');
    }

    $sql = null;
    for ($i = 0; $i < $zip->numFiles; $i++) {
      $name = $zip->getNameIndex($i);
      if (is_string($name) && str_ends_with($name, '.sql')) {
        $sql = $zip->getFromName($name);
        break;
      }
    }
    $zip->close();

    if (!is_string($sql)) {
      throw new \RuntimeException('BACKUP_INVALID');
    }

    $stagingDb = $this->dbName . '_restore_' . gmdate('YmdHis');
    $mysqldump = $this->resolveMysqldump();
    $passArg = $this->dbPass !== '' ? '-p' . escapeshellarg($this->dbPass) : '';

    $createCmd = sprintf(
      '%s -h %s -u %s %s -e %s',
      escapeshellarg($this->resolveMysql()),
      escapeshellarg($this->dbHost),
      escapeshellarg($this->dbUser),
      $passArg,
      escapeshellarg('CREATE DATABASE IF NOT EXISTS `' . $stagingDb . '`'),
    );
    exec($createCmd, $out, $code);
    if ($code !== 0) {
      throw new \RuntimeException('RESTORE_FAILED');
    }

    $tmpFile = tempnam(sys_get_temp_dir(), 'lp_restore_');
    if ($tmpFile === false) {
      throw new \RuntimeException('RESTORE_FAILED');
    }
    file_put_contents($tmpFile, $sql);

    $importCmd = sprintf(
      '%s -h %s -u %s %s %s < %s',
      escapeshellarg($this->resolveMysql()),
      escapeshellarg($this->dbHost),
      escapeshellarg($this->dbUser),
      $passArg,
      escapeshellarg($stagingDb),
      escapeshellarg($tmpFile),
    );
    exec($importCmd, $out2, $code2);
    unlink($tmpFile);

    if ($code2 !== 0) {
      throw new \RuntimeException('RESTORE_FAILED');
    }

    return [
      'restored_to' => $stagingDb,
      'verified' => true,
      'message_key' => 'backup.restore_staging_success',
    ];
  }

  private function resolveFile(?string $file): string
  {
    if ($file === null || $file === '') {
      $files = glob(rtrim($this->backupDir, '/\\') . DIRECTORY_SEPARATOR . 'db_*.zip') ?: [];
      rsort($files);
      if ($files === []) {
        throw new \RuntimeException('BACKUP_NOT_FOUND');
      }
      return $files[0];
    }

    $path = rtrim($this->backupDir, '/\\') . DIRECTORY_SEPARATOR . basename($file);
    if (!is_file($path)) {
      throw new \RuntimeException('BACKUP_NOT_FOUND');
    }

    return $path;
  }

  /** @return array<string, mixed> */
  private function buildManifest(string $sqlFile): array
  {
    $sql = file_get_contents($sqlFile);
    if (!is_string($sql)) {
      return ['tables' => 0, 'rows_estimate' => 0];
    }

    return $this->buildManifestFromSql($sql);
  }

  /** @return array<string, mixed> */
  private function buildManifestFromSql(string $sql): array
  {
    preg_match_all('/CREATE TABLE(?: IF NOT EXISTS)? `([^`]+)`/i', $sql, $matches);
    $tables = $matches[1] ?? [];
    preg_match_all('/INSERT INTO/i', $sql, $inserts);

    return [
      'tables' => count($tables),
      'table_names' => array_slice($tables, 0, 20),
      'rows_estimate' => count($inserts[0] ?? []),
    ];
  }

  private function countStatements(string $sql): int
  {
    $parts = preg_split('/;\s*\n/', $sql) ?: [];

    return count(array_filter($parts, fn ($p) => trim($p) !== ''));
  }

  private function resolveMysqldump(): string
  {
    $candidates = [
      'E:\\xampp\\mysql\\bin\\mysqldump.exe',
      'C:\\xampp\\mysql\\bin\\mysqldump.exe',
      'mysqldump',
    ];
    foreach ($candidates as $path) {
      if ($path === 'mysqldump' || is_file($path)) {
        return $path;
      }
    }

    return 'mysqldump';
  }

  private function resolveMysql(): string
  {
    $candidates = [
      'E:\\xampp\\mysql\\bin\\mysql.exe',
      'C:\\xampp\\mysql\\bin\\mysql.exe',
      'mysql',
    ];
    foreach ($candidates as $path) {
      if ($path === 'mysql' || is_file($path)) {
        return $path;
      }
    }

    return 'mysql';
  }
}
