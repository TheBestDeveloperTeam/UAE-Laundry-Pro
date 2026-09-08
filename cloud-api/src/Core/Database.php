<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Core;

use PDO;
use PDOException;

final class Database
{
    private static ?PDO $pdo = null;

    public static function connect(): ?PDO
    {
        if (self::$pdo !== null) {
            return self::$pdo;
        }

        $config = require dirname(__DIR__, 2) . '/config/database.php';
        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $config['host'],
            $config['port'],
            $config['database'],
            $config['charset']
        );

        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];

        try {
            self::$pdo = new PDO($dsn, $config['username'], $config['password'], $options);
            return self::$pdo;
        } catch (PDOException $e) {
            // Log error
            $logDir = dirname(__DIR__, 2) . '/logs';
            if (!is_dir($logDir)) {
                @mkdir($logDir, 0775, true);
            }
            @file_put_contents($logDir . '/error.log', date('c') . ' DB Connection Error: ' . $e->getMessage() . PHP_EOL, FILE_APPEND);
            return null;
        }
    }
}
