#!/usr/bin/env bash
# interface.sh - what the interface-agent seat runs, so a wake becomes a record and a record becomes a page line without prose
# (WO-20261011-e618, DEC-interface-agent-owns-bearings, DEC-system-runs-the-loop).
#   interface.sh forward  "<wake line>" [--tier stable]      MESSAGE m-.. - text | ANSWER id - decide -> choice: post request.forwarded 300 to the orchestrator
#                                                             (an ANSWER to a break glass card posts break.glass 200 on Grant, 423 on anything else)
#   interface.sh line     --record ID [--tier stable] [--to m-..]   a verified 201 or an owner-needed 423 becomes one line on the page
#                                                             (a break.glass 300 request becomes a Grant or Refuse decision card on the page)
#   interface.sh snapshot sitrep ENTRY.json | board [--tier stable] [--to m-..]   render a SITREP (report/sitrep/sitrep.sh) or copy the board (report/loop/out), print the file; --to also replies under that owner message with the path
# Env: COQ_SEAT (record seat, default interface), COQ_EVENTS_ROOT (event.sh), BEARINGS (bearings.sh path, default tools/bearings/scripts),
#      COQ_STATE (default ~/.local/state/coq; snapshots land in <state>/interface/snapshots, never in git).
# Exit: 0 ok (or already done), 2 usage, 3 refused, 4 io, 6 not found.
#
# BREADCRUMB 2026-10-11 - WO-20261011-e618. Why a script and not the agent's judgement: the owner's law (graph
#   DEC-system-runs-the-loop) is that the notification path is deterministic; the seat is read only and its prompt is one line
#   per wake, so the work an agent does is "run the verb for the line I was woken with". forward and line are idempotent: a
#   re-woken seat (compaction, a retried wake) posts nothing twice. Page lines are bearings replies threaded under the owner
#   message that caused them because bearings has no unsolicited-line API and bearings code changes are out of scope for this
#   ticket (B0 only). Rejected: a new bearings route for lines (out of scope, and the backlog item for after the north star) and
#   the agent composing the record by hand (the 60 second budget of AC-H2 and the format both belong to a script).
#   Cost: a line needs an owner message to hang under; with none on the page, line refuses (exit 6) instead of inventing one.
#   The owner's text goes into a committed record (public repo, AGENTS.md no PII), so it is cut to 160 characters and any 32
#   hex run (the shape of a page key) is replaced before it is written.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
EVENT=$REPO/events/bin/event.sh; BEARINGS=${BEARINGS:-$REPO/tools/bearings/scripts/bearings.sh}
SEAT=${COQ_SEAT:-interface}; STATE=${COQ_STATE:-$HOME/.local/state/coq}
die() { local c=$1; shift; printf 'interface: %s\n' "$*" >&2; exit "$c"; }
usage() { sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
command -v jq >/dev/null || die 4 "jq is required"
verb=${1:-}; shift || true
tier=stable; pos=(); rec=""; to=""
while [ $# -gt 0 ]; do case $1 in
  --tier) tier=${2:?--tier needs a tier}; shift 2;; --record) rec=${2:?--record needs an id}; shift 2;; --to) to=${2:?--to needs a message id}; shift 2;;
  -h|--help) usage;; --*) die 2 "unknown flag $1";; *) pos+=("$1"); shift;; esac; done

# scrub TEXT: one line, no page-key shaped run, at most 160 characters.
scrub() { printf '%s' "$1" | tr '\n\t' '  ' | sed -E 's/[0-9a-f]{32}/[redacted]/g' | cut -c1-160; }
# events_json: every record as one JSON array.
events_json() { "$EVENT" list --json | jq -s '.'; }
# title_of TICKET: the full title from the ticket file (active or archived), empty when there is none.
title_of() {
  local f; f=$(find "$REPO/work-orders" -name "$1-*.md" 2>/dev/null | head -1)
  [ -n "$f" ] || return 0
  awk '/^---$/{c++; next} c==1' "$f" | jq -r '.title // empty'
}
# page_dir: the tier's state directory, from bearings status.
page_dir() { "$BEARINGS" "$tier" status --json 2>/dev/null | jq -r '.dir // empty'; }

