#!/usr/bin/env bash
# merge.test.sh (WO-20261013-f6ae, AC-H1 to AC-H3): line/bin/merge.sh against a fake gh and fixture records, in a scratch state root.
#   merged     201s on the newest head: gh pr merge --squash --match-head-commit HEAD is called once, one merged 200 with the merge sha
#   rerun      the same pull request again: nothing merged, nothing posted
#   held       201s on an older head, a test on another head, no review at all, a closed pull request, no ticket in the title:
#              nothing merged, nothing posted, exit 3
#   conflict   gh says CONFLICTING, or the merge is refused and gh then says CONFLICTING: merge.conflict 409 to the worker, once per head
#   moved      the head moves between the read and the merge: held, nothing posted
#   io         a gh call that never works: three attempts, one blocked 423 to the orchestrator, exit 4
#   --all      one pass over the open pull requests
# Self-wrapping: run bare (bash line/tests/cases/merge.test.sh) it re-runs itself in Podman through line/tests/run.sh; make -C line test
# runs it inside the container with the rest of the suite.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then exec env CASES=merge.test bash "$HERE/../run.sh"; fi
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}
W=${COQ_CASE_WORK:-$(mktemp -d /tmp/coq-merge-XXXX)}; mkdir -p "$W/bin" "$W/gh" "$W/state"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" GH_FAKE_DIR="$W/gh" MERGE_BACKOFF_SECONDS=0
D=$W/gh; RECS=$W/state/records/2026/10; mkdir -p "$RECS"

# ---- a fake gh: pr view (only the fields asked for), pr merge (mode per pull request), pr list ----
cat > "$W/bin/gh" <<'FAKE'
#!/usr/bin/env bash
D=$GH_FAKE_DIR; echo "$*" >> "$D/calls.log"
mergesha() { printf 'e%.0s' {1..32}; printf '%08d' "$1"; }
set_field() { jq --argjson v "$2" ".$1 = \$v" "$D/pr-$3.json" > "$D/pr-$3.json.tmp" && mv "$D/pr-$3.json.tmp" "$D/pr-$3.json"; }
case "$1 $2" in
  "pr view")
    n=$3; [ ! -e "$D/view-fail-$n" ] || { echo "gh: HTTP 502 Bad Gateway" >&2; exit 1; }
    [ -f "$D/pr-$n.json" ] || { echo "gh: no pull request $n" >&2; exit 1; }
    fields=""; while [ $# -gt 0 ]; do [ "$1" != --json ] || fields=$2; shift; done
    jq --arg f "$fields" '($f | split(",")) as $k | with_entries(select(.key as $x | $k | index($x)))' "$D/pr-$n.json" ;;
  "pr merge")
    n=$3; squash=0; match=""; shift 3
    while [ $# -gt 0 ]; do case $1 in --squash) squash=1; shift;; --match-head-commit) match=$2; shift 2;; *) shift;; esac; done
    [ "$squash" = 1 ] || { echo "gh: this fake only squashes" >&2; exit 1; }
    head=$(jq -r .headRefOid "$D/pr-$n.json")
    [ "$match" = "$head" ] || { echo "GraphQL: Head branch was modified. Review and try the merge again. (mergePullRequest)" >&2; exit 1; }
    case "$(cat "$D/merge-$n.mode" 2>/dev/null || echo ok)" in
      ok) set_field state '"MERGED"' "$n"; set_field mergeCommit "{\"oid\":\"$(mergesha "$n")\"}" "$n"; echo "merged" ;;
      conflict) set_field mergeable '"CONFLICTING"' "$n"; echo "GraphQL: Pull Request is not mergeable (mergePullRequest)" >&2; exit 1 ;;
      moved) set_field headRefOid '"cccccccccccccccccccccccccccccccccccccccc"' "$n"; echo "GraphQL: Head branch was modified. (mergePullRequest)" >&2; exit 1 ;;
      fail) echo "gh: HTTP 502 Bad Gateway" >&2; exit 1 ;;
    esac ;;
  "pr list")
    [ ! -e "$D/list-fail" ] || { echo "gh: HTTP 502 Bad Gateway" >&2; exit 1; }
    jq -c 'map({number: .})' "$D/open.json" ;;
  *) echo "fake gh: unexpected: $*" >&2; exit 1 ;;
