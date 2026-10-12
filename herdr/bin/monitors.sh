#!/usr/bin/env bash
# monitors.sh - the fixed 3x3 monitoring tabs of the coq workspace (SPEC-04 s-labels). Map: herdr/config/monitors.json.
#   monitors.sh grid                                     create or repair every tab of nine panes, idempotently
#   monitors.sh take <slot|pos|watcher|monitor|shell> <label> -- <command>
#                                                        plug a job into an open pane; prints the pane id
#   monitors.sh release <pane> [label]                   stop what runs there, clear, back to the neutral cwd, relabel open
#   monitors.sh status                                   one line per slot, grouped by tab; exit 1 when a slot is missing
#   monitors.sh health                                   one line per reserved slot that carries a command: `ok NAME` or `FAILED NAME (why)`, judged by the
#                                                        pane's foreground process and never by its label; exit 1 when any is FAILED
# Exit: 0 ok, 1 nothing free or a pane left alone, 2 usage, 3 a slot another job holds, 4 herdr failure.
#
# BREADCRUMB 2026-10-10 - ported from ~/tools/bearings-v2/bin/monitors.sh (F-28, owner orders of 2026-09-24: "it should
#   always have 9 panes open, NEVER CLOSE THE PANE, complete work and cleanup, putting the shell back to a neutral
#   location"). What broke there: a watcher control script split the monitors tab once per watcher, so the tab became a
#   stack of 18 panes, and `off` left dead shells labelled as watchers. Why this shape: the grid is drawn once, whole,
#   from the map, and afterwards only three things change a pane: its label, the command run in it, and the cleanup.
#   This script never splits a pane after `grid` and never closes a pane or a tab (grep the non-comment lines). No agent
#   lives in a monitoring tab: `take` refuses a claude or codex command and `grid` reports an agent pane it finds.
#   herdr 0.9.0 shapes (bearings-v2 test rounds 1 and 2, findings T1, T2, T4): the verb is `pane process-info --pane`,
#   a pane is busy when foreground_process_group_id differs from shell_pid (a job named "bash" is still a job), and a
#   brand-new root pane is still in shell startup so it is never read as busy. Rejected: first-open placement for every
#   job, which moves a watcher to a different pane after each restart. Cost: nine shells per tab are always there, and
#   a tenth job of one kind waits (take exits 1) instead of getting a pane.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

MC="${COQ_MONITORS_CONFIG:-$SL_HERDR/config/monitors.json}"
mc() { [ -f "$MC" ] || sl_die "no configuration at $MC"; local v; v="$(jq -r "$1 | if . == null then \"__MISSING__\" else . end" "$MC" 2>/dev/null)" || v=__MISSING__; [ "$v" != __MISSING__ ] || sl_die "monitors config $MC has no $1"; printf '%s' "$v"; }
NEUTRAL="$(mc .neutral_cwd)"; NEUTRAL="${NEUTRAL//\$\{repo\}/$SL_REPO}"
LAYOUT="$SL_HERDR/layouts/$(mc .layout).json"; [ -f "$LAYOUT" ] || sl_die "no layout $LAYOUT"
ROWS="$(jq -r '.grid | split("x")[0]' "$LAYOUT")"; COLS="$(jq -r '.grid | split("x")[1]' "$LAYOUT")"
NSLOT=$((ROWS * COLS))
ntabs="$(mc '.tabs | length')"
K_INT="$(sl_cfg .keys.interrupt)"; PROMPT_MS="$(sl_cfg .prompt_timeout_ms)"
usage() { sed -n '2,9p' "$(readlink -f "$0")" | sed 's/^# \{0,1\}//' >&2; exit 2; }

