#!/usr/bin/env bash
# Catches: a ticket seat started with no --worktree not leasing a treehouse slot to its ticket (AC-H1), a lease the seat
# cannot be found by, a rerun that leases a second slot, --down leaving the slot leased or returning twice (AC-H3), a seat
# started with --worktree touching the pool at all (AC-H4), --down returning a lease it did not take, a refused or failed
# bring-up leaving a lease behind, and --check missing a lost lease. The pool is the stub treehouse (tests/stubs), so no real
# slot of the host is leased, reset or returned; its argv log is how a case counts calls (WO-20261010-a429).
# WO-20261011-c077 adds: a leased slot left detached instead of on the ticket's branch (AC-H1), a local branch put back after a
# rerun with its upstream restored, a ticket whose branch is null being leased a slot instead of refused first (AC-H2), and a
# branch no repository has leaving the fresh lease behind. The stub's slots are clones of a bare origin made below.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up lease || exit 1
export TREEHOUSE_STUB_LOG="$WORLD/treehouse.log"; : > "$TREEHOUSE_STUB_LOG"
A=WO-20261010-8777; NA=worker-wo-20261010-8777
B=WO-20261010-c274; NB=worker-wo-20261010-c274
C=WO-20261010-8fa8; NC=worker-wo-20261010-8fa8
D=WO-20261010-539f; ND=worker-wo-20261010-539f
E=WO-20261010-d354
pool() { treehouse status --json; }
held() { pool | jq --arg h "$1" '[.[] | select(.lease_holder == $h)] | length'; }
calls() { grep -c "^$1 " "$TREEHOUSE_STUB_LOG"; }
ws_count() { h workspace list | jq '[.result.workspaces[] | select(.label == "coq")] | length'; }
# The slots are clones of a bare origin that holds main (the stub treehouse reads TREEHOUSE_STUB_ORIGIN). tfile ID is the world's
# copy of a ticket, stamp_branch ID BRANCH writes the frontmatter branch work-order start would, origin_branch BRANCH puts that
# branch on origin so a fresh slot has to fetch it.
ORIGIN="$WORLD/origin.git"; SEED="$WORLD/seed"
git init -q --bare "$ORIGIN"; git clone -q "$ORIGIN" "$SEED" 2>/dev/null
git -C "$SEED" commit -q --allow-empty -m "seed main" && git -C "$SEED" push -q origin main || { echo "case 08: could not seed the origin"; exit 1; }
export TREEHOUSE_STUB_ORIGIN="$ORIGIN"
tfile() { find "$REPO/work-orders" -name "$1-*.md" -not -path '*/archive/*' | head -1; }
branch_of() { awk '/^---$/{c++; next} c==1' "$(tfile "$1")" | jq -r .branch; }
stamp_branch() {
  local f; f="$(tfile "$1")"
  { echo '---'; awk 'c<2 && /^---$/{c++; next} c==1' "$f" | jq --arg b "$2" '.branch=$b'; echo '---'; awk 'c<2 && /^---$/{c++; next} c>=2' "$f"; } > "$f.tmp" && mv "$f.tmp" "$f"
}
origin_branch() { git -C "$SEED" checkout -q -b "$1" main && git -C "$SEED" commit -q --allow-empty -m "work on $1" && git -C "$SEED" push -q origin "$1" && git -C "$SEED" checkout -q main; }
slot_branch() { git -C "$1" rev-parse --abbrev-ref HEAD; }
for t in $A $B; do origin_branch "$(branch_of "$t")"; done
stamp_branch "$D" feat/nats-jetstream-bus; origin_branch feat/nats-jetstream-bus

