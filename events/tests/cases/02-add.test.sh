#!/usr/bin/env bash
# Catches: a record written into the repository instead of the state root, a name that says nothing or is over the limit, an overwrite
# when two records share a second and a name, and a half-written file visible to a reader (WO-20261012-7e13 AC-H1, AC-H2, AC-H3).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up add
T=WO-20261012-7e13
STEM='[0-9]{14}-[a-z0-9]+(-[a-z0-9]+)*'

echo "-- AC-H1: COQ_STATE unset, the record lands under the default state root and the path is printed"
out=$("$EV" add --code 100 --seat worker-wo-20261012-7e13 --kind work.started --ticket $T --note "started"); assert_eq "exit" "$?" 0
assert_match "one line, a path under <XDG state>/coq/<repo>/records/YYYY/MM/" "$out" "^$W/home/.local/state/coq/repo/records/2026/10/[0-9]{14}-work-started-wo-20261012-7e13\\.json$"
assert_file "the printed path exists" "$out"
assert_eq "only one line was printed" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" 1
assert_eq "nothing was written into the repository's events/ tree" "$(find "$R/events" -mindepth 3 -name '*.json' | wc -l | tr -d ' ')" 0
assert_eq "no temporary file was left in the folder" "$(find "$W/home/.local/state" -name '.*' -type f | wc -l | tr -d ' ')" 0

echo "-- AC-H2: COQ_STATE set, the record lands there under a timestamped descriptive name and validates"
export COQ_STATE="$W/s"
p=$("$EV" add --code 100 --seat tester --kind test.passed --ticket WO-20261012-0677 --pr 36 --sha 0123abc --note "ok"); assert_eq "exit" "$?" 0
assert_match "YYYYMMDDHHMMSS-test-passed-pr-36-wo-20261012-0677.json in records/YYYY/MM" "$p" "^$W/s/records/20[0-9]{2}/[0-9]{2}/[0-9]{14}-test-passed-pr-36-wo-20261012-0677\\.json$"
validate "$p"; assert_eq "the record validates against events/schema/event.schema.json" "$?" 0
b=$(basename "$p" .json)
assert_eq "the file name's time is the record's at" "${b:0:14}" "$(jq -r .at "$p" | tr -d ':TZ-')"
assert_eq "its folder is that year and month" "$(basename "$(dirname "$(dirname "$p")")")/$(basename "$(dirname "$p")")" "${b:0:4}/${b:4:2}"
assert_match "the record's own id keeps its shape" "$(jq -r .id "$p")" "^[0-9]{8}T[0-9]{6}Z-100-[a-z0-9]{5}$"
assert_eq "pr and sha are fields" "$(jq -c '[.pr,.sha]' "$p")" '[36,"0123abc"]'
j=$("$EV" add --code 300 --seat architect --kind note --json --note "as json"); assert_eq "--json prints the record" "$(printf '%s' "$j" | jq -r .note)" "as json"
p=$("$EV" add --code 100 --seat seat-up --kind seat.up); assert_match "no ticket: the seat names it" "$p" "/[0-9]{14}-seat-up-seat-up\\.json$"
p=$("$EV" add --code 100 --seat 'Odd_Seat.name' --kind note 2>/dev/null); rc=$?; assert_eq "a seat that breaks the pattern is refused" "$rc" 2

echo "-- the name is lowercase, hyphens only, and never over name_max"
p=$("$EV" add --code 100 --seat a-very-long-seat-name-of-31-ch --kind request.forwarded --pr 123456 --note long); b=$(basename "$p" .json); stem=${b:15}
assert_match "a stem of letters, digits and hyphens" "$b" "^$STEM$"
check "the stem is at most 55 characters (got ${#stem})" "$([ ${#stem} -le 55 ] && echo 1 || echo 0)"
check "the stem does not end in a hyphen" "$([[ $stem != *- ]] && echo 1 || echo 0)"
assert_match "it still starts with what the record is" "$stem" "^request-forwarded-pr-123456-a-very-long-seat"

