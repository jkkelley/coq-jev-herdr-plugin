#!/usr/bin/env bash
# supervisor.sh - one tick of the thing that keeps the line standing when nobody is watching (WO-20261012-b800). systemd runs it at
# boot and every 30 seconds (herdr/systemd/coq-supervisor.timer); each tick brings back, in this order, whatever is down:
#   1 halt flag   the file config .halt_flag names exists -> HALTED, nothing below runs
#   2 herdr       the session answers; when it does not, `systemctl --user start <supervisor.herdr_unit>` (never a child of this script)
#   3 podman      `podman ps` answers; when it does not, `podman system migrate` (backlog 60l24)
#   4 bringup     bringup.sh: control plane, guard, monitors grid, monitor seat, every reserved pane judged by its process
#   5 belt        belt.sh --apply: the runner pane runs and the belt is fresh
#   6 bearings    the owner page server and its wait loop run (config .supervisor.bearings)
# One line per object, in bringup.sh's words: ok | fixed (what) | skipped (why) | FAILED (why). Exit 0 when nothing FAILED.
#   supervisor.sh              one tick, repairing
#   supervisor.sh --check      one tick, changing nothing (what `make -C herdr supervisor-check` runs)
#   supervisor.sh log          print the last tick (the supervisor slot of the watches tab tails this)
# Exit: 0 nothing FAILED, 1 something FAILED, 2 usage. Every step is killed after supervisor.step_timeout_seconds.
#
# BREADCRUMB 2026-10-12 - WO-20261012-b800. What broke: three outages on 2026-10-12 (a herdr restart, a WSL reboot, a suspend) each
#   needed the architect to restart bearings by hand, to notice six monitor panes that bringup.sh --check called ok, and to
#   unstick commands that hung; two seats whose claude crashed with a Bun segfault sat dead until someone looked. Why this
#   fix: one script that runs every tick from a systemd timer, so it exists before any agent does and survives all of them. It
#   calls the scripts that already own each repair (bringup.sh, belt.sh, bearings.sh, seat.sh) and adds only what had no owner:
#   starting herdr through its own unit, podman's pause process, the bearings restart, the re-seat. It never starts a herdr
#   server itself (systemd owns it, owner rule 2026-10-10), never runs `compaction-guard recover --apply` (it resumed other
#   projects' sessions and flooded the architect with ~189 memos on 2026-10-12, which is why recover.sh is not called here),
#   and holds a lock so a tick that hangs is killed by its timeout rather than stacked on by the next. Rejected: a long-running
#   loop (a hung loop is a dead supervisor with no one to restart it) and recover.sh --apply on a timer (the guard step).
#   Cost: a tick takes the length of its slowest step, so a repair can be up to one interval plus that late.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr timeout flock

mode=apply; verb=tick
while [ $# -gt 0 ]; do case "$1" in
  --check) mode=check; shift ;; log) verb=log; shift ;;
  -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done

SUP="$STATE/supervisor"; mkdir -p "$SUP"
if [ "$verb" = log ]; then cat "$SUP/last.log" 2>/dev/null || echo "no tick yet"; exit 0; fi

# One tick at a time. A tick that is still running (its steps are bounded by the timeout, so this ends) is not stacked on.
exec 9>"$SUP/lock"
flock -n 9 || { echo "skipped supervisor (the previous tick is still running)"; exit 0; }

