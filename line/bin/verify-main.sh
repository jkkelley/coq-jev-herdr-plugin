#!/usr/bin/env bash
# verify-main.sh - the verify of main as code (SPEC-17 s-inventory; ticket WO-20261013-9bdd). It checks out the new main sha in a clean
# detached worktree outside the repository, runs lint and the factory, herdr, events and scheduler suites there, and posts one
# verified 200 per pull request when every suite is green, or one rejected 422 naming the failing suites when one is red. A rejected
# main writes the merge hold (cause j), which stays until a later green verify lifts it; a green one removes a hold that names this sha
# or an older one. The decision is the exit codes of the suites, so no seat makes it.
#
#   verify-main.sh --sha SHA --pr N [--pr N]... [--repo DIR] [--json]
# --sha is the merge commit on main, as merged 200 carries it. --pr is every pull request that landed in it (at least one).
# --repo DIR is the git checkout the worktree is cut from and gh runs in (default: the checkout this script is in); a sha it does not
# have yet is fetched from origin.
# Exit codes: 0 verified, 3 rejected (the verdict, the hold and the record are all written), 4 io (a step failed three times; one
# blocked 500 to the orchestrator lane, and no verified is ever posted), 2 usage. Branch on the code, not on the output.
#
# What it writes, all outside the repository (AGENTS.md, Law: runtime data never lives in git):
#   <logs tree>/verify-main/YYYY/MM/YYYYMMDDHHMMSS-<sha12>-<suite>.log   one log per suite
#   <run tree>/merge-hold.json                                            the hold: sha, at, prs, suites, logs, reason (cleared by a green run)
#   <cache root>/verify/<stamp>-<sha12>-<pid>/                            the worktree; removed on every exit, with its git worktree entry
#   <records tree>/...                                                    verified 200 / rejected 422 / blocked 500, through events/bin/event.sh
# Records go to the orchestrator lane. A pull request's ticket is read from its title (WO-YYYYMMDD-xxxx).
#
# The suites, one per line "name<TAB>command", run in the worktree with bash -c. VERIFY_SUITES replaces the list (the test case uses
# stubs). Knobs: VERIFY_RETRIES (attempts per io step, default 3), VERIFY_BACKOFF_SECONDS (sleep after attempt n is n times this,
# default 2), VERIFY_SUITE_TIMEOUT (seconds a suite may run before it counts as red, default 1800).
#
# BREADCRUMB 2026-10-13 - WO-20261013-9bdd. What broke: after a merge the verify of main was orchestrator hand work, and it was skipped or
#   carried by hand on 2026-10-12 and 2026-10-13 (AGENTS.md, Law: three loops, always). PR 94 then merged onto a red main because the
#   hold on merges was a ruling in prose (cause l). Why this fix: the verify is "run the suites at a sha", which needs no judgement, so a
#   script does it and the hold is a file that merge.sh can read (WO-20261013-2d35) instead of a sentence. Rejected: a verify seat (the
#   Haiku merger was the bottleneck merge.sh removed) and running the suites in the orchestrator's own checkout (the checkout moves,
#   so the result would not be about the sha). Choices that look arbitrary:
#   1. Every suite runs even after one fails. A red main is fixed by one ticket, and that ticket needs every red suite, not the first.
#      Cost: a red lint still pays for the container suites.
#   2. ONE rejected 422 per run, not one per pull request: the sha is red, not a pull request. With a single --pr the record carries that
#      pull request and its ticket, so the fix ticket can name it; with several the note lists them and the record carries neither.
#   3. A green run lifts the hold only when the held sha is the verified sha or an ancestor of it (git merge-base --is-ancestor). Verifies
#      can finish out of order, and an old green must never lift the hold a newer red wrote. Cost: a held sha this checkout cannot see
#      (not fetched) keeps the hold until a verify of a descendant fetches it; the hold is the safe side.
#   4. A suite that exceeds VERIFY_SUITE_TIMEOUT is red, exit 124 in its log, so a hung suite cannot leave main unverified for ever.
#   5. A verdict is never lost to a failed ticket lookup: the records are posted without --ticket and the run then exits 4 with the 500.
#   6. verified carries code 200, as the ticket orders. factory/config/routes.json has a verified row for 201 only, so until the
#      after-merge route ticket (WO-20261013-612d) says what consumes it, a 200 is an unmatched record; that is that ticket's to settle.
#   7. The checkout is `git worktree add --detach` under the cache root, not a treehouse slot. AGENTS.md (Where your workspace comes from)
#      forbids a hand-rolled worktree for an agent's workspace; this one belongs to no agent, lives for one run and is removed by the
#      script, so leasing a slot would hold a pool slot (and fail the verify when the pool is full) for a checkout nobody works in. The
#      ticket also orders "a clean detached worktree at SHA outside the repository". Cost: the cache root must have room for one checkout.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); SELF_REPO=$(cd "$HERE/../.." && pwd)
GIT_REPO=$SELF_REPO; SHA=""; PRS=(); JSON=0
SEAT=verify-script; RETRIES=${VERIFY_RETRIES:-3}; BACKOFF=${VERIFY_BACKOFF_SECONDS:-2}; SUITE_TIMEOUT=${VERIFY_SUITE_TIMEOUT:-1800}
die() { local c=$1; shift; printf 'verify-main: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
command -v git >/dev/null || die 4 "git is required"
command -v gh >/dev/null || die 4 "gh is required"
while [ $# -gt 0 ]; do case $1 in
  --sha) SHA=${2:-}; shift 2 || die 2 "--sha needs a commit";;
  --pr) [[ ${2:-} =~ ^[1-9][0-9]*$ ]] || die 2 "--pr needs a pull request number"; PRS+=("$2"); shift 2;;
  --json) JSON=1; shift;;
  --repo) GIT_REPO=$(cd "${2:?--repo needs a directory}" && pwd) || die 4 "no such --repo"; shift 2;;
  *) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac; done
