#Requires -Version 7
# Runs every steps/*.ps1 in order. Each step is independently idempotent --
# see arch-setup/install.sh for the Linux equivalent this mirrors.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "install.ps1 needs an elevated shell -- several steps write to HKLM / register scheduled tasks. Re-run from an admin PowerShell 7 window, or just use boot.ps1's one-liner, which self-elevates."
    exit 1
}

foreach ($step in Get-ChildItem steps/*.ps1 | Sort-Object Name) {
    Write-Host "`n=========================================="
    Write-Host "  $($step.Name)"
    Write-Host "=========================================="
    pwsh -NoProfile -File $step.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "step failed: $($step.Name)"
        exit 1
    }
}

Write-Host "`nAll steps complete."
