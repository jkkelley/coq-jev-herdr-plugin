#!/usr/bin/env bash
# Catches: a merge held for a head that differs from the tested one only by record files under events/ (WO-20261012-3bb0 AC-H1,
# the 2026-10-12 efc1cd2 / 43c22b4 case); a head that differs by any other path being let through; a test on a head the worker
# already moved past counting; a second pr.opened not finding the older head it supersedes; a duplicate pr.opened for the same
# head superseding itself; a record with no sha being held by head_current or let through by heads_match.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261012-aaaa
world_up gate
GATE="$R/factory/bin/gate.sh"
ev() { evo "$@"; }
g() { "$GATE" "$@" --repo "$R"; }

echo "-- a repo with three heads: A, B = A plus one record file under events/, C = A plus a code change"
git -C "$R" init -q -b main; git -C "$R" config user.email t@example.invalid; git -C "$R" config user.name t
echo one > "$R/code.txt"; git -C "$R" add -A; git -C "$R" commit -q -m A; A=$(git -C "$R" rev-parse --short=7 HEAD)
mkdir -p "$R/events/2026/10"; echo '{}' > "$R/events/2026/10/20261012T000000Z-100-zzzzz.json"; git -C "$R" add -A; git -C "$R" commit -q -m B; B=$(git -C "$R" rev-parse --short=7 HEAD)
git -C "$R" checkout -q "$A"; echo two > "$R/code.txt"; git -C "$R" commit -q -am C; C=$(git -C "$R" rev-parse --short=7 HEAD)

echo "-- AC-H1: same-head counts a difference under events/ as the same head and any other path as a different one"
out=$(g same-head "$A" "$B"); assert_eq "A and B differ only under events/: same, exit 0" "$?" 0
assert_eq "and nothing is printed" "$out" ""
out=$(g same-head "$A" "$C"); assert_eq "A and C differ in code.txt: exit 1" "$?" 1
assert_eq "the path is named" "$out" "code.txt"
out=$(g same-head "$B" "$C"); assert_eq "B and C: exit 1" "$?" 1
g same-head "$A" "$A" >/dev/null; assert_eq "one sha against itself" "$?" 0
g same-head "$A" "${A}0123456" >/dev/null; assert_eq "a prefix of the other is the same head, no git needed" "$?" 0
g same-head "$A" 1234567 >/dev/null 2>&1; assert_eq "a sha the repo does not have: exit 4, not a difference" "$?" 4
g same-head "$A" 'not-a-sha' >/dev/null 2>&1; assert_eq "a malformed sha: exit 4" "$?" 4
g same-head "$A" >/dev/null 2>&1; assert_eq "one sha: usage, exit 2" "$?" 2

echo "-- heads_match: test on A, review on B (events only) is merged; review on C is held"
ev --code 100 --seat worker-wo-20261012-aaaa --kind pr.opened --ticket $T --sha "$A" --pr 5 >/dev/null
tp=$(ev --code 201 --seat tester-wo-20261012-aaaa --kind test.passed --ticket $T --sha "$A" --pr 5)
rp=$(ev --code 201 --seat reviewer-wo-20261012-aaaa --kind review.passed --ticket $T --sha "$B" --pr 5)
out=$(g when heads_match --id "$rp"); assert_eq "review on B, test on A: proceed, exit 0" "$?" 0
rc=$(ev --code 201 --seat reviewer-wo-20261012-aaaa --kind review.passed --ticket $T --sha "$C" --pr 5)
out=$(g when heads_match --id "$rc"); assert_eq "review on C, test on A: hold, exit 1" "$?" 1
assert_match "the reason names the test record, the shas and the path" "$out" "test.passed $tp on $A and this record's $C differ outside events/: code.txt"
assert_eq "the reason is one line" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" 1

