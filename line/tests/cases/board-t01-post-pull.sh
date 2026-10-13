#!/usr/bin/env bash
# T01 post then pull (SPEC-17 s-tests; AC-H1 of WO-20261013-f268): an item posted to the tester lane is pulled once by one holder, a second
# pull exits 6, done moves it to the done tree, and the item id equals the record id. Beside it: priority and age order, refusals, the
# claim that lets two pullers race without a lock, and the lease verbs.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"; world_init
A=$(rid 1)

echo "-- post from a record: the item id is the record id"
jq -n --arg id "$A" '{id:$id, kind:"test.passed", code:201, ticket:"WO-20261013-f268", seat:"tester-x"}' > "$W/rec.json"
out=$(board post --record "$W/rec.json" --lane tester); rc=$?
assert_eq "post exits 0" "$rc" 0
assert_eq "post prints the record id" "$out" "$A"
assert_file "the item is a file in the lane" "$W/state/board/tester/p2-$A.json"
assert_eq "the item id equals the record id" "$(jq -r .id "$W/state/board/tester/p2-$A.json")" "$A"
assert_eq "the kind came from the record" "$(jq -r .kind "$W/state/board/tester/p2-$A.json")" "test.passed"

echo "-- one holder pulls it, the second pull exits 6"
out=$(board pull --lane tester --holder tester-1); rc=$?
assert_eq "first pull exits 0" "$rc" 0
assert_eq "first pull prints the id" "$out" "$A"
assert_eq "the lease names the holder" "$(jq -r .lease.holder "$W/state/board/tester/p2-$A.json")" "tester-1"
board pull --lane tester --holder tester-2 >/dev/null 2>&1; assert_eq "second pull exits 6" "$?" 6

echo "-- done moves it to the done tree, stamped with the result record"
R=$(rid 2)
board "done" --id "$A" --result "$R" --by tester-2 >/dev/null 2>"$W/err"; assert_eq "done by a seat that is not the holder exits 3" "$?" 3
assert_file "the item is still open after the refusal" "$W/state/board/tester/p2-$A.json"
out=$(board "done" --id "$A" --result "$R" --by tester-1); rc=$?
assert_eq "done exits 0" "$rc" 0
assert_no_file "the open item is gone" "$W/state/board/tester/p2-$A.json"
assert_file "the done item exists" "$out"
assert_match "it sits in the done tree by year and month, stamp first, then the id" "$out" "/board/done/20[0-9]{2}/[0-9]{2}/[0-9]{14}-${A,,}\.json$"
assert_eq "its id is still the record id" "$(jq -r .id "$out")" "$A"
assert_eq "it carries the result record" "$(jq -r .done.result "$out")" "$R"
assert_eq "it carries who finished it" "$(jq -r .done.by "$out")" "tester-1"
board pull --lane tester --holder tester-1 >/dev/null 2>&1; assert_eq "nothing left to pull: exit 6" "$?" 6
board "done" --id "$A" --result "$R" >/dev/null 2>&1; assert_eq "done twice: exit 6" "$?" 6
board post --id "$A" --lane tester --kind test.passed --code 201 >/dev/null 2>"$W/err"; assert_eq "a done id cannot be posted again: exit 3" "$?" 3

echo "-- priority first, then older first"
board post --id "$(rid 10)" --lane reviewer --kind note --code 100 --priority p3 >/dev/null
board post --id "$(rid 11)" --lane reviewer --kind gate --code 201 --priority p2 >/dev/null
board post --id "$(rid 12)" --lane reviewer --kind gate --code 201 --priority p2 >/dev/null
board post --id "$(rid 13)" --lane reviewer --kind blocked --code 423 --priority p0 >/dev/null
got=$(for _ in 1 2 3 4; do board pull --lane reviewer --holder r1; done | tr '\n' ' ')
assert_eq "p0, then the two p2 oldest first, then p3" "$got" "$(rid 13) $(rid 11) $(rid 12) $(rid 10) "

echo "-- refusals: no lane, an unknown lane, a bad id, a duplicate"
board post --id "$(rid 20)" --kind note --code 100 >/dev/null 2>"$W/err"; rc=$?
assert_eq "a record without a lane: exit 3" "$rc" 3; assert_match "it says why" "$(cat "$W/err")" "without a lane"
board post --id "$(rid 20)" --lane nobody --kind note --code 100 >/dev/null 2>&1; assert_eq "an unknown lane: exit 3" "$?" 3
board post --id nonsense --lane tester --kind note --code 100 >/dev/null 2>&1; assert_eq "a bad id: exit 3" "$?" 3
board post --id "$(rid 20)" --lane tester --kind note --code 99 >/dev/null 2>&1; assert_eq "a code under 100: exit 3" "$?" 3
board post --id "$(rid 20)" --lane tester --kind note --code 100 >/dev/null; board post --id "$(rid 20)" --lane merger --kind note --code 100 >/dev/null 2>&1
assert_eq "one id on two lanes: exit 3" "$?" 3
board post --id "$(rid 21)" --lane tester --bogus >/dev/null 2>&1; assert_eq "an unknown flag: exit 2" "$?" 2
board nonsense >/dev/null 2>&1; assert_eq "an unknown verb: exit 2" "$?" 2

echo "-- twelve pullers race for eight items: each item is leased exactly once"
for n in 30 31 32 33 34 35 36 37; do board post --id "$(rid $n)" --lane merger --kind merged --code 200 >/dev/null; done
seq 1 12 | xargs -P12 -I{} bash "$BOARD_SH" pull --lane merger --holder "m{}" > "$W/race.out" 2>/dev/null || true
assert_eq "eight ids came back" "$(wc -l < "$W/race.out" | tr -d ' ')" 8
assert_eq "no id came back twice" "$(sort "$W/race.out" | uniq -d | wc -l | tr -d ' ')" 0
assert_eq "all eight are leased" "$(board list --lane merger --json | jq '[.[] | select(.lease != null)] | length')" 8
assert_match "check passes with no claim left behind" "$(board check 2>&1)" "^board ok"

echo "-- renew, release, and a sweep that counts expiries"
B=$(rid 40); board post --id "$B" --lane worker --kind blocked --code 423 --ticket WO-20261013-f268 >/dev/null
board pull --lane worker --holder w1 >/dev/null
f="$W/state/board/worker/p2-$B.json"; before=$(jq -r .lease.deadline "$f")
board renew --id "$B" --holder w2 >/dev/null 2>&1; assert_eq "renew by another seat: exit 3" "$?" 3
sleep 1; board renew --id "$B" --holder w1; assert_eq "renew by the holder: exit 0" "$?" 0
check "the deadline moved out" "$([ "$(jq -r .lease.deadline "$f")" != "$before" ] && echo 1 || echo 0)"
board release --id "$B" --holder w1; assert_eq "release: exit 0" "$?" 0
assert_eq "released means open" "$(jq -r '.lease' "$f")" "null"
assert_eq "release leaves the attempt unchanged" "$(jq -r .attempt "$f")" 1
for i in 1 2 3; do
  board pull --lane worker --holder w1 >/dev/null
  jq '.lease.deadline = "2020-01-01T00:00:00Z"' "$f" > "$f.t" && mv "$f.t" "$f"
  sweep=$(board sweep); assert_match "sweep $i releases the expired lease" "$sweep" "released expired lease $B lane worker expiry $i"
done
assert_match "the third expiry is a finding" "$sweep" "finding lease-expired-3 $B lane worker"
assert_eq "the item is open again" "$(jq -r '.lease' "$f")" "null"
board check >/dev/null 2>&1; assert_eq "check still passes" "$?" 0
case_done
