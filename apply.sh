#!/usr/bin/env bash
# Apply this repo's Karabiner config to the live location.
#
#   ./apply.sh            copy karabiner.json + the winkeys-* fragments into
#                         ~/.config/karabiner/ (timestamped backup first).
#                         Files that are already identical are left alone.
#   ./apply.sh --dry-run  show what would happen, change nothing.
#
# Karabiner-Elements watches ~/.config/karabiner/karabiner.json and hot-reloads,
# so no restart is needed. To pull GUI tweaks back into the repo: ./export.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
LIVE="$HOME/.config/karabiner"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=false
[[ "${1:-}" == "--dry-run" ]] && DRY=true

CHANGED=0
copy() {  # copy() SRC DST - skipped when DST already has SRC's content
  cmp -s "$1" "$2" && return 0
  CHANGED=$((CHANGED + 1))
  if $DRY; then echo "  would copy  $1 -> $2"; else cp "$1" "$2"; echo "  copied  $2"; fi
}

[[ -f "$REPO/karabiner.json" ]] || { echo "missing $REPO/karabiner.json"; exit 1; }
[[ -d "$LIVE" ]] || { echo "$LIVE missing - is Karabiner-Elements installed? run ./setup.sh"; exit 1; }

if [[ -f "$LIVE/karabiner.json" ]] && ! cmp -s "$REPO/karabiner.json" "$LIVE/karabiner.json"; then
  if $DRY; then echo "  would back up  $LIVE/karabiner.json -> karabiner-bkp-$STAMP.json"
  else cp -p "$LIVE/karabiner.json" "$LIVE/karabiner-bkp-$STAMP.json"
       echo "  backup  $LIVE/karabiner-bkp-$STAMP.json"; fi
fi

copy "$REPO/karabiner.json" "$LIVE/karabiner.json"

$DRY || mkdir -p "$LIVE/assets/complex_modifications"
for f in "$REPO"/assets/complex_modifications/winkeys-*.json; do
  copy "$f" "$LIVE/assets/complex_modifications/$(basename "$f")"
done

if [[ "$CHANGED" = 0 ]]; then
  echo "  already up to date: $LIVE"
  exit 0
fi
$DRY && { echo $'\n(dry run - nothing changed)'; exit 0; }
echo $'\nDone. Karabiner reloads automatically.'