[[ $SHA =~ ^[0-9a-f]{7,40}$ ]] || die 2 "give --sha as 7 to 40 lowercase hex characters"
[ "${#PRS[@]}" -gt 0 ] || die 2 "give at least one --pr N"
[[ $RETRIES =~ ^[1-9][0-9]*$ ]] || die 2 "VERIFY_RETRIES must be a positive integer"; [[ $BACKOFF =~ ^[0-9]+$ ]] || die 2 "VERIFY_BACKOFF_SECONDS must be a whole number"
[[ $SUITE_TIMEOUT =~ ^[1-9][0-9]*$ ]] || die 2 "VERIFY_SUITE_TIMEOUT must be a positive integer"
EVENT=$SELF_REPO/events/bin/event.sh
[ -x "$EVENT" ] || die 4 "events/bin/event.sh is missing beside this line/ tree"
# shellcheck source=../../bin/state-root.sh
. "$SELF_REPO/bin/state-root.sh" 2>/dev/null || die 4 "bin/state-root.sh missing (roadmap item A1)"
LOGS=$(coq_tree logs) && RUN=$(coq_tree run) && CACHE=$(coq_cache_root) || die 4 "the state root did not resolve; set COQ_STATE"

DEFAULT_SUITES=$'lint\tmake lint\nfactory\tmake -C factory test\nherdr\tmake -C herdr test\nevents\tbash events/tests/run.sh\nscheduler\tmake -C scheduler test'
SUITES=${VERIFY_SUITES:-$DEFAULT_SUITES}
ERRF=$(mktemp "${TMPDIR:-/tmp}/verify-main-err.XXXXXX") || die 4 "cannot make a temp file"
WT=""; GH_ERR=""
cleanup() { # the worktree goes on every exit, with its entry in the repository's .git/worktrees
  if [ -n "$WT" ]; then git -C "$GIT_REPO" worktree remove --force "$WT" >/dev/null 2>&1 || true; rm -rf "$WT"; git -C "$GIT_REPO" worktree prune >/dev/null 2>&1 || true; fi
  rm -f "$ERRF"
}
trap cleanup EXIT

