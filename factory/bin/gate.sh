#!/usr/bin/env bash
# gate.sh - the gate rules the architect used to apply by hand, as code (WO-20261012-3bb0). route.sh calls it for a routes.json row
# that names a `when` predicate or sets `supersede`; it reads the event log and git and writes nothing.
#
#   gate.sh same-head [--repo DIR] A B            0 the two shas are one head: equal, or their trees differ only under events/
#                                                 1 they differ; the paths that differ are printed, one per line
#                                                 4 a sha is not in the repo
#   gate.sh when PREDICATE --id ID [flags]        0 the record may be routed   1 hold: the reason is printed on one line   4 error
#       head_current   the record's sha is the ticket's newest pr.opened head (same-head), or either side carries no sha
#       heads_match    head_current, and the newest test.passed 201 for the ticket names the same head as the record
#   gate.sh supersedes --id ID [flags]            prints the id of the older pr.opened of the ticket that still has no tester result
#                                                 and names a different head, nothing when there is none
#   gate.sh pr-files --ticket ID [--base REF] [--head REF]
#                                                 0 the PR diff stays inside the ticket's files field, carries no aggregate and takes no doc number
#                                                 another PR or main already has   1 hold: each offending path on one line, joined with "; "   4 error
# Flags: --repo DIR (default: the checkout this script is in)   --events DIR (default: the records tree under the state root, $COQ_STATE/records)
# Exit: 0 ok, 1 hold or differ, 2 usage, 4 io or a sha the repo cannot resolve.
#
# BREADCRUMB 2026-10-13 - WO-20261012-0229 (Roadmap A2). What broke: --events defaulted to <repo>/events and load found a record by
#   `find -name "$ID.json"`. Since WO-20261012-7e13 event.sh writes <state>/records/YYYY/MM/YYYYMMDDHHMMSS-<name>.json, so the
#   default read a tree with no records and no file is named by its id any more: every `when` and `supersedes` ended "no record ID"
#   (exit 4), which route.sh turns into a 500 for each gate record. Why this fix: the default is the records tree (through
#   bin/state-root.sh, so COQ_STATE and the default root apply), and load finds the file whose `id` field is the id, by a fixed-string
#   grep for the field and a jq check of the hit. Rejected: keeping a find by file name as a second path (nothing writes that name now)
#   and passing route.sh's file path in (the verbs are also run by hand with an id, and the tests do). Cost: a lookup reads the files
#   that mention the id, which is the record, the receipts and notes that name it, not the whole log.
#   The resolver is loaded only for a verb that reads the log, so same-head and pr-files still run from a copy of this file alone.
# BREADCRUMB 2026-10-12 - WO-20261012-0677, verb pr-files. What broke: nothing checked a PR's diff against what its ticket said it would
#   change, so five PRs edited one set of files on 2026-10-12 and each merge conflicted the next (AC-H2 of the ticket). Why this fix: the
#   rule is factory/bin/claims.sh (files field, aggregates, doc numbers); this verb only gives it the gate's contract, exit 1 and one
#   line, so route.sh can hold a record on it the way it holds one on head_current. Rejected: a second copy of the rule here (two places
#   to drift) and a `when` predicate (those take a record id, and a PR diff has no record). Cost: routes.json does not call it yet -
#   that file was another PR's when this landed - so until a row says `when pr-files` the gate is run by hand or by the merger's step.
#
# BREADCRUMB 2026-10-12 - WO-20261012-3bb0. What broke: three rules lived in the architect's head. (1) On 2026-10-12 the architect judged
#   by hand that a test on efc1cd2 covered 43c22b4, one record file apart, because the merger gate said "test.passed 201 and review.passed
#   201 on the same sha" and a literal compare held a merge for a commit that changed nothing but events/. (2) A tester kept running a
#   head the worker had already moved past, and its result woke the reviewer on a stale sha. (3) A PR that conflicted with main waited
#   for the architect to wake its worker. All three stop when the architect does (epic WO-20261012-187e).
#   Why a script and not playbook prose: playbooks/merger.md is rendered from roles/merger.json, which a worker may not edit, and an
#   LLM seat comparing two trees by eye is the failure this replaces. The runner asks, so a merger is never woken for a head the rule
#   refuses. Rejected: teaching route.sh the rule (its header caps it at applying the table, and git is not a table), and a verdict
#   field on the record (the tester and reviewer would each compute it, twice, with prose).
#   Choices that look arbitrary:
#   1. Only events/ is excluded from the tree compare, not CONTEXT_STATE.md or work-orders/. The ticket names events/ and a record is
#      the one file a gate itself writes; a checkpoint or a ticket move is a change a tester did not run. Cost: a worker's closing
#      commit that touches a ticket file puts the PR back through the tester.
#   2. A sha the repo cannot resolve is exit 4, not "differ", after one `git fetch origin` (20 s). A PR head lives on origin until
#      someone fetches it; calling it different would hold every merge in a checkout that has not fetched. Cost: with no network the
#      answer is an error, and route.sh turns it into a 500 rather than a hold.
#   3. head_current passes when either side has no sha. Records written before event.sh took --sha have none, and holding them would
#      park every old ticket; heads_match is the strict one and holds on a missing sha, because a merge cannot be taken back.
#   4. Two literal shas where one is a prefix of the other (7 characters or more) are the same head with no git call, so a unit
#      test, or a checkout without the commit, still agrees with itself.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); FACTORY=$(cd "$HERE/.." && pwd)
REPO=$(cd "$FACTORY/.." && pwd); EVENTS=""; ID=""; TICKET_ARG=""; BASE_ARG=""; HEAD_ARG=""
die() { local c=$1; shift; printf 'gate: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
VERB=${1:-}; shift || true
ARGS=()
while [ $# -gt 0 ]; do case $1 in
  --repo) REPO=$(cd "${2:?}" && pwd) || die 4 "no such --repo"; shift 2;; --events) EVENTS=${2:?}; shift 2;; --id) ID=${2:?}; shift 2;;
  --ticket) TICKET_ARG=${2:?}; shift 2;; --base) BASE_ARG=${2:?}; shift 2;; --head) HEAD_ARG=${2:?}; shift 2;;
  -*) die 2 "unknown flag $1";; *) ARGS+=("$1"); shift;; esac; done
