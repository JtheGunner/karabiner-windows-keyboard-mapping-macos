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
CHAT_RULE="Antigravity agent chat: Ctrl+A => Cmd+A, Ctrl+C => Ctrl+Insert, Ctrl+Z => Cmd+Z, Ctrl+Y => Cmd+Shift+Z (the chat swallows or misroutes these; the IDE keymap sends them on as ^A / ^C / ^Z / ^Y in the terminal)"
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

def position(description):
    return list(rules).index("[winkeys] " + description)

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

it "Ctrl+A / C / Z / Y become Cmd/Ctrl+Insert equivalents in both Antigravity apps only"
assert_eq "$(query "mappings('$CHAT_RULE')")" "[({'key_code': 'a', 'modifiers': {'mandatory': ['left_control'], 'optional': ['caps_lock']}}, [{'key_code': 'a', 'modifiers': ['left_command']}]), ({'key_code': 'c', 'modifiers': {'mandatory': ['left_control'], 'optional': ['caps_lock']}}, [{'key_code': 'insert', 'modifiers': ['left_control']}]), ({'key_code': 'y', 'modifiers': {'mandatory': ['left_control'], 'optional': ['caps_lock']}}, [{'key_code': 'y', 'modifiers': ['left_command']}]), ({'key_code': 'z', 'modifiers': {'mandatory': ['left_control'], 'optional': ['caps_lock']}}, [{'key_code': 'y', 'modifiers': ['left_command', 'left_shift']}])]"
assert_eq "$(query "scope('$CHAT_RULE', r'^com\\.google\\.antigravity-ide\$')")" "[('frontmost_application_if', True), ('frontmost_application_if', True), ('frontmost_application_if', True), ('frontmost_application_if', True)]"
assert_eq "$(query "scope('$CHAT_RULE', r'^com\\.google\\.antigravity\$')")" "[('frontmost_application_if', True), ('frontmost_application_if', True), ('frontmost_application_if', True), ('frontmost_application_if', True)]"
assert_eq "$(query "scope('$CHAT_RULE', r'^com\\.microsoft\\.VSCode\$')")" "[('frontmost_application_if', False), ('frontmost_application_if', False), ('frontmost_application_if', False), ('frontmost_application_if', False)]"

it "Alt+Insert becomes Option+Insert, Shift passes through"
assert_eq "$(query "mappings('$ALT_INSERT_RULE')")" \
  "[({'key_code': 'insert', 'modifiers': {'mandatory': ['left_command'], 'optional': ['caps_lock', 'shift']}}, [{'key_code': 'insert', 'modifiers': ['left_option']}])]"

it "Alt+Insert applies in exactly the IDEs of the Alt+digit rule"
assert_eq "$(query "rule('$ALT_INSERT_RULE')['manipulators'][0]['conditions'] == rule('$ALT_DIGIT_RULE')['manipulators'][0]['conditions']")" "True"

MOUSE_RULE="Mouse side-keys: back / forward => Cmd+Opt+[ / Cmd+Opt+] in every app that lacks native support (Finder, System Settings, ...); browsers, IDEs, terminals, RDP & VM clients keep their own handling"

it "mouse back/forward send Cmd+Opt+[ / Cmd+Opt+]"
assert_eq "$(query "[(m['from']['pointing_button'], m['to'][0]['key_code'], m['to'][0]['modifiers']) for m in rules['$MOUSE_RULE']['manipulators']]")" \
  "[('button4', 'open_bracket', ['left_command', 'left_option']), ('button5', 'close_bracket', ['left_command', 'left_option'])]"

it "mouse side keys skip browsers, IDEs, terminals and VM clients but not Finder"
mouse_scope() {
  query "[(m['conditions'][0]['type'], r'$1' in m['conditions'][0]['bundle_identifiers']) for m in rules['$MOUSE_RULE']['manipulators']]"
}
for app in '^com\.apple\.Safari' '^com\.google\.Chrome' '^org\.mozilla\.firefox$' '^com\.jetbrains\.' '^com\.microsoft\.VSCode$' '^com\.apple\.Terminal$' '^com\.parallels\.desktop$'; do
  assert_eq "$(mouse_scope "$app")" "[('frontmost_application_unless', True), ('frontmost_application_unless', True)]"
done
assert_eq "$(mouse_scope '^com\.apple\.finder$')" "[('frontmost_application_unless', False), ('frontmost_application_unless', False)]"

F2_RULE="Finder: F2 => Return (rename)"
CONFIRM_RULE="Finder: Enter while renaming => Return (confirm rename)"
CANCEL_RULE="Finder: Escape while renaming => Escape (cancel rename)"
CLICK_RULE="Finder: click while renaming => end rename"
OPEN_RULE="Finder: Enter => Cmd+O (open selected item)"
RENAMING_ON="{'set_variable': {'name': 'finder_renaming', 'value': 1}}"
RENAMING_OFF="{'set_variable': {'name': 'finder_renaming', 'value': 0}}"
FINDER_ONLY="{'type': 'frontmost_application_if', 'bundle_identifiers': ['^com\\\\.apple\\\\.finder\$']}"
WHILE_RENAMING="{'type': 'variable_if', 'name': 'finder_renaming', 'value': 1}"

it "F2 starts the rename and remembers it"
assert_eq "$(query "[m['to'] for m in rule('$F2_RULE')['manipulators']]")" "[[$RENAMING_ON, {'key_code': 'return_or_enter'}]]"

it "Enter while renaming confirms with a plain Return and forgets the rename"
assert_eq "$(query "mappings('$CONFIRM_RULE')")" "[({'key_code': 'return_or_enter', 'modifiers': {'optional': ['caps_lock']}}, [{'key_code': 'return_or_enter'}, $RENAMING_OFF])]"
assert_eq "$(query "rule('$CONFIRM_RULE')['manipulators'][0]['conditions']")" "[$FINDER_ONLY, $WHILE_RENAMING]"

it "Escape while renaming cancels with a plain Escape and forgets the rename"
assert_eq "$(query "mappings('$CANCEL_RULE')")" "[({'key_code': 'escape', 'modifiers': {'optional': ['caps_lock']}}, [{'key_code': 'escape'}, $RENAMING_OFF])]"
assert_eq "$(query "rule('$CANCEL_RULE')['manipulators'][0]['conditions']")" "[$FINDER_ONLY, $WHILE_RENAMING]"

it "a click while renaming still clicks and forgets the rename"
assert_eq "$(query "mappings('$CLICK_RULE')")" "[({'pointing_button': 'button1', 'modifiers': {'optional': ['any']}}, [{'pointing_button': 'button1'}, $RENAMING_OFF])]"
assert_eq "$(query "rule('$CLICK_RULE')['manipulators'][0]['conditions']")" "[$FINDER_ONLY, $WHILE_RENAMING]"

it "Enter outside a rename still opens the selected item"
assert_eq "$(query "[m['to'] for m in rule('$OPEN_RULE')['manipulators']]")" "[[{'key_code': 'o', 'modifiers': ['left_command']}]]"
assert_eq "$(query "rule('$OPEN_RULE')['manipulators'][0]['conditions']")" "[$FINDER_ONLY]"

it "the rename rules come before the Enter-opens rule so they win"
assert_eq "$(query "position('$CONFIRM_RULE') < position('$OPEN_RULE') and position('$CANCEL_RULE') < position('$OPEN_RULE')")" "True"

[ "$FAILED" = 0 ] && echo "all passed"
exit "$FAILED"