# All panes of the workspace, one JSON array: pane_id, tab_id, label; agent is null until cmd_grid fills it (agent_in).
all_panes() { sl_h pane list --workspace "$WS" 2>/dev/null | jq -c '[(.result.panes // [])[] | {pane_id, tab_id, label: (.label // ""), agent: null}]'; }
tf() { jq -r --argjson i "$1" ".tabs[\$i] | $2" "$MC"; }
# pos <tab index> <slot index>: N.R.C
pos() { printf '%s.%s.%s' "$(tf "$1" .n)" $(($2 / COLS + 1)) $(($2 % COLS + 1)); }
# reserved <tab index> <pos> <field>: the reserved slot's name or what; empty when the slot is open to any job of the tab's kind.
reserved() { jq -r --argjson i "$1" --arg p "$2" --arg f "$3" '.tabs[$i].reserved // [] | map(select(.pos == $p)) | first | .[$f] // empty' "$MC"; }
open_label() { local w; w="$(reserved "$1" "$2" what)"; [ -n "$w" ] || w="any $(tf "$1" .noun)"; printf '%s OPEN - %s' "$2" "$w"; }
used_label() { local w; w="$(reserved "$1" "$2" what)"; [ -n "$w" ] || w="$(tf "$1" .noun)"; printf '%s %s - %s' "$2" "$w" "$3"; }
is_open() { case "$1" in *" OPEN - "*) return 0 ;; *) return 1 ;; esac; }
# label_pos <label>: the leading N.R.C of a label, else empty.
label_pos() { printf '%s' "$1" | sed -n 's/^\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)\( .*\)\{0,1\}$/\1/p'; }
# slot_index <tab index> <pos>: 0-based row-major index of that position in the tab, else empty.
slot_index() { local n r c; IFS=. read -r n r c <<<"$2"; [ "$n" = "$(tf "$1" .n)" ] || return 0
  [ "$r" -ge 1 ] && [ "$r" -le "$ROWS" ] && [ "$c" -ge 1 ] && [ "$c" -le "$COLS" ] && printf '%s' $(((r - 1) * COLS + c - 1)); }

# load_tab <tab index> <tab id> <panes json>: SLOT_PANE[0..n-1] and SLOT_LABEL[] from the panes whose label carries one
# of the tab's own positions; TAB_STRAYS holds the pane ids that do not (a fresh split, or a label that drifted).
load_tab() {
  local ti="$1" tid="$2" all="$3" pid lab p ix
  SLOT_PANE=(); SLOT_LABEL=(); TAB_STRAYS=()
  for ((ix = 0; ix < NSLOT; ix++)); do SLOT_PANE[ix]=""; SLOT_LABEL[ix]=""; done
  while IFS=$'\t' read -r pid lab; do
    p="$(label_pos "$lab")"; ix=""; [ -z "$p" ] || ix="$(slot_index "$ti" "$p")"
    if [ -n "$ix" ] && [ -z "${SLOT_PANE[ix]}" ]; then SLOT_PANE[ix]="$pid"; SLOT_LABEL[ix]="$lab"; else TAB_STRAYS+=("$pid"); fi
  done < <(jq -r --arg t "$tid" '.[] | select(.tab_id == $t) | [.pane_id, .label] | @tsv' <<<"$all")
}
proc_info() { sl_h pane process-info --pane "$1" 2>/dev/null; }
fg_process() { local n; n="$(proc_info "$1" | jq -r 'first(.result.process_info.foreground_processes[]?.name) // empty')"; n="${n##*/}"; printf '%s' "${n#-}"; }
# agent_in <pane>: the agent binary when a claude or codex runs in the pane's foreground (directly or as `bash .../claude`).
agent_in() { proc_info "$1" | jq -r '[.result.process_info.foreground_processes[]? | .argv // [.name] | map(split("/") | last) | .[0:2][] | select(. == "claude" or . == "codex")] | first // empty'; }
# busy <pane>: a job runs in the pane's foreground. sl_pane_busy (seat-lib.sh, WO-20261012-277d) is the one rule, shared with supervisor.sh.
busy() { proc_info "$1" | sl_pane_busy; }

