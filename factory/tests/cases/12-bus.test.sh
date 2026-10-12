#!/usr/bin/env bash
# Catches (WO-20261012-da52): a record written in a treehouse slot that never reaches the checkout's events/ (the belt then never
# routes it and the architect copies it by hand), a copy that is not byte identical, a record copied twice, a record the architect
# removed from the checkout coming back, a half-written record routed, a slot typed into the script instead of read from
# treehouse, a record that takes longer than ten seconds, and a path in the user cache directory left in herdr/ or factory/.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up bus
BUS="$R/factory/bin/bus.sh"; BSTATE="$W/bstate"
# Two slots under the world, each with its own event.sh (event.sh writes into the tree it lives in, which is the fault being fixed).
mkslot() { mkdir -p "$W/slots/$1/events"; cp -r "$R/events/bin" "$R/events/schema" "$W/slots/$1/events/"; }
mkslot 1; mkslot 2
th() { jq -nc --argjson n "$1" '[range(1; $n + 1) | {name: (. | tostring), path: ("'"$W"'/slots/" + (. | tostring)), status: "leased"}]' > "$W/th.json"; }
th 2
printf '#!/usr/bin/env bash\npwd > "%s/th.cwd"\n[ ! -e "%s/th.fail" ] || exit 1\ncat "%s/th.json"\n' "$W" "$W" "$W" > "$W/bin/treehouse"; chmod +x "$W/bin/treehouse"
slotrec() { "$W/slots/$1/events/bin/event.sh" add --code 100 --seat "$2" --kind "${3:-work.started}" --ticket WO-20261012-aaaa --note "from slot $1"; }
slotfile() { find "$W/slots/$1/events" -name "$2.json"; }
ckfile() { find "$R/events" -name "$1.json"; }
bus_once() { "$BUS" once --repo "$R" --state "$BSTATE" 2>"$W/bus.err"; }

echo "-- a record older than the lookback is history, not new (the slot's events/ also holds its branch's committed records)"
old="$W/slots/1/events/2020/01"; mkdir -p "$old"; echo '{"id":"20200101T000000Z-100-oldoo"}' > "$old/20200101T000000Z-100-oldoo.json"
bus_once; assert_eq "the first tick copied nothing" "$(find "$R/events" -name '20200101*' | wc -l | tr -d ' ')" 0

echo "-- AC-H1: a record written in a slot appears in the checkout, byte identical, once"
sleep 1; a=$(slotrec 1 worker-wo-20261012-aaaa); bus_once
assert_file "the checkout holds the record" "$(ckfile "$a")"
cmp -s "$(slotfile 1 "$a")" "$(ckfile "$a")"; assert_eq "byte identical" "$?" 0
assert_eq "at the same relative path" "$(ckfile "$a" | sed "s|^$R/||")" "$(slotfile 1 "$a" | sed "s|^$W/slots/1/||")"
m1=$(stat -c %Y%N "$(ckfile "$a")"); sleep 1; bus_once; bus_once
assert_eq "still one file" "$(find "$R/events" -name "$a.json" | wc -l | tr -d ' ')" 1
assert_eq "and not rewritten by the next ticks" "$(stat -c %Y%N "$(ckfile "$a")")" "$m1"
assert_eq "no partial file left" "$(find "$R/events" -name '*.tmp' | wc -l | tr -d ' ')" 0

echo "-- the slots are read from treehouse, run in the repo, and a second slot is served too"
assert_eq "treehouse ran in the repo" "$(cat "$W/th.cwd")" "$R"
sleep 1; b=$(slotrec 2 tester-wo-20261012-aaaa test.passed); bus_once
assert_file "slot 2's record reached the checkout" "$(ckfile "$b")"
echo "-- a slot that joins the pool later is picked up with no edit"
mkslot 3; th 3; sleep 1; c=$(slotrec 3 reviewer-wo-20261012-aaaa); bus_once
assert_file "slot 3's record reached the checkout" "$(ckfile "$c")"

