#!/usr/bin/env bash
# Catches: recover.sh calling a belt ok while the runner pane is gone or the belt file is stale, repairing in --check, a repair
# that does not leave a fresh belt, a restart that opens a second pane instead of reusing the slot, and no closing record
# (AC-H2 of WO-20261011-6842). The runner is the real factory/bin/route.sh run in its monitors pane; the 60 second stale
# threshold is stale_seconds in runner.json and the belt file is backdated rather than waited out.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up recoverbelt '.bringup_gate=true | .belt.status="${repo}/factory/bin/route.sh status"' || exit 1
world_real_belt
RC="$REPO/herdr/bin/recover.sh"; BU="$REPO/herdr/bin/bringup.sh"; MON="$REPO/herdr/bin/monitors.sh"
BELT="$REPO/factory/state/belt"; STATUS="$REPO/factory/bin/route.sh"
run() { "$RC" "$1" > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"; }
fresh() { for _ in $(seq 1 25); do "$STATUS" status >/dev/null 2>&1 && return 0; sleep 1; done; return 1; }
runner_pane() { "$MON" status | sed -nE 's/^ +2\.2\.2 route runner - runner +\[([^]]+)\] +in use$/\1/p'; }

echo "-- bringup starts the real runner in 2.2.2 and its belt moves"
"$BU" --worktree "$REPO" >/dev/null 2>&1; assert_eq "bringup exits 0" "$?" 0
fresh; assert_eq "the belt is fresh" "$?" 0
pane="$(runner_pane)"; assert_match "the runner pane is in use" "$pane" '^w'

echo "-- --check on a healthy line prints ok belt"
run --check; assert_eq "--check exits 0" "$rc" 0
assert_match "ok belt is in the output" "$out" "^ok belt$"

echo "-- the runner stops and the belt goes stale: --check says FAILED belt and changes nothing"
h pane send-keys "$pane" C-c >/dev/null 2>&1; sleep 2; touch -d '-100 seconds' "$BELT"
before="$(find "$EVENTS" -name '*.json' | wc -l)"
run --check; echo "$out" | sed 's/^/    /'
assert_eq "--check exits 1" "$rc" 1
assert_match "FAILED belt says the belt is stopped" "$out" "^FAILED belt \(belt stopped \(last touched 1[0-9][0-9]s ago"
assert_eq "no event was written" "$(find "$EVENTS" -name '*.json' | wc -l)" "$before"
"$STATUS" status >/dev/null 2>&1; assert_eq "the belt is still stale" "$?" 1

echo "-- --apply restarts the runner in its own pane and reports fixed belt"
notes="$(event_count note 100)"
run --apply; echo "$out" | sed 's/^/    /'
assert_eq "--apply exits 0" "$rc" 0
assert_match "it prints fixed belt" "$out" "^fixed belt \(runner restarted through monitors.sh take runner"
assert_eq "the runner is in the same pane" "$(runner_pane)" "$pane"
"$STATUS" status >/dev/null 2>&1; assert_eq "the belt is fresh again" "$?" 0
assert_eq "one closing note 100 was recorded" "$(( $(event_count note 100) - notes ))" 1
assert_match "the closing note says one repair" "$(jq -rs '[.[] | select(.seat == "recover")] | last | .note' "$EVENTS"/2*/*/*.json)" "1 repaired"
run --check; assert_eq "the next --check exits 0" "$rc" 0

echo "-- the runner pane itself is gone: --check names it, --apply draws the grid and restarts the runner"
h pane close "$pane" >/dev/null 2>&1; sleep 1
run --check; echo "$out" | sed 's/^/    /'
assert_eq "--check exits 1" "$rc" 1
assert_match "FAILED belt says the runner pane is missing" "$out" "^FAILED belt \(runner pane missing"
run --apply; echo "$out" | sed 's/^/    /'
assert_eq "--apply exits 0" "$rc" 0
assert_match "the grid is drawn again" "$out" "^fixed monitors"
assert_match "the belt is fixed" "$out" "^fixed belt \(runner restarted"
fresh; assert_eq "the belt is fresh" "$?" 0
assert_match "the runner is in use again in 2.2.2" "$(runner_pane)" '^w'
run --check; assert_eq "the last --check exits 0" "$rc" 0
case_done
