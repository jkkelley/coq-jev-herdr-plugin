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
# BREADCRUMB 2026-10-13 - WO-20261012-0229 (Roadmap A2). What broke: BELT was $REPO/factory/state/belt, the file route.sh kept in the
#   checkout; route.sh now keeps it at <state>/run/belt, and this world exports COQ_STATE="$STATE", so the `touch -d '-100 seconds'`
#   below aged a file nobody read and "the belt is still stale" saw a fresh belt (got 0, want 1; FAILED belt never said "stopped").
#   Why this fix: the one path, nothing else. The runner, route.sh status and recover.sh are the real ones and are untouched.
#   Rejected: pointing route.sh back at factory/state for this world (a second place for the belt) and a --state flag on every
#   call (the world already exports the root). Cost: this file is outside the ticket's declared files; no open PR touches it, and
#   the change is forced by the ticket, so it rides the same pull request (noted in the ticket's retro).
BELT="$STATE/run/belt"; STATUS="$REPO/factory/bin/route.sh"
run() { "$RC" "$1" > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"; }
# BREADCRUMB 2026-10-13 - WO-20261013-2b64 (test speed, polls part 2). What broke: fresh() polled with `sleep 1` (up to 25 looks), and two
#   more fixed sleeps (2 s after the runner's C-c, 1 s after the pane close) were paid in full on every run. Why this fix: fresh() is
#   wait_until 25 on the same `route.sh status` look, 0.2 s apart; the 2 s becomes a wait for the runner pane to be a bare shell, which
#   is the reason it was there (the runner must have stopped touching the belt before the belt is backdated); the 1 s becomes a wait for
#   the pane to leave `pane list`. Rejected: leaving the belt backdate where it was (a runner that exits late re-touches the file and
#   "the belt is still stale" fails by timing). Cost: none; the asserts are unchanged.
belt_fresh() { "$STATUS" status >/dev/null 2>&1; }
fresh() { wait_until 25 belt_fresh; }
pane_bare() { h pane process-info --pane "$1" | jq -e '.result.process_info | .foreground_process_group_id == .shell_pid and all(.foreground_processes[]?; ((.argv // [.name])[0] | split("/") | last | ltrimstr("-")) | IN("bash", "zsh", "sh"))' >/dev/null; }
pane_gone() { [ "$(h pane list | jq -r --arg p "$1" '[.result.panes[] | select(.pane_id == $p)] | length')" = 0 ]; }
runner_pane() { "$MON" status | sed -nE 's/^ +2\.2\.2 route runner - runner +\[([^]]+)\] +in use$/\1/p'; }

echo "-- bringup starts the real runner in 2.2.2 and its belt moves"
"$BU" --worktree "$REPO" >/dev/null 2>&1; assert_eq "bringup exits 0" "$?" 0
fresh; assert_eq "the belt is fresh" "$?" 0
pane="$(runner_pane)"; assert_match "the runner pane is in use" "$pane" '^w'

echo "-- --check on a healthy line prints ok belt"
run --check; assert_eq "--check exits 0" "$rc" 0
assert_match "ok belt is in the output" "$out" "^ok belt$"

echo "-- the runner stops and the belt goes stale: --check says FAILED belt and changes nothing"
h pane send-keys "$pane" C-c >/dev/null 2>&1; wait_until 10 pane_bare "$pane"; touch -d '-100 seconds' "$BELT"
# BREADCRUMB 2026-10-12 - WO-20261011-ceea. What broke: this count took every file in events/, and the flow watch pane that bringup
#   starts in this same world (seat flow-watch, factory/bin/flow.sh, every 15 seconds) writes its own 500 "stall" note while the
#   belt is stale, which is what it is for. On the branch of WO-20261011-ceea, with the three blueprint servers started by the same
#   bringup, a tick landed inside the window every time (3 of 3, got 17 want 15) and "no event was written" failed; on main the
#   tick fell outside it, so the test passed by timing. Why this fix: the claim is that recover.sh --check writes nothing, so count
#   what recover.sh could write, every record whose seat is not the flow watch. Rejected: sleeping past the tick (still a race) and
#   stopping the flow pane (then the world is not the one that ships). Cost: a record recover.sh wrote under seat flow-watch would
#   go unseen; recover.sh uses its own seat name.
nonflow() { find "$EVENTS" -name '*.json' -print0 | xargs -0 -r jq -r 'select(.seat != "flow-watch") | .id' | wc -l; }
before="$(nonflow)"
run --check; echo "$out" | sed 's/^/    /'
assert_eq "--check exits 1" "$rc" 1
assert_match "FAILED belt says the belt is stopped" "$out" "^FAILED belt \(belt stopped \(last touched 1[0-9][0-9]s ago"
assert_eq "no event was written" "$(nonflow)" "$before"
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
h pane close "$pane" >/dev/null 2>&1; wait_until 10 pane_gone "$pane"
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
