<?php

declare(strict_types=1);

namespace LaundryPro\Api\Security;

final class UmacService
{
  public function generate(): string
  {
    $parts = [];
    if (PHP_OS_FAMILY === 'Windows') {
      $mac = shell_exec('getmac /fo csv /nh');
      if (is_string($mac)) {
        $parts[] = trim(explode(',', $mac)[0] ?? '', '"');
      }
    }

    $parts[] = php_uname('n');
    $parts[] = php_uname('m');

    return substr(hash('sha256', implode('|', $parts)), 0, 32);
  }
}
