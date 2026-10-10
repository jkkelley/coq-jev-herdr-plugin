#!/usr/bin/env bash
# herdr/tests/run.sh - the seat suite. One command, one verdict: "tests: N passed, M failed".
#   bash herdr/tests/run.sh              re-execs itself in Podman (localhost/coq-herdr-test:1), --network=none
#   bash herdr/tests/run.sh --image-only build the image and stop
#   CASES="01 03" bash herdr/tests/run.sh   a subset, by prefix
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

if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../.." && pwd)"
  HERDR_BIN="${HERDR_BIN_PATH:-$(command -v herdr || true)}"
  [ -x "$HERDR_BIN" ] || { echo "run.sh: no herdr binary (HERDR_BIN_PATH or PATH)" >&2; exit 4; }
  if ! podman image exists "$IMAGE" 2>/dev/null; then podman build -q -t "$IMAGE" -f "$HERE/Containerfile" "$HERE" >&2 || exit 4; fi
  [ "${1:-}" != --image-only ] || exit 0
  exec podman run --rm --userns=keep-id --network=none \
    -v "$REPO_ROOT:/repo:ro,Z" -v "$(readlink -f "$HERDR_BIN"):/usr/local/bin/herdr:ro" \
    -e COQ_TEST_IN_CONTAINER=1 -e HOME=/tmp/home -e REPO_ROOT=/repo -e CASES="${CASES:-}" -e SHELL=/bin/bash \
    -w /repo/herdr/tests "$IMAGE" bash /repo/herdr/tests/run.sh
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
# No scratch session may survive a case (Spike 11 AC-H1). The harness's own HOME holds every session a case made.
left="$(find "$HOME" -path '*/herdr/sessions/t-*' -maxdepth 6 -type d 2>/dev/null | wc -l | tr -d ' ')"
if [ "$left" != 0 ]; then echo "-- teardown: $left scratch session directories left behind"; failed=$((failed + 1)); names+=(teardown); fi
passed=$((total - failed)); [ "$left" = 0 ] || passed=$((passed + 1))
echo "tests: $passed passed, $failed failed${names[*]:+ (${names[*]})}"
[ "$failed" = 0 ]
