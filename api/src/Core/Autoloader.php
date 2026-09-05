<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

final class Autoloader
{
  private const PREFIX = 'LaundryPro\\Api\\';

  /** @var array<string, string> */
  private static array $classMap = [];

  public static function register(string $apiRoot): void
  {
    spl_autoload_register(static function (string $class) use ($apiRoot): void {
      self::load($class, $apiRoot);
    });
  }

  private static function load(string $class, string $apiRoot): void
  {
    if (!str_starts_with($class, self::PREFIX)) {
      return;
    }

    if (isset(self::$classMap[$class])) {
      $cached = self::$classMap[$class];
      if (is_file($cached)) {
        require_once $cached;
      }

      return;
    }

    $relative = substr($class, strlen(self::PREFIX));
    $psr4Path = $apiRoot . '/src/' . str_replace('\\', '/', $relative) . '.php';

    if (is_file($psr4Path)) {
      require_once $psr4Path;
      self::$classMap[$class] = $psr4Path;

      return;
    }

    $directory = $apiRoot . '/src/' . str_replace('\\', '/', dirname($relative));
    if (!is_dir($directory)) {
      return;
    }

    $files = glob($directory . '/*.php');
    if ($files === false) {
      return;
    }

    foreach ($files as $file) {
      require_once $file;

      if (class_exists($class, false) || interface_exists($class, false)) {
        self::$classMap[$class] = $file;

        return;
      }
    }
  }
}
