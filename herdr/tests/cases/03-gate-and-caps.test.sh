#!/usr/bin/env bash
# Catches: the bring-up gate (DEC-system-before-agents) letting a seat start with the monitor down, door 2 naming a
# fixed seat wrongly, the role cap (max_seats) or the system cap (max_agents) not refusing with a 429 note, or a
# refused seat building panes anyway.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up gate '.bringup_gate=true | .max_agents=3' || exit 1
T=WO-20261010-8777

echo "-- gate: a worker is refused while the monitor seat is down"
"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "refused with exit 3" "$rc" 3
assert_match "the refusal names the bring-up order" "$(cat "$WORLD/err")" "bring-up order: monitor seat monitor is down"
assert_eq "nothing was built" "$(h workspace list | jq '[.result.workspaces[] | select(.label == "coq")] | length')" 0

echo "-- door 2: the monitor seat comes up by task"
out="$("$SEAT" --role monitor --task "watch the factory" --worktree "$REPO")"; rc=$?
assert_eq "monitor door exits 0" "$rc" 0
assert_eq "a label without a token is the name" "$(jq -r .name <<<"$out")" monitor
sleep 1
assert_match "the task brief is the first prompt" "$(h agent read monitor --source recent-unwrapped --lines 200)" "You are the monitor seat named monitor.*Your task: watch the factory"

echo "-- gate open: the worker now comes up"
"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null; assert_eq "worker exits 0 once the monitor is live" "$?" 0

echo "-- role cap: reviewer max_seats is 2"
"$SEAT" --ticket WO-20261010-539f --role reviewer --worktree "$REPO" >/dev/null 2>&1; assert_eq "first reviewer ok (3 agents live, at max_agents)" "$?" 0
"$SEAT" --ticket WO-20261010-d354 --role reviewer --worktree "$REPO" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "the fourth agent is refused by max_agents" "$rc" 3
assert_match "the refusal names the system cap" "$(cat "$WORLD/err")" "3 agents already live \(max_agents 3\)"
assert_eq "a 429 note was recorded" "$(event_count note 429)" 1
"$SEAT" --down worker-wo-20261010-8777 >/dev/null
"$SEAT" --ticket WO-20261010-d354 --role reviewer --worktree "$REPO" >/dev/null 2>&1; assert_eq "second reviewer ok once a slot is free" "$?" 0
"$SEAT" --ticket WO-20261010-7083 --role reviewer --worktree "$REPO" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "a third reviewer is refused by max_seats" "$rc" 3
assert_match "the refusal names the role cap" "$(cat "$WORLD/err")" "2 reviewer seats already live \(max_seats 2\)"
assert_eq "a second 429 note was recorded" "$(event_count note 429)" 2
for n in monitor reviewer-wo-20261010-539f reviewer-wo-20261010-d354; do "$SEAT" --down "$n" >/dev/null; done
case_done
