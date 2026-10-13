#!/usr/bin/env bash
# line/tests/run.sh - the line suite. One command, one verdict: "tests: N passed, M failed".
#   bash line/tests/run.sh               re-execs itself in Podman (localhost/coq-herdr-test:1), --network=none
#   bash line/tests/run.sh --image-only  build the image and stop
#   CASES="board-t01 board-t14" bash line/tests/run.sh   a subset, by prefix
# Each line/tests/cases/*.sh builds its own world (lib/world.sh: a scratch state root, a copy of the board config, a fake herdr on PATH)
# and runs the real, unmodified line/bin scripts against it. The repository is mounted read-only at /repo, so nothing a case does can
# write back. Same shape as herdr/tests/run.sh.
#
# The image is the seat suite's (herdr/tests/Containerfile: bash, jq, git, python3, procps), built from that file when it is missing:
# the line scripts need nothing more, and a second image would be a second pin to keep current (Rule 15). No herdr binary is mounted,
# because the cases use a fake one; the board is files and one prompt line.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="localhost/coq-herdr-test:1"

if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../.." && pwd)"
  if ! podman image exists "$IMAGE" 2>/dev/null; then podman build -q -t "$IMAGE" -f "$REPO_ROOT/herdr/tests/Containerfile" "$REPO_ROOT/herdr/tests" >&2 || exit 4; fi
  [ "${1:-}" != --image-only ] || exit 0
  exec podman run --rm --userns=keep-id --network=none \
    -v "$REPO_ROOT:/repo:ro,Z" \
    -e COQ_TEST_IN_CONTAINER=1 -e HOME=/tmp/home -e REPO_ROOT=/repo -e CASES="${CASES:-}" -e SHELL=/bin/bash \
    -w /repo/line/tests "$IMAGE" bash /repo/line/tests/run.sh
fi

# --- inside the container ---
export REPO_ROOT="${REPO_ROOT:-/repo}"
mkdir -p "$HOME"
WORK_ROOT="$(mktemp -d /tmp/coq-XXXX)"; export WORK_ROOT
trap 'rm -rf "$WORK_ROOT"' EXIT
total=0; failed=0; names=()
for case_file in "$HERE"/cases/*.sh; do
  base="$(basename "$case_file" .sh)"
  if [ -n "${CASES:-}" ]; then hit=0; for c in $CASES; do [[ "$base" == "$c"* ]] && hit=1; done; [ "$hit" = 1 ] || continue; fi
  total=$((total + 1))
  echo "== $base"
  if ( export COQ_CASE_WORK="$WORK_ROOT/$base"; mkdir -p "$COQ_CASE_WORK"; bash "$case_file" ); then echo "-- $base: pass"
  else echo "-- $base: FAIL"; failed=$((failed + 1)); names+=("$base"); fi
done
[ "$total" -gt 0 ] || { echo "tests: no case matched"; exit 2; }
passed=$((total - failed))
echo "tests: $passed passed, $failed failed${names[*]:+ (${names[*]})}"
[ "$failed" = 0 ]
