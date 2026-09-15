<?php
$file = "api/routes/api.php";
$content = file_get_contents($file);
if (strpos($content, "SterilizationController") === false) {
    $content = str_replace(
        "use LaundryPro\Api\Controllers\StorefrontController;",
        "use LaundryPro\Api\Controllers\StorefrontController;\nuse LaundryPro\Api\Controllers\SterilizationController;",
        $content
    );
    $routes = <<<EOT
  \$router->post("/api/v1/sterilization/batch", [SterilizationController::class, "batchCreate"], \$audit, [
    "tag" => "Sterilization", "summary" => "Create batch", "permission" => "advanced.cycle.run",
    "responses" => ["201" => "BATCH_CREATED"]
  ]);
  \$router->post("/api/v1/sterilization/scan", [SterilizationController::class, "batchScan"], \$audit, [
    "tag" => "Sterilization", "summary" => "Scan batch", "permission" => "advanced.cycle.run",
    "responses" => ["201" => "BATCH_SCANNED"]
  ]);
  \$router->post("/api/v1/sterilization/log", [SterilizationController::class, "logSterilization"], \$audit, [
    "tag" => "Sterilization", "summary" => "Log sterilization", "permission" => "advanced.cycle.run",
    "responses" => ["201" => "LOG_CREATED"]
  ]);
  \$router->post("/api/v1/sterilization/sign", [SterilizationController::class, "signElectronic"], \$audit, [
    "tag" => "Sterilization", "summary" => "Sign electronically", "permission" => "advanced.cycle.run",
    "responses" => ["201" => "SIGNED"]
  ]);
  \$router->get("/api/v1/sterilization/logs/{cycleRunId}", [SterilizationController::class, "listLogs"], \$auth, [
    "tag" => "Sterilization", "summary" => "List logs", "permission" => "advanced.cycle.run",
    "responses" => ["200" => "LOGS_LIST"]
  ]);
}
EOT;
    $content = str_replace("}\n", $routes . "\n}\n", $content);
    file_put_contents($file, $content);
}
echo "Done\n";

