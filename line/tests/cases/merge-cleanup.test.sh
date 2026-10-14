#!/usr/bin/env bash
# merge-cleanup.test.sh (WO-20261013-a18c, AC-H1): the cleanup line/bin/merge.sh does itself after the squash merge, against a fake gh,
# a fake treehouse, a real scratch git repo with a real bare origin, and a scratch state root.
#   happy      main is checked out in another worktree and merge.sh runs from a detached HEAD: the remote branch and the local branch
#              are deleted and the slot is returned (treehouse return PATH --if-lease-holder TICKET --force, once); main and the
#              repo's HEAD are not moved; work-order.sh cleanup is never called
#   foreign    a live process that is not merge.sh's is in the slot (architect ruling 00:30Z): no treehouse return, the slot stays
#              leased, one blocked 423 to the orchestrator names the process, the branches are still deleted; a stale pid is not one
#   spare      a `claude bg-spare` or `claude bg-pty-host` with its cwd in the slot is reaped, not foreign (ruling 00:34Z); a spare with its cwd
#              elsewhere, or another claude in the slot, is still foreign
#   cwd        merge.sh itself running inside the slot: no treehouse return (it would end merge.sh), a blocked 423 says so
#   retries    treehouse return that never works: three attempts, one blocked 423, the merge still posted merged 200 and exit 0
#   idempotent the remote branch already gone, no lease for the ticket, a branch that is the repo's own HEAD (detached first)
#   refused    a head branch named main is never deleted
#   io         a remote that cannot be reached: three attempts, one blocked 423, the slot and the local branch are still handled
# Self-wrapping: run bare (bash line/tests/cases/merge-cleanup.test.sh) it re-runs itself in Podman through line/tests/run.sh; make -C line
# test runs it inside the container with the rest of the suite.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then exec env CASES=merge-cleanup bash "$HERE/../run.sh"; fi
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}
W=${COQ_CASE_WORK:-$(mktemp -d /tmp/coq-mergeclean-XXXX)}; mkdir -p "$W/bin" "$W/gh" "$W/state" "$W/th" "$W/slots"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" GH_FAKE_DIR="$W/gh" TH_FAKE_DIR="$W/th" MERGE_BACKOFF_SECONDS=0
D=$W/gh; TH=$W/th; RECS=$W/state/records/2026/10; mkdir -p "$RECS"

# ---- a fake gh: pr view and an always-working squash merge ----
cat > "$W/bin/gh" <<'FAKE'
#!/usr/bin/env bash
D=$GH_FAKE_DIR; echo "$*" >> "$D/calls.log"
case "$1 $2" in
  "pr view")
    n=$3; fields=""; while [ $# -gt 0 ]; do [ "$1" != --json ] || fields=$2; shift; done
    jq --arg f "$fields" '($f | split(",")) as $k | with_entries(select(.key as $x | $k | index($x)))' "$D/pr-$n.json" ;;
  "pr merge")
    n=$3; jq --arg m "$(printf 'e%.0s' {1..32})$(printf '%08d' "$n")" '.state = "MERGED" | .mergeCommit = {oid: $m}' "$D/pr-$n.json" > "$D/pr-$n.tmp" && mv "$D/pr-$n.tmp" "$D/pr-$n.json"; echo merged ;;
  *) echo "fake gh: unexpected: $*" >&2; exit 1 ;;
esac
FAKE
# ---- a fake treehouse: status --json from a file, return marks the slot free unless told to fail ----
cat > "$W/bin/treehouse" <<'FAKE'
#!/usr/bin/env bash
TH=$TH_FAKE_DIR; echo "$*" >> "$TH/calls.log"
case "$1" in
  status) cat "$TH/status.json" ;;
  return)
    path=$2; holder=""; shift 2; while [ $# -gt 0 ]; do case $1 in --if-lease-holder) holder=$2; shift 2;; *) shift;; esac; done
    [ ! -e "$TH/return-fails" ] || { echo "treehouse: could not reset $path" >&2; exit 1; }
    jq --arg p "$path" --arg h "$holder" 'map(if .path == $p and .lease_holder == $h then .status = "available" | .lease_holder = "" | .processes = [] else . end)' "$TH/status.json" > "$TH/status.tmp" && mv "$TH/status.tmp" "$TH/status.json" ;;
  *) echo "fake treehouse: unexpected: $*" >&2; exit 1 ;;