say() { # say OUTCOME DETAIL
  if [ "$JSON" = 1 ]; then jq -nc --arg sha "$SHA" --arg o "$1" --arg d "$2" '{sha:$sha, outcome:$o, detail:$d}'; else printf 'verify %s %s: %s\n' "${SHA:0:12}" "$1" "$2"; fi
}
nap() { sleep $(( BACKOFF * $1 )); }
retry() { # retry CMD...: up to RETRIES attempts, stderr tail kept in GH_ERR; 0 when one worked
  local n=1 rc
  while :; do
    "$@" >/dev/null 2>"$ERRF"; rc=$?; GH_ERR=$(tail -c 300 "$ERRF" | tr '\n' ' ')
    [ "$rc" -ne 0 ] || return 0
    [ "$n" -lt "$RETRIES" ] || return "$rc"
    nap "$n"; n=$((n + 1))
  done
}
post() { retry "$EVENT" add --seat "$SEAT" --to orchestrator --sha "$SHA" "$@"; }
BLOCKED_POSTED=0
fail_io() { # fail_io WHAT: three attempts are spent. One blocked 500 to the orchestrator lane, then exit 4 with no verified ever posted.
  local note="verify-main gave up on ${SHA:0:12}: $1 ${GH_ERR}"; note=${note:0:240}
  if [ "$BLOCKED_POSTED" = 0 ]; then
    BLOCKED_POSTED=1; post --code 500 --kind blocked --note "$note" || printf 'verify-main: the blocked 500 could not be posted either: %s\n' "$GH_ERR" >&2
  fi
  say failed "$1 ${GH_ERR}"; exit 4
}

# ---- the sha, then a clean detached worktree at it ----
git -C "$GIT_REPO" rev-parse --git-dir >/dev/null 2>&1 || die 4 "--repo $GIT_REPO is not a git checkout"
if ! git -C "$GIT_REPO" cat-file -e "$SHA^{commit}" 2>/dev/null; then retry git -C "$GIT_REPO" fetch --quiet origin || fail_io "git fetch for $SHA"; fi
FULL=$(git -C "$GIT_REPO" rev-parse --verify "$SHA^{commit}" 2>"$ERRF") || { GH_ERR=$(tail -c 300 "$ERRF" | tr '\n' ' '); fail_io "git rev-parse of $SHA"; }
SHA=$FULL
read -r STAMP YM < <(date -u '+%Y%m%d%H%M%S %Y/%m')
WT=$CACHE/verify/$STAMP-${SHA:0:12}-$$
mkdir -p "$CACHE/verify" || fail_io "mkdir of $CACHE/verify"
retry git -C "$GIT_REPO" worktree add --detach "$WT" "$SHA" || { rm -rf "$WT"; WT=""; fail_io "git worktree add"; }

# ---- the suites: every one runs; a red or hung one is a name and a log ----
LOGDIR=$LOGS/verify-main/$YM; mkdir -p "$LOGDIR" || fail_io "mkdir of $LOGDIR"
FAILED=(); FAILLOGS=(); RAN=0
while IFS=$'\t' read -r name cmd; do
  [ -n "$name" ] || continue
  [[ $name =~ ^[a-z][a-z0-9-]*$ ]] && [ -n "$cmd" ] || die 2 "a suite is 'name<TAB>command', the name lowercase words joined by -; got '$name'"
  log=$LOGDIR/$STAMP-${SHA:0:12}-$name.log; RAN=$((RAN + 1))
  { printf '# verify-main %s suite %s: %s\n' "${SHA:0:12}" "$name" "$cmd"; } > "$log"
  ( cd "$WT" && timeout "$SUITE_TIMEOUT" bash -c "$cmd" ) >> "$log" 2>&1; rc=$?
  printf '# exit %s%s\n' "$rc" "$([ "$rc" -ne 124 ] || printf ' (timed out after %ss)' "$SUITE_TIMEOUT")" >> "$log"
  if [ "$rc" -ne 0 ]; then FAILED+=("$name"); FAILLOGS+=("$log"); fi
done <<<"$SUITES"
[ "$RAN" -gt 0 ] || die 2 "VERIFY_SUITES lists no suite"

