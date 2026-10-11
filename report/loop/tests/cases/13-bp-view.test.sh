#!/usr/bin/env bash
# 13 - views: --view picks a config, the view's schema judges it, and the board's own path is untouched.
. "$(dirname "$0")/../lib/assert.sh"
CFG="$REPO_ROOT/report/loop/config/blueprint.json"
t "the shipped blueprint config is valid" python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$CFG" "$REPO_ROOT/report/loop/config/blueprint.schema.json"
expect_exit 2 "--view with no name is usage" "$LOOP" --view
expect_exit 2 "--view with a bad name is usage" "$LOOP" --view '../board' collect
expect_exit 4 "--view naming no config file is an io error" "$LOOP" --view nosuchview collect
jq '.view = "board"' "$CFG" > "$W/wrong.json"
LOOP_CONFIG="$W/wrong.json" expect_exit 3 "a blueprint config that says it is the board fails the board schema" "$LOOP" collect --now 2026-10-11T15:00:00Z --no-panes
jq 'del(.stations[3])' "$CFG" > "$W/short.json"
LOOP_CONFIG="$W/short.json" LOOP_ROOT="$FIX/blueprint" expect_exit 3 "a blueprint config with three gates is refused" "$LOOP" --view blueprint collect --now 2026-10-11T15:00:00Z
jq '.stations[0].id = "decision"' "$CFG" > "$W/swap.json"
LOOP_CONFIG="$W/swap.json" LOOP_ROOT="$FIX/blueprint" expect_exit 3 "a blueprint config with the gates out of order is refused" "$LOOP" --view blueprint collect --now 2026-10-11T15:00:00Z
jq '.poll_seconds = 25 | .watch_seconds = 25' "$CFG" > "$W/slow.json"
LOOP_CONFIG="$W/slow.json" LOOP_ROOT="$FIX/blueprint" expect_exit 3 "poll plus watch over 30 seconds is refused for a view too" "$LOOP" --view blueprint collect --now 2026-10-11T15:00:00Z
# One watch pass writes the page, a second with nothing changed touches nothing.
LOOP_ROOT="$FIX/blueprint" "$LOOP" --view blueprint watch --iterations 1 --out "$W/watch" 2>/dev/null
t "a watch pass writes index.html and data.json" test -f "$W/watch/index.html" -a -f "$W/watch/data.json"
m1=$(stat -c %Y "$W/watch/index.html"); sleep 1
LOOP_ROOT="$FIX/blueprint" "$LOOP" --view blueprint watch --iterations 1 --out "$W/watch" 2>/dev/null
eq "a pass that finds nothing new leaves the page alone" "$m1" "$(stat -c %Y "$W/watch/index.html")"
mkdir -p "$W/live"; cp -r "$FIX/blueprint/." "$W/live/"
LOOP_ROOT="$W/live" "$LOOP" --view blueprint watch --iterations 1 --out "$W/watchlive" 2>/dev/null
jq '.title = "Alpha, renamed"' "$FIX/blueprint/graph/nodes/CMP-alpha.json" > "$W/live/graph/nodes/CMP-alpha.json"
LOOP_ROOT="$W/live" "$LOOP" --view blueprint watch --iterations 1 --out "$W/watchlive" 2>/dev/null
eq "a changed node shows on the next pass, with a higher build number" "Alpha, renamed 2" "$(jq -r '"\(.lines[0].sub) \(.number)"' "$W/watchlive/data.json")"
eq "the board's default config is untouched by views" "board" "$(jq -r '.view // "board"' "$REPO_ROOT/report/loop/config/board.json")"
done_case
