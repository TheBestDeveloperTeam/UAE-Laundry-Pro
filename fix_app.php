<?php
$file = "api/src/Core/Application.php";
$content = file_get_contents($file);

if (strpos($content, "SterilizationController") === false) {
    $content = str_replace(
        "use LaundryPro\Api\Controllers\TerminalController;",
        "use LaundryPro\Api\Controllers\TerminalController;\nuse LaundryPro\Api\Controllers\SterilizationController;",
        $content
    );
}
if (strpos($content, "SterilizationRepository") === false) {
    $content = str_replace(
        "use LaundryPro\Api\Repositories\TerminalRepository;",
        "use LaundryPro\Api\Repositories\TerminalRepository;\nuse LaundryPro\Api\Repositories\SterilizationRepository;",
        $content
    );
    
    // add singleton for SterilizationRepository
    $content = str_replace(
        "\$this->container->singleton(TerminalRepository::class, fn(Container \$c) => new TerminalRepository(\$c->pdo()));",
        "\$this->container->singleton(TerminalRepository::class, fn(Container \$c) => new TerminalRepository(\$c->pdo()));\n    \$this->container->singleton(SterilizationRepository::class, fn(Container \$c) => new SterilizationRepository(\$c->pdo()));",
        $content
    );

    // add singleton for SterilizationController
    $content = str_replace(
        "\$this->container->singleton(TerminalController::class, fn(Container \$c) => new TerminalController(\$c->get(TerminalRepository::class)));",
        "\$this->container->singleton(TerminalController::class, fn(Container \$c) => new TerminalController(\$c->get(TerminalRepository::class)));\n    \$this->container->singleton(SterilizationController::class, fn(Container \$c) => new SterilizationController(\$c->get(SterilizationRepository::class)));",
        $content
    );
}

file_put_contents($file, $content);
echo "Done\n";