echo "-- a record the architect removed from the checkout does not come back"
rm -f "$(ckfile "$a")"; bus_once; bus_once
assert_eq "held out for good" "$(ckfile "$a" | wc -l | tr -d ' ')" 0

echo "-- a half-written record is not copied; once it parses it is"
sleep 1; d=$(slotrec 1 worker-wo-20261012-bbbb); df=$(slotfile 1 "$d"); cp "$df" "$W/d.json"; head -c 20 "$W/d.json" > "$df"; bus_once
assert_eq "the torn record stayed in the slot" "$(ckfile "$d" | wc -l | tr -d ' ')" 0
cp "$W/d.json" "$df"; bus_once; assert_file "copied once complete" "$(ckfile "$d")"
cmp -s "$df" "$(ckfile "$d")"; assert_eq "byte identical after the retry" "$?" 0

echo "-- a same-named file that differs is never overwritten"
sleep 1; e=$(slotrec 1 worker-wo-20261012-cccc)
edst="$R/$(slotfile 1 "$e" | sed "s|^$W/slots/1/||")"; mkdir -p "$(dirname "$edst")"; echo '{"id":"mine"}' > "$edst"
bus_once; assert_eq "the checkout's file kept its bytes" "$(jq -r .id "$(ckfile "$e")")" mine
assert_match "and the clash was logged" "$(cat "$W/bus.err")" "differs"

echo "-- treehouse failing is one logged line per outage, no crash, and the next tick recovers"
: > "$W/th.fail"; sleep 1; f=$(slotrec 1 worker-wo-20261012-dddd)
"$BUS" once --repo "$R" --state "$BSTATE" 2>"$W/bus.err"; assert_eq "exit 0 during the outage" "$?" 0
assert_eq "nothing copied" "$(ckfile "$f" | wc -l | tr -d ' ')" 0
assert_match "the outage was logged" "$(cat "$W/bus.err")" "treehouse status failed"
rm -f "$W/th.fail"; bus_once; assert_file "copied after treehouse came back" "$(ckfile "$f")"

echo "-- AC-H1: run mode delivers inside ten seconds"
"$BUS" run --repo "$R" --state "$BSTATE" > "$W/run.log" 2>&1 & BUSPID=$!
sleep 1; t0=$(date +%s); g=$(slotrec 2 tester-wo-20261012-eeee test.passed)
for _ in $(seq 1 100); do [ -n "$(ckfile "$g")" ] && break; read -r -t 0.1 <> <(:) || true; done
took=$(( $(date +%s) - t0 ))
kill -TERM "$BUSPID"; wait "$BUSPID" 2>/dev/null
assert_file "the record reached the checkout" "$(ckfile "$g")"
check "within ten seconds (took ${took}s)" "$([ "$took" -lt 10 ] && echo 1 || echo 0)"
assert_match "the run printed the copy" "$(cat "$W/run.log")" "bus .*slots/2 -> $g.json"

echo "-- the belt routes a seat's record with no copy by hand"
sleep 1; T=WO-20261012-ffff; slot_pr=$("$W/slots/1/events/bin/event.sh" add --code 100 --seat worker-wo-20261012-ffff --kind pr.opened --ticket $T --pr 7 --sha abcdef1)
bus_once; run_once
assert_eq "the tester was seated for the ticket" "$(grep -c -e "--ticket $T --role tester" "$W/seat.log")" 1
assert_match "and woken with the record" "$(tail -1 "$HLOG")" "agent prompt tester-wo-20261012-ffff record $slot_pr pr 7 sha abcdef1 playbook"

echo "-- AC-H2: no path in the user cache directory in herdr/ or factory/"
pat='\.ca''che'
assert_eq "grep finds none" "$(grep -rn "$pat" "$R/factory" "${REPO_ROOT:-/repo}/herdr" "${REPO_ROOT:-/repo}/factory" 2>/dev/null | wc -l | tr -d ' ')" 0
case_done