# BREADCRUMB 2026-10-11 - WO-20261011-4562, break glass (DEC-break-glass-one-time). What broke: nothing yet; the owner's order is that
#   only the owner authorises a break glass, and the only owner channel is this page. Why it is here: the route table sends a
#   break.glass 300 to this seat as a decision (notify_owner, line decision), and an owner ANSWER wakes it as every answer does, so
#   the card and its verdict are two verbs this script already has, not new ones: `line` writes the card, `forward` turns the
#   answer into break.glass 200 (Grant) or 423. The roles/interface-agent.json allow list therefore needs no change.
#   The card's id is the request record's id, and its text names the seat and the exact command, because herdr/bin/seat.sh checks
#   the answer line the page wrote (id, choice Grant, card text) before it touches anything: the 200 written here is a notice,
#   not the authority. The page preselects `rec`, so rec is Refuse: Grant is never the default. The command is not scrubbed on the
#   card, since seat.sh must find it verbatim in the answer; it is already in the committed 300 record. Cost: `ask` replaces the
#   whole cards file, so this reads the cards already there and writes them back with the new one added.
# glass_card RECORD_JSON: add the Grant or Refuse card for a break.glass 300 request, once.
glass_card() {
  local j=$1 seat action why dir q base tmp
  seat=$(jq -r .seat <<<"$j"); action=$(jq -r '.action // empty' <<<"$j"); why=$(scrub "$(jq -r '.note // ""' <<<"$j")")
  [ -n "$action" ] || die 3 "record $rec carries no action; nothing to ask the owner"
  dir=$(page_dir); [ -n "$dir" ] || die 4 "bearings status gave no state directory for tier $tier"
  q=$dir/questions.json
  if [ -f "$q" ] && jq -e --arg id "$rec" '(.items // []) | any(.id == $id)' "$q" >/dev/null 2>&1; then echo "already on the page: $rec"; return 0; fi
  base='{"title":"Break glass","items":[]}'; [ ! -f "$q" ] || base=$(cat "$q")
  tmp=$(mktemp "${TMPDIR:-/tmp}/glass-card.XXXXXX")
  jq --arg id "$rec" --arg seat "$seat" --arg action "$action" --arg why "$why" '
    .items = ((.items // []) + [{id: $id, about: ("Break glass for \($seat). \($why)"),
      decide: ("Break glass for \($seat): run exactly \($action) - once"),
      options: [{label: "Grant", then: "The seat runs exactly that one command, once, with bypass permissions; its role settings come back when it finishes or in a few minutes."},
                {label: "Refuse", then: "Nothing changes; the seat stays on its role."}], rec: 1}])' <<<"$base" > "$tmp" || { rm -f "$tmp"; die 4 "could not build the card"; }
  "$BEARINGS" "$tier" ask "$tmp" >/dev/null 2>&1; local rc=$?; rm -f "$tmp"
  [ "$rc" = 0 ] || die 4 "bearings ask failed for the card $rec"
  echo "card on the page: $rec"
}

# link FILE: print the snapshot's path; with --to, also reply under that owner message so the page carries it.
# BREADCRUMB 2026-10-11 - WO-20261011-e618, AC-H4 "links it on the page". What broke: nothing, a design limit found reading
#   tools/bearings/scripts/reply.mjs and server.mjs: a reply is text only and the only file route is the owner's own upload
#   (POST /file), and bearings code changes are out of scope for this ticket. Why this fix: the reply names the snapshot's
#   path, and under WSL the Windows form of it (\\wsl.localhost\<distro>\...), which the owner's browser or Explorer opens
#   directly. Rejected: serving the file from the page (a bearings route, backlog until the north star) and a file:// URL
#   (a browser refuses it from an http page). Cost: a path, not a clickable http link, until bearings can carry a file.
link() {
  echo "$1"
  [ -n "$to" ] || return 0
  local text="snapshot: $1"
  [ -z "${WSL_DISTRO_NAME:-}" ] || text="$text  (Windows: \\\\wsl.localhost\\$WSL_DISTRO_NAME${1//\//\\})"
  "$BEARINGS" "$tier" reply --to "$to" "$text" >/dev/null
}

