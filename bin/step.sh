#!/usr/bin/env bash
# step.sh - one factory step, end to end, never by hand. Owner, chat 2026-10-10 UTC:
# "No way AWS do any of this by hand. We shouldn't either." and the golden rule in
# AGENTS.md (checkpoint every step, compact early). Lint, changelog entry, commit, push,
# checkpoint. Compaction is not queued here (see the breadcrumb at the bottom): compaction-guard owns it.
#
#   step.sh --msg "subject" [--body FILE] --type feat|fix|docs|chore|decision --title "changelog title"
#           [--ticket WO-...] [--text "changelog text"] [--cp-body FILE] [--no-push] [--compact] [--json]
#
# Env: COQ_SEAT_PANE (default wD3:p2) is the herdr pane that receives the /compact prompt when --compact is given.
# Exit codes: 0 ok, 2 usage, 3 lint or checkpoint validation failed, 4 git or io.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); REPO=$(cd "$HERE/.." && pwd)
die() { local c=$1; shift; printf 'step: %s\n' "$*" >&2; exit "$c"; }
msg=""; body=""; type=""; title=""; ticket=""; text=""; cp=""; push=1; compact=0; json=0
while [ $# -gt 0 ]; do case $1 in
  --msg) msg=$2; shift 2;; --body) body=$2; shift 2;; --type) type=$2; shift 2;; --title) title=$2; shift 2;; --ticket) ticket=$2; shift 2;;
  --text) text=$2; shift 2;; --cp-body) cp=$2; shift 2;; --no-push) push=0; shift;; --compact) compact=1; shift;; --json) json=1; shift;;
  *) die 2 "unknown flag $1";; esac; done
[ -n "$msg" ] && [ -n "$type" ] && [ -n "$title" ] || die 2 "step needs --msg, --type and --title"
CP=$HOME/.claude/skills/context-compaction/scripts/checkpoint.sh
[ -z "$cp" ] || bash "$CP" check --body-file "$cp" >/dev/null || die 3 "checkpoint body incomplete: $cp"
make -C "$REPO" lint >/dev/null 2>&1 || { make -C "$REPO" lint 2>&1 | grep -v ' ok$' >&2; die 3 "lint failed; nothing committed"; }
args=(--type "$type" --title "$title"); [ -z "$ticket" ] || args+=(--ticket "$ticket"); [ -z "$text" ] || args+=(--text "$text")
entry=$(bash "$HERE/changelog.sh" add "${args[@]}")
git -C "$REPO" add -A
# BREADCRUMB 2026-10-10 - WO-20261010-c274. What broke: the message file was "$REPO/.git/STEP_MSG", and in a git worktree
#   (every worker seat's checkout) .git is a file, so the redirect failed with "Not a directory" after the changelog entry
#   was written and staged but before the commit. Why this fix: `git rev-parse --git-path` names the right per-worktree
#   git dir in both layouts. Rejected: a mktemp file, which would leave a message behind when the commit fails.
MSGF=$(git -C "$REPO" rev-parse --path-format=absolute --git-path STEP_MSG)
{ printf '%s\n\n' "$msg"; [ -z "$body" ] || { cat "$body"; echo; }; printf 'Changelog: %s\n\nClaude-Session: https://claude.ai/code/session_01694jMaqrg4CVo5zWF3jq6Z\n' "$entry"; } > "$MSGF"
git -C "$REPO" commit -q -F "$MSGF" || die 4 "commit failed"
sha=$(git -C "$REPO" rev-parse --short HEAD)
[ "$push" = 0 ] || git -C "$REPO" push -q origin HEAD || die 4 "push failed at $sha"
# BREADCRUMB 2026-10-12 - WO-20261012-0677, no file is ever touched by two open PRs. What broke: this block committed and pushed
#   CONTEXT_STATE.md after every step, so every ticket branch carried a rewrite of the same file and each merge conflicted the next
#   PR (PRs 25, 28, 29, 30, 31 on 2026-10-12). Why this fix: CONTEXT_STATE.md is now gitignored seat state (see .gitignore), so the
#   checkpoint is written in place and nothing is committed; resume-checkpoint.sh and compaction-guard read it from the worktree.
#   Rejected: keeping the commit on the records branch only (a branch test that one rename defeats) and an uncommitted tracked file
#   (a later merge of main aborts on it). Cost: a checkpoint is no longer in git history; it lives as long as the slot does.
at=""
if [ -n "$cp" ]; then at=$(bash "$CP" new --project "$REPO" --body-file "$cp") || die 3 "checkpoint refused"; fi
# BREADCRUMB 2026-10-10 21:5x UTC. What broke: this block ran after every step (compact=1 by default) and queued
#   "/compact Keep: ..." into the architect pane with `herdr agent prompt`. Four steps landed back to back at 20:47-20:54
#   UTC, four /compact prompts stacked in the pane, the second and later answered "Not enough messages to compact",
#   which fires compaction-guard's PreCompact (phase compacting) and never a PostCompact, so the guard refused every
#   tool call in the seat until its lease ran out, and the owner's next message sat behind the stack. Why this fix:
#   compaction has one owner, compaction-guard, whose Stop hook compacts the seat at turn end over the schema threshold
#   (30%) and re-injects its checkpoint; a second owner races it on the same turn. The prompt stays behind --compact for
#   the one case a caller wants it now. Rejected: gating on `compaction-guard ctx` (still a second owner), and a
#   dedupe marker (the stack was the symptom, not the fault). Break glass for a stuck lease: herdr/bin/unfreeze.sh.
if [ "$compact" = 1 ] && command -v herdr >/dev/null; then
  herdr agent prompt "${COQ_SEAT_PANE:-wD3:p2}" "/compact Keep: read the top checkpoint of $REPO/CONTEXT_STATE.md first and stop at the second ## Checkpoint; it is the state and the next step." >/dev/null 2>&1 || echo "step: compact prompt not queued (herdr agent prompt failed)" >&2
fi
if [ "$json" = 1 ]; then jq -n --arg sha "$sha" --arg entry "$entry" --arg cp "$at" '{ok:true,sha:$sha,changelog:$entry,checkpoint:$cp}'; else printf '%s %s %s\n' "$sha" "$entry" "$at"; fi
