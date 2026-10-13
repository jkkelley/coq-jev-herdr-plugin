#!/usr/bin/env bash
# record-bus (WO-20261013-1637, Roadmap I; AC-H1): a new record in a stub slot's events/ is copied once into the target records tree and a
# second tick copies nothing. The slot pool is a scratch directory handed to --slots and the state root is the world's, so no typed
# treehouse path is read or written; the real, unmodified line/bin/record-bus.sh runs with --once, one tick per call.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"; world_init
BUS=$REPO/line/bin/record-bus.sh
bus() { bash "$BUS" --once --slots "$W/pool" --held "$W/held" "$@"; }

yy=$(date -u +%Y); mm=$(date -u +%m)
id() { printf '%s-100-%s' "$(date -u +%Y%m%dT%H%M%SZ)" "$1"; }
slot_dir=$W/pool/1/repo/events/$yy/$mm; mkdir -p "$slot_dir" "$W/held"
put() { printf '{"id":"%s","code":100}\n' "${2%.json}" > "$1/$2"; }   # put DIR NAME: a well-formed record whose id is its name

echo "-- a new slot record is copied once into the state root's records tree (the default target)"
new=$(id b0001).json; put "$slot_dir" "$new"
out=$(bus); assert_match "tick 1 reports the copy, naming the slot" "$out" "bus 1 -> $new$"
assert_file "the record is in the target" "$W/state/records/$yy/$mm/$new"
assert_eq "the copy is the slot's record" "$(cmp -s "$slot_dir/$new" "$W/state/records/$yy/$mm/$new" && echo same)" same
out=$(bus); assert_eq "tick 2 copies nothing" "$out" ""
assert_eq "one file in the target" "$(find "$W/state/records" -name '*.json' | wc -l)" 1

echo "-- a record that is not a record, a held record and a record older than the window are left alone"
bad=$(id b0002).json; printf 'not json\n' > "$slot_dir/$bad"
held=$(id b0003).json; put "$slot_dir" "$held"; : > "$W/held/$held"
old=20200101T000000Z-100-b0004.json; put "$slot_dir" "$old"
out=$(bus); assert_eq "tick 3 copies nothing" "$out" ""
assert_no_file "the broken file stays out" "$W/state/records/$yy/$mm/$bad"
assert_no_file "the held record stays out" "$W/state/records/$yy/$mm/$held"
assert_no_file "the old record stays out" "$W/state/records/$yy/$mm/$old"

echo "-- every file the script wrote is under the state root, and none is a .tmp"
assert_eq "no .tmp left behind" "$(find "$W" -name '*.tmp' | wc -l)" 0
assert_eq "only the pool, held list and fixtures sit outside the state root" "$(find "$W" -newer "$slot_dir/$new" -type f -not -path "$W/state/*" -not -path "$W/pool/*" -not -path "$W/held/*" -not -path "$W/bin/*" -not -name 'board.json' -not -name herdr.log | wc -l)" 0

echo "-- --target elsewhere: the slot record and the state root's own record both land there, each once"
t=$W/checkout-events
sr=$(id b0005); mkdir -p "$W/state/records/$yy/$mm"; printf '{"id":"%s","code":100}\n' "$sr" > "$W/state/records/$yy/$mm/$(date -u +%Y%m%d%H%M%S)-note-$sr.json"
out=$(bus --target "$t")
assert_file "the slot record is in the target" "$t/$yy/$mm/$new"
assert_file "the state root record is in the target under its id" "$t/$yy/$mm/$sr.json"
assert_eq "two lines, one per record" "$(printf '%s\n' "$out" | grep -c ' -> ')" 2
out=$(bus --target "$t"); assert_eq "a second tick copies nothing" "$out" ""
assert_no_file "the held record is not in the target either" "$t/$yy/$mm/$held"

echo "-- the default target never copies a state root record back into itself"
before=$(find "$W/state/records" -name '*.json' | wc -l); bus >/dev/null
assert_eq "the state root records tree did not grow by a copy under an id name" "$(find "$W/state/records" -name '*.json' | wc -l)" "$before"

echo "-- usage errors"
bash "$BUS" --bogus >/dev/null 2>&1; assert_eq "an unknown flag: exit 2" "$?" 2
bash "$BUS" --window abc >/dev/null 2>&1; assert_eq "a window that is not a number: exit 2" "$?" 2
bash "$BUS" --target relative/dir >/dev/null 2>&1; assert_eq "a relative target: exit 2" "$?" 2

echo "-- the script carries no typed machine path"
assert_eq "no /home/luna in it" "$(grep -c '/home/luna' "$BUS")" 0
assert_eq "no .cache/coq-watch in it" "$(grep -c '\.cache/coq-watch' "$BUS")" 0
case_done
