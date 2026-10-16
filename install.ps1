#Requires -Version 7
# Runs every steps/*.ps1 in order. Each step is independently idempotent --
# see arch-setup/install.sh for the Linux equivalent this mirrors.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

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
