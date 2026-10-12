#!/usr/bin/env bash
# mint-id.sh - mint the next doc number (SOP-0007, ADR-0003) so two PRs can never take one (WO-20261012-0677, AC-H4).
#
#   mint-id.sh sop|adr [--repo DIR] [--state DIR]    prints the id and reserves it; the next call, from any slot, prints the one after
# Env: COQ_CLAIMS_PRS_JSON=FILE reads the open PRs from FILE instead of `gh pr list` (the shape claims.sh documents).
#      COQ_ID_STATE=DIR the shared counter directory (default ~/.local/state/coq-jev-herdr-plugin/ids)
# Exit: 0 ok, 2 usage, 4 io (no jq, no gh, lock not taken in 10 s).
#
# BREADCRUMB 2026-10-12 - WO-20261012-0677. What broke: docs.sh sop numbers a new SOP as the highest number in its own working tree plus
#   one (.claude/skills/living-docs/scripts/docs.sh dl_next_id), and every slot starts from main, so PR 31 and another PR each took
#   SOP-0003 and the two files sat side by side with one id. Why this fix: the number is the highest of four views plus one - the
#   tree here, origin/main, every open PR's added files, and a counter in a state directory every slot on this machine shares - and the
#   counter is written under a mkdir lock, so two seats asking in the same second still get two numbers. claims.sh ids then refuses a
#   diff that took a number anyway. Rejected: editing docs.sh (a managed skill, replaced on the next sync) and a counter inside the
#   repo (a tracked counter is the file two PRs both touch). Cost: an abandoned PR leaves a gap in the series, and a seat on another
#   machine is seen only through its open PR.
set -uo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/.." && pwd)
STATE=${COQ_ID_STATE:-$HOME/.local/state/coq-jev-herdr-plugin/ids}
die() { local c=$1; shift; printf 'mint-id: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
KIND=${1:-}; shift || true
while [ $# -gt 0 ]; do case $1 in --repo) REPO=$(cd "${2:?}" && pwd) || die 4 "no such --repo"; shift 2;; --state) STATE=${2:?}; shift 2;; *) die 2 "unknown argument $1";; esac; done
PRE=$(printf '%s' "$KIND" | tr '[:lower:]' '[:upper:]')
DIR=$(jq -r --arg p "$PRE" '.doc_ids[] | select(.prefix == $p) | .dir' "$HERE/../factory/config/claims.json" 2>/dev/null)
[ -n "$DIR" ] || die 2 "usage: mint-id.sh sop|adr (a series named in factory/config/claims.json doc_ids)"
mkdir -p "$STATE" || die 4 "cannot create $STATE"
waited=0; until mkdir "$STATE/$PRE.lock" 2>/dev/null; do [ "$waited" -lt 10 ] || die 4 "$STATE/$PRE.lock held for 10 s"; sleep 1; waited=$((waited + 1)); done
trap 'rmdir "$STATE/$PRE.lock" 2>/dev/null' EXIT
# numbers_of: every PREFIX-NNNN in a list of paths on stdin, one number per line.
numbers_of() { sed -n "s|^.*/$PRE-\\([0-9]\\{4\\}\\)-[^/]*\$|\\1|p"; }
max=0
bump() { local n; while read -r n; do n=$((10#$n)); [ "$n" -le "$max" ] || max=$n; done; }
# process substitution, not a pipe: bump must run in this shell or max is lost with the subshell
bump < <(git -C "$REPO" ls-tree -r --name-only HEAD -- "$DIR" 2>/dev/null | numbers_of)
bump < <(git -C "$REPO" ls-tree -r --name-only origin/main -- "$DIR" 2>/dev/null | numbers_of)
if [ -n "${COQ_CLAIMS_PRS_JSON:-}" ]; then prs=$(cat "$COQ_CLAIMS_PRS_JSON") || die 4 "cannot read $COQ_CLAIMS_PRS_JSON"
else command -v gh >/dev/null || die 4 "gh is required to read the open PRs"
  prs=$(cd "$REPO" && gh pr list --state open --limit 200 --json files 2>/dev/null) || die 4 "gh pr list failed, so the open PRs cannot be read"; fi
bump < <(jq -r '.[] | (.files // [])[] | .path' <<<"$prs" | numbers_of)
[ ! -f "$STATE/$PRE.counter" ] || bump < "$STATE/$PRE.counter"
n=$((max + 1)); printf '%04d\n' "$n" > "$STATE/$PRE.counter" || die 4 "cannot write the counter"
printf '%s-%04d\n' "$PRE" "$n"
