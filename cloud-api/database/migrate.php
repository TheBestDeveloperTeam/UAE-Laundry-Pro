<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Database;

use LaundryPro\Cloud\Core\Database;
use PDO;

/**
 * Cloud API Migration Runner
 * 
 * Executes SQL migration files from the migrations/ directory in order.
 * Tracks applied migrations in the schema_migrations table.
 * 
 * Usage:
 *   php cloud-api/database/migrate.php [--fresh]
 *   --fresh  Drop all tables and re-run from scratch (DANGEROUS)
 */
final class MigrationRunner
{
    private PDO $pdo;
    private string $migrationsDir;

    public function __construct(PDO $pdo, string $migrationsDir)
    {
        $this->pdo = $pdo;
        $this->migrationsDir = $migrationsDir;
    }

    public function run(bool $fresh = false): array
    {
        $results = [];

        if ($fresh) {
            $this->dropAllTables();
            $results[] = ['action' => 'FRESH', 'message' => 'All tables dropped'];
        }

        // Ensure schema_migrations table exists
        $this->pdo->exec('
            CREATE TABLE IF NOT EXISTS schema_migrations (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                migration VARCHAR(255) NOT NULL UNIQUE,
                applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ');

        // Get applied migrations
        $applied = [];
        $stmt = $this->pdo->query('SELECT migration FROM schema_migrations ORDER BY migration');
        if ($stmt) {
            $applied = $stmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
        }

        // Find pending migration files
        $files = glob($this->migrationsDir . '/*.sql');
        if ($files === false) {
            $files = [];
        }
        sort($files);

        foreach ($files as $file) {
            $name = basename($file, '.sql');
            if (in_array($name, $applied, true)) {
                $results[] = ['action' => 'SKIP', 'migration' => $name, 'message' => 'Already applied'];
                continue;
            }

            $sql = file_get_contents($file);
            if ($sql === false) {
                $results[] = ['action' => 'ERROR', 'migration' => $name, 'message' => 'Cannot read file'];
                continue;
            }

            try {
                $this->pdo->exec($sql);
                $ins = $this->pdo->prepare('INSERT INTO schema_migrations (migration) VALUES (:m)');
                $ins->execute(['m' => $name]);
                $results[] = ['action' => 'APPLIED', 'migration' => $name, 'message' => 'Success'];
            } catch (\Throwable $e) {
                $results[] = ['action' => 'ERROR', 'migration' => $name, 'message' => $e->getMessage()];
                break; // Stop on first error
            }
        }

        return $results;
    }

    private function dropAllTables(): void
    {
        $this->pdo->exec('SET FOREIGN_KEY_CHECKS = 0');
        $tables = $this->pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
        foreach ($tables as $table) {
            $this->pdo->exec("DROP TABLE IF EXISTS `$table`");
        }
        $this->pdo->exec('SET FOREIGN_KEY_CHECKS = 1');
    }
}

// CLI entrypoint
if (php_sapi_name() === 'cli') {
    require_once dirname(__DIR__) . '/src/Core/Env.php';
    require_once dirname(__DIR__) . '/src/Core/Database.php';

    $envCandidates = [
        dirname(__DIR__) . '/.env',
        dirname(__DIR__) . '/.env.production',
        dirname(__DIR__, 2) . '/.env',
        dirname(__DIR__, 2) . '/.env.production',
    ];
    foreach ($envCandidates as $envCandidate) {
        if (file_exists($envCandidate)) {
            \LaundryPro\Cloud\Core\Env::load($envCandidate);
            break;
        }
    }

    $pdo = Database::connect();
    if ($pdo === null) {
        echo "ERROR: Could not connect to database.\n";
        exit(1);
    }

    $fresh = in_array('--fresh', $argv ?? [], true);
    if ($fresh) {
        echo "⚠️  WARNING: --fresh will DROP ALL TABLES. Continue? [y/N]: ";
        $confirm = trim(fgets(STDIN) ?: '');
        if (strtolower($confirm) !== 'y') {
            echo "Aborted.\n";
            exit(0);
        }
    }

    $runner = new MigrationRunner($pdo, __DIR__ . '/migrations');
    $results = $runner->run($fresh);

    foreach ($results as $r) {
        $icon = match ($r['action']) {
            'APPLIED' => '✅',
            'SKIP'    => '⏭️',
            'ERROR'   => '❌',
            'FRESH'   => '🗑️',
            default   => '  ',
        };
        echo "$icon [{$r['action']}] " . ($r['migration'] ?? '') . " — {$r['message']}\n";
    }

    $appliedCount = count(array_filter($results, fn($r) => $r['action'] === 'APPLIED'));
    echo "\nDone. $appliedCount migration(s) applied.\n";
}
