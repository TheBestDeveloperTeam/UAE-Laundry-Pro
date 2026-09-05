<?php

declare(strict_types=1);

namespace LaundryPro\Api\Helpers;

final class Logger
{
  public function __construct(
    private readonly string $logPath,
  ) {
  }

  public function info(string $message, array $context = []): void
  {
    $this->write('INFO', $message, $context);
  }

  public function error(string $message, array $context = []): void
  {
    $this->write('ERROR', $message, $context);
  }

  private function write(string $level, string $message, array $context): void
  {
    $dir = rtrim($this->logPath, '/\\');
    if (!is_dir($dir)) {
      mkdir($dir, 0775, true);
    }

    $file = $dir . DIRECTORY_SEPARATOR . 'app.log';
    $contextJson = $context !== [] ? ' ' . json_encode($context, JSON_UNESCAPED_UNICODE) : '';
    $line = sprintf("[%s] %s: %s%s\n", gmdate('Y-m-d H:i:s'), $level, $message, $contextJson);
    file_put_contents($file, $line, FILE_APPEND | LOCK_EX);
  }
}
