#!/usr/bin/env bash
# T03 compaction replay (SPEC-17 s-tests; AC-H2 of WO-20261013-f268): twenty queued nudges to one seat collapse into one pull with no
# item lost. After a compaction a queue of stale nudges used to replay into the seat one prompt each (s-inventory H23); a nudge carries
# no content, so the replay costs one pull, and the board still holds every item.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"; world_init

for n in $(seq 1 20); do board post --id "$(rid "$n")" --lane tester --kind test.passed --code 201 --ticket WO-20261013-f268 >/dev/null; done

echo "-- twenty nudge attempts to one seat: one prompt"
for _ in $(seq 1 20); do board nudge --lane tester --seat tester-1 >/dev/null 2>&1; done
assert_eq "one prompt reached the seat" "$(prompts)" 1

echo "-- the seat pulls once and gets one item; the other nineteen are still on the board"
got=$(board pull --lane tester --holder tester-1)
assert_eq "the oldest item came back" "$got" "$(rid 1)"
assert_eq "nineteen open" "$(board list --lane tester --json | jq '[.[] | select(.lease == null)] | length')" 19
assert_eq "one leased" "$(board list --lane tester --json | jq '[.[] | select(.lease != null)] | length')" 1
assert_eq "none lost: twenty on the lane" "$(board list --lane tester --json | jq 'length')" 20
assert_match "check passes" "$(board check 2>&1)" "^board ok: 20 items"

echo "-- a replay after the compaction: twenty more attempts cost nothing, one more pull gets the next item"
for _ in $(seq 1 20); do board nudge --lane tester --seat tester-1 >/dev/null 2>&1; done
assert_eq "still one prompt" "$(prompts)" 1
assert_eq "the next pull gets the next item" "$(board pull --lane tester --holder tester-1)" "$(rid 2)"

echo "-- the health line agrees"
h=$(board health)
assert_eq "tester lane: eighteen open" "$(printf '%s' "$h" | jq '.lanes.tester.open')" 18
assert_eq "tester lane: two leased" "$(printf '%s' "$h" | jq '.lanes.tester.leased')" 2
assert_eq "the line is running" "$(printf '%s' "$h" | jq -r .state)" running
assert_file "the health file is beside the items" "$W/state/board/health.json"
mkdir -p "$W/state/run"; : > "$W/state/run/drain"
assert_eq "a drain flag reads as draining" "$(board health | jq -r .state)" draining
: > "$W/state/run/halt"
assert_eq "a halt flag wins over a drain" "$(board health | jq -r .state)" halted
case_done