echo "-- AC-H1: --ticket with no --worktree leases a slot to the ticket"
out="$("$SEAT" --ticket "$A" --role worker)"; rc=$?
assert_eq "exit 0" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"
assert_match "the seat's worktree is a slot of the pool" "$slot" "^$HOME/.treehouse-stub/slots/[0-9]+$"
assert_eq "treehouse status lists one lease held by the ticket" "$(held "$A")" 1
assert_eq "that lease is the seat's worktree" "$(pool | jq -r --arg h "$A" '.[] | select(.lease_holder == $h) | .path')" "$slot"
assert_eq "exactly one get, with the ticket as the lease holder" "$(grep -c "^get --lease --lease-holder $A --no-fetch --json$" "$TREEHOUSE_STUB_LOG")" 1
R="$STATE/seats/$NA/seat.json"
assert_eq "seat.json worktree is the slot" "$(jq -r .worktree "$R")" "$slot"
assert_eq "seat.json lease names the holder, the lease id and that this seat owns it" \
  "$(jq -c .lease "$R")" "$(pool | jq -c --arg h "$A" '.[] | select(.lease_holder == $h) | {holder:.lease_holder,id:.lease_id,owned:true}')"
assert_eq "the one-line result carries the lease" "$(jq -r .lease.owned <<<"$out")" true
agent="$(jq -r .agent <<<"$out")"
assert_eq "COQ_WORKTREE in the agent pane is the slot" "$(h pane read "$agent" --source recent-unwrapped --lines 200 | grep -cF "COQ_WORKTREE=$slot")" 1
sleep 1
assert_match "the brief says to work only in the slot" "$(h agent read "$NA" --source recent-unwrapped --lines 200)" "Work only in $slot"
assert_eq "the rendered settings allow edits under the slot" "$(jq -r --arg s "$slot" '[.permissions.allow[] | select(startswith("Edit(") and contains($s))] | length' "$STATE/seats/$NA/settings.json")" 1
"$SEAT" --check "$NA" >/dev/null; assert_eq "--check exits 0 with the lease held" "$?" 0
BA="$(branch_of "$A")"
assert_eq "the slot is on the ticket's feat branch, not detached at origin/main" "$(slot_branch "$slot")" "$BA"
assert_eq "that branch tracks origin" "$(git -C "$slot" rev-parse --abbrev-ref "$BA@{upstream}")" "origin/$BA"
assert_eq "the slot holds the tip origin has for it" "$(git -C "$slot" rev-parse HEAD)" "$(git -C "$ORIGIN" rev-parse "refs/heads/$BA")"
assert_eq "the checkout left the slot clean" "$(git -C "$slot" status --porcelain | wc -l | tr -d ' ')" 0

echo "-- AC-H2: the worker's step 1 read finds the lease by ticket and path"
assert_eq "a status read keyed by ticket and worktree returns the entry" \
  "$(pool | jq --arg h "$A" --arg p "$slot" '[.[] | select(.lease_holder == $h and .path == $p)] | length')" 1

echo "-- a rerun repairs and leases nothing more"
out2="$("$SEAT" --ticket "$A" --role worker)"; rc=$?
assert_eq "rerun exits 0" "$rc" 0
assert_eq "the rerun kept the same slot" "$(jq -r .worktree <<<"$out2")" "$slot"
assert_eq "still one lease in the pool" "$(pool | jq length)" 1
assert_eq "still one get" "$(calls get)" 1
assert_eq "the rerun kept ownership" "$(jq -r .lease.owned "$R")" true
assert_eq "the rerun left the slot on the branch" "$(slot_branch "$slot")" "$BA"

echo "-- a slot found detached with its branch already local is put back, and tracks origin again"
git -C "$slot" checkout -q --detach && git -C "$slot" branch -q --unset-upstream "$BA"
"$SEAT" --ticket "$A" --role worker >/dev/null; assert_eq "the repair rerun exits 0" "$?" 0
assert_eq "the slot is back on the ticket's branch" "$(slot_branch "$slot")" "$BA"
assert_eq "its upstream is origin's branch again" "$(git -C "$slot" rev-parse --abbrev-ref "$BA@{upstream}")" "origin/$BA"
assert_eq "still one lease in the pool" "$(pool | jq length)" 1

echo "-- AC-H3: --down returns the slot"
"$SEAT" --down "$NA" >/dev/null; assert_eq "--down exits 0" "$?" 0
assert_eq "treehouse status no longer lists the ticket" "$(held "$A")" 0
[ -d "$slot" ] && gone=0 || gone=1; check "the slot is back in the pool (directory gone from the stub)" "$gone"
assert_eq "one return, for that slot and holder" "$(grep -c "^return $slot --if-lease-holder $A --force$" "$TREEHOUSE_STUB_LOG")" 1
assert_eq "seat.down 100 recorded" "$(event_count seat.down 100)" 1
"$SEAT" --down "$NA" >/dev/null; assert_eq "a second --down exits 0" "$?" 0
assert_eq "a second --down returns nothing more" "$(calls return)" 1

echo "-- a lease lost under the seat: --check says so, --down still ends the seat"
"$SEAT" --ticket "$B" --role worker >/dev/null; assert_eq "seat B up" "$?" 0
slotb="$(jq -r .worktree "$STATE/seats/$NB/seat.json")"
treehouse return "$slotb" --force; assert_eq "the lease is taken away by hand" "$?" 0
diff="$("$SEAT" --check "$NB")"; rc=$?
assert_eq "--check exits 1" "$rc" 1
assert_match "--check names the lost lease" "$diff" "lease missing: treehouse status lists no lease held by $B at $slotb"
returns=$(calls return)
"$SEAT" --down "$NB" >/dev/null; assert_eq "--down exits 0" "$?" 0
assert_eq "--down did not call return for a slot that is no longer leased" "$(calls return)" "$returns"
assert_match "the record carries ended_at" "$(jq -r .ended_at "$STATE/seats/$NB/seat.json")" '^2[0-9]{3}-'

echo "-- AC-H4: --worktree leases nothing and returns nothing"
gets=$(calls get); returns=$(calls return)
out="$("$SEAT" --ticket "$C" --role worker --worktree "$REPO")"; rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "the seat runs in the plain directory it was given" "$(jq -r .worktree <<<"$out")" "$REPO"
assert_eq "seat.json lease is null" "$(jq -c .lease "$STATE/seats/$NC/seat.json")" null
assert_eq "the pool is empty" "$(pool | jq length)" 0
"$SEAT" --check "$NC" >/dev/null; assert_eq "--check exits 0 with no lease to find" "$?" 0
"$SEAT" --down "$NC" >/dev/null; assert_eq "--down exits 0" "$?" 0
assert_eq "no get was made" "$(calls get)" "$gets"
assert_eq "no return was made" "$(calls return)" "$returns"

echo "-- a lease the ticket already held is used, and --down leaves it alone"
pre="$(treehouse get --lease --lease-holder "$D" --no-fetch --json | jq -r .path)"
gets=$(calls get); returns=$(calls return)
out="$("$SEAT" --ticket "$D" --role worker)"; rc=$?
assert_eq "exit 0" "$rc" 0
assert_eq "the seat works in the slot the ticket already held" "$(jq -r .worktree <<<"$out")" "$pre"
assert_eq "no second lease was taken" "$(calls get)" "$gets"
assert_eq "the seat does not own it" "$(jq -r .lease.owned "$STATE/seats/$ND/seat.json")" false
assert_eq "the slot it did not lease was put on the ticket's branch" "$(slot_branch "$pre")" feat/nats-jetstream-bus
"$SEAT" --down "$ND" >/dev/null; assert_eq "--down exits 0" "$?" 0
assert_eq "the other holder's lease is still there" "$(held "$D")" 1
assert_eq "no return was made" "$(calls return)" "$returns"
treehouse return "$pre" --force

echo "-- AC-H2: a ticket whose frontmatter branch is null is refused with exit 3 and no lease is taken"
assert_eq "the fixture ticket has no branch" "$(branch_of "$E")" null
gets=$(calls get); before=$(ws_count)
"$SEAT" --ticket "$E" --role worker >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_match "the refusal names the ticket and says it has no branch" "$(cat "$WORLD/err")" "ticket $E has no branch yet"
assert_eq "no get was made" "$(calls get)" "$gets"
assert_eq "the pool is empty" "$(pool | jq length)" 0
assert_eq "no workspace was built" "$(ws_count)" "$before"

echo "-- WO-20261011-23df: branch null here but origin has feat/<slug> (the start was pushed, not merged): leased on that branch"
SLUG_E="$(awk '/^---$/{c++; next} c==1' "$(tfile "$E")" | jq -r .slug)"
git -C "$REPO" init -q 2>/dev/null; git -C "$REPO" remote add origin "$ORIGIN" 2>/dev/null || git -C "$REPO" remote set-url origin "$ORIGIN"
origin_branch "feat/$SLUG_E"
NE=worker-wo-20261010-d354
out="$("$SEAT" --ticket "$E" --role worker 2>"$WORLD/err")"; rc=$?
assert_eq "exit 0 with the derived branch" "$rc" 0
[ "$rc" = 0 ] || { echo "  diag stderr: $(tail -c 600 "$WORLD/err")"; echo "  diag out: $out"; }
assert_eq "the slot sits on feat/<slug>" "$(slot_branch "$(jq -r .worktree <<<"$out")")" "feat/$SLUG_E"
assert_eq "the fixture ticket frontmatter still says null (nothing was written to it)" "$(branch_of "$E")" null
"$SEAT" --down "$NE" >/dev/null 2>&1
assert_eq "the lease is given back after --down" "$(held "$E")" 0
git -C "$SEED" push -q origin --delete "feat/$SLUG_E"; rm -rf "$REPO/.git"

echo "-- a branch no repository has: refused, and the lease it took is given back"
stamp_branch "$E" feat/never-pushed
gets=$(calls get); returns=$(calls return)
"$SEAT" --ticket "$E" --role worker >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_match "the refusal names the slot, the branch and the ticket" "$(cat "$WORLD/err")" "could not be put on feat/never-pushed for $E: branch feat/never-pushed is on neither the repository nor origin"
assert_eq "a slot had been leased" "$(calls get)" "$((gets + 1))"
assert_eq "and given back" "$(calls return)" "$((returns + 1))"
assert_eq "the pool is empty again" "$(pool | jq length)" 0
stamp_branch "$E" feat/dated-entry-files; origin_branch feat/dated-entry-files

echo "-- a refused bring-up leases nothing"
# WO-20261011-f896: seat-1x2 builds its own test pane, so the refusal belongs to a layout that has none.
notest_layout; role_layout worker seat-nt
gets=$(calls get)
env -u HERDR_TAB_ID "$SEAT" --ticket "$E" --role worker >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "no test pane: exit 3" "$rc" 3
assert_eq "no lease was taken" "$(calls get)" "$gets"
role_layout worker seat-1x2

echo "-- a pool that cannot give a slot builds nothing"
before=$(ws_count)
TREEHOUSE_STUB_FAIL=1 "$SEAT" --ticket "$E" --role worker >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_match "the refusal names the ticket and the failed get" "$(cat "$WORLD/err")" "no treehouse slot for $E: treehouse get --lease failed"
assert_eq "no workspace was built" "$(ws_count)" "$before"
assert_eq "the pool is empty" "$(pool | jq length)" 0

echo "-- a bring-up that dies after the lease gives the slot back"
jq '.grid = "2x2"' "$REPO/herdr/layouts/seat-1x2.json" > "$WORLD/layout.tmp" && mv "$WORLD/layout.tmp" "$REPO/herdr/layouts/seat-1x2.json"
gets=$(calls get)
"$SEAT" --ticket "$E" --role worker >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "refused for the layout, exit 3" "$rc" 3
assert_match "it died on the layout, after the lease" "$(cat "$WORLD/err")" "grid 2x2 does not match"
assert_eq "a slot had been leased" "$(calls get)" "$((gets + 1))"
assert_eq "the pool is empty again" "$(pool | jq length)" 0
case_done