esac
FAKE
chmod +x "$W/bin/gh"

# ---- a scratch git repo with two commits that differ outside events/: A is the old head, B the new one ----
G=$W/git; git init -q "$G"; ( cd "$G" && echo a > f && git add f && git commit -qm A && echo b > f && git commit -qam B )
A=$(git -C "$G" rev-parse HEAD~1); B=$(git -C "$G" rev-parse HEAD); B12=${B:0:12}; A12=${A:0:12}

# ---- fixtures ----
# pr N TICKET [STATE] [MERGEABLE] [TITLE]: the pull request gh will show, head B
pr() {
  local title=${5-"$2 - a fixture ticket"}
  jq -n --argjson n "$1" --arg t "$title" --arg s "${3:-OPEN}" --arg m "${4:-MERGEABLE}" --arg h "$B" \
    '{number:$n, state:$s, title:$t, headRefOid:$h, mergeable:$m, mergeCommit:null}' > "$D/pr-$1.json"
}
seq_n=0
# rec CODE KIND TICKET SHA: a record file as the writer lays it out; ids rise with the call order so the gate sees test before review
rec() {
  seq_n=$((seq_n + 1)); local id; id=$(printf '20261013T10%04dZ-%s-t%04d' "$seq_n" "$1" "$seq_n")
  jq -n --arg id "$id" --argjson code "$1" --arg kind "$2" --arg t "$3" --arg sha "$4" \
    '{schema_version:"1.0.0", id:$id, at:"2026-10-13T10:00:00Z", code:$code, seat:"fixture", kind:$kind, ticket:$t, sha:$sha, note:"", evidence:[], observations:[]}' \
    > "$RECS/$(printf '202610131000%02d' "$seq_n")-$2-$3.json"
}
gate201() { rec 100 pr.opened "$1" "$2"; rec 201 test.passed "$1" "$3"; rec 201 review.passed "$1" "$4"; }   # gate201 TICKET OPENED TEST REVIEW
mergecalls() { grep -c "^pr merge $1 " "$D/calls.log" || true; }
# posted KIND [PR]: how many records merge.sh posted of the kind (its seat is merge-script)
all_recs() { find "$W/state/records" -name '*.json' -exec cat {} + 2>/dev/null; }   # not $RECS: event.sh files by the clock's month
posted() { all_recs | jq -s --arg k "$1" --arg pr "${2:-}" '[.[] | select(.seat == "merge-script" and .kind == $k and ($pr == "" or (.pr | tostring) == $pr))] | length'; }
posted_field() { all_recs | jq -rs --arg k "$1" --argjson pr "$2" --arg f "$3" '[.[] | select(.seat == "merge-script" and .kind == $k and .pr == $pr)] | last | .[$f] // empty'; }
merge() { bash "$REPO/line/bin/merge.sh" --repo "$G" "$@"; }
: > "$D/calls.log"

echo "-- AC-H1: 201s on the newest head: one squash merge with --match-head-commit, one merged 200 with the merge sha"
T=WO-20261013-aa11; pr 11 $T; gate201 $T "$B12" "$B12" "$B12"
out=$(merge --pr 11 2>"$W/err"); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "gh pr merge ran once, squash, matching the head" "$(grep -cFx "pr merge 11 --squash --match-head-commit $B" "$D/calls.log")" 1
assert_eq "gh pr merge ran once and only once" "$(mergecalls 11)" 1
assert_eq "exactly one merged record" "$(posted merged 11)" 1
assert_eq "it is code 200" "$(posted_field merged 11 code)" 200
MS=$(printf 'e%.0s' {1..32})00000011
assert_eq "it carries the merge sha" "$(posted_field merged 11 sha)" "$MS"
assert_eq "it carries the ticket" "$(posted_field merged 11 ticket)" "$T"
assert_eq "it is addressed to the merger" "$(posted_field merged 11 to)" merger
assert_match "the line says merged" "$out" "^PR 11 $T merged:"
assert_eq "nothing else was posted" "$(posted merge.conflict)$(posted blocked)" 00

