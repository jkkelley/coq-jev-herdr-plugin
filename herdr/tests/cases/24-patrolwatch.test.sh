#!/usr/bin/env bash
# Catches (WO-20261013-5b33, owner order 2026-10-13 "isn't the tattle tale on some kind of 1 min loop?"): the compliance officer
# woken only when a seat ends a turn, so a hung seat or a dead line process is never seen. patrolwatch.sh is the system's tick:
# AC-H1: with no officer agent a tick is skipped and logged, and the watch exits 0.
# AC-H2: with the officer up, every tick prompts it once with "PATROL <HH:MMZ>" naming the playbook, and N ticks make N prompts.
# AC-H3: the shipped period is 60 seconds and the watch holds the reserved slot 4.2.1 of the watches tab.
# World: the suite's stub claude as the officer agent (it prints "> <line>" for each prompt, so the agent's screen proves the prompt), the
# poll shortened to 1 second so three ticks take about three seconds. The 60 second period is asserted from the shipped config.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up patrol '.watches.patrol_seconds=1' || exit 1
PW="$REPO/herdr/bin/patrolwatch.sh"

echo "-- AC-H3: the shipped period and slot"
assert_eq "herdr.json ships a 60 second patrol" "$(jq -r .watches.patrol_seconds "$HERE/../../config/herdr.json")" 60
assert_eq "monitors.json holds the patrol tick in slot 4.2.1" "$(jq -r '[.tabs[].reserved[]? | select(.name == "patrolwatch")][0].pos' "$HERE/../../config/monitors.json")" "4.2.1"

echo "-- AC-H1: no officer, no prompt, no failure"
"$PW" --ticks 1 > "$WORLD/none" 2>&1; assert_eq "exits 0" "$?" 0
assert_match "the skipped tick is logged" "$(cat "$WORLD/none")" 'tick skipped: no agent compliance-officer'

echo "-- AC-H2: three ticks, three prompts"
ws="$(h workspace list | jq -r '.result.workspaces[] | select(.label == "architect-fixture") | .workspace_id')"
OP="$(h tab create --workspace "$ws" --label officer --cwd "$REPO" | jq -r '.result.root_pane.pane_id // empty')"
sleep 2; h agent start compliance-officer --kind claude --pane "$OP" -- --model x >/dev/null; assert_eq "the officer comes up" "$?" 0
sleep 3
"$PW" --ticks 3 > "$WORLD/ticks" 2>&1; assert_eq "three ticks exit 0" "$?" 0
assert_eq "the log shows three PATROL lines" "$(grep -c ' PATROL compliance-officer ' "$WORLD/ticks")" 3
sleep 2
heard="$(h agent read compliance-officer --source recent-unwrapped --lines 300 | grep -c '^> PATROL [0-9][0-9]:[0-9][0-9]Z')"
assert_eq "the officer heard three prompts" "$heard" 3
assert_match "each prompt names the playbook" "$(h agent read compliance-officer --source recent-unwrapped --lines 300)" 'playbooks/compliance-officer.md'
case_done