case $VERB in same-head|when|supersedes|pr-files) ;; *) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac
if [ -z "$EVENTS" ] && { [ "$VERB" = when ] || [ "$VERB" = supersedes ]; }; then
  # shellcheck source=paths.sh
  . "$HERE/paths.sh" || die 4 "cannot load paths.sh or the state-root resolver beside it"
  EVENTS=$(coq_tree records) || die 4 "the state root did not resolve; set COQ_STATE"
fi

# resolve SHA: the commit it names in the repo, fetching once when it is not there; empty when it cannot be found.
resolve() {
  local c; c=$(git -C "$REPO" rev-parse --verify --quiet "$1^{commit}" 2>/dev/null) && { printf '%s' "$c"; return; }
  timeout 20 git -C "$REPO" fetch --quiet origin >/dev/null 2>&1 || true
  git -C "$REPO" rev-parse --verify --quiet "$1^{commit}" 2>/dev/null || true
}
# same_head A B: 0 same, 1 differ (paths on stdout), 4 unresolvable (the sha on stderr).
same_head() {
  local a=$1 b=$2 ca cb
  [[ $a =~ ^[0-9a-f]{7,40}$ && $b =~ ^[0-9a-f]{7,40}$ ]] || { printf 'gate: malformed sha %s or %s\n' "$a" "$b" >&2; return 4; }
  case $a in "$b"*) return 0;; esac; case $b in "$a"*) return 0;; esac
  ca=$(resolve "$a"); [ -n "$ca" ] || { printf 'gate: %s is not in this repo\n' "$a" >&2; return 4; }
  cb=$(resolve "$b"); [ -n "$cb" ] || { printf 'gate: %s is not in this repo\n' "$b" >&2; return 4; }
  [ "$ca" != "$cb" ] || return 0
  git -C "$REPO" diff --quiet "$ca" "$cb" -- . ':(exclude)events' && return 0
  git -C "$REPO" diff --name-only "$ca" "$cb" -- . ':(exclude)events'; return 1
}
# the event log as one JSON array on stdout.
# One unreadable file must not blind the gate: the batch read is the fast path, and only when jq refuses it are the files read one by one,
# skipping the bad ones (case 02-no-route plants one, and route.sh turns it into its own 500). The `|| true` matters: under pipefail the
# loop's status is the last file's jq status, so a bad file that find happened to list last made the whole read fail, one run in three
# in 02-no-route on 2026-10-12 (backlog disva), depending on directory order.
log_all() {
  local files f; mapfile -d '' files < <(find "$EVENTS" -path '*/20*/*.json' -name '*.json' -print0 2>/dev/null)
  [ "${#files[@]}" -gt 0 ] || { echo '[]'; return; }
  jq -s '.' "${files[@]}" 2>/dev/null || { for f in "${files[@]}"; do jq -c '.' "$f" 2>/dev/null || true; done | jq -s '.'; }
}
# field NAME JSON: the record's field, empty when absent.
field() { jq -r --arg k "$1" '.[$k] // empty' <<<"$2"; }
# newest KIND CODE ... : the newest record of the ticket matching the jq filter $4 (default true), before the record when BEFORE is set.
newest() {
  jq -c --arg t "$TICKET" --arg id "$RID" --argjson kinds "$1" --argjson before "$2" '
    [ .[] | select(.ticket == $t and ([.kind] | inside($kinds)) and ($before == false or .id < $id)) ] | sort_by(.id) | last // empty' <<<"$ALL"
}
load() {
  [ -n "$ID" ] || die 2 "$VERB needs --id"
  local f hit; f=""
  while IFS= read -r hit; do
    jq -e --arg id "$ID" '.id == $id' "$hit" >/dev/null 2>&1 && { f=$hit; break; }
  done < <(grep -rlF --include='*.json' -e "\"id\": \"$ID\"" -e "\"id\":\"$ID\"" "$EVENTS" 2>/dev/null | LC_ALL=C sort)
  [ -n "$f" ] || die 4 "no record $ID under $EVENTS"
  REC=$(jq -c . "$f" 2>/dev/null) || die 4 "record $ID is not JSON"
  RID=$(field id "$REC"); TICKET=$(field ticket "$REC"); SHA=$(field sha "$REC")
  ALL=$(log_all) || die 4 "cannot read $EVENTS"
}
# hold REASON: the one line route.sh writes into the receipt.
hold() { printf '%s\n' "$1" | cut -c1-200; exit 1; }
# compare_to LABEL RECORD_JSON: hold unless the record's head is the same head as ours (an unresolvable sha is an error).
compare_to() {
  local other=$2 osha paths rc; osha=$(field sha "$other")
  paths=$(same_head "$SHA" "$osha" 2>/dev/null); rc=$?
  case $rc in 0) return 0;; 1) hold "$1 $osha and this record's $SHA differ outside events/: $(tr '\n' ' ' <<<"$paths" | cut -c1-120)";; *) die 4 "cannot compare $SHA with $osha";; esac
}
head_current() {
  local po; po=$(newest '["pr.opened"]' false); [ -n "$po" ] || return 0
  [ -n "$SHA" ] && [ -n "$(field sha "$po")" ] || return 0
  [ "$(field id "$po")" != "$RID" ] || return 0
  compare_to "the head moved: pr.opened $(field id "$po") names" "$po"
}

