#!/usr/bin/env bash
# Catches: a tracked file holding a merge conflict marker passing make lint, or a clean tree failing it, or the failure not
# naming the file (AC-H3 of WO-20261011-6842). The markers are built here, never written as literals, so this file
# is not itself a hit. The check is lint/check-conflict-markers.sh, the one lint.sh calls.
set -uo pipefail
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"
CHECK="${REPO_ROOT:-/repo}/lint/check-conflict-markers.sh"
T="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/conflict-lint"; rm -rf "$T"; mkdir -p "$T/docs" "$T/node_modules/x" "$T/.claude"
L='<<<<<<<'; M='======='; G='>>>>>>>'

echo "-- a clean tree passes, and prose that quotes a marker mid-line or indented does not trip it"
printf 'Title\n=======\nuse %s HEAD to mark ours\n    %s indented example\n' "$L" "$G" > "$T/docs/readme.md"
out=$("$CHECK" "$T" 2>&1); assert_eq "clean tree: exit 0" "$?" 0; assert_eq "clean tree: no output" "$out" ""

echo "-- AC-H3: a marker at column 0 fails and names the file and line"
printf 'a\n%s HEAD\nours\n%s\ntheirs\n%s branch\nz\n' "$L" "$M" "$G" > "$T/docs/guide.md"
out=$("$CHECK" "$T" 2>&1); rc=$?
assert_eq "conflicted tree: exit 3" "$rc" 3
assert_match "names the file and the opening marker line" "$out" '^docs/guide\.md:2: conflict marker <<<<<<<'
assert_match "names the closing marker line" "$out" '^docs/guide\.md:6: conflict marker >>>>>>>'
check "the clean file is not named" "$(grep -q 'readme' <<<"$out" && echo 0 || echo 1)"

echo "-- skipped places and binary files do not fail the tree"
rm "$T/docs/guide.md"
printf '%s HEAD\n' "$L" > "$T/node_modules/x/a.txt"; printf '%s HEAD\n' "$L" > "$T/.claude/b.txt"
printf '\0\n%s HEAD\n' "$L" > "$T/blob.bin"
"$CHECK" "$T" >/dev/null 2>&1; assert_eq "node_modules, .claude and binary: exit 0" "$?" 0
"$CHECK" "$T/nope" >/dev/null 2>&1; assert_eq "no such root: exit 2" "$?" 2
case_done
