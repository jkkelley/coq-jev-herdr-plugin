#!/usr/bin/env bash
# Catches: a gate record written without its pull request head sha, a record whose code the SPEC-17 status code map does not name, a
# schema code set that drifts from the spec, an accepted code or new kind the writer or the schema refuses (WO-20261013-f298 AC-H1, AC-H2, AC-H3).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up refusals
export COQ_STATE="$W/s"
T=WO-20261013-f298
SHA=9ed0690f3a1c5b7d2e4f60718293a4b5c6d7e8f9
SPEC="${REPO_ROOT:-/repo}/specs/SPEC-17-orchestrator-and-agent-health.xml"
written() { find "$W/s" -name '*.json' 2>/dev/null | wc -l | tr -d ' '; }

echo "-- AC-H1: each gate kind without --sha exits 3 naming the flag and the kind, and writes nothing"
for kc in pr.opened:100 test.passed:201 test.failed:422 review.passed:201 review.changes:422 merged:200 merge.conflict:409 verified:201 rejected:422; do
  kind=${kc%%:*}; code=${kc##*:}
  out=$("$EV" add --code "$code" --seat worker --kind "$kind" --ticket $T --pr 5 2>&1 >/dev/null); rc=$?
  assert_eq "$kind without --sha: exit" "$rc" 3
  assert_match "$kind: the message names --sha and the kind" "$out" "^event: --sha is required on a ${kind//./\\.} record"
done
assert_eq "none of them wrote a record" "$(written)" 0

echo "-- AC-H1: the same kinds with a sha are accepted and validate"
for kc in pr.opened:100 test.passed:201 test.failed:422 review.passed:201 review.changes:422 merged:200 merge.conflict:409 verified:201 rejected:422; do
  kind=${kc%%:*}; code=${kc##*:}
  p=$("$EV" add --code "$code" --seat worker --kind "$kind" --ticket $T --sha "$SHA" --pr 5); assert_eq "$kind with --sha: exit" "$?" 0
  validate "$p"; assert_eq "$kind: the record validates" "$?" 0
done
assert_eq "nine records" "$(written)" 9

echo "-- a malformed sha is still a usage error (exit 2), and kinds outside the gate list need no sha"
rm -rf "$W/s"
"$EV" add --code 201 --seat tester --kind test.passed --ticket $T --sha nothex >/dev/null 2>&1; assert_eq "a non-hex sha on a gate kind: exit" "$?" 2
for kc in note:100 work.started:100 blocked:423 seat.up:100 seat.stalled:500 escalated:423 record.routed:300 request.forwarded:300 ticket.cut:100; do
  "$EV" add --code "${kc##*:}" --seat worker --kind "${kc%%:*}" --ticket $T >/dev/null 2>&1; assert_eq "${kc%%:*} without --sha: exit" "$?" 0
done

echo "-- AC-H2: every code of the map is accepted and validates"
rm -rf "$W/s"
MAP="100 200 201 204 300 400 409 412 422 423 429 500 503"
for c in $MAP; do
  p=$("$EV" add --code "$c" --seat worker --kind note --ticket $T); assert_eq "code $c: exit" "$?" 0
  validate "$p"; assert_eq "code $c: the record validates" "$?" 0
done
assert_eq "thirteen records" "$(written)" 13

echo "-- AC-H2: a code outside the map exits 3 naming the code, and writes nothing"
rm -rf "$W/s"
for c in 101 150 199 202 203 301 401 410 450 424 499 501 502 504 599; do
  out=$("$EV" add --code "$c" --seat worker --kind note --ticket $T 2>&1 >/dev/null); rc=$?
  assert_eq "code $c: exit" "$rc" 3
  assert_match "code $c: the message names it" "$out" "^event: --code $c is not in the SPEC-17 status code map"
done
assert_eq "none of them wrote a record" "$(written)" 0
"$EV" add --code 99 --seat worker --kind note >/dev/null 2>&1; assert_eq "a code under 100 stays a usage error: exit" "$?" 2
"$EV" add --code 600 --seat worker --kind note >/dev/null 2>&1; assert_eq "a code over 599 stays a usage error: exit" "$?" 2
"$EV" add --code abc --seat worker --kind note >/dev/null 2>&1; assert_eq "a code that is not a number stays a usage error: exit" "$?" 2

echo "-- the schema is the map: its code set equals SPEC-17 s-codes, and the schema refuses a record outside it"
spec_codes=$(sed -n '/id="s-codes"/,/<\/section>/p' "$SPEC" | grep -oE '<text>[0-9]{3} [A-Z]+' | grep -oE '[0-9]{3}' | sort -n | tr '\n' ' ')
schema_codes=$(jq -r '.properties.code.enum | sort | map(tostring) | join(" ")' "$R/events/schema/event.schema.json")
assert_eq "SPEC-17 s-codes lists the codes the schema allows" "${spec_codes% }" "$schema_codes"
assert_eq "and those are the thirteen this case accepts" "$schema_codes" "$MAP"
p=$("$EV" add --code 100 --seat worker --kind note --ticket $T)
jq '.code = 450' "$p" > "$W/bad.json"; validate "$W/bad.json"; assert_eq "a record with code 450 fails the schema" "$?" 1
jq '.code = 503' "$p" > "$W/ok.json"; validate "$W/ok.json"; assert_eq "a record with code 503 passes it" "$?" 0

echo "-- the halt, drain and resume kinds"
rm -rf "$W/s"
p=$("$EV" add --code 503 --seat orchestrator --kind line.halted --note "USERHALT"); assert_eq "line.halted 503: exit" "$?" 0; validate "$p"; assert_eq "line.halted validates" "$?" 0
p=$("$EV" add --code 503 --seat orchestrator --kind line.draining --note "drain"); assert_eq "line.draining 503: exit" "$?" 0; validate "$p"; assert_eq "line.draining validates" "$?" 0
p=$("$EV" add --code 100 --seat orchestrator --kind line.resumed --note "USERGO"); assert_eq "line.resumed 100: exit" "$?" 0; validate "$p"; assert_eq "line.resumed validates" "$?" 0
assert_match "the file name says what it is" "$p" "/[0-9]{14}-line-resumed-orchestrator\\.json$"
assert_eq "check passes all three" "$("$EV" check 2>&1)" "events ok: 3 files"
case_done
