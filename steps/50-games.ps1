#Requires -Version 7
# Steam + Battle.net are already in packages/winget.txt and installed by
# steps/10-packages.ps1. This step only verifies they're present and warns
# if the komorebi float rules that keep them (and games) untiled aren't
# linked yet -- those live in windows-dotfiles/komorebi/.config/komorebi/applications.json,
# linked by steps/70-dotfiles.ps1.
#
# Idempotent: read-only checks, no mutation.
$ErrorActionPreference = 'Stop'

Write-Host "==> Verifying Steam + Battle.net installed"

$steam = Get-Command "${env:ProgramFiles(x86)}\Steam\steam.exe" -ErrorAction SilentlyContinue
if (-not $steam) {
    Write-Warning "Steam not found at the default path -- check steps/10-packages.ps1 ran (winget id Valve.Steam)."
}

$battleNet = Get-Command "${env:ProgramFiles(x86)}\Battle.net\Battle.net Launcher.exe" -ErrorAction SilentlyContinue
if (-not $battleNet) {
    Write-Warning "Battle.net not found at the default path -- check steps/10-packages.ps1 ran (winget id Blizzard.BattleNet)."
}

$appRules = "$HOME\.config\komorebi\applications.json"
if (-not (Test-Path $appRules)) {
    Write-Warning "$appRules not linked yet -- steps/70-dotfiles.ps1 hasn't run. Steam/Battle.net/games will get tiled by komorebi until it does."
} else {
    Write-Host "    -> komorebi float rules for games already linked"
}

Write-Host "==> Done. Account sign-in and library/install-path setup for both launchers is manual -- see packages/manual.txt / steps/60-manual.ps1."
