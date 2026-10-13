#!/usr/bin/env bash
# flow-table (WO-20261013-ccb8, AC-H1): line/bin/flow-table.sh on a fixture records tree, in a scratch state root, with a fake gh and a
# stub column (the test image has no column; the stub passes the tab-separated rows through, so a case reads fields, not alignment).
#   stage      each ticket's stage is its newest lifecycle record; a tester's seat.up and a note do not move a ticket
#   minutes    minutes in stage = NOW minus that record; a reworked ticket shows its latest pass and its completed-stage minutes
#   attribute  a record with a PR and no ticket belongs to the ticket another record ties to that PR
#   bottleneck the stage with the most SUMMED waiting minutes among live tickets; queued is never named
#   classes    live (open PR or started in the window), stale (neither), held (HELD_PRS), done; gh failing filters nothing
#   window     a ticket whose newest record is older than HOURS is not shown
#   writes     with COQ_STATE set, every file the run writes is under it and the scratch directory is gone afterwards
# NOW is set far from every real record, so the checkout's own events/ tree (which the script also reads) cannot add a ticket.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}; SCRIPT=$REPO/line/bin/flow-table.sh
W=${COQ_CASE_WORK:-$(mktemp -d /tmp/coq-flow-XXXX)}; mkdir -p "$W/bin" "$W/state" "$W/gh"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" TMPDIR="$W/no-such-tmp" GH_FAKE_DIR="$W/gh"
RECS=$W/state/records/2031/03; mkdir -p "$RECS"
NOW=$(date -u -d 2031-03-05T12:00:00Z +%s)

printf '#!/usr/bin/env bash\ncat\n' > "$W/bin/column"
cat > "$W/bin/gh" <<'FAKE'
#!/usr/bin/env bash
[ ! -e "$GH_FAKE_DIR/fail" ] || { echo "gh: HTTP 502" >&2; exit 1; }
cat "$GH_FAKE_DIR/open"
FAKE
chmod +x "$W/bin/column" "$W/bin/gh"

# rec TIME KIND SEAT TICKET PR: one record; TIME is HH:MM on 2031-03-05 (or a full ISO stamp), "-" leaves TICKET or PR out
n=0
rec() {
  n=$((n + 1)); local at=$1; [[ $at == *T* ]] || at=2031-03-05T$at:00Z
  jq -n --arg at "$at" --arg kind "$2" --arg seat "$3" --arg t "$4" --arg pr "$5" \
    '{at:$at, kind:$kind, seat:$seat, code:100} + (if $t != "-" then {ticket:$t} else {} end) + (if $pr != "-" then {pr:($pr|tonumber)} else {} end)' \
    > "$RECS/$(printf '%04d' "$n")-$2.json"
}
row() { printf '%s\n' "$OUT" | awk -F'\t' -v t="$1" '$1 == t' | head -1; }   # the table row of ticket T
col() { printf '%s' "$1" | cut -f"$2"; }                                       # field N of a row