case $VERB in
  pr-files) [ -n "$TICKET_ARG" ] || die 2 "pr-files needs --ticket"
    ex=(--repo "$REPO"); [ -z "$BASE_ARG" ] || ex+=(--base "$BASE_ARG"); [ -z "$HEAD_ARG" ] || ex+=(--head "$HEAD_ARG")
    d=$("$HERE/claims.sh" diff --id "$TICKET_ARG" "${ex[@]}"); r1=$?; i=$("$HERE/claims.sh" ids "${ex[@]}"); r2=$?
    [ "$r1" -lt 4 ] && [ "$r2" -lt 4 ] || die 4 "claims.sh could not read the PR (diff $r1, ids $r2)"
    [ "$r1" = 0 ] && [ "$r2" = 0 ] || hold "$(printf '%s\n%s\n' "$d" "$i" | grep . | paste -sd';' | sed 's/;/; /g')"
    exit 0 ;;
  same-head) [ "${#ARGS[@]}" = 2 ] || die 2 "same-head needs two shas"; same_head "${ARGS[0]}" "${ARGS[1]}"; exit $? ;;
  when) [ "${#ARGS[@]}" = 1 ] || die 2 "when needs a predicate"; load
    case ${ARGS[0]} in
      head_current) head_current ;;
      heads_match)
        [ -n "$SHA" ] || hold "$(field kind "$REC") $RID carries no sha, so it cannot be matched to a test"
        tp=$(newest '["test.passed"]' true); [ -n "$tp" ] || hold "no test.passed for $TICKET before $RID"
        [ -n "$(field sha "$tp")" ] || hold "test.passed $(field id "$tp") carries no sha"
        compare_to "test.passed $(field id "$tp") on" "$tp"; head_current ;;
      *) die 2 "unknown predicate ${ARGS[0]}" ;;
    esac; exit 0 ;;
  supersedes) [ "${#ARGS[@]}" = 0 ] || die 2 "supersedes takes no arguments"; load; [ -n "$SHA" ] || exit 0
    # the older pr.opened of the ticket: before this record, and no tester result (test.passed, test.failed, blocked) after it.
    old=$(jq -c --arg t "$TICKET" --arg id "$RID" '. as $all
      | [ $all[] | select(.ticket == $t and .kind == "pr.opened" and .id < $id and (.sha // "") != "") ] | sort_by(.id) | last // empty
      | select(. as $p | [ $all[] | select(.ticket == $t and .id > $p.id and ([.kind] | inside(["test.passed", "test.failed", "blocked"]))) ] | length == 0)' <<<"$ALL")
    [ -n "$old" ] || exit 0
    same_head "$SHA" "$(field sha "$old")" >/dev/null 2>&1; [ $? = 0 ] || printf '%s\n' "$(field id "$old")"; exit 0 ;;
esac
