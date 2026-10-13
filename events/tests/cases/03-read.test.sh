#!/usr/bin/env bash
# Catches: list, tail and check reading only one of the two trees while both exist (until roadmap item A4 removes events/ from git),
# an order that differs between the old and the new file name shape, and a check that passes a bad name or a bad record.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up read
export COQ_STATE="$W/s"
T=WO-20261012-7e13

# A record in the old shape: <id>.json in the repository's events/YYYY/MM, the id being the file name.
mkdir -p "$R/events/2026/10"
jq -n '{schema_version:"1.0.0", id:"20261012T215900Z-150-oldaa", at:"2026-10-12T21:59:00Z", code:150, seat:"legacy", kind:"gate", ticket:null, pane:null, note:"old shape", evidence:[], observations:[]}' > "$R/events/2026/10/20261012T215900Z-150-oldaa.json"
freeze_clock 1; "$EV" add --code 100 --seat worker --kind work.started --ticket $T --note "new one" >/dev/null
freeze_clock 3; "$EV" add --code 423 --seat worker --kind blocked --ticket $T --note "new two" >/dev/null

echo "-- list reads both trees, oldest first by the record's time"
assert_eq "all three, by time, not by file name" "$("$EV" list | cut -f6 | tr '\n' '|')" "old shape|new one|new two|"
assert_eq "--code" "$("$EV" list --code 423 | cut -f6)" "new two"
assert_eq "--seat" "$("$EV" list --seat legacy | cut -f6)" "old shape"
assert_eq "--ticket" "$("$EV" list --ticket $T | wc -l | tr -d ' ')" 2
assert_eq "--since" "$("$EV" list --since 2026-10-12T22:00:02Z | cut -f6)" "new two"
assert_eq "--json is one record per object, in the same order" "$("$EV" list --json | jq -r .note | tr '\n' '|')" "old shape|new one|new two|"
assert_eq "tail is the newest ten, oldest of them first" "$("$EV" tail | cut -f6 | tr '\n' '|')" "old shape|new one|new two|"
for i in $(seq 1 9); do freeze_clock $((10 + i)); "$EV" add --code 100 --seat filler --kind note --note "filler-$i" >/dev/null; done
assert_eq "tail stops at ten" "$("$EV" tail | wc -l | tr -d ' ')" 10
assert_eq "and ends with the newest" "$("$EV" tail | tail -1 | cut -f6)" "filler-9"

echo "-- check passes both shapes and says how many"
assert_eq "check exit" "$("$EV" check >/dev/null 2>&1; echo $?)" 0
assert_eq "check counts all twelve" "$("$EV" check 2>&1)" "events ok: 12 files"

echo "-- check names every kind of offender and exits 3"
good=$(find "$W/s/records" -name '*work-started*' | head -1)
d=$(dirname "$good")
cp "$good" "$d/20261012220001-BadName.json"
out=$("$EV" check 2>&1); assert_eq "an upper-case name: exit" "$?" 3; assert_match "it names the file" "$out" "bad name .*20261012220001-BadName.json"
rm "$d/20261012220001-BadName.json"
cp "$good" "$d/20261012220009-work-started.json"
out=$("$EV" check 2>&1); assert_eq "a time that is not the record's at: exit" "$?" 3; assert_match "it names the file" "$out" "bad name .*20261012220009-work-started.json"
rm "$d/20261012220009-work-started.json"
long=$(printf 'a%.0s' $(seq 1 56)); cp "$good" "$d/20261012220001-$long.json"
out=$("$EV" check 2>&1); assert_eq "a name of 56 characters: exit" "$?" 3; assert_match "it names the file" "$out" "bad name .*$long"
rm "$d/20261012220001-$long.json"
mkdir -p "$W/s/records/2026/11"; cp "$good" "$W/s/records/2026/11/$(basename "$good")"
out=$("$EV" check 2>&1); assert_eq "a file in the wrong month folder: exit" "$?" 3; assert_match "it names the file" "$out" "bad name .*2026/11"
rm -r "$W/s/records/2026/11"
jq '.code = 7' "$good" > "$d/20261012220001-work-started.json"
out=$("$EV" check 2>&1); assert_eq "a record the schema refuses: exit" "$?" 3; assert_match "it names the file" "$out" "invalid: .*20261012220001-work-started.json"
rm "$d/20261012220001-work-started.json"
cp "$R/events/2026/10/20261012T215900Z-150-oldaa.json" "$R/events/2026/10/20261012T215900Z-150-moved.json"
out=$("$EV" check 2>&1); assert_eq "an old-shape file whose name is not its id: exit" "$?" 3; assert_match "it names the file" "$out" "filename/id mismatch: .*moved"
rm "$R/events/2026/10/20261012T215900Z-150-moved.json"
assert_eq "clean again" "$("$EV" check 2>&1)" "events ok: 12 files"

echo "-- a state root that does not exist yet is an empty tree, and an unresolvable one leaves the repository tree readable"
export COQ_STATE="$W/never-written"
assert_eq "list on an absent state root shows the old tree" "$("$EV" list | cut -f6)" "old shape"
assert_eq "check on an absent state root" "$("$EV" check 2>&1)" "events ok: 1 files"
unset COQ_STATE
out=$(env -u HOME -u XDG_STATE_HOME "$EV" list 2>"$W/err"); rc=$?
assert_eq "no HOME, no XDG, no COQ_STATE: list exit" "$rc" 0
assert_eq "it still lists the old tree" "$(printf '%s\n' "$out" | cut -f6)" "old shape"
assert_match "and it warns on stderr" "$(cat "$W/err")" "state root unresolved"
COQ_STATE=relative "$EV" list >/dev/null 2>"$W/err"; assert_eq "a relative COQ_STATE is refused, never skipped" "$?" 3
case_done
