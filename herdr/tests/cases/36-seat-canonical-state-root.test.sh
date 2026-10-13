#!/usr/bin/env bash
# Catches: a seat's state root named after the checkout it was seated from (WO-20261013-69df, cause v, system epic WO-20261013-16f1).
# At 20:03Z three testers were seated by seat.sh run from the verify-fba7551 worktree; seat.sh exported COQ_REPO=<that checkout>,
# bin/state-root.sh names the root after COQ_REPO's basename, so their test.passed records went to ~/.local/state/coq/verify-fba7551/
# records and the merger never saw them. The world's repository is made a git repository with a second worktree named verify-fba7551,
# as on the host, and seat.sh is run from that worktree with COQ_STATE unset and an inherited COQ_REPO that names it.
#   AC-H1  the seat's records (seat.up, the pane's COQ_REPO, a post from the seat's own event.sh) land in the canonical tree
#   AC-H2  a seat whose own resolver would post elsewhere (a stale resolver) is refused with exit 3 naming both trees, and nothing
#          is written to either tree; a checkout with no resolver has nothing to judge and is let through
# The last block puts the old behaviour back (the checkout names the repository) and asserts the case's checks then fail, so the case
# is shown to fail for the fault it names. It sets COQ_STATE itself where it needs it and leaves herdr/tests/lib/world.sh as it is.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up canonroot || exit 1
T=WO-20261010-8777; N=worker-wo-20261010-8777        # the seat the worker label gives this ticket
TM=WO-20261012-b800; NM=worker-wo-20261012-b800      # the mutant's seat
TR=WO-20261011-ceea                                  # the refused seats
# The host: a repository whose second worktree has another name. The world is a plain copy, so make it one and commit it.
git -C "$REPO" init -q && git -C "$REPO" -c user.name=case -c user.email=case@example.invalid add -A >/dev/null 2>&1 \
  && git -C "$REPO" -c user.name=case -c user.email=case@example.invalid commit -q -m "world" \
  && git -C "$REPO" worktree add -q --detach "$WORLD/verify-fba7551" >/dev/null 2>&1 \
  || { echo "case 36: could not make the second worktree"; exit 1; }
WT2="$WORLD/verify-fba7551"; CANON="$XDG_STATE_HOME/coq/repo"; WRONG="$XDG_STATE_HOME/coq/verify-fba7551"
# records of a tree, as files (YYYY/MM/name.json); the seat's own seat directory is under state_dir, not here
recs() { find "$1/records" -mindepth 3 -maxdepth 3 -name '*.json' 2>/dev/null; }
seat_up_in() { local f; for f in $(recs "$1"); do jq -e --arg s "$2" '.kind == "seat.up" and .seat == $s and .code == 100' "$f" >/dev/null 2>&1 && return 0; done; return 1; }
# seat.sh as the orchestrator runs it: from WT2, COQ_STATE unset, the COQ_REPO of the seat it runs in
run_seat() { ( cd "$WT2" && env -u COQ_STATE COQ_REPO="$WT2" "$WT2/herdr/bin/seat.sh" "$@" ); }
agent_line() { h pane read "$(jq -r .agent <<<"$1")" --source recent-unwrapped --lines 200; }

echo "-- the world starts clean and the second worktree is another name for the same repository"
assert_eq "the canonical root resolves from the first checkout" "$(env -u COQ_STATE "$REPO/bin/state-root.sh" tree records)" "$CANON/records"
assert_eq "with the inherited COQ_REPO the second worktree alone resolves a root named after itself (the incident)" \
  "$(cd "$WT2" && env -u COQ_STATE COQ_REPO="$WT2" "$WT2/bin/state-root.sh" tree records)" "$WRONG/records"
assert_eq "no record exists in either tree" "$(($(recs "$CANON" | wc -l) + $(recs "$WRONG" | wc -l)))" 0

echo "-- AC-H1: a seat started from the second worktree posts into the canonical records tree"
out="$(run_seat --ticket "$T" --role worker --worktree "$WT2" 2>"$WORLD/up.err")"; rc=$?
assert_eq "seat-up from the second worktree exits 0" "$rc" 0
seat_up_in "$CANON" "$N"; check "seat.up 100 for the seat is a record under the canonical tree" "$((1 - $?))"
assert_eq "no record in a root named after the second worktree" "$(recs "$WRONG" | wc -l | tr -d ' ')" 0
assert_eq "the seat's environment line carries the canonical repository" "$(agent_line "$out" | grep -cF "COQ_REPO=$REPO")" 1
assert_eq "and not the checkout it was seated from" "$(agent_line "$out" | grep -cF "COQ_REPO=$WT2")" 0
before=$(recs "$CANON" | wc -l | tr -d ' ')
( cd "$WT2" && env -u COQ_STATE COQ_REPO="$REPO" "$WT2/events/bin/event.sh" add --code 100 --seat "$N" --kind work.started --ticket "$T" --note "case 36 post from the seat" >/dev/null ); rc=$?
assert_eq "a post from the seat's own event.sh with the exported COQ_REPO exits 0" "$rc" 0
assert_eq "it added one record to the canonical tree" "$(recs "$CANON" | wc -l | tr -d ' ')" "$((before + 1))"
assert_eq "and none to a root named after the checkout" "$(recs "$WRONG" | wc -l | tr -d ' ')" 0

