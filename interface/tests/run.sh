#!/usr/bin/env bash
# run.sh - the interface agent's script suite (WO-20261011-e618). Runs in the lint image (bash, jq, python3 + jsonschema) via
# `make -C interface test`, or on any host that has them. Each check prints ok/FAIL; exit 1 if any failed.
#   case 1: a MESSAGE wake becomes one request.forwarded 300 to the orchestrator, once, with a page-key shaped run scrubbed (AC-H2)
#   case 2: an ANSWER wake is forwarded; a STOPPED line and prose forward nothing
#   case 3: a verified 201 becomes one reply line with the ticket id and full title, threaded under the owner's message, once (AC-H3)
#   case 4: a 423 becomes a "needs you" line; a 300 and a record with no ticket are refused; an unknown record is not found
#   case 5: snapshot sitrep renders the 003 entry into the state dir (AC-H4); snapshot board with no board is not found;
#           snapshot --to hangs a reply with the path (and its Windows form under WSL) under the owner's message, and without --to posts none
#   case 6: a break.glass 300 becomes one Grant or Refuse card whose text names the seat and the exact command, with Refuse preselected and the
#           other cards kept; an ANSWER on that card becomes break.glass 200 on Grant and 423 on anything else, once (WO-20261011-4562)
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
f2=$(WSL_DISTRO_NAME=TestDistro "$IF" snapshot sitrep "$REPO/report/sitrep/entries/2026/10/20261011-sitrep-003.json" --to m-100); check "snapshot --to exits 0" "$?" 0
snap=$(jq -sc 'map(select(.from == "claude")) | last' "$STUB_DIR/messages.jsonl")
check "the snapshot reply hangs under the owner's message" "$(jq -r .reply_to <<<"$snap")" m-100
check "and names the snapshot path" "$(jq -r .text <<<"$snap" | grep -cF "snapshot: $f2")" 1
check "and its Windows form under WSL" "$(jq -r .text <<<"$snap" | grep -cF '(Windows: \\wsl.localhost\TestDistro\tmp\')" 1
n=$(jq -s '[.[] | select(.from == "claude")] | length' "$STUB_DIR/messages.jsonl")
"$IF" snapshot sitrep "$REPO/report/sitrep/entries/2026/10/20261011-sitrep-003.json" >/dev/null
check "without --to no reply is posted" "$(jq -s '[.[] | select(.from == "claude")] | length' "$STUB_DIR/messages.jsonl")" "$n"

echo "-- case 6: break glass, the card and the verdict"
SEATG=worker-wo-20261011-e618; ACT='gh pr merge 17 --squash'
printf '%s\n' '{"title":"other","items":[{"id":"q-other","about":"a","decide":"d","options":[{"label":"A","then":"a"}],"rec":0}]}' > "$STUB_DIR/questions.json"
g1=$("$EV" add --code 300 --seat $SEATG --kind break.glass --ticket $TICKET --action "$ACT" --note "the merger cannot merge PR 17")
out=$("$IF" line --record "$g1"); check "line on a break.glass 300 exits 0" "$?" 0
check "it says a card is on the page" "$out" "card on the page: $g1"
Q="$STUB_DIR/questions.json"
check "the card is added and the other card is kept" "$(jq -r '[.items[].id] | join(" ")' "$Q")" "q-other $g1"
check "the card text names the seat and the exact command" "$(jq -r --arg id "$g1" '.items[] | select(.id == $id) | .decide' "$Q")" "Break glass for $SEATG: run exactly $ACT - once"
check "the options are Grant then Refuse" "$(jq -r --arg id "$g1" '.items[] | select(.id == $id) | [.options[].label] | join(" ")' "$Q")" "Grant Refuse"
check "Refuse is the preselected answer" "$(jq -r --arg id "$g1" '.items[] | select(.id == $id) | .rec' "$Q")" 1
check "the card says why" "$(jq -r --arg id "$g1" '.items[] | select(.id == $id) | .about' "$Q" | grep -cF 'the merger cannot merge PR 17')" 1
out=$("$IF" line --record "$g1"); check "a second run says it is already there" "$out" "already on the page: $g1"
check "and adds no second card" "$(jq '.items | length' "$Q")" 2
w=$("$EV" add --code 200 --seat $SEATG --kind break.glass --action "$ACT" --answer 20260101T000000Z-300-zzzzz); "$IF" line --record "$w" 2>/dev/null; check "a break.glass 200 is not a page line (exit 3)" "$?" 3
nofile=$("$EV" add --code 300 --seat $SEATG --kind break.glass --action "$ACT"); rm -f "$Q"; "$IF" line --record "$nofile" >/dev/null
check "with no cards file yet the card still lands" "$(jq -r '.items[0].id' "$Q")" "$nofile"

echo "-- case 6b: the owner's answer becomes the verdict record"
v=$("$IF" forward "ANSWER $g1 - Break glass for $SEATG: run exactly $ACT - once -> Grant"); check "forward exits 0" "$?" 0
vr=$("$EV" list --json | jq -s -c --arg id "$v" '.[] | select(.id == $id)')
check "Grant is break.glass 200" "$(jq -r '"\(.kind) \(.code)"' <<<"$vr")" "break.glass 200"
check "for the seat on the request" "$(jq -r .seat <<<"$vr")" "$SEATG"
check "with the exact command" "$(jq -r .action <<<"$vr")" "$ACT"
check "naming the card as its answer" "$(jq -r .answer <<<"$vr")" "$g1"
check "and the ticket" "$(jq -r .ticket <<<"$vr")" "$TICKET"
check "a second wake returns the same record" "$("$IF" forward "ANSWER $g1 - Break glass for $SEATG: run exactly $ACT - once -> Grant")" "$v"
check "and writes no second verdict" "$("$EV" list --json | jq -s --arg id "$g1" '[.[] | select(.kind == "break.glass" and .answer == $id and .code == 200)] | length')" 1
g2=$("$EV" add --code 300 --seat $SEATG --kind break.glass --action "$ACT")
v2=$("$IF" forward "ANSWER $g2 - Break glass for $SEATG: run exactly $ACT - once -> Refuse | words: not now")
check "Refuse is break.glass 423" "$("$EV" list --json | jq -s -r --arg id "$v2" '.[] | select(.id == $id) | "\(.kind) \(.code)"')" "break.glass 423"
g3=$("$EV" add --code 300 --seat $SEATG --kind break.glass --action "$ACT")
v3=$("$IF" forward "ANSWER $g3 - Break glass for $SEATG: run exactly $ACT - once -> grant it")
check "anything but exactly Grant is a 423" "$("$EV" list --json | jq -s -r --arg id "$v3" '.[] | select(.id == $id) | .code')" 423
before=$(count request.forwarded); "$IF" forward "ANSWER q-other - d -> A" >/dev/null
check "an answer to any other card is still a forwarded request" "$(count request.forwarded)" "$((before + 1))"

[ "$fail" = 0 ] && echo "interface: all ok" || { echo "interface: failures" >&2; exit 1; }
