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
export COQ_TEST_PANE="$P" COQ_WORKTREE="$SLOT"
pane_cwd() { h pane process-info --pane "$P" | jq -r '.result.process_info.foreground_processes[0].cwd // empty'; }
# BREADCRUMB 2026-10-13 - WO-20261013-2b64 (test speed, polls part 2). What broke: settle polled for its file with `sleep 0.5` and then
#   always slept a further second "for the prompt", and three more fixed sleeps (1 s, 1 s, 1.5 s) followed a pane run; every call paid
#   all of it whether the shell was back in 50 ms or not. Why this fix: settle waits for the file (wait_until) and then for the pane's
#   foreground to be its own shell again (pane_idle), which is what "the prompt is back" meant; the command that left no file (`&& false`)
#   now touches one, so the wait cannot pass before the command started. pane_idle checks the foreground, not the cwd, so a shell left
#   standing in the slot (the bug under test) is still idle and its wrong cwd is still what the assert reads. Rejected: polling the cwd to
#   equal home after the test pane command (it would hide a transient cwd; the bug is a cwd that stays). The control's `cd back` is the one
#   exception, polled on the cwd, because there the cwd moving is the effect being waited for. Cost: none; the asserts are unchanged.
pane_idle() { h pane process-info --pane "$P" | jq -e '.result.process_info | .foreground_process_group_id == .shell_pid and all(.foreground_processes[]?; ((.argv // [.name])[0] | split("/") | last | ltrimstr("-")) | IN("bash", "zsh", "sh"))' >/dev/null; }
file_exists() { [ -f "$1" ]; }
cwd_is() { [ "$(pane_cwd)" = "$1" ]; }
# settle FILE: wait for the command to have finished (it touches FILE last), then for the shell to be back at its prompt.
settle() { wait_until 15 file_exists "$1"; wait_until 10 pane_idle; }
home="$(pane_cwd)"
check "the fixture pane has a shell with a cwd of its own" "$([ -n "$home" ] && echo 1 || echo 0)"

echo "-- control: a bare pane run of a cd moves the pane's shell"
h pane run "$P" "cd $SLOT && touch $WORLD/control.done" >/dev/null; settle "$WORLD/control.done"
assert_eq "the pane now stands in the slot" "$(pane_cwd)" "$SLOT"
h pane run "$P" "cd $home" >/dev/null; wait_until 10 cwd_is "$home"
assert_eq "and goes back" "$(pane_cwd)" "$home"

echo "-- AC-H1: testpane.sh <pane> 'cd <slot> && true' leaves the pane where it was"
"$TP" "$P" "cd $SLOT && touch $WORLD/sub.done" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 0" "$rc" 0
settle "$WORLD/sub.done"
check "the command ran" "$([ -f "$WORLD/sub.done" ] && echo 1 || echo 0)"
assert_eq "the pane's cwd is unchanged" "$(pane_cwd)" "$home"

echo "-- a failing command and an exit in it leave the pane where it was too"
"$TP" "$P" "cd $SLOT && touch $WORLD/false.done && false" >/dev/null; settle "$WORLD/false.done"
assert_eq "after a failing command" "$(pane_cwd)" "$home"
"$TP" "$P" "cd $SLOT && touch $WORLD/exit.done && exit 3" >/dev/null; settle "$WORLD/exit.done"
assert_eq "after an exit in the command" "$(pane_cwd)" "$home"
assert_eq "the pane still has its shell" "$(h pane list | jq -r --arg p "$P" '[.result.panes[] | select(.pane_id == $p)] | length')" 1
case_done
