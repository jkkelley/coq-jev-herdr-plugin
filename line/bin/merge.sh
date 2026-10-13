#!/usr/bin/env bash
# merge.sh - the merge as code (SPEC-17 s-inventory H11; ticket WO-20261013-f6ae). It squash-merges a pull request whose newest head has a
# test.passed 201 and a review.passed 201 on it, posts merged 200 with the merge sha so the merger seat can verify main, and posts
# merge.conflict 409 to the worker lane when the branch no longer merges cleanly. The decision is a function of records and the head,
# so no seat makes it.
#
#   merge.sh --pr N [--repo DIR] [--json]    one pull request
#   merge.sh --all  [--repo DIR] [--json]    one pass over every open pull request, lowest number first
# --repo DIR is the git checkout gate.sh compares heads in and gh runs from (default: the checkout this script is in).
# One line per pull request on stdout (--json: one JSON object per line: pr, ticket, outcome, detail).
#
# Outcomes and exit codes (--all exits 0 unless a gh call failed for good or the merge hold is on when the pass starts; a held or a conflicting
# pull request is a normal state in a pass):
#   merged           0  squash-merged; exactly one merged 200 posted, sha = the merge commit, pr, ticket, to merger
#   already-merged   0  the pull request is already merged; nothing posted, nothing merged
#   held             3  nothing is merged or posted: no review.passed 201, or the 201s name an older head, or gate.sh heads_match
#                       holds, or the pull request is closed, or its title names no ticket
#   held (merge hold) 3 the merge hold file exists (see "The merge hold" below): nothing is merged, whatever the pull request, and ONE
#                       blocked 423 to the orchestrator lane names the hold's reason (once per hold, not once per pass or per PR).
#                       --all prints one line, with PR 0, and exits 3 (the other held outcomes keep --all at 0)
#   conflict         5  merge.conflict 409 posted to the worker lane with the pull request and head (once per head; a rerun on
#                       the same head posts nothing)
#   failed           4  a gh call (or gate.sh) failed three times; ONE blocked 423 to the orchestrator lane, then the run stops
#   usage            2
# Records are read from the records tree under the state root (bin/state-root.sh), the tree gate.sh reads, and written through
# events/bin/event.sh. Knobs, for tests and a slow network: MERGE_RETRIES (attempts per gh call, default 3), MERGE_BACKOFF_SECONDS
# (sleep after attempt n is n times this, default 2).
#
# BREADCRUMB 2026-10-13 - WO-20261013-f6ae. What broke: factory/config/routes.json:12 hands every review.passed 201 to the merger seat
#   (roles/merger.json, a Haiku seat), and that seat ran `gh pr merge --squash` for one pull request at a time, about fifteen minutes
#   each on 2026-10-13 (owner 03:02Z, "I hate bottlenecks"), though the merge is mechanical: the heads either match the records or they
#   do not. Why this fix: the whole gate is already code (factory/bin/gate.sh heads_match and same-head), so this script is that gate
#   plus one gh call plus two records; the merger seat is left with the verify of main and with conflicts. Rejected: teaching route.sh
#   to merge (its header caps it at applying the table, and a merge is a side effect on GitHub, not a route) and a GitHub auto-merge
#   setting (it knows nothing of test.passed and review.passed records, which live in the state root and not in GitHub).
#   Choices that look arbitrary:
#   1. The decision reads the NEWEST review.passed 201 of the ticket, asks gate.sh same-head whether it names the head gh reports now,
#      and only then asks gate.sh when heads_match, which finds the test.passed. A head pushed after the review is therefore held, and
#      --match-head-commit makes GitHub refuse a head that moves between our read and the merge. Cost: a worker's closing commit that
#      changes a file outside events/ puts the pull request back through the tester, as gate.sh already documents.
#   2. A conflict is decided by gh's own `mergeable` field (CONFLICTING), read before the merge and again after a refused merge, never
#      by matching the refusal text: GitHub also refuses a clean branch for a branch rule, and that is a block for the orchestrator,
#      not a rebase for the worker. Cost: UNKNOWN (GitHub still computing) is tried, and a refusal with UNKNOWN is retried with backoff.
#   3. A merge refused because the pull request meanwhile became MERGED (a lost reply, or a second run) is a success: the merge sha is
#      read back and merged 200 is posted unless one already names this pull request and ticket. Cost: a second run racing the first
#      between its own merge and its own post can still post twice; there is no lock file, because a lock directory would be a new
#      artifact tree that needs its own README (AGENTS.md, Law: tooling in the repository). The dedupe read narrows the window to
#      milliseconds.
#   4. merge.conflict is posted once per (pull request, head): the patrol tick runs --all every minute and a conflicting pull request
#      would otherwise post a record a minute until the worker rebases. The rebase changes the head, which re-arms the post.
#   5. An already merged pull request posts nothing, even when no merged record exists for it (a crash between the merge and the post,
#      or a merge by hand). The ticket says "posts nothing twice" and healing from here would post for pull requests merged long
#      before this script. Cost: a failed post of merged 200 leaves no verify; the script then exits 4 and prints the exact merge sha
#      and the command to post it again, rather than staying silent.
#   6. --all stops at the first pull request whose gh call fails for good: a gh outage would otherwise post one blocked 423 per open
#      pull request. The next pass starts again from the lowest number; the outcome lines already printed stand.
# The merge hold (WO-20261013-2d35, cause l). What broke: on 2026-10-13 PR 94 was merged onto a red main because the hold on merges
#   was a ruling in prose, which no script read (record gsp29). verify-main.sh (WO-20261013-9bdd, cause j) now writes the hold as a
#   file, <run tree>/merge-hold.json, and removes it on a green verify of that sha or a later one; this script is the reader. Why this
#   fix: the file is the only thing every merge path shares, so refusing here stops the merger seat, the patrol tick and a hand run
#   alike, and nobody has to remember a sentence. Choices that look arbitrary:
#   1. The file existing is the hold, whatever it holds: a file jq cannot read still holds, with the reason "unreadable". Fail closed;
#      lifting is verify-main.sh's job and a hand `rm` of the file.
#   2. The hold is checked before any gh call (a held pass costs no API calls) and again right before `gh pr merge`, because a verify
#      can write the hold while a long --all pass is under way. Cost: the second check is a stat; there is still a window of
#      milliseconds between it and GitHub taking the merge, which only GitHub-side branch protection could close.
#   3. The 423 is deduped on its note (which carries the hold's sha) because the patrol tick runs --all every minute and a hold lasts
#      until main is green again; one 423 per minute would bury the orchestrator. Cost: a hold rewritten for the same sha with the same
#      reason posts nothing new, which is right: the orchestrator has that 423 already.
#   4. --all exits 3 under a hold, unlike every other held outcome: the ticket says the refusal is exit 3, and a pass that merged
#      nothing because main is red is not a normal state the patrol should read as success.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); SELF_REPO=$(cd "$HERE/../.." && pwd)
GIT_REPO=$SELF_REPO; PR=""; ALL_FLAG=0; JSON=0
SEAT=merge-script; RETRIES=${MERGE_RETRIES:-3}; BACKOFF=${MERGE_BACKOFF_SECONDS:-2}
die() { local c=$1; shift; printf 'merge: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
command -v gh >/dev/null || die 4 "gh is required"
while [ $# -gt 0 ]; do case $1 in
  --pr) PR=${2:-}; shift 2 || die 2 "--pr needs a number";; --all) ALL_FLAG=1; shift;; --json) JSON=1; shift;;
  --repo) GIT_REPO=$(cd "${2:?--repo needs a directory}" && pwd) || die 4 "no such --repo"; shift 2;;
  *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac; done
