#!/usr/bin/env bash
# merge-hold.sh (WO-20261013-2d35, AC-H1, cause l): line/bin/merge.sh refuses to merge while the merge hold file exists.
#   hold on, --pr   exit 3, no gh pr merge, no gh call at all, ONE blocked 423 to the orchestrator that names the hold's reason
#   hold on, rerun  the same hold posts nothing more (the patrol tick reruns every minute)
#   hold on, --all  exit 3, no gh call, nothing merged, one line with PR 0
#   hold appears   mid-pass (the file written while gh pr view runs): the merge is refused just before gh pr merge
#   odd holds      a file that is not JSON still holds, with the reason "unreadable"
#   hold lifted    the file removed: the same pull request merges, one merged 200
# Self-wrapping like merge.test.sh: run bare it re-runs itself in Podman through line/tests/run.sh.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then exec env CASES=merge-hold bash "$HERE/../run.sh"; fi
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}
W=${COQ_CASE_WORK:-$(mktemp -d /tmp/coq-merge-hold-XXXX)}; mkdir -p "$W/bin" "$W/gh" "$W/state"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" GH_FAKE_DIR="$W/gh" MERGE_BACKOFF_SECONDS=0
D=$W/gh; RECS=$W/state/records/2026/10; RUN=$W/state/run; HOLD=$RUN/merge-hold.json; mkdir -p "$RECS" "$RUN"

# ---- a fake gh: pr view, pr merge (always works), pr list; every call is logged ----
cat > "$W/bin/gh" <<'FAKE'
#!/usr/bin/env bash
D=$GH_FAKE_DIR; echo "$*" >> "$D/calls.log"
case "$1 $2" in
  "pr view")
    n=$3; fields=""; while [ $# -gt 0 ]; do [ "$1" != --json ] || fields=$2; shift; done
    # GH_FAKE_HOLD_ON_VIEW: the hold appears while the pass is reading the pull request (the mid-pass case)
    if [ -n "${GH_FAKE_HOLD_ON_VIEW:-}" ] && [ ! -e "$GH_FAKE_HOLD_ON_VIEW" ]; then cp "$D/hold.json" "$GH_FAKE_HOLD_ON_VIEW"; fi
    jq --arg f "$fields" '($f | split(",")) as $k | with_entries(select(.key as $x | $k | index($x)))' "$D/pr-$n.json" ;;
  "pr merge")
    n=$3; jq '.state = "MERGED" | .mergeCommit = {oid: "dddddddddddddddddddddddddddddddddddddddd"}' "$D/pr-$n.json" > "$D/pr-$n.json.tmp" && mv "$D/pr-$n.json.tmp" "$D/pr-$n.json"; echo merged ;;
  "pr list") jq -c 'map({number: .})' "$D/open.json" ;;
  *) echo "fake gh: unexpected: $*" >&2; exit 1 ;;
esac
FAKE
chmod +x "$W/bin/gh"

G=$W/git; git init -q "$G"; ( cd "$G" && echo a > f && git add f && git commit -qm A )
B=$(git -C "$G" rev-parse HEAD); B12=${B:0:12}

pr() { jq -n --argjson n "$1" --arg t "$2 - a fixture ticket" --arg h "$B" '{number:$n, state:"OPEN", title:$t, headRefOid:$h, mergeable:"MERGEABLE", mergeCommit:null}' > "$D/pr-$1.json"; }
seq_n=0
rec() {
  seq_n=$((seq_n + 1)); local id; id=$(printf '20261013T10%04dZ-%s-t%04d' "$seq_n" "$1" "$seq_n")
  jq -n --arg id "$id" --argjson code "$1" --arg kind "$2" --arg t "$3" --arg sha "$4" \
    '{schema_version:"1.0.0", id:$id, at:"2026-10-13T10:00:00Z", code:$code, seat:"fixture", kind:$kind, ticket:$t, sha:$sha, note:"", evidence:[], observations:[]}' \
    > "$RECS/$(printf '202610131000%02d' "$seq_n")-$2-$3.json"
}
gate201() { rec 100 pr.opened "$1" "$B12"; rec 201 test.passed "$1" "$B12"; rec 201 review.passed "$1" "$B12"; }
write_hold() { jq -n --arg sha "$B" --arg reason "main ${B12} is red: ${2:-unit} failed; merges are held until a green verify of it or a later main" \
  '{schema_version:"1.0.0", sha:$sha, at:"2026-10-13T10:00:00Z", prs:[94], suites:["unit"], logs:[], reason:$reason}' > "$1"; }
