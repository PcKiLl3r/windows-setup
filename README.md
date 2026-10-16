# windows-setup

Provisions a Windows machine to behave as close as possible to our Omarchy
(Hyprland) setup: tiling WM (komorebi + whkd), top bar (YASB), launcher
(Flow Launcher), plus Battle.net and Steam on top. This is the Windows
counterpart to [`arch-setup`](https://github.com/PcKiLl3r/arch-setup) --
system-level provisioning here, config symlinking in the separate
[`windows-dotfiles`](https://github.com/PcKiLl3r/windows-dotfiles) repo,
which this repo clones and runs as its second-to-last step.

## Install -- one command

On a fresh Windows 11 install, in stock (unelevated) PowerShell:

```powershell
irm https://raw.githubusercontent.com/PcKiLl3r/windows-setup/master/boot.ps1 | iex
```

One UAC prompt, then it runs to completion: installs Git + PowerShell 7,
clones this repo, hands off to `install.ps1`, which installs everything
else and links `windows-dotfiles`. Ends by printing the manual checklist
(account sign-ins, the exact keyboard layout build, the keybinding audit --
see below). Safe to re-run; every step is idempotent.

**Both repos are public** -- unlike `arch-setup`/`.dotfiles`, which stay
private. Neither holds secrets (checked: no keys, no tokens, just the
user's name in `.gitconfig`), and public is what lets the one-liner clone
with zero credentials on a machine that has none yet. The secrets/vault
step (`arch-setup/steps/15-secrets.sh`) has no Windows port -- SSH keys etc.
stay a manual, out-of-band copy either way.

## What's here

```
install.ps1                 Entry point: runs every steps/*.ps1 in order
steps/10-packages.ps1        winget install everything in packages/winget.txt
steps/15-spotify.ps1         Install Spotify via a /extract workaround (winget install always fails elevated)
steps/20-tiling.ps1          Register komorebi + whkd autostart
steps/30-shell.ps1           Register YASB + Flow Launcher autostart
steps/40-keyboard.ps1        US-Dvorak input method, repeat rate, numlock
steps/45-windows-tweaks.ps1  Dev Mode, release reserved hotkeys, animations off
steps/50-games.ps1           Verify Steam + Battle.net, warn if float rules missing
steps/60-manual.ps1          Print the can't-be-scripted checklist
steps/70-dotfiles.ps1        Clone/pull windows-dotfiles, run its run.ps1
steps/80-autostart.ps1       (Re)start komorebi/whkd/YASB with linked configs
packages/winget.txt          Package ids, one per line
packages/manual.txt          No-winget-id / sign-in-required items
bin/Sync-Packages.ps1        Drift check: tracked vs. actually installed
keyboard/README.md           Real Programmer Dvorak layout build instructions
boot.ps1                     The one-liner's target -- bootstraps Git/pwsh7, then runs install.ps1
```

`boot.ps1` is the only script here that must stay PowerShell 5.1 compatible
(that's all a fresh box has); everything it hands off to requires
PowerShell 7. Running `install.ps1` directly (skipping `boot.ps1`) needs an
elevated PowerShell 7 shell and a prior Git + PowerShell 7 install --
`boot.ps1` handles both and self-elevates.

## Keybinding audit

The full Omarchy -> Windows keybinding translation table lives in the
project plan this repo was built from. After running `install.ps1`, walk
every bind from `omarchy menu keybindings --print` (the Linux machine) and
record it here as the audit is performed:

| Status | Count |
|---|---|
| Works as a direct komorebi/whkd equivalent | TBD after first real-machine run |
| Remapped (different mechanism, same intent) | TBD |
| Intentionally dropped (no Windows equivalent, or redundant) | TBD |

See `whkd/.config/whkdrc` in `windows-dotfiles` for the per-bind comments
explaining each mapping, remap, or drop.

## OS-reserved hotkeys

`steps/45-windows-tweaks.ps1` releases `Win+D` from Explorer's "show
desktop" so Flow Launcher can claim it (`SUPER+D` on Linux). `Win+L` cannot
be released by any app -- not a conflict here, since the Omarchy lock bind
is `SUPER+CTRL+L`, leaving `SUPER+L` free for vim-style focus-right.

## Out of scope

Quickshell parity (OSD, notification center, custom lock screen, wallpaper
rotation), secrets/vault handling (SSH keys stay a manual copy, see
`packages/manual.txt`), mise runtimes, firewall rules, Slovenian šumnik
helpers.