if [ "$ALL_FLAG" = 1 ]; then [ -z "$PR" ] || die 2 "--pr and --all are exclusive"
else [[ $PR =~ ^[1-9][0-9]*$ ]] || die 2 "give --pr N (a pull request number) or --all"; fi
[[ $RETRIES =~ ^[1-9][0-9]*$ ]] || die 2 "MERGE_RETRIES must be a positive integer"; [[ $BACKOFF =~ ^[0-9]+$ ]] || die 2 "MERGE_BACKOFF_SECONDS must be a whole number"
EVENT=$SELF_REPO/events/bin/event.sh; GATE=$SELF_REPO/factory/bin/gate.sh
[ -x "$EVENT" ] && [ -x "$GATE" ] || die 4 "events/bin/event.sh or factory/bin/gate.sh is missing beside this line/ tree"
# shellcheck source=../../bin/state-root.sh
. "$SELF_REPO/bin/state-root.sh" 2>/dev/null || die 4 "bin/state-root.sh missing (roadmap item A1)"
RECS=$(coq_tree records) && RUN=$(coq_tree run) || die 4 "the state root did not resolve; set COQ_STATE"
HOLD=$RUN/merge-hold.json
ERRF=$(mktemp "${TMPDIR:-/tmp}/merge-err.XXXXXX") || die 4 "cannot make a temp file"; trap 'rm -f "$ERRF"' EXIT
BLOCKED_POSTED=0; GH_OUT=""; GH_ERR=""

