<?php

declare(strict_types=1);

namespace LaundryPro\Api\Security;

final class PermissionChecker
{
  /** @param array<int, string> $permissions */
  public function has(array $permissions, string $required): bool
  {
    if (in_array('*', $permissions, true)) {
      return true;
    }

    if (in_array($required, $permissions, true)) {
      return true;
    }

    $parts = explode('.', $required);
    while (count($parts) > 1) {
      array_pop($parts);
      $wildcard = implode('.', $parts) . '.*';
      if (in_array($wildcard, $permissions, true)) {
        return true;
      }
    }

    return false;
  }
}
