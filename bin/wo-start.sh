#!/usr/bin/env bash
# wo-start.sh - start a ticket only when its files are free (WO-20261012-0677, AC-H1): claims.sh start, then work-order.sh start.
#
#   wo-start.sh --id WO-... [--project DIR]     exit 3 and the overlap on stdout when an open PR or a live ticket holds a file
# Anything else is passed to work-order.sh start unchanged (--json). Exit: 0 started, 3 refused, 4 io, else work-order.sh's.
#
# BREADCRUMB 2026-10-12 - WO-20261012-0677. What broke: `work-order.sh start` checks the ticket's status and a clean tree and nothing
#   else, so on 2026-10-12 five tickets were started onto the same herdr/bin/seat.sh, routes.json, herdr.json and RUNBOOK.md. Why this fix:
#   work-order.sh is a managed skill copy (gitignored, replaced on every session start), so the check is a wrapper that every start goes
#   through: this script is the one way the architect, a seat or bringup starts a ticket. Rejected: patching work-order.sh (the next sync
#   drops it) and a git hook (a branch is created by the call that would be refused). Cost: a start by hand through work-order.sh skips the
#   check; the gate (gate.sh pr-files) still fails that PR, one step later.
set -uo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/.." && pwd)
WO=${WORK_ORDER_SH:-$REPO/.claude/skills/work-order/scripts/work-order.sh}
die() { local c=$1; shift; printf 'wo-start: %s\n' "$*" >&2; exit "$c"; }
[ -f "$WO" ] || die 4 "no work-order.sh at $WO"
id=""; project=$REPO; rest=()
while [ $# -gt 0 ]; do case $1 in --id) id=${2:-}; shift 2;; --project) project=${2:-}; shift 2;; *) rest+=("$1"); shift;; esac; done
[ -n "$id" ] || die 2 "--id WO-... is required"
bash "$HERE/../factory/bin/claims.sh" start --id "$id" --repo "$project"; rc=$?
[ "$rc" = 0 ] || { printf 'wo-start: %s not started: its files are not free\n' "$id" >&2; exit "$rc"; }
exec bash "$WO" start --project "$project" --id "$id" "${rest[@]}"
