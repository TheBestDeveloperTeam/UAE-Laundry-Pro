<?php

declare(strict_types=1);

/**
 * Shared release apply logic (CLI + HTTP deploy automation).
 */
final class ReleaseAutomation
{
    private string $automationDir;

    public function __construct(?string $automationDir = null)
    {
        $this->automationDir = $automationDir ?? __DIR__;
    }

    /**
     * @return array{exitCode:int,output:string}
     */
    public function applyPackage(string $deployRoot, string $packageRelativePath): array
    {
        $output = '';
        $append = static function (string $line) use (&$output): void {
            $output .= $line . (str_ends_with($line, "\n") ? '' : "\n");
        };

        $packageRelativePath = ltrim(str_replace('\\', '/', $packageRelativePath), '/');
        if (str_contains($packageRelativePath, '..')) {
            return ['exitCode' => 1, 'output' => "Invalid package path\n"];
        }

        $zipPath = $deployRoot . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $packageRelativePath);
        if (!is_file($zipPath)) {
            return ['exitCode' => 1, 'output' => "Package not found: {$zipPath}\n"];
        }

        $staging = $deployRoot . DIRECTORY_SEPARATOR . 'deploy_staging';
        $extractDir = $staging . DIRECTORY_SEPARATOR . '_extract_' . date('YmdHis');
        $append("Extracting {$zipPath} ...");
        try {
            $this->extractZip($zipPath, $extractDir);
        } catch (Throwable $e) {
            return ['exitCode' => 1, 'output' => $output . $e->getMessage() . "\n"];
        }

        $append("Merging into {$deployRoot} ...");
        try {
            $this->copyMerge($extractDir, $deployRoot, []);
        } catch (Throwable $e) {
            return ['exitCode' => 1, 'output' => $output . $e->getMessage() . "\n"];
        }

        foreach (['cloud-api/logs', 'cloud-api/storage'] as $rel) {
            $dir = $deployRoot . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $rel);
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }
        }

        $append('Pruning stray paths ...');
        $pruneCode = $this->runPhpScript($this->automationDir . '/prune_tree.php', ['--root=' . $deployRoot], $pruneOut);
        $output .= $pruneOut;
        if ($pruneCode !== 0) {
            $this->purgeDir($extractDir);
            return ['exitCode' => $pruneCode, 'output' => $output];
        }

        $append('Running fresh database deploy (REBUILD_CONFIRM=1) ...');
        $deployCode = $this->runPhpScript($this->automationDir . '/run_deploy.php', [], $deployOut);
        $output .= $deployOut;

        $this->purgeDir($extractDir);

        return ['exitCode' => $deployCode, 'output' => $output];
    }

    /** @return array{exitCode:int,output:string} */
    public static function tailLogs(string $deployRoot, int $lines = 80): array
    {
        $logDir = $deployRoot . DIRECTORY_SEPARATOR . 'cloud-api' . DIRECTORY_SEPARATOR . 'logs';
        if (!is_dir($logDir)) {
            return ['exitCode' => 0, 'output' => 'no log directory'];
        }

        $chunks = [];
        foreach (glob($logDir . DIRECTORY_SEPARATOR . '*.log') ?: [] as $file) {
            $content = @file($file, FILE_IGNORE_NEW_LINES);
            if ($content === false) {
                continue;
            }
            $tail = array_slice($content, -$lines);
            $chunks[] = '=== ' . basename($file) . " ===\n" . implode("\n", $tail);
        }

        return [
            'exitCode' => 0,
            'output' => $chunks === [] ? 'no log files' : implode("\n\n", $chunks),
        ];
    }

    public static function writeStatusFile(string $cloudApiDir, array $payload): void
    {
        $storage = $cloudApiDir . DIRECTORY_SEPARATOR . 'storage';
        if (!is_dir($storage)) {
            mkdir($storage, 0755, true);
        }
        $payload['updated_at'] = gmdate('c');
        file_put_contents($storage . DIRECTORY_SEPARATOR . 'deploy_last.json', json_encode($payload, JSON_PRETTY_PRINT));
    }

    private function extractZip(string $zipPath, string $destDir): void
    {
        if (!is_dir($destDir) && !mkdir($destDir, 0755, true) && !is_dir($destDir)) {
            throw new RuntimeException('Cannot create extract dir: ' . $destDir);
        }

        if (class_exists(ZipArchive::class)) {
            $zip = new ZipArchive();
            if ($zip->open($zipPath) === true) {
                $zip->extractTo($destDir);
                $zip->close();

                return;
            }
        }

        $unzip = trim((string) shell_exec('which unzip 2>/dev/null') ?: '');
        if ($unzip !== '') {
            $cmd = 'unzip -o ' . escapeshellarg($zipPath) . ' -d ' . escapeshellarg($destDir);
            passthru($cmd, $code);
            if ($code === 0) {
                return;
            }
        }

        throw new RuntimeException('Cannot extract zip (need php-zip or unzip): ' . $zipPath);
    }

    /** @param list<string> $skipBasenames */
    private function copyMerge(string $source, string $destination, array $skipBasenames): void
    {
        if (!is_dir($source)) {
            throw new RuntimeException('Source missing: ' . $source);
        }
        if (!is_dir($destination) && !mkdir($destination, 0755, true) && !is_dir($destination)) {
            throw new RuntimeException('Cannot create: ' . $destination);
        }

        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($source, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::SELF_FIRST
        );

        foreach ($iterator as $item) {
            $subPath = $iterator->getSubPathName();
            $subPathNorm = str_replace('\\', '/', $subPath);
            $base = basename($subPathNorm);
            if (in_array($base, $skipBasenames, true)) {
                continue;
            }
            if (str_ends_with($subPathNorm, 'cloud-api/.env') || str_ends_with($subPathNorm, '.env')) {
                $targetFile = $destination . DIRECTORY_SEPARATOR . $subPath;
                if (is_file($targetFile)) {
                    continue;
                }
            }

            $target = $destination . DIRECTORY_SEPARATOR . $subPath;
            if ($item->isDir()) {
                if (!is_dir($target) && !mkdir($target, 0755, true) && !is_dir($target)) {
                    throw new RuntimeException('Cannot mkdir: ' . $target);
                }
            } else {
                $parent = dirname($target);
                if (!is_dir($parent) && !mkdir($parent, 0755, true) && !is_dir($parent)) {
                    throw new RuntimeException('Cannot mkdir: ' . $parent);
                }
                if (!copy($item->getPathname(), $target)) {
                    throw new RuntimeException('Copy failed: ' . $item->getPathname());
                }
            }
        }
    }

    /** @param list<string> $args */
    private function runPhpScript(string $script, array $args, string &$captured): int
    {
        $php = PHP_BINARY ?: 'php';
        $cmd = escapeshellarg($php) . ' ' . escapeshellarg($script);
        foreach ($args as $arg) {
            $cmd .= ' ' . escapeshellarg($arg);
        }
        ob_start();
        passthru($cmd, $code);
        $captured = (string) ob_get_clean();

        return $code;
    }

    private function purgeDir(string $path): void
    {
        if (!is_dir($path)) {
            return;
        }
        $items = scandir($path);
        if ($items === false) {
            return;
        }
        foreach ($items as $item) {
            if ($item === '.' || $item === '..') {
                continue;
            }
            $full = $path . DIRECTORY_SEPARATOR . $item;
            if (is_dir($full)) {
                $this->purgeDir($full);
                rmdir($full);
            } else {
                unlink($full);
            }
        }
        @rmdir($path);
    }
}
