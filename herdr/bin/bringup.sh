#!/usr/bin/env bash
# bringup.sh - WFL-bringup (SPEC-04 s-bringup): the system comes up before any agent, in this order, each node a check
# and, when it fails, one repair: herdr session -> control plane -> compaction-guard -> monitors grid -> monitor seat ->
# the reserved monitor panes (event log tail, queue list). Worker seats come later, through seat.sh, which refuses while
# the monitor seat is down (DEC-system-before-agents, locked).
#   bringup.sh [--worktree DIR]     repair what is down, in order; stops at the first failure with a 500 record and a notification
#   bringup.sh --check              report only; no record, no notification
# Prints one line per node: ok | fixed (what) | skipped (why) | FAILED (why). Exit 0 when every node is up, 1 otherwise.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

mode=apply; wt="$SL_REPO"
while [ $# -gt 0 ]; do case "$1" in
  --check) mode=check; shift ;; --worktree) wt="${2:?--worktree needs a directory}"; shift 2 ;;
  -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done
fixed=0
okln() { printf 'ok %s\n' "$1"; }
skipln() { printf 'skipped %s (%s)\n' "$1" "$2"; }
fixedln() { printf 'fixed %s (%s)\n' "$1" "$2"; fixed=$((fixed + 1)); sl_record note 100 bringup --note "bringup: $1 $2"; }
# The first failure ends the run: every later node needs this one (the DAG is a chain).
failln() {
  printf 'FAILED %s (%s)\n' "$1" "$2"
  if [ "$mode" = apply ]; then
    sl_record note 500 bringup --note "bringup: $1 failed: $2"
    sl_h notification show "500 bringup: $1 failed: $2" >/dev/null 2>&1 || true
  fi
  exit 1
}

# 1. herdr session. Never started here: on the host systemd owns it, in the suite the world does; a seat that started a
#    server would hide a process under an agent (owner rule 2026-10-10).
sl_h workspace list >/dev/null 2>&1 || failln herdr "session $HS is not running; start the herdr server for it first (systemd unit herdr-$HS)"
okln herdr

# 2. control plane, only when configured.
url="$(sl_cfg '.control_plane.health_url // ""')"
if [ -z "$url" ]; then skipln control-plane "no control_plane.health_url configured"
else
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || echo 000)"
  [ "$code" = 200 ] && okln control-plane || failln control-plane "health $url answered $code, not 200"
fi

# 3. compaction-guard doctor, only when seats require the guard.
if [ "$(sl_cfg .require_guard)" = true ]; then
  if ! command -v compaction-guard >/dev/null 2>&1; then failln compaction-guard "not on PATH"
  elif compaction-guard doctor 2>/dev/null | jq -e '.ok == true' >/dev/null 2>&1; then okln compaction-guard
  else failln compaction-guard "doctor is not ok: $(compaction-guard doctor 2>&1 | tr -d '\n' | head -c 200)"; fi
else skipln compaction-guard "require_guard is false"; fi

# 4. monitors grid: the fixed tabs, drawn or repaired by monitors.sh grid.
MON="$SL_HERE/monitors.sh"
# Status is read into a variable once and grepped from there: `status | grep -q` closes the pipe on the first match and
# pipefail then reports monitors.sh's SIGPIPE as a failure (case 04, first run: every rerun "fixed" a pane already there).
mon_why() { grep -m1 -E 'missing|not built|unlabeled|no workspace|left alone' <<<"$1" | sed -E 's/^[[:space:]]+//; s/^monitors.sh: //'; }
st="$("$MON" status 2>&1)" && st_rc=0 || st_rc=$?
if [ "$st_rc" = 0 ]; then okln monitors
elif [ "$mode" = check ]; then failln monitors "$(mon_why "$st")"
elif "$MON" grid >/dev/null 2>&1 && st="$("$MON" status 2>&1)"; then fixedln monitors "grid drawn"
else failln monitors "grid did not leave every slot in place: $(mon_why "$st")"; fi

