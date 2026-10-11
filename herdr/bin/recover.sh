#!/usr/bin/env bash
# recover.sh - RUN-recover (SPEC-04 s-recovery): after a crash, a reboot or a herdr restart, close the record of every
# seat that died, re-arm the guard and report the tickets left open, so the owner does none of it by hand.
#   recover.sh --check      report only: no repair, no record, no notification
#   recover.sh --apply      repair what is repairable, then one note record and one herdr notification
# The order is fixed, each object prints one line:
#   1 halt flag      the file config .halt_flag names exists -> print HALTED, exit 0, change nothing, never lift it here
#   2 herdr          the session answers (never started here: systemd owns it on the host, the world owns it in the suite)
#   3 monitors       monitors.sh status                      (apply: monitors.sh grid)
#   4 monitor seat   seat.sh --check <monitor_seat>          (apply: bringup.sh)
#   5 every seat     each seat record with no ended_at: seat.sh --check
#                    "agent not running" -> check FAILED <name> (agent gone); apply seat.sh --down, fixed <name>
#                    any other difference -> FAILED <name> (<difference>), reported in both modes and never repaired
#   5b panes         every reserved monitors.json slot with a command: label up and its `check` passing, else restarted (apply)
#   6 guard          compaction-guard recover [--apply], once, only when config .require_guard is true
#   7 tickets        one WARN per in-progress ticket with no live seat (the queue resumes it; WARN never fails the run)
# Lines: ok <object> | fixed <object> (what) | skipped <object> (why) | FAILED <object> (why) | WARN <ticket> - <title> (..)
# Exit: 0 nothing FAILED (HALTED included), 1 something FAILED, 2 usage. DRY_RUN=1 prints every mutating call, writes nothing.
#
# BREADCRUMB 2026-10-10 - RUN-recover, WO-20261010-c274. Not ported: bearings-v2 had no recover script, the owner did this
#   by hand after each crash. What the design refuses, and why:
#   - Resuming a seat. seat.sh --ticket does that and re-attaches by label (SPEC-04 s-recovery); resume_agents_on_restore
#     stays false so nothing resumes silently. Recovery here only makes the records true: a gone agent is downed so the
#     queue sees a free slot and the ticket WARN below is the hand-off. Cost: a gone seat needs one more command, from the queue.
#   - Repairing any difference but "agent not running". A missing pane or drifted settings on a live agent is repaired by
#     a seat.sh rerun for that ticket, which is a decision (it may restart work), so it is reported FAILED and left.
#   - Lifting the halt flag, or starting the herdr server (owner rule 2026-10-10: nothing hides a process under an agent).
#   - Scoping the guard. compaction-guard recover walks every session on the host, not only this repo's seats (115 on the
#     owner's host on 2026-10-10, 100+ of them gone panes from other projects), so --check counts them as a WARN, never a
#     FAILED, and --apply is the owner's explicit mode. Rejected: --session per seat, the seat record carries no guard session id.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

mode=""
while [ $# -gt 0 ]; do case "$1" in
  --check) mode=check; shift ;; --apply) mode=apply; shift ;;
  -h|--help) sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done