echo "-- AC-H2: a rerun after the merge posts nothing and merges nothing"
out=$(merge --pr 11 2>"$W/err"); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "still one gh pr merge" "$(mergecalls 11)" 1
assert_eq "still one merged record" "$(posted merged 11)" 1
assert_match "the line says already-merged" "$out" "already-merged"

echo "-- AC-H2: 201s on an older head: nothing merged, nothing posted, exit 3"
T=WO-20261013-ab12; pr 12 $T; gate201 $T "$A12" "$A12" "$A12"
out=$(merge --pr 12 2>"$W/err"); rc=$?
assert_eq "exit 3" "$rc" 3
assert_eq "no gh pr merge" "$(mergecalls 12)" 0
assert_eq "nothing posted for it" "$(posted merged 12)$(posted merge.conflict 12)$(posted blocked 12)" 000
assert_match "the line says held and names the heads" "$out" "held: review.passed .* names $A12, the head is ${B:0:12}"

echo "-- held: no review at all, a test on another head, a closed pull request, a title with no ticket"
pr 13 WO-20261013-ac13
out=$(merge --pr 13 2>&1); assert_eq "no records: exit 3" "$?" 3; assert_match "says so" "$out" "no review.passed 201"
T=WO-20261013-ad14; pr 14 $T; gate201 $T "$B12" "$A12" "$B12"
out=$(merge --pr 14 2>&1); assert_eq "review on B, test on A: exit 3" "$?" 3; assert_match "gate.sh says the test differs" "$out" "held: test.passed .* on $A12"
pr 20 WO-20261013-ae20 CLOSED
out=$(merge --pr 20 2>&1); assert_eq "closed: exit 3" "$?" 3; assert_match "says so" "$out" "CLOSED, not open"
pr 21 "" OPEN MERGEABLE "a title with no ticket"
out=$(merge --pr 21 2>&1); assert_eq "no ticket in the title: exit 3" "$?" 3; assert_match "says so" "$out" "names no ticket"
assert_eq "none of them was merged" "$(mergecalls 13)$(mergecalls 14)$(mergecalls 20)$(mergecalls 21)" 0000
assert_eq "none of them posted anything" "$(posted merged)" 1

echo "-- already merged by someone else: exit 0, nothing posted"
pr 19 WO-20261013-af19 MERGED
out=$(merge --pr 19 2>&1); assert_eq "exit 0" "$?" 0; assert_eq "no gh pr merge" "$(mergecalls 19)" 0; assert_eq "no merged record" "$(posted merged 19)" 0

echo "-- AC-H2: a conflict gh already reports: no merge attempt, merge.conflict 409 to the worker, once per head"
T=WO-20261013-ba15; pr 15 $T OPEN CONFLICTING; gate201 $T "$B12" "$B12" "$B12"
out=$(merge --pr 15 2>"$W/err"); rc=$?
assert_eq "exit 5" "$rc" 5
assert_eq "no gh pr merge" "$(mergecalls 15)" 0
assert_eq "one merge.conflict" "$(posted merge.conflict 15)" 1
assert_eq "code 409" "$(posted_field merge.conflict 15 code)" 409
assert_eq "to the worker lane" "$(posted_field merge.conflict 15 to)" worker
assert_eq "it names the head" "$(posted_field merge.conflict 15 sha)" "$B"
assert_eq "it names the ticket" "$(posted_field merge.conflict 15 ticket)" "$T"
out=$(merge --pr 15 2>&1); assert_eq "a rerun on the same head: exit 5" "$?" 5
assert_eq "a rerun posts nothing more" "$(posted merge.conflict 15)" 1
assert_match "and says it was posted already" "$out" "already posted"

echo "-- AC-H2: a conflict found only when the merge is refused: gh says CONFLICTING afterwards"
T=WO-20261013-bb16; pr 16 $T; gate201 $T "$B12" "$B12" "$B12"; echo conflict > "$D/merge-16.mode"
out=$(merge --pr 16 2>"$W/err"); rc=$?
assert_eq "exit 5" "$rc" 5
assert_eq "the merge was tried once, not retried" "$(mergecalls 16)" 1
assert_eq "one merge.conflict" "$(posted merge.conflict 16)" 1
assert_eq "and no merged record" "$(posted merged 16)" 0