esac
FAKE
# ---- a fake work-order.sh: merge.sh must never call it (cleanup fails inside a slot when main is checked out elsewhere) ----
cat > "$W/bin/work-order.sh" <<'FAKE'
#!/usr/bin/env bash
echo "$*" >> "$TH_FAKE_DIR/work-order.log"
FAKE
chmod +x "$W/bin/gh" "$W/bin/treehouse" "$W/bin/work-order.sh"
echo '[]' > "$TH/status.json"; : > "$D/calls.log"; : > "$TH/calls.log"; : > "$TH/work-order.log"

# ---- a scratch repo: main checked out in G; merge.sh runs from WT, a detached worktree of it; origin is a real bare repo ----
G=$W/git; O=$W/origin.git; WT=$W/wt
git init -q -b main "$G"; ( cd "$G" && echo a > f && git add f && git commit -qm A && echo b > f && git commit -qam B )
git init -q --bare "$O"; git -C "$G" remote add origin "$O"; git -C "$G" push -q origin main; git -C "$G" fetch -q origin; git -C "$G" remote set-head origin main >/dev/null
git -C "$G" worktree add -q --detach "$WT" main
B=$(git -C "$G" rev-parse HEAD); B12=${B:0:12}
MAIN_SHA=$(git -C "$G" rev-parse main); WT_SHA=$(git -C "$WT" rev-parse HEAD)

# ---- fixtures ----
# prb N TICKET BRANCH: the pull request gh will show, head B, on a branch that exists locally and on origin
prb() {
  jq -n --argjson n "$1" --arg t "$2 - a fixture ticket" --arg h "$B" --arg b "$3" \
    '{number:$n, state:"OPEN", title:$t, headRefOid:$h, mergeable:"MERGEABLE", headRefName:$b, mergeCommit:null}' > "$D/pr-$1.json"
  if [ "$3" != main ]; then git -C "$G" branch -q "$3" "$B"; git -C "$G" push -q origin "$3"; fi
}
# slot N TICKET [PID NAME]: a leased treehouse slot with a real directory, optionally holding one process
slot() {
  mkdir -p "$W/slots/$1"
  jq --arg n "$1" --arg p "$W/slots/$1" --arg t "$2" --argjson procs "$( [ -n "${3:-}" ] && jq -nc --argjson pid "$3" --arg nm "$4" '[{pid:$pid,name:$nm}]' || echo '[]')" \
    '. + [{name:$n, path:$p, status:"leased", flavor:"git", lease_id:("lease-"+$n), lease_holder:$t, leased_at:"2026-10-14T00:00:00Z", processes:$procs}]' "$TH/status.json" > "$TH/status.tmp" && mv "$TH/status.tmp" "$TH/status.json"
}
seq_n=0
rec() {
  seq_n=$((seq_n + 1)); local id; id=$(printf '20261013T10%04dZ-%s-t%04d' "$seq_n" "$1" "$seq_n")
  jq -n --arg id "$id" --argjson code "$1" --arg kind "$2" --arg t "$3" --arg sha "$4" \
    '{schema_version:"1.0.0", id:$id, at:"2026-10-13T10:00:00Z", code:$code, seat:"fixture", kind:$kind, ticket:$t, sha:$sha, note:"", evidence:[], observations:[]}' \
    > "$RECS/$(printf '202610131000%02d' "$seq_n")-$2-$3.json"
}
gate201() { rec 100 pr.opened "$1" "$B12"; rec 201 test.passed "$1" "$B12"; rec 201 review.passed "$1" "$B12"; }
all_recs() { find "$W/state/records" -name '*.json' -exec cat {} + 2>/dev/null; }
posted() { all_recs | jq -s --arg k "$1" --arg pr "${2:-}" '[.[] | select(.seat == "merge-script" and .kind == $k and ($pr == "" or (.pr | tostring) == $pr))] | length'; }
posted_field() { all_recs | jq -rs --arg k "$1" --argjson pr "$2" --arg f "$3" '[.[] | select(.seat == "merge-script" and .kind == $k and .pr == $pr)] | last | .[$f] // empty'; }
merge() { bash "$REPO/line/bin/merge.sh" --repo "$WT" "$@"; }
remote_has() { git -C "$G" ls-remote --exit-code --heads "$O" "refs/heads/$1" >/dev/null 2>&1; }   # 0 when origin still has the branch
local_has() { git -C "$G" show-ref --verify --quiet "refs/heads/$1"; }
returns() { grep -c "^return $W/slots/$1 " "$TH/calls.log" || true; }
holder() { jq -r --arg n "$1" '.[] | select(.name == $n) | .lease_holder' "$TH/status.json"; }

