<div align="center">

# ⌨️ Windows Keyboard Mapping for macOS

**Windows / PC muscle memory on a Mac, without breaking the terminal.**

<code>🪟 PC keyboard (Swiss ISO)</code> &nbsp;→&nbsp; <code>🔄 Karabiner-Elements</code> &nbsp;→&nbsp; <code>🍎 macOS apps · terminals · IDEs</code>

![License](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square)
![Platform](https://img.shields.io/badge/platform-macOS-0ea5e9?style=flat-square&logo=apple&logoColor=white)
![Karabiner-Elements](https://img.shields.io/badge/Karabiner--Elements-15%2B-8b5cf6?style=flat-square)
![Python](https://img.shields.io/badge/python-3-3776ab?style=flat-square&logo=python&logoColor=white)
![PRs welcome](https://img.shields.io/badge/PRs-welcome-f59e0b?style=flat-square)

</div>

---

## 🎯 What it is

A [Karabiner-Elements](https://karabiner-elements.pqrs.org/) configuration for
a Mac driven by a **Swiss-German ISO PC keyboard**. It gives you the Windows
shortcuts your fingers already know:

- `Ctrl+C/V/X/Z/Y`, `Ctrl+S`, `Ctrl+F`, … in every GUI app
- `Home` / `End`, `Ctrl+Home/End`, `Ctrl+←/→` word jump, `Ctrl+Backspace/Delete`
- `Alt+F4`, `Ctrl+Space` (Spotlight), `F2` rename and `Enter` open in Finder
- `F5`, `F12`, `Ctrl+H` and `Ctrl`+keypad zoom in browsers

…while **terminals keep real UNIX behaviour** (`Ctrl+C` = SIGINT) and **IDEs
keep their own keymaps**.

| Piece | Where it lives |
|-------|----------------|
| Windows shortcuts (this repo) | Karabiner-Elements |
| Swiss AltGr characters (`@ # \| \ ~ [] {} €`) | [swiss-windows-keyboard-layout-macos](https://github.com/JtheGunner/swiss-windows-keyboard-layout-macos) (a keyboard layout, not Karabiner) |
| IDE keymaps for the VS Code family | [intelli-key-port](https://github.com/JtheGunner/intelli-key-port) |
| Whole-Mac bootstrap that wires it all together | [macos-base-config](https://github.com/JtheGunner/macos-base-config) |

---

## 🧭 Design

Every key press is routed by the app in front:

```text
                 ┌──────────────────────────────────────────────┐
  key press ───▶ │ Karabiner: which app is frontmost?           │
                 └──────────────────────────────────────────────┘
                   │                 │                  │
             terminal              IDE            any other GUI app
                   │                 │                  │
     Ctrl stays Ctrl (SIGINT)  native keymap      Ctrl → Cmd (PC-style)
     Ctrl+Shift+C/V = copy/paste  + Alt+digit →    Home/End, word jump,
     Ctrl+←/→ = word motion       tool windows     Alt+F4, F2, F5, …
```

1. **Terminals are not IDEs.** Terminal-only rules match real terminal
   emulators — Terminal, iTerm2, Ghostty, Warp, Tabby, WezTerm, Kitty,
   Alacritty, Hyper. IDE bundle ids are **deliberately not** in that list, so an
   IDE's editor never gets terminal rewrites.
2. **IDEs keep their native keymaps.** VS Code (+ Insiders), VSCodium, Cursor,
   Windsurf, Zed, Antigravity and all JetBrains IDEs run Windows-style keymaps
   themselves, so the PC-Ctrl swap and the cursor rules skip them.
3. **`Ctrl+C` stays SIGINT in terminals.** Clipboard verbs are remapped only
   outside terminals; inside, `Ctrl+Shift+C/V` (or `Ctrl/Shift+Insert`) copy
   and paste.
4. **Remote and VM clients get raw keys.** Microsoft Remote Desktop, Parallels,
   VMware, VirtualBox, Citrix, TeamViewer, Parsec, … are excluded from the
   PC-Ctrl swap, the cursor rules and the system verbs, so the Windows guest
   receives the keys unchanged.

---

## 🗂️ Rule groups

Source files: `assets/complex_modifications/winkeys-<nn>-*.json`. In
`karabiner.json` every rule of this set is prefixed with `[winkeys]`.

|    | #  | Rule group                                                                                                             | Active in                                                        |
|:--:|----|------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| ↩️ | 05 | `Shift+Enter` → real newline (Claude Code, zsh, REPLs)                                                                 | terminals + Windsurf, VSCodium, Code-OSS, Zed                    |
| 🔁 | 10 | PC-style Ctrl: `left_control+<key>` → `left_command+<key>`                                                             | GUI apps **except** terminals, IDEs, remote/VM clients           |
| ↪️ | 15 | `Ctrl+Y` (physical QWERTZ Y) → Redo                                                                                    | same scope as 10                                                 |
| 🔤 | 20 | `Home/End`, `Ctrl+Home/End`, `Ctrl+←/→` word jump, `Ctrl+Backspace/Delete` word delete                                 | GUI apps **except** terminals, IDEs, remote/VM clients ¹         |
| 💻 | 25 | `Ctrl+←/→` → `Option+←/→` word motion                                                                                  | **terminals only**                                               |
| 🖱️ | 35 | `Ctrl+left-click` → `Cmd+left-click` (discontiguous multi-select)                                                      | everywhere                                                       |
| 📋 | 40 | `Ctrl+Shift+C/V/F/A`, `Ctrl+T/N`, `Ctrl/Shift+Insert`                                                                  | **terminals only**                                               |
| 🧰 | 45 | `Alt+0…9` → `Ctrl+Shift+Alt+Cmd+0…9` (tool windows); AltGr stays free so `AltGr+1/2/3/7` type `\| @ # \|`             | **IDEs only**                                                    |
| ❌ | 50 | `Alt+F4` → close window · `Ctrl+Space` → Spotlight                                                                     | everywhere except remote/VM clients                              |
| 📁 | 60 | `F2` → rename · `Enter` → open selected item                                                                           | Finder                                                           |
| 🌐 | 70 | `F5` / `Ctrl+F5` reload · `F12` DevTools · `Ctrl+H` history · `Ctrl`+keypad `-/+/0` zoom                               | Safari, Chrome, Brave, Edge, Firefox, Arc, Dia                   |

¹ Exception: **Antigravity IDE** is *not* excluded from `Home/End`,
`Ctrl+Home/End` and `Ctrl+←/→`, so these keys also work in its agent-chat input.
Port your editor keymap with `intelli-key-port --layer karabiner-winkeys` so
the editor side matches the rewritten keys.

> [!IMPORTANT]
> Karabiner evaluates rules top-down and the first match wins. The group number
> is an id, not the position: in `karabiner.json`, groups **15** and **70** sit
> **before** group 10, otherwise the generic Ctrl→Cmd swap would swallow
> `Ctrl+Y`, `Ctrl+H` and `Ctrl+F5`.

### 🧰 Why rule 45 exists

macOS apps cannot tell left from right Option. An IDE shortcut on `Option+3`
therefore swallows the `#` that `AltGr+3` (right Option) should type. The fix:

- the physical **Alt** key, which arrives as `left_command` on this keyboard,
  is rewritten to `Ctrl+Shift+Alt+Cmd+<digit>` inside IDEs;
- the IDE keymaps bind their tool windows to `Ctrl+Shift+Alt+Cmd+<digit>` and
  keep **no** `Alt+<digit>` binding — for the VS Code family,
  [intelli-key-port](https://github.com/JtheGunner/intelli-key-port) ports that
  from the JetBrains keymap.

### ✨ Personal extras

`karabiner.json` also carries a few rules that are **not** part of the
`winkeys` set and have no source file:

| Shortcut              | Action                                  |
|-----------------------|-----------------------------------------|
| `Option+.`            | emoji picker                            |
| `Option+V`            | macOS clipboard history                 |
| `Option+Shift+S`      | area screenshot to the clipboard        |
| mouse side keys       | back / forward                          |
| `Cmd+Option+L`        | format document in IDEs                 |
| `Option+L`            | lock screen                             |
| `Ctrl+Esc`            | Launchpad                               |
| `Ctrl+Cmd+Delete`     | Activity Monitor                        |
| `Option+E`            | open Finder                             |

---

## 📋 Requirements

- macOS with [Homebrew](https://brew.sh/) (or Karabiner-Elements installed manually)
- `python3` (ships with the Xcode Command Line Tools)
- A PC keyboard with an ISO layout — the machine config below assumes a Swiss-German one

---

## 🚀 Install

|    | Command                | What it does                                                                                        |
|:--:|------------------------|-----------------------------------------------------------------------------------------------------|
| 🆕 | `./setup.sh`           | Fresh Mac: installs Karabiner-Elements via Homebrew, runs `apply.sh` and `set-machine-config.py`, opens the permission panes |
| 📥 | `./apply.sh`           | Backs up the live config, copies `karabiner.json` and the `winkeys-*.json` files into `~/.config/karabiner/` |
| 👀 | `./apply.sh --dry-run` | Shows what `apply.sh` would do, changes nothing                                                    |
| 📤 | `./export.sh`          | Pulls the live config back into the repo after GUI tweaks and shows the `git diff --stat`          |

Karabiner hot-reloads `karabiner.json` — no restart needed.

> [!WARNING]
> No script can grant the three macOS permissions Karabiner needs. After
> `setup.sh`, enable them by hand in **System Settings**:
> **Driver Extensions** → `Karabiner-DriverKit-VirtualHIDDevice`,
> **Input Monitoring** → `karabiner_grabber`,
> **Accessibility** → `Karabiner-Elements`.

### 🔧 Machine-level settings

`karabiner_cli` cannot set simple modifications or device settings, so
`bin/set-machine-config.py` edits the selected profile in
`~/.config/karabiner/karabiner.json` directly (backup first):

```sh
python3 bin/set-machine-config.py          # all of the below
python3 bin/set-machine-config.py --show   # print current values, change nothing
python3 bin/set-machine-config.py --iso    # one at a time: --simple-mods / --iso / --devices
```

| Flag            | Sets                                                                  |
|-----------------|-----------------------------------------------------------------------|
| `--simple-mods` | `right_command` → `right_option`, so the right Alt key acts as AltGr  |
| `--iso`         | virtual keyboard type `iso`                                           |
| `--devices`     | known Logitech keyboard/mice (vendor id `1133`); edit `DEVICES` in the script for your hardware — entries only match that exact device and are harmless otherwise |

---

## 📁 Repository layout

```
assets/complex_modifications/winkeys-*.json   source rule groups (importable in the Karabiner GUI)
karabiner.json                                full profile that apply.sh installs
apply.sh · export.sh · setup.sh               install / sync scripts
bin/set-machine-config.py                     machine-level settings
tests/apply-test.sh                           tests for apply.sh (bash tests/apply-test.sh)
```

> [!NOTE]
> There is no build step. `karabiner.json` contains the `winkeys` rules verbatim
> (prefixed `[winkeys]`), so a rule change has to land in **both** its
> `winkeys-*.json` file and `karabiner.json`. `export.sh` only syncs
> `karabiner.json` — mirror GUI edits into the matching source file by hand.

---

## ⏪ Rollback

Every write by `apply.sh` or `set-machine-config.py` leaves a timestamped backup
next to the live file. `apply.sh` leaves files that already match this repo
alone, so a re-run without changes writes nothing and makes no backup:

```sh
cp ~/.config/karabiner/karabiner-bkp-<timestamp>.json ~/.config/karabiner/karabiner.json
```

Karabiner's own `~/.config/karabiner/automatic_backups/` is a second safety net.

---

## 🤝 Contributing

Issues and pull requests are welcome. Try changes with `./apply.sh --dry-run`
first and run the tests with `bash tests/apply-test.sh`. After tweaking rules in the Karabiner GUI, run `./export.sh` and update
the matching `winkeys-*.json` so both files stay in sync in your PR.

---

## 📄 License

MIT — see [LICENSE](LICENSE). © 2026 Jeffry Würmli.

Built on [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) by pqrs.org.

---

<div align="center"><sub>Made for fingers that learned on Windows and moved to a Mac. ⌨️</sub></div>
