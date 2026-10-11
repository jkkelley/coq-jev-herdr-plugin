#!/usr/bin/env bash
# run.sh - the interface agent's script suite (WO-20261011-e618). Runs in the lint image (bash, jq, python3 + jsonschema) via
# `make -C interface test`, or on any host that has them. Each check prints ok/FAIL; exit 1 if any failed.
#   case 1: a MESSAGE wake becomes one request.forwarded 300 to the orchestrator, once, with a page-key shaped run scrubbed (AC-H2)
#   case 2: an ANSWER wake is forwarded; a STOPPED line and prose forward nothing
#   case 3: a verified 201 becomes one reply line with the ticket id and full title, threaded under the owner's message, once (AC-H3)
#   case 4: a 423 becomes a "needs you" line; a 300 and a record with no ticket are refused; an unknown record is not found
#   case 5: snapshot sitrep renders the 003 entry into the state dir (AC-H4); snapshot board with no board is not found
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$HERE/../.."
IF="$REPO/interface/bin/interface.sh"; EV="$REPO/events/bin/event.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export COQ_EVENTS_ROOT="$T/events" COQ_STATE="$T/state" COQ_SEAT=interface BEARINGS="$HERE/bearings-stub.sh" STUB_DIR="$T/page"
mkdir -p "$STUB_DIR" "$COQ_EVENTS_ROOT"   # a real events root always exists; event.sh list runs find on it before the first add
fail=0
ok() { printf '  ok   - %s\n' "$1"; }
bad() { printf '  FAIL - %s (got %s)\n' "$1" "${2:-?}"; fail=1; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "'$2' wanted '$3'"; fi; }
count() { "$EV" list --json | jq -s --arg k "$1" '[.[] | select(.kind == $k)] | length'; }
TICKET=WO-20261011-e618
TITLE="Interface agent seat owns the bearings page: owner requests become records and the done line comes from it"
KEY=0123456789abcdef0123456789abcdef

echo "-- case 1: a MESSAGE wake becomes one request.forwarded 300"
printf '%s\n' '{"id":"m-100","from":"you","text":"please add a retry","at":"2026-10-11T00:00:00Z"}' > "$STUB_DIR/messages.jsonl"
id=$("$IF" forward "MESSAGE m-100 - please add a retry to the board, key $KEY | files: /tmp/x"); check "forward exits 0" "$?" 0
rec=$("$EV" list --json | jq -s -c --arg id "$id" '.[] | select(.id == $id)')
check "kind and code" "$(jq -r '"\(.kind) \(.code)"' <<<"$rec")" "request.forwarded 300"
check "addressed to the orchestrator" "$(jq -r .to <<<"$rec")" orchestrator
check "written by the interface seat" "$(jq -r .seat <<<"$rec")" interface
check "the note leads with the message id" "$(jq -r .note <<<"$rec" | cut -c1-8)" "m-100: p"
check "a page-key shaped run is scrubbed" "$(jq -r .note <<<"$rec" | grep -c "$KEY")" 0
check "the files suffix is not in the note" "$(jq -r .note <<<"$rec" | grep -c 'files:')" 0
id2=$("$IF" forward "MESSAGE m-100 - please add a retry to the board, key $KEY | files: /tmp/x")
check "a second wake for the same message returns the same record" "$id2" "$id"
check "and writes no second record" "$(count request.forwarded)" 1

echo "-- case 2: an ANSWER is forwarded; STOPPED and prose are not"
"$IF" forward "ANSWER q12b - Path on this machine -> Option 2 | words: it is on D:" >/dev/null
check "two requests now" "$(count request.forwarded)" 2
check "the answer note says answer" "$("$EV" list --json | jq -s -r '.[] | select(.note | startswith("q12b:")) | .note' | cut -c1-12)" "q12b: answer"
"$IF" forward "STOPPED stopped at 2026-10-11T00:00:00Z - restart" >/dev/null; check "STOPPED exits 0" "$?" 0
"$IF" forward "hello there" >/dev/null
check "nothing else was forwarded" "$(count request.forwarded)" 2

echo "-- case 3: a verified 201 is one line under the owner's message"
v=$("$EV" add --code 201 --seat tester-wo-20261011-e618 --kind verified --ticket $TICKET --note "PR 17 head abc1234, make test green")
"$IF" line --record "$v" >/dev/null; check "line exits 0" "$?" 0
reply=$(jq -sc 'map(select(.from == "claude")) | last' "$STUB_DIR/messages.jsonl")
check "threaded under the owner's message" "$(jq -r .reply_to <<<"$reply")" m-100
check "names the ticket id and its full title" "$(jq -r .text <<<"$reply" | grep -cF "$TICKET - $TITLE")" 1
check "says verified 201 and carries the record id" "$(jq -r .text <<<"$reply" | grep -cF "verified 201: PR 17 head abc1234, make test green ($v)")" 1
out=$("$IF" line --record "$v"); check "a second run says it is already there" "$out" "already on the page: $v"
check "one claude line, not two" "$(jq -s '[.[] | select(.from == "claude")] | length' "$STUB_DIR/messages.jsonl")" 1

echo "-- case 4: 423, wrong code, no ticket, unknown record"
b=$("$EV" add --code 423 --seat worker-wo-20261011-e618 --kind blocked --ticket $TICKET --note "needs the role file from the architect")
"$IF" line --record "$b" >/dev/null; check "423 exits 0" "$?" 0
check "423 reads as needs you" "$(jq -sr 'map(select(.from == "claude")) | last | .text' "$STUB_DIR/messages.jsonl" | grep -cF 'needs you (423): needs the role file')" 1
n=$("$EV" add --code 300 --seat interface --kind request.forwarded --note "m-9: x"); "$IF" line --record "$n" 2>/dev/null; check "a 300 is refused with exit 3" "$?" 3
w=$("$EV" add --code 201 --seat tester-wo-20261011-e618 --kind verified --note "no ticket"); "$IF" line --record "$w" 2>/dev/null; check "a record with no ticket is refused with exit 3" "$?" 3
"$IF" line --record 20260101T000000Z-201-zzzzz 2>/dev/null; check "an unknown record exits 6" "$?" 6
x=$("$EV" add --code 201 --seat tester-wo-20261011-e618 --kind verified --ticket WO-20990101-ffff --note "no such ticket"); "$IF" line --record "$x" 2>/dev/null; check "a ticket with no file exits 6" "$?" 6

echo "-- case 5: snapshots"
f=$("$IF" snapshot sitrep "$REPO/report/sitrep/entries/2026/10/20261011-sitrep-003.json"); check "sitrep exits 0" "$?" 0
check "the page is under the state dir" "$(dirname "$f")" "$COQ_STATE/interface/snapshots"
check "and holds the SITREP title" "$(grep -c '<title>Qud Factory SITREP 003</title>' "$f")" 1
"$IF" snapshot board 2>/dev/null; check "no board yet exits 6" "$?" 6

[ "$fail" = 0 ] && echo "interface: all ok" || { echo "interface: failures" >&2; exit 1; }
