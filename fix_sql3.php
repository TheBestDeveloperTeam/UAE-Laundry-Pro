<?php
$f = 'api/database/migrations/002_advanced_module.sql';
$c = file_get_contents($f);
$c = preg_replace('/ALTER TABLE users ADD COLUMN failed_attempts.*/s', '', $c);
$c = rtrim($c);
$c .= "\n";
file_put_contents($f, $c);

