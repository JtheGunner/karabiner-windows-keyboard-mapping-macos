#!/usr/bin/env bash
# Tests for apply.sh, against a throwaway HOME. Run: bash tests/apply-test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { echo "FAIL: $CURRENT: $*"; FAILED=1; }
it() { CURRENT="$1"; echo "- $1"; }
assert_contains() { case "$1" in *"$2"*) ;; *) fail "expected [$2] in: $1" ;; esac; }
assert_not_contains() { case "$1" in *"$2"*) fail "did not expect [$2] in: $1" ;; esac; }
backups() { ls "$H/.config/karabiner" | grep -c '^karabiner-bkp-' || true; }

# run_apply ARG... -> OUT, RC; HOME is $H
run_apply() { OUT="$(HOME="$H" bash "$REPO/apply.sh" "$@" 2>&1)"; RC=$?; }

it "a first apply copies everything, no backup without an old karabiner.json"
H="$TMP/h1"
mkdir -p "$H/.config/karabiner"
run_apply
[ "$RC" = 0 ] || fail "exit $RC"
assert_contains "$OUT" "copied  $H/.config/karabiner/karabiner.json"
cmp -s "$REPO/karabiner.json" "$H/.config/karabiner/karabiner.json" || fail "karabiner.json not copied"
[ "$(backups)" = 0 ] || fail "backup without an old file"

it "a second apply leaves identical files alone: no copy, no backup"
run_apply
[ "$RC" = 0 ] || fail "exit $RC"
assert_not_contains "$OUT" "copied"
assert_not_contains "$OUT" "backup"
assert_contains "$OUT" "already up to date"
[ "$(backups)" = 0 ] || fail "backup of an unchanged file"

it "a changed karabiner.json is backed up, then replaced; unchanged fragments stay"
echo '{"changed": true}' > "$H/.config/karabiner/karabiner.json"
run_apply
assert_contains "$OUT" "backup  $H/.config/karabiner/karabiner-bkp-"
assert_contains "$OUT" "copied  $H/.config/karabiner/karabiner.json"
assert_not_contains "$OUT" "winkeys-"
[ "$(backups)" = 1 ] || fail "expected one backup"

it "a dry run names only what would change"
echo '{"changed": true}' > "$H/.config/karabiner/karabiner.json"
run_apply --dry-run
assert_contains "$OUT" "would copy  $REPO/karabiner.json"
assert_not_contains "$OUT" "winkeys-"
assert_contains "$(cat "$H/.config/karabiner/karabiner.json")" '"changed": true'

[ "$FAILED" = 0 ] && echo "all passed"
exit "$FAILED"
