param(
  [string]$BaseUrl = "http://localhost/laundrypro-api/public/api/v1",
  [string]$Username = "admin",
  [string]$Password = "admin123"
)

# Full endpoint paths are required, e.g. /health not just /api/v1

$ErrorActionPreference = "Stop"

Write-Host "Smoke test: GET $BaseUrl/health"
$health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get
$health | ConvertTo-Json -Depth 6

if (-not $health.success) {
  throw "Health check failed"
}

Write-Host "Smoke test: POST $BaseUrl/auth/login"
$loginBody = @{ username = $Username; password = $Password } | ConvertTo-Json
$login = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$login | ConvertTo-Json -Depth 6

if (-not $login.success) {
  throw "Login failed"
}

$token = $login.data.access_token
Write-Host "Smoke test: GET $BaseUrl/auth/me"
$me = Invoke-RestMethod -Uri "$BaseUrl/auth/me" -Method Get -Headers @{ Authorization = "Bearer $token" }
$me | ConvertTo-Json -Depth 6

if (-not $me.success) {
  throw "/auth/me failed"
}

Write-Host "API smoke tests passed."
