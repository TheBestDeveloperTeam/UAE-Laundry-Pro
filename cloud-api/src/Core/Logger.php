<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Core;

final class Logger
{
    private readonly string $logPath;

    public function __construct(?string $logPath = null)
    {
        $this->logPath = $logPath ?? (dirname(__DIR__, 2) . '/logs');
    }

    public function info(string $message, array $context = []): void
    {
        $this->write('INFO', $message, $context);
    }

    public function warning(string $message, array $context = []): void
    {
        $this->write('WARNING', $message, $context);
    }

    public function error(string $message, array $context = []): void
    {
        $this->write('ERROR', $message, $context);
    }

    public function debug(string $message, array $context = []): void
    {
        $this->write('DEBUG', $message, $context);
    }

    private function write(string $level, string $message, array $context): void
    {
        $dir = rtrim($this->logPath, '/\\');
        if (!is_dir($dir)) {
            @mkdir($dir, 0775, true);
        }

        $date = gmdate('Y-m-d');
        $file = $dir . DIRECTORY_SEPARATOR . "cloud-app-{$date}.log";
        $contextJson = $context !== [] ? ' ' . json_encode($context, JSON_UNESCAPED_UNICODE) : '';
        $line = sprintf("[%s] %s: %s%s\n", gmdate('Y-m-d H:i:s'), $level, $message, $contextJson);
        @file_put_contents($file, $line, FILE_APPEND | LOCK_EX);

        // Maintain legacy cloud.log link/file
        $legacyFile = $dir . DIRECTORY_SEPARATOR . 'cloud.log';
        @file_put_contents($legacyFile, $line, FILE_APPEND | LOCK_EX);

        // Auto-prune log files older than 30 days (1 in 50 writes)
        if (random_int(1, 50) === 1) {
            $this->pruneLogs($dir, 30);
        }
    }

    private function pruneLogs(string $dir, int $daysToKeep): void
    {
        $threshold = time() - ($daysToKeep * 86400);
        $files = glob($dir . DIRECTORY_SEPARATOR . 'cloud-app-*.log') ?: [];
        foreach ($files as $filePath) {
            if (is_file($filePath) && filemtime($filePath) < $threshold) {
                @unlink($filePath);
            }
        }
    }
}
