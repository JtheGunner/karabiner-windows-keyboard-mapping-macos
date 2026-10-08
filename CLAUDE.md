# karabiner-windows-keyboard-mapping-macos

Config-only repo: no app, no CI pipeline. Follows the global rules in `~/.claude/rules/` without deltas.

- Core artifact is `karabiner.json` (generated/exported, not hand-edited — see `export.sh`).
- `apply.sh` installs the mapping, `setup.sh` bootstraps a fresh machine.
- Tests are shell scripts under `tests/` (`apply-test.sh`, `config-test.sh`) — run them directly, no test runner.
- Changes here affect the user's live keyboard mapping; verify with `tests/apply-test.sh` before considering a change done.
