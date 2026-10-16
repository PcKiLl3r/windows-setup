#Requires -Version 7
# Registers komorebi and whkd to autostart, and starts them now if not running.
# komorebi/whkd binaries themselves come from steps/10-packages.ps1 (winget).
#
# Idempotent: Unregister-ScheduledTask then Register-ScheduledTask is
# last-write-wins; Start-Process checks for a running instance first.
$ErrorActionPreference = 'Stop'

function Register-AutostartTask {
    param([string]$Name, [string]$Exe, [string]$Args = '')
    Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue
    $action = New-ScheduledTaskAction -Execute $Exe -Argument $Args
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $Name -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-Host "    -> registered autostart task: $Name"
}

Write-Host "==> Registering komorebi + whkd autostart"

$komorebic = Get-Command komorebic -ErrorAction SilentlyContinue
if (-not $komorebic) {
    Write-Error "komorebic not found -- run steps/10-packages.ps1 first (winget install LGUG2Z.komorebi)."
    exit 1
}
$whkd = Get-Command whkd -ErrorAction SilentlyContinue
if (-not $whkd) {
    Write-Error "whkd not found -- run steps/10-packages.ps1 first (winget install LGUG2Z.whkd)."
    exit 1
}

Register-AutostartTask -Name 'omarchy-komorebi' -Exe $komorebic.Source -Args 'start --whkd'

Write-Host "==> Done. komorebi config (komorebi.json, applications.json) and whkdrc are linked by steps/70-dotfiles.ps1 -- start/restart komorebi after that step runs, not before."
