<?php
$f = 'api/database/migrations/002_advanced_module.sql';
$c = file_get_contents($f);
$c = rtrim($c);
$c .= "\n\nALTER TABLE sync_outbox ADD COLUMN status ENUM('pending', 'synced', 'failed') NOT NULL DEFAULT 'pending', ADD COLUMN next_retry_at TIMESTAMP NULL DEFAULT NULL;\n";
file_put_contents($f, $c);
