#!/usr/bin/env bash
# 04 - collect derives the floor from records, tickets and the pane list: seats, panes, belt, blocked work (AC-H1).
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
world_init
T=WO-20261011-0001; S=worker-wo-20261011-0001

ticket "$T" in-progress feat/make-the-thing null "Make the thing"
ev 2026-10-11T14:00:00Z "$S" seat.up 100 "$T" wD3:p5 "worker seat up"
ev 2026-10-11T14:01:00Z "$S" note 100 "$T" wD3:p5 "work.started: worker seat begins"
panes "$S=wD3:p5" "bearings-stable=wD3:p1N"

t "collect builds an entry from events, tickets and the pane list" collect
RESULT_JQ "the entry has one line, named for the ticket" '(.lines | length) == 1 and .lines[0].id == "0001" and .lines[0].ticket == "WO-20261011-0001" and .lines[0].name == "Make the thing"'
RESULT_JQ "the line says where its branch is" '.lines[0].sub == "in-progress · feat/make-the-thing"'
RESULT_JQ "work.started in a note leaves the work with the worker" '.lines[0].here == "worker"'
RESULT_JQ "the worker station is live and names its seat and pane" '.lines[0].st.worker.status == "live" and (.lines[0].st.worker.parts | any(.[1] == "seat up: worker-wo-20261011-0001, wD3:p5"))'
RESULT_JQ "the owner station is live because the page server pane is up" '.lines[0].st.owner.status == "live"'
RESULT_JQ "a station with no seat is queued and says so" '.lines[0].st.tester.status == "queued" and (.lines[0].st.tester.parts | any(.[0] == "todo" and .[1] == "seat up"))'
RESULT_JQ "role file and playbook parts come from the files" '.lines[0].st.worker.parts | (any(.[1] == "role file" and .[0] == "ok")) and (any(.[1] == "playbook" and .[0] == "ok"))'
RESULT_JQ "the belt is stopped with no state file, on the line and in the headline" '.lines[0].belt == "stopped" and (.headline | contains("belt stopped"))'
RESULT_JQ "nothing waits on a belt when the last record has no route" '.lines[0] | has("waiting") | not'
RESULT_JQ "the sources line counts what it read" '.sources | contains("2 records") and contains("2 panes")'
RESULT_JQ "the entry names all nine stations from roles and config" '(.stations | length) == 9 and .stations[3].role == "Worker" and .stations[3].model == "sonnet · high" and .stations[7].model == "verify"'
RESULT_JQ "the kickback lanes are drawn from routes.json rows" '.kickbacks[0].tag == "test.failed 422 · attempt < 3" and .kickbacks[4].tag == "blocked 423 · escalations 1 · owner card" and .kickbacks[3].esc == true'

# A pane that is gone is not a seat that is up: the record says up, herdr says no.
panes "bearings-stable=wD3:p1N"
collect
RESULT_JQ "a seat whose pane is gone is not live" '.lines[0].st.worker.status == "building" and (.lines[0].st.worker.parts | any(.[0] == "bad" and (.[1] | contains("pane wD3:p5 is gone"))))'

# A seat that was retired is not up, pane or no pane.
panes "$S=wD3:p5" "bearings-stable=wD3:p1N"
ev 2026-10-11T14:30:00Z "$S" seat.down 100 "$T" wD3:p5 "seat retired"
collect
RESULT_JQ "a seat.down record ends the seat" '.lines[0].st.worker.status == "building" and (.lines[0].st.worker.parts | any(.[0] == "todo" and .[1] == "seat up"))'

# Without herdr the board trusts the records alone and says so; it neither hangs nor invents a pane list.
find "$ROOT_FIX/events" -name '*-100-x0003.json' -delete
LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/board.json" "$LOOP" collect --now "$NOW" --no-panes > "$W/entry.json" 2>"$W/collect.err"
RESULT_JQ "with no pane list the state says so" '.state == "HERDR PANES UNAVAILABLE" and (.sources | contains("herdr pane list (unavailable)"))'
RESULT_JQ "with no pane list a seat record alone counts" '.lines[0].st.worker.status == "live"'
RESULT_JQ "with no pane list the owner station is not claimed live" '.lines[0].st.owner.status == "queued"'

# The belt: live while the route runner's state file is young, stale after belt_max_age_seconds.
panes "$S=wD3:p5" "bearings-stable=wD3:p1N"
belt 5; collect
RESULT_JQ "a young belt state file runs the belt" '.lines[0].belt == "live" and (.headline | contains("belt running")) and (.sources | contains("belt state (running)"))'
belt 100; collect
RESULT_JQ "an old belt state file is a stopped belt, said as stale" '.lines[0].belt == "stopped" and (.sources | contains("belt state (stale, over 30s old)"))'

# Blocked: a 423 escalates to the architect, whose station holds the work and says why; a path in the note never reaches the page.
ev 2026-10-11T14:40:00Z "$S" blocked 423 "$T" wD3:p5 "stuck: cannot read /home/someone/secret/file.txt today"
collect
RESULT_JQ "a 423 blocks the line" '.lines[0].status == "blocked" and .lines[0].st.arch.status == "blocked" and .lines[0].here == "arch"'
RESULT_JQ "the blocked station says why, without the path" '.lines[0].st.arch.parts | any(.[0] == "bad" and (.[1] | startswith("blocked 423:")) and (.[1] | contains("/home/") | not))'
RESULT_JQ "the headline counts the blocked line" '.headline | contains("1 blocked")'
done_case
