#!/usr/bin/env bash
# inbox.sh - one wake line into a seat's inbox while its quiet window is open (SPEC-16.H h-verbs inbox, SPEC-05 s-quiet).
#
#   inbox.sh DIR TEXT     writes TEXT and a newline as one new UTC-named file in DIR, prints the file's path
#
# The executor's inbox verb runs this with DIR = <state_dir>/seats/<seat>/inbox; the compaction guard drains the directory
# oldest first after the resume card. One call is one file and never an append (AGENTS.md dated entry files): the name is
# the UTC time to the nanosecond, then a random suffix, so names sort in write order and two writers never share a path.
# The file is written under a dot name and renamed into place, so a drain never reads half a line.
# Exit codes: 0 ok, 2 usage, 3 validation, 4 io.
set -euo pipefail
die() { local c=$1; shift; printf 'inbox: %s\n' "$*" >&2; exit "$c"; }

[ $# -eq 2 ] || die 2 "usage: inbox.sh DIR TEXT"
dir=$1 text=$2
[ -n "$dir" ] || die 2 "DIR is empty"
[ -n "$text" ] || die 3 "TEXT is empty"
case $text in *$'\n'* | *$'\r'*) die 3 "TEXT holds a line break; a wake is one line" ;; esac

mkdir -p "$dir" || die 4 "cannot create $dir"
tmp=$(mktemp "$dir/.inbox.XXXXXXXX") || die 4 "cannot write in $dir"
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$text" > "$tmp" || die 4 "cannot write $tmp"
for _ in 1 2 3 4 5; do
  final="$dir/$(date -u +%Y%m%dT%H%M%S.%NZ)-${tmp##*.}.txt"
  # mv -n never replaces an existing file; the existence check after it is what proves this call's file landed.
  if [ ! -e "$final" ] && mv -n "$tmp" "$final" && [ ! -e "$tmp" ]; then
    trap - EXIT; printf '%s\n' "$final"; exit 0
  fi
done
die 4 "no free name in $dir after 5 tries"
