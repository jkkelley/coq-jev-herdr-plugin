#!/usr/bin/env bash
# Catches: housekeeping records (seat.up 100, seat.down 100, note 100, record.routed 300) becoming 500 notes to the monitor
# and burying the real 500s (nine in six minutes at 18:32Z on 2026-10-11); an ignore row that also swallows a record it should
# not (a note 500 must still wake the monitor); a record with no row at all no longer being a 500; an ignored record leaving
# any trace but its ledger entry (WO-20261011-4db1 AC-H3).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up ignore
nrec() { "$R/events/bin/event.sh" list | grep -c .; }

echo "-- AC-H3: seat.up, seat.down, note and record.routed records produce no 500 and no receipt"
i1=$(rec seat.up 100 tester-wo-20261011-aaaa $T)
i2=$(rec seat.down 100 tester-wo-20261011-aaaa $T)
i3=$(rec note 100 worker-wo-20261011-aaaa $T)
i4=$(rec record.routed 300 some-other-runner $T)
i5=$(rec seat.up 100 monitor)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "no 500 record of any kind" "$(find "$R/events" -name '*-500-*.json' | wc -l | tr -d ' ')" 0
assert_eq "herdr was not called" "$(hcalls)" 0
assert_eq "no receipt: the only record.routed is the one the case wrote" "$(ids_of record.routed | grep -c .)" 1
assert_eq "five records in the log, none added by the runner" "$(nrec)" 5
for id in $i1 $i2 $i3 $i4 $i5; do assert_eq "ledger says ignored for $id" "$(cat "$STATE/routed/$id")" ignored; done

echo "-- a second tick routes none of them again"
run_once; assert_eq "event count unchanged" "$(nrec)" 5

echo "-- the rows ignore by kind and code: a note 500 still wakes the monitor, a note 429 and a gate 150 are still 500s"
sleep 1; n5=$(rec note 500 route-check $T); n4=$(rec note 429 seat-check $T); g=$(rec gate 150 someone $T)
run_once
assert_match "the note 500 woke the monitor" "$(cat "$HLOG")" "^--session stable agent prompt monitor record $n5 playbook $R/playbooks/monitor.md$"
fives=$(find "$R/events" -name '*-500-*.json' | wc -l | tr -d ' ')
notes=$(cat "$R"/events/20*/*/*-500-*.json | jq -r .note)
assert_match "the note 429 has no row" "$notes" "no route for note 429, record $n4"
assert_match "the gate 150 has no row" "$notes" "no route for gate 150, record $g"
assert_eq "exactly those two new 500s, plus the note 500 the case wrote" "$fives" 3
case_done
