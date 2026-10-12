#!/usr/bin/env bash
# Catches: an inbox write that appends to a shared file, overwrites an earlier wake, leaves a half-written file a drain could
# read, names files so they do not sort in write order, or accepts a wake that is not one line (SPEC-16.H h-verbs inbox,
# SPEC-05 s-quiet).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=../../../../herdr/tests/lib/assert.sh
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"
# shellcheck source-path=SCRIPTDIR source=../lib/world.sh
. "$HERE/../lib/world.sh"
world_up inbox
INBOX="$SCHED/host/bin/inbox.sh"; D="$W/state/seats/tester-wo-20261011-aaaa/inbox"

echo "-- one call is one new UTC-named file holding the line, in a directory it creates"
line="record 20261011T120000Z-100-abcde playbook /x/playbooks/tester.md"
out=$(bash "$INBOX" "$D" "$line"); assert_eq "exit 0" "$?" 0
assert_file "the printed path is the file" "$out"
assert_eq "the file holds the line" "$(cat "$out")" "$line"
assert_eq "exactly one byte past the line: the newline" "$(wc -c < "$out")" "$((${#line} + 1))"
assert_match "the name is the UTC to the nanosecond, a suffix, .txt" "$(basename "$out")" '^[0-9]{8}T[0-9]{6}\.[0-9]{9}Z-[A-Za-z0-9]{8}\.txt$'

echo "-- a second and third call add files and leave the first alone; names sort in write order"
bash "$INBOX" "$D" "second" >/dev/null; bash "$INBOX" "$D" "third" >/dev/null
assert_eq "three files" "$(find "$D" -type f | wc -l)" 3
assert_eq "no temp file left behind" "$(find "$D" -name '.inbox.*' | wc -l)" 0
assert_eq "sorted by name, the lines come back in write order" "$(find "$D" -type f | sort | xargs cat | paste -sd,)" \
  "$line,second,third"

echo "-- twenty writers at once: twenty files, no line lost"
for i in $(seq 1 20); do bash "$INBOX" "$W/burst" "wake $i" >/dev/null & done; wait
assert_eq "twenty files" "$(find "$W/burst" -type f | wc -l)" 20
assert_eq "every line once" "$(cat "$W/burst"/* | sort -V | paste -sd,)" "$(seq -f 'wake %g' 1 20 | paste -sd,)"

echo "-- refusals: usage 2, a line break or an empty line 3, an unwritable directory 4; nothing written"
bash "$INBOX" "$D" 2>/dev/null; assert_eq "one argument is usage" "$?" 2
bash "$INBOX" "$D" a b 2>/dev/null; assert_eq "three arguments is usage" "$?" 2
bash "$INBOX" "$D" "$(printf 'one\ntwo')" 2>/dev/null; assert_eq "a newline is refused" "$?" 3
bash "$INBOX" "$D" "$(printf 'one\rtwo')" 2>/dev/null; assert_eq "a carriage return is refused" "$?" 3
bash "$INBOX" "$D" "" 2>/dev/null; assert_eq "an empty line is refused" "$?" 3
mkdir -p "$W/ro"; chmod 0500 "$W/ro"
bash "$INBOX" "$W/ro/inbox" "x" 2>/dev/null; assert_eq "a directory it cannot create is io" "$?" 4
assert_eq "still three files in the inbox" "$(find "$D" -type f | wc -l)" 3
case_done
