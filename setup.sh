#!/usr/bin/env bash
# First-time setup on a fresh Mac.
#
#   1. install Karabiner-Elements (Homebrew cask) if missing
#   2. apply this repo's config          (./apply.sh)
#   3. set machine-level bits            (bin/set-machine-config.py)
#   4. print the manual permission steps (cannot be scripted)
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"

# --- 1. install ------------------------------------------------------------
if [[ -d "/Applications/Karabiner-Elements.app" ]]; then
  echo "Karabiner-Elements: already installed"
elif command -v brew >/dev/null 2>&1; then
  echo "installing Karabiner-Elements via Homebrew ..."
  brew install --cask karabiner-elements
else
  echo "Homebrew not found. Install Karabiner-Elements manually:"
  echo "  https://karabiner-elements.pqrs.org/"
  exit 1
fi

# Karabiner needs to run once to create ~/.config/karabiner/
open -ga "Karabiner-Elements" || true
for _ in $(seq 1 20); do [[ -d "$HOME/.config/karabiner" ]] && break; sleep 0.5; done

# --- 2 + 3. apply config -------------------------------------------------------
"$REPO/apply.sh"
python3 "$REPO/bin/set-machine-config.py"

# --- 4. permissions (manual - macOS will not let a script grant these) -------
cat <<'EOF'

────────────────────────────────────────────────────────────────────────────
MANUAL STEPS (macOS security - no script can do these):

1. System Extension
   System Settings > General > Login Items & Extensions > Driver Extensions
   -> enable "Karabiner-DriverKit-VirtualHIDDevice"

2. Input Monitoring
   System Settings > Privacy & Security > Input Monitoring
   -> enable "karabiner_grabber" (and "Karabiner-Elements")

3. Accessibility
   System Settings > Privacy & Security > Accessibility
   -> enable "Karabiner-Elements"

Opening the relevant panes now...
────────────────────────────────────────────────────────────────────────────
EOF
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" || true
open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension" || true

echo
echo "After granting the permissions, the config is live (Karabiner hot-reloads)."
