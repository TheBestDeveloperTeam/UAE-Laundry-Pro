<#
.SYNOPSIS
  Build a minimal cPanel upload zip: cloud-api (with migrations), root .htaccess, deployment.md
#>
param(
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) {
  $OutDir = Join-Path $RepoRoot "dist"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$zipPath = Join-Path $OutDir "cloud-cpanel-upload.zip"
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

$stage = Join-Path $env:TEMP ("lp-cloud-cpanel-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$cloudSrc = Join-Path $RepoRoot "cloud-api"
$cloudDst = Join-Path $stage "cloud-api"
Copy-Item -Recurse -Force $cloudSrc $cloudDst

$prune = @(
  ".env",
  ".env.production",
  "logs",
  "storage",
  "vendor",
  "node_modules"
)
foreach ($name in $prune) {
  Get-ChildItem -Path $cloudDst -Recurse -Force -Filter $name -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

Copy-Item -Force (Join-Path $RepoRoot ".htaccess") (Join-Path $stage ".htaccess")
Copy-Item -Force (Join-Path $RepoRoot "deployment.md") (Join-Path $stage "deployment.md")
if (Test-Path (Join-Path $RepoRoot "lp_deploy_apply.php")) {
  $lp = Join-Path $RepoRoot "lp_deploy_apply.php"
  Copy-Item -Force $lp (Join-Path $stage "lp_deploy_apply.php")
  $publicDir = Join-Path $cloudDst "public"
  New-Item -ItemType Directory -Force -Path $publicDir | Out-Null
  Copy-Item -Force $lp (Join-Path $publicDir "lp_deploy_apply.php")
}

Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $stage

Write-Host "Created: $zipPath"
Write-Host "Upload and extract to subdomain root, then:"
Write-Host "  cd cloud-api && cp .env.production.example .env && php scripts/deploy.php"
