#Requires -Version 7
# Clones (or updates) windows-dotfiles and delegates to its own entry point,
# the same way arch-setup/steps/60-dotfiles.sh clones ~/.dotfiles and runs
# its ./run -- so the package list lives in exactly one place.
#
# Idempotent: `git pull --ff-only` on an existing clone; run.ps1's Link.ps1
# is a safe no-op re-link (Force-overwrites existing symlinks pointing to
# the same target).
$ErrorActionPreference = 'Stop'

$Dotfiles = if ($env:DOTFILES) { $env:DOTFILES } else { "$HOME\.dotfiles" }
$Repo = 'git@github.com:PcKiLl3r/windows-dotfiles.git'

Write-Host "==> Syncing windows-dotfiles to $Dotfiles"

if (Test-Path "$Dotfiles\.git") {
    git -C $Dotfiles pull --ff-only
} else {
    git clone --recurse-submodules $Repo $Dotfiles
}

$env:DOTFILES = $Dotfiles
& "$Dotfiles\run.ps1"

Write-Host "==> Done. Configs linked. Next: steps/80-autostart.ps1 to (re)start komorebi/whkd/yasb with them."
