#Requires -Version 7
# Registers the stock "United States-Dvorak" layout alongside US QWERTY, and
# matches the repeat rate / numlock settings from
# ~/.dotfiles/hypr/.config/hypr/input.lua (repeat rate 40, delay 600, numlock
# on by default). CapsLock-as-layout-switch is handled by PowerToys Keyboard
# Manager, whose config is a windows-dotfiles package linked in
# steps/70-dotfiles.ps1 -- this step only ensures both layouts exist to
# switch between.
#
# NOTE: this installs the closest STOCK layout (US-Dvorak), not the exact
# Real Programmer Dvorak variant (which remaps symbol keys too). Building
# that exact layout needs MSKLC run interactively -- see
# packages/manual.txt and windows-setup/keyboard/README.md.
#
# Idempotent: registry list add checks for an existing entry first;
# HKCU keyboard values are last-write-wins.
$ErrorActionPreference = 'Stop'

Write-Host "==> Registering US-Dvorak input method alongside US QWERTY"

$languageList = Get-WinUserLanguageList
$en = $languageList | Where-Object { $_.LanguageTag -eq 'en-US' }
if (-not $en) {
    Write-Error "en-US language not found in Get-WinUserLanguageList -- add it via Settings > Time & Language first, then re-run."
    exit 1
}

$dvorakId = '0409:00010409'   # US-Dvorak keyboard layout id
if ($en.InputMethodTips -notcontains $dvorakId) {
    $en.InputMethodTips.Add($dvorakId)
    Set-WinUserLanguageList $languageList -Force
    Write-Host "    -> added US-Dvorak input method"
} else {
    Write-Host "    -> US-Dvorak input method already registered"
}

Write-Host "==> Setting key repeat rate (40 Hz -> fastest Windows allows) and delay"
Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name 'KeyboardSpeed' -Value '31'
Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name 'KeyboardDelay' -Value '0'

Write-Host "==> Enabling NumLock on boot"
Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name 'InitialKeyboardIndicators' -Value '2147483650'

Write-Host "==> Done. Build the exact Real Programmer Dvorak layout with MSKLC (manual, see keyboard/README.md) and bind CapsLock-cycle in PowerToys Keyboard Manager (steps/70-dotfiles.ps1 links its config)."
