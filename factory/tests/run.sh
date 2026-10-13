#!/usr/bin/env bash
# factory/tests/run.sh - the route runner suite. One command, one verdict: "tests: N passed, M failed".
#   bash factory/tests/run.sh              runs every case in its OWN Podman container (localhost/coq-factory-test:2), --network=none,
#                                          JOBS at a time, through bin/test-cases.sh
#   bash factory/tests/run.sh --case NAME  one case, in one container (what the runner calls for each case)
#   bash factory/tests/run.sh --image-only build the image and stop
#   CASES="01 03" bash factory/tests/run.sh   a subset, by prefix
#   JOBS=1 bash factory/tests/run.sh          containers at once for this run (default min(cores, cap), config/tests.json); 1 is serial
# Each factory/tests/cases/*.test.sh builds its own world (lib/world.sh: a copy of the pieces the runner touches, a stub
# herdr on PATH that logs its argv) and runs the real, unmodified factory/bin/route.sh. The repo is mounted read-only at
# /repo, so nothing a case does can write back. The pattern is herdr/tests/run.sh with the herdr server taken out: the
# runner only ever calls `herdr agent prompt`, so a stub proves exactly what it asks of herdr.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="localhost/coq-factory-test:2"

# One container per case (WO-20261013-0bc0, architect ruling; the reason is the breadcrumb in bin/test-cases.sh).
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../.." && pwd)"
  if ! podman image exists "$IMAGE" 2>/dev/null; then podman build -q -t "$IMAGE" -f "$HERE/Containerfile" "$HERE" >&2 || exit 4; fi
  [ "${1:-}" != --image-only ] || exit 0
  if [ "${1:-}" = --case ]; then
    [ -n "${2:-}" ] || { echo "run.sh: --case needs a case name" >&2; exit 2; }
    exec podman run --rm --userns=keep-id --network=none \
      -v "$REPO_ROOT:/repo:ro,Z" \
      -e COQ_TEST_IN_CONTAINER=1 -e HOME=/tmp/home -e REPO_ROOT=/repo \
      -w /repo/factory/tests "$IMAGE" bash /repo/factory/tests/run.sh --case "$2"
  fi
  bash "$REPO_ROOT/bin/test-cases.sh" --suite factory --case-cmd "bash '$HERE/run.sh' --case \"\$COQ_CASE\"" "$HERE/cases"
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
( export COQ_CASE_WORK="$WORK_ROOT/$2"; mkdir -p "$COQ_CASE_WORK"; exec bash "$case_file" )
exit $?
