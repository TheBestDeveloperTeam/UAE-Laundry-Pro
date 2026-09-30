param(
  [string]$XamppRoot = "E:\xampp",
  [string]$RepoRoot = "E:\Projects\Flutter\UAE-Laundry-Pro"
)

# Requires Run as Administrator on Windows Workstation
Write-Host "=========================================================="
Write-Host " LaundryPro UAE — Workstation Host & Apache VirtualHosts  "
Write-Host "=========================================================="

# 1. Update Windows hosts file
$HostsPath = "$env:windir\System32\drivers\etc\hosts"
$HostEntries = @"
127.0.0.1		laundrypro-api
127.0.0.1		cloud-api
"@

$Content = Get-Content $HostsPath -Raw -ErrorAction SilentlyContinue
if ($Content -notmatch "laundrypro-api" -or $Content -notmatch "cloud-api") {
    Write-Host "[1/3] Registering laundrypro-api & cloud-api in hosts..." -ForegroundColor Cyan
    Add-Content -Path $HostsPath -Value "`n# LaundryPro UAE Local Development Hosts`n$HostEntries"
} else {
    Write-Host "[1/3] hosts entries already configured." -ForegroundColor Green
}

# 2. Configure Apache VirtualHost in XAMPP
$VHostFile = Join-Path $XamppRoot "apache\conf\extra\httpd-vhosts.conf"
$ApiPublicDir = (Join-Path $RepoRoot "api\public").Replace("\", "/")
$CloudPublicDir = (Join-Path $RepoRoot "cloud-api\public").Replace("\", "/")
$ApiLogsDir = (Join-Path $RepoRoot "api\logs").Replace("\", "/")
$CloudLogsDir = (Join-Path $RepoRoot "cloud-api\logs").Replace("\", "/")

# Ensure log folders exist
if (-not (Test-Path (Join-Path $RepoRoot "api\logs"))) {
    New-Item -ItemType Directory -Path (Join-Path $RepoRoot "api\logs") -Force | Out-Null
}
if (-not (Test-Path (Join-Path $RepoRoot "cloud-api\logs"))) {
    New-Item -ItemType Directory -Path (Join-Path $RepoRoot "cloud-api\logs") -Force | Out-Null
}

if (Test-Path $VHostFile) {
    $VHostContent = Get-Content $VHostFile -Raw
    if ($VHostContent -notmatch "laundrypro-api") {
        Write-Host "[2/3] Adding VirtualHosts in httpd-vhosts.conf..." -ForegroundColor Cyan
        $VHostBlock = @"

# LaundryPro UAE Dedicated VirtualHosts
<VirtualHost *:80>
    ServerName laundrypro-api
    DocumentRoot "$ApiPublicDir"
    <Directory "$ApiPublicDir">
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "$ApiLogsDir/error.log"
    CustomLog "$ApiLogsDir/access.log" common
</VirtualHost>

<VirtualHost *:80>
    ServerName cloud-api
    DocumentRoot "$CloudPublicDir"
    <Directory "$CloudPublicDir">
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "$CloudLogsDir/error.log"
    CustomLog "$CloudLogsDir/access.log" common
</VirtualHost>
"@
        Add-Content -Path $VHostFile -Value $VHostBlock
    } else {
        Write-Host "[2/3] VirtualHosts already configured in httpd-vhosts.conf." -ForegroundColor Green
    }
} else {
    Write-Host "[2/3] Warning: XAMPP vhosts not found at $VHostFile. Configure manually if using different path." -ForegroundColor Yellow
}

# 3. Create NTFS Directory Junction for Apache (Optional convenience)
$JunctionTarget = Join-Path $XamppRoot "htdocs\laundrypro-api"
if (-not (Test-Path $JunctionTarget)) {
    Write-Host "[3/3] Creating Apache Junction: $JunctionTarget..." -ForegroundColor Cyan
    $ApiDir = Join-Path $RepoRoot "api"
    cmd /c mklink /J "$JunctionTarget" "$ApiDir" | Out-Null
} else {
    Write-Host "[3/3] Junction already exists at $JunctionTarget." -ForegroundColor Green
}

Write-Host "`nSetup complete! Ensure Apache and MySQL are running in XAMPP." -ForegroundColor Green

