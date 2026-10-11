#!/usr/bin/env bash
# check-conflict-markers.sh - fail when a tracked text file still holds a merge conflict marker (WO-20261011-6842, AC-H3).
#   check-conflict-markers.sh [ROOT]     ROOT defaults to /repo; prints "<file>:<line>: <marker>" per hit, exit 3 when any, 0 when none
#
# BREADCRUMB 2026-10-11 - WO-20261011-6842. What broke: a merge left conflict markers in a tracked file and nothing
#   noticed. Why this check and not a git hook: lint runs in a container with the repo mounted read-only and no git, so it
#   reads the tree. Only a marker at column 0 followed by a space or the end of the line counts, so indented examples in
#   prose pass. `=======` is not matched on its own: it is a Markdown setext underline, and a real conflict always has
#   the other two. Rejected: `git ls-files` (the worktree's .git points outside the mount), so without git the scan skips
#   .git, node_modules, .claude and factory/state and treats a file with a NUL byte as binary (grep -I).
#   Cost: where git is absent, an untracked file under the scanned directories can fail lint that CI would not see.
set -uo pipefail
R=${1:-/repo}; [ -d "$R" ] || { printf 'check-conflict-markers: no such directory %s\n' "$R" >&2; exit 2; }
if git -C "$R" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -d '' FILES < <(git -C "$R" ls-files -z)
else
  mapfile -d '' FILES < <(cd "$R" && find . \( -name .git -o -name node_modules -o -name .claude -o -path ./factory/state \) -prune -o -type f -print0 | sed -z 's|^\./||')
fi
hits=0
for f in "${FILES[@]}"; do
  [ -f "$R/$f" ] || continue
  while IFS= read -r line; do printf '%s:%s\n' "$f" "$line"; hits=1; done \
    < <(grep -InE '^(<<<<<<<|>>>>>>>)( |$)' "$R/$f" 2>/dev/null | sed -E 's/^([0-9]+):(.{0,7}).*/\1: conflict marker \2/')
done
[ "$hits" = 0 ] || exit 3