STEP_T="$(sl_cfg .supervisor.step_timeout_seconds)"
LINES_OUT=(); bad=0; fixed_list=()
say() { LINES_OUT+=("$1"); printf '%s\n' "$1"; }
okln() { say "ok $1"; }
skipln() { say "skipped $1 ($2)"; }
fixedln() { say "fixed $1 ($2)"; fixed_list+=("$1"); }
failln() { say "FAILED $1 ($2)"; bad=1; [ "$mode" != apply ] || SL_REPORT_SEAT=supervisor sl_report_500 "$1" "supervisor: $1 failed: $2"; }
# relay <prefix> <text>: the lines a called script printed, kept in the tick's log.
relay() { local l; while IFS= read -r l; do [ -z "$l" ] || say "  $1: $l"; done <<<"$2"; }
# th <seconds> <herdr args>: herdr on this session, killed after <seconds>; function-free so `timeout` can run it.
th() { local t="$1"; shift; timeout --kill-after=5 "$t" env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$HS" "$@"; }
# run <script> <args>: a repo script, killed after the step timeout; RUN_OUT and RUN_RC hold what it said and how it ended.
run() { RUN_OUT="$(timeout --kill-after=10 "$STEP_T" "$@" 2>&1)"; RUN_RC=$?; }
finish() {
  local summary
  if [ "${#fixed_list[@]}" -gt 0 ]; then summary="supervisor: fixed ${fixed_list[*]}"; [ "$bad" = 0 ] || summary+="; FAILED remain"
    [ "$mode" != apply ] || sl_record note 100 supervisor --note "$(cut -c1-230 <<<"$summary")"; fi
  { printf '%s tick (%s)\n' "$(sl_now)" "$mode"; printf '%s\n' "${LINES_OUT[@]}"; } > "$SUP/last.log.tmp" && mv "$SUP/last.log.tmp" "$SUP/last.log"
  exit "$bad"
}

# 1. halt flag, the owner's stop.
halt="$(sl_cfg .halt_flag)"; halt="$(sl_expand "${halt//\$\{state_dir\}/$STATE}")"
if [ -e "$halt" ]; then say "HALTED ($halt)"; finish; fi

# 2. herdr. Started through systemd and nothing else: a server this script forked would be a process under no unit and under no pane.
unit="$(sl_cfg .supervisor.herdr_unit)"
if th 15 workspace list >/dev/null 2>&1; then okln herdr
elif [ -z "$unit" ]; then failln herdr "session $HS is not running and supervisor.herdr_unit is empty"; finish
elif [ "$mode" = check ]; then failln herdr "session $HS is not running; apply would start $unit"; finish
elif ! timeout 30 systemctl --user start "$unit" >/dev/null 2>&1; then failln herdr "systemctl --user start $unit failed"; finish
else
  up=0; for ((i = 0; i < $(sl_cfg .supervisor.herdr_wait_seconds); i++)); do th 5 workspace list >/dev/null 2>&1 && { up=1; break; }; sleep 1; done
  if [ "$up" = 1 ]; then fixedln herdr "started $unit"; else failln herdr "$unit started but session $HS did not answer in $(sl_cfg .supervisor.herdr_wait_seconds)s"; finish; fi
fi

# 3. podman. The rootless pause process dies with every herdr restart and WSL reboot, and until `podman system migrate` every lint
#    and test run fails with an error that names neither (backlog 60l24, seen 2026-10-12).
if [ "$(sl_cfg .supervisor.podman)" = true ] && command -v podman >/dev/null 2>&1; then
  if timeout 30 podman ps >/dev/null 2>&1; then okln podman
  elif [ "$mode" = check ]; then failln podman "podman ps fails; apply would run podman system migrate"
  elif timeout 60 podman system migrate >/dev/null 2>&1 && timeout 30 podman ps >/dev/null 2>&1; then fixedln podman "podman system migrate"
  else failln podman "podman ps fails and podman system migrate did not fix it"; fi
else skipln podman "supervisor.podman is false or podman is not on PATH"; fi

# 4. bringup.sh: its own lines are the tick's lines. It exits 1 when any node FAILED and already reported it, so only a timeout is added here.
bargs=(--worktree "$SL_REPO"); [ "$mode" != check ] || bargs+=(--check)
run "$SL_HERE/bringup.sh" "${bargs[@]}"
relay bringup "$RUN_OUT"
if [ "$RUN_RC" = 124 ] || [ "$RUN_RC" = 137 ]; then failln bringup "killed after ${STEP_T}s"
elif [ "$RUN_RC" != 0 ]; then bad=1; fi
while read -r _ n; do fixed_list+=("$n"); done < <(grep -o '^fixed [^ ]*' <<<"$RUN_OUT")

# 5. belt.
run "$SL_HERE/belt.sh" "--$mode"
if [ "$RUN_RC" = 124 ] || [ "$RUN_RC" = 137 ]; then RUN_OUT="FAILED belt (killed after ${STEP_T}s)"; fi
case "$RUN_OUT" in
  "ok belt") okln belt ;;
  "fixed belt ("*) RUN_OUT="${RUN_OUT#fixed belt (}"; fixedln belt "${RUN_OUT%)}" ;;
  *) failln belt "$(sed -E 's/^FAILED belt \((.*)\)$/\1/' <<<"$RUN_OUT" | tail -n 1)" ;;
