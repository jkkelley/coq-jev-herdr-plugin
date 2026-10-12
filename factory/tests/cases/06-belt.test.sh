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
# BREADCRUMB 2026-10-12 - WO-20261011-4db1. What broke: this case backdated the belt 61 seconds and wanted stopped, then 59 and
#   wanted fresh. Run 49ab55b failed it once (test.failed 422 20261012T132330Z-422-hyds1: "belt: running (touched 60s ago)").
#   The wall clock on this WSL2 host steps back about 1.05 s every ~35 s (realtime minus /proc/uptime, sampled across 20 runs of
#   this case, fell from ...044.0 to ...035.6), so a step between the touch below and route.sh's `date +%s` makes a 61 second
#   belt 60 seconds old. 3000 backdates with no step always read 61 or 62, never 60, so the fault is the 1 second margin and not
#   the arithmetic. Why this fix: the real-clock checks keep a wide margin (65 and 55), and the exact boundary is pinned with a
#   `date` stub that fixes `+%s`, which no clock step can move. Rejected: only widening the margin, which would leave the exact
#   boundary untested and let the -le/-lt contradiction (route.sh header says "fresher than", the code said <=) hide again.
#   Cost: the boundary block proves route.sh's comparison, not the real clock; the 65 and 55 checks keep that covered.
touch -d '-65 seconds' "$belt"
out=$("$ROUTE" status --repo "$R" --state "$STATE"); rc=$?
assert_eq "65 seconds old: exit 1" "$rc" 1
assert_match "and it says stopped" "$out" "belt: stopped"
touch -d '-55 seconds' "$belt"; "$ROUTE" status --repo "$R" --state "$STATE" >/dev/null; assert_eq "55 seconds old: still fresh" "$?" 0

echo "-- the boundary itself, with the clock fixed: fresher than 60 is running, 60 and older is stopped"
mkdir -p "$W/fakedate"
printf '#!/usr/bin/env bash\n[ "$1" = "+%%s" ] && { echo "$FAKE_EPOCH"; exit 0; }\nexec /usr/bin/date "$@"\n' > "$W/fakedate/date"; chmod +x "$W/fakedate/date"
touch -d @1000000000 "$belt"
for pair in "59 0 running" "60 1 stopped" "61 1 stopped"; do
  set -- $pair
  out=$(FAKE_EPOCH=$((1000000000 + $1)) PATH="$W/fakedate:$PATH" "$ROUTE" status --repo "$R" --state "$STATE"); rc=$?
  assert_eq "$1 seconds old: exit $2" "$rc" "$2"
  assert_match "$1 seconds old: says $3" "$out" "belt: $3"
done
case_done
