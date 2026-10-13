#!/usr/bin/env bash
# Catches: note 300 and work.started 100 matching no row, so each became a "no route for ..." 500 to the monitor (16 of the 25 route
# 500s on 2026-10-13 were these two, record 8pj4r), burying the real failures; an ignore row that also swallows a record it should
# not (a note 500 and a work.started 500 must still wake the monitor); an unknown kind no longer being a 500 (WO-20261013-7a76 AC-H1).
#
# BREADCRUMB 2026-10-13 - WO-20261013-7a76, cause m. What broke: factory/config/routes.json had ignore rows for seat.up 100,
#   seat.down 100, note 100 and record.routed 300 only, so the two kinds seats post most (work.started 100 at every start, note
#   300 for progress notes) fell to route.sh's "no route for" 500. Why this fix: two explicit ignore rows in routes.json, the table
#   being the one place a behaviour is written (route.sh line "no route for $kind $code" stays the answer for everything else).
#   This supersedes the work.started paragraph of the 4db1 breadcrumb in factory/bin/route.sh, which says the row waits for a
#   change to report/loop/lib/collect.jq: station_for there selects stations with .role == $row.to, an ignore row has no `to`
#   (routes.schema.json forbids it), so it yields null and the board falls back to emitter_of($last), the worker station, which
#   is where a work.started ticket already sat. JSON has no comment syntax, so the reason lives here.
#   Rejected: a skip list of kinds inside route.sh and filtering the monitor's 500s by text. Cost: like every ignored record,
#   these leave only their ledger entry, and collect.jq counts them as routed.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261013-aaaa
world_up noroutenoise

echo "-- AC-H1: note 300 and work.started 100 route to ignore, with no 500, no receipt and no herdr call"
i1=$(rec note 300 worker-wo-20261013-aaaa $T)
i2=$(rec work.started 100 worker-wo-20261013-aaaa $T)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "no 500 record of any kind" "$(files_code 500 | wc -l | tr -d ' ')" 0
assert_eq "herdr was not called" "$(hcalls)" 0
assert_eq "no receipt: the runner wrote no record.routed" "$(ids_of record.routed | grep -c .)" 0
for id in $i1 $i2; do assert_eq "ledger says ignored for $id" "$(cat "$(ledger_of "$id")")" ignored; done

echo "-- a second tick routes neither again"
before=$(rec_files | wc -l | tr -d ' ')
run_once; assert_eq "record count unchanged" "$(rec_files | wc -l | tr -d ' ')" "$before"

echo "-- AC-H1: an unknown kind still posts a 500, and a 500 of either kind still wakes the monitor"
sleep 1; u=$(rec deploy 250 someone $T); n5=$(rec note 500 route-check $T); w5=$(rec work.started 500 worker-wo-20261013-aaaa $T)
n2=$(rec note 299 seat-check $T); w2=$(rec work.started 101 worker-wo-20261013-aaaa $T)
run_once
notes=$(notes_code 500)
assert_match "the unknown kind has no row" "$notes" "no route for deploy 250, record $u"
assert_match "note 299 is not the ignored note 300" "$notes" "no route for note 299, record $n2"
assert_match "work.started 101 is not the ignored work.started 100" "$notes" "no route for work.started 101, record $w2"
assert_match "the note 500 woke the monitor" "$(cat "$HLOG")" "^--session stable agent prompt monitor record $n5 playbook $R/playbooks/monitor.md$"
assert_match "the work.started 500 woke the monitor" "$(cat "$HLOG")" "^--session stable agent prompt monitor record $w5 playbook $R/playbooks/monitor.md$"
assert_eq "three new 500s (deploy, note 299, work.started 101) plus the two the case wrote" "$(files_code 500 | wc -l | tr -d ' ')" 5
case_done
