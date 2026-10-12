#!/usr/bin/env bash
# turnwatch.sh - prompts the architect through herdr when a seat finishes a turn. Runs in the reserved monitor slot 4.1.1.
#   turnwatch.sh [--ticks N]     poll every watches.turn_poll_seconds forever (N ticks then exit 0, for tests)
# One prompt per seat per transition into done: "TURN <seat> <pane> <done HH:MMZ>: read the pane, act per playbooks."
# Exit: 0 ok (only with --ticks), 2 usage.
#
# BREADCRUMB 2026-10-12 - WO-20261012-b800, backlog 60l24. What broke: on 2026-10-12 five re-seated seats sat idle for up to ten
#   minutes while the architect waited, because the only thing that woke it was a watcher it had armed by hand under its own
#   session (turn-watch.sh in the architect's user cache directory), and that died with the session; the interim copy had the session, the
#   workspace id and the architect pane typed into it. Why this fix: the same loop lives in the repo, started by bringup.sh as a
#   reserved slot, so monitors.sh health and the supervisor restart it when it dies. Seats are read from their seat records
#   (not from a "claude-" label), the architect is found by agent name (watches.architect_agent in herdr.json) so a new
#   architect pane needs no edit, and every herdr call names its session. The footer is the signal, not herdr's agent_status,
#   which says idle while a seat runs a long Bash command (owner, 2026-10-12): a spinner line is busy, "for Ns ... done HH:MMZ"
#   is done. Rejected: herdr agent_status alone (wrong in exactly that case) and a Claude Code Monitor task (hidden under the
#   architect). Cost: it reads the footer text of Claude Code, so a change of that footer silences it, and the first pass only
#   learns the states, so a turn that ended before the watcher started is not announced.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

ticks=0
while [ $# -gt 0 ]; do case "$1" in
  --ticks) ticks="${2:?--ticks needs a number}"; shift 2 ;;
  -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done

architect="$(sl_cfg .watches.architect_agent)"; poll="$(sl_cfg .watches.turn_poll_seconds)"
declare -A st; first=1; n=0
while :; do
  apane="$(sl_h agent get "$architect" 2>/dev/null | jq -r '.result.agent.pane_id // empty')"
  for f in "$STATE"/seats/*/seat.json; do
    [ -f "$f" ] || continue
    [ -z "$(jq -r '.ended_at // empty' "$f")" ] || continue
    pane="$(jq -r '.pane // empty' "$f")"; name="$(jq -r .name "$f")"
    [ -n "$pane" ] && [ "$pane" != "$apane" ] || continue
    txt="$(sl_h pane read "$pane" --source recent --lines 12 --format text 2>/dev/null)" || continue
    if grep -qE '… \([0-9]+[ms]|Running…' <<<"$txt"; then s=busy
    elif grep -qE ' for [0-9]+[hms].*done [0-9]{2}:[0-9]{2}Z' <<<"$txt"; then s=finished; else s=other; fi
    if [ "$s" = finished ] && [ "${st[$pane]:-}" != finished ] && [ "$first" = 0 ]; then
      last="$(grep -oE 'done [0-9]{2}:[0-9]{2}Z' <<<"$txt" | tail -1)"
      echo "$(date -u +%H:%M:%SZ) TURN $name $pane $last"
      sl_h agent prompt "$architect" "TURN $name $pane $last: read the pane, act per playbooks." >/dev/null 2>&1 \
        || echo "$(date -u +%H:%M:%SZ) prompt to $architect failed"
    fi
    st[$pane]=$s
  done
  first=0; n=$((n + 1))
  [ "$ticks" = 0 ] || [ "$n" -lt "$ticks" ] || exit 0
  sleep "$poll"
done
