#!/usr/bin/env bash
# Catches: the executor wrapper running something other than the built binary's exec subcommand on executor.json, taking
# arguments, leaving the socket's directory missing or open to others, or hiding the binary's exit code behind its own
# (SPEC-16.H h-pane, h-executor).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=../../../../herdr/tests/lib/assert.sh
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"
# shellcheck source-path=SCRIPTDIR source=../lib/world.sh
. "$HERE/../lib/world.sh"
world_up run-exec
RUNX="$SCHED/host/bin/run-exec.sh"

echo "-- it execs dist/scheduler exec --config scheduler/config/executor.json, nothing else"
bash "$RUNX"; assert_eq "exit 0, the binary's" "$?" 0
assert_eq "argv" "$(argv_of "$W/bin.argv")" "$SCHED/dist/scheduler exec --config $SCHED/config/executor.json"
assert_eq "the socket's directory exists" "$(test -d "$XDG_RUNTIME_DIR/coq-scheduler" && echo yes)" yes
assert_eq "and is the owner's alone" "$(stat -c %a "$XDG_RUNTIME_DIR/coq-scheduler")" 700
assert_match "the pane's environment reaches the binary" "$(cat "$W/bin.env")" "^COQ_HERDR_SESSION=scratch$"

echo "-- exec, not a child: the binary's exit code is the pane's"
echo 3 > "$W/bin.exit"; bash "$RUNX"; assert_eq "exit 3 passed through" "$?" 3
rm -f "$W/bin.exit"

echo "-- refusals before the binary runs"
rm -f "$W/bin.argv"
bash "$RUNX" --mode active 2>/dev/null; assert_eq "an argument is usage" "$?" 2
unset XDG_RUNTIME_DIR
err=$(bash "$RUNX" 2>&1); assert_eq "an unset ENV name is validation" "$?" 3
assert_match "naming it" "$err" "ENV:XDG_RUNTIME_DIR is unset"
export XDG_RUNTIME_DIR="$W/run"
mv "$SCHED/config/executor.json" "$W/executor.json"
bash "$RUNX" 2>/dev/null; assert_eq "no config is io" "$?" 4
mv "$W/executor.json" "$SCHED/config/executor.json"; rm "$SCHED/dist/scheduler"
err=$(bash "$RUNX" 2>&1); assert_eq "no binary is io" "$?" 4
assert_match "and says how to build it" "$err" "make -C scheduler build"
assert_eq "the binary never ran" "$(test -e "$W/bin.argv" && echo ran || echo no)" no
case_done
