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
    # Refresh PATH from the registry before every step. Each step below
    # runs as a NEW pwsh process, but it inherits the current process's
    # (this loop's) in-memory env block, not a fresh read of the registry
    # -- so without this, a package steps/10-packages.ps1 just installed
    # (komorebi, whkd, yasb, Flow Launcher, ...) is invisible to the very
    # next step that needs its binary on PATH. Same two lines boot.ps1
    # already uses once before handing off to this script.
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = $machinePath + ';' + $userPath

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
