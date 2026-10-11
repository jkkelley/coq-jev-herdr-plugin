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
#   5 belt           the route runner pane in use and the belt fresh (config .belt)
#                    otherwise check FAILED belt (why); apply monitors.sh take <slot>, wait for a fresh belt, fixed belt
#   6 every seat     each seat record with no ended_at: seat.sh --check
#                    "agent not running" -> check FAILED <name> (agent gone); apply seat.sh --down, fixed <name>
#                    any other difference -> FAILED <name> (<difference>), reported in both modes and never repaired
#   7 guard          compaction-guard recover [--apply], once, only when config .require_guard is true
#   8 tickets        one WARN per in-progress ticket with no live seat (the queue resumes it; WARN never fails the run)
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

# 5. the belt (WO-20261011-6842). The runner pane is in use (the monitors.sh status line for the slot) and config .belt.status
#    exits 0. Repair is the same call bringup.sh makes for that slot, so the pane, label and command come from monitors.json.
# BREADCRUMB 2026-10-11 - WO-20261011-6842. What broke: 2026-10-11 18:01Z to 18:23Z the route runner was not running, so every
#   gate record sat unrouted and recover.sh printed ok for everything it checked, because it checked health and not flow.
#   Why this fix: a node that asks monitors.sh whether the runner slot is in use and route.sh status whether the belt moves, and
#   restarts the slot through monitors.sh take (it hands a running job back clean first, so a hung runner restarts in its own
#   pane). Rejected: killing the runner by pid (a process under no pane is the thing the herdr-first law forbids) and a
#   second definition of stale here (route.sh status owns stale_seconds). Cost: a restart does not replay the interrupted record,
#   route.sh writes a 500 for it on start; and the settle wait is a sleep loop of at most .belt.settle_seconds.
bslot="$(sl_cfg .belt.slot)"; bsettle="$(sl_cfg .belt.settle_seconds)"; bstat="$(sl_cfg .belt.status)"; bstat="${bstat//\$\{repo\}/$SL_REPO}"
MC="${COQ_MONITORS_CONFIG:-$SL_HERDR/config/monitors.json}"
bwhat="$(jq -r --arg n "$bslot" '[.tabs[].reserved[] | select(.name == $n)] | first | .what // empty' "$MC")"
bcmd="$(jq -r --arg n "$bslot" '[.tabs[].reserved[] | select(.name == $n)] | first | .command // empty' "$MC")"; bcmd="${bcmd//\$\{repo\}/$SL_REPO}"
# belt_state: 0 when the runner pane is in use and the belt is fresh; else 1 with BELT_WHY.
belt_state() {
  local st out bs
  st="$("$MON" status 2>/dev/null)"
  if ! grep -qF " $bwhat - $bslot  [" <<<"$st"; then BELT_WHY="runner pane missing (slot $bslot is not running $bwhat)"; return 1; fi
  read -ra bs <<<"$bstat"
  if out="$("${bs[@]}" 2>&1)"; then BELT_WHY=""; return 0; fi
  BELT_WHY="belt $(head -n 1 <<<"$out" | sed -E 's/^belt: //')"; return 1
}
if [ -z "$bwhat" ] || [ -z "$bcmd" ]; then failln belt "monitors.json has no slot $bslot with a command"
elif belt_state; then okln belt
elif ! apply; then failln belt "$BELT_WHY"
else
  why="$BELT_WHY"
  if [ "$DRY" = 1 ]; then fixedln belt "dry run: would restart slot $bslot ($why)"
  elif "$MON" take "$bslot" "$bslot" -- "$bcmd" >/dev/null 2>&1; then
    for ((i = 0; i < bsettle; i++)); do belt_state && break; sleep 1; done
    if belt_state; then fixedln belt "runner restarted through monitors.sh take $bslot ($why)"
    else failln belt "restart left no fresh belt in ${bsettle}s: $BELT_WHY"; fi
  else failln belt "monitors.sh take $bslot failed ($why)"; fi
fi

# 6. every other seat record that was never ended. A record with ended_at is history and is not read.
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

# 7. the guard, once. The count is of sessions whose pane is gone and that the guard can re-arm; see the breadcrumb for why
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

# 8. tickets left open. In progress with no seat record that is open and answered for by herdr: the queue resumes it.
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
