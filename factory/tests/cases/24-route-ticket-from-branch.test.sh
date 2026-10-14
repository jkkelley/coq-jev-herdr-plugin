#!/usr/bin/env bash
# Catches: a gate record with a pr and no ticket (test.passed 201 and test.failed 422 for PR 137, records 20261013T213137Z-201-6p9av and
# 20261013T214216Z-422-2tk0m, 2026-10-13) failing as "seat needs a ticket" in route.sh act_primary, so the reviewer or the worker
# was never woken (WO-20261013-9b21 AC-H1); a PR that names two tickets not using the first; a record that already has a ticket
# being re-read from the PR (AC-H2); a failing gh turning into anything but the old "needs a ticket" 500.
#
# gh is a stub on PATH (the suite runs --network=none): $W/gh.<pr> holds the JSON `gh pr view <pr> --json headRefName,title` prints,
# a missing file exits 1, and every call is appended to $W/gh.log.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up ticketfrombranch
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/gh.log"\n[ "$1 $2" = "pr view" ] && [ -f "%s/gh.$3" ] || exit 1\ncat "%s/gh.$3"\n' "$W" "$W" "$W" > "$W/bin/gh"; chmod +x "$W/bin/gh"
: > "$W/gh.log"
seat_calls() { grep -c -e "$1" "$W/seat.log" | tr -d ' '; }

echo '{"headRefName":"feat/something-else","title":"WO-20261013-249e and WO-20261013-7000 - cause w and cause x (#137)"}' > "$W/gh.137"
echo '{"headRefName":"feat/WO-20261013-5555-the-branch-names-it","title":"WO-20261013-6666 - the title names another"}' > "$W/gh.138"
echo '{"headRefName":"feat/no-id-here","title":"a title with no id"}' > "$W/gh.139"

echo "-- AC-H1: a test.passed 201 with pr 137 and no ticket seats the reviewer for the PR's first ticket"
id=$(REC_PR=137 rec test.passed 201 tester-wo-20261013-249e)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "one gh call, for that pr" "$(cat "$W/gh.log")" "pr view 137 --json headRefName,title"
assert_eq "seat.sh --ticket is the first ticket, not the second" "$(grep -e '--role reviewer' "$W/seat.log")" "--ticket WO-20261013-249e --role reviewer"
assert_eq "and it took the tester of that ticket down" "$(seat_calls "--down tester-wo-20261013-249e")" 1
assert_match "the prompt went to that ticket's reviewer" "$(tail -1 "$HLOG")" "^--session stable agent prompt reviewer-wo-20261013-249e record $id pr 137 playbook"
rid=$(ids_of record.routed | tail -1)
assert_eq "the receipt carries the derived ticket" "$(rec_json "$rid" | jq -r .ticket)" WO-20261013-249e
assert_eq "no 500" "$(files_code 500 | wc -l | tr -d ' ')" 0

echo "-- the head branch is read before the title"
sleep 1; REC_PR=138 rec test.passed 201 tester-wo-20261013-5555 >/dev/null; run_once
assert_eq "the branch ticket was seated" "$(seat_calls "--ticket WO-20261013-5555 --role reviewer")" 1
assert_eq "not the title's" "$(seat_calls "--ticket WO-20261013-6666 ")" 0

echo "-- a test.failed 422 with pr 137 and no ticket wakes the worker of the first ticket"
sleep 1; id2=$(REC_PR=137 rec test.failed 422 tester-wo-20261013-249e "" 1)
run_once
assert_match "the worker of that ticket was woken" "$(tail -1 "$HLOG")" "agent prompt worker-wo-20261013-249e record $id2 "

echo "-- AC-H2: a record that has a ticket is unchanged: no gh call, its own ticket"
: > "$W/gh.log"; sleep 1; REC_PR=137 rec test.passed 201 tester-wo-20261013-aaaa WO-20261013-aaaa >/dev/null; run_once
assert_eq "no gh call" "$(wc -l < "$W/gh.log" | tr -d ' ')" 0
assert_eq "seated for its own ticket" "$(seat_calls "--ticket WO-20261013-aaaa --role reviewer")" 1

echo "-- a PR with no ticket in its branch or title, and a PR gh cannot show, keep today's answer: the 500 that says a seat needs a ticket"
sleep 1; id3=$(REC_PR=139 rec pr.opened 100 worker-wo-20261013-bbbb)
sleep 1; id4=$(REC_PR=140 rec pr.opened 100 worker-wo-20261013-bbbb)
before=$(seat_calls "--role tester"); run_once
assert_eq "seat.sh was not called for either" "$(seat_calls "--role tester")" "$before"
for i in $id3 $id4; do n=$(files_code 500 | xargs -r grep -l -- "$i" | head -1)
  assert_match "the 500 for $i says why" "$(jq -r .note "$n")" "route failed for pr.opened 100, record $i: seat needs a ticket"; done
case_done
