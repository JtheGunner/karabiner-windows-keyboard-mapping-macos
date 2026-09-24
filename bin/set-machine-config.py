#!/usr/bin/env python3
"""
Set the machine-level bits of the live Karabiner profile in place, without
replacing the whole file.

Karabiner-Elements has no CLI for this (`karabiner_cli` only does profiles,
runtime variables, lint, format). The supported way is to edit
~/.config/karabiner/karabiner.json directly; Karabiner watches the file and
hot-reloads.

What it sets on the *selected* profile:
  --simple-mods   simple_modifications  = right_command -> right_option  (AltGr)
  --iso           virtual_hid_keyboard.keyboard_type_v2 = "iso"
  --devices       devices[]             = the known Logitech keyboard/mice
                  (vendor_id 1133; only matches that exact hardware - harmless
                  otherwise), incl. the MX Keys Windows-mode Alt/Win swap.
                  Edit DEVICES below for your gear.

    python3 bin/set-machine-config.py            # all of the above
    python3 bin/set-machine-config.py --iso      # just one
    python3 bin/set-machine-config.py --show     # print current values, change nothing
"""

from __future__ import annotations

import argparse
import datetime
import json
import shutil
import sys
from pathlib import Path

LIVE = Path.home() / ".config" / "karabiner" / "karabiner.json"

SIMPLE_MODS = [
    {"from": {"key_code": "right_command"}, "to": [{"key_code": "right_option"}]},
]

KEYBOARD_TYPE = "iso"  # Swiss/German ISO physical layout

# vendor_id 1133 = Logitech. `ignore: false` = Karabiner processes the device.
# The MX Keys (45915) runs in its Windows mode, the only mode that sends Insert.
# There Alt arrives as left_option and Win as left_command; the swap restores
# the macOS-mode codes (Alt = left_command, Win = left_option) all rules expect.
MX_KEYS_WINDOWS_MODE_SWAP = [
    {"from": {"key_code": "left_option"}, "to": [{"key_code": "left_command"}]},
    {"from": {"key_code": "left_command"}, "to": [{"key_code": "left_option"}]},
]
DEVICES = [
    {"identifiers": {"is_keyboard": True, "is_pointing_device": True,
                     "product_id": 45915, "vendor_id": 1133},
     "ignore": False, "treat_as_built_in_keyboard": True,
     "simple_modifications": MX_KEYS_WINDOWS_MODE_SWAP},
    {"identifiers": {"is_pointing_device": True, "product_id": 45108, "vendor_id": 1133},
     "ignore": False},
    {"identifiers": {"is_pointing_device": True, "product_id": 50504, "vendor_id": 1133},
     "ignore": False},
]


def selected_profile(cfg: dict) -> dict:
    profs = cfg.get("profiles", [])
    for p in profs:
        if p.get("selected"):
            return p
    if profs:
        return profs[0]
    raise SystemExit("no profiles in karabiner.json")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--simple-mods", action="store_true")
    ap.add_argument("--iso", action="store_true")
    ap.add_argument("--devices", action="store_true")
    ap.add_argument("--show", action="store_true", help="print current values, change nothing")
    args = ap.parse_args(argv)

    if not LIVE.is_file():
        raise SystemExit(f"{LIVE} not found - install Karabiner-Elements / run ./setup.sh first")

    cfg = json.loads(LIVE.read_text(encoding="utf-8"))
    prof = selected_profile(cfg)

    if args.show:
        print(f"profile: {prof.get('name')!r}")
        print("simple_modifications :", json.dumps(prof.get("simple_modifications")))
        print("virtual_hid_keyboard :", json.dumps(prof.get("virtual_hid_keyboard")))
        print("devices              :", json.dumps(prof.get("devices"), indent=1))
        return 0

    do_all = not (args.simple_mods or args.iso or args.devices)
    changed = []

    if do_all or args.simple_mods:
        if prof.get("simple_modifications") != SIMPLE_MODS:
            prof["simple_modifications"] = SIMPLE_MODS
            changed.append("simple_modifications")

    if do_all or args.iso:
        vhid = prof.setdefault("virtual_hid_keyboard", {})
        if vhid.get("keyboard_type_v2") != KEYBOARD_TYPE:
            vhid["keyboard_type_v2"] = KEYBOARD_TYPE
            changed.append("virtual_hid_keyboard.keyboard_type_v2")

    if do_all or args.devices:
        if prof.get("devices") != DEVICES:
            prof["devices"] = DEVICES
            changed.append("devices")

    if not changed:
        print("already up to date - nothing changed")
        return 0

    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    bak = LIVE.with_name(f"karabiner-bkp-{stamp}.json")
    shutil.copy2(LIVE, bak)
    LIVE.write_text(json.dumps(cfg, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"backup: {bak.name}")
    print("updated:", ", ".join(changed))
    print("Karabiner reloads automatically.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
