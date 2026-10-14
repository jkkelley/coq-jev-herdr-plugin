#!/usr/bin/env bash
# branchcompare.sh BRANCH [CLONE] - for each file the branch changed since its merge base with origin/main: absent on main, identical on main, or differs.
# Read-only. Output: one summary line, then the paths of the absent and differing files (first 15 of each).
B=$1; CLONE=${2:-/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/coq}
g() { git -C "$CLONE" "$@"; }
mb=$(g merge-base origin/main "origin/$B") || exit 4
abs=0; same=0; diff=0; deleted=0; A=(); D=()
while IFS=$'\t' read -r st p; do
  if [ "$st" = D ]; then deleted=$((deleted+1)); continue; fi
  if ! g cat-file -e "origin/main:$p" 2>/dev/null; then abs=$((abs+1)); A+=("$p"); continue; fi
  if [ "$(g rev-parse "origin/main:$p")" = "$(g rev-parse "origin/$B:$p")" ]; then same=$((same+1)); else diff=$((diff+1)); D+=("$p"); fi
done < <(g diff --no-renames --name-status "$mb" "origin/$B")
echo "$B: files since merge base: $((abs+same+diff+deleted)) (absent on main $abs, identical on main $same, differs $diff, deleted by branch $deleted)"
printf '  absent: %s\n' "${A[@]:0:15}"; printf '  differs: %s\n' "${D[@]:0:15}"
# the absent files that are not paperwork (changelog/, events/, work-orders/, CHANGELOG.md, CONTEXT_STATE.md, INDEX.md), all of them
echo "  absent, not paperwork:"; for p in "${A[@]}"; do case $p in changelog/*|events/*|work-orders/*|CHANGELOG.md|CONTEXT_STATE.md) ;; *) echo "    $p";; esac; done