# TA: queued, working, PR 101 up at 10:40 -> awaiting-test, 80 min. A tester's seat.up and a note after that must not move it.
rec 10:00 ticket.cut orchestrator WO-A -;       rec 10:10 work.started worker-a WO-A -;  rec 10:40 pr.opened worker-a WO-A 101
rec 11:50 seat.up tester-x WO-A -;              rec 11:55 note worker-a WO-A -
# TD: awaiting-test, 60 min (PR 104). Two tickets in awaiting-test sum to 140, more than any other stage.
rec 11:00 pr.opened worker-d WO-D 104
# TB: PR 102, the test.passed record carries the PR and no ticket -> attributed through pr.opened; awaiting-review, 30 min.
rec 11:20 pr.opened worker-b WO-B 102;          rec 11:30 test.passed tester-x - 102
# TC: awaiting-merge, 120 min: the largest single wait, but alone in its stage (120 < 140).
rec 09:00 pr.opened worker-c WO-C 103;          rec 09:30 test.passed tester-x WO-C 103;  rec 10:00 review.passed reviewer-x WO-C 103
# TR: reworked: pr.opened 10:00, test.failed 10:20, work.started 10:30, pr.opened 11:00 -> awaiting-test again, 60 min since the LATEST pass.
rec 10:00 pr.opened worker-r WO-R 105;          rec 10:20 test.failed tester-x WO-R 105;  rec 10:30 work.started worker-r WO-R -;  rec 11:00 pr.opened worker-r WO-R 105
# TQ: a cut ticket nobody started: 240 minutes queued, the biggest wait there is, and never the bottleneck.
rec 08:00 ticket.cut orchestrator WO-Q -
# TS: started six hours ago, no open PR -> stale, not counted.
rec 06:00 work.started worker-s WO-S -
# TH: PR 35 is in the default HELD_PRS -> held, never ranked.
rec 10:00 pr.opened worker-h WO-H 35
# TZ: verified -> done.
rec 09:00 pr.opened worker-z WO-Z 106;          rec 09:40 merged merger-x WO-Z 106;       rec 10:30 verified merger-x WO-Z 106
# TOLD: its newest record is 20 hours old, outside the 12 hour window.
rec 2031-03-04T16:00 pr.opened worker-o WO-OLD 107
find "$W/state" -type f | LC_ALL=C sort > "$W/before"

run() { NOW=$NOW bash "$SCRIPT" 2>"$W/stderr"; }

echo "-- gh answers: open PRs 101 102 103 104 105 (106 closed, 107 closed)"
printf '101\n102\n103\n104\n105\n35\n' > "$W/gh/open"; rm -f "$W/gh/fail"
OUT=$(run); rc=$?; assert_eq "exit status" "$rc" 0
assert_match "header names the clock and the open PRs" "$OUT" "FLOW TABLE 12:00Z \(UTC\), window 12h"
assert_match "header lists the open PRs" "$OUT" "open PRs: 101,102,103,104,105,35"

echo "-- stage is the newest lifecycle record, minutes are NOW minus it"
r=$(row WO-A); assert_eq "WO-A: awaiting-test (a tester seat.up and a note do not move it)" "$(col "$r" 10)" awaiting-test; assert_eq "WO-A: 80 minutes" "$(col "$r" 11)" 80
assert_eq "WO-A: PR 101" "$(col "$r" 2)" 101; assert_eq "WO-A: cut 10:00" "$(col "$r" 3)" 10:00; assert_eq "WO-A: started 10:10" "$(col "$r" 4)" 10:10
assert_eq "WO-A: PR opened 10:40" "$(col "$r" 5)" 10:40
assert_eq "WO-A: minutes per completed stage" "$(col "$r" 12)" "queued=10 working=30"
r=$(row WO-D); assert_eq "WO-D: awaiting-test" "$(col "$r" 10)" awaiting-test; assert_eq "WO-D: 60 minutes" "$(col "$r" 11)" 60
r=$(row WO-C); assert_eq "WO-C: awaiting-merge" "$(col "$r" 10)" awaiting-merge; assert_eq "WO-C: 120 minutes" "$(col "$r" 11)" 120
assert_eq "WO-C: review column 10:00" "$(col "$r" 7)" 10:00

echo "-- a record with a PR and no ticket is attributed through the PR"
r=$(row WO-B); assert_eq "WO-B: awaiting-review" "$(col "$r" 10)" awaiting-review; assert_eq "WO-B: 30 minutes" "$(col "$r" 11)" 30
assert_eq "WO-B: test column 11:30" "$(col "$r" 6)" 11:30

echo "-- a reworked ticket shows its latest pass, and every completed stage is summed"
r=$(row WO-R); assert_eq "WO-R: awaiting-test again" "$(col "$r" 10)" awaiting-test; assert_eq "WO-R: 60 minutes since the latest pr.opened" "$(col "$r" 11)" 60
assert_eq "WO-R: PR opened column is the latest, 11:00" "$(col "$r" 5)" 11:00
assert_eq "WO-R: stage minutes" "$(col "$r" 12)" "awaiting-test=20 rework=10 working=30"

