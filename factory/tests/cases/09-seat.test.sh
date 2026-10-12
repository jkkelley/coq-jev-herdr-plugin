#!/usr/bin/env bash
# Catches: a pr.opened 100 for a ticket with no tester seat failing as "route failed" because the runner only prompts (500 muiv4,
# 2026-10-11 18:31Z) and the architect seating every tester, reviewer and merger by hand; the prompt going out before the seat
# is up; a second record for a live seat building it again; a refused bring-up vanishing instead of becoming a 500 that names
# what seat.sh said; a wake row calling seat.sh; the belt reading stopped after a slow bring-up (WO-20261011-4db1 AC-H1).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up seat
seats() { grep -c -e '^--ticket' "$W/seat.log" | tr -d ' '; }   # bring-ups only: a row with a down also calls --down

echo "-- AC-H1: a pr.opened 100 for a ticket with no tester seat brings it up through seat.sh and prompts it"
id=$(rec pr.opened 100 worker-wo-20261011-aaaa $T)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "one seat.sh call" "$(seats)" 1
assert_eq "it was --ticket and --role, nothing else" "$(cat "$W/seat.log")" "--ticket $T --role tester"
assert_eq "one herdr call" "$(hcalls)" 1
assert_match "the prompt is the wake line, to the seat seat.sh named" "$(cat "$HLOG")" "^--session stable agent prompt tester-wo-20261011-aaaa record $id playbook $R/playbooks/tester.md$"
assert_eq "seat.sh first, then the prompt" "$(cut -d' ' -f1 "$W/order.log" | tr '\n' ' ')" "seat herdr "
rid=$(ids_of record.routed); r=$(rec_json "$rid")
assert_eq "one receipt, to the tester, for the ticket" "$(jq -r '[.to, .ticket] | join(" ")' <<<"$r")" "tester $T"
assert_match "the receipt says seat" "$(jq -r .note <<<"$r")" "routed pr.opened 100 \($id\): seat tester"
assert_eq "no 500" "$(find "$R/events" -name '*-500-*.json' | wc -l | tr -d ' ')" 0
assert_eq "seat.up 100 is on the log, from seat.sh" "$(ids_of seat.up | grep -c .)" 1

echo "-- a record for a live seat: seat.sh is called and leaves it as is, the prompt still goes"
sleep 1; id2=$(rec pr.opened 100 worker-wo-20261011-aaaa $T)
run_once
assert_eq "two seat.sh calls" "$(seats)" 2
assert_eq "still one seat.up: the live seat was not built again" "$(ids_of seat.up | grep -c .)" 1
assert_match "and the second prompt went to the same seat" "$(tail -1 "$HLOG")" "^--session stable agent prompt tester-wo-20261011-aaaa record $id2 playbook"
run_once
assert_eq "the seat.up record the stub wrote is ignored, not a 500" "$(find "$R/events" -name '*-500-*.json' | wc -l | tr -d ' ')" 0

echo "-- the merger is one shared seat named merger"
sleep 1; id3=$(rec review.passed 201 reviewer-wo-20261011-aaaa $T)
run_once
assert_match "seat.sh --ticket --role merger" "$(grep -e '--role merger' "$W/seat.log")" "^--ticket $T --role merger$"
assert_match "the prompt went to merger" "$(tail -1 "$HLOG")" "^--session stable agent prompt merger record $id3 playbook $R/playbooks/merger.md$"

echo "-- a refused bring-up is a 500 that says what seat.sh said, and nothing is prompted"
printf 'seat.sh: refused - bring-up order: monitor seat monitor is down\n' > "$W/seat.fail"
sleep 1; U=WO-20261011-bbbb; id4=$(rec pr.opened 100 worker-wo-20261011-bbbb $U)
before=$(hcalls); run_once
assert_eq "herdr was not called" "$(hcalls)" "$before"
n=$(grep -l "$id4" "$R"/events/20*/*/*-500-*.json | head -1)
assert_match "the 500 names the record, the command, the exit code and the reason" "$(jq -r .note "$n")" "route failed for pr.opened 100, record $id4: seat.sh --ticket $U --role tester failed \(exit 3\): seat.sh: refused - bring-up order"
assert_eq "it is addressed to the monitor" "$(jq -r .to "$n")" monitor
assert_eq "no receipt for it" "$(ids_of record.routed | grep -c "")" 3
rm -f "$W/seat.fail"

echo "-- a row that stays wake does not call seat.sh"
sleep 1; before=$(seats); rec test.failed 422 tester-wo-20261011-aaaa $T 1 >/dev/null; run_once
assert_eq "seat.sh calls unchanged" "$(seats)" "$before"
assert_match "the worker was woken" "$(tail -1 "$HLOG")" "agent prompt worker-wo-20261011-aaaa record"

echo "-- a seat row for a record with no ticket is a 500, seat.sh is not called"
sleep 1; before=$(seats); id5=$(rec pr.opened 100 worker-wo-20261011-aaaa); run_once
assert_eq "seat.sh calls unchanged" "$(seats)" "$before"
n=$(grep -l "$id5" "$R"/events/20*/*/*-500-*.json | head -1)
assert_match "the 500 says why" "$(jq -r .note "$n")" "route failed for pr.opened 100, record $id5: seat needs a ticket"

echo "-- the belt is touched after a slow bring-up, so it does not read stopped while seat.sh ran"
touch "$W/seat.slow"; sleep 1; V=WO-20261011-cccc; rec pr.opened 100 worker-wo-20261011-cccc $V >/dev/null
run_once
assert_file "the stub saw the belt while it ran" "$W/seat.belt"
check "the belt was touched again after seat.sh returned" "$([ "$(date -r "$STATE/belt" +%s%N)" -gt "$(cat "$W/seat.belt")" ] && echo 1 || echo 0)"
case_done
