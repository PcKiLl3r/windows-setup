#Requires -Version 7
# Spotify's Squirrel-based installer refuses to run under ANY admin token
# (APPINSTALLER_CLI_ERROR_INSTALLER_PROHIBITS_ELEVATION), and this whole
# install.ps1 run is always elevated -- so `winget install` for it can
# never succeed here, on this machine, by design (confirmed: EnableLUA=0,
# UAC fully disabled, no unelevated process is reachable at all).
#
# Workaround: Spotify's installer also supports a machine-wide /extract
# mode that skips the elevation check entirely (this is how winget-pkgs
# itself documents installing it machine-scope --
# https://github.com/microsoft/winget-pkgs/issues/210448). `winget
# download` fetches the installer without running it, then it's invoked
# directly with /extract. The normal per-user installer sets up its own
# Start Menu shortcut and "spotify" App Path registry entry as part of
# installing -- /extract does neither, so both are created here too, so
# Flow Launcher can find it and whkdrc's `start spotify` bind
# (win + shift + m) resolves.
#
# Idempotent: skips entirely if Spotify.exe already exists at the target
# path; the registry/shortcut writes are last-write-wins.
$ErrorActionPreference = 'Stop'

$InstallDir = "$env:ProgramFiles\Spotify"
$SpotifyExe = "$InstallDir\Spotify.exe"

if (Test-Path $SpotifyExe) {
    Write-Host "==> Spotify already installed at $SpotifyExe -- skipping"
    exit 0
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found -- run steps/10-packages.ps1 first."
    exit 1
}

Write-Host "==> Downloading Spotify installer"
$downloadDir = Join-Path $env:TEMP "spotify-installer-download"
if (Test-Path $downloadDir) {
    Remove-Item $downloadDir -Recurse -Force
}
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

winget download --exact --id Spotify.Spotify -d $downloadDir --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Warning "winget download failed for Spotify.Spotify (exit $LASTEXITCODE) -- skipping. Try manually: winget download --exact --id Spotify.Spotify"
    exit 0
}

$installerExe = Get-ChildItem -Path $downloadDir -Filter '*.exe' -Recurse | Select-Object -First 1
if (-not $installerExe) {
    Write-Warning "winget download produced no .exe in $downloadDir -- skipping Spotify."
    exit 0
}

Write-Host "==> Extracting Spotify to $InstallDir (bypasses the installer's elevation check)"
& $installerExe.FullName /extract "$InstallDir"
if (-not (Test-Path $SpotifyExe)) {
    Write-Warning "/extract did not produce $SpotifyExe -- Spotify's installer may have changed its flags. Skipping; install manually from a non-elevated terminal instead."
    exit 0
}

Write-Host "==> Registering App Paths entry so 'start spotify' resolves"
$appPathsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\spotify.exe'
if (-not (Test-Path $appPathsKey)) {
    New-Item -Path $appPathsKey -Force | Out-Null
}
Set-ItemProperty -Path $appPathsKey -Name '(default)' -Value $SpotifyExe
Set-ItemProperty -Path $appPathsKey -Name 'Path' -Value $InstallDir

Write-Host "==> Creating Start Menu shortcut (so Flow Launcher can find it)"
$shortcutPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $SpotifyExe
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Save()

Remove-Item $downloadDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "==> Done. Spotify won't self-update via its normal per-user mechanism from this install path -- re-run this step later to pick up a newer winget-tracked version if needed."
