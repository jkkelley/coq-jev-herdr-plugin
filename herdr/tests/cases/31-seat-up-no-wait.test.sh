#!/usr/bin/env bash
# Catches: a claude seat whose guard sends no ack line holding seat.sh, and with it route.sh's serial belt tick, for longer than the
# belt's stale_seconds (AC-H1: 180 s per bring-up on 2026-10-13, WO-20261013-7af7), a shipped nudge_wait_seconds the schema would let
# grow back past that budget, and the nudge-once behaviour of a seat that does ack being lost by the shortening (AC-H2; case 11 holds
# the full matrix). This case runs with the SHIPPED nudge_wait_seconds (herdr/config/herdr.json), not the 1 s the world defaults to, because
# the shipped value is what the belt pays. WO-20261013-7af7.
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
case_done
