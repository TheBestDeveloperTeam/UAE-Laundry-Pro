<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/src/Core/Money.php';
require_once dirname(__DIR__) . '/src/Core/Uuid.php';
require_once dirname(__DIR__) . '/src/Core/EventBus.php';
require_once dirname(__DIR__) . '/src/Core/Validator.php';

use LaundryPro\Api\Core\Money;
use LaundryPro\Api\Core\Uuid;
use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Validator;

$passed = 0;
$failed = 0;

function assertTest(bool $condition, string $message) {
    global $passed, $failed;
    if ($condition) {
        $passed++;
        echo "[PASS] $message\n";
    } else {
        $failed++;
        echo "[FAIL] $message\n";
    }
}

echo "=== Running Phase 0 Core Unit Tests ===\n";

// 1. Money tests
try {
    $m1 = new Money("100.50");
    $m2 = new Money("50.25");
    $sum = $m1->add($m2);
    assertTest($sum->getAmount() === "150.75", "Money addition");

    $sub = $m1->subtract($m2);
    assertTest($sub->getAmount() === "50.25", "Money subtraction");

    $mul = $m1->multiply("2");
    assertTest($mul->getAmount() === "201.00", "Money multiplication");

    $div = $m1->divide("2");
    assertTest($div->getAmount() === "50.25", "Money division");

    assertTest($m1->greaterThan($m2), "Money greaterThan");
} catch (Exception $e) {
    assertTest(false, "Money tests threw exception: " . $e->getMessage());
}

// 2. Uuid tests
try {
    $uuid1 = Uuid::v4();
    $uuid2 = Uuid::v4();
    assertTest(preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i', $uuid1) === 1, "UUID format valid");
    assertTest($uuid1 !== $uuid2, "UUIDs are unique");
} catch (Exception $e) {
    assertTest(false, "Uuid tests threw exception: " . $e->getMessage());
}

// 3. EventBus tests
try {
    $bus = new EventBus();
    $triggered = false;
    $bus->subscribe('test_event', function($payload) use (&$triggered) {
        $triggered = $payload === 'success';
    });
    $bus->publish('test_event', 'success');
    assertTest($triggered, "EventBus subscriber triggered");
} catch (Exception $e) {
    assertTest(false, "EventBus tests threw exception: " . $e->getMessage());
}

// 4. Validator tests
try {
    $data = ['name' => 'John', 'age' => 20, 'status' => 'active'];
    $validator = new Validator($data);

    $valid = $validator->validate([
        'name' => 'required|string|max:50',
        'age' => 'numeric|min:18',
        'status' => 'enum:active,inactive'
    ]);
    assertTest($valid === true, "Validator passes valid data");

    $invalidValidator = new Validator(['age' => 15]);
    $invalid = $invalidValidator->validate(['age' => 'numeric|min:18']);
    assertTest($invalid === false, "Validator fails on min rule");
    assertTest(count($invalidValidator->getErrors()) > 0, "Validator populates errors");
} catch (Exception $e) {
    assertTest(false, "Validator tests threw exception: " . $e->getMessage());
}

echo "\nSummary: $passed Passed | $failed Failed\n";
exit($failed > 0 ? 1 : 0);
