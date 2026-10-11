#!/usr/bin/env bash
# 01 - the schema refuses what the page cannot draw, and the fixture (the design's own DATA block) passes.
. "$(dirname "$0")/../lib/assert.sh"
F="$FIX/design-iteration-5.json"

t "the design fixture validates" "$LOOP" validate "$F"

# neg DESC JQ-EXPR: the fixture mutated by the expression is refused with exit 3.
neg() { jq "$2" "$F" > "$W/m.json"; expect_exit 3 "$1" "$LOOP" validate "$W/m.json"; }
neg "a missing headline is refused" 'del(.headline)'
neg "an absolute path in a name is refused" '.lines[0].name = "see /home/someone/a/b"'
neg "a path after a quote is refused" '.lines[0].sub = "run \"/var/log/x\""'
neg "poll_seconds over 30 is refused" '.poll_seconds = 31'
neg "poll_seconds under 5 is refused" '.poll_seconds = 4'
neg "a kickback naming no station is refused" '.kickbacks[0].to = "nobody"'
neg "a duplicate line id is refused" '.lines[1].id = .lines[0].id'
neg "a duplicate station id is refused" '.stations[1].id = .stations[0].id'
neg "a line state for an unknown station is refused" '.lines[0].st.ghost = .lines[0].st.owner'
neg "a here naming no station is refused" '.lines[0].here = "ghost"'
neg "a waiting naming no station is refused" '.lines[0].waiting = "ghost"'
neg "an unknown status is refused" '.lines[0].st.owner.status = "great"'
neg "an unknown part kind is refused" '.lines[0].st.owner.parts[0][0] = "maybe"'
neg "an extra field is refused" '.surprise = 1'
neg "a string sim is refused" '.lines[0].sim = "no"'
neg "a board step of 5 is refused" '.board[0].step = 5'
neg "a bad ticket id is refused" '.lines[0].ticket = "WO-1"'
neg "a text over 400 characters is refused" '.headline = ("x" * 401)'

# A slash that is not the start of a path stays legal: the sources line and the legend carry plenty.
jq '.headline = "roles/*.json and factory/config/routes.json, 3 / 4 done"' "$F" > "$W/ok.json"
t "relative paths and a spaced slash are accepted" "$LOOP" validate "$W/ok.json"

expect_exit 4 "a missing file is an io error" "$LOOP" validate "$W/none.json"
expect_exit 2 "no verb is a usage error" "$LOOP"
done_case
