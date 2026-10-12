#!/usr/bin/env bash
# Catches: the verifier seat being refused for a merged ticket (WO-20261012-72a0). A merged 200 wakes the verifier after the
# worker's archive move is on main and the ticket's branch is deleted, so door 1 must find the ticket in work-orders/archive/,
# lease a slot, and detach it at origin/main instead of looking for a branch. A worker on the same archived ticket is still
# refused, and a lease is never left behind by the refusal.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up verifier || exit 1
export TREEHOUSE_STUB_LOG="$WORLD/treehouse.log"; : > "$TREEHOUSE_STUB_LOG"
T=WO-20261010-8777; N=verifier-wo-20261010-8777
ORIGIN="$WORLD/origin.git"; SEED="$WORLD/seed"
git init -q --bare "$ORIGIN"; git clone -q "$ORIGIN" "$SEED" 2>/dev/null
git -C "$SEED" commit -q --allow-empty -m "seed main" && git -C "$SEED" push -q origin main || { echo "case 17: could not seed the origin"; exit 1; }
export TREEHOUSE_STUB_ORIGIN="$ORIGIN"
held() { treehouse status --json | jq --arg h "$1" '[.[] | select(.lease_holder == $h)] | length'; }
f="$(find "$REPO/work-orders" -name "$T-*.md" -not -path '*/archive/*' | head -1)"
mkdir -p "$REPO/work-orders/archive/2026"; mv "$f" "$REPO/work-orders/archive/2026/"

echo "-- a worker on the archived ticket is refused and leases nothing"
out="$("$SEAT" --ticket "$T" --role worker 2>&1)"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_match "the refusal says archived" "$out" "no ticket $T under work-orders/"
assert_eq "no lease" "$(held "$T")" 0

echo "-- the verifier comes up on it, in a slot detached at origin/main, with no branch needed"
out="$("$SEAT" --ticket "$T" --role verifier)"; rc=$?
assert_eq "exit 0" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"
assert_eq "one lease held by the ticket" "$(held "$T")" 1
assert_eq "the slot is detached" "$(git -C "$slot" rev-parse --abbrev-ref HEAD)" HEAD
assert_eq "at the tip of origin main" "$(git -C "$slot" rev-parse HEAD)" "$(git -C "$ORIGIN" rev-parse refs/heads/main)"
sleep 1
assert_match "the brief names the ticket and the verifier playbook" "$(h agent read "$N" --source recent-unwrapped --lines 200)" "$T - .*Playbook playbooks/verifier.md"
"$SEAT" --down "$N" >/dev/null; assert_eq "--down returns the slot" "$(held "$T")" 0