esac

# 6. bearings: the owner page server and its wait loop.
# BREADCRUMB 2026-10-12 - WO-20261012-b800. What broke: after each of the three outages of 2026-10-12 the owner's page was down
#   until the architect ran `bearings.sh stable serve --join --session <id>` by hand, because the server is a process in a
#   herdr pane and nothing watched it; and `bearings.sh` only runs inside herdr (HERDR_ENV, HERDR_PANE_ID, HERDR_TAB_ID name
#   the tab whose OPEN slot it claims), which a systemd unit is not. Why this fix: the node judges the server by its pid
#   (`status --json` .alive) and the wait loop by its pane's foreground process, and restarts either by calling bearings.sh
#   with the herdr environment of the tab that already holds the page (the pane labelled for the tier, else the wait pane,
#   else the architect's tab), so the OPEN slot it claims is in the owner's own tab and nothing is split. `serve` is given
#   --join and the session, model and working-on that session.json already holds, which is what rotate-key does for the same
#   reason. A stop that was meant is respected: stopped.json says "stopped", is newer than the herdr server, and no pane
#   still carries the tier's label (a planned `stop` hands both panes back as OPEN); a server killed by a herdr restart or a
#   WSL shutdown also writes "stopped" on SIGTERM, but is older than the new herdr server, so it is restarted. Rejected:
#   restarting from the architect (the point is that no architect is needed) and a pid file of our own (server.json is it).
#   Cost: the owner page's key never changes on a restart (server.json keeps it) and the server's url, which carries the key,
#   is never printed or logged here; a page stopped on purpose before the last herdr start is restarted, once.
bearings_node() {
  local enabled script tier cfg dir st alive plabel wlabel panes pp wp tab apane ag wake s m w sock hstart at reason out
  enabled="$(sl_cfg .supervisor.bearings.enabled)"
  [ "$enabled" = true ] || { skipln bearings "supervisor.bearings.enabled is false"; return 0; }
  script="$(sl_cfg .supervisor.bearings.script)"; script="${script//\$\{repo\}/$SL_REPO}"; tier="$(sl_cfg .supervisor.bearings.tier)"
  [ -x "$script" ] || { failln bearings "no script at $script"; return 0; }
  cfg="$(cd "$(dirname "$script")/.." && pwd)/config/bearings.json"
  plabel="$(jq -r --arg t "$tier" '.tiers[$t].pane_label // empty' "$cfg" 2>/dev/null)"; wlabel="$(jq -r --arg t "$tier" '.tiers[$t].wait_pane_label // empty' "$cfg" 2>/dev/null)"
  case "$plabel$wlabel" in "" | *'${'*) failln bearings "tier $tier has no plain pane labels in $cfg"; return 0 ;; esac
  st="$(timeout 30 "$script" "$tier" status --json 2>/dev/null)" || st=""
  alive="$(jq -r '.alive // false' <<<"$st" 2>/dev/null)"; dir="$(jq -r '.dir // empty' <<<"$st" 2>/dev/null)"
  [ -n "$dir" ] || { failln bearings "$script $tier status --json said nothing"; return 0; }
  panes="$(th 15 pane list 2>/dev/null | jq -c '[.result.panes[]? | {pane_id, tab_id, label: (.label // "")}]')" || panes="[]"
  pp="$(jq -r --arg l "$plabel" 'first(.[] | select(.label == $l) | .pane_id) // empty' <<<"$panes")"
  wp="$(jq -r --arg l "$wlabel" 'first(.[] | select(.label == $l) | .pane_id) // empty' <<<"$panes")"
  wake="$(sl_cfg .watches.architect_agent)"
  ag="$(th 10 agent get "$wake" 2>/dev/null | jq -r '.result.agent.pane_id // empty')"; apane="$ag"
  tab="$(jq -r --arg a "${pp:-x}" --arg b "${wp:-x}" --arg c "${apane:-x}" 'first(.[] | select(.pane_id == $a or .pane_id == $b or .pane_id == $c) | .tab_id) // empty' <<<"$panes")"
  pane_busy() { th 10 pane process-info --pane "$1" 2>/dev/null | jq -e '.result.process_info | .foreground_process_group_id != null and .shell_pid != null and .foreground_process_group_id != .shell_pid' >/dev/null 2>&1; }
  benv() { HERDR_ENV=1 HERDR_SESSION="$HS" HERDR_PANE_ID=supervisor HERDR_TAB_ID="$tab" timeout --kill-after=10 "$STEP_T" env -u HERDR_SOCKET_PATH -u COQ_SEAT "$@"; }
  if [ "$alive" = true ]; then
    if [ -n "$wp" ] && pane_busy "$wp"; then okln bearings; return 0; fi
    [ "$mode" = apply ] || { failln bearings "the wait loop is not running"; return 0; }
    [ -n "$tab" ] || { failln bearings "no tab holds the page's panes or the $wake agent"; return 0; }
    if benv "$script" "$tier" wait --to "$wake" >/dev/null 2>"$SUP/bearings.err"; then fixedln bearings "wait loop restarted, waking $wake"
    else failln bearings "wait loop restart failed: $(tail -n 1 "$SUP/bearings.err")"; fi
    return 0
  fi
  # Not alive. A stop that was meant is left alone.
  if [ -f "$dir/stopped.json" ] && [ -z "$pp" ]; then
    reason="$(jq -r '.reason // empty' "$dir/stopped.json" 2>/dev/null)"; at="$(jq -r '.at // empty' "$dir/stopped.json" 2>/dev/null)"
    sock="${HERDR_SOCKET_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/sessions/$HS/herdr.sock}"; hstart=""
    [ ! -S "$sock" ] || hstart="$(date -u -d "@$(stat -c %Y "$sock")" +%Y-%m-%dT%H:%M:%S)"
    if [ "$reason" = stopped ] && [ -n "$at" ] && [ -n "$hstart" ] && [[ "$at" > "$hstart" ]]; then skipln bearings "stopped on purpose at $at, after this herdr server started"; return 0; fi
  fi
  [ "$mode" = apply ] || { failln bearings "the page server is not running"; return 0; }
  [ -n "$tab" ] || { failln bearings "the page server is down and no tab holds its panes or the $wake agent"; return 0; }
  s="$(jq -r '.session // empty' "$dir/session.json" 2>/dev/null)"; m="$(jq -r '.model // empty' "$dir/session.json" 2>/dev/null)"; w="$(jq -r '.working_on // empty' "$dir/session.json" 2>/dev/null)"
  local sargs=(serve --join); [ -z "$s" ] || sargs+=(--session "$s"); [ -z "$m" ] || sargs+=(--model "$m"); [ -z "$w" ] || sargs+=(--working-on "$w")
  # stdout is the page url, which carries the key: it goes nowhere. stderr is bearings.sh's own notes.
  if ! benv "$script" "$tier" "${sargs[@]}" >/dev/null 2>"$SUP/bearings.err"; then failln bearings "serve failed: $(tail -n 1 "$SUP/bearings.err")"; return 0; fi
  if benv "$script" "$tier" wait --to "$wake" >/dev/null 2>>"$SUP/bearings.err"; then out="server and wait loop restarted, waking $wake"
  else out="server restarted; the wait loop did not: $(tail -n 1 "$SUP/bearings.err")"; fi
  fixedln bearings "$out"
}
bearings_node

finish