# ---- output: one line per pull request ----
say() { # say PR TICKET OUTCOME DETAIL
  if [ "$JSON" = 1 ]; then jq -nc --argjson pr "$1" --arg t "$2" --arg o "$3" --arg d "$4" '{pr:$pr, ticket:(if $t=="" then null else $t end), outcome:$o, detail:$d}'
  else printf 'PR %s %s %s: %s\n' "$1" "${2:--}" "$3" "$4"; fi
}

# ---- gh with retries: GH_OUT is the last attempt's stdout, GH_ERR the tail of its stderr ----
nap() { sleep $(( BACKOFF * $1 )); }
gh_retry() { # gh_retry ARGS...: up to RETRIES attempts; 0 when one worked
  local n=1 rc
  while :; do
    GH_OUT=$(cd "$GIT_REPO" && gh "$@" 2>"$ERRF"); rc=$?; GH_ERR=$(tail -c 300 "$ERRF" | tr '\n' ' ')
    [ "$rc" -ne 0 ] || return 0
    [ "$n" -lt "$RETRIES" ] || return "$rc"
    nap "$n"; n=$((n + 1))
  done
}

# ---- records ----
# the state root's record files as one JSON array. One unreadable file must not blind the merge: batch first, file by file if jq refuses.
log_all() {
  local files f; mapfile -d '' files < <(find "$RECS" -path '*/20*/*.json' -name '*.json' -print0 2>/dev/null)
  [ "${#files[@]}" -gt 0 ] || { echo '[]'; return; }
  jq -s '.' "${files[@]}" 2>/dev/null || { for f in "${files[@]}"; do jq -c '.' "$f" 2>/dev/null || true; done | jq -s '.'; }
}
post() { # post ARGS...: event.sh add, retried; 0 when written
  local n=1 rc
  while :; do
    "$EVENT" add --seat "$SEAT" "$@" >/dev/null 2>"$ERRF"; rc=$?
    [ "$rc" -ne 0 ] || return 0
    [ "$n" -lt "$RETRIES" ] || { GH_ERR=$(tail -c 300 "$ERRF" | tr '\n' ' '); return "$rc"; }
    nap "$n"; n=$((n + 1))
  done
}
# fail_io PR TICKET WHAT: three attempts are spent. One blocked 423 per run, to the orchestrator, then exit 4 with the reason on stderr.
fail_io() {
  local note="merge.sh gave up on PR $1: $3 ${GH_ERR}"; note=${note:0:240}
  if [ "$BLOCKED_POSTED" = 0 ]; then
    BLOCKED_POSTED=1
    local t=(); [ -z "$2" ] || t=(--ticket "$2"); [ "$1" = 0 ] || t+=(--pr "$1")   # a failed `gh pr list` has no pull request
    post --code 423 --kind blocked --to orchestrator "${t[@]}" --note "$note" || printf 'merge: the blocked 423 for PR %s could not be posted either: %s\n' "$1" "$GH_ERR" >&2
  fi
  say "$1" "$2" failed "$3 ${GH_ERR}"; return 4
}

# ---- the merge hold ----
# hold_reason: while the hold file exists, sets HOLD_REASON and HOLD_SHA and returns 0; returns 1 when there is no hold. It sets globals
# and prints nothing, because a $(...) caller would lose HOLD_SHA to the subshell (found by merge-hold.sh: the 423 carried no sha).
hold_reason() {
  [ -e "$HOLD" ] || return 1
  HOLD_SHA=$(jq -r '.sha // empty' "$HOLD" 2>/dev/null)
  HOLD_REASON=$(jq -r '.reason // empty' "$HOLD" 2>/dev/null)
  : "${HOLD_REASON:=the merge hold file $HOLD exists and names no reason (unreadable or empty)}"
}
# post_hold REASON: the one blocked 423 per hold. REASON is trimmed so the note fits event.sh's 240 characters; the note is the dedupe key.
post_hold() {
  local note="merge.sh refuses to merge: $1"; note=${note:0:240}
  if jq -e --arg n "$note" 'any(.[]; .kind == "blocked" and .code == 423 and .seat == "merge-script" and .note == $n)' <<<"$(log_all)" >/dev/null 2>&1; then return 0; fi
  local s=(); [[ ${HOLD_SHA:-} =~ ^[0-9a-f]{7,40}$ ]] && s=(--sha "$HOLD_SHA")
  post --code 423 --kind blocked --to orchestrator "${s[@]}" --note "$note" \
    || printf 'merge: the blocked 423 for the merge hold could not be posted: %s\n' "$GH_ERR" >&2
}
# refuse_on_hold PR TICKET: 0 when there is no hold; with a hold, posts the 423, says held and returns 3
refuse_on_hold() {
  hold_reason || return 0
  post_hold "$HOLD_REASON"
  say "$1" "$2" held "the merge hold is on: $HOLD_REASON"; return 3
}

