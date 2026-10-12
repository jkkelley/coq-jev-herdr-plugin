#!/usr/bin/env bash
# Catches: a tester left up after its test 201 or 422 and a reviewer after its review 201 or 422 (the architect taking them down by
# hand, 2026-10-11); the merger left up after merged 200 or merge.conflict 409; a seat taken down before the next seat is up and
# woken; a seat left up because the primary action failed; a failed --down vanishing instead of becoming a 500 that says so; a
# second gate record for the same ticket failing because the seat is already down (WO-20261011-4db1 AC-H2).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up down
order() { cut -d' ' -f1 "$W/order.log" | tr '\n' ' '; }
fives() { find "$R/events" -name '*-500-*.json' | wc -l | tr -d ' '; }
downs() { grep -c -e '--down' "$W/seat.log" | tr -d ' '; }
next() { sleep 1; : > "$W/order.log"; }

echo "-- AC-H2: a test 201 brings the reviewer up, wakes it, then takes the tester down and records seat.down 100"
rec pr.opened 100 worker-wo-20261011-aaaa $T >/dev/null; run_once
assert_eq "the tester is up: pr.opened seated it" "$(ids_of seat.up | grep -c .)" 1
next; id=$(rec test.passed 201 tester-wo-20261011-aaaa $T); run_once
assert_eq "seat.sh up, the prompt, then seat.sh down, in that order" "$(order)" "seat herdr seat "
assert_eq "the reviewer was seated" "$(grep -c -e '--ticket '$T' --role reviewer' "$W/seat.log")" 1
assert_eq "and the tester was taken down by name" "$(tail -1 "$W/seat.log")" "--down tester-wo-20261011-aaaa"
assert_match "the prompt went to the reviewer" "$(tail -1 "$HLOG")" "^--session stable agent prompt reviewer-wo-20261011-aaaa record $id playbook $R/playbooks/reviewer.md$"
sd=$(ids_of seat.down); assert_eq "one seat.down 100 record" "$(printf '%s\n' "$sd" | grep -c .)" 1
assert_eq "it is the tester's, for the ticket" "$(rec_json "$sd" | jq -r '[.seat, .code, .ticket] | join(" ")')" "tester-wo-20261011-aaaa 100 $T"
assert_match "the receipt says both" "$(ids_of record.routed | while read -r r; do rec_json "$r" | jq -r .note; done)" "routed test.passed 201 \($id\): seat reviewer, down tester"
run_once; assert_eq "the seat.down record is ignored, no 500" "$(fives)" 0

echo "-- a second gate record for the same ticket: the seat is already down, seat.sh says so, no new record, no 500"
next; rec test.passed 201 tester-wo-20261011-aaaa $T >/dev/null; run_once
assert_eq "still one seat.down" "$(ids_of seat.down | grep -c .)" 1
assert_eq "no 500" "$(fives)" 0

echo "-- a test 422 wakes the worker (no bring-up) and takes the tester down; so does the escalation at attempt 3"
next; U=WO-20261011-bbbb; rec pr.opened 100 worker-wo-20261011-bbbb $U >/dev/null; run_once; next
idf=$(rec test.failed 422 tester-wo-20261011-bbbb $U 1); run_once
assert_eq "the worker was woken first, then the tester went down" "$(order)" "herdr seat "
assert_match "worker prompt" "$(tail -1 "$HLOG")" "agent prompt worker-wo-20261011-bbbb record $idf playbook"
assert_eq "the seat call was a --down" "$(tail -1 "$W/seat.log")" "--down tester-wo-20261011-bbbb"
next; V=WO-20261011-cccc; rec pr.opened 100 worker-wo-20261011-cccc $V >/dev/null; run_once; next
rec test.failed 422 tester-wo-20261011-cccc $V 3 >/dev/null; run_once
assert_eq "an escalated record was written" "$(ids_of escalated | grep -c .)" 1
assert_eq "and the tester went down" "$(tail -1 "$W/seat.log")" "--down tester-wo-20261011-cccc"

echo "-- review.passed seats the merger and takes the reviewer down; review.changes wakes the worker and takes the reviewer down"
next; rec review.passed 201 reviewer-wo-20261011-aaaa $T >/dev/null; run_once
assert_eq "merger up, prompt, reviewer down" "$(order)" "seat herdr seat "
assert_eq "reviewer went down" "$(tail -1 "$W/seat.log")" "--down reviewer-wo-20261011-aaaa"
next; rec review.changes 422 reviewer-wo-20261011-bbbb $U 1 >/dev/null; run_once
assert_eq "worker woken, reviewer down" "$(order)" "herdr seat "
assert_eq "the reviewer of the other ticket" "$(tail -1 "$W/seat.log")" "--down reviewer-wo-20261011-bbbb"

