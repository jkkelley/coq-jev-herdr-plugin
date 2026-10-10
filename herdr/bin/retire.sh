#!/usr/bin/env bash
# retire.sh - RUN-retire (SPEC-04 s-cleanup): take one agent out of its pane without leaving a wedged dialog behind.
#   retire.sh <name> [--pane <pane>]      exit 0 once herdr no longer answers for the agent; 1 when it still does
# Sequence, each step only if the agent is still there: agent send-keys <escape>; agent prompt "/exit"; poll agent get
# for retire_poll_seconds; answer the "Exit and stop tasks" dialog (down, enter); interrupt twice (C-c, C-c); poll again.
# The caller (seat.sh --down) closes the emptied tab, releases the slot and records seat.down 100; this script records
# nothing and closes nothing, so it is safe to run on any agent, seat or not.
#
# BREADCRUMB - ported from bearings-v2 bin/lib.sh retire_agent, 2026-10-10. What broke there (A-02 wedged tester,
#   2026-09-21T06:05:49Z): /exit on a Claude with a running task opens an "Exit and stop tasks" dialog, and a tab closed
#   over it left a zombie claude holding the worktree. Why this shape: every step is conditional on `agent get` still
#   answering, so a clean exit costs one prompt and nothing else is typed into a pane that already holds a shell.
#   Cost: up to 2 x retire_poll_seconds for a wedged agent.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

name="${1:-}"; pane=""; shift || true
while [ $# -gt 0 ]; do case "$1" in --pane) pane="${2:?--pane needs a pane id}"; shift 2 ;; *) sl_die "unknown argument $1" ;; esac; done
[ -n "$name" ] || { sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

poll="$(sl_cfg .retire_poll_seconds)"
k_esc="$(sl_cfg .keys.escape)"; k_down="$(sl_cfg .keys.down)"; k_enter="$(sl_cfg .keys.enter)"; k_int="$(sl_cfg .keys.interrupt)"
gone() { ! sl_agent_live "$name"; }
wait_gone() { local i; for ((i = 0; i < poll; i++)); do gone && return 0; sleep 1; done; gone; }

gone && { sl_log "retire $name: already gone"; exit 0; }
[ -n "$pane" ] || pane="$(sl_h agent get "$name" 2>/dev/null | jq -r '.result.agent.pane_id // empty')"
sl_mut agent send-keys "$name" "$k_esc" >/dev/null 2>&1 || true
sl_mut agent prompt "$name" "/exit" >/dev/null 2>&1 || true
[ "$DRY" = 1 ] && exit 0
wait_gone && exit 0
screen="$(sl_h agent read "$name" --source visible --lines 20 2>/dev/null || true)"
if grep -qi 'exit and stop tasks' <<<"$screen"; then
  sl_mut agent send-keys "$name" "$k_down" >/dev/null 2>&1 || true
  sl_mut agent send-keys "$name" "$k_enter" >/dev/null 2>&1 || true
  wait_gone && exit 0
fi
sl_mut agent send-keys "$name" "$k_int" >/dev/null 2>&1 || true
sleep 1
sl_mut agent send-keys "$name" "$k_int" >/dev/null 2>&1 || true
wait_gone && exit 0
sl_log "retire $name: still answering after /exit, the dialog and two interrupts (pane ${pane:-?})"
exit 1
