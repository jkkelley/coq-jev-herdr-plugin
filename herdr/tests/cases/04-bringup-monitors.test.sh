#!/usr/bin/env bash
# Catches: bringup.sh running nodes out of the WFL-bringup order, building when --check should only report, not
# bringing the monitor seat up before the gate opens, monitors.sh drawing anything but three 3x3 tabs, a rerun
# duplicating panes, take handing an agent a monitoring pane, release not giving the slot back, or monitors 1 not
# running the guard lease watcher (1.1.1) and compaction-guard watch (1.1.2) the way monitors 2 runs its tails.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up bringup '.bringup_gate=true' || exit 1
BU="$REPO/herdr/bin/bringup.sh"; MON="$REPO/herdr/bin/monitors.sh"

echo "-- --check on an empty session reports and builds nothing"
"$BU" --check --worktree "$REPO" > "$WORLD/out" 2>&1; rc=$?; out="$(tr '\n' ' ' < "$WORLD/out")"
assert_eq "--check exits 1" "$rc" 1
assert_match "herdr is ok, the guard is skipped, monitors are the first failure" "$out" "^ok herdr.*skipped compaction-guard.*FAILED monitors"
assert_eq "nothing was built" "$(h workspace list | jq '[.result.workspaces[] | select(.label == "coq")] | length')" 0

echo "-- bringup builds the system in order"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; rc=$?; out="$(tr '\n' ' ' < "$WORLD/out")"
echo "$out" | sed 's/^/    /'
assert_eq "bringup exits 0" "$rc" 0
assert_match "monitors, the monitor seat and all four reserved panes were fixed, in that order" "$out" "fixed monitors.*fixed monitor-seat.*fixed pane-lease.*fixed pane-guard.*fixed pane-events.*fixed pane-queue"
ws="$(h workspace list | jq -r '.result.workspaces[] | select(.label == "coq") | .workspace_id')"
assert_match "one workspace labelled coq" "$ws" '^w'
assert_eq "three monitors tabs plus the monitor seat tab" "$(h tab list --workspace "$ws" | jq -r '[.result.tabs[].label] | sort | join("|")')" "monitor|monitors 1 - compaction watchers|monitors 2 - loop, events and queue|monitors 3 - shells"
for t in "monitors 1 - compaction watchers" "monitors 2 - loop, events and queue" "monitors 3 - shells"; do
  tid="$(h tab list --workspace "$ws" | jq -r --arg l "$t" '.result.tabs[] | select(.label == $l) | .tab_id')"
  assert_eq "$t holds 9 panes" "$(h pane list --workspace "$ws" | jq -r --arg t "$tid" '[.result.panes[] | select(.tab_id == $t)] | length')" 9
done
st="$("$MON" status)"; rc=$?
assert_eq "monitors.sh status exits 0" "$rc" 0
assert_match "1.1.1 runs the guard lease watcher" "$st" "1\.1\.1 guard lease watcher - lease  \[[^]]+\]  in use"
assert_match "1.1.2 runs compaction-guard watch" "$st" "1\.1\.2 compaction-guard watch - guard  \[[^]]+\]  in use"
assert_match "1.1.3 stays an open orchestrator watcher slot" "$st" "1\.1\.3 OPEN - orchestrator compaction watcher  \[[^]]+\]  open"
# The status lines name the commands' panes; each must show its own output, not just a label (the watchers are the
# real unfreeze.sh --watch and the suite's stub compaction-guard, so neither touches the host).
slot_pane() { sed -nE "s/^ +$1 .*\[([^]]+)\] +in use$/\1/p" <<<"$st"; }
lp="$(slot_pane '1\.1\.1')"; gp="$(slot_pane '1\.1\.2')"
h pane wait-output "$lp" --regex 'tick: [0-9]+ released, [0-9]+ ok, rc [0-9]' --source recent-unwrapped --timeout 20000 >/dev/null 2>&1; assert_eq "1.1.1 printed an unfreeze.sh --watch tick" "$?" 0
h pane wait-output "$gp" --match 'stub compaction-guard watch --interval 15' --source recent-unwrapped --timeout 20000 >/dev/null 2>&1; assert_eq "1.1.2 runs compaction-guard watch --interval 15" "$?" 0
assert_match "2.1.1 runs the event log tail" "$st" "2\.1\.1 event log tail - events  \[[^]]+\]  in use"
assert_match "2.1.2 runs the queue list" "$st" "2\.1\.2 queue list - queue  \[[^]]+\]  in use"
assert_match "3.1.1 is an open shell" "$st" "3\.1\.1 OPEN - any shell  \[[^]]+\]  open"
assert_eq "the monitor seat is live" "$(h agent get monitor | jq -r .result.agent.agent_status)" idle
assert_eq "six note 100 records, one per repaired node" "$(event_count note 100)" 6
chk="$("$BU" --check --worktree "$REPO" 2>&1)"; rc=$?; assert_eq "--check now exits 0" "$rc" 0
assert_match "--check reports the lease and guard watchers ok, ahead of the tails" "$(tr '\n' ' ' <<<"$chk")" "ok pane-lease ok pane-guard ok pane-events ok pane-queue"

echo "-- rerun is idempotent"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; rc=$?; out="$(tr '\n' ' ' < "$WORLD/out")"
assert_eq "rerun exits 0" "$rc" 0
assert_match "every node reads ok" "$out" "^ok herdr.*ok monitors.*ok monitor-seat.*ok pane-events.*ok pane-queue"
assert_eq "still 27 monitoring panes plus 2 seat panes" "$(h pane list --workspace "$ws" | jq '.result.panes | length')" 29

echo "-- take and release"
"$MON" take shell probe -- claude --model x >/dev/null 2>"$WORLD/err"; assert_eq "take refuses an agent" "$?" 1
assert_match "the refusal points at seat.sh" "$(cat "$WORLD/err")" "refusing to run an agent"
p="$("$MON" take shell probe -- sleep 300)"; rc=$?
assert_eq "take exits 0" "$rc" 0
assert_match "take prints the pane" "$p" '^w'
assert_match "the slot is labelled in use" "$("$MON" status)" "3\.1\.1 shell - probe  \[$p\]  in use"
p2="$("$MON" take shell probe -- sleep 300)"; assert_eq "the same job again restarts in its own slot" "$p2" "$p"
"$MON" release "$p" other >/dev/null 2>&1; assert_eq "release with another job's label is refused with 3" "$?" 3
"$MON" release "$p" probe >/dev/null; assert_eq "release exits 0" "$?" 0
assert_match "the slot is open again" "$("$MON" status)" "3\.1\.1 OPEN - any shell  \[$p\]  open"

echo "-- the gate opened: a worker comes up behind the monitor seat"
"$REPO/herdr/bin/seat.sh" --ticket WO-20261010-8777 --role worker --worktree "$REPO" >/dev/null; assert_eq "worker exits 0" "$?" 0
"$REPO/herdr/bin/seat.sh" --down worker-wo-20261010-8777 >/dev/null
"$REPO/herdr/bin/seat.sh" --down monitor >/dev/null
case_done
