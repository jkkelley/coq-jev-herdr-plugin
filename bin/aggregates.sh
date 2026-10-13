#!/usr/bin/env bash
# aggregates.sh - render the gitignored work-order aggregates (work-orders/INDEX.md and the READMEs) with the tool that owns their format.
#
#   aggregates.sh [--project DIR]        runs work-order.sh reindex; make aggregates calls it after the changelog render
# Finds work-order.sh in this order: $WORK_ORDER_SH, <project>/.claude/skills/work-order/scripts/work-order.sh, then the machine copy
# $CLAUDE_HOME/skills/work-order/scripts/work-order.sh ($CLAUDE_HOME defaults to ~/.claude).
# Exit: 0 rendered, 2 usage, 4 work-order.sh not found (the message names it and how to get it), else work-order.sh's own code.
#
# BREADCRUMB 2026-10-12 - WO-20261012-aac3. What broke: Makefile:43 ran $(HERE).claude/skills/work-order/scripts/work-order.sh reindex.
#   That path is a managed skill copy: .claude/skills/ is gitignored (.gitignore: **/.claude/skills/) and skill-sync writes it at a
#   Claude session start, so in a fresh clone or a new git worktree the file does not exist and `make aggregates` died with "No such
#   file or directory" (shell 127, make 2), found verifying PR 36 on main (record k5ygl). Why this fix: the lookup lives in one script
#   that tries the project copy, then the machine copy skill-sync keeps current under ~/.claude/skills, and when neither exists says what
#   is missing and how to get it, exit 4 (the repo's io code), instead of a bare 127. wo-start.sh already honours $WORK_ORDER_SH, so the
#   override is the same name. Rejected: vendoring work-order.sh into the repository (a second copy of a skill that dotfiles owns would
#   drift from it, and AGENTS.md says a managed skill is never edited in place), and having make run skill-sync (it needs the network and a
#   session; a render must work offline). Cost: with no skill anywhere the aggregates are not rendered, and make prints its own
#   "Error 4" line and exits 2, because GNU make exits 2 for any failed recipe; the script's code 4 is the one in that line and in a
#   direct `bash bin/aggregates.sh` call. Record: WO-20261012-aac3.
set -uo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/.." && pwd)
die() { local c=$1; shift; printf 'aggregates: %s\n' "$*" >&2; exit "$c"; }
project=$REPO
while [ $# -gt 0 ]; do case $1 in
  --project) [ -n "${2:-}" ] || die 2 "--project needs a directory"; project=$2; shift 2;;
  *) die 2 "unknown argument $1 (usage: aggregates.sh [--project DIR])";;
esac; done
[ -d "$project" ] || die 4 "project $project is not a directory"

WO=""
for c in "${WORK_ORDER_SH:-}" "$project/.claude/skills/work-order/scripts/work-order.sh" "${CLAUDE_HOME:-$HOME/.claude}/skills/work-order/scripts/work-order.sh"; do
  if [ -n "$c" ] && [ -f "$c" ]; then WO=$c; break; fi
done
if [ -z "$WO" ]; then
  die 4 "work-order.sh not found. Looked at \$WORK_ORDER_SH, $project/.claude/skills/work-order/scripts/work-order.sh and ${CLAUDE_HOME:-$HOME/.claude}/skills/work-order/scripts/work-order.sh.
  It is the work-order skill, a managed copy from jkkelley/dotfiles (claude/skills/work-order) that skill-sync installs at the start of a Claude session in this checkout (.claude/skills.toml lists it).
  Start a session here, or run skill-sync, or point WORK_ORDER_SH at a work-order.sh, then run make aggregates again."
fi
exec bash "$WO" reindex --project "$project"
