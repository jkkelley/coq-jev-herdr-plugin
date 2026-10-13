#!/usr/bin/env bash
# digest (WO-20261013-0ffe, AC-H1): line/bin/digest.sh sends the architect ONE prompt per interval, and none for an interval with nothing.
#   two records addressed to the architect in one interval -> exactly one stubbed prompt, naming both and counting two
#   a record of an architect or route-runner seat, a kind the digest does not carry, a record from before the window: not in the prompt
#   a route failure (code 500) is counted without being listed
#   the next interval, nothing new -> no prompt
#   every file the script writes lands under the state root, and the file holds no /home/luna and no .cache/coq-watch
# The script loops forever; DIGEST_ROUNDS=1 makes it stop after one interval, DIGEST_SECONDS=1 keeps the case to seconds. The fake herdr
# of lib/world.sh logs its argv, so a prompt is a line of it.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"; world_init
DIGEST_SH=$REPO/line/bin/digest.sh
export DIGEST_SECONDS=1 DIGEST_ROUNDS=1
RUN=$W/state/run; REC=$W/state/records/2026/10; mkdir -p "$RUN" "$REC"
# rec NAME SEAT KIND TO CODE AT: one record file, the shape bin/event.sh writes (id, at, code, seat, kind, ticket, optional to)
rec() {
  local stamp; stamp=$(date -u -d "$6" +%Y%m%dT%H%M%SZ)
  jq -n --arg id "$stamp-$5-$1" --arg at "$(date -u -d "$6" +%Y-%m-%dT%H:%M:%SZ)" --argjson code "$5" --arg seat "$2" --arg kind "$3" --arg to "$4" \
    '{schema_version: "1.0.0", id: $id, at: $at, code: $code, seat: $seat, kind: $kind, ticket: "WO-20261013-0ffe"} + (if $to == "" then {} else {to: $to} end)' \
    > "$REC/$(date -u -d "$6" +%Y%m%d%H%M%S)-$3-$1.json"
}
digest() { bash "$DIGEST_SH"; }

echo "-- two records for the architect in one interval: one prompt"
date -u -d '30 minutes ago' +%Y%m%dT%H%M%SZ > "$RUN/digest.last"
rec aaaaa worker-1 blocked "" 423 '5 minutes ago'
rec bbbbb tester-1 note architect 300 '4 minutes ago'
rec ccccc architect merged "" 200 '3 minutes ago'
rec ddddd worker-1 work.started "" 100 '3 minutes ago'
rec eeeee route-runner blocked "" 423 '3 minutes ago'
rec fffff route-runner route.failed "" 500 '2 minutes ago'
rec ggggg worker-9 blocked "" 423 '2 hours ago'
out=$(digest 2>&1); rc=$?
assert_eq "it exits 0 after its one round" "$rc" 0
assert_eq "one prompt in all" "$(prompts)" 1
log=$(cat "$W/herdr.log")
assert_match "it went to the architect through the session" "$log" "^--session t-board agent prompt architect DIGEST "
assert_match "it counts two records and one route failure" "$log" "2 records for you, 1 route failures\."
assert_match "it names the blocked record" "$log" "blocked WO-20261013-0ffe pr=-"
assert_match "it names the record addressed to the architect" "$log" "note WO-20261013-0ffe pr=-"
assert_no_match "the architect's own record is not in it" "$log" "merged"
assert_no_match "a kind the digest does not carry is not in it" "$log" "work.started"
assert_no_match "a record from before the window is not in it" "$log" "ggggg"
assert_match "it says it sent" "$out" "digest sent"

echo "-- the next interval has nothing new: no prompt"
: > "$W/herdr.log"
out=$(digest 2>&1)
assert_eq "no prompt" "$(prompts)" 0
assert_match "it says nothing" "$out" "digest: nothing"

echo "-- a later interval with a new record prompts again"
rec hhhhh worker-2 escalated "" 400 'now'
sleep 1; digest >/dev/null 2>&1
assert_eq "one prompt for the new record" "$(prompts)" 1

echo "-- what it writes and what it carries"
assert_file "the window start is in the state root" "$RUN/digest.last"
stray=$(find "$W" -type f ! -path "$W/state/*" ! -path "$W/bin/herdr" ! -path "$W/herdr.log" ! -path "$W/board.json" | head -3)
assert_eq "the state root holds the records and digest.last and nothing else" "$(find "$W/state" -type f ! -path "$REC/*" | sed "s|$W/state/||")" "run/digest.last"
assert_eq "nothing is written outside the state root" "$stray" ""
assert_eq "no /home/luna in the script" "$(grep -c '/home/luna' "$DIGEST_SH")" 0
assert_eq "no .cache/coq-watch in the script" "$(grep -c '\.cache/coq-watch' "$DIGEST_SH")" 0
case_done