cmd_grid() {
  local rc=0 ti tlabel tid all ix p out dir from_i ratio pid lab want made held fresh from
  for ((ti = 0; ti < ntabs; ti++)); do
    tlabel="$(tf "$ti" .label)"
    tid="$(sl_tab_id "$WS" "$tlabel")"; fresh=""
    if [ -z "$tid" ]; then
      if [ -n "$WS_ROOT_TAB" ]; then
        # A workspace this run created has one root tab already; it becomes the first tab of the map.
        tid="$WS_ROOT_TAB"; fresh="$WS_ROOT_PANE"; WS_ROOT_TAB=""
        sl_mut tab rename "$tid" "$tlabel" >/dev/null || { echo "cannot rename the root tab to $tlabel" >&2; rc=1; continue; }
      else
        out="$(sl_mut tab create --workspace "$WS" --cwd "$NEUTRAL" --label "$tlabel" --no-focus)" || { echo "cannot create tab $tlabel" >&2; rc=1; continue; }
        tid="$(jq -r '.result.tab.tab_id // empty' <<<"$out")"; [ -n "$tid" ] || { echo "tab create for $tlabel returned no tab id" >&2; rc=1; continue; }
        fresh="$(jq -r '.result.root_pane.pane_id // empty' <<<"$out")"
      fi
    fi
    all="$(all_panes)"
    while read -r pid; do
      p="$(agent_in "$pid")"; [ -z "$p" ] || all="$(jq -c --arg p "$pid" --arg a "$p" 'map(if .pane_id == $p then .agent = $a else . end)' <<<"$all")"
    done < <(jq -r --arg t "$tid" '.[] | select(.tab_id == $t) | .pane_id' <<<"$all")
    while IFS=$'\t' read -r pid lab p; do
      echo "agent $p in a monitoring tab; bring it up in its own tab with herdr/bin/seat.sh ($tlabel, pane $pid, label $lab)" >&2
    done < <(jq -r --arg t "$tid" '.[] | select(.tab_id == $t and .agent != null) | [.pane_id, .label, (.agent | tostring)] | @tsv' <<<"$all")
    if [ "$(jq --arg t "$tid" '[.[] | select(.tab_id == $t and .agent == null)] | length' <<<"$all")" -gt "$NSLOT" ]; then
      echo "tab $tlabel holds more than $NSLOT panes, so it is not a ${ROWS}x${COLS} grid; left alone (retire it by renaming it, then rerun grid)" >&2
      rc=1; continue
    fi
    load_tab "$ti" "$tid" "$all"
    # Free slots take the stray panes in order, unless one is an agent or runs something: those are never touched.
    made=(); held=0
    for p in "${TAB_STRAYS[@]}"; do
      [ "$(jq -r --arg p "$p" 'first(.[] | select(.pane_id == $p) | .agent) // empty' <<<"$all")" = "" ] || { held=1; continue; }
      if [ "$p" != "$fresh" ] && busy "$p"; then echo "pane $p in $tlabel runs $(fg_process "$p") and carries no position label; left alone" >&2; rc=1; held=1; continue; fi
      for ((ix = 0; ix < NSLOT; ix++)); do
        [ -z "${SLOT_PANE[ix]}" ] && { SLOT_PANE[ix]="$p"; SLOT_LABEL[ix]=""; made+=("$ix"); break; }
      done
    done
    # Cells still empty are split from their neighbour (sl_grid_step). A pane left alone keeps its space: no split while one is.
    for ((ix = 0; ix < NSLOT; ix++)); do
      [ -z "${SLOT_PANE[ix]}" ] || continue
      if [ "$held" = 1 ]; then echo "cell $(pos "$ti" "$ix") in $tlabel stays empty while a pane left alone holds its space" >&2; rc=1; break; fi
      if [ "$ix" = 0 ]; then echo "tab $tlabel holds no pane to build the grid from" >&2; rc=1; break; fi
      read -r dir from_i ratio < <(sl_grid_step "$ix" "$ROWS" "$COLS")
      from="${SLOT_PANE[from_i]}"; [ -n "$from" ] || { echo "cell $(pos "$ti" "$ix") has no neighbour pane to split from" >&2; rc=1; break; }
      out="$(sl_mut pane split "$from" --direction "$dir" --ratio "$ratio" --cwd "$NEUTRAL" --no-focus)" \
        || { echo "pane split from $from failed" >&2; rc=1; break; }
      p="$(jq -r '.result.pane.pane_id // empty' <<<"$out")"
      [ -n "$p" ] || { echo "pane split from $from returned no pane id" >&2; rc=1; break; }
      SLOT_PANE[ix]="$p"; SLOT_LABEL[ix]=""
    done
    # Labels: an in-use label is never touched; every other pane reads its open label.
    for ((ix = 0; ix < NSLOT; ix++)); do
      [ -n "${SLOT_PANE[ix]}" ] || continue
      want="$(open_label "$ti" "$(pos "$ti" "$ix")")"; lab="${SLOT_LABEL[ix]}"
      if [ -n "$lab" ] && ! is_open "$lab"; then continue; fi
      [ "$lab" = "$want" ] || sl_mut pane rename "${SLOT_PANE[ix]}" "$want" >/dev/null || { echo "could not rename ${SLOT_PANE[ix]}" >&2; rc=1; }
    done
  done
  return "$rc"
}

