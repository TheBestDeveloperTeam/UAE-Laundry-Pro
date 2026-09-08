param(
  [string]$XamppRoot = "E:\xampp",
  [string]$RepoRoot = "E:\Projects\Flutter\UAE-Laundry-Pro"
)

# Requires Run as Administrator on Windows Client Workstation
Write-Host "====================================================="
Write-Host " LaundryPro UAE — Client Node Security & Host Setup  "
Write-Host "====================================================="

# 1. Update Windows hosts file
$HostsPath = "$env:windir\System32\drivers\etc\hosts"
$HostEntry = "127.0.0.1    laundrypro-localapi"

$Content = Get-Content $HostsPath -Raw -ErrorAction SilentlyContinue
if ($Content -notmatch "laundrypro-localapi") {
    Write-Host "[1/3] Registering laundrypro-localapi in hosts..." -ForegroundColor Cyan
    Add-Content -Path $HostsPath -Value "`n# LaundryPro UAE Local Node`n$HostEntry"
} else {
    Write-Host "[1/3] hosts entry already configured." -ForegroundColor Green
}

# 2. Configure Apache VirtualHost in XAMPP
$VHostFile = Join-Path $XamppRoot "apache\conf\extra\httpd-vhosts.conf"
$PublicDir = (Join-Path $RepoRoot "api\public").Replace("\", "/")

if (Test-Path $VHostFile) {
    $VHostContent = Get-Content $VHostFile -Raw
    if ($VHostContent -notmatch "laundrypro-localapi") {
        Write-Host "[2/3] Adding VirtualHost in httpd-vhosts.conf..." -ForegroundColor Cyan
        $VHostBlock = @"

# LaundryPro UAE Client Dedicated VirtualHost
<VirtualHost *:80>
    ServerName laundrypro-localapi
    DocumentRoot "$PublicDir"
    <Directory "$PublicDir">
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require local
    </Directory>
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
</VirtualHost>
"@
        Add-Content -Path $VHostFile -Value $VHostBlock
    } else {
        Write-Host "[2/3] VirtualHost already configured in httpd-vhosts.conf." -ForegroundColor Green
    }
} else {
    Write-Host "[2/3] Warning: XAMPP vhosts not found at $VHostFile. Configure manually if using different path." -ForegroundColor Yellow
}

# 3. Create NTFS Directory Junction for Apache
$JunctionTarget = Join-Path $XamppRoot "htdocs\laundrypro-api"
if (-not (Test-Path $JunctionTarget)) {
    Write-Host "[3/3] Creating Apache Junction: $JunctionTarget..." -ForegroundColor Cyan
    $ApiDir = Join-Path $RepoRoot "api"
    cmd /c mklink /J "$JunctionTarget" "$ApiDir" | Out-Null
} else {
    Write-Host "[3/3] Junction already exists at $JunctionTarget." -ForegroundColor Green
}

Write-Host "`nSetup complete! Ensure Apache and MySQL are running in XAMPP." -ForegroundColor Green

