#!/usr/bin/env bash
# test-cases.sh - the one case runner every suite's run.sh calls (WO-20261013-0bc0, design 20261013160000-test-speed-design.md
# d-shape 3, architect ruling 2026-10-13: one container per case). One verdict line: "tests: N passed, M failed".
#
#   test-cases.sh [--suite NAME] [--case-cmd CMD] CASE_DIR
#     runs every CASE_DIR/*.test.sh, JOBS at a time, and prints each case's output whole, in name order, as
#         == <case>
#         <the case's stdout and stderr, as it wrote them>
#         -- <case>: pass            or   -- <case>: FAIL
#     --case-cmd CMD  how one case is run: `bash -c CMD` with COQ_CASE=<case name> and COQ_CASE_FILE=<its path> in the
#                     environment. The suites pass a command that runs the case in its OWN podman container (see the breadcrumb).
#                     Without it the case runs in this shell's container as `bash <file>` with COQ_CASE_WORK=$WORK_ROOT/<case>
#                     (WORK_ROOT is exported by the caller, else made here): only for cases that share nothing (the self-test).
#     CASES="01 03"   a subset, by name prefix (as before)
#     JOBS=n          cases at once for this run; wins over the config. Default: min(cores, cap), config/tests.json jobs
#     --suite NAME    the suite's name for the per_suite row; default: the directory above CASE_DIR's tests/ (herdr, factory)
# Exit: 0 every case passed, 1 a case failed, 2 usage, 4 io (no case dir, unreadable config).
#
# BREADCRUMB 2026-10-13 - WO-20261013-0bc0. What broke: herdr/tests/run.sh and factory/tests/run.sh each ran their 27 and 22 cases
#   one after another (a copy of the same 8 line loop in each), so a suite took the sum of its cases (serial baseline of this ticket,
#   2026-10-13 UTC: herdr 18m25s, factory 3m58s), and the owner said suites cannot be the bottleneck (m-20261013154808303-p0c28).
#   Why this fix: cases run JOBS at a time and the runner buffers each case's output and prints it whole in name order, flushed as
#   soon as every earlier case has printed, so the log reads the same at any JOBS. Each case runs in its OWN podman container
#   (architect ruling, 2026-10-13: cases share /proc inside one container, so do not run cases in parallel inside one container).
#   The first version of this ticket ran them in parallel inside the one suite container, and herdr then failed 8 cases it passes
#   serially (19 passed, 8 failed against 26 passed, 1 failed; the suite log of 2026-10-13 18:11 UTC): `seat.sh --audit` walks the
#   container's /proc (herdr/bin/seat.sh line ~390), so 02-audit counted the stub agents of the cases running beside it (7
#   seat.stalled records where 3 are expected) and 05-recover, 13-recover-belt, 14-adopt and 19-supervisor, which audit through
#   recover.sh and supervisor.sh, saw the same; 12-blueprint-panes runs `pkill -f 'server.py --tier dev'` (line 27), which kills the
#   blueprint panes of every other case in the container. One container per case gives each case its own /proc, its own herdr
#   sessions and its own HOME and /tmp. Rejected: a serial list of the cases that touch /proc (a new case that audits would flake
#   and nothing would say why), a PID namespace per case inside the container (unshare needs CAP_SYS_ADMIN, which a
#   rootless --network=none sandbox should not hand out) and fixing 12's pkill alone (the audit still sees its neighbours).
#   Cost: about a second of container start per case; the runner runs on the host and needs podman, jq and nproc there; and the
#   herdr cap in config/tests.json holds because each container runs one herdr server (31.8G herdr death, 2026-10-13).
#   JOBS=1 gives the old serial order to bisect one. Rejected for the scheduler: `xargs -P` (it cannot print in name order while
#   keeping each case's exit status).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${COQ_TESTS_CONFIG:-$HERE/../config/tests.json}"

usage() { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }

suite=""; case_dir=""; case_cmd=""
while [ $# -gt 0 ]; do
  case "$1" in
    --suite) [ $# -ge 2 ] || usage; suite="$2"; shift 2 ;;
    --case-cmd) [ $# -ge 2 ] || usage; case_cmd="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "test-cases.sh: unknown flag $1" >&2; usage ;;
    *) [ -z "$case_dir" ] || usage; case_dir="$1"; shift ;;
  esac
