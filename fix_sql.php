<?php
$f = 'api/database/migrations/002_advanced_module.sql';
$content = file_get_contents($f);
// Remove anything after the last ";" which is where the broken stuff is
$pos = strrpos($content, ');');
if ($pos !== false) {
    $content = substr($content, 0, $pos + 2);
}
$content .= "\n\nALTER TABLE users ADD COLUMN failed_attempts INT UNSIGNED NOT NULL DEFAULT 0, ADD COLUMN locked_until TIMESTAMP NULL DEFAULT NULL;\n";
file_put_contents($f, $content);
