#Requires -Version 7
# Installs every package listed in packages/winget.txt via winget.
#
# Idempotent: `winget install --exact --id X` is a no-op (exit 0, "already
# installed") when the package is already present.
$ErrorActionPreference = 'Stop'
Set-Location "$PSScriptRoot/.."

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found -- install 'App Installer' from the Microsoft Store first, then re-run this step."
    exit 1
}

Write-Host "==> Installing packages from packages/winget.txt"

Get-Content packages/winget.txt |
    Where-Object { $_ -and $_ -notmatch '^\s*#' } |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ } |
    ForEach-Object {
        Write-Host "    -> $_"
        winget install --exact --id $_ --accept-source-agreements --accept-package-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
            # -1978335189 = APPINSTALLER_CLI_ERROR_NO_APPLICABLE_UPDATE (already up to date)
            Write-Warning "winget install failed for $_ (exit $LASTEXITCODE) -- continuing"
        }
    }

Write-Host "==> Done. Anything with no winget id is in packages/manual.txt -- see steps/60-manual.ps1."
