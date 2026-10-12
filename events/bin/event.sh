#!/usr/bin/env bash
# event.sh - the event log. One file per event under events/YYYY/MM/, named
# <UTC>-<code>-<suffix>.json, so N seats write at once with no lock and git never
# conflicts (REQ-event-log). Only important items: code >= 300, seat up/down, a
# gate result, a merge, a compaction. Routine progress is not an event.
#
#   event.sh add --code NNN --seat NAME --kind KIND [--ticket WO-...] [--pane P] [--to ROLE] [--note "<=240 chars"]
#                [--evidence PATH]... [--observe "path:line:saw:expected"]... [--attempt N] [--sha HEX7-40] [--pr N] [--action "<=240 chars"] [--answer ID] [--policy POL-id] [--json]
#   event.sh list [--since YYYY-MM-DD] [--code NNN] [--seat NAME] [--ticket WO-...] [--json]
#   event.sh check                      every file matches events/schema/event.schema.json; exit 3 names offenders
#   event.sh tail                       newest 10, one line each (what the monitor pane shows)
# Exit codes: 0 ok, 2 usage, 3 validation, 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); ROOT=$(cd "$HERE/.." && pwd); SCHEMA=$ROOT/schema/event.schema.json
# BREADCRUMB 2026-10-11 - WO-20261011-4db1, --sha and --pr. What broke: no record could carry the pull request head or number as a
#   field, so every pr.opened, test.passed and review.passed in the live log has the head only inside its note ("PR 15 head
#   9ed0690", 20261011T183149Z-100-muiv4) and the merger gate "review.passed 201 and test.passed 201 on the same sha" (playbooks/
#   merger.md step 1) held on prose that nothing may route on. factory/schema/record.schema.json already named sha and pr; this
#   writer never could. Why this fix: two optional, validated flags written as fields (7 to 40 lowercase hex; a PR number from
#   1), schema entries for both, and the route runner copies them onto the wake line of a row that says `with pr`. Rejected:
#   reading them back out of the note (routing on prose is the one thing the runner is forbidden to do) and making them
#   required (most kinds have no PR). Cost: a seat has to pass them; one that does not still routes, on the plain line.
die() { local c=$1; shift; printf 'event: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
# BREADCRUMB 2026-10-11 - WO-20261011-38c7. What broke: KINDS held only the twelve event-log kinds, so a factory record of
#   kind pr.opened, test.failed, review.passed, merged and the rest (factory/schema/record.schema.json, SPEC-03 s-records) could
#   not be written here, and the route runner (factory/bin/route.sh) would never see a real record; the runner's own receipt
#   record.routed 300 could not be written either. Seats had been posting these as kind note with the kind in the note text,
#   which nothing may branch on. Why this fix: the runner routes on kind and code only, so the kinds belong in the enum; `--to`
#   adds the addressee (AC-H2 and AC-H3 of the ticket ask for a record "to the monitor" and "to the architect") as a field, not
#   as note text. Rejected: a second writer script for factory records (two formats in one log) and routing on the note prefix.
#   Cost: the enum is now a superset of the event kinds, so a typo'd factory kind is no longer a validation error here; the
#   routes file and make lint own the meaning of a kind.
KINDS='seat.up|seat.down|seat.stalled|gate|test|review|merge|deploy|compaction|blocked|escalation|note|request\.forwarded|request\.accepted|request\.rejected|ticket\.cut|work\.started|pr\.opened|test\.passed|test\.failed|review\.passed|review\.changes|merged|merge\.conflict|verified|rejected|escalated|record\.routed|break\.glass|policy\.applied'
ROLES='interface-agent|orchestrator|architect|worker|tester|reviewer|merger|verifier|player|monitor'
line_of() { jq -r '"\(.at)\t\(.code)\t\(.kind)\t\(.seat)\t\(.ticket // "-")\t\(.note // "")"' "$1"; }
VERB=${1:-}; shift || true
case $VERB in
  add)
    code=""; seat=""; kind=""; ticket=null; pane=null; to=null; note=""; attempt=null; sha=null; pr=null; action=null; answer=null; policy=null; ev=(); obs=(); JSON=0
    while [ $# -gt 0 ]; do case $1 in
      --code) code=$2; shift 2;; --seat) seat=$2; shift 2;; --kind) kind=$2; shift 2;; --ticket) ticket=$2; shift 2;; --pane) pane=$2; shift 2;; --to) to=$2; shift 2;;
      --note) note=$2; shift 2;; --attempt) attempt=$2; shift 2;; --sha) sha=$2; shift 2;; --pr) pr=$2; shift 2;; --action) action=$2; shift 2;; --answer) answer=$2; shift 2;; --policy) policy=$2; shift 2;; --evidence) ev+=("$2"); shift 2;; --observe) obs+=("$2"); shift 2;; --json) JSON=1; shift;; *) die 2 "unknown flag $1";; esac; done
    [[ $code =~ ^[1-5][0-9]{2}$ ]] || die 2 "--code must be 100..599"; [[ $seat =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || die 2 "--seat must match ^[a-z][a-z0-9_-]{0,31}$"
    [[ $kind =~ ^($KINDS)$ ]] || die 2 "--kind must be one of $KINDS"; [ ${#note} -le 240 ] || die 3 "--note over 240 chars"
    [ "$to" = null ] || [[ $to =~ ^($ROLES)$ ]] || die 2 "--to must be one of $ROLES"
    # BREADCRUMB 2026-10-11 - WO-20261011-4562, break glass (DEC-break-glass-one-time). What broke: nothing yet; the owner's
    #   order is that a seat may run one command its role denies only when the owner says so, once, and every such grant is a
    #   record the board shows. KINDS and event.schema.json had no kind for it, and a record about a command needs the command
    #   and the owner's answer as fields, not as note text nobody may branch on. Why this fix: kind break.glass with `action`
    #   (the one command, 240 chars like note) and `answer` (the id of the 300 request, which is also the id of the card on
    #   the bearings page). Codes: 300 request, 200 granted by the owner, 423 refused, 100 in effect, 201 action done,
    #   204 role settings restored; the record's seat is the seat the glass is broken for, whoever writes it. herdr/bin/seat.sh
    #   --break-glass never trusts a 200: it reads the owner's answer from the page itself. Rejected: --action and --answer on
    #   every kind (a stray flag on a test record would pass silently) and a second writer script (two formats in one log).
    #   Cost: the two flags are refused on any other kind, so a future kind that wants them edits this line.
    [ "$kind" != break.glass ] || { [ "$action" != null ] && [ -n "$action" ]; } || die 2 "a break.glass record needs --action (the one command)"
    [ "$kind" = break.glass ] || [ "$action" = null ] || die 2 "--action belongs to kind break.glass only"
    # BREADCRUMB 2026-10-12 - WO-20261012-9b2c, kind policy.applied (factory/bin/policy.sh). What broke: nothing yet; an escalation
    #   that nobody answers by its deadline now gets the default its policy row names, and the line needs a record that says which
    #   policy fired and which record it answers as FIELDS, because the notes of other kinds are prose nothing may branch on (the
    #   count of defaults already applied to a ticket, limit_per_ticket in factory/config/policies.json, is read from `policy`).
    #   Why this fix: `answer` already means "the id of the request record this one answers" (break.glass), so policy.applied
    #   reuses it; `policy` is one new field. Both are refused on any other kind, as --action is, so a stray flag cannot pass
    #   silently, and policy.applied cannot be written without them. Rejected: a second writer script (two formats in one log) and
    #   putting the policy id in the note (the limit would count prose). Cost: a future kind that wants either flag edits this line.
    [ "$kind" = break.glass ] || [ "$kind" = policy.applied ] || [ "$answer" = null ] || die 2 "--answer belongs to kinds break.glass and policy.applied only"
    [ "$kind" != policy.applied ] || { [ "$policy" != null ] && [ "$answer" != null ]; } || die 2 "a policy.applied record needs --policy and --answer (the record it answers)"
    [ "$kind" = policy.applied ] || [ "$policy" = null ] || die 2 "--policy belongs to kind policy.applied only"
    [ "$policy" = null ] || [[ $policy =~ ^POL-[a-z0-9][a-z0-9-]{0,47}$ ]] || die 3 "--policy must be POL-<lowercase words joined by ->"
    [ "$action" = null ] || [ ${#action} -le 240 ] || die 3 "--action over 240 chars"
    [ "$answer" = null ] || [[ $answer =~ ^[0-9]{8}T[0-9]{6}Z-[0-9]{3}-[a-z0-9]{5}$ ]] || die 3 "--answer must be a record id"
    [ "$ticket" = null ] || [[ $ticket =~ ^WO-[0-9]{8}-[0-9a-f]{4}$ ]] || die 3 "--ticket must be WO-YYYYMMDD-xxxx"
    [ "$sha" = null ] || [[ $sha =~ ^[0-9a-f]{7,40}$ ]] || die 2 "--sha must be 7 to 40 lowercase hex characters"
    [ "$pr" = null ] || [[ $pr =~ ^[1-9][0-9]*$ ]] || die 2 "--pr must be a pull request number, 1 or more"
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ); stamp=$(date -u +%Y%m%dT%H%M%SZ); suf=$(head -c 200 /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | cut -c1-5)
    id="$stamp-$code-$suf"; dir="$ROOT/$(date -u +%Y/%m)"; mkdir -p "$dir"
    evj=$(printf '%s\n' "${ev[@]:-}" | { grep -v '^$' || true; } | jq -R . | jq -s .)
    obj=$(printf '%s\n' "${obs[@]:-}" | { grep -v '^$' || true; } | jq -R 'split(":") | {path:.[0], line:(.[1]|tonumber? // 0), saw:.[2], expected:.[3]}' | jq -s .)
    tq() { if [ "$1" = null ]; then echo null; else jq -n --arg v "$1" '$v'; fi; }
    jq -n --arg id "$id" --arg at "$now" --argjson code "$code" --arg seat "$seat" --arg kind "$kind" --argjson ticket "$(tq "$ticket")" --argjson pane "$(tq "$pane")" --argjson to "$(tq "$to")" --arg note "$note" --argjson evidence "$evj" --argjson observations "$obj" --argjson attempt "$attempt" --argjson sha "$(tq "$sha")" --argjson pr "$pr" --argjson action "$(tq "$action")" --argjson answer "$(tq "$answer")" --argjson policy "$(tq "$policy")" \
      '{schema_version:"1.0.0", id:$id, at:$at, code:$code, seat:$seat, kind:$kind, ticket:$ticket, pane:$pane, note:$note, evidence:$evidence, observations:$observations} + (if $attempt==null then {} else {attempt:$attempt} end) + (if $to==null then {} else {to:$to} end) + (if $sha==null then {} else {sha:$sha} end) + (if $pr==null then {} else {pr:$pr} end) + (if $action==null then {} else {action:$action} end) + (if $answer==null then {} else {answer:$answer} end) + (if $policy==null then {} else {policy:$policy} end)' > "$dir/$id.json.tmp"
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
