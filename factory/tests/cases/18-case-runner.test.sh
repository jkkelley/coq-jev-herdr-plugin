#!/usr/bin/env bash
# Catches: the shared case runner (bin/test-cases.sh, WO-20261013-0bc0) running cases one at a time, running more at once than its cap
# (herdr died at 31.8G on 2026-10-13 with too many servers), printing a case's output split or out of name order, or giving a different
# verdict at JOBS=1 than at the default. Every case below is a throwaway script in a scratch directory; the runner under test is the
# repository's own, with a config of this case's making (COQ_TESTS_CONFIG), so the real caps in config/tests.json are not what is proved.
set -uo pipefail
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"
RUNNER="${REPO_ROOT:-/repo}/bin/test-cases.sh"
W="${COQ_CASE_WORK:-$(mktemp -d)}"; mkdir -p "$W"
cores="$(nproc 2>/dev/null || echo 1)"

# mkcase DIR NAME BODY: a case script that runs BODY.
mkcase() { mkdir -p "$1"; printf '#!/usr/bin/env bash\n%s\n' "$3" > "$1/$2.test.sh"; }
# run_cases CONFIG ARGS...: the runner with no JOBS inherited from the suite that is running this case; stdout in $OUT, status in $RC.
run_cases() { local cfg="$1"; shift; OUT="$(env -u JOBS COQ_TESTS_CONFIG="$cfg" bash "$RUNNER" "$@" 2>"$W/stderr")"; RC=$?; }
# cfg CAP [PER_SUITE_JSON]: writes a tests.json with that cap and those rows; prints its path.
cfg() { local per="${2:-}"; [ -n "$per" ] || per='{}'; jq -n --argjson cap "$1" --argjson per "$per" '{schema_version:"1.0.0", jobs:{cap:$cap, per_suite:$per}}' > "$W/tests.json"; echo "$W/tests.json"; }

echo "-- output is whole and in name order even when a later case finishes first"
D="$W/order"; export FLAG="$W/b-done"
mkcase "$D" 01-a 'echo "a: first"; for i in $(seq 100); do [ -f "$FLAG" ] && break; sleep 0.1; done; [ -f "$FLAG" ] || { echo "a: 02-b never finished while 01-a waited"; exit 1; }; echo "a: after b"'
mkcase "$D" 02-b 'echo "b: only"; touch "$FLAG"'
run_cases "$(cfg 2)" --suite alpha "$D"
assert_eq "exit 0 (01-a can only pass if 02-b ran while it waited, so the two ran together)" "$RC" 0
want=$'== 01-a\na: first\na: after b\n-- 01-a: pass\n== 02-b\nb: only\n-- 02-b: pass\ntests: 2 passed, 0 failed'
assert_eq "01-a prints first, whole, although 02-b finished first" "$OUT" "$want"
unset FLAG

echo "-- never more cases at once than the cap, and the cap is min(cores, config)"
D="$W/cap"; export RUNDIR="$W/running"; mkdir -p "$RUNDIR"
body='touch "$RUNDIR/$(basename "$0")"; n=$(ls "$RUNDIR" | wc -l); echo "$n" >> "$RUNDIR.max"; sleep 0.4; rm -f "$RUNDIR/$(basename "$0")"'
for n in 01 02 03 04 05 06 07 08; do mkcase "$D" "$n-c" "$body"; done
peak() { sort -n "$RUNDIR.max" | tail -n 1; rm -f "$RUNDIR.max"; }
run_cases "$(cfg 3)" --suite alpha "$D"; got="$(peak)"; want=$(( cores < 3 ? cores : 3 ))
assert_eq "cap 3: exit 0" "$RC" 0
assert_eq "cap 3: the peak is min(cores, 3), so no more than the cap and as many as the host allows" "$got" "$want"
run_cases "$(cfg 3 '{"alpha":1}')" --suite alpha "$D"; got="$(peak)"
assert_eq "a per_suite row for the suite beats the cap: one at a time" "$got" 1
run_cases "$(cfg 3 '{"beta":1}')" --suite alpha "$D"; got="$(peak)"
assert_eq "a row for another suite changes nothing" "$got" "$want"
# run_cases unsets JOBS, so JOBS is passed to the runner directly from here on
OUT="$(JOBS=1 COQ_TESTS_CONFIG="$(cfg 3)" bash "$RUNNER" --suite alpha "$D")"; got="$(peak)"
assert_eq "JOBS=1 in the environment wins over the config: one at a time" "$got" 1
if [ "$cores" -ge 2 ]; then
  OUT="$(JOBS=2 COQ_TESTS_CONFIG="$(cfg 3 '{"alpha":1}')" bash "$RUNNER" --suite alpha "$D")"; got="$(peak)"
  assert_eq "JOBS=2 wins over a per_suite row of 1 too" "$got" 2
else echo "  skip - JOBS=2 needs 2 cores"; fi
OUT="$(JOBS=0 bash "$RUNNER" "$D" 2>&1)"; RC=$?; assert_eq "JOBS=0 is a usage error: exit 2" "$RC" 2
OUT="$(JOBS=abc bash "$RUNNER" "$D" 2>&1)"; RC=$?; assert_eq "JOBS=abc is a usage error: exit 2" "$RC" 2
unset RUNDIR

