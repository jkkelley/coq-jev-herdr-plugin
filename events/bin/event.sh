#!/usr/bin/env bash
# event.sh - the event log. One file per event, so N seats write at once with no lock and git never conflicts (REQ-event-log).
# A record is written under the state root, <state>/records/YYYY/MM/YYYYMMDDHHMMSS-<descriptive name>.json (UTC; the name says what
# the record is, at most name_max characters), never into the repository (ROADMAP.md, Where runtime data lives). The state root is
# $COQ_STATE, else the default in config/state.json, both through bin/state-root.sh. Only important items: code >= 300, seat
# up/down, a gate result, a merge, a compaction. Routine progress is not an event.
#
#   event.sh add --code NNN --seat NAME --kind KIND [--ticket WO-...] [--pane P] [--to ROLE] [--note "<=240 chars"]
#                [--evidence PATH]... [--observe "path:line:saw:expected"]... [--attempt N] [--sha HEX7-40] [--pr N] [--action "<=240 chars"] [--answer ID] [--policy POL-id] [--json]
#                prints the new file's path, or with --json the record
#   event.sh list [--since YYYY-MM-DD] [--code NNN] [--seat NAME] [--ticket WO-...] [--json]    oldest first, by the record's time
#   event.sh check                      every file matches events/schema/event.schema.json and its name; exit 3 names offenders
#   event.sh tail                       newest 10, one line each (what the monitor pane shows)
# list, tail and check read the state root and, until roadmap item A4 removes it from git, the repository's events/ tree too.
# add refuses, with exit 3 and nothing written: a --code outside the SPEC-17 s-codes status code map (the code enum in the schema), and a
# --sha missing on kind pr.opened, test.passed, test.failed, review.passed, review.changes, merged, merge.conflict, verified or rejected.
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
# BREADCRUMB 2026-10-12 - WO-20261012-7e13 (Roadmap A1, owner cards C10 and C11). What broke: add wrote every record into the
#   repository, as $ROOT/YYYY/MM/<UTC>-<code>-<suffix>.json (the line this replaces), so 2,689 record files rode one pull request on
#   2026-10-12 and a name like 20261012T223337Z-100-ms2zc says nothing until it is opened. Why this fix: add writes under the state
#   root that bin/state-root.sh resolves (COQ_STATE, else the default in config/state.json), on the layout <state>/records/YYYY/MM/
#   YYYYMMDDHHMMSS-<descriptive name>.json, and prints the new path. The record's own `id` field keeps its old shape: --answer and
#   the routed ledger refer to it, and moving them is items A2 and A3. list, tail and check read both trees until item A4 takes
#   events/ out of git. Rejected: a fallback that writes the old tree when the resolver is missing (a partial copy of this script
#   would then put records back in git without a word; it stops with exit 4 instead) and a dual write (every post would still be a
#   tracked file). Cost: a script or test world that copies events/bin alone must also copy bin/state-root.sh and config/state.json
#   (factory/tests/lib/world.sh and herdr/tests/lib/world.sh do not yet, and the belt and seats read the old tree until A2).
. "$ROOT/../bin/state-root.sh" 2>/dev/null || die 4 "bin/state-root.sh is missing beside this events/ tree; records go to the state root and nothing here may guess one"
LEGACY=$ROOT; TREES=()
# load_trees: TREES is the state root's records tree when it exists, then the repository's events/ tree; a malformed root stops here
load_trees() {
  local r rc=0; TREES=()
  r=$(coq_tree records) || rc=$?
  case $rc in 0) [ ! -d "$r" ] || TREES+=("$r");; 4) printf 'event: state root unresolved, reading the repository events/ only\n' >&2;; *) exit "$rc";; esac
  [ ! -d "$LEGACY" ] || TREES+=("$LEGACY")
}
tree_files() { [ ${#TREES[@]} -eq 0 ] || find "${TREES[@]}" -mindepth 3 -maxdepth 3 -name '*.json' -print; }
dated_files() { # every record, oldest first by its own time, then by path
  local f; tree_files | while read -r f; do printf '%s\t%s\n' "$(jq -r '.at // ""' "$f" 2>/dev/null || true)" "$f"; done | LC_ALL=C sort | cut -f2-
}
slug() { printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9' '-' | tr -s '-' | sed 's/^-//; s/-$//'; }
record_name() { # record_name KIND PR TICKET SEAT MAX: kind, then pr-N, then the ticket (the seat when there is none), cut to MAX
  local n; n=$(slug "$1"); [ "$2" = null ] || n=$n-pr-$2
  if [ "$3" != null ]; then n=$n-$(slug "$3"); else n=$n-$(slug "$4"); fi
  n=${n:0:$5}; printf '%s\n' "${n%-}"
}
# BREADCRUMB 2026-10-11 - WO-20261011-38c7. What broke: KINDS held only the twelve event-log kinds, so a factory record of
#   kind pr.opened, test.failed, review.passed, merged and the rest (factory/schema/record.schema.json, SPEC-03 s-records) could
#   not be written here, and the route runner (factory/bin/route.sh) would never see a real record; the runner's own receipt
#   record.routed 300 could not be written either. Seats had been posting these as kind note with the kind in the note text,
#   which nothing may branch on. Why this fix: the runner routes on kind and code only, so the kinds belong in the enum; `--to`
#   adds the addressee (AC-H2 and AC-H3 of the ticket ask for a record "to the monitor" and "to the architect") as a field, not
#   as note text. Rejected: a second writer script for factory records (two formats in one log) and routing on the note prefix.
#   Cost: the enum is now a superset of the event kinds, so a typo'd factory kind is no longer a validation error here; the
#   routes file and make lint own the meaning of a kind.
KINDS='seat.up|seat.down|seat.stalled|gate|test|review|merge|deploy|compaction|blocked|escalation|note|request\.forwarded|request\.accepted|request\.rejected|ticket\.cut|work\.started|pr\.opened|test\.passed|test\.failed|review\.passed|review\.changes|merged|merge\.conflict|verified|rejected|escalated|record\.routed|break\.glass|policy\.applied|line\.halted|line\.draining|line\.resumed'
# GATE_KINDS: the records a gate or a merge step routes on by pull request head (SPEC-17 s-codes 201, 409, 412, 422; s-inventory H11).
GATE_KINDS='pr\.opened|test\.passed|test\.failed|review\.passed|review\.changes|merged|merge\.conflict|verified|rejected'
ROLES='interface-agent|orchestrator|architect|worker|tester|reviewer|merger|player|monitor'
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
    # BREADCRUMB 2026-10-13 - WO-20261013-f298 (Roadmap K5, SPEC-17 s-codes and s-inventory H11). What broke: --code accepted any
    #   of 100..599 (the regex two lines up) and --sha was optional on every kind, so on 2026-10-12 a tester's test.passed with no sha
    #   was written and routed, the reviewer's pass was held on it (factory/bin/gate.sh heads_match) until a seat was re-posted by
    #   hand, and a code that no routes row maps (events/ held 150 and 450 in tests and roles/compliance-officer.json) would route
    #   nowhere. Why this fix: the writer is the one place every record passes, so it refuses both before anything is written
    #   (exit 3, naming the flag or the code). The map is read from the schema's code enum, not copied into this script, so the
    #   schema, this refusal and events/tests/cases/04-refusals.test.sh (which compares the enum with SPEC-17 s-codes) cannot drift.
    #   Rejected: a required sha in the schema (records written before this rule have none and `event.sh check` must keep passing
    #   them) and a warning instead of a refusal (a warning is what let the record through on 2026-10-12). Cost: a caller that
    #   posts a gate kind without --sha now fails with exit 3 (factory/tests and herdr/tests post them bare; roadmap item A2 holds
    #   those files), and roles/compliance-officer.json reports with code 450, which is not in the map (SPEC-17 s-codes puts seat
    #   findings at 500); both are for the architect to rule on, recorded in WO-20261013-f298's notes.
    codes=$(jq -r '.properties.code.enum | map(tostring) | join("|")' "$SCHEMA" 2>/dev/null) && [ -n "$codes" ] || die 4 "cannot read the status code map from $SCHEMA"
    [[ $code =~ ^($codes)$ ]] || die 3 "--code $code is not in the SPEC-17 status code map (${codes//|/, })"
    ! [[ $kind =~ ^($GATE_KINDS)$ ]] || [ "$sha" != null ] || die 3 "--sha is required on a $kind record (the pull request head the gate is about, 7 to 40 lowercase hex characters)"
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
    # one `date` call, so the id, the `at` field, the file name and the YYYY/MM folder can never straddle a second
    read -r now stamp fstamp ym < <(date -u '+%Y-%m-%dT%H:%M:%SZ %Y%m%dT%H%M%SZ %Y%m%d%H%M%S %Y/%m'); suf=$(head -c 200 /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | cut -c1-5)
    id="$stamp-$code-$suf"; recs=$(coq_tree records) || exit $?; max=$(coq_state_get name_max) || exit $?
    dir="$recs/$ym"; mkdir -p "$dir" || die 4 "cannot create $dir"
    evj=$(printf '%s\n' "${ev[@]:-}" | { grep -v '^$' || true; } | jq -R . | jq -s .)
    obj=$(printf '%s\n' "${obs[@]:-}" | { grep -v '^$' || true; } | jq -R 'split(":") | {path:.[0], line:(.[1]|tonumber? // 0), saw:.[2], expected:.[3]}' | jq -s .)
    tq() { if [ "$1" = null ]; then echo null; else jq -n --arg v "$1" '$v'; fi; }
    tmp="$dir/.$fstamp-$id.tmp"; trap 'rm -f "$tmp"' EXIT
    jq -n --arg id "$id" --arg at "$now" --argjson code "$code" --arg seat "$seat" --arg kind "$kind" --argjson ticket "$(tq "$ticket")" --argjson pane "$(tq "$pane")" --argjson to "$(tq "$to")" --arg note "$note" --argjson evidence "$evj" --argjson observations "$obj" --argjson attempt "$attempt" --argjson sha "$(tq "$sha")" --argjson pr "$pr" --argjson action "$(tq "$action")" --argjson answer "$(tq "$answer")" --argjson policy "$(tq "$policy")" \
      '{schema_version:"1.0.0", id:$id, at:$at, code:$code, seat:$seat, kind:$kind, ticket:$ticket, pane:$pane, note:$note, evidence:$evidence, observations:$observations} + (if $attempt==null then {} else {attempt:$attempt} end) + (if $to==null then {} else {to:$to} end) + (if $sha==null then {} else {sha:$sha} end) + (if $pr==null then {} else {pr:$pr} end) + (if $action==null then {} else {action:$action} end) + (if $answer==null then {} else {answer:$answer} end) + (if $policy==null then {} else {policy:$policy} end)' > "$tmp"
    # Exclusive create with no lock: a hard link fails when the name exists and the content is complete the instant it appears. A clash
    # (same second, same name) takes -2, then -3; the suffix counts inside the name limit, so no name is ever over it.
    base=$(record_name "$kind" "$pr" "$ticket" "$seat" "$max"); n=1
    while :; do
      sfx=""; [ "$n" -eq 1 ] || sfx="-$n"; cand=${base:0:$((max - ${#sfx}))}; cand=${cand%-}$sfx
      target="$dir/$fstamp-$cand.json"
      ln "$tmp" "$target" 2>/dev/null && break
      [ -e "$target" ] || die 4 "cannot create $target"
      n=$((n + 1)); [ "$n" -le 99 ] || die 4 "99 records named $fstamp-$base in one second"
    done
    if [ "$JSON" = 1 ]; then cat "$target"; else printf '%s\n' "$target"; fi ;;
  list)
    since=""; fcode=""; fseat=""; fticket=""; JSON=0
    while [ $# -gt 0 ]; do case $1 in --since) since=$2; shift 2;; --code) fcode=$2; shift 2;; --seat) fseat=$2; shift 2;; --ticket) fticket=$2; shift 2;; --json) JSON=1; shift;; *) die 2 "unknown flag $1";; esac; done
    load_trees
    dated_files | while read -r f; do
      jq -e --arg s "$since" --arg c "$fcode" --arg st "$fseat" --arg t "$fticket" 'select(($s=="" or .at>=$s) and ($c=="" or (.code|tostring)==$c) and ($st=="" or .seat==$st) and ($t=="" or .ticket==$t))' "$f" >/dev/null 2>&1 || continue
      if [ "$JSON" = 1 ]; then cat "$f"; else line_of "$f"; fi; done ;;
  check)
    command -v python3 >/dev/null || die 4 "python3 with jsonschema is required for check"; bad=0; n=0; load_trees; max=$(coq_state_get name_max) || exit $?
    while read -r f; do
      n=$((n + 1)); b=$(basename "$f" .json)
      python3 -c 'import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))' "$f" "$SCHEMA" 2>/dev/null || { echo "invalid: $f" >&2; bad=1; }
      case $f in
        "$LEGACY"/*) [ "$b" = "$(jq -r .id "$f" 2>/dev/null)" ] || { echo "filename/id mismatch: $f" >&2; bad=1; } ;;
        *) at=$(jq -r '.at // ""' "$f" 2>/dev/null)
           if [[ $b =~ ^([0-9]{14})-([a-z0-9]+(-[a-z0-9]+)*)$ ]] && [ ${#BASH_REMATCH[2]} -le "$max" ] && [ "${BASH_REMATCH[1]}" = "$(printf '%s' "$at" | tr -d ':TZ-')" ] && [ "$(dirname "$f")" = "$(dirname "$(dirname "$f")")/${b:4:2}" ] && [ "$(basename "$(dirname "$(dirname "$f")")")" = "${b:0:4}" ]; then :
           else echo "bad name (want YYYYMMDDHHMMSS-<name of at most $max lowercase letters, digits and hyphens>.json in YYYY/MM, the time being the record's at): $f" >&2; bad=1; fi ;;
      esac
    done < <(tree_files)
    [ "$bad" = 0 ] && echo "events ok: $n files" || exit 3 ;;
  tail) load_trees; dated_files | tail -10 | while read -r f; do line_of "$f"; done ;;
  *) sed -n '2,15p' "$0" >&2; exit 2 ;;
esac