echo "-- the head moves between the read and the merge: held, nothing posted"
T=WO-20261013-bc17; pr 17 $T; gate201 $T "$B12" "$B12" "$B12"; echo moved > "$D/merge-17.mode"
out=$(merge --pr 17 2>"$W/err"); rc=$?
assert_eq "exit 3" "$rc" 3
assert_eq "the merge was tried once" "$(mergecalls 17)" 1
assert_eq "nothing posted" "$(posted merged 17)$(posted merge.conflict 17)$(posted blocked 17)" 000
assert_match "says the head moved" "$out" "head moved"

echo "-- a gh call that never works: three attempts, one blocked 423 to the orchestrator, exit 4"
: > "$D/calls.log"; T=WO-20261013-bd18; pr 18 $T; touch "$D/view-fail-18"
out=$(merge --pr 18 2>"$W/err"); rc=$?
assert_eq "exit 4" "$rc" 4
assert_eq "gh pr view was tried three times" "$(grep -c '^pr view 18 ' "$D/calls.log")" 3
assert_eq "one blocked record" "$(posted blocked 18)" 1
assert_eq "code 423" "$(posted_field blocked 18 code)" 423
assert_eq "to the orchestrator" "$(posted_field blocked 18 to)" orchestrator
assert_match "the line says failed" "$out" "failed"
: > "$D/calls.log"; T=WO-20261013-be22; pr 22 $T; gate201 $T "$B12" "$B12" "$B12"; echo fail > "$D/merge-22.mode"
out=$(merge --pr 22 2>"$W/err"); rc=$?
assert_eq "a merge that always fails: exit 4" "$rc" 4
assert_eq "gh pr merge was tried three times" "$(mergecalls 22)" 3
assert_eq "one blocked record for it" "$(posted blocked 22)" 1
assert_eq "and nothing merged" "$(posted merged 22)" 0

echo "-- --all: one pass over the open pull requests"
: > "$D/calls.log"
pr 30 WO-20261013-ca30; gate201 WO-20261013-ca30 "$B12" "$B12" "$B12"
pr 31 WO-20261013-cb31
pr 32 WO-20261013-cc32; gate201 WO-20261013-cc32 "$B12" "$B12" "$B12"
echo '[32,30,31]' > "$D/open.json"   # bare numbers; the fake wraps them the way gh does
out=$(merge --all 2>"$W/err"); rc=$?
assert_eq "exit 0 though one is held" "$rc" 0
assert_eq "30 was merged" "$(mergecalls 30)" 1; assert_eq "32 was merged" "$(mergecalls 32)" 1; assert_eq "31 was not" "$(mergecalls 31)" 0
assert_eq "one merged record each" "$(posted merged 30)$(posted merged 32)$(posted merged 31)" 110
assert_eq "lowest number first" "$(grep -o '^PR [0-9]*' <<<"$out" | tr '\n' ' ')" "PR 30 PR 31 PR 32 "
assert_match "31 is held" "$out" "^PR 31 WO-20261013-cb31 held"
out=$(merge --all 2>&1); assert_eq "a second pass: exit 0" "$?" 0
assert_eq "merges nothing more" "$(mergecalls 30)$(mergecalls 32)" 11
echo "-- --all: gh pr list never works: one blocked 423, exit 4"
before=$(posted blocked); lb=$(grep -c '^pr list' "$D/calls.log"); touch "$D/list-fail"
out=$(merge --all 2>"$W/err"); rc=$?
assert_eq "exit 4" "$rc" 4
assert_eq "one more blocked record" "$(( $(posted blocked) - before ))" 1
assert_eq "gh pr list was tried three times" "$(( $(grep -c '^pr list' "$D/calls.log") - lb ))" 3

echo "-- --json and usage"
rm -f "$D/list-fail"
out=$(merge --pr 11 --json 2>&1); assert_eq "json: pr" "$(jq -r .pr <<<"$out")" 11; assert_eq "json: outcome" "$(jq -r .outcome <<<"$out")" already-merged
merge >/dev/null 2>&1; assert_eq "no arguments: exit 2" "$?" 2
merge --pr abc >/dev/null 2>&1; assert_eq "a bad number: exit 2" "$?" 2
merge --pr 1 --all >/dev/null 2>&1; assert_eq "--pr with --all: exit 2" "$?" 2

case_done