# ---- one pull request: returns 0 merged or already merged, 3 held, 4 failed, 5 conflict ----
merge_sha() { # merge_sha PR: the merge commit of a merged pull request (waits for GitHub to fill it in), in MERGE_SHA
  local n=1
  MERGE_SHA=""
  while :; do
    if gh_retry pr view "$1" --json state,mergeCommit; then
      MERGE_SHA=$(jq -r 'select(.state == "MERGED") | .mergeCommit.oid // empty' <<<"$GH_OUT" 2>/dev/null)
      [[ $MERGE_SHA =~ ^[0-9a-f]{40}$ ]] && return 0
    else return 4; fi
    [ "$n" -lt "$RETRIES" ] || { GH_ERR="the merge commit of PR $1 never appeared"; return 4; }
    nap "$n"; n=$((n + 1))
  done
}
post_merged() { # post_merged PR TICKET HEAD MERGE_SHA: merged 200 once
  if jq -e --arg t "$2" --argjson pr "$1" 'any(.[]; .kind == "merged" and .code == 200 and .ticket == $t and .pr == $pr)' <<<"$(log_all)" >/dev/null 2>&1; then
    say "$1" "$2" merged "merged 200 already posted; merge commit ${4:0:12}"; return 0
  fi
  if ! post --code 200 --kind merged --to merger --ticket "$2" --pr "$1" --sha "$4" --note "squash-merged PR $1 at head ${3:0:12}, merge commit ${4:0:12}"; then
    printf 'merge: PR %s IS MERGED (merge commit %s) but merged 200 could not be posted: %s\n  post it again: events/bin/event.sh add --seat %s --code 200 --kind merged --to merger --ticket %s --pr %s --sha %s\n' \
      "$1" "$4" "$GH_ERR" "$SEAT" "$2" "$1" "$4" >&2
    GH_ERR="PR merged as $4 but merged 200 was not posted"; fail_io "$1" "$2" "post"; return 4
  fi
  say "$1" "$2" merged "merge commit ${4:0:12}, head ${3:0:12}"; return 0
}
post_conflict() { # post_conflict PR TICKET HEAD
  if jq -e --arg t "$2" --argjson pr "$1" --arg h "$3" 'any(.[]; .kind == "merge.conflict" and .code == 409 and .ticket == $t and .pr == $pr and .sha == $h)' <<<"$(log_all)" >/dev/null 2>&1; then
    say "$1" "$2" conflict "merge.conflict 409 already posted for head ${3:0:12}"; return 5
  fi
  post --code 409 --kind merge.conflict --to worker --ticket "$2" --pr "$1" --sha "$3" --note "PR $1 no longer merges cleanly at head ${3:0:12}; merge main into the branch" \
    || { fail_io "$1" "$2" "post"; return 4; }
  say "$1" "$2" conflict "merge.conflict 409 posted to the worker lane for head ${3:0:12}"; return 5
}