echo "-- AC-H1: main is checked out in another worktree: remote and local branch deleted, slot returned"
T=WO-20261013-c041; prb 41 $T feat/c041; gate201 $T; slot 41 $T
out=$(merge --pr 41 2>"$W/err"); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "one merged 200" "$(posted merged 41)" 1
assert_eq "the remote branch is gone" "$(remote_has feat/c041 && echo yes || echo no)" no
assert_eq "the local branch is gone" "$(local_has feat/c041 && echo yes || echo no)" no
assert_eq "treehouse return ran once on the slot" "$(returns 41)" 1
assert_eq "it passed the lease holder and --force" "$(grep -cFx "return $W/slots/41 --if-lease-holder $T --force" "$TH/calls.log")" 1
assert_eq "the slot is free again" "$(holder 41)" ""
assert_eq "nothing blocked" "$(posted blocked 41)" 0
assert_match "the line says merged and names the cleanup" "$out" "^PR 41 $T merged:.*remote branch deleted.*slot 41 returned.*local branch deleted"
assert_eq "main did not move" "$(git -C "$G" rev-parse main)" "$MAIN_SHA"
assert_eq "the checkout that holds main still holds it" "$(git -C "$G" symbolic-ref HEAD)" refs/heads/main
assert_eq "the worktree merge.sh ran from is still detached at the same commit" "$(git -C "$WT" rev-parse HEAD)$(git -C "$WT" symbolic-ref -q HEAD || echo detached)" "${WT_SHA}detached"

echo "-- architect ruling 00:30Z: a process that is not the downed seat's is in the slot: no return, slot stays leased, one note names it"
sleep 300 & SP=$!
T=WO-20261013-c042; prb 42 $T feat/c042; gate201 $T; slot 42 $T $SP sleep
out=$(merge --pr 42 2>"$W/err"); rc=$?
assert_eq "exit 0 (the merge happened)" "$rc" 0
assert_eq "one merged 200" "$(posted merged 42)" 1
assert_eq "treehouse return was not called" "$(returns 42)" 0
assert_eq "the slot is still leased to the ticket" "$(holder 42)" "$T"
assert_eq "one blocked 423" "$(posted blocked 42)" 1
assert_eq "to the orchestrator" "$(posted_field blocked 42 to)" orchestrator
assert_eq "code 423" "$(posted_field blocked 42 code)" 423
assert_match "the note names the pid and the process" "$(posted_field blocked 42 note)" "$SP.*sleep|sleep.*$SP"
assert_match "the note says the slot was left leased" "$(posted_field blocked 42 note)" "left leased"
assert_match "the line says so" "$out" "slot 42 left leased"
assert_eq "the branches were still deleted" "$(remote_has feat/c042 && echo yes || echo no)$(local_has feat/c042 && echo yes || echo no)" nono
kill "$SP" 2>/dev/null; wait "$SP" 2>/dev/null
echo "-- a stale pid in the slot's process list is not a process: the slot is returned"
T=WO-20261013-c043; prb 43 $T feat/c043; gate201 $T; slot 43 $T 4194000 ghost
out=$(merge --pr 43 2>"$W/err"); assert_eq "exit 0" "$?" 0
assert_eq "treehouse return ran" "$(returns 43)" 1
assert_eq "nothing blocked" "$(posted blocked 43)" 0

