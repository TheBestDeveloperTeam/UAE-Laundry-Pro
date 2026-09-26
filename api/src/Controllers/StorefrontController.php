<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use PDO;

class StorefrontController
{
    public function __construct(private readonly PDO $db)
    {
    }

    /**
     * Public catalog, no auth required, just requires admin identifier in query or header
     */
    public function getCatalog(Request $request, Response $response): void
    {
        $adminId = $_GET['admin_id'] ?? null;
        if (!$adminId) {
            $response->error(400, 'Admin ID is required for public storefront');
            return;
        }

        $stmt = $this->db->prepare("SELECT id, name, category, price, is_active FROM services WHERE admin_id = ? AND is_active = 1");
        $stmt->execute([(int)$adminId]);
        $services = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $response->success($services, 'Catalog retrieved');
    }

    /**
     * Storefront config (branding, enabled features, contact info)
     */
    public function getConfig(Request $request, Response $response): void
    {
        $adminId = $_GET['admin_id'] ?? null;
        if (!$adminId) {
            $response->error(400, 'Admin ID is required');
            return;
        }

        $stmt = $this->db->prepare("SELECT setting_key, setting_value FROM system_settings WHERE admin_id = ? AND setting_key IN ('business_name', 'logo_url', 'contact_email', 'contact_phone', 'storefront_enabled')");
        $stmt->execute([(int)$adminId]);
        $settings = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);

        if (($settings['storefront_enabled'] ?? '0') !== '1') {
            $response->error(403, 'Storefront is not enabled for this business');
            return;
        }

        $response->success($settings, 'Config retrieved');
    }
}
