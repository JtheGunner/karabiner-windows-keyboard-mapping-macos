#!/usr/bin/env bash
# Pull the live Karabiner config back into this repo (after GUI edits).
#
#   ./export.sh   copy ~/.config/karabiner/karabiner.json + winkeys-* fragments
#                 into the repo, then show `git diff` so you can review.
#
# The winkeys-* fragments are the *source* rules; karabiner.json is the
# assembled profile. If you added/edited a rule in the GUI, also mirror the
# change into the matching winkeys-*.json by hand (the GUI does not).
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
LIVE="$HOME/.config/karabiner"

[[ -f "$LIVE/karabiner.json" ]] || { echo "no $LIVE/karabiner.json"; exit 1; }

cp "$LIVE/karabiner.json" "$REPO/karabiner.json"
for f in "$LIVE"/assets/complex_modifications/winkeys-*.json; do
  [[ -e "$f" ]] && cp "$f" "$REPO/assets/complex_modifications/"
done

echo "pulled live config into the repo. Review:"
echo
git -C "$REPO" --no-pager diff --stat
echo
echo "  git -C '$REPO' diff        # full diff"
echo "  reminder: mirror any new/changed GUI rule into its winkeys-*.json source"
