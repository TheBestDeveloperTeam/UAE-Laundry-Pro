<?php
require 'api/vendor/autoload.php';
require 'api/src/Core/Application.php';
$app = new \LaundryPro\Api\Core\Application('api');
$c = $app->getContainer();
$s = $c->get(\LaundryPro\Api\Repositories\SettingsRepository::class);
try {
  $s->upsert('business.name', 'LaundryPro UAE');
  echo "OK\n";
} catch (\Throwable $e) {
  echo $e->getMessage() . "\n";
}

