#!/usr/bin/env bash
# Tests for the shipped config: karabiner.json, the winkeys-* fragments and
# bin/set-machine-config.py. Run: bash tests/config-test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

fail() { echo "FAIL: $CURRENT: $*"; FAILED=1; }
it() { CURRENT="$1"; echo "- $1"; }
assert_eq() { [ "$1" = "$2" ] || fail "expected [$2], got [$1]"; }

MX_KEYS=45915
INSERT_RULE="Ctrl+Insert / Shift+Insert => copy / paste  (all apps; IDEs keep their own Insert bindings; excluded in RDP & VM clients)"
ALT_INSERT_RULE="Alt (left_command on this keyboard)+Insert => Option+Insert in IDEs (Generate / New element; +Shift = column selection)"
ALT_DIGIT_RULE="Alt (left_command on this keyboard)+0..9 => Ctrl+Shift+Option+Cmd+0..9 in IDEs (tool windows; keeps AltGr = right Option free to type | @ # |)"

# query EXPR -> prints the Python expression EXPR, evaluated with the helpers below
query() {
  REPO="$REPO" python3 - "$1" <<'EOF'
import json, os, runpy, sys
from pathlib import Path

repo = Path(os.environ["REPO"])
profile = next(p for p in json.loads((repo / "karabiner.json").read_text())["profiles"] if p.get("selected"))
rules = {r["description"]: r for r in profile["complex_modifications"]["rules"]}

def rule(description):
    return rules["[winkeys] " + description]

def fragment_rules_out_of_sync():
    fragments = sorted((repo / "assets" / "complex_modifications").glob("winkeys-*.json"))
    return [f"{f.name}: {r['description']}"
            for f in fragments for r in json.loads(f.read_text())["rules"]
            if rules.get("[winkeys] " + r["description"], {}).get("manipulators") != r["manipulators"]]

def script_devices():
    return runpy.run_path(str(repo / "bin" / "set-machine-config.py"))["DEVICES"]

def device_swaps(product_id):
    device = next(d for d in profile["devices"] if d["identifiers"].get("product_id") == product_id)
    return sorted((m["from"]["key_code"], m["to"][0]["key_code"]) for m in device.get("simple_modifications", []))

def devices_with_simple_mods():
    return [d["identifiers"].get("product_id") for d in profile["devices"] if d.get("simple_modifications")]

def scope(description, bundle):
    # -> (condition type, whether bundle is listed) of every manipulator
    return [(m["conditions"][0]["type"], bundle in m["conditions"][0]["bundle_identifiers"])
            for m in rule(description)["manipulators"]]

def mappings(description):
    return [(m["from"], m["to"]) for m in rule(description)["manipulators"]]

sys.dont_write_bytecode = True
print(eval(sys.argv[1]))
EOF
}

it "every winkeys fragment rule is in karabiner.json verbatim"
assert_eq "$(query 'fragment_rules_out_of_sync()')" "[]"

it "set-machine-config.py DEVICES match karabiner.json"
assert_eq "$(query 'script_devices() == profile["devices"]')" "True"

it "the MX Keys swaps Alt and Win back from its Windows mode"
assert_eq "$(query "device_swaps($MX_KEYS)")" "[('left_command', 'left_option'), ('left_option', 'left_command')]"

it "no other device carries simple modifications"
assert_eq "$(query 'devices_with_simple_mods()')" "[$MX_KEYS]"

it "Ctrl+Insert copies and Shift+Insert pastes"
assert_eq "$(query "mappings('$INSERT_RULE')")" \
  "[({'key_code': 'insert', 'modifiers': {'mandatory': ['left_control'], 'optional': ['caps_lock']}}, [{'key_code': 'c', 'modifiers': ['left_command']}]), ({'key_code': 'insert', 'modifiers': {'mandatory': ['left_shift'], 'optional': ['caps_lock']}}, [{'key_code': 'v', 'modifiers': ['left_command']}])]"

it "Ctrl/Shift+Insert skip IDEs and VM clients but not terminals"
assert_eq "$(query "scope('$INSERT_RULE', r'^com\.jetbrains\.')")" "[('frontmost_application_unless', True), ('frontmost_application_unless', True)]"
assert_eq "$(query "scope('$INSERT_RULE', r'^com\.parallels\.desktop$')")" "[('frontmost_application_unless', True), ('frontmost_application_unless', True)]"
assert_eq "$(query "scope('$INSERT_RULE', r'^com\.apple\.Terminal$')")" "[('frontmost_application_unless', False), ('frontmost_application_unless', False)]"

it "Alt+Insert becomes Option+Insert, Shift passes through"
assert_eq "$(query "mappings('$ALT_INSERT_RULE')")" \
  "[({'key_code': 'insert', 'modifiers': {'mandatory': ['left_command'], 'optional': ['caps_lock', 'shift']}}, [{'key_code': 'insert', 'modifiers': ['left_option']}])]"

it "Alt+Insert applies in exactly the IDEs of the Alt+digit rule"
assert_eq "$(query "rule('$ALT_INSERT_RULE')['manipulators'][0]['conditions'] == rule('$ALT_DIGIT_RULE')['manipulators'][0]['conditions']")" "True"

[ "$FAILED" = 0 ] && echo "all passed"
exit "$FAILED"
