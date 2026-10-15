param(
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$PhpPath = ""
foreach ($c in @("E:\xampp\php\php.exe", "C:\xampp\php\php.exe", "php")) {
  if ($c -eq "php") {
    if (Get-Command php -ErrorAction SilentlyContinue) { $PhpPath = "php"; break }
  } elseif (Test-Path $c) {
    $PhpPath = $c
    break
  }
}
if (-not $PhpPath) { throw "PHP CLI not found" }

$json = & $PhpPath (Join-Path $PSScriptRoot "export_creds_json.php")
$creds = $json | ConvertFrom-Json
$base = ($creds.deploy.apply_url -replace '/api/v1/internal/deploy/apply$', '')
$token = [string]$creds.deploy.automation_token

function Write-Line([string]$msg) {
  if (-not $Quiet) { Write-Host $msg }
}

$script:fail = $false

function Probe-Get([string]$label, [string]$url, [int[]]$okCodes = @(200)) {
  try {
    $resp = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 60 -UseBasicParsing -MaximumRedirection 0 -ErrorAction Stop
    $code = [int]$resp.StatusCode
    Write-Line ("  {0} -> HTTP {1}" -f $label, $code)
    if ($okCodes -notcontains $code) { $script:fail = $true }
  } catch {
    $code = 0
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode.value__ }
    Write-Line ("  {0} -> HTTP {1}" -f $label, $code)
    if ($okCodes -notcontains $code) { $script:fail = $true }
  }
}

Write-Line "=== Live cloud API smoke ==="
Write-Line ("  base: {0}" -f $base)

Probe-Get "health" "$base/api/v1/health"
Probe-Get "openapi" "$base/api/v1/docs/openapi.json"

if ($token) {
  try {
    $headers = @{ "X-LaundryPro-Deploy-Token" = $token; "Accept" = "application/json" }
    $resp = Invoke-WebRequest -Uri "$base/api/v1/internal/deploy/status" -Headers $headers -Method GET -TimeoutSec 60 -UseBasicParsing -ErrorAction Stop
    Write-Line ("  deploy_status -> HTTP {0}" -f [int]$resp.StatusCode)
    if ([int]$resp.StatusCode -ge 400) { $script:fail = $true }
  } catch {
    $code = 0
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode.value__ }
    Write-Line ("  deploy_status -> HTTP {0} (route or token)" -f $code)
    if ($code -eq 404) { $script:fail = $true }
  }
} else {
  Write-Line "  deploy_status -> SKIP (no automation_token in credentials)"
}

Probe-Get "bootstrap_lp_deploy_apply" "$base/lp_deploy_apply.php" @(200, 405)

if ($script:fail) { exit 1 }
Write-Line "Live smoke: PASS"
exit 0
