#!/usr/bin/env bash
# Build the Factory Rebuild Plan page with the execution rail skill, with every path wired.
# Why a wrapper: the rail skill rule says to commit the wrapper that calls it, and the ledger, the built page and the .approved marker
# must stay out of git, so they are pointed at the state directory below and never at the repository.
# The wrapper refuses to build when plan.json or side.html differ from what the XML generates, so the page can never show a stale plan.
# Usage: rebuild/rail.sh [--approved|--not-approved]     (extra flags pass straight to rail-build.sh)
# Then publish the printed page.html with the Artifact tool, to the same URL as before after the first time.
# Env: COQ_REBUILD_PLAN_STATE overrides the state directory; RAIL_SKILL overrides the skill location.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state="${COQ_REBUILD_PLAN_STATE:-$HOME/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/plan}"
skill="${RAIL_SKILL:-$HOME/.claude/skills/execution-rail}"
mkdir -p "$state"
"$here/bin/plan-to-rail.sh" --check
exec "$skill/bin/rail-build.sh" \
  --plan "$here/plan.json" \
  --side "$here/side.html" \
  --ledger "$state/ledger.tsv" \
  --out "$state/page.html" \
  --title "Factory Rebuild Plan" \
  --eyebrow "coq-jev-herdr-plugin · factory rebuild · 2026-10-14" \
  --source "rebuild/factory-rebuild-plan.xml" \
  "$@"
