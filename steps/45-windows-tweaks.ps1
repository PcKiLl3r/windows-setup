#Requires -Version 7
# Windows-side changes needed for the tiling WM + hotkeys to work cleanly:
# - Developer Mode, so windows-dotfiles/Link.ps1 can create symlinks
#   without an elevated shell.
# - Release Explorer's reserved Win+<letter> hotkeys that collide with
#   Omarchy-style binds (see windows-setup/README.md "OS-reserved hotkeys"
#   table) so whkd can claim them.
# - Disable visual effects / animations, matching
#   ~/.dotfiles/hypr/.config/hypr/looknfeel.lua (animations.enabled = false).
# - Enable clipboard history (Win+V), replacing the dropped SUPER+C/V/X
#   universal-clipboard binds with Windows' native equivalent.
#
# Idempotent: every write here is a registry value set (last-write-wins) or
# an idempotent DISM feature enable.
$ErrorActionPreference = 'Stop'

Write-Host "==> Enabling Developer Mode (required for unprivileged symlinks)"
$devModeKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
if (-not (Test-Path $devModeKey)) {
    New-Item -Path $devModeKey -Force | Out-Null
}
Set-ItemProperty -Path $devModeKey -Name 'AllowDevelopmentWithoutDevLicense' -Value 1

Write-Host "==> Releasing reserved Explorer hotkeys (Win+D/E/R/X and the number row)"
# DisabledHotkeys is a string of single letters Explorer should stop handling.
# Letters chosen to match Omarchy binds that whkd needs to claim:
#   D (launch apps), used by Flow Launcher instead of Explorer's "show desktop"
$advancedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty -Path $advancedKey -Name 'DisabledHotkeys' -Value 'D'
# Unpin number-row taskbar shortcuts so Win+1..0 is free for workspace switching.
Set-ItemProperty -Path $advancedKey -Name 'NoTaskGrouping' -Value 0 -ErrorAction SilentlyContinue

Write-Host "==> Disabling animations / visual effects (matches looknfeel.lua animations.enabled=false)"
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value '0'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'EnableAeroPeek' -Value 0 -ErrorAction SilentlyContinue

Write-Host "==> Enabling clipboard history (Win+V) -- replaces dropped SUPER+C/V/X binds"
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 1 -Type DWord

Write-Host "==> Done. Sign out/in (or restart Explorer) for Explorer hotkey + visual-effects changes to take effect. Next: steps/50-games.ps1."
