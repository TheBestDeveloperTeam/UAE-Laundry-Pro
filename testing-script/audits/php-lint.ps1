param(
  [string]$PhpPath = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ApiRoot = Join-Path $RepoRoot "api"

function Resolve-Php {
  param([string]$CustomPath)
  if ($CustomPath -and (Test-Path $CustomPath)) { return $CustomPath }
  $candidates = @("E:\xampp\php\php.exe", "php")
  foreach ($candidate in $candidates) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
      return (Get-Command $candidate).Source
    }
    if (Test-Path $candidate) { return $candidate }
  }
  throw "PHP not found."
}

$php = Resolve-Php -CustomPath $PhpPath
$files = Get-ChildItem -Path (Join-Path $ApiRoot "src") -Recurse -Filter *.php
$failed = $false

foreach ($file in $files) {
  & $php -l $file.FullName | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Syntax error: $($file.FullName)"
    $failed = $true
  }
}

if ($failed) { exit 1 }
Write-Host "PHP lint passed for $($files.Count) files."
