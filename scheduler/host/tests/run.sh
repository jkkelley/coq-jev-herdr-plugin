#!/usr/bin/env bash
# scheduler/host/tests/run.sh - the host files' suite (SPEC-16.H h-t7). One command, one verdict: "tests: N passed, M failed".
#   bash scheduler/host/tests/run.sh             re-execs itself in Podman (the repository lint image), --network=none;
#                                                the host needs bash and podman only
#   CASES="01 03" bash scheduler/host/tests/run.sh   a subset, by prefix
# The first case is shellcheck over every script under scheduler/host, at the severity make lint uses. Each
# cases/*.test.sh then builds its own world (lib/world.sh: a copy of scheduler/host, a stub scheduler binary and a stub
# podman that log their argv, config files rendered from SPEC-16.G) and runs the real, unmodified wrappers. Nothing real
# runs: no podman, no Go binary, no herdr. The repo is mounted read-only at /repo, so no case can write back.
# The lint image is the one make lint builds (Makefile LINT_IMAGE): debian with bash, jq and shellcheck, which is all the
# wrappers and the suite need; the ticket's test plan pins it by digest.
set -uo pipefail
src=${BASH_SOURCE[0]}; [[ $src == */* ]] || src=./$src   # no dirname: the host side runs on bash and podman alone
HERE="$(cd "${src%/*}" && pwd)"
IMAGE="localhost/coq-lint:1"

if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
  # Host needs: bash and podman, nothing else (rule from the coq architect, record 20261012T201732Z-100-239yt: the tester
  # runs the test-plan command literally on the host). So a missing image is built here the way the root Makefile's images
  # target builds it, not through make, which would also build every tool image and need make on the host.
  if ! podman image exists "$IMAGE" 2>/dev/null; then
    podman build -q -t "$IMAGE" -f "$REPO_ROOT/lint/Containerfile" "$REPO_ROOT/lint" >&2 || exit 4
  fi
  exec podman run --rm --userns=keep-id --network=none \
    -v "$REPO_ROOT:/repo:ro,Z" \
    -e COQ_TEST_IN_CONTAINER=1 -e HOME=/tmp/home -e REPO_ROOT=/repo -e CASES="${CASES:-}" \
    -w /repo/scheduler/host/tests "$IMAGE" bash /repo/scheduler/host/tests/run.sh
fi

# --- inside the container ---
export REPO_ROOT="${REPO_ROOT:-/repo}"
mkdir -p "$HOME"
WORK_ROOT="$(mktemp -d /tmp/coq-host-XXXX)"; export WORK_ROOT
trap 'rm -rf "$WORK_ROOT"' EXIT
total=0; failed=0; names=()
run_case() { # NAME COMMAND...
  total=$((total + 1)); echo "== $1"
  if "${@:2}"; then echo "-- $1: pass"; else echo "-- $1: FAIL"; failed=$((failed + 1)); names+=("$1"); fi
}
selected() { [ -z "${CASES:-}" ] && return 0; local c; for c in $CASES; do [[ "$1" == "$c"* ]] && return 0; done; return 1; }

if selected 00; then
  mapfile -t SH < <(find "$REPO_ROOT/scheduler/host" -name '*.sh' | sort)
  run_case 00-shellcheck shellcheck -S warning -x "${SH[@]}"
fi
for case_file in "$HERE"/cases/*.test.sh; do
  base="$(basename "$case_file" .test.sh)"
  selected "$base" || continue
  run_case "$base" env COQ_CASE_WORK="$WORK_ROOT/$base" bash "$case_file"
done
passed=$((total - failed))
echo "tests: $passed passed, $failed failed${names[*]:+ (${names[*]})}"
[ "$failed" = 0 ]
