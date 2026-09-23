# Windows keyboard mapping for macOS (Karabiner-Elements)

Full **Windows / PC muscle memory** on a macOS box with a Swiss‑German ISO PC
keyboard — `Ctrl+C/V/Z/Y`, `Ctrl+←/→` word jump, `Home/End`, `Ctrl+Backspace`,
`Alt+F4`, `F2` rename, browser `F5/F12`, … — **while keeping real UNIX terminal
behaviour** (`Ctrl+C` = SIGINT) and leaving IDEs' own keymaps untouched.

Companion pieces: the Swiss AltGr characters (`@ \ ~ [] {} €`) come from a
[custom keyboard layout](https://github.com/JtheGunner/swiss-windows-keyboard-layout-macos),
not Karabiner. Overview: [macos-base-config](https://github.com/JtheGunner/macos-base-config).

## Design

Two things this config is careful about:

1. **Terminals are not IDEs.** VS Code / Antigravity / JetBrains / Cursor /
   Zed keep their *native* keymaps (they run Windows‑style keymaps themselves).
   The PC‑Ctrl swap and the cursor/word rules are `frontmost_application_unless`
   the IDE bundle ids; the *terminal‑only* rules are `frontmost_application_if`
   real terminal emulators (Terminal, iTerm2, Ghostty, Warp, Tabby, WezTerm,
   Kitty, Alacritty, Hyper) — **the IDE bundle ids are deliberately not in that
   list**, so an IDE's editor never gets terminal rewrites.
2. **`Ctrl+C` stays SIGINT in terminals.** The clipboard verbs are remapped
   only outside terminals; inside, `Ctrl+Shift+C/V` are copy/paste.

### Rule groups (`assets/complex_modifications/winkeys-*.json`)

| # | group | scope |
|---|-------|-------|
| 05 | `Shift+Enter` => real newline (Claude Code, REPLs, Electron editors) | terminals + a few Electron apps |
| 10 | PC‑style Ctrl: `left_control+<key>` => `left_command+<key>` | all GUI apps **except** terminals, RDP/VM clients, IDEs |
| 15 | `Ctrl+Y` (QWERTZ physical Y) => Redo | GUI apps (runs before 10) |
| 20 | `Ctrl+Home/End`, `Home/End`, `Ctrl+←/→` word jump, `Ctrl+Backspace/Delete` word delete | all GUI apps **except** terminals + IDEs |
| 25 | Terminals: `Ctrl+←/→` => `Option+←/→` word motion | **real terminals only** |
| 35 | `Ctrl+left‑click` => `Cmd+left‑click` (discontiguous multi‑select) | all |
| 40 | Terminals: `Ctrl+Shift+C/V/F/A`, `Ctrl+T/N`, `Ctrl/Shift+Insert` | **real terminals only** |
| 45 | IDEs: `Alt+0…9` (physical Alt = `left_command`) => `Ctrl+Shift+Alt+Cmd+0…9` (tool windows); AltGr (right Option) stays untouched so `AltGr+1/2/3/7` type `\| @ # \|` | IDEs only |
| 50 | `Alt+F4` => close window · `Ctrl+Space` => Spotlight | all |
| 60 | Finder: `F2` => rename · `Enter` => open selected item | Finder |
| 70 | Browser: `F5`/`Ctrl+F5` reload · `F12` DevTools · `Ctrl+H` history · `Ctrl`+keypad `-/+/0` zoom | browsers (runs before 10) |

Rule 45 exists because macOS apps cannot tell left from right Option: an IDE
shortcut on `Option+3` swallows the `#` that AltGr+3 (right Option) should type.
So the IDE keymaps keep `Option+<digit>` free, and the physical Alt key, which
arrives as `left_command` like in the Alt+F4 rule, is rewritten instead. The IDE keymaps must bind
their tool windows to `Ctrl+Shift+Alt+Cmd+<digit>` and have no `Alt+<digit>`
left; for the VS Code family,
[intelli-key-port](https://github.com/JtheGunner/intelli-key-port) ports that
from the JetBrains keymap.

In the VS Code family, rule 20 rewrites `Ctrl+←/→` and `Home`/`End` before the
editor sees them (e.g. in Antigravity IDE). Port with
`intelli-key-port --layer karabiner-winkeys` so the editor bindings match.

`karabiner.json` also carries a handful of personal rules that are **not** part
of the winkeys set and live only in that file (Option+. emoji, Option+V
clipboard history, screenshot, mouse side‑keys, format‑doc, Launchpad, …).

The `winkeys-*.json` files are the **source** rule library (importable in the
Karabiner GUI). `karabiner.json` is the **assembled** profile that
`./apply.sh` installs.

## Install / apply

```sh
./setup.sh        # fresh Mac: brew‑install Karabiner + apply + machine config + permission steps
./apply.sh        # already have Karabiner: back up the live config, copy this repo's in
./apply.sh --dry-run
./export.sh       # pull the live config back into the repo after GUI tweaks
```

`setup.sh` cannot grant the three macOS permissions Karabiner needs (Driver
Extension, Input Monitoring, Accessibility) — it opens the panes and prints the
steps. Everything else is automated; Karabiner hot‑reloads `karabiner.json`.

### Machine‑level bits

`karabiner_cli` has no command for `simple_modifications` / device settings, so
`bin/set-machine-config.py` edits `~/.config/karabiner/karabiner.json` directly
(backup first, Karabiner reloads):

```sh
python3 bin/set-machine-config.py          # right_command→right_option (AltGr) + iso layout + known Logitech devices
python3 bin/set-machine-config.py --show   # print current values only
python3 bin/set-machine-config.py --iso    # one at a time: --simple-mods / --iso / --devices
```

Device entries are keyed by USB vendor/product id (Logitech, `vendor_id 1133`);
they only match that exact hardware and are harmless otherwise. Adjust
`DEVICES` in the script for your gear.

## Rollback

Every write makes a timestamped backup next to the live file:

```sh
cp ~/.config/karabiner/karabiner-bkp-<timestamp>.json ~/.config/karabiner/karabiner.json
```

Karabiner's own `automatic_backups/` is another safety net (git‑ignored here).

## Credits

[Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) by pqrs.org.

## Contributing

Issues and pull requests are welcome. Try changes with `./apply.sh --dry-run`
first; after tweaking rules in the Karabiner GUI, run `./export.sh` so the PR
contains the updated `karabiner.json`.

## License

[MIT](LICENSE)
