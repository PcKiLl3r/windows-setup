# Real Programmer Dvorak layout

`steps/40-keyboard.ps1` registers the stock **US-Dvorak** layout, which gets
the letter positions right but not the symbol remapping that Real
Programmer Dvorak (`real-prog-dvorak` in
`~/.dotfiles/hypr/.config/hypr/input.lua`) uses.

Building the exact layout needs the Microsoft Keyboard Layout Creator
(MSKLC), run interactively, because the symbol-key mapping has to be
verified by typing on the real machine rather than guessed blind:

1. Install MSKLC (https://www.microsoft.com/en-us/download/details.aspx?id=102134).
2. Reference layout: https://www.kaufmann.no/roland/dvorak/ (the Linux
   `real-prog-dvorak` XKB variant this Omarchy setup uses is based on this).
3. Build and install the `.msi`; name it `RealProgDvorak` so
   `steps/40-keyboard.ps1`'s companion check (added once this exists) can
   detect it.
4. Re-run `steps/40-keyboard.ps1` after installing, to register it in the
   language list the same way as US-Dvorak.

## whkd + custom layout risk

`whkd` resolves key names through the **active keyboard layout**. If Real
Programmer Dvorak is active when whkd starts, `win + h` may bind to the
physical key that produces `h` in Dvorak rather than the QWERTY `h`
position -- the same class of problem the Linux config solves with raw
keycodes (`code:10`-`code:21` in
`~/.dotfiles/hypr/.config/hypr/bindings.lua`).

**Test this before trusting the generated `whkdrc`:** switch to the custom
layout, restart whkd, and confirm `win + h` still focuses left. If it
doesn't, move the letter-key binds from `whkd/.config/whkdrc` into
`ahk/.config/ahk/omarchy.ahk`, which can bind by scancode (e.g. `SC023`)
independent of the active layout.