[ -n "$mode" ] || { sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

SEAT="$SL_HERE/seat.sh"; MON="$SL_HERE/monitors.sh"; BU="$SL_HERE/bringup.sh"
bad=0; fixed=0; warned=0; failed_names=()
okln() { printf 'ok %s\n' "$1"; }
skipln() { printf 'skipped %s (%s)\n' "$1" "$2"; }
fixedln() { printf 'fixed %s (%s)\n' "$1" "$2"; fixed=$((fixed + 1)); }
failln() { printf 'FAILED %s (%s)\n' "$1" "$2"; bad=1; failed_names+=("$1"); }
apply() { [ "$mode" = apply ]; }

# The last act of a run in apply mode: one note record (100 clean, 500 when anything is still FAILED) and one
# notification. Neither is written in --check, and neither when the halt flag stops the run.
finish() {
  local summary code
  if [ "$bad" = 0 ]; then code=100; summary="recover: $fixed repaired, $warned ticket warning(s), every object ok"
  else code=500; summary="recover: FAILED ${failed_names[*]}; $fixed repaired"; fi
  if apply; then
    sl_record note "$code" recover --note "$(cut -c1-230 <<<"$summary")"
    if [ "$code" = 100 ]; then sl_h notification show "$summary" >/dev/null 2>&1 || true
    else sl_h notification show "500 $summary" >/dev/null 2>&1 || true; fi
  fi
  exit "$bad"
}

# 1. halt flag. The owner's stop: nothing below may change anything while it stands.
halt="$(sl_cfg .halt_flag)"; halt="$(sl_expand "${halt//\$\{state_dir\}/$STATE}")"
if [ -e "$halt" ]; then echo "HALTED ($halt)"; exit 0; fi

# 2. herdr. Without a session nothing below can be checked, so this is the one node that ends the run.
if ! sl_h workspace list >/dev/null 2>&1; then
  failln herdr "session $HS is not running; start the herdr server for it first (systemd unit herdr-$HS)"
  finish
fi
okln herdr

# why_of <text>: the first line that explains a failure, with the script prefix stripped.
why_of() { { grep -m1 -E "$2" <<<"$1" || tail -n 1 <<<"$1"; } | sed -E 's/^[[:space:]]+//; s/^[a-z.-]+\.sh: //'; }

# 3. monitors grid.
st="$("$MON" status 2>&1)" && st_rc=0 || st_rc=$?
mon_re='missing|not built|unlabeled|no workspace|left alone'
if [ "$st_rc" = 0 ]; then okln monitors
elif ! apply; then failln monitors "$(why_of "$st" "$mon_re")"
elif "$MON" grid >/dev/null 2>&1 && st="$("$MON" status 2>&1)"; then fixedln monitors "grid drawn"
else failln monitors "grid did not leave every slot in place: $(why_of "$st" "$mon_re")"; fi

# seat_state <name>: SEAT_RC and SEAT_WHY from one seat.sh --check. gone=1 when the only reason that matters is that
# herdr no longer answers for the agent; every other line is a drift and joins the reason as it is.
seat_state() {
  local out
  out="$("$SEAT" --check "$1" 2>&1)"; SEAT_RC=$?; SEAT_GONE=0
  if [ "$SEAT_RC" = 0 ]; then SEAT_WHY=""; return 0; fi
  if grep -q 'agent not running' <<<"$out"; then SEAT_GONE=1; SEAT_WHY="agent gone"
  else SEAT_WHY="$(sed -E "s/^$1: //" <<<"$out" | paste -sd ';' - | sed 's/;/; /g')"; fi
  return 0
}

# 4. the monitor seat. Its repair is bringup.sh: one rerun of seat.sh --role monitor, with the gate and grid it needs.
mseat="$(sl_cfg .monitor_seat)"; mrec="$(sl_seat_record "$mseat")"
mend=""; [ ! -f "$mrec" ] || mend="$(jq -r '.ended_at // empty' "$mrec")"
if [ ! -f "$mrec" ]; then SEAT_RC=3; SEAT_WHY="no seat record"
elif [ -n "$mend" ]; then SEAT_RC=3; SEAT_WHY="down since $mend"
else seat_state "$mseat"; fi
if [ "$SEAT_RC" = 0 ]; then okln "$mseat"
elif ! apply; then failln "$mseat" "$SEAT_WHY"
else
  out="$("$BU" --worktree "$SL_REPO" 2>&1)"; bu_rc=$?
  if [ "$bu_rc" = 0 ] && [ -f "$mrec" ] && [ -z "$(jq -r '.ended_at // empty' "$mrec")" ] && seat_state "$mseat" && [ "$SEAT_RC" = 0 ]; then
    fixedln "$mseat" "bringup.sh brought the seat back"
  else failln "$mseat" "bringup.sh: $(tail -n 1 <<<"$out")"; fi
fi

# 5. every other seat record that was never ended. A record with ended_at is history and is not read.
for f in "$STATE"/seats/*/seat.json; do
  [ -f "$f" ] || continue
  [ -z "$(jq -r '.ended_at // empty' "$f")" ] || continue
  n="$(jq -r .name "$f")"; [ "$n" != "$mseat" ] || continue
  seat_state "$n"
  if [ "$SEAT_RC" = 0 ]; then okln "$n"
  elif [ "$SEAT_GONE" = 1 ] && apply; then
    if out="$("$SEAT" --down "$n" 2>&1)"; then fixedln "$n" "agent gone, seat downed"
    else failln "$n" "agent gone, seat.sh --down failed: $(tail -n 1 <<<"$out")"; fi
  else failln "$n" "$SEAT_WHY"; fi
done

# 5b. the reserved monitor panes that carry a command in monitors.json (event tail, queue list, board watch, the three blueprint
#    servers). Same rule as bringup.sh's loop: a slot is ok when its label is up and its `check`, when it has one, passes; a slot
#    that is down or fails its check is restarted by `monitors.sh take` in apply mode and FAILED in check mode.
# BREADCRUMB 2026-10-11 - WO-20261011-ceea. What broke: recover.sh repaired the grid, the monitor seat and the seats, and no
#   pane that bringup.sh plugs in, so a blueprint server killed in its pane stayed dead until someone reran bringup.sh by hand
#   (AC-H3: recover.sh restarts a killed one). Why this fix: the loop is the same few lines as bringup.sh's, kept here so recover
#   needs no second bringup run (bringup also repairs the monitor seat and sends its own notification). Rejected: calling
#   bringup.sh from here for panes (it stops at its first failure and its note records would double recover's). It runs after
#   the seats so the order of the lines above it is unchanged. Cost: the loop exists twice; monitors.json is the one source.
MC="${COQ_MONITORS_CONFIG:-$SL_HERDR/config/monitors.json}"
while IFS=$'\t' read -r pname pwhat pcmd pchk; do
  pcmd="${pcmd//\$\{repo\}/$SL_REPO}"; pchk="${pchk//\$\{repo\}/$SL_REPO}"
  pst="$("$MON" status 2>/dev/null)"
  pup=0; grep -qF " $pwhat - $pname  [" <<<"$pst" && pup=1
  if [ "$pup" = 1 ] && { [ -z "$pchk" ] || bash -c "$pchk" >/dev/null 2>&1; }; then okln "pane-$pname"
  elif ! apply; then failln "pane-$pname" "$([ "$pup" = 1 ] && echo "slot is up but its check failed" || echo "slot is not running $pwhat")"
  elif "$MON" take "$pname" "$pname" -- "$pcmd" >/dev/null 2>&1; then fixedln "pane-$pname" "$pwhat $([ "$pup" = 1 ] && echo restarted || echo 'plugged in')"
  else failln "pane-$pname" "monitors.sh take $pname failed"; fi
done < <(jq -r '.tabs[].reserved[] | select(.command != null) | [.name, .what, .command, (.check // "")] | @tsv' "$MC")

# 6. the guard, once. The count is of sessions whose pane is gone and that the guard can re-arm; see the breadcrumb for why
#    that is a WARN and not a FAILED.
if [ "$(sl_cfg .require_guard)" = true ]; then
  if ! command -v compaction-guard >/dev/null 2>&1; then failln compaction-guard "not on PATH"
  else
    gargs=(recover); apply && gargs+=(--apply)
    gout="$(compaction-guard "${gargs[@]}" 2>&1)"; grc=$?
    need="$(jq -Rn '[inputs | fromjson? | select(type == "object" and .needs_recovery == true)] | length' <<<"$gout" 2>/dev/null || echo 0)"
    if [ "$grc" != 0 ]; then failln compaction-guard "recover exited $grc: $(tail -n 1 <<<"$gout" | head -c 160)"
    elif apply; then
      if [ "$need" = 0 ]; then okln compaction-guard; else fixedln compaction-guard "recover --apply ran over $need session(s) that needed it"; fi
    elif [ "$need" = 0 ]; then okln compaction-guard
    else printf 'WARN compaction-guard (%s session(s) need recovery; recover.sh --apply runs compaction-guard recover --apply)\n' "$need"; warned=$((warned + 1)); fi
  fi
else skipln compaction-guard "require_guard is false"; fi

# 7. tickets left open. In progress with no seat record that is open and answered for by herdr: the queue resumes it.
#    A ticket file starts with a JSON frontmatter between two --- lines (work-order skill); archive/ is closed work.
while IFS= read -r tf; do
  fm="$(awk 'NR == 1 && $0 == "---" { on = 1; next } on && $0 == "---" { exit } on' "$tf")"
  [ "$(jq -r '.status // empty' <<<"$fm" 2>/dev/null)" = in-progress ] || continue
  tid="$(jq -r .id <<<"$fm")"; title="$(jq -r .title <<<"$fm")"; seated=0
  for f in "$STATE"/seats/*/seat.json; do
    [ -f "$f" ] || continue
    [ "$(jq -r '.ticket // empty' "$f")" = "$tid" ] && [ -z "$(jq -r '.ended_at // empty' "$f")" ] || continue
    sl_agent_live "$(jq -r .name "$f")" && { seated=1; break; }
  done
  [ "$seated" = 1 ] || { printf 'WARN %s - %s (no live seat; the queue resumes it)\n' "$tid" "$title"; warned=$((warned + 1)); }
done < <(find "$SL_REPO/work-orders" -name 'WO-*.md' -not -path '*/archive/*' 2>/dev/null | sort)

finish
