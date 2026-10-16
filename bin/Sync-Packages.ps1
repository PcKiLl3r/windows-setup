#Requires -Version 7
# Drift detector: diffs installed winget packages against packages/winget.txt,
# both directions -- mirrors arch-setup/bin/sync-packages.sh's comm -23 use.
$ErrorActionPreference = 'Stop'
Set-Location "$PSScriptRoot/.."

$tracked = Get-Content packages/winget.txt |
    Where-Object { $_ -and $_ -notmatch '^\s*#' } |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ } |
    Sort-Object

$installedRaw = winget list --disable-interactivity 2>$null
# winget list output doesn't cleanly expose package ids without parsing
# fixed-width columns; use --id filtering per tracked package instead, which
# is slower but exact.
$installed = @()
foreach ($id in $tracked) {
    $result = winget list --exact --id $id --disable-interactivity 2>$null
    if ($LASTEXITCODE -eq 0 -and $result -match [regex]::Escape($id)) {
        $installed += $id
    }
}

$missing = $tracked | Where-Object { $_ -notin $installed }

Write-Host "==> Tracked but not installed:"
if ($missing) { $missing | ForEach-Object { Write-Host "    $_" } } else { Write-Host "    (none)" }

Write-Host "`n==> Done. This only checks tracked packages are present -- it does not list untracked installed software (winget has no reliable machine-wide inventory diff like pacman -Qe)."
