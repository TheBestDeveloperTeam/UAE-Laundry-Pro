<?php
$token = json_decode(file_get_contents("http://localhost/laundrypro-api/public/api/v1/auth/login", false, stream_context_create([
    "http" => [
        "method" => "POST",
        "header" => "Content-Type: application/json",
        "content" => json_encode(["username" => "admin", "password" => "admin123"])
    ]
])))->data->access_token;

$ch = curl_init("http://localhost/laundrypro-api/public/api/v1/sterilization/batch");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    "lot_number" => "LOT-999",
    "expiry_date" => "2029-12-31",
    "origin_sales_order_id" => 1
]));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Content-Type: application/json",
    "Authorization: Bearer " . $token
]);
$result = curl_exec($ch);
echo "Result:\n" . $result . "\n";

