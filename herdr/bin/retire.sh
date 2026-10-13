#!/usr/bin/env bash
# retire.sh - RUN-retire (SPEC-04 s-cleanup): take one agent out of its pane without leaving a wedged dialog behind.
#   retire.sh <name> [--pane <pane>] [--slot <dir>]   exit 0 once herdr no longer answers for the agent and no process of the seat is left;
#                                         1 when herdr still answers; 3 when a process of the seat survived (500 note names the pid)
# Sequence, each step only if the agent is still there: agent send-keys <escape>; agent prompt "/exit"; poll agent get
# for retire_poll_seconds; answer the "Exit and stop tasks" dialog (down, enter); interrupt twice (C-c, C-c); poll again.
# Then, whether or not the agent was still there, herdr/bin/seat-lib.sh sl_end_seat_procs ends every process of the seat (the agent
# pane's tree, the tree as it was before /exit, every claude whose COQ_SEAT is <name> or whose cwd is --slot) and checks none is left
# (WO-20261013-50a4, cause g). --slot is passed only for a slot the seat leased, never for a shared checkout.
# The caller (seat.sh --down) closes the emptied tab, releases the slot and records seat.down 100; this script records
# nothing but a 500 note for a survivor and closes nothing, so it is safe to run on any agent, seat or not.
#
# BREADCRUMB - ported from bearings-v2 bin/lib.sh retire_agent, 2026-10-10. What broke there (A-02 wedged tester,
#   2026-09-21T06:05:49Z): /exit on a Claude with a running task opens an "Exit and stop tasks" dialog, and a tab closed
#   over it left a zombie claude holding the worktree. Why this shape: every step is conditional on `agent get` still
#   answering, so a clean exit costs one prompt and nothing else is typed into a pane that already holds a shell.
#   Cost: up to 2 x retire_poll_seconds for a wedged agent.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

name="${1:-}"; pane=""; slot=""; shift || true
while [ $# -gt 0 ]; do case "$1" in --pane) pane="${2:?--pane needs a pane id}"; shift 2 ;; --slot) slot="${2:?--slot needs a directory}"; shift 2 ;; *) sl_die "unknown argument $1" ;; esac; done
[ -n "$name" ] || { sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

poll="$(sl_cfg .retire_poll_seconds)"
k_esc="$(sl_cfg .keys.escape)"; k_down="$(sl_cfg .keys.down)"; k_enter="$(sl_cfg .keys.enter)"; k_int="$(sl_cfg .keys.interrupt)"
gone() { ! sl_agent_live "$name"; }
wait_gone() { local i; for ((i = 0; i < poll; i++)); do gone && return 0; sleep 1; done; gone; }

# exit_agent: the /exit sequence; 0 once herdr no longer answers for the agent, 1 when it still does.
exit_agent() {
  gone && { sl_log "retire $name: already gone"; return 0; }
  sl_mut agent send-keys "$name" "$k_esc" >/dev/null 2>&1 || true
  sl_mut agent prompt "$name" "/exit" >/dev/null 2>&1 || true
  [ "$DRY" = 1 ] && return 0
  wait_gone && return 0
  screen="$(sl_h agent read "$name" --source visible --lines 20 2>/dev/null || true)"
  if grep -qi 'exit and stop tasks' <<<"$screen"; then
    sl_mut agent send-keys "$name" "$k_down" >/dev/null 2>&1 || true
    sl_mut agent send-keys "$name" "$k_enter" >/dev/null 2>&1 || true
    wait_gone && return 0
  fi
  sl_mut agent send-keys "$name" "$k_int" >/dev/null 2>&1 || true
  sleep 1
  sl_mut agent send-keys "$name" "$k_int" >/dev/null 2>&1 || true
  wait_gone && return 0
  sl_log "retire $name: still answering after /exit, the dialog and two interrupts (pane ${pane:-?})"
  return 1
}
[ -n "$pane" ] || pane="$(sl_h agent get "$name" 2>/dev/null | jq -r '.result.agent.pane_id // empty')"
# The pane's tree must be read before /exit: the children of a claude that has gone are no longer under the shell.
snap=""; [ "$DRY" = 1 ] || snap="$(sl_pane_snapshot "$pane")"
exit_agent; rc=$?
[ "$DRY" = 1 ] && exit "$rc"
sl_end_seat_procs "$name" "$pane" "$slot" "$snap" || exit 3
exit "$rc"
