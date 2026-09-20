# Knowledge: stack_mariadb

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Technology Stack

## Reference

MariaDB 10.4 on XAMPP. InnoDB engine for all tables. utf8mb4_unicode_ci collation. DECIMAL(18,2) for all monetary columns. BIGINT UNSIGNED AUTO_INCREMENT for PKs. Composite indexes for multi-tenant queries (business_owner_id + frequently filtered columns). Foreign keys enforced. Soft delete via is_active TINYINT(1) + deleted_at DATETIME. Audit columns: created_at, updated_at, created_by, updated_by.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |