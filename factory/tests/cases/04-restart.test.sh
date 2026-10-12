#!/usr/bin/env bash
# Catches: a stopped and restarted runner routing a record twice, a TERM that waits out the poll interval, and a runner killed
# mid-action repeating its wake instead of telling the monitor (AC-H4).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up restart
start_runner() { "$ROUTE" run --from-start --repo "$R" --state "$STATE" > "$W/run.log" 2>&1 & RUNNER=$!; }
stop_runner() { local t0=$SECONDS; kill -TERM "$RUNNER"; wait "$RUNNER" 2>/dev/null; assert_eq "TERM stops the runner within 3s, not after the 10s poll" "$(( SECONDS - t0 < 3 ))" 1; }
# wait_for N: until the runner has written N receipts, not until herdr was called N times. The prompt goes out a few milliseconds before
# its receipt, and a TERM that lands in between leaves the record "claimed", so the next start reports it as interrupted (a 500 and a
# missing receipt, seen on 2026-10-12 in WO-20261012-3bb0 when the poll happened to land in that window). The cost is that this case
# now waits for the whole route, which is what it means by "the runner woke the tester".
wait_for() { for _ in $(seq 1 40); do [ "$(ids_of record.routed | grep -c .)" -ge "$1" ] && return 0; read -r -t 0.25 <> <(:) || true; done; return 1; }

echo "-- AC-H4: stop and restart over the same events dir"
rec pr.opened 100 worker-wo-20261011-aaaa $T >/dev/null
start_runner; wait_for 1; check "first run woke the tester" "$([ "$(hcalls)" = 1 ] && echo 1 || echo 0)"
stop_runner
sleep 1; rec pr.opened 100 worker-wo-20261011-aaaa $T >/dev/null
start_runner; wait_for 2; read -r -t 1 <> <(:) || true; stop_runner
assert_eq "two records, two wakes: the first was not routed again" "$(hcalls)" 2
assert_eq "two receipts" "$(ids_of record.routed | grep -c .)" 2
start_runner; read -r -t 2 <> <(:) || true; stop_runner
assert_eq "a third start routes nothing" "$(hcalls)" 2

echo "-- a record left claimed by a killed runner is reported, never repeated"
sleep 1; id=$(rec pr.opened 100 worker-wo-20261011-aaaa $T)
printf 'claimed 2026-10-11T00:00:00Z\n' > "$STATE/routed/$id"
run_once; assert_eq "exit 0" "$?" 0
assert_eq "no wake for it" "$(hcalls)" 2
assert_match "a 500 names the interrupted record" "$(cat "$R"/events/20*/*/*-500-*.json | jq -r .note)" "routing of record $id was interrupted; not repeated"
assert_eq "the ledger says interrupted" "$(cat "$STATE/routed/$id")" interrupted
n=$(ids_of note | grep -c .); run_once
assert_eq "and says so only once" "$(ids_of note | grep -c .)" "$n"
case_done
