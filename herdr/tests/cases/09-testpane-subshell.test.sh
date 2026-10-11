#!/usr/bin/env bash
# Catches: testpane.sh leaving the test pane's own shell with its cwd inside a directory the command cd'd into, which is how
# `treehouse return --force` ended the pane's zsh and herdr closed the pane twice (WO-20261011-36d7, AC-H1). Runs against a real
# headless herdr and a real shell in the pane, and reads the pane's cwd from herdr's own process-info, so the proof is the
# pane's cwd and not the command line testpane.sh sent (case 07 covers that). A control first shows the check can see a cwd
# move: a bare `herdr pane run` of the same cd does move the pane.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up tpsub || exit 1
TP="$REPO/herdr/bin/testpane.sh"; P="$WORLD_TEST_PANE"
SLOT="$WORLD/fake-slot"; mkdir -p "$SLOT"
export COQ_TEST_PANE="$P"
pane_cwd() { h pane process-info --pane "$P" | jq -r '.result.process_info.foreground_processes[0].cwd // empty'; }
# settle FILE: wait for the command to have finished (it touches FILE last), then give the shell a moment to print its prompt.
settle() { local n=0; while [ ! -f "$1" ] && [ "$n" -lt 30 ]; do sleep 0.5; n=$((n + 1)); done; sleep 1; }
home="$(pane_cwd)"
check "the fixture pane has a shell with a cwd of its own" "$([ -n "$home" ] && echo 1 || echo 0)"

echo "-- control: a bare pane run of a cd moves the pane's shell"
h pane run "$P" "cd $SLOT && touch $WORLD/control.done" >/dev/null; settle "$WORLD/control.done"
assert_eq "the pane now stands in the slot" "$(pane_cwd)" "$SLOT"
h pane run "$P" "cd $home" >/dev/null; sleep 1
assert_eq "and goes back" "$(pane_cwd)" "$home"

echo "-- AC-H1: testpane.sh <pane> 'cd <slot> && true' leaves the pane where it was"
"$TP" "$P" "cd $SLOT && touch $WORLD/sub.done" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 0" "$rc" 0
settle "$WORLD/sub.done"
check "the command ran" "$([ -f "$WORLD/sub.done" ] && echo 1 || echo 0)"
assert_eq "the pane's cwd is unchanged" "$(pane_cwd)" "$home"

echo "-- a failing command and an exit in it leave the pane where it was too"
"$TP" "$P" "cd $SLOT && false" >/dev/null; sleep 1.5
assert_eq "after a failing command" "$(pane_cwd)" "$home"
"$TP" "$P" "cd $SLOT && touch $WORLD/exit.done && exit 3" >/dev/null; settle "$WORLD/exit.done"
assert_eq "after an exit in the command" "$(pane_cwd)" "$home"
assert_eq "the pane still has its shell" "$(h pane list | jq -r --arg p "$P" '[.result.panes[] | select(.pane_id == $p)] | length')" 1
case_done
