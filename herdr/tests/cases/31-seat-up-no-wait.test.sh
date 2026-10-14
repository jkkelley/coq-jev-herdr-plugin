#!/usr/bin/env bash
# Catches: a claude seat whose guard sends no ack line holding seat.sh, and with it route.sh's serial belt tick, for longer than the
# belt's stale_seconds (AC-H1: 180 s per bring-up on 2026-10-13, WO-20261013-7af7), a shipped nudge_wait_seconds the schema would let
# grow back past that budget, and the nudge-once behaviour of a seat that does ack being lost by the shortening (AC-H2; case 11 holds
# the full matrix). This case runs with the SHIPPED nudge_wait_seconds (herdr/config/herdr.json), not the 1 s the world defaults to, because
# the shipped value is what the belt pays. WO-20261013-7af7.
# AC-H3 (reviewer ruling on PR 163, architect note ha64w): the real factory/bin/route.sh drives the same stubbed bring-up through a
# pr.opened 100 record, and `route.sh status` is polled before, during and after it; every poll must read running.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
CFG="$HERE/../../config/herdr.json"; SCHEMA="$HERE/../../config/herdr.schema.json"
SHIPPED="$(jq -r .nudge_wait_seconds "$CFG")"
BUDGET="$(jq -r .stale_seconds "$HERE/../../../factory/config/runner.json")"
world_up nudgewait ".nudge_wait_seconds = $SHIPPED | .nudge_settle_seconds = 4" || exit 1
A=WO-20261010-8777; NA=worker-wo-20261010-8777
B=WO-20261010-c274; NB=worker-wo-20261010-c274
MODE="$HOME/claude-stub.mode"
nudges() { h agent read "$1" --source recent-unwrapped --lines 300 | grep -c '^> .*[Cc]ontinue your brief'; }
nudged_once() { [ "$(nudges "$1")" -ge 1 ]; }

echo "-- the shipped value fits the belt: below the schema cap and below route.sh stale_seconds ($BUDGET)"
assert_eq "the shipped nudge_wait_seconds is below the belt's stale budget" "$([ "$SHIPPED" -lt "$BUDGET" ] && echo yes || echo no)" yes
assert_eq "the schema caps nudge_wait_seconds below the belt's stale budget" \
  "$(jq -r --argjson b "$BUDGET" '.properties.nudge_wait_seconds.maximum as $m | if $m != null and $m < $b then "yes" else "no" end' "$SCHEMA")" yes
assert_eq "the shipped value is inside the schema cap" "$([ "$SHIPPED" -le "$(jq -r .properties.nudge_wait_seconds.maximum "$SCHEMA")" ] && echo yes || echo no)" yes