# find_slot <tab index> <slot index>: the pane and label now in that slot, as FOUND_PANE and FOUND_LABEL.
find_slot() { local all; all="$(all_panes)"; load_tab "$1" "$(sl_tab_id "$WS" "$(tf "$1" .label)")" "$all"; FOUND_PANE="${SLOT_PANE[$2]}"; FOUND_LABEL="${SLOT_LABEL[$2]}"; }

cmd_take() {
  local target="${1:-}" label="${2:-}" ti ix p cmd first w ok=0 tk all tid named=0
  [ -n "$target" ] && [ -n "$label" ] || usage
  shift 2; [ "${1:-}" != -- ] || shift; cmd="$*"
  # Agents never live in a monitoring tab: the first word that is not a VAR=value assignment names the program.
  first=""; for w in $cmd; do case "$w" in [A-Za-z_]*=*) continue ;; esac; first="${w##*/}"; break; done
  case "$first" in claude|codex) echo "monitors.sh: refusing to run an agent in a monitoring tab; bring it up with herdr/bin/seat.sh" >&2; return 1 ;; esac
  ti=""; ix=""
  for ((tk = 0; tk < ntabs; tk++)); do
    p="$(jq -r --argjson i "$tk" --arg t "$target" '.tabs[$i].reserved // [] | map(select(.name == $t or .pos == $t)) | first | .pos // empty' "$MC")"
    [ -z "$p" ] || { ti="$tk"; ix="$(slot_index "$tk" "$p")"; [ "$p" = "$target" ] || named=1; break; }
  done
  if [ -z "$ti" ] && [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    for ((tk = 0; tk < ntabs; tk++)); do ix="$(slot_index "$tk" "$target")"; [ -z "$ix" ] || { ti="$tk"; break; }; done
  fi
  if [ -n "$ti" ]; then
    find_slot "$ti" "$ix"
    [ -n "$FOUND_PANE" ] || { echo "monitors.sh: slot $(pos "$ti" "$ix") has no pane; run herdr/bin/monitors.sh grid" >&2; return 1; }
    if ! is_open "$FOUND_LABEL"; then
      # The same job asking again is a restart: the pane is handed back clean first, so a command is never typed into a
      # running one. A slot asked for by its reserved name has one owner, so whatever holds it is that owner's earlier job.
      if [ "$named" = 1 ] || [[ "$FOUND_LABEL" == *" - $label" ]]; then cmd_release "$FOUND_PANE" >/dev/null || return 1
      else echo "monitors.sh: slot $(pos "$ti" "$ix") is in use: $FOUND_LABEL" >&2; return 3; fi
    fi
  else
    for ((tk = 0; tk < ntabs; tk++)); do [ "$(tf "$tk" .kind)" = "$target" ] && { ti="$tk"; ok=1; break; }; done
    [ "$ok" = 1 ] || { echo "monitors.sh: $target is neither a slot name, a position nor a kind (watcher, monitor, shell)" >&2; return 2; }
    all="$(all_panes)"; tid="$(sl_tab_id "$WS" "$(tf "$ti" .label)")"; load_tab "$ti" "$tid" "$all"
    FOUND_PANE=""
    # The same job asking again restarts in the slot it already holds, so a re-arm never takes a second one.
    for ((ix = 0; ix < NSLOT; ix++)); do
      [ -z "$(reserved "$ti" "$(pos "$ti" "$ix")" name)" ] || continue
      if [ -n "${SLOT_PANE[ix]}" ] && [ "${SLOT_LABEL[ix]}" = "$(used_label "$ti" "$(pos "$ti" "$ix")" "$label")" ]; then
        cmd_release "${SLOT_PANE[ix]}" >/dev/null || return 1; FOUND_PANE="${SLOT_PANE[ix]}"; break
      fi
    done
    [ -n "$FOUND_PANE" ] || for ((ix = 0; ix < NSLOT; ix++)); do
      [ -z "$(reserved "$ti" "$(pos "$ti" "$ix")" name)" ] || continue
      if [ -n "${SLOT_PANE[ix]}" ] && is_open "${SLOT_LABEL[ix]}"; then FOUND_PANE="${SLOT_PANE[ix]}"; break; fi
    done
    if [ -z "$FOUND_PANE" ]; then
      echo "monitors.sh: no open $target slot in $(tf "$ti" .label); what holds them:" >&2
      for ((ix = 0; ix < NSLOT; ix++)); do echo "  ${SLOT_LABEL[ix]:-$(pos "$ti" "$ix") no pane}" >&2; done
      return 1
    fi
  fi
  sl_mut pane rename "$FOUND_PANE" "$(used_label "$ti" "$(pos "$ti" "$ix")" "$label")" >/dev/null || return 4
  [ -z "$cmd" ] || sl_mut pane run "$FOUND_PANE" "$cmd" >/dev/null || return 4
  printf '%s\n' "$FOUND_PANE"
}

