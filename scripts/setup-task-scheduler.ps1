param(
  [string]$PhpExe = "",
  [string]$RepoRoot = "",
  [int]$SyncIntervalMinutes = 5
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Split-Path -Parent $PSScriptRoot
}

if ([string]::IsNullOrWhiteSpace($PhpExe)) {
  $candidates = @(
    "C:\xampp\php\php.exe",
    "E:\xampp\php\php.exe",
    "$env:ProgramFiles\PHP\php.exe"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) {
      $PhpExe = $c
      break
    }
  }
  if ([string]::IsNullOrWhiteSpace($PhpExe)) {
    $PhpExe = "php.exe"
  }
}

$SyncScript = Join-Path $RepoRoot "api\scripts\sync_scheduler.php"
$BackupScript = Join-Path $RepoRoot "api\scripts\backup_cli.php"

if (-not (Test-Path $SyncScript)) {
  throw "Sync script not found: $SyncScript"
}

Write-Host "====================================================="
Write-Host " LaundryPro UAE — Task Scheduler Configuration"
Write-Host " Repo: $RepoRoot"
Write-Host " PHP:  $PhpExe"
Write-Host "====================================================="

$TaskName = "LaundryPro_SyncOutbox"
$Action = New-ScheduledTaskAction -Execute $PhpExe -Argument "-f `"$SyncScript`""
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $SyncIntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 3650)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

Write-Host "Registering $TaskName (every $SyncIntervalMinutes minutes)..." -ForegroundColor Cyan
Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -TaskName $TaskName -Description "LaundryPro local outbox sync to cloud" -User "SYSTEM" -Force

$BackupTaskName = "LaundryPro_DailyBackup"
if (-not (Test-Path $BackupScript)) {
  throw "Backup CLI not found: $BackupScript"
}
$BackupAction = New-ScheduledTaskAction -Execute $PhpExe -Argument "-f `"$BackupScript`""
$BackupTrigger = New-ScheduledTaskTrigger -Daily -At "02:00"
Write-Host "Registering $BackupTaskName (daily 02:00)..." -ForegroundColor Cyan
Register-ScheduledTask -Action $BackupAction -Trigger $BackupTrigger -Settings $Settings -TaskName $BackupTaskName -Description "LaundryPro daily local database backup" -User "SYSTEM" -Force

Write-Host "Tasks registered." -ForegroundColor Green
