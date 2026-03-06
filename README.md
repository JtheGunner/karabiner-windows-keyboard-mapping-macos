# Windows Keyboard Mapping for macOS

This repository provides a Karabiner-Elements configuration to remap your Mac keyboard to match the layout and behavior of a classic Microsoft Windows system.

## Features

- Remaps macOS keys to Windows equivalents (e.g., Command ⌘ to Control, Option ⌥ to Alt)
- Adjusts function keys and shortcuts for Windows-like usage
- Designed for seamless transition between Windows and macOS environments

## Configuration Details

The included `karabiner.json` provides a comprehensive set of key remappings and shortcut adjustments to mimic Windows keyboard behavior on macOS. Some highlights:

- **Modifier Key Swaps:**
  - Command ⌘ and Control are swapped for Windows-like shortcuts.
  - Option ⌥ is mapped to Alt.

- **Shortcut Remapping:**
  - Common Windows shortcuts (Ctrl+C, Ctrl+V, Ctrl+Z, Ctrl+Y, etc.) are mapped to their macOS equivalents.
  - Function keys (F2, F4, F5) are remapped for actions like rename, exit, and reload.
  - Navigation keys (Home, End, Ctrl+Arrow) are adjusted for familiar Windows cursor movement.

- **Application-Specific Rules:**
  - Terminal, IDEs, browsers, and Finder have custom shortcut behaviors for improved usability.

- **Special Actions:**
  - Open Finder with Option+E.
  - Delete files in Finder with Delete mapped to Cmd+Backspace.
  - Rename files in Finder with F2 mapped to Enter.

- **Device Support:**
  - The configuration is tailored for keyboards and pointing devices, ensuring compatibility.

You can further customize these mappings by editing the `karabiner.json` file or by using the Karabiner-Elements interface to suit your workflow.

## Installation

1. Install [Karabiner-Elements](https://karabiner-elements.pqrs.org/).
2. Download the `karabiner.json` configuration file from this repository.
3. Copy the configuration file (karabiner.json) to your Karabiner-Elements directory:

    ```bash
    cp karabiner.json ~/.config/karabiner/
    ```

## Usage

Once enabled, your Mac keyboard will behave like a Windows keyboard, making it easier for Windows users to adapt to macOS.

## Credits

- [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements)
- Inspired by Windows keyboard layouts
