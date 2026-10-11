#!/usr/bin/env bash
# Catches: testpane.sh running a command in any pane but the one in COQ_TEST_PANE, running one when the seat has no test
# pane at all, taking a missing command, or dropping or splitting the command it was given (WO-20261010-8fa8, AC-H3).
# WO-20261011-36d7 adds: the command reaching herdr inside ( ... ), so a cd in it cannot move the pane's own shell (the real
# pane's cwd is proved in case 09).
# No herdr server: a stub herdr on PATH logs its argv, so the case proves what testpane.sh asks herdr to do and nothing else.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"
REPO="${REPO_ROOT:-/repo}"; TP="$REPO/herdr/bin/testpane.sh"
W="${COQ_CASE_WORK:-/tmp}/testpane"; mkdir -p "$W/bin"; : > "$W/herdr.log"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/herdr.log"\necho "{}"\n' "$W" > "$W/bin/herdr"; chmod +x "$W/bin/herdr"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" COQ_HERDR_SESSION=t-testpane
unset COQ_TEST_PANE
calls() { grep -c ' pane run ' "$W/herdr.log"; }

echo "-- the named pane runs the command, whole, in a subshell"
COQ_TEST_PANE=w9:pT "$TP" w9:pT 'cd /work && make -C herdr test 2>&1 | tail -30' >/dev/null 2>"$W/err"; rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "one pane run was asked of herdr" "$(calls)" 1
assert_match "it went to the named pane with the command in one piece" "$(cat "$W/herdr.log")" "^--session t-testpane pane run w9:pT \( cd /work && make -C herdr test 2>&1 \| tail -30 \)$"

echo "-- AC-H3: any other pane is refused and herdr is never asked"
for other in w9:p1 w9:pTT wD3:pF; do
  COQ_TEST_PANE=w9:pT "$TP" "$other" 'make -C herdr test' >/dev/null 2>"$W/err"; rc=$?
  assert_eq "$other: exit 3" "$rc" 3
  assert_match "$other: the refusal names the pane the brief gave" "$(cat "$W/err")" "refused - $other is not the test pane your brief names \(w9:pT\)"
done
assert_eq "still one pane run in total" "$(calls)" 1

echo "-- a seat with no test pane, and bad usage"
"$TP" w9:pT 'make' >/dev/null 2>"$W/err"; rc=$?
assert_eq "no COQ_TEST_PANE: exit 3" "$rc" 3
assert_match "it says seat.sh exports the variable" "$(cat "$W/err")" "no COQ_TEST_PANE"
COQ_TEST_PANE='' "$TP" '' 'make' >/dev/null 2>&1; assert_eq "an empty pane and an empty COQ_TEST_PANE never match" "$?" 3
COQ_TEST_PANE=w9:pT "$TP" w9:pT >/dev/null 2>&1; assert_eq "a pane with no command: exit 2" "$?" 2
COQ_TEST_PANE=w9:pT "$TP" >/dev/null 2>&1; assert_eq "no arguments: exit 2" "$?" 2
assert_eq "none of those reached herdr" "$(calls)" 1
case_done
