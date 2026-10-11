#!/usr/bin/env bash
# 06 - the build board's bars, the legend, the window, and what the entry must never carry (AC-H1, AC-H6 config side).
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
world_init

# Board bars come from ticket status: planned, cut, in progress, PR, merged. A missing ticket file is a bar of 0, said so.
jq '.board = [{k:"B1",ticket:"WO-20261011-0010"},{k:"B2",ticket:"WO-20261011-0011"},{k:"B3",ticket:"WO-20261011-0012"},{k:"B4",ticket:"WO-20261011-0013"},{k:"B5",ticket:"WO-20261011-0014"},{k:"B6",ticket:"WO-20261011-0015"}]' "$W/board.json" > "$W/b2.json" && mv "$W/b2.json" "$W/board.json"
ticket WO-20261011-0010 draft "" null "Draft one"
ticket WO-20261011-0011 ready "" null "Ready one"
ticket WO-20261011-0012 in-progress feat/y null "Building one"
ticket WO-20261011-0013 in-review feat/z 40 "In review one"
ticket WO-20261011-0014 "done" feat/w 41 "Done one"
collect
RESULT_JQ "the bars follow the tickets' status" '[.board[].step] == [0, 1, 2, 3, 4, 0]'
RESULT_JQ "a board row carries the full title and the status" '.board[3].t == "In review one" and .board[3].sub == "WO-20261011-0013 · in-review"'
RESULT_JQ "a missing ticket is a bar of 0 that says so" '.board[5].t == "ticket file not found" and .board[5].sub == "WO-20261011-0015 · missing"'
RESULT_JQ "the board heading comes from config" '.board_title == "Build board · the small loop"'
RESULT_JQ "the legend gives every ticket its id and full title" '.legend | any(.[0] == "0010" and .[1] == "WO-20261011-0010 - Draft one")'
RESULT_JQ "the config's legend notes follow the tickets" '.legend[-1][0] == "B0-B7" and (.legend[-2][0] == "records")'
RESULT_JQ "only tickets in progress or in review are lines" '(.lines | map(.id)) == ["0012", "0013"]'

# The window: a record older than events_days is not read.
world_init; ticket WO-20261011-0020 in-progress feat/q null "Old news"
ev 2026-09-01T10:00:00Z worker-wo-20261011-0020 note 100 WO-20261011-0020 wD3:p1 "work.started: long ago"
ev 2026-10-10T10:00:00Z worker-wo-20261011-0020 note 100 WO-20261011-0020 wD3:p1 "work.started: yesterday"
collect
RESULT_JQ "a record older than the window is not read" '.sources | contains("1 records in 14 days")'

# No ticket in progress: the floor says so and the page still renders.
world_init; ticket WO-20261011-0030 ready "" null "Not started"
collect
RESULT_JQ "an empty floor says why" '(.lines | length) == 0 and (.headline | startswith("Floor: no ticket in progress"))'
t "an empty floor renders" "$LOOP" render --in "$W/entry.json" --out "$W/empty-out"
has "the page tells the owner nothing is running" "$W/empty-out/index.html" 'No ticket is in progress or in review'

# What the entry must never carry: an absolute path, the world's own directory, the repository's name.
world_init; ticket WO-20261011-0040 in-progress feat/p null "Safe"
ev 2026-10-11T14:00:00Z worker-wo-20261011-0040 blocked 423 WO-20261011-0040 wD3:p1 "see /home/luna/projects/coq-jev-herdr-plugin/x and \"/tmp/y/z\""
collect
RESULT_JQ "no home directory path reaches the entry" '[.. | strings | select(contains("/home/"))] | length == 0'
RESULT_JQ "no tmp path reaches the entry" '[.. | strings | select(contains("/tmp/"))] | length == 0'
RESULT_JQ "the repository's name is not in the entry" '[.. | strings | select(contains("coq-jev-herdr-plugin"))] | length == 0'
eq "the scratch world's own directory is not in the entry" "0" "$(grep -c -F "$W" "$W/entry.json")"

# Derived, not typed: the same world gives the same bytes; one more record changes them.
collect; first=$(sha256sum < "$W/entry.json")
collect; eq "the same world collects to the same bytes" "$first" "$(sha256sum < "$W/entry.json")"
ev 2026-10-11T14:05:00Z worker-wo-20261011-0040 note 100 WO-20261011-0040 wD3:p1 "pr.opened: PR 5"
collect; if [ "$first" != "$(sha256sum < "$W/entry.json")" ]; then pass "a new record changes the entry"; else flunk "a new record changes the entry"; fi
collect --number 7
RESULT_JQ "--number sets the build count" '.number == 7'

# A kickback lane that names no row of the routes table is refused: the config cannot draw a route that does not exist.
jq '.kickbacks[0].route.kind = "no.such.kind"' "$W/board.json" > "$W/bad-board.json"
expect_exit 3 "a kickback naming no route is refused" env LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/bad-board.json" "$LOOP" collect --now "$NOW" --no-panes
has "and the refusal names the lane" "$W/.out" 'names no row of the routes table'

# collect writes the entry where --out says, and the entry renders.
t "collect --out writes the file" env LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/board.json" "$LOOP" collect --now "$NOW" --no-panes --out "$W/o/entry.json"
t "the collected entry validates" "$LOOP" validate "$W/o/entry.json"
t "the collected entry renders" "$LOOP" render --in "$W/o/entry.json" --out "$W/o/page"
done_case
