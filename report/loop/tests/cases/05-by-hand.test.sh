#!/usr/bin/env bash
# 05 - where the work is comes from the routes table, and "by hand" is a PR with no pr.opened record (AC-H2).
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
S=worker-wo-20261011-0002; T=WO-20261011-0002

fresh() { world_init; ticket "$T" in-progress feat/x "${1:-null}" "A ticket with a PR"; panes "$S=wD3:p6"; ev 2026-10-11T14:00:00Z "$S" seat.up 100 "$T" wD3:p6 "up"; ev 2026-10-11T14:01:00Z "$S" note 100 "$T" wD3:p6 "work.started: begins"; }

# AC-H2, first half: a ticket with a pr.opened record shows its work at the tester, the record waiting on a stopped belt.
fresh 12
ev 2026-10-11T14:20:00Z "$S" note 100 "$T" wD3:p6 "pr.opened: PR 12 at abc1234"
t "a ticket with a pr.opened record collects" collect
RESULT_JQ "the work is at the tester" '.lines[0].here == "tester"'
RESULT_JQ "the record rides a stopped belt: it is waiting at the worker station's belt" '.lines[0].waiting == "worker"'
RESULT_JQ "the worker is not marked by hand" '.lines[0].st.worker | has("hand") | not'
RESULT_JQ "the tester station is building: the work is there and no seat is" '.lines[0].st.tester.status == "building" and (.lines[0].st.tester.parts | any(.[0] == "bad" and .[1] == "work is here, no seat up"))'
RESULT_JQ "the worker station shows the record it handed on" '.lines[0].st.worker.parts | any(.[1] == "pr.opened 100 at 14:20Z")'

# The same record written as a real factory kind reads the same.
fresh 12
ev 2026-10-11T14:20:00Z "$S" pr.opened 100 "$T" wD3:p6 "PR 12"
collect
RESULT_JQ "a pr.opened kind and a pr.opened note prefix are one thing" '.lines[0].here == "tester" and .lines[0].waiting == "worker"'

# A running belt carries the record: nothing sits waiting.
belt 3; collect
RESULT_JQ "on a running belt nothing is waiting" '.lines[0].belt == "live" and (.lines[0] | has("waiting") | not) and .lines[0].here == "tester"'

# AC-H2, second half: a PR in the frontmatter and no pr.opened record is by hand.
fresh 13
collect
RESULT_JQ "a PR with no pr.opened record puts the PR at the tester" '.lines[0].here == "tester"'
RESULT_JQ "and marks the worker station by hand" '.lines[0].st.worker.hand == true and (.lines[0].st.worker.parts | any(.[0] == "hand" and .[1] == "PR 13 opened by hand, no pr.opened record"))'
RESULT_JQ "the floor meter and the card both say by hand through the same flag" '[.lines[0].st[] | select(.hand == true)] | length == 1'

# No PR, no pr.opened record: that is a worker still working, never by hand.
fresh null
collect
RESULT_JQ "a ticket with no PR is not by hand" '.lines[0].here == "worker" and (.lines[0].st.worker | has("hand") | not)'

# A kickback: a failed test goes back to the worker; the failed record sits on the belt behind the tester.
fresh 12
ev 2026-10-11T14:20:00Z "$S" note 100 "$T" wD3:p6 "pr.opened: PR 12"
ev 2026-10-11T14:30:00Z tester-wo-20261011-0002 test.failed 422 "$T" wD3:p7 "case 3 failed"
collect
RESULT_JQ "test.failed 422 sends the work back to the worker" '.lines[0].here == "worker" and .lines[0].waiting == "tester"'

# The happy path on: a passing test is at the reviewer; a passing review at the merger.
ev 2026-10-11T14:40:00Z tester-wo-20261011-0002 test.passed 201 "$T" wD3:p7 "green"
collect
RESULT_JQ "test.passed 201 puts the work at the reviewer" '.lines[0].here == "reviewer"'
ev 2026-10-11T14:50:00Z reviewer-wo-20261011-0002 review.passed 201 "$T" wD3:p8 "ok"
collect
RESULT_JQ "review.passed 201 puts the work at the merger" '.lines[0].here == "merger"'
ev 2026-10-11T14:55:00Z merger-wo-20261011-0002 merged 200 "$T" wD3:p9 "squashed"
collect
RESULT_JQ "merged 200 puts the work at the verifier's verify station" '.lines[0].here == "verify"'
done_case
