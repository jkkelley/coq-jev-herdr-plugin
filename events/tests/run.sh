#!/usr/bin/env bash
# events/tests/run.sh - the state root and event log suite. One command, one verdict: "tests: N passed, M failed".
#   bash events/tests/run.sh               re-execs itself in Podman (localhost/coq-lint:1), --network=none
#   bash events/tests/run.sh --image-only  build the image and stop
#   CASES="01 03" bash events/tests/run.sh a subset, by prefix
# Each tests/cases/*.test.sh builds its own world (lib/world.sh: a copy of bin/state-root.sh, config/state.* and events/bin plus
# events/schema, a private HOME and XDG tree) and runs the real, unmodified scripts. The repository is mounted read-only at /repo,
# so nothing a case does can write back. The lint image is the one `make lint` uses: the suite needs bash, jq and python3
# jsonschema (a record is validated against events/schema/event.schema.json) and nothing else.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="localhost/coq-lint:1"

if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../.." && pwd)"
  command -v podman >/dev/null || { echo "run.sh: podman is required" >&2; exit 4; }
  if ! podman image exists "$IMAGE" 2>/dev/null; then podman build -q -t "$IMAGE" -f "$REPO_ROOT/lint/Containerfile" "$REPO_ROOT/lint" >&2 || exit 4; fi
  [ "${1:-}" != --image-only ] || exit 0
  exec podman run --rm --userns=keep-id --network=none \
    -v "$REPO_ROOT:/repo:ro,Z" \
    -e COQ_TEST_IN_CONTAINER=1 -e HOME=/tmp/home -e REPO_ROOT=/repo -e CASES="${CASES:-}" \
    -w /repo/events/tests "$IMAGE" bash /repo/events/tests/run.sh
fi

# --- inside the container ---
export REPO_ROOT="${REPO_ROOT:-/repo}"
mkdir -p "$HOME"
WORK_ROOT="$(mktemp -d /tmp/coq-XXXX)"; export WORK_ROOT
trap 'rm -rf "$WORK_ROOT"' EXIT
total=0; failed=0; names=()
for case_file in "$HERE"/cases/*.test.sh; do
  base="$(basename "$case_file" .test.sh)"
  if [ -n "${CASES:-}" ]; then hit=0; for c in $CASES; do [[ "$base" == "$c"* ]] && hit=1; done; [ "$hit" = 1 ] || continue; fi
  total=$((total + 1))
  echo "== $base"
  if ( export COQ_CASE_WORK="$WORK_ROOT/$base"; mkdir -p "$COQ_CASE_WORK"; bash "$case_file" ); then echo "-- $base: pass"
  else echo "-- $base: FAIL"; failed=$((failed + 1)); names+=("$base"); fi
done
passed=$((total - failed))
echo "tests: $passed passed, $failed failed${names[*]:+ (${names[*]})}"
[ "$failed" = 0 ]