echo "-- the classes"
live=$(printf '%s\n' "$OUT" | sed -n '/^LIVE/,/^$/p'); stale=$(printf '%s\n' "$OUT" | sed -n '/^NOT COUNTED/,/^$/p')
held=$(printf '%s\n' "$OUT" | sed -n '/^HELD/,/^$/p'); done_=$(printf '%s\n' "$OUT" | sed -n '/^DONE/,/^$/p')
for t in WO-A WO-B WO-C WO-D WO-R; do assert_match "$t is live" "$live" "$t"; done
assert_no_match "WO-S and WO-Q are not live" "$live" "WO-S|WO-Q"
assert_match "WO-S (no open PR, started 6h ago) is NOT COUNTED" "$stale" "WO-S"; assert_match "WO-Q (never started) is NOT COUNTED" "$stale" "WO-Q"
assert_match "WO-H (PR 35) is held" "$held" "WO-H"; assert_no_match "WO-H is not live" "$live" "WO-H"
assert_match "WO-Z is done" "$done_" "WO-Z"
assert_no_match "WO-OLD (20h) is outside the window" "$OUT" "WO-OLD"

echo "-- the bottleneck is the stage with the most summed minutes, not the single longest wait"
assert_match "summary row awaiting-test: 3 waiting (A, D, R), median 60, max 80, total 200" "$OUT" $'awaiting-test\t3\t60\t80\t200\t'
assert_match "awaiting-test is named" "$OUT" "awaiting-test.*BOTTLENECK"
assert_match "BOTTLENECK line lists its items" "$OUT" "^BOTTLENECK: awaiting-test - items: .*WO-A\(80m\)"
assert_match "awaiting-merge has the longest single wait (120) and is not the bottleneck" "$OUT" $'awaiting-merge\t1\t120\t120\t120\t'

echo "-- gh failing: nothing is filtered, the header says so, queued is listed and never ranked"
printf 'x' > "$W/gh/fail"
OUT=$(run); rc=$?; assert_eq "exit status" "$rc" 0
assert_match "header warns" "$OUT" "WARNING gh pr list failed, nothing filtered"
live=$(printf '%s\n' "$OUT" | sed -n '/^LIVE/,/^$/p')
assert_match "WO-S is live now" "$live" "WO-S"; assert_match "WO-Q is live now" "$live" "WO-Q"
assert_match "queued: 1 waiting, 240 minutes, not ranked" "$OUT" $'queued\t1\t240\t240\t240\t.*backlog by design'
assert_no_match "queued is never the BOTTLENECK" "$OUT" "queued.*BOTTLENECK|BOTTLENECK: queued"
assert_match "the bottleneck is still a waiting stage" "$OUT" "^BOTTLENECK: (awaiting-test|awaiting-merge|working) - items:"

echo "-- only queued tickets: no bottleneck"
rm -rf "$RECS"; mkdir -p "$RECS"; n=0; rec 08:00 ticket.cut orchestrator WO-Q -
OUT=$(run); assert_match "none" "$OUT" "^BOTTLENECK: none"

echo "-- writes: only the fixture records are under the state root, the scratch directory is gone, nothing went to TMPDIR"
find "$W/state" -type f | LC_ALL=C sort | grep -v '/records/' > "$W/after" || true
assert_eq "no file outside records/ is left behind" "$(wc -l < "$W/after" | tr -d ' ')" 0
assert_eq "no scratch directory is left under the run tree" "$(find "$W/state/run" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')" 0
assert_no_file "TMPDIR (a directory that does not exist) was never needed or created" "$W/no-such-tmp"

echo "-- the file itself"
assert_eq "no literal home path or cache watch directory in the script" "$(grep -c -e '/home/luna' -e '\.cache/coq-watch' "$SCRIPT" || true)" 0
case_done
