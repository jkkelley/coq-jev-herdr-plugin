#!/usr/bin/env bash
# Catches: a gate record with no consumer record that nobody is told about, a note repeated on every tick, a note for a gate
# that was taken or is not yet old enough, a gate kind that is code and not config, and a config that lets a stall take
# longer than two minutes to show (AC-H1 of WO-20261011-6842). Runner pane and belt are fresh throughout, so only gate notes appear.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa; U=WO-20261011-bbbb
world_up flowgate; flow_world

echo "-- AC-H1: a 201 older than stall_seconds with no consumer record is one 500 note to the monitor that names the record"
g=$(rec test.passed 201 tester "$T"); backdate "$g" 100
flow_once; assert_eq "exit 0" "$?" 0
assert_eq "one note" "$(flow_notes | grep -c .)" 1
n=$(flow_notes)
assert_eq "500 note to the monitor on the ticket" "$(jq -r '[.code, .kind, .to, .ticket] | join(" ")' <<<"$n")" "500 note monitor $T"
assert_match "it names the record, the kind and the missing role" "$(jq -r .note <<<"$n")" "test.passed 201 $g has no reviewer record"
echo "-- a second tick does not repeat it"
flow_once; flow_once; assert_eq "still one note" "$(flow_notes | grep -c .)" 1

echo "-- a gate record younger than stall_seconds is left alone"
y=$(rec test.passed 201 tester "$U"); backdate "$y" 10
flow_once; assert_eq "no new note" "$(flow_notes | grep -c .)" 1

echo "-- a gate record whose consumer wrote a record after it is left alone"
world_up flowgate2; flow_world
g=$(rec pr.opened 100 worker "$T"); backdate "$g" 100; sleep 1; rec test.failed 422 tester "$T" >/dev/null
flow_once; assert_eq "no note for a taken gate" "$(flow_notes | grep -c .)" 0
echo "-- a consumer record on another ticket does not count"
world_up flowgate3; flow_world
g=$(rec pr.opened 100 worker "$T"); backdate "$g" 100; sleep 1; rec test.passed 201 tester "$U" >/dev/null
flow_once; assert_eq "one note" "$(flow_notes | grep -c .)" 1

echo "-- every gates row of flow.json stalls the same way: the kinds are config, not code"
world_up flowrows; flow_world
n=0; while IFS=$'\t' read -r kind code; do
  g=$(rec "$kind" "$code" worker "WO-20261011-c$(printf '%03d' "$n")"); backdate "$g" 100; n=$((n + 1)); done < <(jq -r '.gates[] | [.kind, .code] | @tsv' "$R/factory/config/flow.json")
flow_once; assert_eq "one note per gates row ($n)" "$(flow_notes | grep -c .)" "$n"

echo "-- records already in the log at the first start are not judged without --from-start"
world_up flowfirst; flow_world
g=$(rec test.passed 201 tester "$T"); backdate "$g" 100; sleep 2
"$FLOW" once --repo "$R" --state "$FSTATE"; assert_eq "exit 0" "$?" 0; assert_eq "no note" "$(flow_notes | grep -c .)" 0

echo "-- status prints the stall, writes nothing and exits 1; a quiet line says ok and exits 0"
world_up flowstatus; flow_world
out=$("$FLOW" status --from-start --repo "$R" --state "$FSTATE"); assert_eq "quiet: exit 0" "$?" 0; assert_match "quiet: says ok" "$out" '^flow: ok$'
g=$(rec merged 200 merger "$T"); backdate "$g" 100
out=$("$FLOW" status --from-start --repo "$R" --state "$FSTATE"); assert_eq "stalled: exit 1" "$?" 1
assert_match "it names the record" "$out" "stall gate $g $T merged 200: no architect record"
assert_eq "status wrote no note" "$(flow_notes | grep -c .)" 0

echo "-- a config where poll + stall pass visible_within_seconds is refused at start"
jq '.poll_seconds = 30 | .stall_seconds = 100' "$R/factory/config/flow.json" > "$W/flow.json"
"$FLOW" once --config "$W/flow.json" --repo "$R" --state "$FSTATE" 2> "$W/err"; assert_eq "exit 3" "$?" 3
assert_match "it says why" "$(cat "$W/err")" 'poll_seconds 30 \+ stall_seconds 100 is more than visible_within_seconds 120'
case_done