done
[ -n "$case_dir" ] || usage
[ -d "$case_dir" ] || { echo "test-cases.sh: no case directory $case_dir" >&2; exit 4; }
case_dir="$(cd "$case_dir" && pwd)"
[ -n "$suite" ] || suite="$(basename "$(dirname "$(dirname "$case_dir")")")"

# JOBS: the environment wins for one run; else min(cores, cap) from the config.
if [ -n "${JOBS:-}" ]; then
  [[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || { echo "test-cases.sh: JOBS must be a positive integer, got '$JOBS'" >&2; exit 2; }
  jobs="$JOBS"
else
  cap="$(jq -er --arg s "$suite" '.jobs.per_suite[$s] // .jobs.cap | select(type == "number" and . >= 1 and . == floor)' "$CONFIG" 2>/dev/null)" \
    || { echo "test-cases.sh: no jobs cap for suite '$suite' in $CONFIG" >&2; exit 4; }
  cores="$(nproc 2>/dev/null || echo 1)"
  jobs=$(( cores < cap ? cores : cap ))
fi

OWN_WORK=0
if [ -z "$case_cmd" ] && [ -z "${WORK_ROOT:-}" ]; then WORK_ROOT="$(mktemp -d /tmp/coq-XXXX)"; OWN_WORK=1; fi
export WORK_ROOT
OUT="$(mktemp -d /tmp/coq-cases-XXXX)"
cleanup() {
  local pids; pids="$(jobs -p)"
  # shellcheck disable=SC2086  # word splitting of the pid list is the point
  [ -z "$pids" ] || kill $pids 2>/dev/null
  rm -rf "$OUT"
  [ "$OWN_WORK" = 0 ] || rm -rf "$WORK_ROOT"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

names=(); files=()
for case_file in "$case_dir"/*.test.sh; do
  [ -e "$case_file" ] || continue
  base="$(basename "$case_file" .test.sh)"
  if [ -n "${CASES:-}" ]; then hit=0; for c in $CASES; do [[ "$base" == "$c"* ]] && hit=1; done; [ "$hit" = 1 ] || continue; fi
  names+=("$base"); files+=("$case_file")
done
total=${#names[@]}

failed=0; failed_names=(); next=0
# flush: print every case at the head of the name order that has finished, whole.
flush() {
  local n rc
  while [ "$next" -lt "$total" ] && [ -f "$OUT/${names[$next]}.rc" ]; do
    n="${names[$next]}"; rc="$(<"$OUT/$n.rc")"
    echo "== $n"
    cat "$OUT/$n.out"
    if [ "$rc" = 0 ]; then echo "-- $n: pass"; else echo "-- $n: FAIL"; failed=$((failed + 1)); failed_names+=("$n"); fi
    rm -f "$OUT/$n.out" "$OUT/$n.rc"
    next=$((next + 1))
  done
}

# run_case NAME FILE: the case's output in $OUT/NAME.out, then its exit status in $OUT/NAME.rc (written last, so a .rc means done).
run_case() {
  local n="$1" f="$2"
  if [ -n "$case_cmd" ]; then
    COQ_CASE="$n" COQ_CASE_FILE="$f" bash -c "$case_cmd" > "$OUT/$n.out" 2>&1 < /dev/null
  else
    ( export COQ_CASE_WORK="$WORK_ROOT/$n"; mkdir -p "$COQ_CASE_WORK"; exec bash "$f" ) > "$OUT/$n.out" 2>&1 < /dev/null
  fi
  echo $? > "$OUT/$n.rc.tmp"; mv "$OUT/$n.rc.tmp" "$OUT/$n.rc"
}

running=0
for i in "${!names[@]}"; do
  if [ "$running" -ge "$jobs" ]; then wait -n; running=$((running - 1)); flush; fi
  run_case "${names[$i]}" "${files[$i]}" &
  running=$((running + 1))
done
while [ "$running" -gt 0 ]; do wait -n; running=$((running - 1)); flush; done
flush

echo "tests: $((total - failed)) passed, $failed failed${failed_names[*]:+ (${failed_names[*]})}"
[ "$failed" = 0 ]
