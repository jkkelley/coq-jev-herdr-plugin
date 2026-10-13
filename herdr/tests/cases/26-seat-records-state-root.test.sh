#!/usr/bin/env bash
# Catches: a seat started in a treehouse slot posting its records into the slot's own events/ instead of the state root
# (WO-20261013-496d, Roadmap A3). On 2026-10-12 22:05Z a seat in a slot wrote and searched records in the slot's events/, so the
# belt and the next seat, which read the state root, never saw them. Since A1 (WO-20261012-7e13) events/bin/event.sh resolves the
# state root; this case pins that a seat brought up from a copy of the repository as a slot lands its seat.up under
# $COQ_STATE/records and leaves the copy's events/ without a record. It sets COQ_STATE itself (the world exports it, the case
# re-exports its own) and leaves herdr/tests/lib/world.sh as it is. The last block turns the writer back on the slot's events/
# and asserts the case's own checks then fail, so the case is shown to fail for the fault it names (AC-H1).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up staterec || exit 1
T=WO-20261010-8777; N=worker-wo-20261010-8777
SLOT="$REPO"                                  # the copy of the repository is the slot the seat works in
export COQ_STATE="$WORLD/case-state"; mkdir -p "$COQ_STATE"
# the records tree of the state root and of the slot, as files; a record is a json file three levels down (YYYY/MM/name.json)
in_state() { find "$COQ_STATE/records" -mindepth 3 -maxdepth 3 -name '*.json' 2>/dev/null; }
in_slot() { find "$SLOT/events" -mindepth 3 -maxdepth 3 -name '*.json' ! -path '*/schema/*' ! -path '*/tests/*' 2>/dev/null; }
seat_up_in_state() { local f; for f in $(in_state); do jq -e --arg s "$N" '.kind == "seat.up" and .seat == $s and .code == 100' "$f" >/dev/null 2>&1 && return 0; done; return 1; }

echo "-- a seat started in the slot posts seat.up into the state root"
assert_eq "the slot starts with no record under events/" "$(in_slot | wc -l | tr -d ' ')" 0
assert_eq "the state root starts with no record" "$(in_state | wc -l | tr -d ' ')" 0
out="$("$SEAT" --ticket "$T" --role worker --worktree "$SLOT")"; rc=$?
assert_eq "seat-up exits 0" "$rc" 0
assert_eq "the seat works in the slot" "$(jq -r .worktree <<<"$out")" "$SLOT"
seat_up_in_state; check "seat.up 100 for the seat is a record under COQ_STATE/records" "$((1 - $?))"
assert_match "the record sits on the dated layout" "$(in_state | head -1)" "^$COQ_STATE/records/20[0-9]{2}/[0-9]{2}/[0-9]{14}-[a-z0-9.-]+\.json$"
assert_eq "no record under the slot's events/" "$(in_slot | wc -l | tr -d ' ')" 0
assert_eq "the slot's events/ gained no dated directory" "$(find "$SLOT/events" -maxdepth 1 -name '20*' | wc -l | tr -d ' ')" 0

echo "-- the seat's own bin/event.sh in the slot is the one that wrote it"
before=$(in_state | wc -l | tr -d ' ')
"$SLOT/events/bin/event.sh" add --code 100 --seat "$N" --kind work.started --ticket "$T" --note "case 26 post from the slot" >/dev/null; rc=$?
assert_eq "a post from the slot's event.sh exits 0" "$rc" 0
assert_eq "it added one record to the state root" "$(in_state | wc -l | tr -d ' ')" "$((before + 1))"
assert_eq "and none to the slot's events/" "$(in_slot | wc -l | tr -d ' ')" 0

echo "-- AC-H1: the case fails when the writer is pointed back at the slot's events/"
# The mutant: add writes into the slot's events/ tree (recs=$ROOT), which is what a seat did before A1 (event.sh line ~110).
sed -i 's|recs=\$(coq_tree records) |recs=$ROOT |' "$SLOT/events/bin/event-real.sh"
grep -q 'recs=\$ROOT ' "$SLOT/events/bin/event-real.sh"; check "the mutant writer was built (event.sh still resolves its write tree on a recs= line)" "$((1 - $?))"
state_n=$(in_state | wc -l | tr -d ' ')
"$SLOT/events/bin/event.sh" add --code 100 --seat "$N" --kind work.started --ticket "$T" --note "case 26 mutant" >/dev/null 2>&1
assert_eq "the mutant put one record in the slot's events/, the fault the case names" "$(in_slot | wc -l | tr -d ' ')" 1
assert_eq "and none in the state root, so the 'added one record to the state root' check would fail" "$(in_state | wc -l | tr -d ' ')" "$state_n"
case_done
