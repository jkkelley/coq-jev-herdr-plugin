#!/usr/bin/env bash
# Catches (WO-20261012-b800, backlog 60l24): the architect's two wake-ups living outside the repo where nothing restarts them
# (turnwatch and recwatch were scripts in the architect's user cache directory run by hand), bringup not building the watches tab, a seat's finished turn
# or a gate record in the checkout or in a treehouse slot not reaching the architect through herdr, a record kind that is not
# a gate kind or a record from before the watcher started waking it, and a record announced twice because a slot's copy
# reached the checkout.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up watches '.bringup_gate=true | .watches.turn_poll_seconds=1 | .watches.record_poll_seconds=1' || exit 1
BU="$REPO/herdr/bin/bringup.sh"; MON="$REPO/herdr/bin/monitors.sh"
T=WO-20261010-8777; N=worker-wo-20261010-8777

echo "-- bringup builds the watches tab and starts both watches in it"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; assert_eq "bringup exits 0" "$?" 0
assert_match "pane-turnwatch and pane-recwatch were plugged in" "$(tr '\n' ' ' < "$WORLD/out")" "fixed pane-turnwatch.*fixed pane-recwatch"
ws="$(h workspace list | jq -r '.result.workspaces[] | select(.label == "coq") | .workspace_id')"
tid="$(h tab list --workspace "$ws" | jq -r '.result.tabs[] | select(.label == "monitors 4 - watches") | .tab_id')"
assert_match "the tab monitors 4 - watches exists" "$tid" '^w'
assert_eq "it holds 9 panes" "$(h pane list --workspace "$ws" | jq --arg t "$tid" '[.result.panes[] | select(.tab_id == $t)] | length')" 9
st="$("$MON" status)"
assert_match "4.1.1 runs the seat turn watch" "$st" "4\.1\.1 seat turn watch - turnwatch  \[[^]]+\]  in use"
assert_match "4.1.2 runs the gate record watch" "$st" "4\.1\.2 gate record watch - recwatch  \[[^]]+\]  in use"
"$MON" health > "$WORLD/health" 2>&1; assert_eq "health is ok" "$?" 0
RP="$(sed -nE 's/^ +4\.1\.2 .*\[([^]]+)\] +in use$/\1/p' <<<"$st")"

echo "-- an architect agent and a worker seat"
AP="$(h tab create --workspace "$ws" --label arch --cwd "$REPO" | jq -r '.result.root_pane.pane_id // empty')"
sleep 2; h agent start architect --kind claude --pane "$AP" -- --model x >/dev/null; assert_eq "the architect comes up" "$?" 0
"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null; assert_eq "the worker comes up" "$?" 0
WP="$(jq -r .pane "$STATE/seats/$N/seat.json")"
# heard <needle>: how many screen lines of the architect carry it; the stub echoes what it is sent, so 0 means not sent.
heard() { h agent read architect --source recent-unwrapped --lines 300 | grep -c -- "$1"; }
wait_heard() { local i; for ((i = 0; i < 40; i++)); do [ "$(heard "$1")" -gt 0 ] && return 0; sleep 0.5; done; return 1; }
sleep 5   # both watchers have made their first pass: they only announce what is new after it

echo "-- a seat that finishes a turn is announced to the architect, once its footer says done"
h agent prompt "$N" "ran for 5s, done 12:00Z" >/dev/null
wait_heard "TURN $N $WP done 12:00Z"; assert_eq "the architect heard TURN with the seat, pane and time" "$?" 0

echo "-- a gate record in the checkout is announced; another kind, and a record older than the watcher, are not"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; ym="$(date -u +%Y/%m)"
mkrec() { # mkrec <dir> <id> <kind> <at>
  mkdir -p "$1/events/$ym"
  jq -n --arg id "$2" --arg k "$3" --arg at "$4" '{schema_version:"1.0.0",id:$id,at:$at,code:100,seat:"fixture-seat",kind:$k,ticket:null,pane:null,note:"",evidence:[],observations:[]}' > "$1/events/$ym/$2.json"
}
mkrec "$REPO" 20991231T000001Z-100-aaaaa pr.opened "$now"
mkrec "$REPO" 20991231T000002Z-100-bbbbb seat.up "$now"
mkrec "$REPO" 20991231T000003Z-100-ccccc pr.opened 2020-01-01T00:00:00Z
wait_heard "REC checkout 20991231T000001Z-100-aaaaa fixture-seat pr.opened 100"; assert_eq "pr.opened in the checkout reached the architect" "$?" 0
sleep 4
assert_eq "seat.up is not a gate kind, so it was not announced" "$(heard 20991231T000002Z-100-bbbbb)" 0
assert_eq "a record from before the watcher started was not announced" "$(heard 20991231T000003Z-100-ccccc)" 0

echo "-- a record born in a treehouse slot is announced from the slot, and once, when the bus copies it to the checkout"
slot="$(treehouse get --lease --lease-holder WO-20269999-slot --no-fetch --json | jq -r .path)"
mkrec "$slot" 20991231T000004Z-100-ddddd test.passed "$now"
wait_heard "REC slot[0-9]* 20991231T000004Z-100-ddddd fixture-seat test.passed 100"; assert_eq "the slot's record reached the architect" "$?" 0
cp "$slot/events/$ym/20991231T000004Z-100-ddddd.json" "$REPO/events/$ym/"
sleep 4
assert_eq "the watch pane announced it exactly once" "$(h pane read "$RP" --source recent-unwrapped --lines 200 | grep -c ' REC .* 20991231T000004Z-100-ddddd ')" 1

echo "-- killing the watch is caught by health and repaired by bringup"
h pane send-keys "$RP" C-c >/dev/null; h pane send-keys "$RP" C-c >/dev/null
for _ in $(seq 1 30); do hl="$("$MON" health 2>/dev/null)"; grep -qE '^FAILED recwatch ' <<<"$hl" && break; sleep 0.5; done
assert_match "health says recwatch is a bare shell" "$hl" "FAILED recwatch \\(pane $RP is a bare shell"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; assert_eq "bringup exits 0" "$?" 0
assert_match "bringup fixed pane-recwatch" "$(cat "$WORLD/out")" "fixed pane-recwatch"
case_done