# 5. the monitor seat (door 2 of seat.sh). A seat check that fails for any reason but "agent not running" is a drift
#    seat.sh repairs on its rerun, so the rerun is the one repair for both.
mseat="$(sl_cfg .monitor_seat)"; SEAT="$SL_HERE/seat.sh"
mrec="$(sl_seat_record "$mseat")"
if [ -f "$mrec" ] && [ -z "$(jq -r '.ended_at // empty' "$mrec")" ] && out="$("$SEAT" --check "$mseat" 2>&1)"; then okln monitor-seat
elif [ "$mode" = check ]; then failln monitor-seat "${out:-no live seat record}"
else
  [ ! -f "$mrec" ] || [ -z "$(jq -r '.ended_at // empty' "$mrec")" ] || rm -f "$mrec"   # a downed record is history; door 2 writes a new one
  if out="$("$SEAT" --role monitor --task "$(sl_cfg .monitor_task)" --worktree "$wt" 2>&1)"; then
    fixedln monitor-seat "seat.sh --role monitor, started $(jq -r .started <<<"$out")"
  else failln monitor-seat "seat.sh: $(tail -n 1 <<<"$out")"; fi
fi

# 6. the reserved monitor panes that carry a command in herdr/config/monitors.json (guard lease watcher, compaction-guard
#    watch, event log tail, queue list).
# BREADCRUMB 2026-10-10 - WO-20261010-8fa8. What broke: nothing ran herdr/bin/unfreeze.sh, so on 2026-10-10 the architect
#   seat sat frozen 20:57-21:36 UTC behind a guard lease that expired at 21:00:20Z (full account in unfreeze.sh's header).
#   Why this fix: monitors.json slots 1.1.1 (lease) and 1.1.2 (guard) now carry commands and this loop, which already
#   plugs in every reserved slot that has one, needed no change; a new loop for watchers would be a second way to start a
#   pane. JSON has no comments, so the reason lives here. Cost: bringup now fails (500) when it cannot start either
#   pane, and the watcher panes need unfreeze.sh and compaction-guard on PATH wherever herdr was started.
# BREADCRUMB 2026-10-11 - WO-20261011-6842. What broke: on 2026-10-11 nothing started the route runner or watched the flow, so a
#   line sat still for 22 minutes with every gate record posted (18:01Z to 18:23Z) and nothing said so. Why this fix: monitors.json
#   slots 2.2.2 (runner) and 2.2.3 (flow) carry factory/bin/route.sh run and factory/bin/flow.sh run, in that order because the
#   flow watch judges the belt the runner keeps; this loop already plugs in every reserved slot that has a command, so it needed
#   no change and recover.sh's belt node restarts the same slot through monitors.sh take. Rejected: a second start path for the
#   runner (WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a
#   seat while the belt is stopped still owns the refusal of a seat while the belt is stopped). Cost: bringup now fails (500)
#   when either pane cannot be plugged in, and both need jq and herdr on PATH where herdr was started.
MC="${COQ_MONITORS_CONFIG:-$SL_HERDR/config/monitors.json}"
while IFS=$'\t' read -r name what cmd; do
  cmd="${cmd//\$\{repo\}/$SL_REPO}"
  st="$("$MON" status 2>/dev/null)"
  if grep -qF " $what - $name  [" <<<"$st"; then okln "pane-$name"
  elif [ "$mode" = check ]; then failln "pane-$name" "slot $name is not running $what"
  elif "$MON" take "$name" "$name" -- "$cmd" >/dev/null 2>&1; then fixedln "pane-$name" "$what plugged in"
  else failln "pane-$name" "monitors.sh take $name failed"; fi
done < <(jq -r '.tabs[].reserved[] | select(.command != null) | [.name, .what, .command] | @tsv' "$MC")

[ "$mode" = check ] || [ "$fixed" = 0 ] || sl_h notification show "bringup: $fixed node(s) repaired, system up" >/dev/null 2>&1 || true
exit 0