all_recs() { find "$W/state/records" -name '*.json' -exec cat {} + 2>/dev/null; }
posted() { all_recs | jq -s --arg k "$1" '[.[] | select(.seat == "merge-script" and .kind == $k)] | length'; }
# BREADCRUMB 2026-10-13 - PR 144 rework (WO-20261013-2d35). What broke: the "note says unreadable" assertion (below) failed 2 runs in 6
#   standalone and once in the full suite, because it read posted_field blocked note, which is `sort_by(.id) | last`. A record id is
#   <UTC second>-<code>-<random suffix> (events/bin/event.sh), so the first hold's 423 and the "unreadable" hold's 423, posted in the
#   same second, sort by the random suffix and the "last" one is either. Why this fix: ask for the record by what it says
#   (posted_note_count) instead of by an order the ids cannot give. Rejected: sleeping a second between the two holds (it slows the
#   case and only narrows the window) and sorting by file name or `at` (also one-second resolution). Cost: none; the other
#   posted_field callers read the only blocked record that exists at that point.
posted_note_count() { all_recs | jq -s --arg k "$1" --arg p "$2" '[.[] | select(.seat == "merge-script" and .kind == $k and (.note | test($p)))] | length'; }
posted_field() { all_recs | jq -rs --arg k "$1" --arg f "$2" '[.[] | select(.seat == "merge-script" and .kind == $k)] | sort_by(.id) | last | .[$f] // empty'; }
gh_calls() { wc -l < "$D/calls.log" | tr -d ' '; }
mergecalls() { grep -c "^pr merge $1 " "$D/calls.log" || true; }
merge() { bash "$REPO/line/bin/merge.sh" --repo "$G" "$@"; }
: > "$D/calls.log"

T=WO-20261013-aa11; pr 11 $T; gate201 $T
echo "-- AC-H1: the hold file is present: merge.sh --pr merges nothing and posts one 423"
write_hold "$HOLD"
out=$(merge --pr 11 2>"$W/err"); rc=$?
assert_eq "exit 3" "$rc" 3
assert_eq "no gh pr merge" "$(mergecalls 11)" 0
assert_eq "no gh call at all (the hold is read before gh)" "$(gh_calls)" 0
assert_eq "no merged record" "$(posted merged)" 0
assert_eq "one blocked record" "$(posted blocked)" 1
assert_eq "it is code 423" "$(posted_field blocked code)" 423
assert_eq "to the orchestrator lane" "$(posted_field blocked to)" orchestrator
assert_eq "it names the hold's sha" "$(posted_field blocked sha)" "$B"
assert_match "its note names the hold's reason" "$(posted_field blocked note)" "main $B12 is red: unit failed"
assert_match "the line says held and names the reason" "$out" "^PR 11 - held: the merge hold is on: main $B12 is red"

echo "-- a rerun under the same hold posts nothing more (the patrol runs every minute)"
out=$(merge --pr 11 2>&1); assert_eq "exit 3 again" "$?" 3
assert_eq "still one blocked record" "$(posted blocked)" 1
assert_eq "still no gh pr merge" "$(mergecalls 11)" 0

echo "-- --all under the hold: exit 3, no gh call, nothing merged, still one 423"
echo '[11]' > "$D/open.json"
out=$(merge --all 2>"$W/err"); rc=$?
assert_eq "exit 3" "$rc" 3
assert_eq "no gh call at all, not even pr list" "$(gh_calls)" 0
assert_eq "still one blocked record" "$(posted blocked)" 1
assert_match "one line, for PR 0" "$out" "^PR 0 - held: the merge hold is on"
out=$(merge --pr 11 --json 2>&1); assert_eq "json: outcome held" "$(jq -r .outcome <<<"$out")" held

echo "-- a hold file that is not JSON still holds; its reason is 'unreadable'"
echo 'not json' > "$HOLD"
out=$(merge --pr 11 2>&1); assert_eq "exit 3" "$?" 3
assert_eq "no gh pr merge" "$(mergecalls 11)" 0
assert_eq "a second blocked record, for the new reason" "$(posted blocked)" 2
assert_eq "the new blocked record's note says unreadable" "$(posted_note_count blocked 'unreadable or empty')" 1

echo "-- AC-H1: the hold lifted: the same pull request merges, one merged 200"
rm -f "$HOLD"
out=$(merge --pr 11 2>"$W/err"); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "gh pr merge ran once" "$(mergecalls 11)" 1
assert_eq "one merged record" "$(posted merged)" 1
assert_eq "no further blocked record" "$(posted blocked)" 2

echo "-- the hold written during the pass: refused just before gh pr merge"
T=WO-20261013-bb12; pr 12 $T; gate201 $T; write_hold "$D/hold.json" lint   # a different reason: the 423 for the first hold is deduped, this one is new
before=$(posted blocked)
out=$(GH_FAKE_HOLD_ON_VIEW="$HOLD" merge --pr 12 2>"$W/err"); rc=$?
assert_eq "exit 3" "$rc" 3
assert_eq "the pull request was read" "$(grep -c '^pr view 12 ' "$D/calls.log")" 1
assert_eq "gh pr merge was not called for it" "$(mergecalls 12)" 0
assert_eq "one more blocked record" "$(( $(posted blocked) - before ))" 1
assert_match "the line says held" "$out" "^PR 12 $T held: the merge hold is on"
rm -f "$HOLD"

echo "-- no hold: --all merges as before"
T=WO-20261013-cc13; pr 13 $T; gate201 $T; echo '[13]' > "$D/open.json"
out=$(merge --all 2>"$W/err"); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "13 was merged" "$(mergecalls 13)" 1
case_done
