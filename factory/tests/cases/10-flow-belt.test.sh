#!/usr/bin/env bash
# Catches: a stale or missing belt, or a runner pane that is gone or sitting at a prompt, that nobody is told about; a note
# repeated on every tick while the stall stands; and a stall that cannot be noted again after it cleared and came back (AC-H2 of
# WO-20261011-6842). The belt age is route.sh status's, so the 60 second threshold is stale_seconds in runner.json; the file
# is backdated rather than waited out.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up flowbelt; flow_world
belt="$R/factory/state/belt"

echo "-- a fresh belt and a running runner pane: silence"
flow_once; assert_eq "exit 0" "$?" 0; assert_eq "no note" "$(flow_notes | grep -c .)" 0

echo "-- AC-H2: a belt older than stale_seconds is one 500 that names the belt"
touch -d '-61 seconds' "$belt"; flow_once
assert_eq "one note" "$(flow_notes | grep -c .)" 1
n=$(flow_notes | head -1)
assert_eq "500 note to the monitor, no ticket" "$(jq -r '[.code, .kind, .to, (.ticket // "none")] | join(" ")' <<<"$n")" "500 note monitor none"
assert_match "it names the belt and its age" "$(jq -r .note <<<"$n")" 'stall: belt stopped \(last touched 6[0-9]s ago, stale after 60s\)'
echo "-- the next ticks do not repeat it"
flow_once; flow_once; assert_eq "still one note" "$(flow_notes | grep -c .)" 1
echo "-- the belt moves again: no note, and the latch clears; stale again is a new note"
touch "$belt"; flow_once; assert_eq "still one note" "$(flow_notes | grep -c .)" 1
touch -d '-90 seconds' "$belt"; flow_once; assert_eq "two notes" "$(flow_notes | grep -c .)" 2
echo "-- a belt file that does not exist is a stall too"
world_up flowbelt2; flow_world; rm -f "$R/factory/state/belt"; flow_once
assert_eq "one note" "$(flow_notes | grep -c .)" 1; assert_match "it says no belt file" "$(flow_notes | jq -r .note)" 'no belt file'

echo "-- the runner pane gone is one 500 that names the pane, not repeated"
world_up flowpane; flow_world; runner_pane gone; flow_once; flow_once
assert_eq "one note" "$(flow_notes | grep -c .)" 1
assert_match "it says the runner pane is not running" "$(flow_notes | jq -r .note)" 'route runner pane is not running'
echo "-- a runner pane whose shell sits at a prompt is not running"
world_up flowidle; flow_world; runner_pane idle; flow_once
assert_eq "one note" "$(flow_notes | grep -c .)" 1
echo "-- the pane comes back: latch clears, silence, then gone again is a second note"
runner_pane up; flow_once; assert_eq "still one" "$(flow_notes | grep -c .)" 1
runner_pane gone; flow_once; assert_eq "two" "$(flow_notes | grep -c .)" 2
echo "-- both stalls at once are two notes"
world_up flowboth; flow_world; runner_pane gone; touch -d '-100 seconds' "$R/factory/state/belt"; flow_once
assert_eq "two notes" "$(flow_notes | grep -c .)" 2
case_done