echo "-- merged 200 seats the verifier, wakes it, and takes the merger down; merge.conflict 409 wakes the worker and takes it down"
next; idm=$(rec merged 200 merger $T); run_once
assert_eq "verifier up, prompt, merger down" "$(order)" "seat herdr seat "
assert_eq "the verifier was seated for the ticket" "$(grep -c -e '--ticket '$T' --role verifier' "$W/seat.log")" 1
assert_match "the verifier line" "$(grep 'agent prompt' "$HLOG" | tail -1)" "agent prompt verifier-wo-20261011-aaaa record $idm playbook $R/playbooks/verifier.md"
assert_eq "the merger is one shared seat: --down merger" "$(tail -1 "$W/seat.log")" "--down merger"
echo "-- verified 201 and rejected 422 wake the monitor and take the verifier down; neither reaches the architect"
next; idv=$(rec verified 201 verifier-wo-20261011-aaaa $T); run_once
assert_eq "monitor woken, verifier down" "$(order)" "herdr seat "
assert_match "the monitor line" "$(tail -1 "$HLOG")" "agent prompt monitor record $idv playbook"
assert_eq "the verifier of the ticket went down" "$(tail -1 "$W/seat.log")" "--down verifier-wo-20261011-aaaa"
next; idr=$(rec rejected 422 verifier-wo-20261011-bbbb $U); run_once
assert_match "the monitor line for a rejection" "$(tail -1 "$HLOG")" "agent prompt monitor record $idr playbook"
assert_eq "no architect was ever prompted" "$(grep -c 'agent prompt architect' "$HLOG")" 0
next; rec merge.conflict 409 merger $U >/dev/null; run_once
assert_eq "worker woken, merger down again (seat.sh says already down)" "$(order)" "herdr seat "
assert_eq "no 500 through all of that" "$(fives)" 0

echo "-- the primary action failing does not leave the seat up"
next; W2=WO-20261011-dddd; rec pr.opened 100 worker-wo-20261011-dddd $W2 >/dev/null; run_once; next
touch "$W/herdr.fail"; idx=$(rec test.passed 201 tester-wo-20261011-dddd $W2); run_once; rm -f "$W/herdr.fail"
assert_eq "the tester still went down" "$(tail -1 "$W/seat.log")" "--down tester-wo-20261011-dddd"
n=$(grep -l "$idx" "$R"/events/20*/*/*-500-*.json | head -1)
assert_match "the 500 names the prompt that failed" "$(jq -r .note "$n")" "route failed for test.passed 201, record $idx: herdr agent prompt reviewer-wo-20261011-dddd failed"

echo "-- a failing --down is a 500 that says so, and the primary action was still done"
next; X=WO-20261011-eeee; rec pr.opened 100 worker-wo-20261011-eeee $X >/dev/null; run_once; next
before=$(hcalls); printf 'seat.sh: slot holds a foreign process\n' > "$W/seat.fail.down"
idy=$(rec test.passed 201 tester-wo-20261011-eeee $X); run_once; rm -f "$W/seat.fail.down"
assert_eq "the reviewer was prompted" "$(hcalls)" "$((before + 1))"
n=$(grep -l "$idy" "$R"/events/20*/*/*-500-*.json | head -1)
assert_match "the 500 names the --down and its reason" "$(jq -r .note "$n")" "route failed for test.passed 201, record $idy: seat.sh --down tester-wo-20261011-eeee failed \(exit 3\): seat.sh: slot holds a foreign process"
echo "-- a gate record with no ticket cannot name a seat: a 500, seat.sh not called"
next; before=$(grep -c . "$W/seat.log"); idz=$(rec test.passed 201 tester-wo-20261011-eeee); run_once
assert_eq "seat.sh not called" "$(grep -c . "$W/seat.log")" "$before"
n=$(grep -l "$idz" "$R"/events/20*/*/*-500-*.json | head -1)
assert_match "the 500 says both reasons" "$(jq -r .note "$n")" "record $idz: seat needs a ticket; down needs a ticket"
case_done
