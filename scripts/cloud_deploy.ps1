param(
  [ValidateSet("Auto", "Ssh", "Ftp")]
  [string]$Transport = "Auto",
  [switch]$DryRun,
  [switch]$SkipBuild,
  [switch]$VerifyOnly,
  [switch]$GenerateKeys,
  [switch]$TestConnections,
  [switch]$SkipSshCheck
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
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

if ($GenerateKeys) {
  & (Join-Path $RepoRoot "scripts\cloud_deploy\generate_deploy_keys.ps1")
  exit $LASTEXITCODE
}

if ($TestConnections) {
  & (Join-Path $RepoRoot "scripts\cloud_deploy\test_connections.ps1")
  exit $LASTEXITCODE
}

$useFtp = $false
if ($Transport -eq "Ftp") {
  $useFtp = $true
} elseif ($Transport -eq "Ssh") {
  $useFtp = $false
} else {
  $testScript = Join-Path $RepoRoot "scripts\cloud_deploy\test_connections.ps1"
  & $testScript -Quiet
  if ($LASTEXITCODE -ne 0) {
    $useFtp = $true
    Write-Host "SSH unavailable; using FTP+HTTP transport."
  }
}

if ($useFtp) {
  $args = @("$RepoRoot\scripts\cloud_ftp_deploy.php")
  if ($DryRun) { $args += "--dry-run" }
  if ($SkipBuild) { $args += "--skip-build" }
  if ($VerifyOnly) { $args += "--verify-only" }
  & $PhpPath @args
  exit $LASTEXITCODE
}

$args = @("$RepoRoot\scripts\cloud_ssh_deploy.php")
if ($DryRun) { $args += "--dry-run" }
if ($SkipBuild) { $args += "--skip-build" }
if ($VerifyOnly) { $args += "--verify-only" }
if ($SkipSshCheck) { $args += "--skip-ssh-check" }

& $PhpPath @args
exit $LASTEXITCODE
