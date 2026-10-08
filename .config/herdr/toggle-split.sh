#!/usr/bin/env bash
# Toggle a two-pane tab between top/bottom and left/right (like tmux prefix+space).
# Bound in config.toml via [[keys.command]].
set -euo pipefail

# Use the focused pane rather than the pane this command was launched from.
unset HERDR_PANE_ID HERDR_TAB_ID
if [ $# -gt 0 ]; then layout=$(herdr pane layout --pane "$1"); else layout=$(herdr pane layout --current); fi

read -r tab first second dir ratio < <(python3 -c '
import json, sys
l = json.load(sys.stdin)["result"]["layout"]
if len(l["panes"]) != 2 or len(l["splits"]) != 1:
    sys.exit(1)
p = sorted(l["panes"], key=lambda p: (p["rect"]["y"], p["rect"]["x"]))
s = l["splits"][0]
print(l["tab_id"], p[0]["pane_id"], p[1]["pane_id"], s["direction"], s["ratio"])
' <<<"$layout") || exit 0

if [ "$dir" = "down" ]; then new=right; else new=down; fi

# herdr refuses moves within the same tab, so park the second pane in a temp tab and bring it back.
herdr pane move "$second" --new-tab --no-focus >/dev/null
herdr pane move "$second" --tab "$tab" --target-pane "$first" --split "$new" --ratio "$ratio" --no-focus >/dev/null