echo "-- a COQ_STATE the caller set rides the environment line, so the seat posts to the same root as its caller"
export COQ_STATE="$WORLD/explicit-state"; mkdir -p "$COQ_STATE"
TC=WO-20261010-539f; NC=worker-wo-20261010-539f
outc="$(cd "$WT2" && COQ_REPO="$WT2" "$WT2/herdr/bin/seat.sh" --ticket "$TC" --role worker --worktree "$WT2" 2>/dev/null)"; rc=$?
assert_eq "seat-up with COQ_STATE set exits 0" "$rc" 0
seat_up_in "$COQ_STATE" "$NC"; check "seat.up 100 lands under the caller's COQ_STATE" "$((1 - $?))"
assert_eq "the line exports that COQ_STATE" "$(agent_line "$outc" | grep -cF "COQ_STATE=$COQ_STATE")" 1
assert_eq "and the first seat's line exports none (its caller had none)" "$(agent_line "$out" | grep -c 'COQ_STATE=')" 0
unset COQ_STATE

echo "-- AC-H2: a seat whose own resolver would post elsewhere is refused with exit 3, nothing written"
STALE="$WORLD/stale-checkout"; cp -a "$WT2" "$STALE"
cat > "$STALE/bin/state-root.sh" <<'STUB'
#!/usr/bin/env bash
# a resolver from before roadmap item A1: it names the root after its own checkout and ignores COQ_REPO and COQ_STATE
printf '%s/records\n' "$(dirname "$(cd "$(dirname "$0")" && pwd)")"
STUB
chmod +x "$STALE/bin/state-root.sh"
canon_n=$(recs "$CANON" | wc -l | tr -d ' ')
err="$(env -u COQ_STATE "$REPO/herdr/bin/seat.sh" --ticket "$TR" --role worker --worktree "$STALE" 2>&1 >/dev/null)"; rc=$?
assert_eq "a stale resolver is refused with exit 3" "$rc" 3
assert_match "the refusal names the canonical tree" "$err" "$CANON/records"
assert_match "and the tree the seat would have used" "$err" "$STALE/records"
assert_eq "no record was written to the canonical tree" "$(recs "$CANON" | wc -l | tr -d ' ')" "$canon_n"
assert_eq "none to the stale checkout's tree" "$(recs "$STALE" | wc -l | tr -d ' ')" 0
assert_eq "no agent was started for the refused seat" "$(h agent list 2>/dev/null | grep -c 'worker-wo-20261011-ceea')" 0
rm -f "$STALE/bin/state-root.sh"
err="$(env -u COQ_STATE "$REPO/herdr/bin/seat.sh" --ticket "$TR" --role worker --worktree "$STALE" 2>&1 >/dev/null)"; rc=$?
assert_eq "a checkout with no resolver has no tree to judge and comes up (an empty stub slot is one)" "$rc" 0
assert_match "the gate says so in the log" "$err" "has no bin/state-root.sh"
assert_eq "its own records are still the canonical tree's (seat.sh posts with its own resolver)" "$(recs "$STALE" | wc -l | tr -d ' ')" 0

echo "-- the case fails for the fault it names: with the old behaviour back, the records go to the checkout's name"
# The mutant: the repository is the checkout seat.sh runs from (sl_canonical_repo before this ticket), in the second worktree only.
sed -i 's|^sl_canonical_repo() {|sl_canonical_repo() { printf "%s\\n" "$SL_REPO"; return 0|' "$WT2/herdr/bin/seat-lib.sh"
grep -q '^sl_canonical_repo() { printf' "$WT2/herdr/bin/seat-lib.sh"; check "the mutant was built (sl_canonical_repo answers the checkout)" "$((1 - $?))"
outm="$(run_seat --ticket "$TM" --role worker --worktree "$WT2" 2>/dev/null)"; rc=$?
assert_eq "the mutant seat comes up (the fault is silent, which is why it starved the merger)" "$rc" 0
seat_up_in "$WRONG" "$NM"; check "the mutant put its seat.up in the root named after the checkout, the incident" "$((1 - $?))"
assert_eq "and none in the canonical tree, so the AC-H1 checks above would fail" "$(seat_up_in "$CANON" "$NM"; echo $?)" 1
assert_eq "its environment line names the checkout, so 'carries the canonical repository' would fail" "$(agent_line "$outm" | grep -cF "COQ_REPO=$WT2")" 1
case_done
