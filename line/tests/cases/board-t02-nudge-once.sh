#!/usr/bin/env bash
# T02 nudge once (SPEC-17 s-tests; AC-H2 of WO-20261013-f268): fifty records posted to the architect lane produce at most one nudge within
# digest_seconds. The flood of 2026-10-12 was one prompt per record; here every post is followed by the nudge call a watch would make
# and the seat still hears one line, with a lane and a count and no record's content.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"; world_init

echo "-- fifty records to the architect lane, a nudge call after each: one prompt"
for n in $(seq 1 50); do
  board post --id "$(rid "$n")" --lane architect --kind blocked --code 423 --ticket WO-20261013-f268 --priority p1 >/dev/null
  board nudge --lane architect --seat architect-1 >/dev/null 2>&1
done
assert_eq "one prompt in all" "$(prompts)" 1
assert_match "it went to the architect's seat, through the session" "$(cat "$W/herdr.log")" "^--session t-board agent prompt architect-1 board: 1 item in lane architect, pull$"
assert_no_match "it carries no record id" "$(cat "$W/herdr.log")" "2026[0-9]{4}T"
assert_no_match "it carries no ticket" "$(cat "$W/herdr.log")" "WO-"
out=$(board nudge --lane architect --seat architect-1); assert_match "a later call says it was suppressed" "$out" "^suppressed: architect-1 was nudged"
assert_eq "still one prompt" "$(prompts)" 1

echo "-- the digest is one block, grouped by ticket, oldest first"
d=$(board digest --lane architect)
assert_match "it opens with the lane and the count" "$(printf '%s' "$d" | head -1)" "^board digest lane architect: 50 open$"
assert_eq "it names the ticket once, with its count" "$(printf '%s' "$d" | grep -c '^WO-20261013-f268 (50)$')" 1
assert_eq "all fifty ids are in it" "$(printf '%s' "$d" | grep -c '^  2026')" 50
assert_eq "the oldest is first" "$(printf '%s' "$d" | sed -n 3p | awk '{print $1}')" "$(rid 1)"

echo "-- fifty callers at once to a fresh seat: still one prompt"
for n in $(seq 101 150); do board post --id "$(rid "$n")" --lane tester --kind test.passed --code 201 >/dev/null; done
: > "$W/herdr.log"
seq 1 50 | xargs -P25 -I{} bash "$BOARD_SH" nudge --lane tester --seat tester-1 >/dev/null 2>&1 || true
assert_eq "one prompt" "$(prompts)" 1
assert_match "it counts the items" "$(cat "$W/herdr.log")" "board: 50 items in lane tester, pull"

echo "-- after the interval the seat hears again; an empty lane is never nudged"
cfg_set nudge_seconds 1
sleep 2; board nudge --lane tester --seat tester-1 >/dev/null; assert_eq "a second prompt after the interval" "$(prompts)" 2
board nudge --lane merger --seat merger-1 >/dev/null 2>&1; assert_eq "an empty lane: exit 6" "$?" 6
assert_eq "no prompt for it" "$(prompts)" 2

echo "-- a prompt that fails is retried at once, not after a whole interval"
: > "$W/herdr.log"; touch "$W/herdr.fail"
board nudge --lane tester --seat tester-2 >/dev/null 2>"$W/err"; assert_eq "herdr failed: exit 4" "$?" 4
rm -f "$W/herdr.fail"
board nudge --lane tester --seat tester-2 >/dev/null; assert_eq "the retry was sent" "$(grep -c 'agent prompt tester-2 ' "$W/herdr.log")" 2
case_done
