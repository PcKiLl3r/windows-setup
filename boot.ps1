# One-command bootstrap, run from STOCK Windows PowerShell 5.1 on Windows 11:
#
#   irm https://raw.githubusercontent.com/PcKiLl3r/windows-setup/master/boot.ps1 | iex
#
# This is the only script in the repo that must stay PowerShell 5.1
# compatible -- it's what a fresh box has before anything else is
# installed. Everything it hands off to (install.ps1 and steps/*.ps1)
# requires PowerShell 7 and is written against that.
#
# Idempotent: re-running after a partial or full install is safe --
# winget installs are no-ops when present, the clone step pulls instead
# of re-cloning, and install.ps1's own steps are each idempotent.

# 1. Force TLS 1.2 -- the .NET default in PowerShell 5.1 can otherwise
# fail the HTTPS request to raw.githubusercontent.com outright.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BootUrl = 'https://raw.githubusercontent.com/PcKiLl3r/windows-setup/master/boot.ps1'

# 2. Self-elevate. `irm | iex` never writes this script to disk, so the
# elevated relaunch has to re-fetch it from $BootUrl rather than pointing
# at a local path.
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "==> Relaunching elevated (one UAC prompt)"
    $elevatedCommand = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$BootUrl' | iex"
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-Command', $elevatedCommand
    )
    return
}

$ErrorActionPreference = 'Stop'

# 3. winget preflight -- this repo targets Windows 11, where winget (App
# Installer) ships preinstalled. No Windows 10 msixbundle fallback.
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found -- this bootstrap targets Windows 11, where it's preinstalled. On Windows 10, install 'App Installer' from the Microsoft Store first, then re-run."
    exit 1
}

# 4. Install Git + PowerShell 7, the only two things boot.ps1 itself needs
# beyond winget. Everything else is installed by steps/10-packages.ps1.
Write-Host "==> Installing Git + PowerShell 7"
foreach ($id in @('Git.Git', 'Microsoft.PowerShell')) {
    winget install --exact --id $id --accept-source-agreements --accept-package-agreements --disable-interactivity
}

# 5. Refresh PATH for this process. winget updates the registry's Path
# values, but a running process keeps its own stale copy -- without this,
# the git clone two lines down fails with "git not recognized" even though
# it was just installed.
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path = $machinePath + ';' + $userPath

# 6. Clone or pull windows-setup over HTTPS (public repo, no credentials
# needed). Same clone-or-pull shape as steps/70-dotfiles.ps1.
$Setup = "$env:USERPROFILE\.setup"
$Repo = 'https://github.com/PcKiLl3r/windows-setup.git'
Write-Host "==> Syncing windows-setup to $Setup"
if (Test-Path "$Setup\.git") {
    git -C $Setup pull --ff-only
} else {
    git clone $Repo $Setup
}

# 7. Hand off to install.ps1 under PowerShell 7. Resolve pwsh.exe by
# explicit path first -- the PATH refresh in step 5 only re-read registry
# values present *before* this process started, and winget's own PATH
# broadcast can lag a fresh install by one shell. -ExecutionPolicy Bypass
# is required: default Windows client policy is Restricted, which blocks
# running the unsigned steps/*.ps1 files from disk (the `irm | iex` pipe
# bypasses policy only for content piped directly into iex, not for
# scripts it later loads from a file).
$pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if (-not (Test-Path $pwshPath)) {
    $pwshCmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        $pwshPath = $pwshCmd.Source
    } else {
        Write-Error "pwsh.exe not found after installing Microsoft.PowerShell -- check steps/10-packages.ps1's winget output above, then run $Setup\install.ps1 manually from a PowerShell 7 window."
        exit 1
    }
}

Write-Host "==> Handing off to install.ps1 (PowerShell 7)"
& $pwshPath -NoProfile -ExecutionPolicy Bypass -File "$Setup\install.ps1"
