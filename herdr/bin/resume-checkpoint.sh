#!/usr/bin/env bash
# resume-checkpoint.sh - SessionStart hook, matcher "compact" (WO-20261012-8fb2). After a compaction it prints the seat's own
# newest CONTEXT_STATE.md checkpoint, so the seat resumes from the resume line it wrote (AGENTS.md golden rule) and not only
# from the guard's generic summary. Claude Code adds a SessionStart hook's stdout to the seat's context.
#
#   resume-checkpoint.sh            the seat is the live seat record whose pane is $HERDR_PANE_ID; its worktree is read
#   COQ_CHECKPOINT_SH=PATH          checkpoint.sh to call (default: ~/.claude/skills/context-compaction, then the repo's copy)
# Exit code: always 0. A hook that exits non-zero on a compact would be noise in the one turn that matters, so every failure is
# one line on stdout saying what was missing (AC-H2).
#
# BREADCRUMB 2026-10-12 - WO-20261012-8fb2. What broke: after a compact the only checkpoint in front of a seat is the one
#   compaction-guard writes (git status, last prompts, last message); the checkpoint the seat wrote with checkpoint.sh, where
#   AGENTS.md:37 tells it to put the resume line, was never shown, so a seat resumed from a generic summary. Why this fix: a
#   second SessionStart entry after the guard's, wired by matcher to compact only (AC-H3), prints `checkpoint.sh read --top 1`
#   for the seat's worktree. The seat is found by the pane herdr gave it, because a pane id is the one thing the hook and the
#   seat record agree on. Rejected: reading $COQ_WORKTREE (a seat started by hand has none, and the owner's ask is the record),
#   a guard change (out of scope, the guard is a separate binary) and the owner's global hooks (not this repo's to edit).
#   Cost: a seat with no live record gets one line instead of its checkpoint; the checkpoint is then one `checkpoint.sh read` away.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
say() { printf 'resume-checkpoint: %s\n' "$*"; exit 0; }
command -v jq >/dev/null 2>&1 || say "jq is not on PATH, no checkpoint shown"
[ -n "${HERDR_PANE_ID:-}" ] || say "HERDR_PANE_ID is unset, so no seat is named; no checkpoint shown"

# The state dir comes from the same config seat-lib.sh reads; COQ_STATE wins, as it does there. seat-lib dies on a missing
# key, so it runs in a subshell and a failure is only an empty answer.
state="${COQ_STATE:-}"
if [ -z "$state" ]; then
  state="$( . "$HERE/seat-lib.sh" 2>/dev/null && printf '%s' "$STATE" )" || state=""
fi
[ -d "$state/seats" ] || say "no seat records under ${state:-the state dir}, no checkpoint shown"

worktree=""; best=""
for f in "$state"/seats/*/seat.json; do
  [ -f "$f" ] || continue
  row="$(jq -r --arg p "$HERDR_PANE_ID" 'select(.pane == $p and ((.ended_at // "") == "")) | "\(.started_at // "")\t\(.worktree // "")"' "$f" 2>/dev/null)" || continue
  [ -n "$row" ] || continue
  started="${row%%$'\t'*}"
  # A pane id can be handed to a later seat; the newest live record for it is the seat that is asking.
  if [ -z "$best" ] || [[ "$started" > "$best" ]]; then best="$started"; worktree="${row#*$'\t'}"; fi
done
[ -n "$worktree" ] || say "no live seat record names pane $HERDR_PANE_ID, no checkpoint shown"
[ -d "$worktree" ] || say "the worktree $worktree of pane $HERDR_PANE_ID is missing, no checkpoint shown"

cp_sh=""
for c in "${COQ_CHECKPOINT_SH:-}" "$HOME/.claude/skills/context-compaction/scripts/checkpoint.sh" "$REPO/.claude/skills/context-compaction/scripts/checkpoint.sh"; do
  if [ -n "$c" ] && [ -f "$c" ]; then cp_sh="$c"; break; fi
done
[ -n "$cp_sh" ] || say "checkpoint.sh was not found, no checkpoint shown"

body="$(bash "$cp_sh" read --project "$worktree" --top 1 2>/dev/null)" || body=""
[ -n "$body" ] || say "no checkpoint in $worktree/CONTEXT_STATE.md, nothing shown"
printf 'resume-checkpoint: your own newest checkpoint from %s/CONTEXT_STATE.md, written before the compaction. Its resume line is your next step.\n\n%s\n' "$worktree" "$body"
exit 0