echo "-- AC-H3: same second, same name: -2, -3, nothing overwritten"
freeze_clock 5
a=$("$EV" add --code 100 --seat worker --kind blocked --ticket $T --note first)
b=$("$EV" add --code 100 --seat worker --kind blocked --ticket $T --note second)
c=$("$EV" add --code 100 --seat worker --kind blocked --ticket $T --note third)
assert_eq "first is <name>.json" "$(basename "$a")" "20261012220005-blocked-wo-20261012-7e13.json"
assert_eq "second is <name>-2.json" "$(basename "$b")" "20261012220005-blocked-wo-20261012-7e13-2.json"
assert_eq "third is <name>-3.json" "$(basename "$c")" "20261012220005-blocked-wo-20261012-7e13-3.json"
assert_eq "the first file still holds the first note" "$(jq -r .note "$a")" first
assert_eq "the others hold theirs" "$(jq -r .note "$b")/$(jq -r .note "$c")" second/third
long=(--code 100 --seat a-very-long-seat-name-of-31-ch --kind request.forwarded --pr 123456)
x=$("$EV" add "${long[@]}" --note x); y=$("$EV" add "${long[@]}" --note y)
sx=$(basename "$x" .json); sy=$(basename "$y" .json)
check "a clash at the limit: the first stem is 55 characters (got $(( ${#sx} - 15 )))" "$([ $(( ${#sx} - 15 )) -eq 55 ] && echo 1 || echo 0)"
check "a clash at the limit: the second stem ends -2 and is still at most 55 (got $(( ${#sy} - 15 )))" "$([[ $sy == *-2 && $(( ${#sy} - 15 )) -le 55 ]] && echo 1 || echo 0)"
assert_eq "a different name in the same second is its own file" "$(basename "$("$EV" add --code 100 --seat worker --kind gate --ticket $T)")" "20261012220005-gate-wo-20261012-7e13.json"

echo "-- eight writers at once, one frozen second, one name: eight files, none lost"
rm -rf "$W/s"
seq 1 8 | xargs -P 8 -I{} "$EV" add --code 100 --seat racer --kind note --ticket $T --note "writer-{}" >/dev/null
assert_eq "eight files" "$(find "$W/s/records" -name '*.json' | wc -l | tr -d ' ')" 8
assert_eq "every note is present" "$(find "$W/s/records" -name '*.json' -exec jq -r .note {} + | sort | tr '\n' ' ')" "writer-1 writer-2 writer-3 writer-4 writer-5 writer-6 writer-7 writer-8 "
assert_eq "no temporary file is left" "$(find "$W/s" -name '.*' -type f | wc -l | tr -d ' ')" 0
rm -f "$W/bin/date"

echo "-- refusals, with nothing written"
rm -rf "$W/s"
"$EV" add --code 99 --seat s --kind note >/dev/null 2>&1; assert_eq "bad code exit" "$?" 2
"$EV" add --code 100 --seat s --kind nope >/dev/null 2>&1; assert_eq "bad kind exit" "$?" 2
"$EV" add --code 100 --seat s --kind note --pr 0 >/dev/null 2>&1; assert_eq "bad pr exit" "$?" 2
"$EV" add --code 100 --seat s --kind note --ticket WO-1 >/dev/null 2>&1; assert_eq "bad ticket exit" "$?" 3
COQ_STATE=relative "$EV" add --code 100 --seat s --kind note >/dev/null 2>"$W/err"; assert_eq "relative COQ_STATE exit" "$?" 3
assert_eq "nothing was written by any of them" "$(find "$W/s" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')" 0
mv "$R/bin/state-root.sh" "$R/bin/state-root.sh.off"
"$EV" add --code 100 --seat s --kind note >/dev/null 2>"$W/err"; assert_eq "no resolver: exit 4" "$?" 4
assert_match "it says what is missing" "$(cat "$W/err")" "bin/state-root.sh is missing"
assert_eq "and it did not fall back to the repository tree" "$(find "$R/events" -mindepth 3 -name '*.json' | wc -l | tr -d ' ')" 0
case_done
