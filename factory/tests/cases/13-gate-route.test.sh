#!/usr/bin/env bash
# Catches: the runner waking the merger for a review on a head that differs from the tested one by a code change, or holding it for one
# that differs by record files only (WO-20261012-3bb0 AC-H1); a held record taking the tester seat down or writing a 500; a second
# pr.opened whose wake line does not name the older head, and a result on the older head still reaching the reviewer or the worker
# (AC-H2); merge.conflict 409 reaching the worker without "merge main"; a gate.sh failure turning into a silent hold instead of a 500.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up gateroute
fives() { find "$R/events" -name '*-500-*.json' | wc -l | tr -d ' '; }
receipts() { ids_of record.routed | while read -r r; do rec_json "$r" | jq -r .note; done; }
seat_calls() { grep -c -e "$1" "$W/seat.log" | tr -d ' '; }

echo "-- three heads: A, B = A plus a record file under events/, C = A plus a code change"
git -C "$R" init -q -b main; git -C "$R" config user.email t@example.invalid; git -C "$R" config user.name t
echo one > "$R/code.txt"; git -C "$R" add -A; git -C "$R" commit -q -m A; A=$(git -C "$R" rev-parse --short=7 HEAD)
mkdir -p "$R/events/2026/10"; echo '{}' > "$R/events/2026/10/20261012T000000Z-100-zzzzz.json"; git -C "$R" add -A; git -C "$R" commit -q -m B; B=$(git -C "$R" rev-parse --short=7 HEAD)
git -C "$R" checkout -q "$A"; echo two > "$R/code.txt"; git -C "$R" commit -q -am C; C=$(git -C "$R" rev-parse --short=7 HEAD)

echo "-- AC-H1: tested on A, reviewed on B (one record file apart): the merger is seated and woken with the review's sha"
T1=WO-20261012-1111
evo --code 100 --seat worker-wo-20261012-1111 --kind pr.opened --ticket $T1 --sha "$A" --pr 5 >/dev/null
evo --code 201 --seat tester-wo-20261012-1111 --kind test.passed --ticket $T1 --sha "$A" --pr 5 >/dev/null
rp=$(evo --code 201 --seat reviewer-wo-20261012-1111 --kind review.passed --ticket $T1 --sha "$B" --pr 5)
run_once; assert_eq "exit 0" "$?" 0
assert_match "the merger line carries pr 5 and the review's sha B" "$(cat "$HLOG")" "^--session stable agent prompt merger record $rp pr 5 sha $B playbook $R/playbooks/merger.md$"
assert_eq "seat.sh brought the merger up" "$(seat_calls "--ticket $T1 --role merger")" 1
assert_eq "and took the reviewer down" "$(seat_calls "--down reviewer-wo-20261012-1111")" 1
assert_eq "no 500" "$(fives)" 0

echo "-- AC-H1: tested on A, reviewed on C (code.txt differs): held - a receipt that says why, no merger, no seat call, no 500"
T2=WO-20261012-2222
evo --code 100 --seat worker-wo-20261012-2222 --kind pr.opened --ticket $T2 --sha "$A" --pr 6 >/dev/null
evo --code 201 --seat tester-wo-20261012-2222 --kind test.passed --ticket $T2 --sha "$A" --pr 6 >/dev/null
rc=$(evo --code 201 --seat reviewer-wo-20261012-2222 --kind review.passed --ticket $T2 --sha "$C" --pr 6)
run_once
assert_eq "no merger prompt for it" "$(grep -c "record $rc " "$HLOG" | tr -d ' ')" 0
assert_eq "no merger seat for $T2" "$(seat_calls "--ticket $T2 --role merger")" 0
assert_eq "the reviewer stays up: a held record takes nothing down" "$(seat_calls "--down reviewer-wo-20261012-2222")" 0
assert_match "the receipt says held, names the record, the shas and the path" "$(receipts)" "held review.passed 201 \($rc\): test.passed .* on $A and this record's $C differ outside events/: code.txt"
assert_eq "the ledger says held" "$(cut -d' ' -f1 "$STATE/routed/$rc")" held
assert_eq "no 500" "$(fives)" 0
run_once; assert_eq "a second tick does not route it again" "$(receipts | grep -c "held review.passed 201 ($rc)")" 1

echo "-- a review with no test.passed at all is held too"
T3=WO-20261012-3333
rn=$(evo --code 201 --seat reviewer-wo-20261012-3333 --kind review.passed --ticket $T3 --sha "$A" --pr 7)
run_once
assert_match "held, and says there is no test" "$(receipts)" "held review.passed 201 \($rn\): no test.passed for $T3"
assert_eq "no merger seat for $T3" "$(seat_calls "--ticket $T3 --role merger")" 0