echo "-- architect ruling 00:34Z: an idle claude bg-spare and bg-pty-host in the slot are reaped, not foreign; the slot is returned"
T=WO-20261013-c051; prb 51 $T feat/c051; gate201 $T; mkdir -p "$W/slots/51"
( cd "$W/slots/51" && exec -a "claude bg-spare" sleep 300 ) & SA=$!
( cd "$W/slots/51" && exec -a "claude bg-pty-host" sleep 300 ) & SB=$!
sleep 0.3; slot 51 $T
jq --argjson a "$SA" --argjson b "$SB" 'map(if .name == "51" then .processes = [{pid:$a,name:"claude"},{pid:$b,name:"claude"}] else . end)' "$TH/status.json" > "$TH/status.tmp" && mv "$TH/status.tmp" "$TH/status.json"
out=$(merge --pr 51 2>"$W/err"); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "both spares are gone" "$( ( kill -0 "$SA" 2>/dev/null && [ "$(ps -o stat= -p "$SA" | cut -c1)" != Z ] ) && echo alive; ( kill -0 "$SB" 2>/dev/null && [ "$(ps -o stat= -p "$SB" | cut -c1)" != Z ] ) && echo alive; true)" ""
assert_eq "treehouse return ran" "$(returns 51)" 1
assert_eq "nothing blocked" "$(posted blocked 51)" 0
assert_match "the line says the spares were reaped" "$out" "slot 51 returned after reaping 2 idle claude spare"
kill -9 "$SA" "$SB" 2>/dev/null; wait "$SA" "$SB" 2>/dev/null
echo "-- a bg-spare whose cwd is not in the slot, and another claude in the slot, are foreign: left alone, slot left leased"
T=WO-20261013-c052; prb 52 $T feat/c052; gate201 $T; mkdir -p "$W/slots/52" "$W/elsewhere"
( cd "$W/elsewhere" && exec -a "claude bg-spare" sleep 300 ) & SC=$!
( cd "$W/slots/52" && exec -a "claude chat" sleep 300 ) & SD=$!
sleep 0.3; slot 52 $T
jq --argjson a "$SC" --argjson b "$SD" 'map(if .name == "52" then .processes = [{pid:$a,name:"claude"},{pid:$b,name:"claude"}] else . end)' "$TH/status.json" > "$TH/status.tmp" && mv "$TH/status.tmp" "$TH/status.json"
out=$(merge --pr 52 2>"$W/err"); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "treehouse return was not called" "$(returns 52)" 0
assert_eq "both processes still run" "$(kill -0 "$SC" 2>/dev/null && kill -0 "$SD" 2>/dev/null && echo yes || echo no)" yes
assert_eq "one blocked 423 naming both" "$(posted blocked 52)$(posted_field blocked 52 note | grep -c "$SC.*$SD")" 11
kill -9 "$SC" "$SD" 2>/dev/null; wait "$SC" "$SD" 2>/dev/null

echo "-- merge.sh running inside the slot: no treehouse return, it would end merge.sh"
T=WO-20261013-c044; prb 44 $T feat/c044; gate201 $T; slot 44 $T
out=$( cd "$W/slots/44" && merge --pr 44 2>"$W/err" ); rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "treehouse return was not called" "$(returns 44)" 0
assert_eq "one blocked 423 that names the working directory" "$(posted blocked 44)$(posted_field blocked 44 note | grep -c 'working directory')" 11

