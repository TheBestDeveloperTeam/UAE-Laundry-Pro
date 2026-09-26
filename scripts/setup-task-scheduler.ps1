param(
  [string]$PhpExe = "C:\xampp\php\php.exe",
  [string]$ScriptPath = "E:\Projects\Flutter\UAE-Laundry-Pro\api\scripts\sync_scheduler.php"
)

# Requires Run as Administrator
Write-Host "====================================================="
Write-Host " LaundryPro UAE — Sync Scheduler Task Configuration  "
Write-Host "====================================================="

if (-not (Test-Path $PhpExe)) {
    Write-Host "Warning: PHP executable not found at $PhpExe. Task might fail if PHP is not in PATH." -ForegroundColor Yellow
}

$TaskName = "LaundryPro_SyncOutbox"
$Action = New-ScheduledTaskAction -Execute $PhpExe -Argument "-f `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

Write-Host "Creating Scheduled Task: $TaskName (every 5 minutes)..." -ForegroundColor Cyan
Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -TaskName $TaskName -Description "Runs LaundryPro local outbox sync to the cloud every 5 minutes" -User "SYSTEM" -Force

Write-Host "Task registered successfully!" -ForegroundColor Green
