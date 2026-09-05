<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

use PDO;
use PDOException;

final class PdoFactory
{
  public static function create(array $config): PDO
  {
    $dsn = sprintf(
      'mysql:host=%s;port=%d;dbname=%s;charset=%s',
      $config['host'],
      $config['port'],
      $config['database'],
      $config['charset']
    );

    try {
      $pdo = new PDO($dsn, $config['username'], $config['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
      ]);
    } catch (PDOException $e) {
      throw new PDOException('Database connection failed: ' . $e->getMessage(), (int) $e->getCode(), $e);
    }

    return $pdo;
  }
}
