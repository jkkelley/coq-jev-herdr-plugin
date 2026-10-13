#!/usr/bin/env bash
# verify-main.sh case (WO-20261013-9bdd, AC-H1): line/bin/verify-main.sh against stub suites, a fake gh and a scratch git repo.
#   green      every suite exits 0: exit 0, one verified 200 per pull request (sha, pr, ticket), no hold, no worktree left
#   checkout   the suites run in a detached worktree at the sha asked for, outside the repository
#   red        one suite exits 1: exit 3, every suite still ran, one rejected 422 naming it with its log, the hold file, no verified
#   red-multi  two pull requests on a red main: still one rejected, carrying neither pr nor ticket, the note naming both
#   lift       a green run of the held sha removes the hold; a green run of an OLDER sha leaves it
#   timeout    a suite past VERIFY_SUITE_TIMEOUT is red
#   io         an unknown sha: three tries, one blocked 500, no verified, exit 4; a gh that never answers: verdict posted, then the 500
#   usage      no --pr is exit 2
# No file is left in the repository: the scratch repo's status and worktree list are checked after every run.
# Self-wrapping: run bare (bash line/tests/cases/verify-main.sh) it re-runs itself in Podman through line/tests/run.sh; make -C line test
# runs it inside the container with the rest of the suite.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then exec env CASES=verify-main bash "$HERE/../run.sh"; fi
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}
W=${COQ_CASE_WORK:-$(mktemp -d /tmp/coq-verify-XXXX)}; mkdir -p "$W/bin" "$W/state" "$W/cache"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" COQ_CACHE="$W/cache" VERIFY_BACKOFF_SECONDS=0 GH_FAKE_DIR="$W"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# ---- a fake gh: pr view N --json title, and a switch that makes it fail ----
cat > "$W/bin/gh" <<'FAKE'
#!/usr/bin/env bash
[ ! -e "$GH_FAKE_DIR/gh.fail" ] || { echo "gh: HTTP 502 Bad Gateway" >&2; exit 1; }
[ "$1 $2" = "pr view" ] || { echo "fake gh: unexpected: $*" >&2; exit 1; }
printf '{"title":"WO-20261013-a%03d - a fixture ticket"}\n' "$3"
FAKE
chmod +x "$W/bin/gh"

# ---- a scratch repo with two commits: A (old) and B (new); f holds the commit's letter ----
G=$W/git; git init -q "$G"; ( cd "$G" && echo a > f && git add f && git commit -qm A && echo b > f && git commit -qam B )
A=$(git -C "$G" rev-parse HEAD~1); B=$(git -C "$G" rev-parse HEAD)

# ---- stub suites: alpha proves the checkout is the sha (f is the letter asked for) and leaves a marker; beta fails on demand ----
export VERIFY_SUITES
VERIFY_SUITES=$(printf 'alpha\ttest "$(cat f)" = "$(cat %s/want)" && pwd > %s/alpha.cwd\nbeta\ttest ! -e %s/beta.fail\n' "$W" "$W" "$W")
want() { printf '%s\n' "$1" > "$W/want"; }

all_recs() { find "$W/state/records" -name '*.json' -exec cat {} + 2>/dev/null; }
posted() { all_recs | jq -s --arg k "$1" '[.[] | select(.seat == "verify-script" and .kind == $k)] | length'; }   # posted KIND
field() { all_recs | jq -rs --arg k "$1" --arg f "$2" '[.[] | select(.seat == "verify-script" and .kind == $k)] | last | .[$f] // empty'; }   # field KIND FIELD
fieldpr() { all_recs | jq -rs --arg k "$1" --argjson pr "$2" --arg f "$3" '[.[] | select(.seat == "verify-script" and .kind == $k and .pr == $pr)] | first | .[$f] // empty'; }   # fieldpr KIND PR FIELD
clear_recs() { rm -rf "$W/state/records"; }
verify() { bash "$REPO/line/bin/verify-main.sh" --repo "$G" "$@"; }
HOLD=$W/state/run/merge-hold.json
repo_clean() { # repo_clean LABEL: no stray file in the repository, no leftover worktree entry or directory
  assert_eq "$1: git status is clean" "$(git -C "$G" status --porcelain)" ""
  assert_eq "$1: one worktree entry" "$(git -C "$G" worktree list | wc -l)" 1
  assert_eq "$1: no worktree directory in the cache" "$(find "$W/cache/verify" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)" 0
}

echo "-- green"
want b; rm -f "$W/beta.fail" "$W/alpha.cwd"
out=$(verify --sha "$B" --pr 12 --pr 13 2>&1); rc=$?
assert_eq "green exits 0" "$rc" 0
assert_eq "one verified 200 per pull request" "$(posted verified)" 2
assert_eq "no rejected" "$(posted rejected)" 0
assert_eq "verified carries the sha" "$(field verified sha)" "$B"
assert_eq "verified carries the code" "$(field verified code)" 200
assert_eq "verified carries pull request 12's ticket, read from its title" "$(fieldpr verified 12 ticket)" WO-20261013-a012
assert_eq "verified carries pull request 13's ticket, read from its title" "$(fieldpr verified 13 ticket)" WO-20261013-a013
assert_eq "verified goes to the orchestrator lane" "$(field verified to)" orchestrator
assert_no_file "green leaves no hold" "$HOLD"
assert_match "the outcome line says verified" "$out" 'verified'
cwd=$(cat "$W/alpha.cwd" 2>/dev/null)
assert_match "the suites ran in a worktree under the cache root" "$cwd" "^$W/cache/verify/"
assert_no_match "the worktree is not the repository" "$cwd" "^$G"
repo_clean green