case $verb in
  forward)
    [ ${#pos[@]} -eq 1 ] || usage
    wake=${pos[0]}
    if [[ $wake =~ ^(MESSAGE|ANSWER)\ ([A-Za-z0-9._:-]+)\ -\ (.*)$ ]]; then kind=${BASH_REMATCH[1]}; mid=${BASH_REMATCH[2]}; body=${BASH_REMATCH[3]}
    else echo "interface: not a request, nothing forwarded: ${wake:0:60}"; exit 0; fi
    body=${body%% | files:*}; body=${body%% | words:*}
    # An answer to a break glass card is a verdict on that request, not a new request: Grant is break.glass 200, anything else 423.
    # Once per card: a seat woken twice finds the verdict it already wrote.
    if [ "$kind" = ANSWER ]; then
      greq=$(events_json | jq -c --arg id "$mid" 'map(select(.id == $id and .kind == "break.glass" and .code == 300)) | first // empty')
      if [ -n "$greq" ]; then
        have=$(events_json | jq -r --arg id "$mid" 'map(select(.kind == "break.glass" and .answer == $id and (.code == 200 or .code == 423))) | first | .id // empty')
        if [ -n "$have" ]; then echo "$have"; exit 0; fi
        choice=${body##* -> }; gargs=(--seat "$(jq -r .seat <<<"$greq")" --kind break.glass --action "$(jq -r .action <<<"$greq")" --answer "$mid")
        gt=$(jq -r '.ticket // empty' <<<"$greq"); [ -z "$gt" ] || gargs+=(--ticket "$gt")
        if [ "$choice" = Grant ]; then "$EVENT" add --code 200 "${gargs[@]}" --note "the owner granted it on the page"
        else "$EVENT" add --code 423 "${gargs[@]}" --note "the owner did not grant it: ${choice:0:60}"; fi
        exit 0
      fi
    fi
    # The same message id is forwarded once: a seat woken twice for one message finds its record.
    have=$(events_json | jq -r --arg m "$mid:" 'map(select(.kind == "request.forwarded" and (.note | startswith($m)))) | first | .id // empty')
    if [ -n "$have" ]; then echo "$have"; exit 0; fi
    text=$(scrub "$body"); [ "$kind" = ANSWER ] && text="answer $text"
    "$EVENT" add --code 300 --seat "$SEAT" --kind request.forwarded --to orchestrator --note "$mid: $text" ;;
  line)
    [ -n "$rec" ] || usage
    json=$(events_json | jq -c --arg id "$rec" 'map(select(.id == $id)) | first // empty')
    [ -n "$json" ] || die 6 "no record $rec under the events root"
    code=$(jq -r .code <<<"$json"); kind=$(jq -r .kind <<<"$json"); ticket=$(jq -r '.ticket // empty' <<<"$json"); note=$(jq -r '.note // ""' <<<"$json")
    if [ "$kind" = break.glass ] && [ "$code" = 300 ]; then glass_card "$json"; exit $?; fi
    case "$code:$kind" in
      201:verified|201:test.passed|201:review.passed) lead="verified $code" ;;
      423:*) lead="needs you ($code)" ;;
      *) die 3 "record $rec is $kind $code: only a verified 201 or a 423 for the owner becomes a page line" ;;
    esac
    [ -n "$ticket" ] || die 3 "record $rec names no ticket; a page line names the ticket and its full title"
    title=$(title_of "$ticket"); [ -n "$title" ] || die 6 "no ticket file for $ticket, so there is no full title to name"
    dir=$(page_dir); [ -n "$dir" ] || die 4 "bearings status gave no state directory for tier $tier"
    # Already on the page: the record id is in a reply.
    if [ -f "$dir/messages.jsonl" ] && grep -qF "($rec)" "$dir/messages.jsonl"; then echo "already on the page: $rec"; exit 0; fi
    if [ -z "$to" ]; then
      to=$( [ -f "$dir/messages.jsonl" ] && jq -rs 'map(select(.from != "claude")) | last | .id // empty' "$dir/messages.jsonl" || true)
      [ -n "$to" ] || die 6 "no owner message on the $tier page to hang the line under"
    fi
    line="$ticket - $title - $lead: $(scrub "$note") ($rec)"
    "$BEARINGS" "$tier" reply --to "$to" "${line:0:400}" ;;
  snapshot)
    what=${pos[0]:-}; out=$STATE/interface/snapshots; mkdir -p "$out"; stamp=$(date -u +%Y%m%dT%H%M%SZ)
    case $what in
      sitrep) [ ${#pos[@]} -eq 2 ] || usage
        [ -f "${pos[1]}" ] || die 6 "no SITREP entry ${pos[1]}"
        "$REPO/report/sitrep/sitrep.sh" render "${pos[1]}" --out "$out/$stamp-sitrep.html" >/dev/null; link "$out/$stamp-sitrep.html" ;;
      board) src=$REPO/report/loop/out
        [ -d "$src" ] && f=$(find "$src" -name '*.html' | sort | tail -1) && [ -n "$f" ] || die 6 "no board under $src; report/loop has not landed or has not rendered"
        cp "$f" "$out/$stamp-board.html"; link "$out/$stamp-board.html" ;;
      *) usage ;;
    esac ;;
  *) usage ;;
esac