# ---- a pull request's ticket, from its title ----
declare -A TICKET
LOOKUP_FAILED=0
for p in "${PRS[@]}"; do
  if retry bash -c 'cd "$1" && gh pr view "$2" --json title >"$3"' _ "$GIT_REPO" "$p" "$ERRF.title" && t=$(jq -r '.title // empty' "$ERRF.title" 2>/dev/null) && [[ $t =~ ^(WO-[0-9]{8}-[0-9a-f]{4}) ]]; then TICKET[$p]=${BASH_REMATCH[1]}
  else TICKET[$p]=""; LOOKUP_FAILED=1; LOOKUP_ERR=$GH_ERR; fi
done
rm -f "$ERRF.title"
tflag() { [ -z "${TICKET[$1]}" ] || printf '%s\n%s\n' --ticket "${TICKET[$1]}"; }   # tflag PR: the --ticket flag pair, or nothing

HOLD=$RUN/merge-hold.json
if [ "${#FAILED[@]}" -eq 0 ]; then
  # ---- green: lift a hold that names this sha or an older one, then one verified 200 per pull request ----
  if [ -f "$HOLD" ]; then
    held=$(jq -r '.sha // empty' "$HOLD" 2>/dev/null)
    if [ -n "$held" ] && { [ "$held" = "$SHA" ] || git -C "$GIT_REPO" merge-base --is-ancestor "$held" "$SHA" 2>/dev/null; }; then rm -f "$HOLD"
    else say note "the merge hold names ${held:0:12}, which is not this sha or an ancestor of it; it stays"; fi
  fi
  for p in "${PRS[@]}"; do
    mapfile -t tf < <(tflag "$p")
    post --code 200 --kind verified --pr "$p" "${tf[@]}" --note "main ${SHA:0:12} verified: $RAN suites green, PR $p" \
      || fail_io "the verified 200 for PR $p"
  done
  [ "$LOOKUP_FAILED" = 0 ] || { GH_ERR=$LOOKUP_ERR; fail_io "gh pr view for a ticket (verified was posted without it)"; }
  say verified "$RAN suites green; verified 200 posted for PR ${PRS[*]}"; exit 0
fi

# ---- red: the hold first (it is what stops the next merge), then one rejected 422 ----
names=$(IFS=,; printf '%s' "${FAILED[*]}")
reason="main ${SHA:0:12} is red: ${names} failed; merges are held until a green verify of it or a later main"
write_hold() {
  local tmp="$HOLD.tmp.$$"
  mkdir -p "$RUN" && jq -n --arg sha "$SHA" --arg at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" --arg reason "$reason" \
    --argjson prs "$(printf '%s\n' "${PRS[@]}" | jq -R 'tonumber' | jq -s .)" \
    --argjson suites "$(printf '%s\n' "${FAILED[@]}" | jq -R . | jq -s .)" --argjson logs "$(printf '%s\n' "${FAILLOGS[@]}" | jq -R . | jq -s .)" \
    '{schema_version:"1.0.0", sha:$sha, at:$at, prs:$prs, suites:$suites, logs:$logs, reason:$reason}' > "$tmp" && mv "$tmp" "$HOLD"
}
HOLD_FAILED=0; retry write_hold || { HOLD_FAILED=1; HOLD_ERR=$GH_ERR; }   # the verdict is posted either way; the 4 comes after it
ev=(); for l in "${FAILLOGS[@]}"; do ev+=(--evidence "$l"); done
pr_flags=(); note="main ${SHA:0:12} rejected: ${names} failed, logs under ${LOGDIR}; PR ${PRS[*]}"
if [ "${#PRS[@]}" -eq 1 ]; then mapfile -t tf < <(tflag "${PRS[0]}"); pr_flags=(--pr "${PRS[0]}" "${tf[@]}"); fi
post --code 422 --kind rejected "${pr_flags[@]}" "${ev[@]}" --note "${note:0:240}" || fail_io "the rejected 422"
[ "$HOLD_FAILED" = 0 ] || { GH_ERR=$HOLD_ERR; fail_io "writing the merge hold $HOLD (rejected was posted)"; }
[ "$LOOKUP_FAILED" = 0 ] || { GH_ERR=$LOOKUP_ERR; fail_io "gh pr view for a ticket (rejected was posted without it)"; }
say rejected "$names failed; merge hold written to $HOLD"; exit 3
