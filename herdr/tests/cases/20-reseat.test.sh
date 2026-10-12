#!/usr/bin/env bash
# Catches (WO-20261012-b800): a seat whose claude died staying a bare shell until a person noticed, a seat re-seated on one
# sighting or while seat.sh --down is retiring it, an idle seat or the monitor seat being touched, a crash loop restarted for
# ever, a seat on a closed ticket started again instead of downed, and a re-seat that loses the ticket brief or the seat.up record.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up reseat '.bringup_gate=true | .supervisor.herdr_unit="" | .supervisor.podman=false | .supervisor.bearings.enabled=false | .supervisor.reseat.grace_seconds=3 | .supervisor.reseat.up_seconds=0 | .supervisor.reseat.max_per_window=2' || exit 1
SUP="$REPO/herdr/bin/supervisor.sh"
T=WO-20269999-aaaa; N=worker-wo-20269999-aaaa; T2=WO-20269999-bbbb; N2=worker-wo-20269999-bbbb
tick() { "$SUP" "$@" > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"; }
mkticket() { mkdir -p "$REPO/work-orders/WO-20269999-0000"; cat > "$REPO/work-orders/WO-20269999-0000/$1-fixture.md" <<EOF
---
{"id": "$1", "slug": "fixture", "title": "$2", "type": "feature", "status": "$3"}
---

# $1 - $2
EOF
}
mkticket "$T" "fixture ticket with a seat" in-progress; mkticket "$T2" "fixture ticket that will close" in-progress
# gone <agent>: end the stub the way the real claude ends, then wait until herdr stops answering for it.
gone() { h agent prompt "$1" "/exit" >/dev/null 2>&1; local _; for _ in $(seq 1 20); do h agent get "$1" >/dev/null 2>&1 || return 0; sleep 1; done; return 1; }
claude_in() { h pane process-info --pane "$1" | jq -r '[.result.process_info.foreground_processes[]? | (.argv // [.name]) | map(split("/") | last) | .[0:2][] | select(. == "claude")] | length'; }

echo "-- bringup, then two worker seats"
"$REPO/herdr/bin/bringup.sh" --worktree "$REPO" >/dev/null 2>&1; assert_eq "bringup exits 0" "$?" 0
"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null; assert_eq "the first worker comes up" "$?" 0
"$SEAT" --ticket "$T2" --role worker --worktree "$REPO" >/dev/null; assert_eq "the second worker comes up" "$?" 0
P="$(jq -r .pane "$STATE/seats/$N/seat.json")"
ups0="$(event_count seat.up 100)"

echo "-- a seat whose claude runs, idle or not, is left alone"
tick; assert_eq "exit 0" "$rc" 0
assert_match "seats ok, two judged" "$out" "^ok seats \\(2 judged\\)"
assert_eq "no re-seat" "$(grep -c '^fixed seat-' <<<"$out")" 0

echo "-- AC-H2: kill the claude; the first sighting only notes it, the second after the grace re-seats it"
gone "$N"; assert_eq "the first worker's claude is gone" "$?" 0
assert_eq "no claude in its pane" "$(claude_in "$P")" 0
tick; assert_match "first sighting: skipped, nothing started" "$out" "^skipped seat-$N \\(no claude in pane $P; seen once"
assert_eq "still no agent" "$(h agent get "$N" >/dev/null 2>&1; echo $?)" 1
sleep 4
tick
echo "$out" | grep -E 'seat-' | sed 's/^/    /'
assert_eq "exit 0" "$rc" 0
assert_match "second sighting past the grace: fixed" "$out" "^fixed seat-$N \\(claude had been gone [0-9]+s, seat.sh started it again"
assert_eq "herdr answers for the agent again" "$(h agent get "$N" >/dev/null 2>&1; echo $?)" 0
assert_eq "in the same pane" "$(h agent get "$N" | jq -r .result.agent.pane_id)" "$P"
assert_eq "a claude runs in the pane" "$(claude_in "$P")" 1
assert_eq "one more seat.up 100 record" "$(( $(event_count seat.up 100) - ups0 ))" 1
sleep 2
assert_match "the ticket brief reached it" "$(h agent read "$N" --source recent-unwrapped --lines 200)" "Playbook playbooks/worker\\.md"
assert_eq "the seat record is the same seat, not ended" "$(jq -r '.ended_at' "$STATE/seats/$N/seat.json")" null
assert_match "a supervisor note says so" "$(jq -r 'select(.seat == "supervisor") | .note' "$EVENTS"/2*/*/*.json | tr '\n' ' ')" "fixed .*seat-$N"
tick; assert_eq "the next tick has nothing to fix" "$(grep -c '^fixed \|FAILED' <<<"$out")" 0

echo "-- a seat that seat.sh --down is retiring is left alone"
gone "$N"; rm -f "$STATE/supervisor/reseats/$N"
date +%s > "$STATE/seats/$N/down.lock"
tick; sleep 4; tick
assert_eq "no seat line for it while the lock is fresh" "$(grep -c "seat-$N" <<<"$out")" 0
assert_eq "and no agent" "$(h agent get "$N" >/dev/null 2>&1; echo $?)" 1
echo $(( $(date +%s) - 400 )) > "$STATE/seats/$N/down.lock"
tick; sleep 4; tick
assert_match "a lock older than down_lock_seconds is ignored" "$out" "^fixed seat-$N "

echo "-- a claude that dies every time is started max_per_window times, then a 500 and no more"
n500="$(event_count note 500)"
gone "$N"; tick; sleep 4; tick
assert_match "the second re-seat in the window is allowed" "$out" "^fixed seat-$N "
gone "$N"; tick; sleep 4; tick
assert_eq "the third is refused: exit 1" "$rc" 1
assert_match "FAILED names the cap" "$out" "^FAILED seat-$N \\(claude died again after 2 re-seats in 1800s"
assert_eq "no agent was started" "$(h agent get "$N" >/dev/null 2>&1; echo $?)" 1
assert_eq "one 500 record for it" "$(( $(event_count note 500) - n500 ))" 1
tick; tick; assert_eq "and not one per tick" "$(( $(event_count note 500) - n500 ))" 1

echo "-- a seat on a closed ticket is downed, not started"
mkticket "$T2" "fixture ticket that will close" "done"
gone "$N2"; tick; sleep 4; tick
assert_match "downed" "$out" "^fixed seat-$N2 \\(no claude and ticket $T2 is closed, seat downed\\)"
assert_match "its record has ended_at" "$(jq -r .ended_at "$STATE/seats/$N2/seat.json")" '^20'
assert_eq "no agent" "$(h agent get "$N2" >/dev/null 2>&1; echo $?)" 1

echo "-- --check reports a dead seat and changes nothing"
gone "$N" 2>/dev/null; rm -f "$STATE/supervisor/reseats/$N" "$STATE/supervisor/dead/$N"
tick --check
assert_eq "exit 1" "$rc" 1
assert_match "a first sighting is named, not recorded" "$out" "^FAILED seat-$N \\(no claude in pane $P; apply would judge it again"
assert_eq "--check wrote no dead marker" "$([ -f "$STATE/supervisor/dead/$N" ] && echo 1 || echo 0)" 0
tick; sleep 4; tick --check
assert_match "past the grace it says what apply would do" "$out" "^FAILED seat-$N \\(claude has been gone [0-9]+s; apply would re-seat it\\)"
assert_eq "still no agent" "$(h agent get "$N" >/dev/null 2>&1; echo $?)" 1

echo "-- the monitor seat is bringup's, not the seat node's"
gone monitor; tick; first="$out"; sleep 4; tick
assert_eq "the seat node never names the monitor" "$(grep -c '^[a-z]* seat-monitor' <<<"$first$out")" 0
assert_match "bringup brought it back on the first tick" "$first" "fixed monitor-seat"
case_done