do_pr() { # do_pr PR
  local pr=$1 view state title head mergeable ticket review rid rsha rc paths n=1 out mstate
  gh_retry pr view "$pr" --json number,state,title,headRefOid,mergeable || { fail_io "$pr" "" "gh pr view"; return 4; }
  view=$GH_OUT
  state=$(jq -r '.state // empty' <<<"$view" 2>/dev/null); title=$(jq -r '.title // empty' <<<"$view"); head=$(jq -r '.headRefOid // empty' <<<"$view")
  mergeable=$(jq -r '.mergeable // "UNKNOWN"' <<<"$view")
  [[ $title =~ ^(WO-[0-9]{8}-[0-9a-f]{4}) ]] && ticket=${BASH_REMATCH[1]} || ticket=""
  case $state in
    MERGED) say "$pr" "$ticket" already-merged "nothing to do"; return 0;;
    OPEN) ;;
    *) say "$pr" "$ticket" held "the pull request is ${state:-in an unknown state}, not open"; return 3;;
  esac
  [[ $head =~ ^[0-9a-f]{40}$ ]] || { GH_ERR="gh reported no head commit"; fail_io "$pr" "$ticket" "gh pr view"; return 4; }
  [ -n "$ticket" ] || { say "$pr" "" held "the title names no ticket (WO-YYYYMMDD-xxxx), so no record can be matched"; return 3; }

  # the gate: the newest review.passed 201 must name this head, and gate.sh heads_match must find a test.passed 201 on it
  review=$(jq -c --arg t "$ticket" '[.[] | select(.ticket == $t and .kind == "review.passed" and .code == 201)] | sort_by(.id) | last // empty' <<<"$(log_all)")
  [ -n "$review" ] || { say "$pr" "$ticket" held "no review.passed 201 for the ticket"; return 3; }
  rid=$(jq -r .id <<<"$review"); rsha=$(jq -r '.sha // empty' <<<"$review")
  [ -n "$rsha" ] || { say "$pr" "$ticket" held "review.passed $rid carries no sha"; return 3; }
  paths=$("$GATE" same-head --repo "$GIT_REPO" "$rsha" "$head" 2>"$ERRF"); rc=$?
  case $rc in
    0) ;;
    1) say "$pr" "$ticket" held "review.passed $rid names ${rsha:0:12}, the head is ${head:0:12}; they differ in: $(tr '\n' ' ' <<<"$paths" | cut -c1-100)"; return 3;;
    *) GH_ERR=$(tail -c 300 "$ERRF" | tr '\n' ' '); fail_io "$pr" "$ticket" "gate.sh same-head"; return 4;;
  esac
  out=$("$GATE" when heads_match --repo "$GIT_REPO" --id "$rid" 2>"$ERRF"); rc=$?
  case $rc in
    0) ;;
    1) say "$pr" "$ticket" held "$out"; return 3;;
    *) GH_ERR=$(tail -c 300 "$ERRF" | tr '\n' ' '); fail_io "$pr" "$ticket" "gate.sh when heads_match"; return 4;;
  esac

  [ "$mergeable" != CONFLICTING ] || { post_conflict "$pr" "$ticket" "$head"; return $?; }

  # the merge: GitHub refuses it if the head moved since we read it; a hold written since the pass began refuses it here
  refuse_on_hold "$pr" "$ticket" || return 3
  while :; do
    out=$(cd "$GIT_REPO" && gh pr merge "$pr" --squash --match-head-commit "$head" 2>&1); rc=$?
    [ "$rc" -ne 0 ] || break
    GH_ERR=$(printf '%s' "$out" | tail -c 300 | tr '\n' ' ')
    gh_retry pr view "$pr" --json state,headRefOid,mergeable || { fail_io "$pr" "$ticket" "gh pr view after a refused merge"; return 4; }
    mstate=$(jq -r '.state // empty' <<<"$GH_OUT"); mergeable=$(jq -r '.mergeable // "UNKNOWN"' <<<"$GH_OUT")
    [ "$mstate" = MERGED ] && break
    if [ "$(jq -r '.headRefOid // empty' <<<"$GH_OUT")" != "$head" ]; then
      say "$pr" "$ticket" held "the head moved from ${head:0:12} while merging; the next pass checks the new head"; return 3
    fi
    if [ "$mergeable" = CONFLICTING ]; then post_conflict "$pr" "$ticket" "$head"; return $?; fi
    if [ "$n" -ge "$RETRIES" ]; then fail_io "$pr" "$ticket" "gh pr merge"; return 4; fi
    nap "$n"; n=$((n + 1))
  done
  merge_sha "$pr" || { fail_io "$pr" "$ticket" "gh pr view for the merge commit"; return 4; }
  post_merged "$pr" "$ticket" "$head" "$MERGE_SHA"
}

# a hold on merges: nothing is merged and no gh call is made (--all names no pull request, so its line says PR 0)
if [ "$ALL_FLAG" = 0 ]; then refuse_on_hold "$PR" "" || exit 3; else refuse_on_hold 0 "" || exit 3; fi
if [ "$ALL_FLAG" = 0 ]; then do_pr "$PR"; exit $?; fi
gh_retry pr list --state open --limit 200 --json number || { fail_io 0 "" "gh pr list"; exit 4; }
mapfile -t NUMS < <(jq -r 'map(.number) | sort | .[]' <<<"$GH_OUT" 2>/dev/null)
for p in "${NUMS[@]}"; do
  do_pr "$p"; rc=$?
  [ "$rc" -ne 4 ] || exit 4
done
exit 0