cmd_release() {
  local pane="${1:-}" job="${2:-}" all lab p ti ix tk
  [ -n "$pane" ] || usage
  all="$(all_panes)"
  lab="$(jq -r --arg p "$pane" 'first(.[] | select(.pane_id == $p) | .label) // empty' <<<"$all")"
  [ -n "$lab" ] || { echo "monitors.sh: no pane $pane in workspace $WS_LABEL" >&2; return 1; }
  p="$(label_pos "$lab")"; ti=""; ix=""
  for ((tk = 0; tk < ntabs; tk++)); do ix="$(slot_index "$tk" "${p:-x}")"; [ -z "$ix" ] || { ti="$tk"; break; }; done
  [ -n "$ti" ] || { echo "monitors.sh: pane $pane ($lab) is not a monitoring slot; not touching it" >&2; return 1; }
  # With a label, only that job's pane is handed back: a slot a later job has taken over is left alone (exit 3).
  [ -z "$job" ] || [[ "$lab" == *" - $job" ]] || { echo "monitors.sh: pane $pane now holds $lab, not $job; not touching it" >&2; return 3; }
  # 1. stop what runs there (interrupt only when the foreground is not the shell), 2. wait for the prompt, 3. neutral cwd, 4. label open.
  if busy "$pane"; then sl_mut pane send-keys "$pane" "$K_INT" >/dev/null || return 4; fi
  sl_mut pane wait-output "$pane" --regex "$SL_PROMPT_RE" --timeout "$PROMPT_MS" >/dev/null 2>&1 \
    || { echo "monitors.sh: pane $pane showed no shell prompt in $PROMPT_MS ms; still labelled: $lab" >&2; return 1; }
  sl_mut pane run "$pane" "cd $(printf '%q' "$NEUTRAL") && clear" >/dev/null || return 4
  sl_mut pane rename "$pane" "$(open_label "$ti" "$p")" >/dev/null || return 4
}

cmd_status() {
  local rc=0 ti tid all ix
  all="$(all_panes)"
  for ((ti = 0; ti < ntabs; ti++)); do
    tid="$(sl_tab_id "$WS" "$(tf "$ti" .label)")"
    printf 'tab %s: %s\n' "$(tf "$ti" .n)" "$(tf "$ti" .label)"
    if [ -z "$tid" ]; then echo "  not built; run herdr/bin/monitors.sh grid"; rc=1; continue; fi
    load_tab "$ti" "$tid" "$all"
    for ((ix = 0; ix < NSLOT; ix++)); do
      if [ -z "${SLOT_PANE[ix]}" ]; then printf '  %s  missing\n' "$(pos "$ti" "$ix")"; rc=1
      elif is_open "${SLOT_LABEL[ix]}"; then printf '  %s  [%s]  open\n' "${SLOT_LABEL[ix]}" "${SLOT_PANE[ix]}"
      else printf '  %s  [%s]  in use\n' "${SLOT_LABEL[ix]}" "${SLOT_PANE[ix]}"; fi
    done
    [ "${#TAB_STRAYS[@]}" = 0 ] || { echo "  unlabeled panes: ${TAB_STRAYS[*]}; run herdr/bin/monitors.sh grid"; rc=1; }
  done
  return "$rc"
}

