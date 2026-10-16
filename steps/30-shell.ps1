#Requires -Version 7
# Registers YASB (bar) and Flow Launcher (SUPER+D launcher) to autostart.
# Binaries come from steps/10-packages.ps1.
#
# Idempotent: same Unregister/Register-ScheduledTask last-write-wins pattern
# as steps/20-tiling.ps1.
$ErrorActionPreference = 'Stop'

function Register-AutostartTask {
    # Named $Arguments, not $Args -- see steps/20-tiling.ps1's copy of this
    # function for why (collides with PowerShell's reserved automatic
    # $args variable, and New-ScheduledTaskAction -Argument '' is itself
    # invalid, not just -Argument $null).
    param([string]$Name, [string]$Exe, [string]$Arguments = '')
    Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue
    if ($Arguments) {
        $action = New-ScheduledTaskAction -Execute $Exe -Argument $Arguments
    } else {
        $action = New-ScheduledTaskAction -Execute $Exe
    }
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $Name -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-Host "    -> registered autostart task: $Name"
}

Write-Host "==> Registering YASB + Flow Launcher autostart"

$yasbc = Get-Command yasbc -ErrorAction SilentlyContinue
if (-not $yasbc) {
    Write-Warning "yasbc not found -- run steps/10-packages.ps1 first (winget install AmN.yasb). Skipping bar autostart."
} else {
    Register-AutostartTask -Name 'omarchy-yasb' -Exe $yasbc.Source
}

$flowLauncherPath = "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe"
if (-not (Test-Path $flowLauncherPath)) {
    Write-Warning "Flow Launcher not found at $flowLauncherPath -- run steps/10-packages.ps1 first. Skipping launcher autostart."
} else {
    Register-AutostartTask -Name 'omarchy-flow-launcher' -Exe $flowLauncherPath
}

Write-Host "==> Done. YASB config (config.yaml/styles.css) and Flow Launcher settings are linked by steps/70-dotfiles.ps1."
