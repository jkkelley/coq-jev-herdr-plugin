#!/usr/bin/env bash
# herdr/tests/fixtures/checkpoint.sh - the one checkpoint.sh subcommand resume-checkpoint.sh calls, for case 17.
#   checkpoint.sh read --project DIR [--top N]     print the top N checkpoints of DIR/CONTEXT_STATE.md (default 10)
# Exit codes as the real script: 0 ok, 2 usage, 6 no CONTEXT_STATE.md.
#
# BREADCRUMB 2026-10-12 - WO-20261012-e36e. What broke: herdr/tests/cases/17-resume-checkpoint.test.sh called
#   $REPO/.claude/skills/context-compaction/scripts/checkpoint.sh, a copy skill-sync installs and .gitignore:91 (**/.claude/skills/)
#   keeps out of git. A seat slot has it, so PR 30 passed its gates; a clean worktree (verify on main, CI, a fresh clone) does not,
#   and `make -C herdr test` failed 22 passed / 1 failed on main 372f9aa and on every clean run since (PR 25, PR 34 verify).
#   Why this fix: the case installs this tracked file where the hook looks for the repo's copy, in the throwaway world only,
#   so it needs nothing outside tracked files and the real resume-checkpoint.sh runs unmodified. The awk body is the real
#   cmd_read's (~/dotfiles/claude/skills/context-compaction/scripts/checkpoint.sh), the only part the hook uses.
#   Rejected: a vendored copy of the whole 330 line skill script (a managed file that would drift and does more than the
#   case needs), skipping the case when the copy is absent (a green run that proved nothing), and un-ignoring the skills dir
#   (skill-sync owns it). Cost: if the skill's `read` output format changes, this copy has to follow it; the case would then
#   fail on its "top checkpoint verbatim" lines, not pass silently.
set -uo pipefail
[ "${1:-}" = read ] || { echo "checkpoint.sh fixture: only 'read' is implemented, got '${1:-}'" >&2; exit 2; }
shift
project=""; top=10
while [ $# -gt 0 ]; do
  case $1 in
    --project) project=${2:-}; shift 2 ;;
    --top) top=${2:-}; shift 2 ;;
    *) echo "checkpoint.sh fixture: unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$project" ] || { echo "checkpoint.sh fixture: --project is required" >&2; exit 2; }
[[ $top =~ ^[0-9]+$ ]] || { echo "checkpoint.sh fixture: --top must be a non-negative integer: $top" >&2; exit 2; }
f="$project/CONTEXT_STATE.md"
[ -f "$f" ] || { echo "checkpoint.sh fixture: no CONTEXT_STATE.md in $project" >&2; exit 6; }
awk -v mark='## Checkpoint ' -v want="$top" '
  index($0, mark) == 1 { seen++ }
  seen == 0 { next }
  seen > want { exit }
  { print }
' "$f"
