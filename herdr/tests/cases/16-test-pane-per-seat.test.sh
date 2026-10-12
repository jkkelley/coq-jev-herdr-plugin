#!/usr/bin/env bash
# Catches (WO-20261011-f896): two seats brought up back to back sharing one COQ_TEST_PANE (the architect tab's) instead of
# holding two panes, a seat's test pane built outside the seat's own tab, testpane.sh in one seat running in the other seat's
# pane, a test pane whose shell stays in the seat's slot (treehouse return --force would end it), --down leaving a pane of
# the seat's tab behind or touching the other seat's, a rerun that does not put a lost test pane back, and a layout with no
# test slot losing the architect-tab fallback. Runs against a real headless herdr, so the JSON shapes are herdr's own.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up testpane || exit 1
A=WO-20261010-8777; NA=worker-wo-20261010-8777
B=WO-20261010-c274; NB=worker-wo-20261010-c274
C=WO-20261010-8fa8; NC=worker-wo-20261010-8fa8
TP="$REPO/herdr/bin/testpane.sh"
SLOT_A="$WORLD/slot-a"; SLOT_B="$WORLD/slot-b"; mkdir -p "$SLOT_A" "$SLOT_B"
# pane_tab PANE: the tab a pane lives in, empty when herdr has no such pane.
pane_tab() { h pane list | jq -r --arg p "$1" 'first(.result.panes[] | select(.pane_id == $p) | .tab_id) // empty'; }
# pane_cwd PANE: the working directory of the pane's shell, read from /proc (the herdr server runs in this container).
pane_cwd() { local sp; sp="$(h pane process-info --pane "$1" | jq -r '.result.process_info.shell_pid // empty')"; [ -n "$sp" ] && readlink "/proc/$sp/cwd"; }

echo "-- two worker seats up back to back (AC-H1)"
outA="$("$SEAT" --ticket "$A" --role worker --worktree "$SLOT_A")"; rcA=$?
outB="$("$SEAT" --ticket "$B" --role worker --worktree "$SLOT_B")"; rcB=$?
assert_eq "seat A exits 0" "$rcA" 0
assert_eq "seat B exits 0" "$rcB" 0
tabA="$(jq -r .tab <<<"$outA")"; tabB="$(jq -r .tab <<<"$outB")"; tpA="$(jq -r .test_pane <<<"$outA")"; tpB="$(jq -r .test_pane <<<"$outB")"
agA="$(jq -r .agent <<<"$outA")"; agB="$(jq -r .agent <<<"$outB")"
check "the two seats have different tabs" "$([ -n "$tabA" ] && [ "$tabA" != "$tabB" ] && echo 1 || echo 0)"
check "the two seats have different test panes" "$([ -n "$tpA" ] && [ -n "$tpB" ] && [ "$tpA" != "$tpB" ] && echo 1 || echo 0)"
check "neither is the architect tab's pane" "$([ "$tpA" != "$WORLD_TEST_PANE" ] && [ "$tpB" != "$WORLD_TEST_PANE" ] && echo 1 || echo 0)"
assert_eq "A's test pane is a pane of A's own tab" "$(pane_tab "$tpA")" "$tabA"
assert_eq "B's test pane is a pane of B's own tab" "$(pane_tab "$tpB")" "$tabB"
assert_eq "A's test pane carries A's label" "$(h pane list | jq -r --arg p "$tpA" '.result.panes[] | select(.pane_id == $p) | .label')" "test - herdr - $NA"
assert_eq "A's environment line holds A's pane" "$(h pane read "$agA" --source recent-unwrapped --lines 200 | grep -cF "COQ_TEST_PANE=$tpA")" 1
assert_eq "B's environment line holds B's pane" "$(h pane read "$agB" --source recent-unwrapped --lines 200 | grep -cF "COQ_TEST_PANE=$tpB")" 1
assert_eq "the seat record keeps the pane" "$(jq -r .test_pane "$STATE/seats/$NA/seat.json")" "$tpA"
sleep 1
assert_match "A's brief names A's pane" "$(h agent read "$NA" --source recent-unwrapped --lines 200)" "Your test pane is $tpA; run commands only there"
assert_match "B's brief names B's pane" "$(h agent read "$NB" --source recent-unwrapped --lines 200)" "Your test pane is $tpB; run commands only there"

echo "-- the agent keeps at least half of its tab"
# The test pane is split down from the monitor pane, so the agent pane is the whole left column. herdr reports no geometry in
# pane list, so the proof is the shape: the agent shares its tab's row with the monitor and test panes stacked, not with a third column.
assert_eq "three panes in A's tab" "$(h pane list | jq -r --arg t "$tabA" '[.result.panes[] | select(.tab_id == $t)] | length')" 3