echo "-- AC-H1: a seat that never prints the ack comes up in under $BUDGET s with no nudge"
: > "$MODE"
t0=$SECONDS; "$SEAT" --ticket "$A" --role worker --worktree "$REPO" >/dev/null 2>"$WORLD/err-$A"; rc=$?; took=$((SECONDS - t0))
assert_eq "seat.sh exits 0" "$rc" 0
assert_eq "the bring-up held the caller for less than $BUDGET s (took ${took}s)" "$([ "$took" -lt "$BUDGET" ] && echo yes || echo no)" yes
assert_match "the log says no ack arrived within the shipped wait" "$(cat "$WORLD/err-$A")" "seat $NA: no guard ack within ${SHIPPED}s, no nudge"
assert_eq "no continue prompt was sent" "$(nudges "$NA")" 0
assert_eq "seat.json nudged_at is null" "$(jq -c .nudged_at "$STATE/seats/$NA/seat.json")" null
"$SEAT" --down "$NA" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- AC-H2: a seat that prints the ack and then idles is still nudged exactly once, with the shipped wait"
echo ack > "$MODE"
t0=$SECONDS; "$SEAT" --ticket "$B" --role worker --worktree "$REPO" >/dev/null 2>"$WORLD/err-$B"; rc=$?; took=$((SECONDS - t0))
assert_eq "seat.sh exits 0" "$rc" 0
assert_eq "an acking seat is also back in under $BUDGET s (took ${took}s)" "$([ "$took" -lt "$BUDGET" ] && echo yes || echo no)" yes
assert_match "the log says the seat was nudged once" "$(cat "$WORLD/err-$B")" "seat $NB: idle after the guard ack, nudged once"
wait_until 10 nudged_once "$NB"
assert_eq "the seat received exactly one continue prompt" "$(nudges "$NB")" 1
"$SEAT" --down "$NB" >/dev/null; assert_eq "--down exits 0" "$?" 0
# BREADCRUMB 2026-10-14 - WO-20261013-7af7, rework of PR 163. What broke: AC-H3 ("a live bring-up through route.sh leaves route.sh status
#   'running' throughout") sat unticked because the only proof was the seat.sh wall time (AC-H1), a proxy: it never ran the runner, so
#   nothing here would fail if route.sh went back to holding its belt past stale_seconds some other way. Why this fix: the same stubbed
#   seat (the stub claude that never acks, the shipped nudge_wait_seconds) is brought up by the REAL factory/bin/route.sh once, started
#   from a pr.opened 100 record through the default routes table (a `seat` row, route.sh:185), and route.sh status is polled every second
#   from before it starts until it returns. route.sh reads age against stale_seconds from factory/config/runner.json, the same figure
#   AC-H1 uses as BUDGET. Rejected: a live bring-up (a worker seat may not seat a real agent, and the world is the stub's) and a fake
#   seat.sh behind route.sh (it would prove the runner, not the real seat.sh wait). Cost: about 25 s more in this case, the bring-up itself.
echo "-- AC-H3: route.sh status reads running before, during and after a bring-up route.sh drives"
ROUTE="$REPO/factory/bin/route.sh"; NT=tester-wo-20261010-8777
route() { "$ROUTE" "$@" --repo "$REPO" --state "$STATE"; }
# route.sh calls seat.sh with no --worktree, so the seat leases a slot of the stub treehouse pool, a clone of a bare origin that
# holds the ticket's branch (the arrangement of case 08).
ORIGIN="$WORLD/origin.git"; SEED="$WORLD/seed"
git init -q --bare "$ORIGIN"; git clone -q "$ORIGIN" "$SEED" 2>/dev/null
git -C "$SEED" commit -q --allow-empty -m "seed main" && git -C "$SEED" push -q origin main || { echo "case 31: could not seed the origin"; exit 1; }
TBRANCH="$(awk '/^---$/{c++; next} c==1' "$(find "$REPO/work-orders" -name "$A-*.md" -not -path '*/archive/*' | head -1)" | jq -r .branch)"
git -C "$SEED" checkout -q -b "$TBRANCH" main && git -C "$SEED" commit -q --allow-empty -m "work on $TBRANCH" \
  && git -C "$SEED" push -q origin "$TBRANCH" || { echo "case 31: could not put $TBRANCH on the origin"; exit 1; }
export TREEHOUSE_STUB_ORIGIN="$ORIGIN"
: > "$MODE"
route once >/dev/null 2>"$WORLD/route-first.err"; assert_eq "an idle first tick exits 0 and starts the belt" "$?" 0
route status >/dev/null; assert_eq "route.sh status is running before the bring-up" "$?" 0
"$REPO/events/bin/event.sh" add --code 100 --seat worker-wo-20261010-8777 --kind pr.opened --ticket "$A" --sha abc1234 --pr 5 \
  --note "AC-H3 fixture: a pr.opened that makes route.sh seat a tester" >/dev/null; assert_eq "the pr.opened record was posted" "$?" 0
route once >"$WORLD/route.out" 2>"$WORLD/route.err" & rp=$!
polls=0; stopped=0; worst=0
while kill -0 "$rp" 2>/dev/null; do
  out=$(route status); rc=$?; polls=$((polls + 1))
  [ "$rc" = 0 ] || { stopped=$((stopped + 1)); echo "  status poll $polls: $out"; }
  age=$(sed -n 's/^belt: running (touched \([0-9]*\)s ago)$/\1/p' <<<"$out"); [ -z "$age" ] || [ "$age" -le "$worst" ] || worst=$age
  sleep 1
done
wait "$rp"; assert_eq "route.sh once exits 0" "$?" 0
# a refused bring-up is a 500 note that route.sh writes; show it so a failure below says why
for f in "$EVENTS"/2*/*/*.json; do jq -r 'select(.code == 500) | "  route 500: " + .note' "$f" 2>/dev/null; done
check "route.sh status was polled while the bring-up ran ($polls polls)" "$([ "$polls" -ge 3 ] && echo 1 || echo 0)"
assert_eq "no poll during the bring-up read stopped (oldest belt seen ${worst}s, budget ${BUDGET}s)" "$stopped" 0
# route.sh keeps seat.sh's stderr (it is only the reason of a refusal), so the no-ack path is read off the seat record instead
assert_eq "the bring-up was the no-ack one: the tester was never nudged" "$(jq -c .nudged_at "$STATE/seats/$NT/seat.json")" null
route status >/dev/null; assert_eq "route.sh status is running after the bring-up" "$?" 0
assert_eq "the tester seat is up" "$("$SEAT" --check "$NT" >/dev/null 2>&1; echo $?)" 0
assert_eq "the runner counted the record done, not failed" "$(cat "$STATE"/ledger/routed/*pr-opened* 2>/dev/null | tr -d '\n')" "done seat"
"$SEAT" --down "$NT" >/dev/null; assert_eq "--down exits 0" "$?" 0
case_done
