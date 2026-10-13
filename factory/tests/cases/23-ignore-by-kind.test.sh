#!/usr/bin/env bash
# Catches: the ignore rows for note and verified matching one code each (note 100 and 300, verified 201 as the owner line), so the
# note 200, 409 and 422 and the verified 200 the orchestrators post fell to route.sh's "no route for" 500 - 25 of 28 route-runner
# failures between 21:30Z and 22:08Z on 2026-10-13 (WO-20261013-9cc9 AC-H1 and AC-H2); an ignore row that also swallows the 500
# that reports a failure (a note 500 and a verified 500 must still wake the monitor); a verified 201 no longer reaching the owner.
#
# BREADCRUMB 2026-10-13 - WO-20261013-9cc9, cause m part 2. What broke: factory/config/routes.json matched note only at 100 and 300
#   and verified only at 201, so note 200, 409 and 422 and verified 200 matched no row and each became a 500 to the monitor, which
#   buried the real failures. Why this fix: the two ignore rows match on kind alone (the matcher in route.sh already treats an
#   absent code as any code), one for note and one for verified. First match wins, so two rows come before them: the existing
#   verified 201 owner line stays first, and a `code_gte 500` wake of the monitor is added per kind - route.sh's own failure report
#   is a note 500, and a bare `kind: note` row would have ignored it and the monitor would never hear of a failing runner.
#   JSON has no comment syntax, so the reason lives here. Rejected: listing the codes seen so far (the next code is the next 500; this
#   ticket exists because the list was one code short) and moving the final `code_gte 500` row up (the ticket's non-goal is no
#   change to other rows). Cost: any note or verified from 101 to 499 is silently ignored, including a typo'd code; the ledger
#   entry is the only trace. This changes cases 08 and 22, whose "note 429 has no row" and "note 299 has no row" lines are no longer true.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261013-bbbb
world_up ignorebykind

echo "-- AC-H1, AC-H2: note 200, 409, 422 and verified 200 route to ignore, with no 500, no receipt and no herdr call"
i1=$(rec note 200 orchestrator $T)
i2=$(rec note 409 orchestrator $T)
i3=$(rec note 422 orchestrator $T)
i4=$(rec verified 200 orchestrator $T)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "no 500 record of any kind" "$(files_code 500 | wc -l | tr -d ' ')" 0
assert_eq "herdr was not called" "$(hcalls)" 0
assert_eq "no receipt: the runner wrote no record.routed" "$(ids_of record.routed | grep -c .)" 0
for id in $i1 $i2 $i3 $i4; do assert_eq "ledger says ignored for $id" "$(cat "$(ledger_of "$id")")" ignored; done

echo "-- a second tick routes none of them again"
before=$(rec_files | wc -l | tr -d ' ')
run_once; assert_eq "record count unchanged" "$(rec_files | wc -l | tr -d ' ')" "$before"

echo "-- verified 201 still notifies the owner, and a 500 of either kind still wakes the monitor"
sleep 1; v1=$(rec verified 201 orchestrator $T); n5=$(rec note 500 route-check $T); v5=$(rec verified 500 orchestrator $T)
run_once
assert_match "verified 201 notified the owner, not ignored" "$(cat "$HLOG")" "^--session stable agent prompt interface record $v1 line done playbook $R/playbooks/interface-agent.md$"
assert_match "the note 500 woke the monitor" "$(cat "$HLOG")" "^--session stable agent prompt monitor record $n5 playbook $R/playbooks/monitor.md$"
assert_match "the verified 500 woke the monitor" "$(cat "$HLOG")" "^--session stable agent prompt monitor record $v5 playbook $R/playbooks/monitor.md$"
assert_eq "no 500 note was written for any of them" "$(notes_code 500 | grep -c 'no route for')" 0
case_done