echo "-- red"
clear_recs; : > "$W/beta.fail"; rm -f "$W/alpha.cwd"
out=$(verify --sha "$B" --pr 12 2>&1); rc=$?
assert_eq "red exits 3" "$rc" 3
assert_eq "one rejected" "$(posted rejected)" 1
assert_eq "no verified" "$(posted verified)" 0
assert_eq "rejected carries code 422" "$(field rejected code)" 422
assert_eq "rejected carries the pull request" "$(field rejected pr)" 12
assert_eq "rejected carries the ticket" "$(field rejected ticket)" WO-20261013-a012
assert_match "the note names the failing suite" "$(field rejected note)" 'beta failed'
assert_no_match "the note does not blame the green suite" "$(field rejected note)" 'alpha'
assert_eq "the evidence is the failing suite's log" "$(all_recs | jq -rs '[.[] | select(.kind == "rejected")] | last | .evidence | length')" 1
log=$(all_recs | jq -rs '[.[] | select(.kind == "rejected")] | last | .evidence[0]')
assert_file "the failing suite's log is under the state root" "$log"
assert_match "the log path is in the logs tree" "$log" "^$W/state/logs/verify-main/20[0-9][0-9]/[0-9][0-9]/[0-9]{14}-${B:0:12}-beta\.log$"
assert_match "the log records the exit code" "$(cat "$log")" '# exit 1'
assert_file "the green suite still ran (every suite runs)" "$W/alpha.cwd"
assert_file "the merge hold exists" "$HOLD"
assert_eq "the hold names the sha" "$(jq -r .sha "$HOLD")" "$B"
assert_eq "the hold names the failing suites" "$(jq -c .suites "$HOLD")" '["beta"]'
assert_eq "the hold names the pull requests" "$(jq -c .prs "$HOLD")" '[12]'
assert_match "the hold gives a reason" "$(jq -r .reason "$HOLD")" 'beta failed'
repo_clean red

echo "-- red with two pull requests"
clear_recs
out=$(verify --sha "$B" --pr 12 --pr 13 2>&1); rc=$?
assert_eq "exits 3" "$rc" 3
assert_eq "still one rejected" "$(posted rejected)" 1
assert_eq "rejected carries no pull request" "$(field rejected pr)" ""
assert_eq "rejected carries no ticket" "$(field rejected ticket)" ""
assert_match "the note names both pull requests" "$(field rejected note)" 'PR 12 13'
assert_eq "the hold names both pull requests" "$(jq -c .prs "$HOLD")" '[12,13]'
repo_clean red-multi

echo "-- the hold lifts only for the held sha or a descendant"
clear_recs; rm -f "$W/beta.fail"; want a
out=$(verify --sha "$A" --pr 11 2>&1); rc=$?
assert_eq "an older green sha exits 0" "$rc" 0
assert_file "an older green sha leaves the hold of the newer red one" "$HOLD"
assert_eq "the hold still names the newer sha" "$(jq -r .sha "$HOLD")" "$B"
assert_match "the run says why the hold stays" "$out" 'stays'
want b
out=$(verify --sha "$B" --pr 12 2>&1); rc=$?
assert_eq "the held sha, green, exits 0" "$rc" 0
assert_no_file "the held sha, green, lifts the hold" "$HOLD"
# a descendant lifts it too
: > "$W/beta.fail"; verify --sha "$A" --pr 11 >/dev/null 2>&1; rm -f "$W/beta.fail"
assert_file "(setup) a red older sha wrote a hold" "$HOLD"
out=$(verify --sha "$B" --pr 12 2>&1)
assert_no_file "a green descendant lifts the hold of an ancestor" "$HOLD"
repo_clean lift

echo "-- a suite past its timeout is red"
clear_recs
out=$(VERIFY_SUITES=$'slow\tsleep 5' VERIFY_SUITE_TIMEOUT=1 verify --sha "$B" --pr 12 2>&1); rc=$?
assert_eq "exits 3" "$rc" 3
assert_match "the note names the slow suite" "$(field rejected note)" 'slow failed'
log=$(all_recs | jq -rs '[.[] | select(.kind == "rejected")] | last | .evidence[0]')
assert_match "the log says it timed out" "$(cat "$log")" 'timed out after 1s'
rm -f "$HOLD"
repo_clean timeout

echo "-- io"
clear_recs; want b
out=$(verify --sha deadbeef --pr 12 2>&1); rc=$?
assert_eq "an unknown sha exits 4" "$rc" 4
assert_eq "one blocked 500" "$(posted blocked)" 1
assert_eq "the blocked code is 500" "$(field blocked code)" 500
assert_eq "no verified" "$(posted verified)" 0
assert_eq "no rejected" "$(posted rejected)" 0
assert_no_file "no hold from a run that never ran" "$HOLD"
clear_recs; : > "$W/gh.fail"
out=$(verify --sha "$B" --pr 12 2>&1); rc=$?
assert_eq "gh down exits 4" "$rc" 4
assert_eq "the verdict is still posted" "$(posted verified)" 1
assert_eq "posted without a ticket" "$(field verified ticket)" ""
assert_eq "and one blocked 500 follows" "$(posted blocked)" 1
rm -f "$W/gh.fail"
repo_clean io

echo "-- usage"
out=$(verify --sha "$B" 2>&1); rc=$?
assert_eq "no --pr exits 2" "$rc" 2
out=$(verify --pr 12 2>&1); rc=$?
assert_eq "no --sha exits 2" "$rc" 2

case_done