echo "-- the suite name defaults to the directory above tests/"
mkdir -p "$W/gamma/tests"; D="$W/gamma/tests/cases"; for n in 01 02 03 04; do mkcase "$D" "$n-c" "$body"; done; export RUNDIR="$W/running2"; mkdir -p "$RUNDIR"
run_cases "$(cfg 3 '{"gamma":1}')" "$D"; got="$(peak)"
assert_eq "gamma/tests/cases picks the gamma row: one at a time" "$got" 1
unset RUNDIR

echo "-- a failing case is shown whole, counted, named, and fails the run; a passing neighbour is unaffected"
D="$W/fail"
mkcase "$D" 01-ok 'echo ok'
mkcase "$D" 02-bad 'echo "bad: line 1"; echo "bad: to stderr" >&2; exit 7'
mkcase "$D" 03-ok 'echo ok too'
run_cases "$(cfg 4)" --suite alpha "$D"
assert_eq "exit 1" "$RC" 1
want=$'== 01-ok\nok\n-- 01-ok: pass\n== 02-bad\nbad: line 1\nbad: to stderr\n-- 02-bad: FAIL\n== 03-ok\nok too\n-- 03-ok: pass\ntests: 2 passed, 1 failed (02-bad)'
assert_eq "the log (stdout and stderr of a case together, in name order)" "$OUT" "$want"
serial="$(JOBS=1 COQ_TESTS_CONFIG="$(cfg 4)" bash "$RUNNER" --suite alpha "$D" 2>&1)"
assert_eq "JOBS=1 prints the same log" "$serial" "$OUT"

echo "-- --case-cmd runs each case through the command, with COQ_CASE and COQ_CASE_FILE set, and the log is the same as without it"
D="$W/cmd"; mkcase "$D" 01-a 'echo "never run: the command replaces bash <file>"; exit 9'; mkcase "$D" 02-b 'exit 9'
run_cases "$(cfg 4)" --suite alpha --case-cmd 'echo "ran $COQ_CASE from $(basename "$COQ_CASE_FILE")"; [ "$COQ_CASE" != 02-b ]' "$D"
assert_eq "exit 1: the command's status is the case's" "$RC" 1
want=$'== 01-a\nran 01-a from 01-a.test.sh\n-- 01-a: pass\n== 02-b\nran 02-b from 02-b.test.sh\n-- 02-b: FAIL\ntests: 1 passed, 1 failed (02-b)'
assert_eq "the log, in name order" "$OUT" "$want"

echo "-- CASES keeps only the cases whose name starts with a listed prefix"
D="$W/sub"; mkcase "$D" 01-a 'echo a'; mkcase "$D" 02-b 'echo b'; mkcase "$D" 03-c 'echo c'
OUT="$(CASES="01 03" COQ_TESTS_CONFIG="$(cfg 4)" bash "$RUNNER" --suite alpha "$D")"
assert_eq "01 and 03 only" "$OUT" $'== 01-a\na\n-- 01-a: pass\n== 03-c\nc\n-- 03-c: pass\ntests: 2 passed, 0 failed'
OUT="$(CASES="99" COQ_TESTS_CONFIG="$(cfg 4)" bash "$RUNNER" --suite alpha "$D")"; RC=$?
assert_eq "no case matches: an empty run is a pass, as before" "$OUT" "tests: 0 passed, 0 failed"

echo "-- every case gets its own COQ_CASE_WORK under WORK_ROOT"
D="$W/work"; mkcase "$D" 01-w 'echo "$COQ_CASE_WORK"; test -d "$COQ_CASE_WORK"'; mkcase "$D" 02-w 'echo "$COQ_CASE_WORK"; test -d "$COQ_CASE_WORK"'
OUT="$(WORK_ROOT="$W/wr" COQ_TESTS_CONFIG="$(cfg 4)" bash "$RUNNER" --suite alpha "$D")"
assert_match "01-w" "$OUT" "^$W/wr/01-w\$"
assert_match "02-w" "$OUT" "^$W/wr/02-w\$"

echo "-- refusals: a missing case directory or config is exit 4, a missing argument exit 2"
OUT="$(COQ_TESTS_CONFIG="$(cfg 4)" bash "$RUNNER" --suite alpha "$W/nowhere" 2>&1)"; RC=$?; assert_eq "no such case directory: exit 4" "$RC" 4
OUT="$(env -u JOBS COQ_TESTS_CONFIG="$W/nope.json" bash "$RUNNER" --suite alpha "$W/sub" 2>&1)"; RC=$?; assert_eq "no config: exit 4" "$RC" 4
assert_match "and it names the suite and the file" "$OUT" "no jobs cap for suite 'alpha' in $W/nope.json"
OUT="$(bash "$RUNNER" 2>&1)"; RC=$?; assert_eq "no case directory argument: exit 2" "$RC" 2
OUT="$(bash "$RUNNER" --bogus "$W/sub" 2>&1)"; RC=$?; assert_eq "an unknown flag: exit 2" "$RC" 2

echo "-- the real config names a cap that holds the herdr servers to a few"
cap="$(jq -r '.jobs.per_suite.herdr // .jobs.cap' "${REPO_ROOT:-/repo}/config/tests.json")"
check "herdr's cap is between 1 and 4 (31.8G herdr death, 2026-10-13)" "$([ "$cap" -ge 1 ] && [ "$cap" -le 4 ] && echo 1 || echo 0)"

case_done
