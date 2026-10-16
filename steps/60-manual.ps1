#Requires -Version 7
# Prints the checklist of things that can't be scripted -- mirrors
# arch-setup/steps/50-manual.sh (a pure heredoc of [ ] items).
$ErrorActionPreference = 'Stop'

@'
Manual checklist (nothing below this point is scripted):

Keyboard
  [ ] Build + install the exact Real Programmer Dvorak layout via MSKLC
      -- see windows-setup/keyboard/README.md (steps/40-keyboard.ps1 only
      registers the stock US-Dvorak approximation).
  [ ] Confirm whkd letter-binds still work once that layout is active
      -- see the "whkd + custom layout risk" section of the same README.

Accounts / sign-ins
  [ ] Battle.net: sign in, install games, verify library paths
  [ ] Steam: sign in, set library folder, install games
  [ ] 1Password: sign in + install browser extension
  [ ] Signal: link this device
  [ ] Docker Desktop: sign in, confirm WSL2 backend

Secrets
  [ ] Copy SSH key onto this machine out-of-band (same step as
      arch-setup/steps/15-secrets.sh handles on Linux -- no Windows port
      exists; see windows-setup/README.md "Out of scope")

Verification (see windows-setup/README.md "Keybinding audit")
  [ ] Walk the full keybinding table from the plan and confirm each bind
      works / was intentionally remapped / was intentionally dropped
'@ | Write-Host

Write-Host "`n==> Done. This is the last required step; steps/70-dotfiles.ps1 and 80-autostart.ps1 still need to run."
