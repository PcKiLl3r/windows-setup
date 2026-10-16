#Requires -Version 7
# Starts (or restarts) komorebi, whkd, and YASB now that their configs are
# linked by steps/70-dotfiles.ps1. Scheduled tasks for next login were
# already registered by steps/20-tiling.ps1 and 30-shell.ps1; this step
# just brings today's session up to date without requiring a reboot.
#
# Idempotent: stop-if-running then start is safe to run repeatedly.
$ErrorActionPreference = 'Stop'

function Restart-Tool {
    param([string]$ProcessName, [string]$Exe, [string]$Args = '')
    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 300
    Start-Process -FilePath $Exe -ArgumentList $Args
    Write-Host "    -> (re)started $ProcessName"
}

Write-Host "==> (Re)starting komorebi + whkd + YASB with linked configs"

$komorebic = (Get-Command komorebic -ErrorAction SilentlyContinue).Source
if ($komorebic) {
    & $komorebic stop --whkd 2>$null
    Start-Sleep -Milliseconds 300
    & $komorebic start --whkd
    Write-Host "    -> (re)started komorebi + whkd"
} else {
    Write-Warning "komorebic not found -- run steps/10-packages.ps1 and steps/20-tiling.ps1 first."
}

$yasbc = (Get-Command yasbc -ErrorAction SilentlyContinue).Source
if ($yasbc) {
    & $yasbc stop 2>$null
    Start-Sleep -Milliseconds 300
    & $yasbc start
    Write-Host "    -> (re)started YASB"
} else {
    Write-Warning "yasbc not found -- run steps/10-packages.ps1 first."
}

Write-Host "==> Done. Everything that can be automated is now running. See steps/60-manual.ps1's checklist for what's left."
