#!/usr/bin/env bash
# Catches: a belt file touched only when there is work, one that keeps moving after the runner stops, and a status that does not
# read the age (AC-H6). The 60 second threshold is stale_seconds in runner.json; the file is backdated rather than waited out.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up belt
jq '.poll_seconds = 5' "$R/factory/config/runner.json" > "$W/runner.json"
belt="$STATE/belt"

echo "-- status with no belt file"
"$ROUTE" status --repo "$R" --state "$STATE" >/dev/null; assert_eq "no belt: exit 1" "$?" 1

echo "-- a running runner touches the belt every tick, work or no work"
"$ROUTE" run --config "$W/runner.json" --repo "$R" --state "$STATE" > "$W/run.log" 2>&1 & RUNNER=$!
for _ in $(seq 1 20); do [ -f "$belt" ] && break; read -r -t 0.25 <> <(:) || true; done
assert_file "belt file written on the first tick" "$belt"
m1=$(stat -c %Y "$belt"); read -r -t 6.5 <> <(:) || true; m2=$(stat -c %Y "$belt")
check "the belt moved on the next tick with nothing to route" "$([ "$m2" -gt "$m1" ] && echo 1 || echo 0)"
"$ROUTE" status --repo "$R" --state "$STATE" | grep -q 'belt: running'; assert_eq "status: running, exit 0" "${PIPESTATUS[0]}" 0

echo "-- after a stop the belt stops moving and goes stale"
kill -TERM "$RUNNER"; wait "$RUNNER" 2>/dev/null; m3=$(stat -c %Y "$belt"); read -r -t 6 <> <(:) || true
assert_eq "no touch after the stop" "$(stat -c %Y "$belt")" "$m3"
touch -d '-61 seconds' "$belt"
out=$("$ROUTE" status --repo "$R" --state "$STATE"); rc=$?
assert_eq "61 seconds old: exit 1" "$rc" 1
assert_match "and it says stopped" "$out" "belt: stopped"
touch -d '-59 seconds' "$belt"; "$ROUTE" status --repo "$R" --state "$STATE" >/dev/null; assert_eq "59 seconds old: still fresh" "$?" 0
case_done