echo "-- AC-H2: a second pr.opened names the older head; a result on the older head reaches nobody and takes no seat down"
T4=WO-20261012-4444
p1=$(evo --code 100 --seat worker-wo-20261012-4444 --kind pr.opened --ticket $T4 --sha "$A" --pr 9)
run_once
assert_match "the first wake is the plain pr/sha line" "$(tail -1 "$HLOG")" "^--session stable agent prompt tester-wo-20261012-4444 record $p1 pr 9 sha $A playbook $R/playbooks/tester.md$"
p2=$(evo --code 100 --seat worker-wo-20261012-4444 --kind pr.opened --ticket $T4 --sha "$C" --pr 9)
run_once
assert_match "the second names the first as superseded" "$(tail -1 "$HLOG")" "^--session stable agent prompt tester-wo-20261012-4444 record $p2 pr 9 sha $C supersedes $p1 playbook $R/playbooks/tester.md$"
calls=$(hcalls); downs=$(seat_calls "--down tester-wo-20261012-4444")
ts=$(evo --code 201 --seat tester-wo-20261012-4444 --kind test.passed --ticket $T4 --sha "$A" --pr 9)
tf=$(evo --code 422 --seat tester-wo-20261012-4444 --kind test.failed --ticket $T4 --sha "$A" --pr 9 --attempt 1)
run_once
assert_eq "no herdr call for the older head's results" "$(hcalls)" "$calls"
assert_eq "the tester seat, now running the newer head, was not taken down" "$(seat_calls "--down tester-wo-20261012-4444")" "$downs"
assert_match "test.passed is held, saying the head moved" "$(receipts)" "held test.passed 201 \($ts\): the head moved: pr.opened $p2 names $C"
assert_match "test.failed is held too" "$(receipts)" "held test.failed 422 \($tf\): the head moved"
tc=$(evo --code 201 --seat tester-wo-20261012-4444 --kind test.passed --ticket $T4 --sha "$C" --pr 9)
run_once
assert_match "a result on the newer head wakes the reviewer" "$(tail -1 "$HLOG")" "^--session stable agent prompt reviewer-wo-20261012-4444 record $tc pr 9 sha $C playbook $R/playbooks/reviewer.md$"
assert_eq "and takes the tester down" "$(tail -1 "$W/seat.log")" "--down tester-wo-20261012-4444"
assert_eq "no 500 through all of that" "$(fives)" 0

echo "-- a pr.opened with a sha one record file apart from the running head does not supersede it"
T5=WO-20261012-5555
evo --code 100 --seat worker-wo-20261012-5555 --kind pr.opened --ticket $T5 --sha "$A" --pr 10 >/dev/null
q2=$(evo --code 100 --seat worker-wo-20261012-5555 --kind pr.opened --ticket $T5 --sha "$B" --pr 10)
run_once
assert_match "the line has no supersedes" "$(tail -1 "$HLOG")" "^--session stable agent prompt tester-wo-20261012-5555 record $q2 pr 10 sha $B playbook"

echo "-- merge.conflict 409 wakes the worker with the PR and the words merge main, and takes the merger down"
T6=WO-20261012-6666
mc=$(evo --code 409 --seat merger --kind merge.conflict --ticket $T6 --pr 12 --sha "$C")
run_once
assert_match "worker line" "$(grep "record $mc " "$HLOG")" "^--session stable agent prompt worker-wo-20261012-6666 record $mc pr 12 sha $C merge main playbook $R/playbooks/worker.md$"
assert_eq "merger down" "$(tail -1 "$W/seat.log")" "--down merger"
assert_eq "still no 500" "$(fives)" 0

echo "-- gate.sh failing (a sha this repo does not have) is a 500 that names it, and nothing is sent"
T7=WO-20261012-7777
evo --code 201 --seat tester-wo-20261012-7777 --kind test.passed --ticket $T7 --sha "$A" --pr 13 >/dev/null
rx=$(evo --code 201 --seat reviewer-wo-20261012-7777 --kind review.passed --ticket $T7 --sha 1234567 --pr 13)
run_once
assert_eq "no herdr call for the review" "$(grep -c "record $rx " "$HLOG" | tr -d ' ')" 0
assert_eq "exactly one 500" "$(fives)" 1
assert_match "it names the record, the predicate and the exit code" "$(cat "$R"/events/20*/*/*-500-*.json | jq -r .note)" "route failed for review.passed 201, record $rx: gate.sh when heads_match failed \(exit 4\)"
assert_eq "the ledger says failed" "$(cat "$STATE/routed/$rx")" failed
case_done
