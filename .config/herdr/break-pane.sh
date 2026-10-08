#!/usr/bin/env bash
# Move the focused pane into its own new tab (like tmux prefix+!).
set -euo pipefail
unset HERDR_PANE_ID HERDR_TAB_ID
pane=$(herdr pane layout --current | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"]["layout"]["focused_pane_id"])')
herdr pane move "$pane" --new-tab --focus >/dev/null
