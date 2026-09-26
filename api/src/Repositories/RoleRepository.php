<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use LaundryPro\Api\Core\Database;

class RoleRepository
{
    public function __construct(private readonly PDO $db)
    {
    }

    public function getAllRoles(int $adminId): array
    {
        $stmt = $this->db->prepare("SELECT * FROM roles WHERE admin_id = ? OR is_system_default = 1");
        $stmt->execute([$adminId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function createRole(int $adminId, string $name, array $permissions): int
    {
        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("INSERT INTO roles (admin_id, name) VALUES (?, ?)");
            $stmt->execute([$adminId, $name]);
            $roleId = (int)$this->db->lastInsertId();

            if (!empty($permissions)) {
                $placeholders = str_repeat('?,', count($permissions) - 1) . '?';
                $permsQuery = "SELECT id FROM permissions WHERE name IN ($placeholders)";
                $permsStmt = $this->db->prepare($permsQuery);
                $permsStmt->execute($permissions);
                $permIds = $permsStmt->fetchAll(PDO::FETCH_COLUMN);

                $insertPerms = $this->db->prepare("INSERT INTO role_permissions (role_id, permission_id) VALUES (?, ?)");
                foreach ($permIds as $pid) {
                    $insertPerms->execute([$roleId, $pid]);
                }
            }

            $this->db->commit();
            return $roleId;
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    public function deleteRole(int $adminId, int $roleId): void
    {
        // Block delete if users assigned
        $checkStmt = $this->db->prepare("SELECT COUNT(*) FROM users WHERE role_id = ? AND admin_id = ?");
        $checkStmt->execute([$roleId, $adminId]);
        if ($checkStmt->fetchColumn() > 0) {
            throw new \Exception("Cannot delete role: users are assigned to it.");
        }

        $this->db->beginTransaction();
        try {
            $this->db->prepare("DELETE FROM role_permissions WHERE role_id = ?")->execute([$roleId]);
            $this->db->prepare("DELETE FROM roles WHERE id = ? AND admin_id = ?")->execute([$roleId, $adminId]);
            $this->db->commit();
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }
}
