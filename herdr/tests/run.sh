#!/usr/bin/env bash
# herdr/tests/run.sh - the seat suite. One command, one verdict: "tests: N passed, M failed".
#   bash herdr/tests/run.sh              runs every case in its OWN Podman container (localhost/coq-herdr-test:1), --network=none,
#                                        JOBS at a time, through bin/test-cases.sh
#   bash herdr/tests/run.sh --case NAME  one case, in one container (what the runner calls for each case)
#   bash herdr/tests/run.sh --image-only build the image and stop
#   CASES="01 03" bash herdr/tests/run.sh   a subset, by prefix
#   JOBS=1 bash herdr/tests/run.sh          containers at once for this run (default min(cores, cap), config/tests.json); 1 is serial
# Each herdr/tests/cases/*.test.sh builds its own world (lib/world.sh: a copy of the repo, a private HOME, a stub
# claude on PATH, a headless `herdr --session t-<case> server` with its own XDG dirs) and runs the real, unmodified
# herdr/bin scripts against it. The real repo is mounted read-only at /repo, so nothing a case does can write back.
# Teardown stops and deletes every scratch session (Spike 11 AC-H1: leaves no session behind); the harness asserts it.
#
# BREADCRUMB 2026-10-10 - Spike 11 (SPK-11-herdr-scratch-harness) is answered here rather than in a separate
#   throwaway: herdr 0.9.0 runs headless under a private XDG_CONFIG_HOME (the socket path must stay short: a
#   scratchpad-length HOME failed with "local socket name length exceeds capacity of sun_path"), a stub claude whose
#   OSC title starts with the ✳ glyph is detected idle by the claude manifest's osc_title_idle rule, and `agent start`
#   then returns in about 5 s. Rejected: a herdr stub (bearings-v2 tests/stubs/herdr), which proved the JSON shapes it
#   guessed rather than herdr's; two of its shapes were wrong on the live fleet (its F-28 breadcrumb).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="localhost/coq-herdr-test:1"

# BREADCRUMB 2026-10-13 - WO-20261013-0bc0 (architect ruling: one container per case). What broke: the suite ran every case in one
#   container, one after another (18m25s), and running them side by side in that container failed 8 cases (see the breadcrumb in
#   bin/test-cases.sh): cases share /proc (seat.sh --audit) and pkill. Why this fix: the host-side runner starts one container per
#   case, same image and mounts, so each case has its own /proc, herdr sessions, HOME and /tmp, and JOBS containers run at once. The
#   scratch-session teardown check (Spike 11 AC-H1) now runs at the end of each case's container: with the container gone the
#   suite-wide find could only ever see one case anyway. Cost: about a second of container start per case.
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../.." && pwd)"
  HERDR_BIN="${HERDR_BIN_PATH:-$(command -v herdr || true)}"
  [ -x "$HERDR_BIN" ] || { echo "run.sh: no herdr binary (HERDR_BIN_PATH or PATH)" >&2; exit 4; }
  if ! podman image exists "$IMAGE" 2>/dev/null; then podman build -q -t "$IMAGE" -f "$HERE/Containerfile" "$HERE" >&2 || exit 4; fi
  [ "${1:-}" != --image-only ] || exit 0
  if [ "${1:-}" = --case ]; then
    [ -n "${2:-}" ] || { echo "run.sh: --case needs a case name" >&2; exit 2; }
    exec podman run --rm --userns=keep-id --network=none \
      -v "$REPO_ROOT:/repo:ro,Z" -v "$(readlink -f "$HERDR_BIN"):/usr/local/bin/herdr:ro" \
      -e COQ_TEST_IN_CONTAINER=1 -e HOME=/tmp/home -e REPO_ROOT=/repo -e SHELL=/bin/bash \
      -w /repo/herdr/tests "$IMAGE" bash /repo/herdr/tests/run.sh --case "$2"
  fi
  bash "$REPO_ROOT/bin/test-cases.sh" --suite herdr --case-cmd "bash '$HERE/run.sh' --case \"\$COQ_CASE\"" "$HERE/cases"
  exit $?
fi

# --- inside the container: one case ---
[ "${1:-}" = --case ] && [ -n "${2:-}" ] || { echo "run.sh: in the container it runs one case: --case NAME" >&2; exit 2; }
export REPO_ROOT="${REPO_ROOT:-/repo}"
mkdir -p "$HOME"
WORK_ROOT="$(mktemp -d /tmp/coq-XXXX)"; export WORK_ROOT
trap 'rm -rf "$WORK_ROOT"' EXIT
case_file="$HERE/cases/$2.test.sh"
[ -f "$case_file" ] || { echo "run.sh: no case $2" >&2; exit 2; }
( export COQ_CASE_WORK="$WORK_ROOT/$2"; mkdir -p "$COQ_CASE_WORK"; exec bash "$case_file" ); rc=$?
# No scratch session or server may survive the case (Spike 11 AC-H1). The case's world lives under /tmp/hw-<pid>-<name> (herdr/tests/lib/world.sh)
# and world_down deletes it; a server still alive a few seconds after the case is a leak.
left="$(find "$HOME" -path '*/herdr/sessions/t-*' -maxdepth 6 -type d 2>/dev/null | wc -l | tr -d ' ')"
dirs="$(find /tmp -maxdepth 1 -name 'hw-*' 2>/dev/null | wc -l | tr -d ' ')"
procs=1; for _ in $(seq 20); do procs="$(pgrep -fc 'herdr --session t-' || true)"; [ "${procs:-0}" = 0 ] && break; sleep 0.2; done
if [ "$left" != 0 ] || [ "$dirs" != 0 ] || [ "${procs:-0}" != 0 ]; then
  echo "-- teardown: $left scratch session directories, $dirs scratch worlds and ${procs:-0} herdr servers left behind"; rc=1
fi
exit "$rc"
