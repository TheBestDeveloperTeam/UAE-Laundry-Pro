<?php

declare(strict_types=1);

/**
 * Remove stray top-level deploy-root entries not allowed for cloud hosting.
 * Usage: php prune_tree.php [--root=/path/to/deploy]
 */

function deploy_root_dir(): string
{
    foreach ($GLOBALS['argv'] ?? [] as $arg) {
        if (str_starts_with($arg, '--root=')) {
            return rtrim(substr($arg, 7), '/\\');
        }
    }

    return dirname(__DIR__, 3);
}

function load_manifest(string $automationDir): array
{
    $json = file_get_contents($automationDir . '/manifest.cloud.json');
    if ($json === false) {
        throw new RuntimeException('Cannot read manifest.cloud.json');
    }
    $data = json_decode($json, true, 512, JSON_THROW_ON_ERROR);

    return $data;
}

function delete_path(string $path): void
{
    if (!file_exists($path)) {
        return;
    }
    if (is_file($path) || is_link($path)) {
        unlink($path);

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
        delete_path($path . DIRECTORY_SEPARATOR . $item);
    }
    rmdir($path);
}

$root = deploy_root_dir();
$manifest = load_manifest(__DIR__);
$allow = array_flip($manifest['allow_root_entries'] ?? []);
$protectedPrefixes = $manifest['protected_directory_prefixes'] ?? [];
$pruneNames = $manifest['prune_top_level_globs'] ?? [];

foreach ($pruneNames as $name) {
    $target = $root . DIRECTORY_SEPARATOR . $name;
    if (!file_exists($target)) {
        continue;
    }
    $rel = str_replace('\\', '/', $name);
    foreach ($protectedPrefixes as $prefix) {
        if (str_starts_with($prefix, $rel)) {
            continue 2;
        }
    }
    if (isset($allow[$name])) {
        continue;
    }
    echo "Prune: {$name}\n";
    delete_path($target);
}

echo "Prune complete.\n";
