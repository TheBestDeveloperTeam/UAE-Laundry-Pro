<?php
$f = 'api/database/migrations/002_advanced_module.sql';
$c = file_get_contents($f);
// Find the exact pos of the start of the bad stuff:
$bad_pos = strpos($c, "A\x00L\x00T\x00E\x00R");
if ($bad_pos === false) {
    $bad_pos = strpos($c, "A L T E R");
}
if ($bad_pos !== false) {
    $c = substr($c, 0, $bad_pos);
}
// Clean up any trailing whitespace/newlines
$c = rtrim($c);
// Append correct one
$c .= "\n\nALTER TABLE users ADD COLUMN failed_attempts INT UNSIGNED NOT NULL DEFAULT 0, ADD COLUMN locked_until TIMESTAMP NULL DEFAULT NULL;\n";

// Remove BOM
if (substr($c, 0, 3) === "\xEF\xBB\xBF") {
    $c = substr($c, 3);
}

file_put_contents($f, $c);
echo "Fixed\n";
