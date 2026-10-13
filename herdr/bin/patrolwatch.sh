#!/usr/bin/env bash
# patrolwatch.sh - the system's one-minute tick for the compliance officer (WO-20261013-5b33). Runs in the reserved monitor slot 4.2.1.
#   patrolwatch.sh [--ticks N]     every watches.patrol_seconds, prompt the agent watches.compliance_agent once; N ticks then exit 0 (tests)
# One prompt per tick: "PATROL <HH:MMZ>: read every agent's pane, check every line process, report per playbooks/compliance-officer.md."
# A tick is skipped, and logged, when the officer is absent or its footer says it is still busy on the last patrol.
# Exit: 0 ok (only with --ticks), 2 usage.
#
# BREADCRUMB 2026-10-13 - WO-20261013-5b33. What broke: two testers sat up to 40 minutes on a refused git command and nobody saw it,
#   because the only wake-up of a watcher was turnwatch.sh, which fires on a seat's turn ending (herdr/bin/turnwatch.sh, the
#   `finished` transition); a seat that is hung or refused never ends a turn, and a dead line process ends no turn at all. Owner
#   2026-10-13: "isn't the tattle tale on some kind of 1 min loop?" Why this fix: a tick the system owns, in a reserved monitor
#   slot that monitors.sh health and the supervisor restart, so the officer is woken every minute whether or not any seat spoke.
#   It prompts and reads nothing, so it has no judgement to get wrong. Rejected: pointing turnwatch.sh at the officer (it is
#   still turn-driven) and a timer inside the officer's own session (it dies with that session, as the architect's watchers did
#   on 2026-10-12). Cost: an officer still busy when a tick arrives skips that tick, so a hung officer is silent; it is not
#   watched by itself, the supervisor's alive check (SPEC-17 s-health C1) is what catches it. The tick is a prompt, not a lease:
#   two ticks never stack in the officer's input.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

ticks=0
while [ $# -gt 0 ]; do case "$1" in
  --ticks) ticks="${2:?--ticks needs a number}"; shift 2 ;;
  -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done

officer="$(sl_cfg .watches.compliance_agent)"; poll="$(sl_cfg .watches.patrol_seconds)"
n=0
while :; do
  now="$(date -u +%H:%MZ)"
  pane="$(sl_h agent get "$officer" 2>/dev/null | jq -r '.result.agent.pane_id // empty')"
  if [ -z "$pane" ]; then echo "$(date -u +%H:%M:%SZ) tick skipped: no agent $officer"
  elif sl_h pane read "$pane" --source recent --lines 12 --format text 2>/dev/null | grep -qE '… \([0-9]+[ms]|Running…'; then
    echo "$(date -u +%H:%M:%SZ) tick skipped: $officer is busy on the last patrol"
  elif sl_h agent prompt "$officer" "PATROL $now: read every agent's pane, check every line process, report per playbooks/compliance-officer.md." >/dev/null 2>&1; then
    echo "$(date -u +%H:%M:%SZ) PATROL $officer $pane $now"
  else echo "$(date -u +%H:%M:%SZ) prompt to $officer failed"; fi
  n=$((n + 1))
  [ "$ticks" = 0 ] || [ "$n" -lt "$ticks" ] || exit 0
  sleep "$poll"
done
