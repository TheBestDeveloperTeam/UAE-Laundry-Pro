param(
  [string]$TargetDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $TargetDir) {
  $TargetDir = Join-Path $RepoRoot "build\windows\x64\runner\Release"
}

$dlls = @(
  "msvcp140.dll",
  "msvcp140_1.dll",
  "vcruntime140.dll",
  "vcruntime140_1.dll"
)

$searchRoots = @(
  "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Redist\MSVC",
  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC",
  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\VC\Redist\MSVC"
)

if (-not (Test-Path $TargetDir)) {
  New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
}

foreach ($dll in $dlls) {
  $found = $null
  foreach ($root in $searchRoots) {
    if (-not (Test-Path $root)) { continue }
    $match = Get-ChildItem $root -Recurse -Filter $dll -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { $found = $match; break }
  }
  if ($found) {
    Copy-Item $found.FullName (Join-Path $TargetDir $dll) -Force
    Write-Host "Staged $dll"
  } else {
    Write-Warning "Could not find $dll — install Visual C++ Redistributable"
  }
}

Write-Host "DLL staging complete for $TargetDir"
