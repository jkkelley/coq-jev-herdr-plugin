#!/usr/bin/env bash
# guardwatch.sh - the compaction-guard watch of monitor slot 1.1.2, scoped to the seats that are alive (WO-20261012-ee9c).
# Each tick lists the panes the watchers govern (seat-lib.sh sl_guard_targets: open seat records, then the hand-started panes
# exemptions.json names), resolves each pane to the Claude session running in it right now (seat-lib.sh sl_pane_session:
# herdr pane process-info -> claude pid -> <claude_sessions_dir>/<pid>.json), and runs one
# `compaction-guard watch --once --session <sid>` for exactly that session. A pane with no claude process is skipped with one
# line and the guard is not called. The session it resolved is written to the seat's seat.json (claude_session) whenever it
# differs, so recover.sh and the operator read the session off the record instead of walking the guard's bindings.
#   guardwatch.sh --once              one tick, then exit
#   guardwatch.sh --watch [SECONDS]   a tick every SECONDS (default: herdr.json .guard_watch_interval_seconds), one summary line each
# Lines: watched <pane> <name> <session> | skipped <pane> <name> (<why>) | FAILED <pane> <name> <session> (guard exit N)
# Exit: 0 (--once: 1 when a guard call failed), 2 usage.
#
# BREADCRUMB 2026-10-12 - WO-20261012-ee9c, replaces `compaction-guard watch --interval 15` in monitors.json slot 1.1.2.
#   What broke: that command walks every binding on the host and memos any session bound to a pane, live or dead; at 02:16Z on
#   2026-10-12 it typed about 189 GOV-100 memos into the architect pane (backlog lh51y), the watch was stopped, and with it
#   stall recovery. Why this fix: the guard already scopes a tick with --session, so this script supplies the one session per
#   live pane instead of changing the guard (not this repo's). Rejected: `--role` (a role names a kind of seat, not the session
#   now in the pane) and filtering the guard's own output (the memo is sent before any output exists). Cost: one guard process
#   per live pane per tick instead of one for the fleet; a seat whose claude has not written its session file yet is skipped
#   for one tick.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr compaction-guard

mode=""; every=""
while [ $# -gt 0 ]; do case "$1" in
  --once) mode=once; shift ;;
  --watch) mode=watch; shift; [[ "${1:-}" =~ ^[0-9]+$ ]] && { every=$1; shift; } ;;
  -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
  *) sl_die "unknown argument $1" ;; esac; done
[ -n "$mode" ] || { sed -n '9,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
[ -n "$every" ] || every="$(sl_cfg .guard_watch_interval_seconds)"

# remember <name> <sid>: seat.json claude_session, only when it differs; a hand-started pane has no record and is left alone.
remember() {
  local f; f="$(sl_seat_record "$1")"; [ -f "$f" ] || return 0
  [ "$(jq -r '.claude_session // empty' "$f")" != "$2" ] || return 0
  jq --arg s "$2" '.claude_session = $s' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}
# tick: one pass; prints one line per target and returns 1 when a guard call failed.
tick() {
  local pane name sid rc=0 grc
  while IFS=$'\t' read -r pane name; do
    [ -n "$pane" ] || continue
    sid="$(sl_pane_session "$pane")"
    if [ -z "$sid" ]; then
      if [ -z "$(sl_pane_claude_pid "$pane")" ]; then printf 'skipped %s %s (no claude process in the pane)\n' "$pane" "$name"
      else printf 'skipped %s %s (claude has no session file yet)\n' "$pane" "$name"; fi
      continue
    fi
    remember "$name" "$sid"
    compaction-guard watch --once --session "$sid" >/dev/null 2>&1; grc=$?
    if [ "$grc" = 0 ]; then printf 'watched %s %s %s\n' "$pane" "$name" "$sid"
    else printf 'FAILED %s %s %s (guard exit %s)\n' "$pane" "$name" "$sid" "$grc"; rc=1; fi
  done < <(sl_guard_targets)
  return "$rc"
}
if [ "$mode" = watch ]; then
  while :; do
    out="$(tick)"; rc=$?
    printf '%s tick: %s watched, %s skipped, rc %s\n' "$(sl_now)" "$(grep -c '^watched' <<<"$out")" "$(grep -c '^skipped' <<<"$out")" "$rc"
    grep -v '^watched' <<<"$out" | grep . || true
    sleep "$every"
  done
else tick; fi
