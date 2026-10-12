#!/usr/bin/env bash
# Catches: testpane.sh running a command from the pane's own cwd, the main checkout, instead of the seat's worktree - which let
# `make test` and `make lint` check the architect's records branch and void four PRs' results on 2026-10-12 (WO-20261012-3cb1).
# AC-H1: a command sent through testpane.sh prints the seat's worktree from pwd, never the checkout the pane stands in.
# AC-H2: the pane's own shell cwd is unchanged afterwards, so seat.sh --down still leaves the pane alive (WO-20261011-36d7).
# Runs against a real headless herdr and a real shell in the pane; the pwd comes from the command's own output into a file, and
# the pane's cwd from herdr's process-info, so neither proof is the command line testpane.sh sent (case 07 covers that).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up tpwt || exit 1
TP="$REPO/herdr/bin/testpane.sh"; P="$WORLD_TEST_PANE"
WT="$WORLD/seat worktree"; mkdir -p "$WT"
export COQ_TEST_PANE="$P" COQ_WORKTREE="$WT"
pane_cwd() { h pane process-info --pane "$P" | jq -r '.result.process_info.foreground_processes[0].cwd // empty'; }
settle() { local n=0; while [ ! -f "$1" ] && [ "$n" -lt 30 ]; do sleep 0.5; n=$((n + 1)); done; sleep 1; }
home="$(pane_cwd)"
check "the fixture pane has a shell with a cwd of its own" "$([ -n "$home" ] && echo 1 || echo 0)"
check "and it is not the seat's worktree" "$([ "$home" != "$WT" ] && echo 1 || echo 0)"

echo "-- AC-H1: pwd through testpane.sh is the seat's worktree"
"$TP" "$P" "pwd > $WORLD/pwd.out && touch $WORLD/pwd.done" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 0" "$rc" 0
settle "$WORLD/pwd.done"
assert_eq "the command's pwd is the worktree, spaces and all" "$(cat "$WORLD/pwd.out" 2>/dev/null)" "$WT"

echo "-- AC-H2: the pane's own shell has not moved"
assert_eq "the pane's cwd is unchanged" "$(pane_cwd)" "$home"
assert_eq "the pane still has its shell" "$(h pane list | jq -r --arg p "$P" '[.result.panes[] | select(.pane_id == $p)] | length')" 1

echo "-- a failing command still leaves the pane where it was"
"$TP" "$P" "pwd > $WORLD/pwd2.out; touch $WORLD/pwd2.done; false" >/dev/null 2>&1; settle "$WORLD/pwd2.done"
assert_eq "the second command ran in the worktree too" "$(cat "$WORLD/pwd2.out" 2>/dev/null)" "$WT"
assert_eq "the pane's cwd is still unchanged" "$(pane_cwd)" "$home"
case_done
