#!/usr/bin/env bash
# report/loop/tests/run.sh - the factory board suite. One command, one verdict: "tests: N passed, M failed".
#   bash report/loop/tests/run.sh               re-execs itself in Podman (localhost/coq-lint:1), --network=none
#   bash report/loop/tests/run.sh --image-only  build the image and stop
#   CASES="01 03" bash report/loop/tests/run.sh a subset, by prefix
# Each tests/cases/*.test.sh runs the real, unmodified report/loop/loop.sh against fixtures. The repository is mounted
# read-only at /repo, so nothing a case does can write back; every case writes in its own scratch directory.
# The lint image is the one `make lint` uses (jq, python3 jsonschema, shellcheck): the board is bash and jq and needs no more.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="localhost/coq-lint:1"

if [ "${LOOP_TEST_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
  command -v podman >/dev/null || { echo "run.sh: podman is required" >&2; exit 4; }
  if ! podman image exists "$IMAGE" 2>/dev/null; then podman build -q -t "$IMAGE" -f "$REPO_ROOT/lint/Containerfile" "$REPO_ROOT/lint" >&2 || exit 4; fi
  [ "${1:-}" != --image-only ] || exit 0
  exec podman run --rm --userns=keep-id --network=none \
    -v "$REPO_ROOT:/repo:ro,Z" \
    -e LOOP_TEST_IN_CONTAINER=1 -e REPO_ROOT=/repo -e HOME=/tmp/home -e CASES="${CASES:-}" \
    -w /repo/report/loop/tests "$IMAGE" bash /repo/report/loop/tests/run.sh
fi

# --- inside the container ---
export REPO_ROOT="${REPO_ROOT:-/repo}"
mkdir -p "$HOME"
WORK_ROOT="$(mktemp -d /tmp/loop-XXXX)"; export WORK_ROOT
trap 'rm -rf "$WORK_ROOT"' EXIT
total=0; failed=0; names=()
for case_file in "$HERE"/cases/*.test.sh; do
  base="$(basename "$case_file" .test.sh)"
  if [ -n "${CASES:-}" ]; then hit=0; for c in $CASES; do [[ "$base" == "$c"* ]] && hit=1; done; [ "$hit" = 1 ] || continue; fi
  total=$((total + 1))
  echo "== $base"
  if ( export CASE_WORK="$WORK_ROOT/$base"; mkdir -p "$CASE_WORK"; bash "$case_file" ); then echo "-- $base: pass"
  else echo "-- $base: FAIL"; failed=$((failed + 1)); names+=("$base"); fi
done
passed=$((total - failed))
echo "tests: $passed passed, $failed failed${names[*]:+ (${names[*]})}"
[ "$failed" = 0 ]
