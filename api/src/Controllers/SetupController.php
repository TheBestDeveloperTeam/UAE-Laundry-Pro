<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use PDO;

class SetupController
{
    public function __construct(private readonly PDO $db)
    {
    }

    /**
     * Step 14: Finalize wizard completion
     */
    public function complete(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) {
            $response->error(401, 'Unauthorized');
            return;
        }

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("UPDATE system_settings SET setting_value = '1' WHERE admin_id = ? AND setting_key = 'onboarding_complete'");
            $stmt->execute([$adminId]);

            // If the row didn't exist, insert it
            if ($stmt->rowCount() === 0) {
                $ins = $this->db->prepare("INSERT INTO system_settings (admin_id, setting_key, setting_value) VALUES (?, 'onboarding_complete', '1')");
                $ins->execute([$adminId]);
            }

            $this->db->commit();
            $response->success(null, 'Setup completed successfully');
        } catch (\Exception $e) {
            $this->db->rollBack();
            $response->error(500, 'Server Error', [$e->getMessage()]);
        }
    }
}
