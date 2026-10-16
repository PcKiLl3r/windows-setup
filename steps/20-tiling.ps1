#Requires -Version 7
# Registers komorebi and whkd to autostart, and starts them now if not running.
# komorebi/whkd binaries themselves come from steps/10-packages.ps1 (winget).
#
# komorebi's default config location is $env:USERPROFILE itself, not
# ~/.config/komorebi where windows-dotfiles links komorebi.json and
# applications.json -- https://lgug2z.github.io/komorebi/common-workflows/komorebi-config-home.html.
# Fixed two ways: an explicit --config flag on the autostart command (belt),
# and a persistent KOMOREBI_CONFIG_HOME user env var (braces), since some
# komorebi entry points (e.g. the YASB tray) read the env var instead of
# accepting a flag.
#
# Idempotent: Unregister-ScheduledTask then Register-ScheduledTask is
# last-write-wins; Start-Process checks for a running instance first;
# SetEnvironmentVariable is last-write-wins.
$ErrorActionPreference = 'Stop'

$KomorebiConfigHome = "$HOME\.config\komorebi"
[Environment]::SetEnvironmentVariable('KOMOREBI_CONFIG_HOME', $KomorebiConfigHome, 'User')
$env:KOMOREBI_CONFIG_HOME = $KomorebiConfigHome

function Register-AutostartTask {
    # Named $Arguments, not $Args -- $args is PowerShell's reserved
    # automatic variable for unbound positional parameters, and declaring
    # a param literally called Args makes binding unreliable (this is what
    # silently produced a null/empty value here on the real machine).
    # New-ScheduledTaskAction's own -Argument also rejects an empty string,
    # not just null, so it's only passed when there's something to pass.
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

Register-AutostartTask -Name 'omarchy-komorebi' -Exe $komorebic.Source -Arguments "start --whkd --config `"$KomorebiConfigHome\komorebi.json`""

Write-Host "==> Done. komorebi config (komorebi.json, applications.json) and whkdrc are linked by steps/70-dotfiles.ps1 -- start/restart komorebi after that step runs, not before."
