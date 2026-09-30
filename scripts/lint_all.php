<?php

$dirs = ['api', 'cloud-api'];
$errors = 0;
$count = 0;

foreach ($dirs as $dir) {
    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator(__DIR__ . '/../' . $dir));
    foreach ($iterator as $file) {
        if ($file->isFile() && $file->getExtension() === 'php') {
            $count++;
            $path = $file->getPathname();
            $output = [];
            $code = 0;
            exec("E:\\xampp\\php\\php.exe -l " . escapeshellarg($path), $output, $code);
            if ($code !== 0) {
                echo implode("\n", $output) . "\n";
                $errors++;
            }
        }
    }
}

echo "Lint completed: {$count} PHP files checked. Errors: {$errors}\n";
exit($errors === 0 ? 0 : 1);