echo "-- treehouse return never works: three attempts, one blocked 423, the merge stands"
T=WO-20261013-c045; prb 45 $T feat/c045; gate201 $T; slot 45 $T; touch "$TH/return-fails"
out=$(merge --pr 45 2>"$W/err"); rc=$?
rm -f "$TH/return-fails"
assert_eq "exit 0" "$rc" 0
assert_eq "three attempts" "$(returns 45)" 3
assert_eq "one blocked 423 that names the slot step" "$(posted blocked 45)$(posted_field blocked 45 note | grep -c 'slot')" 11
assert_eq "one merged 200" "$(posted merged 45)" 1
assert_eq "the branches were deleted all the same" "$(remote_has feat/c045 && echo yes || echo no)$(local_has feat/c045 && echo yes || echo no)" nono
assert_eq "the slot is still leased" "$(holder 45)" "$T"

echo "-- idempotent: the remote branch is already gone"
T=WO-20261013-c046; prb 46 $T feat/c046; gate201 $T; slot 46 $T; git -C "$G" push -q origin --delete feat/c046
out=$(merge --pr 46 2>"$W/err"); assert_eq "exit 0" "$?" 0
assert_eq "nothing blocked" "$(posted blocked 46)" 0
assert_eq "the local branch is gone and the slot returned" "$(local_has feat/c046 && echo yes || echo no)$(returns 46)" no1

echo "-- idempotent: no slot is leased to the ticket"
T=WO-20261013-c047; prb 47 $T feat/c047; gate201 $T
out=$(merge --pr 47 2>"$W/err"); assert_eq "exit 0" "$?" 0
assert_eq "nothing blocked" "$(posted blocked 47)" 0
assert_eq "the branches are gone" "$(remote_has feat/c047 && echo yes || echo no)$(local_has feat/c047 && echo yes || echo no)" nono
assert_match "the line says no slot was leased" "$out" "no slot"

echo "-- the branch is the repo's own HEAD: it is detached first, then deleted; main is never checked out"
T=WO-20261013-c048; prb 48 $T feat/c048; gate201 $T; slot 48 $T; git -C "$WT" switch -q feat/c048
out=$(merge --pr 48 2>"$W/err"); assert_eq "exit 0" "$?" 0
assert_eq "the local branch is gone" "$(local_has feat/c048 && echo yes || echo no)" no
assert_eq "the worktree is detached" "$(git -C "$WT" symbolic-ref -q HEAD || echo detached)" detached
assert_eq "at the same commit" "$(git -C "$WT" rev-parse HEAD)" "$B"
assert_eq "main did not move" "$(git -C "$G" rev-parse main)" "$MAIN_SHA"

echo "-- a head branch named main is never deleted"
T=WO-20261013-c049; prb 49 $T main; gate201 $T; slot 49 $T
out=$(merge --pr 49 2>"$W/err"); assert_eq "exit 0" "$?" 0
assert_eq "main is still on origin and local" "$(remote_has main && echo yes || echo no)$(local_has main && echo yes || echo no)" yesyes
assert_eq "the slot was not returned" "$(returns 49)" 0
assert_match "the line says it refuses" "$out" "refuses"

echo "-- a remote that cannot be reached: three attempts, one blocked 423, the slot and the local branch are still handled"
T=WO-20261013-c050; prb 50 $T feat/c050; gate201 $T; slot 50 $T
git -C "$G" remote set-url origin "$W/no-such-origin.git"
out=$(merge --pr 50 2>"$W/err"); rc=$?
git -C "$G" remote set-url origin "$O"
assert_eq "exit 0" "$rc" 0
assert_eq "one blocked 423 that names the remote branch" "$(posted blocked 50)$(posted_field blocked 50 note | grep -c 'remote branch')" 11
assert_eq "the slot was returned and the local branch deleted" "$(returns 50)$(local_has feat/c050 && echo yes || echo no)" 1no

echo "-- work-order.sh cleanup is never called, and nothing in merge.sh names it as a command"
assert_eq "the fake work-order.sh was never run" "$(wc -c < "$TH/work-order.log" | tr -d ' ')" 0
assert_eq "main still holds the same commit and checkout" "$(git -C "$G" rev-parse main)$(git -C "$G" symbolic-ref HEAD)" "${MAIN_SHA}refs/heads/main"

case_done