echo "-- heads_match holds on a missing sha, a missing test, and a head that moved"
rn=$(ev --code 201 --seat reviewer-wo-20261012-aaaa --kind review.passed --ticket $T --pr 5)
out=$(g when heads_match --id "$rn"); assert_eq "a review with no sha: hold" "$?" 1; assert_match "says so" "$out" "carries no sha"
U=WO-20261012-bbbb
ru=$(ev --code 201 --seat reviewer-wo-20261012-bbbb --kind review.passed --ticket $U --sha "$A" --pr 6)
out=$(g when heads_match --id "$ru"); assert_eq "no test.passed for the ticket: hold" "$?" 1; assert_match "says so" "$out" "no test.passed for $U"
tn=$(ev --code 201 --seat tester-wo-20261012-bbbb --kind test.passed --ticket $U --pr 6)
rt=$(ev --code 201 --seat reviewer-wo-20261012-bbbb --kind review.passed --ticket $U --sha "$A" --pr 6)
out=$(g when heads_match --id "$rt"); assert_eq "a test with no sha: hold" "$?" 1; assert_match "says so" "$out" "test.passed $tn carries no sha"

echo "-- head_current: a result on a head the worker moved past is held; one on the current head, or with no sha, passes"
ev --code 100 --seat worker-wo-20261012-aaaa --kind pr.opened --ticket $T --sha "$C" --pr 5 >/dev/null
ts=$(ev --code 201 --seat tester-wo-20261012-aaaa --kind test.passed --ticket $T --sha "$A" --pr 5)
out=$(g when head_current --id "$ts"); assert_eq "test on A after pr.opened on C: hold" "$?" 1; assert_match "the reason says the head moved" "$out" "the head moved: pr.opened .* names $C"
tc=$(ev --code 201 --seat tester-wo-20261012-aaaa --kind test.passed --ticket $T --sha "$C" --pr 5)
g when head_current --id "$tc" >/dev/null; assert_eq "test on C: proceed" "$?" 0
tb=$(ev --code 201 --seat tester-wo-20261012-aaaa --kind test.passed --ticket $T --sha "$B" --pr 5)
g when head_current --id "$tb" >/dev/null; assert_eq "test on B against a head of C: hold, B differs from C in code.txt" "$?" 1
tz=$(ev --code 201 --seat tester-wo-20261012-aaaa --kind test.passed --ticket $T --pr 5)
g when head_current --id "$tz" >/dev/null; assert_eq "a result with no sha: proceed" "$?" 0
V=WO-20261012-cccc
tv=$(ev --code 201 --seat tester-wo-20261012-cccc --kind test.passed --ticket $V --sha "$A" --pr 7)
g when head_current --id "$tv" >/dev/null; assert_eq "a ticket with no pr.opened: proceed" "$?" 0
g when nonsense --id "$tv" >/dev/null 2>&1; assert_eq "an unknown predicate: exit 2" "$?" 2
g when head_current --id 20260101T000000Z-100-nope >/dev/null 2>&1; assert_eq "an unknown record: exit 4" "$?" 4

echo "-- AC-H2: supersedes names the older head that has no tester result yet, and only that"
W2=WO-20261012-dddd
p1=$(ev --code 100 --seat worker-wo-20261012-dddd --kind pr.opened --ticket $W2 --sha "$A" --pr 8)
p2=$(ev --code 100 --seat worker-wo-20261012-dddd --kind pr.opened --ticket $W2 --sha "$C" --pr 8)
assert_eq "the first pr.opened supersedes nothing" "$(g supersedes --id "$p1")" ""
assert_eq "the second names the first" "$(g supersedes --id "$p2")" "$p1"
p3=$(ev --code 100 --seat worker-wo-20261012-dddd --kind pr.opened --ticket $W2 --sha "$C" --pr 8)
assert_eq "a third on the same head as the second: the second is in flight but is the same head, nothing is dropped" "$(g supersedes --id "$p3")" ""
ev --code 422 --seat tester-wo-20261012-dddd --kind test.failed --ticket $W2 --sha "$C" --pr 8 >/dev/null
p4=$(ev --code 100 --seat worker-wo-20261012-dddd --kind pr.opened --ticket $W2 --sha "$A" --pr 8)
assert_eq "after a tester result the older head is finished: nothing to supersede" "$(g supersedes --id "$p4")" ""
p5=$(ev --code 100 --seat worker-wo-20261012-dddd --kind pr.opened --ticket $W2 --pr 8)
assert_eq "a pr.opened with no sha supersedes nothing" "$(g supersedes --id "$p5")" ""
p6=$(ev --code 100 --seat worker-wo-20261012-dddd --kind pr.opened --ticket $W2 --sha "$B" --pr 8)
assert_eq "B is the same head as A (events only): the in-flight A is not superseded by it" "$(g supersedes --id "$p6")" ""
case_done
