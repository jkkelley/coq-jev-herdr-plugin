#!/usr/bin/env bash
# branches.sh - every remote branch not main: ahead/behind main, files vs main, last commit (UTC). Read-only. Usage: branches.sh [CLONE]
CLONE=${1:-/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/coq}; export TZ=UTC
git -C "$CLONE" fetch -q origin --prune
for b in $(git -C "$CLONE" for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v '^origin$\|origin/main$\|origin/HEAD'); do
  read -r behind ahead < <(git -C "$CLONE" rev-list --left-right --count origin/main..."$b")
  files=$(git -C "$CLONE" diff --name-only "origin/main...$b" | wc -l)
  mb_files=$(git -C "$CLONE" diff --name-only "origin/main" "$b" | wc -l)
  last=$(git -C "$CLONE" log -1 --format=%ad --date=format-local:%Y-%m-%dT%H:%MZ "$b")
  printf '%s\tahead=%s\tbehind=%s\tfiles_since_merge_base=%s\tfiles_vs_main_tip=%s\tlast=%s\t%s\n' "${b#origin/}" "$ahead" "$behind" "$files" "$mb_files" "$last" "$(git -C "$CLONE" log -1 --format=%s "$b" | cut -c1-80)"
done
