#!/usr/bin/env bash
# Catches: a tester, reviewer or merger refused on a ticket that is done and archived on its branch while its PR is still
# open (the close-out law archives before the merge, so every PR in review looks like this), a brief for such a seat that
# names no title (brief.sh exited 6 and seat.sh fell back to "the ticket file could not be read; post blocked 423"), and the
# worker losing its refusal on an archived ticket. Live failure 2026-10-11: tester-wo-20261011-9639 on PR 13 (WO-20261011-23df).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up archived || exit 1
export TREEHOUSE_STUB_LOG="$WORLD/treehouse.log"; : > "$TREEHOUSE_STUB_LOG"
ORIGIN="$WORLD/origin.git"; SEED="$WORLD/seed"
git init -q --bare "$ORIGIN"; git clone -q "$ORIGIN" "$SEED" 2>/dev/null
git -C "$SEED" commit -q --allow-empty -m "seed main" && git -C "$SEED" push -q origin main || { echo "case 11: could not seed the origin"; exit 1; }
export TREEHOUSE_STUB_ORIGIN="$ORIGIN"
# The world copies every archived ticket back to the root (world.sh); this case wants one that exists only in archive/,
# the way a checkout carrying the ticket's own branch has it after `work-order done`.
ARCH="$(find "$REPO/work-orders/archive" -name 'WO-*.md' | head -1)"
[ -n "$ARCH" ] || { echo "case 11: the world has no archived ticket to use"; exit 1; }
T="$(basename "$ARCH" | sed -E 's/^(WO-[0-9]{8}-[0-9a-f]{4})-.*/\1/')"
rm -f "$REPO/work-orders/$(basename "$ARCH")"
TITLE="$(awk '/^---$/{c++; next} c==1' "$ARCH" | jq -r .title)"
SLUG="$(awk '/^---$/{c++; next} c==1' "$ARCH" | jq -r .slug)"
git -C "$SEED" checkout -q -b "feat/$SLUG" main && git -C "$SEED" commit -q --allow-empty -m "work on $T" && git -C "$SEED" push -q origin "feat/$SLUG" && git -C "$SEED" checkout -q main
assert_eq "the ticket is only in archive/" "$(find "$REPO/work-orders" -name "$T-*.md" -not -path '*/archive/*' | wc -l | tr -d ' ')" 0

echo "-- a worker on an archived ticket is still refused, before any lease"
"$SEAT" --ticket "$T" --role worker >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_match "the refusal says archived and worker" "$(cat "$WORLD/err")" "archived and role is worker"
assert_eq "no lease was taken" "$(grep -c '^get ' "$TREEHOUSE_STUB_LOG")" 0

echo "-- a tester on the same ticket comes up from the archived copy"
out="$("$SEAT" --ticket "$T" --role tester 2>"$WORLD/err")"; rc=$?
assert_eq "exit 0" "$rc" 0
assert_match "the log says it read the archived copy" "$(cat "$WORLD/err")" "archived in this checkout"
N="tester-wo-${T#WO-}"; N="${N,,}"
assert_eq "the seat is named for the ticket" "$(jq -r .name <<<"$out")" "$N"
assert_eq "the slot is on the ticket's branch" "$(git -C "$(jq -r .worktree <<<"$out")" rev-parse --abbrev-ref HEAD)" "feat/$SLUG"
sleep 1
brief="$(h agent read "$N" --source recent-unwrapped --lines 200)"
assert_match "the brief carries the ticket title, not the 423 fallback" "$brief" "$T - $TITLE"
assert_eq "the brief never says the ticket could not be read" "$(grep -c 'could not be read' <<<"$brief")" 0
assert_match "the brief names what the role denies" "$brief" "Your role denies only: .*Bash\(git \*\)"

echo "-- brief.sh by hand: tester finds the archive, worker does not"
"$REPO/roles/bin/brief.sh" --role tester --ticket "$T" --project "$REPO" >/dev/null 2>&1; assert_eq "tester brief exit 0" "$?" 0
"$REPO/roles/bin/brief.sh" --role worker --ticket "$T" --project "$REPO" >/dev/null 2>&1; assert_eq "worker brief exit 6" "$?" 6
"$SEAT" --down "$N" >/dev/null 2>&1
case_done
