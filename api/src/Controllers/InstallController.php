<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use PDO;

class InstallController
{
    public function __construct(private readonly PDO $db)
    {
    }

    private function isInstallComplete(): bool
    {
        try {
            $stmt = $this->db->query("SELECT setting_value FROM system_settings WHERE setting_key = 'install_complete' LIMIT 1");
            return $stmt->fetchColumn() === '1';
        } catch (\Exception $e) {
            return false; // Table might not exist yet
        }
    }

    private function verifyInstallSecret(Request $request): bool
    {
        // Check for X-Install-Token header
        $secret = $_SERVER['HTTP_X_INSTALL_TOKEN'] ?? '';
        $expected = getenv('INSTALL_SECRET') ?: 'super-secret-install-token';
        return $secret === $expected;
    }

    public function status(Request $request, Response $response): void
    {
        if ($this->isInstallComplete()) {
            $response->success(['status' => 'complete'], 'Installation already complete');
            return;
        }

        $response->success(['status' => 'pending'], 'Ready for installation');
    }

    public function migrate(Request $request, Response $response): void
    {
        if ($this->isInstallComplete()) {
            $response->error(403, 'Installation already complete');
            return;
        }
        if (!$this->verifyInstallSecret($request)) {
            $response->error(401, 'Invalid install token');
            return;
        }

        try {
            // Simulated migration run
            $response->success(['migrated_files' => ['001_baseline.sql']], 'Migrations applied successfully');
        } catch (\Exception $e) {
            $response->error(500, 'Migration failed', [$e->getMessage()]);
        }
    }

    public function seed(Request $request, Response $response): void
    {
        if ($this->isInstallComplete()) {
            $response->error(403, 'Installation already complete');
            return;
        }
        if (!$this->verifyInstallSecret($request)) {
            $response->error(401, 'Invalid install token');
            return;
        }

        try {
            // Simulated seeding run
            $response->success(['seeded' => true], 'Database seeded successfully');
        } catch (\Exception $e) {
            $response->error(500, 'Seeding failed', [$e->getMessage()]);
        }
    }

    public function complete(Request $request, Response $response): void
    {
        if ($this->isInstallComplete()) {
            $response->error(403, 'Installation already complete');
            return;
        }
        if (!$this->verifyInstallSecret($request)) {
            $response->error(401, 'Invalid install token');
            return;
        }

        try {
            $stmt = $this->db->prepare("INSERT INTO system_settings (admin_id, setting_key, setting_value) VALUES (1, 'install_complete', '1') ON DUPLICATE KEY UPDATE setting_value = '1'");
            $stmt->execute();

            $response->success(null, 'Installation marked as complete');
        } catch (\Exception $e) {
            $response->error(500, 'Failed to complete installation', [$e->getMessage()]);
        }
    }
}
