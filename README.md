# windows-setup

Provisions a Windows machine to behave as close as possible to our Omarchy
(Hyprland) setup: tiling WM (komorebi + whkd), top bar (YASB), launcher
(Flow Launcher), plus Battle.net and Steam on top. This is the Windows
counterpart to [`arch-setup`](https://github.com/PcKiLl3r/arch-setup) --
system-level provisioning here, config symlinking in the separate
[`windows-dotfiles`](https://github.com/PcKiLl3r/windows-dotfiles) repo,
which this repo clones and runs as its second-to-last step.

## What's here

```
install.ps1                 Entry point: runs every steps/*.ps1 in order
steps/10-packages.ps1        winget install everything in packages/winget.txt
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
```

## Install

Both repos are private and cloned over SSH (`steps/70-dotfiles.ps1` clones
`git@github.com:PcKiLl3r/windows-dotfiles.git`), so an SSH key registered
with GitHub must exist before step 1 -- same prerequisite
`arch-setup/README.md` states for Linux.

1. Copy an SSH private key onto the machine out-of-band (USB drive, etc.)
   and register it with `ssh-agent` / Pageant, or generate a new one with
   `ssh-keygen` and add the public key at
   https://github.com/settings/keys.
2. Verify: `ssh -T git@github.com` should greet you by username.
3. Install Git for Windows and PowerShell 7 if not already present (needed
   just to run the clone + `install.ps1` itself):
   ```powershell
   winget install --exact --id Git.Git
   winget install --exact --id Microsoft.PowerShell
   ```
4. Clone and run, from an **elevated** PowerShell 7 session (`#Requires
   -Version 7` on every script; some steps -- Developer Mode, hotkey
   registry, scheduled tasks -- need admin):
   ```powershell
   git clone git@github.com:PcKiLl3r/windows-setup.git $env:USERPROFILE\.setup
   cd $env:USERPROFILE\.setup
   ./install.ps1
   ```
5. Work through the checklist `steps/60-manual.ps1` prints at the end
   (account sign-ins, the exact Real Programmer Dvorak layout build, the
   keybinding audit).
6. Sign out and back in once, so the Explorer hotkey release and scheduled
   autostart tasks from steps 20/30/45 take full effect.

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