echo "-- testpane.sh in one seat refuses the other seat's pane (AC-H2)"
COQ_TEST_PANE="$tpA" "$TP" "$tpB" 'true' >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "A running in B's pane: exit 3" "$rc" 3
assert_match "the refusal is the fence message and names A's pane" "$(cat "$WORLD/err")" "testpane: refused - $tpB is not the test pane your brief names \($tpA\)"
COQ_TEST_PANE="$tpB" "$TP" "$tpA" 'true' >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "B running in A's pane: exit 3" "$rc" 3
COQ_TEST_PANE="$tpA" "$TP" "$WORLD_TEST_PANE" 'true' >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "A running in the architect tab's pane: exit 3" "$rc" 3
COQ_WORKTREE="$SLOT_A" COQ_TEST_PANE="$tpA" "$TP" "$tpA" "echo ran-in-a > $WORLD/ran-a" >/dev/null 2>&1; assert_eq "A running in its own pane: exit 0" "$?" 0
COQ_WORKTREE="$SLOT_B" COQ_TEST_PANE="$tpB" "$TP" "$tpB" "echo ran-in-b > $WORLD/ran-b" >/dev/null 2>&1
for _ in $(seq 1 20); do [ -f "$WORLD/ran-a" ] && [ -f "$WORLD/ran-b" ] && break; sleep 0.5; done
assert_eq "the command ran in A's pane" "$(cat "$WORLD/ran-a" 2>/dev/null)" ran-in-a
assert_eq "and B's ran in B's, at the same time" "$(cat "$WORLD/ran-b" 2>/dev/null)" ran-in-b

echo "-- the test pane's shell is in the main checkout, never in the slot (AC-H3)"
for _ in $(seq 1 20); do [ "$(pane_cwd "$tpA")" = "$REPO" ] && break; sleep 0.5; done
assert_eq "A's test pane shell stands in the checkout that brought the seat up" "$(pane_cwd "$tpA")" "$REPO"
assert_eq "B's test pane shell stands there too" "$(pane_cwd "$tpB")" "$REPO"
check "and not in A's slot" "$([ "$(pane_cwd "$tpA")" != "$SLOT_A" ] && echo 1 || echo 0)"

echo "-- a lost test pane is put back by a rerun"
h pane close "$tpB" >/dev/null 2>&1
diff="$("$SEAT" --check "$NB")"; rc=$?
assert_eq "--check exits 1" "$rc" 1
assert_match "--check names the missing test pane" "$diff" "pane missing: test - herdr - $NB"
outB2="$("$SEAT" --ticket "$B" --role worker --worktree "$SLOT_B" 2>/dev/null)"
tpB2="$(jq -r .test_pane <<<"$outB2")"
assert_eq "the rerun built a test pane in B's tab" "$(pane_tab "$tpB2")" "$tabB"
check "it is not A's" "$([ "$tpB2" != "$tpA" ] && echo 1 || echo 0)"
"$SEAT" --check "$NB" >/dev/null; assert_eq "--check exits 0 after the repair" "$?" 0

echo "-- --down closes the seat's whole tab and only that one (AC-H3)"
"$SEAT" --down "$NA" >/dev/null; assert_eq "--down A exits 0" "$?" 0
assert_eq "no pane of A's tab is left" "$(h pane list | jq -r --arg t "$tabA" '[.result.panes[] | select(.tab_id == $t)] | length')" 0
assert_eq "A's test pane is gone" "$(pane_tab "$tpA")" ""
assert_eq "B's test pane is untouched" "$(pane_tab "$tpB2")" "$tabB"
"$SEAT" --check "$NB" >/dev/null; assert_eq "B is still healthy" "$?" 0
"$SEAT" --down "$NB" >/dev/null; assert_eq "--down B exits 0" "$?" 0
assert_eq "the architect tab's pane is untouched by both downs" "$(pane_tab "$WORLD_TEST_PANE")" "$HERDR_TAB_ID"

echo "-- a layout with no test slot still gets the architect tab's pane (AC-H4)"
notest_layout; role_layout worker seat-nt
outC="$("$SEAT" --ticket "$C" --role worker --worktree "$REPO")"; rc=$?
assert_eq "exits 0" "$rc" 0
assert_eq "COQ_TEST_PANE is the architect tab's labelled pane" "$(jq -r .test_pane <<<"$outC")" "$WORLD_TEST_PANE"
assert_eq "the seat tab holds 2 panes, as before" "$(h pane list | jq -r --arg t "$(jq -r .tab <<<"$outC")" '[.result.panes[] | select(.tab_id == $t)] | length')" 2
assert_eq "its environment line holds the fallback" "$(h pane read "$(jq -r .agent <<<"$outC")" --source recent-unwrapped --lines 200 | grep -cF "COQ_TEST_PANE=$WORLD_TEST_PANE")" 1
"$SEAT" --down "$NC" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- a layout whose split slot does not follow the grid is refused before anything is built"
jq '.panes |= (.[2:] + .[0:2])' "$REPO/herdr/layouts/seat-1x2.json" > "$REPO/herdr/layouts/seat-bad.json"
role_layout worker seat-bad
"$SEAT" --ticket "$A" --role worker --worktree "$SLOT_A" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "refused with exit 3" "$rc" 3
assert_match "the refusal names the rule" "$(cat "$WORLD/err")" "a split slot must follow every grid slot"
case_done
