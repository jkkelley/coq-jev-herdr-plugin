#!/usr/bin/env bash
# Catches: a record no routes row matches being dropped, or becoming anything but a 500 note to the monitor; the runner
# routing its own 500 and receipts (a loop); an unreadable file stopping the tick (AC-H2).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up noroute

echo "-- AC-H2: a deploy 250 record matches no row"
id=$(rec deploy 250 someone $T)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "herdr was not called" "$(hcalls)" 0
assert_eq "no receipt" "$(ids_of record.routed | grep -c .)" 0
n=$(files_code 500); assert_eq "one 500 record" "$(printf '%s\n' "$n" | grep -c .)" 1
r=$(cat "$n")
assert_eq "500 is a note addressed to the monitor" "$(jq -r '[.code, .kind, .to, .seat, .ticket] | join(" ")' <<<"$r")" "500 note monitor route-runner $T"
assert_match "it names the record" "$(jq -r .note <<<"$r")" "no route for deploy 250, record $id"

echo "-- the runner does not route its own records: a second tick adds nothing"
before=$(rec_files | wc -l | tr -d ' ')
run_once; run_once
assert_eq "event count unchanged" "$(rec_files | wc -l | tr -d ' ')" "$before"

echo "-- an unreadable file becomes a 500 and does not stop the tick"
sleep 1; d="$STATE/records/$(date -u +%Y/%m)"; printf 'not json' > "$d/$(date -u +%Y%m%d%H%M%S)-note-zzzzz.json"
rec pr.opened 100 worker-wo-20261011-aaaa $T >/dev/null
run_once; assert_eq "exit 0" "$?" 0
assert_eq "the good record after it was still routed" "$(hcalls)" 1
[ "$(hcalls)" = 1 ] || { echo "  DIAG herdr log:"; cat "$HLOG"; echo "  DIAG records and 500 notes:"; rec_files | sed "s|.*/||"; notes_code 500; ls "$STATE/ledger/routed"; }
assert_match "an unreadable-record 500 exists" "$(notes_code 500)" "unreadable record"
case_done
