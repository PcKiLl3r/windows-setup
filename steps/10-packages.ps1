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
        # Optional `<id>|<extra args>` suffix for packages whose manifest
        # needs flags beyond the common set (see packages/winget.txt's
        # header comment) -- e.g. Blizzard.BattleNet requires an explicit
        # --location even with --disable-interactivity. Tokenize
        # respecting "quoted segments" so a path with spaces stays one arg.
        $line = $_
        $id, $extraArgsRaw = $line -split '\|', 2
        $id = $id.Trim()
        $extraArgs = @()
        if ($extraArgsRaw) {
            $extraArgs = [regex]::Matches($extraArgsRaw, '"[^"]*"|\S+') | ForEach-Object { $_.Value.Trim('"') }
        }

        Write-Host "    -> $id"

        $attempt = 1
        $maxAttempts = 3
        $succeeded = $false
        while (-not $succeeded -and $attempt -le $maxAttempts) {
            winget install --exact --id $id --accept-source-agreements --accept-package-agreements --disable-interactivity @extraArgs
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
                # -1978335189 = APPINSTALLER_CLI_ERROR_NO_APPLICABLE_UPDATE (already up to date)
                $succeeded = $true
            } elseif ($LASTEXITCODE -eq -2147012889) {
                # InternetOpenUrl() failed -- transient network error; worth
                # retrying rather than permanently skipping the package.
                if ($attempt -lt $maxAttempts) {
                    Write-Warning "winget install hit a transient network error for $id (attempt $attempt/$maxAttempts) -- retrying in 10s"
                    Start-Sleep -Seconds 10
                }
            } else {
                # Not a transient-looking failure (bad id, manifest error,
                # etc.) -- retrying won't help.
                break
            }
            $attempt++
        }

        if (-not $succeeded) {
            Write-Warning "winget install failed for $id (exit $LASTEXITCODE) -- continuing"
        }
    }

Write-Host "==> Done. Anything with no winget id is in packages/manual.txt -- see steps/60-manual.ps1."
