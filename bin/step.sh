#!/usr/bin/env bash
# step.sh - one factory step, end to end, never by hand. Owner, chat 2026-10-10 UTC:
# "No way AWS do any of this by hand. We shouldn't either." and the golden rule in
# AGENTS.md (checkpoint every step, compact early). Lint, changelog entry, commit, push,
# checkpoint, then queue /compact into the seat. Any failure stops before the commit.
#
#   step.sh --msg "subject" [--body FILE] --type feat|fix|docs|chore|decision --title "changelog title"
#           [--ticket WO-...] [--text "changelog text"] [--cp-body FILE] [--no-push] [--no-compact] [--json]
#
# Env: COQ_SEAT_PANE (default wD3:p2) is the herdr pane that receives the /compact prompt.
# Exit codes: 0 ok, 2 usage, 3 lint or checkpoint validation failed, 4 git or io.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); REPO=$(cd "$HERE/.." && pwd)
die() { local c=$1; shift; printf 'step: %s\n' "$*" >&2; exit "$c"; }
msg=""; body=""; type=""; title=""; ticket=""; text=""; cp=""; push=1; compact=1; json=0
while [ $# -gt 0 ]; do case $1 in
  --msg) msg=$2; shift 2;; --body) body=$2; shift 2;; --type) type=$2; shift 2;; --title) title=$2; shift 2;; --ticket) ticket=$2; shift 2;;
  --text) text=$2; shift 2;; --cp-body) cp=$2; shift 2;; --no-push) push=0; shift;; --no-compact) compact=0; shift;; --json) json=1; shift;;
  *) die 2 "unknown flag $1";; esac; done
[ -n "$msg" ] && [ -n "$type" ] && [ -n "$title" ] || die 2 "step needs --msg, --type and --title"
CP=$HOME/.claude/skills/context-compaction/scripts/checkpoint.sh
[ -z "$cp" ] || bash "$CP" check --body-file "$cp" >/dev/null || die 3 "checkpoint body incomplete: $cp"
make -C "$REPO" lint >/dev/null 2>&1 || { make -C "$REPO" lint 2>&1 | grep -v ' ok$' >&2; die 3 "lint failed; nothing committed"; }
args=(--type "$type" --title "$title"); [ -z "$ticket" ] || args+=(--ticket "$ticket"); [ -z "$text" ] || args+=(--text "$text")
entry=$(bash "$HERE/changelog.sh" add "${args[@]}")
git -C "$REPO" add -A
{ printf '%s\n\n' "$msg"; [ -z "$body" ] || { cat "$body"; echo; }; printf 'Changelog: %s\n\nClaude-Session: https://claude.ai/code/session_01694jMaqrg4CVo5zWF3jq6Z\n' "$entry"; } > "$REPO/.git/STEP_MSG"
git -C "$REPO" commit -q -F "$REPO/.git/STEP_MSG" || die 4 "commit failed"
sha=$(git -C "$REPO" rev-parse --short HEAD)
[ "$push" = 0 ] || git -C "$REPO" push -q origin HEAD || die 4 "push failed at $sha"
at=""
if [ -n "$cp" ]; then at=$(bash "$CP" new --project "$REPO" --body-file "$cp") || die 3 "checkpoint refused"
  git -C "$REPO" add CONTEXT_STATE.md && git -C "$REPO" commit -q -m "chore: checkpoint $at

Claude-Session: https://claude.ai/code/session_01694jMaqrg4CVo5zWF3jq6Z" && { [ "$push" = 0 ] || git -C "$REPO" push -q origin HEAD; }
fi
if [ "$compact" = 1 ] && command -v herdr >/dev/null; then
  herdr agent prompt "${COQ_SEAT_PANE:-wD3:p2}" "/compact Keep: read the top checkpoint of $REPO/CONTEXT_STATE.md first and stop at the second ## Checkpoint; it is the state and the next step." >/dev/null 2>&1 || echo "step: compact prompt not queued (herdr agent prompt failed)" >&2
fi
if [ "$json" = 1 ]; then jq -n --arg sha "$sha" --arg entry "$entry" --arg cp "$at" '{ok:true,sha:$sha,changelog:$entry,checkpoint:$cp}'; else printf '%s %s %s\n' "$sha" "$entry" "$at"; fi
