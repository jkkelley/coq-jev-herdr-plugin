#!/usr/bin/env bash
# Catches: the PR head sha living only in a note, so the merger gate holds on prose (WO-20261011-4db1 AC-H4). event.sh cannot
# write a sha or a pr, or writes a malformed one; a wake line for a row that says with pr not carrying the record's sha and pr;
# a record without them changing the line (case 01 pins the plain line, this pins the extended one); a row that does not say
# with pr picking them up anyway; a malformed sha in a hand-edited record reaching a seat's prompt instead of becoming a 500.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
SHA=9ed0690f3a1c5b7d2e4f60718293a4b5c6d7e8f9
world_up sha
ev() { evo "$@"; }   # evo keeps the ids in order across the host clock stepping back, and passes event.sh exit codes on

echo "-- event.sh writes the sha and the pr, and refuses a malformed one"
# a review.passed is held unless a test.passed names the same head (gate.sh heads_match, WO-20261012-3bb0), so the test comes first
ev --code 201 --seat tester-wo-20261011-aaaa --kind test.passed --ticket $T --sha "$SHA" --pr 18 >/dev/null; sleep 1
id=$(ev --code 201 --seat reviewer-wo-20261011-aaaa --kind review.passed --ticket $T --sha "$SHA" --pr 18)
r=$(rec_json "$id")
assert_eq "the record carries sha and pr as fields" "$(jq -r '[.sha, (.pr | tostring)] | join(" ")' <<<"$r")" "$SHA 18"
id0=$(ev --code 100 --seat worker-wo-20261011-aaaa --kind pr.opened --ticket $T)
assert_eq "a record without them has neither key" "$(rec_json "$id0" | jq -r '[has("sha"), has("pr")] | join(" ")')" "false false"
ev --code 100 --seat worker-wo-20261011-aaaa --kind pr.opened --ticket $T --sha 'not-a-sha' >/dev/null 2>&1; assert_eq "a non-hex sha: exit 2" "$?" 2
ev --code 100 --seat worker-wo-20261011-aaaa --kind pr.opened --ticket $T --sha abc12 >/dev/null 2>&1; assert_eq "a sha under 7 characters: exit 2" "$?" 2
ev --code 100 --seat worker-wo-20261011-aaaa --kind pr.opened --ticket $T --pr 0 >/dev/null 2>&1; assert_eq "pr 0: exit 2" "$?" 2
ev --code 100 --seat worker-wo-20261011-aaaa --kind pr.opened --ticket $T --pr 1x >/dev/null 2>&1; assert_eq "pr 1x: exit 2" "$?" 2

echo "-- AC-H4: the merger wake line carries the PR head sha and the PR from the record"
run_once; assert_eq "exit 0" "$?" 0
assert_match "merger line: id, pr, sha, playbook, in that order" "$(cat "$HLOG")" "^--session stable agent prompt merger record $id pr 18 sha $SHA playbook $R/playbooks/merger.md$"
assert_match "the same row without sha and pr stays the plain line" "$(cat "$HLOG")" "^--session stable agent prompt tester-wo-20261011-aaaa record $id0 playbook $R/playbooks/tester.md$"

echo "-- a row that does not say with pr does not pick the fields up"
sleep 1; idf=$(ev --code 422 --seat tester-wo-20261011-aaaa --kind test.failed --ticket $T --sha "$SHA" --pr 18)
run_once
assert_match "the worker kickback is the plain line" "$(tail -1 "$HLOG")" "^--session stable agent prompt worker-wo-20261011-aaaa record $idf playbook $R/playbooks/worker.md$"

echo "-- a sha only, and a pr only"
sleep 1; ids=$(ev --code 201 --seat tester-wo-20261011-aaaa --kind test.passed --ticket $T --sha abcdef1)
sleep 1; idp=$(ev --code 100 --seat worker-wo-20261011-aaaa --kind pr.opened --ticket $T --pr 7)
run_once
assert_match "sha only" "$(grep "record $ids " "$HLOG")" "record $ids sha abcdef1 playbook $R/playbooks/reviewer.md$"
assert_match "pr only" "$(grep "record $idp " "$HLOG")" "record $idp pr 7 playbook $R/playbooks/tester.md$"

echo "-- a malformed sha in a record on disk is a 500 and nothing is sent"
sleep 1; idb=$(ev --code 100 --seat worker-wo-20261011-aaaa --kind pr.opened --ticket $T --sha "$SHA")
f=$(rec_file "$idb"); jq '.sha = "$(touch pwned)"' "$f" > "$f.t" && mv "$f.t" "$f"
before=$(hcalls); run_once
assert_eq "no herdr call for it" "$(hcalls)" "$before"
assert_match "a 500 names the record and the sha" "$(notes_code 500)" "route failed for pr.opened 100, record $idb: record $idb has a malformed sha"
case_done
