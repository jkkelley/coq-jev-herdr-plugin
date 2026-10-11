#!/usr/bin/env bash
# event.sh - the event log. One file per event under events/YYYY/MM/, named
# <UTC>-<code>-<suffix>.json, so N seats write at once with no lock and git never
# conflicts (REQ-event-log). Only important items: code >= 300, seat up/down, a
# gate result, a merge, a compaction. Routine progress is not an event.
#
#   event.sh add --code NNN --seat NAME --kind KIND [--ticket WO-...] [--pane P] [--note "<=240 chars"]
#                [--evidence PATH]... [--observe "path:line:saw:expected"]... [--attempt N] [--json]
#   event.sh list [--since YYYY-MM-DD] [--code NNN] [--seat NAME] [--ticket WO-...] [--json]
#   event.sh check                      every file matches events/schema/event.schema.json; exit 3 names offenders
#   event.sh tail                       newest 10, one line each (what the monitor pane shows)
# Exit codes: 0 ok, 2 usage, 3 validation, 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); SCHEMA=$HERE/../schema/event.schema.json
# BREADCRUMB 2026-10-11 - WO-20261011-23df. What broke: ROOT was always this script's own events/, so a seat running in a
#   leased treehouse slot wrote its record as an untracked file there, and `treehouse return --force` (seat.sh --down) wiped
#   it: tester-wo-20261011-9639's test 201 20261011T151907Z-201-ftoqv on PR 13 is gone. A tester or reviewer cannot commit
#   (its role denies git), so nothing in the slot could have kept it. Why this fix: seat.sh exports COQ_EVENTS_ROOT, the
#   events/ of the checkout that brought the seat up, for every role that cannot run git, so the record lands where the
#   architect's own commits pick it up and no slot return can reach it; the schema still comes from this tree. Rejected:
#   letting those roles run `git add events && git commit` (the deny on git is the fence that keeps a reviewer from touching
#   history) and copying on --down alone (a seat killed before --down still loses the file; seat.sh salvages as a second net).
#   Cost: a record from such a seat is an untracked file on the architect's checkout until the next make step.
ROOT=${COQ_EVENTS_ROOT:-$(cd "$HERE/.." && pwd)}
die() { local c=$1; shift; printf 'event: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
KINDS='seat.up|seat.down|seat.stalled|gate|test|review|merge|deploy|compaction|blocked|escalation|note'
line_of() { jq -r '"\(.at)\t\(.code)\t\(.kind)\t\(.seat)\t\(.ticket // "-")\t\(.note // "")"' "$1"; }
VERB=${1:-}; shift || true
case $VERB in
  add)
    code=""; seat=""; kind=""; ticket=null; pane=null; note=""; attempt=null; ev=(); obs=(); JSON=0
    while [ $# -gt 0 ]; do case $1 in
      --code) code=$2; shift 2;; --seat) seat=$2; shift 2;; --kind) kind=$2; shift 2;; --ticket) ticket=$2; shift 2;; --pane) pane=$2; shift 2;;
      --note) note=$2; shift 2;; --attempt) attempt=$2; shift 2;; --evidence) ev+=("$2"); shift 2;; --observe) obs+=("$2"); shift 2;; --json) JSON=1; shift;; *) die 2 "unknown flag $1";; esac; done
    [[ $code =~ ^[1-5][0-9]{2}$ ]] || die 2 "--code must be 100..599"; [[ $seat =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || die 2 "--seat must match ^[a-z][a-z0-9_-]{0,31}$"
    [[ $kind =~ ^($KINDS)$ ]] || die 2 "--kind must be one of $KINDS"; [ ${#note} -le 240 ] || die 3 "--note over 240 chars"
    [ "$ticket" = null ] || [[ $ticket =~ ^WO-[0-9]{8}-[0-9a-f]{4}$ ]] || die 3 "--ticket must be WO-YYYYMMDD-xxxx"
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ); stamp=$(date -u +%Y%m%dT%H%M%SZ); suf=$(head -c 200 /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | cut -c1-5)
    id="$stamp-$code-$suf"; dir="$ROOT/$(date -u +%Y/%m)"; mkdir -p "$dir"
    evj=$(printf '%s\n' "${ev[@]:-}" | { grep -v '^$' || true; } | jq -R . | jq -s .)
    obj=$(printf '%s\n' "${obs[@]:-}" | { grep -v '^$' || true; } | jq -R 'split(":") | {path:.[0], line:(.[1]|tonumber? // 0), saw:.[2], expected:.[3]}' | jq -s .)
    tq() { if [ "$1" = null ]; then echo null; else jq -n --arg v "$1" '$v'; fi; }
    jq -n --arg id "$id" --arg at "$now" --argjson code "$code" --arg seat "$seat" --arg kind "$kind" --argjson ticket "$(tq "$ticket")" --argjson pane "$(tq "$pane")" --arg note "$note" --argjson evidence "$evj" --argjson observations "$obj" --argjson attempt "$attempt" \
      '{schema_version:"1.0.0", id:$id, at:$at, code:$code, seat:$seat, kind:$kind, ticket:$ticket, pane:$pane, note:$note, evidence:$evidence, observations:$observations} + (if $attempt==null then {} else {attempt:$attempt} end)' > "$dir/$id.json.tmp"
    mv "$dir/$id.json.tmp" "$dir/$id.json"
    if [ "$JSON" = 1 ]; then cat "$dir/$id.json"; else printf '%s\n' "$id"; fi ;;
  list)
    since=""; fcode=""; fseat=""; fticket=""; JSON=0
    while [ $# -gt 0 ]; do case $1 in --since) since=$2; shift 2;; --code) fcode=$2; shift 2;; --seat) fseat=$2; shift 2;; --ticket) fticket=$2; shift 2;; --json) JSON=1; shift;; *) die 2 "unknown flag $1";; esac; done
    find "$ROOT" -path '*/20*/*.json' -name '*.json' | sort | while read -r f; do
      jq -e --arg s "$since" --arg c "$fcode" --arg st "$fseat" --arg t "$fticket" 'select(($s=="" or .at>=$s) and ($c=="" or (.code|tostring)==$c) and ($st=="" or .seat==$st) and ($t=="" or .ticket==$t))' "$f" >/dev/null 2>&1 || continue
      if [ "$JSON" = 1 ]; then cat "$f"; else line_of "$f"; fi; done ;;
  check)
    command -v python3 >/dev/null || die 4 "python3 with jsonschema is required for check"; bad=0
    while read -r f; do
      python3 -c 'import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))' "$f" "$SCHEMA" 2>/dev/null || { echo "invalid: $f" >&2; bad=1; }
      [ "$(basename "$f" .json)" = "$(jq -r .id "$f")" ] || { echo "filename/id mismatch: $f" >&2; bad=1; }
    done < <(find "$ROOT" -path '*/20*/*.json' -name '*.json')
    [ "$bad" = 0 ] && echo "events ok: $(find "$ROOT" -path '*/20*/*.json' -name '*.json' | wc -l) files" || exit 3 ;;
  tail) find "$ROOT" -path '*/20*/*.json' -name '*.json' | sort | tail -10 | while read -r f; do line_of "$f"; done ;;
  *) sed -n '2,13p' "$0" >&2; exit 2 ;;
esac