# BREADCRUMB 2026-10-12 - WO-20261012-b800, backlog m2jhs. What broke: after the 2026-10-12 WSL reboot six of seven reserved
#   monitor panes (lease, guard, events, queue, board, flow) were bare shells for 40 minutes while bringup.sh --check printed
#   ok for each, because bringup grepped the slot label from `status` and a label says what a pane was told to do, not what
#   it is doing. Why this fix: the same `busy` test cmd_grid and cmd_release already trust (herdr `pane process-info`: the
#   foreground process group differs from the pane's shell) is asked of every reserved slot that has a command, so a dead
#   command reads FAILED whatever the pane is called. A slot labelled OPEN whose pane is busy is FAILED too and is never
#   restarted by a caller: `take` would type a second command into a running job. Rejected: matching the foreground argv to
#   the configured command (the commands are `while` loops whose foreground is a sleep) and a heartbeat file per watcher
#   (a second thing to keep true). Cost: a command that exits at once (a typo in monitors.json) is restarted every run, and
#   a command that is alive but hung reads ok; hung ones are the supervisor's timeout, not this verb's.
cmd_health() {
  local rc=0 ti tid all pos name ix pane lab why
  all="$(all_panes)"
  for ((ti = 0; ti < ntabs; ti++)); do
    tid="$(sl_tab_id "$WS" "$(tf "$ti" .label)")"
    [ -n "$tid" ] && load_tab "$ti" "$tid" "$all"
    while IFS=$'\t' read -r pos name; do
      [ -n "$pos" ] || continue
      if [ -z "$tid" ]; then echo "FAILED $name (tab $(tf "$ti" .n) is not built; run herdr/bin/monitors.sh grid)"; rc=1; continue; fi
      ix="$(slot_index "$ti" "$pos")"; pane="${SLOT_PANE[ix]}"; lab="${SLOT_LABEL[ix]}"
      if [ -z "$pane" ]; then echo "FAILED $name (slot $pos has no pane)"; rc=1; continue; fi
      if ! proc_info "$pane" | jq -e '.result.process_info | .shell_pid != null' >/dev/null 2>&1; then echo "FAILED $name (herdr process-info for pane $pane failed)"; rc=1; continue; fi
      if busy "$pane"; then
        if is_open "$lab"; then echo "FAILED $name (slot $pos is labelled open but pane $pane runs $(fg_process "$pane"); left alone)"; rc=1
        elif [ "$lab" != "$(used_label "$ti" "$pos" "$name")" ]; then echo "FAILED $name (slot $pos holds '$lab', not $name)"; rc=1
        else echo "ok $name"; fi
      else
        if is_open "$lab"; then why="slot $pos is open and its pane is a bare shell"; else why="pane $pane is a bare shell, the command in slot $pos is not running"; fi
        echo "FAILED $name ($why)"; rc=1
      fi
    done < <(jq -r --argjson i "$ti" '.tabs[$i].reserved // [] | .[] | select(.command != null) | [.pos, .name] | @tsv' "$MC")
  done
  return "$rc"
}

verb="${1:-}"; case "$verb" in grid|take|release|status|health) ;; *) usage ;; esac
sl_h workspace list >/dev/null 2>&1 || { SL_EXIT=4 sl_die "herdr session $HS is not running; herdr/bin/bringup.sh starts it"; }
WS="$(sl_ws_id)"; WS_ROOT_TAB=""; WS_ROOT_PANE=""
if [ -z "$WS" ]; then
  # Only grid builds; every other verb needs a workspace that is already there.
  [ "$verb" = grid ] || SL_EXIT=1 sl_die "no workspace labelled $WS_LABEL in herdr session $HS; run herdr/bin/monitors.sh grid"
  out="$(sl_mut workspace create --label "$WS_LABEL" --cwd "$NEUTRAL" --no-focus)" || SL_EXIT=4 sl_die "workspace create failed"
  WS="$(jq -r '.result.workspace.workspace_id // empty' <<<"${out:-{\}}")"; [ -n "$WS" ] || SL_EXIT=4 sl_die "workspace create returned no id"
  WS_ROOT_TAB="$(jq -r '.result.tab.tab_id // empty' <<<"$out")"; WS_ROOT_PANE="$(jq -r '.result.root_pane.pane_id // empty' <<<"$out")"
fi
case "$verb" in
  grid) cmd_grid ;;
  take) shift; cmd_take "$@" ;;
  release) shift; cmd_release "$@" ;;
  status) cmd_status ;;
  health) cmd_health ;;
esac
