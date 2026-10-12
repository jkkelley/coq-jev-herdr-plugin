#!/usr/bin/env bash
# seat.sh - the one way a seat comes up, is checked, is taken down and is audited (SPEC-04 RUN-seat-up).
#   seat.sh --ticket WO-ID --role R [--runtime claude|codex] [--worktree DIR]   door 1: the ticket names the seat (worker-WO-...); no --worktree leases a treehouse slot to the ticket and checks it out on the ticket's branch
#   seat.sh --role R --task "text" [--worktree DIR]                             door 2: a fixed seat (monitor, merger, orchestrator)
#   seat.sh --adopt --role R --pane P --session ID [--ticket WO-ID] [--worktree DIR]   adopt: the claude already running in pane P becomes the role's seat in place
#                               (seat.json, agent name, pane label, settings.json for the next restart, seat.up 100); no agent is started or stopped
#   seat.sh ... --resume ID     on door 1 or door 2: start claude with --resume ID, so a seat can be re-started from a session transcript in a fresh pane
#   seat.sh --check NAME        one line per difference, exit 1 if any; a downed seat prints "down since", exit 3
#   seat.sh --down NAME         retire.sh, close the tab, return the slot this seat leased, record seat.down 100; a second --down records nothing
#                               the log names each process in the slot (pid, name) first; a foreign one refuses the return, exit 3
#   seat.sh --audit             every agent process on the host: COMPLIANT or OUT OF COMPLIANCE + seat.stalled 500; exit 1 if any
# Reads roles/<role>.json and the layout it names (herdr/layouts/<pane_layout>.json). Workspace by label, tab by label,
# panes from the layout with their labels, settings rendered from the role's allow and deny into
# <state_dir>/seats/<name>/settings.json, COQ_* exported on one physical line into the agent pane only, a shell prompt
# waited for, `herdr agent start` with the role's model, effort and permission mode, then the brief (roles/bin/brief.sh)
# as the first prompt; a claude seat that then acks the compaction-guard memo and goes idle gets one continue prompt (nudge_seat, seat.json nudged_at). A rerun repairs: a pane with the right label is kept, strays are relabelled, missing ones split.
# Prints one JSON line. DRY_RUN=1 prints every mutating herdr call and writes nothing.
# Exit: 0 ok, 1 check differences, 2 usage, 3 refused (gate, cap, guard, name, no test pane for a ticket seat, no treehouse slot, a ticket with no branch, a slot that cannot reach it, --down with a foreign process in the slot), 4 herdr failure
#   or a slot that would not come back on --down.
#
# BREADCRUMB 2026-10-10 - ported from ~/tools/bearings-v2/bin/seat.sh (644 lines, proven on the rime fleet) and
#   reduced to what SPEC-04 asks: the role file is the whole contract (no ticket-side model or layout override, the
#   architect writes the role it wants into the ticket's degrees of freedom), records go through events/bin/event.sh
#   instead of a2a.jsonl, compaction grants are gone because the guard binds itself through .claude/settings.json hooks
#   in the worktree (the file is in git, so every worktree carries it) and the status line tap the same way.
#   Rejected: keeping bearings-v2's `rime` special case for bypassPermissions; here the role schema decides the mode
#   (roles/schema/role.schema.json permission_mode) and the audit compares the process against its role, nothing else.
#   Cost: a role that asks for bypassPermissions gets it; its fence is its deny list and its playbook.
# BREADCRUMB 2026-10-10 - the bring-up gate (DEC-system-before-agents, locked). A seat of any role but the monitor is
#   refused while the monitor seat is down, so no agent ever runs unwatched. Tests set bringup_gate false in their
#   own config, or bring a stub monitor up first. herdr/config/exemptions.json can lift it per seat with a card id.
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

usage() { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
refuse() { SL_EXIT=3 sl_die "$@"; }
mode=up; ticket=""; role=""; task=""; wt="$SL_REPO"; wt_given=0; name_arg=""; runtime_arg=""; adopt_pane=""; claude_sid=""; resume_id=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ticket) ticket="${2:?--ticket needs an id}"; shift 2 ;;
    --role) role="${2:?--role needs a role}"; shift 2 ;;
    --task) task="${2:?--task needs text}"; shift 2 ;;
    --runtime) runtime_arg="${2:?--runtime needs claude or codex}"; shift 2 ;;
    --worktree) wt="${2:?--worktree needs a directory}"; wt_given=1; shift 2 ;;
    --adopt) mode=adopt; shift ;;
    --pane) adopt_pane="${2:?--pane needs a pane id}"; shift 2 ;;
    --session) claude_sid="${2:?--session needs a claude session id}"; shift 2 ;;
    --resume) resume_id="${2:?--resume needs a claude session id}"; shift 2 ;;
    --check) mode=check; name_arg="${2:?--check needs a seat name}"; shift 2 ;;
    --down) mode=down; name_arg="${2:?--down needs a seat name}"; shift 2 ;;
    --audit) mode=audit; shift ;;
    -h|--help) usage ;;
    *) sl_die "unknown argument $1" ;;
  esac
done
wt="$(cd "$wt" && pwd -P)"
EMPTY='{}'

sub() { sed -e "s|\${MODEL}|$MODEL|g" -e "s|\${effort}|$effort|g" -e "s|\${ticket}|$id|g" -e "s|\${seat}|$role|g" \
            -e "s|\${name}|$name|g" -e "s|\${state_dir}|$sd|g" -e "s|\${worktree}|$wt|g" -e "s|\${repo}|$SL_REPO|g"; }
# test_pane: the pane whose label starts with "test - herdr" in the tab this script was started from (HERDR_TAB_ID, which
# every herdr pane carries; the architect tab). Prints its id, or nothing. WO-20261010-8fa8: a worker runs commands only in
# its test pane, through herdr/bin/testpane.sh, and reads its id in the brief. Since WO-20261011-f896 this is the FALLBACK,
# used only for a layout with no slot of kind test; the seat's own pane is the normal case (breadcrumb below).
test_pane() {
  [ -n "${HERDR_TAB_ID:-}" ] || return 0
  sl_h pane list ${HERDR_WORKSPACE_ID:+--workspace "$HERDR_WORKSPACE_ID"} 2>/dev/null \
    | jq -r --arg t "$HERDR_TAB_ID" 'first((.result.panes // [])[] | select(.tab_id == $t and ((.label // "") | startswith("test - herdr"))) | .pane_id) // empty'
}
# BREADCRUMB 2026-10-11 - WO-20261011-f896, the test pane per seat. What broke: test_pane() above resolved ONE pane, the
#   "test - herdr" pane of the architect tab, and seat.sh exported it to every seat, so every seat's `make` ran through the
#   same shell: at 19:25 UTC five workers were live, three reported their step queued behind another seat's run, and at the
#   owner's 16-agent budget (18:52 UTC "speed and efficiency always") the whole line serialises on it. Why this fix: the
#   layout carries a slot of kind test (herdr/layouts/seat-1x2.json), seat.sh builds it in the seat's own tab like the
#   monitor pane and exports ITS id as COQ_TEST_PANE, so N seats hold N panes and testpane.sh's one comparison (unchanged)
#   refuses every pane but your own. The slot's command is `cd ${repo}`, so the pane shell parks in the main checkout and
#   `treehouse return --force` on --down can never end it (WO-20261011-36d7); the tab close takes the pane with the tab.
#   The architect-tab pane is the fallback only for a layout with no test slot (player-1x3, interface-2x2). The slot is
#   split down from the monitor pane (layout `split`), not placed by the rows x columns grid: a 1x3 grid gives the agent a
#   third of the tab, and the ticket wants it to keep at least half. Rejected: a seat-1x3 layout (the role files that name
#   seat-1x2 are the architect's, so nothing would use it) and one shared pane with a queue (it is the bottleneck itself).
#   Cost: one more idle shell per seat; the layout is still called seat-1x2 though its tab holds three panes, until the
#   architect renames it in roles/; `grid` counts grid slots only. Record: WO-20261011-f896.
slot_count() { jq '.panes|length' "$layout_file"; }
grid_count() { jq '[.panes[] | select(has("split") | not)] | length' "$layout_file"; }
slot_field() { jq -r --argjson i "$1" --arg f "$2" '.panes[$i][$f]' "$layout_file" | sub; }
slot_split() { jq -r --argjson i "$1" --arg f "$2" '.panes[$i].split[$f]' "$layout_file"; }
slot_index() { jq -r --arg s "$1" '[.panes[].slot] | index($s) // empty' "$layout_file"; }
want_labels() { local i n; n="$(slot_count)"; for ((i = 0; i < n; i++)); do slot_field "$i" label; done; }

# BREADCRUMB 2026-10-11 - WO-20261011-4c5e. What broke: roles/worker.json allow.paths spells the seat's worktree
#   "${worktree}/" but the gsub below only knew "${repo}", so the rendered allow rule came out as
#   Edit(//<slot>/${worktree}/**) (found in worker-wo-20261011-4c5e's settings.json; the a429 worker saw it first). It stayed
#   harmless only because a seat runs under bypassPermissions, where an allow rule restricts nothing. The deny side was never
#   broken: roles/worker.json spells it "${repo}/specs/" and that token was substituted with the seat's worktree already.
#   Why this fix: both tokens substitute to the seat's worktree. "${worktree}" is the canonical spelling because it says what
#   the path is; "${repo}" reads as the main checkout, which is the misreading the a429 report made, and it stays as an alias
#   because roles/{architect,interface-agent,monitor,orchestrator,worker}.json still use it. Rejected: rewriting those role
#   files in this change (a worker's fence denies roles/, and the architect owns that migration) and accepting only
#   "${worktree}" (it would leave the architect, monitor and deny paths with a literal token). Cost: two spellings render the
#   same until the role files and roles/schema move to "${worktree}" alone. Case 01 asserts no "${" survives. Record: WO-20261011-4c5e.
# render_settings: the role's allow and deny as Claude Code permission rules, deterministic so --check and --audit can
# cmp it with the file on disk. ${worktree} (alias ${repo}) in a path is the seat's worktree, a relative path is under it, a
# trailing slash means the whole directory. allow.paths and deny.paths become Edit rules (Edit covers Write), so bare Write and Edit
# are dropped from allow.tools: a bare Edit would allow every path, which is what the role's paths exist to narrow.
# A command holding a * renders as Bash(<cmd>) and Bash(<cmd> *) (bearings-v2 F-23: Claude Code never matches a :*
# rule with a * mid-pattern); a plain command keeps the Bash(<cmd>:*) prefix form.
render_settings() {
  jq --arg wt "$wt" '
    def ab: gsub("\\$\\{(worktree|repo)\\}"; $wt) | if startswith("/") then . else $wt + "/" + . end;
    def cmd: if contains("*") then "Bash(\(.))", "Bash(\(.) *)" else "Bash(\(.):*)" end;
    def rule($t): ab as $a | "\($t)(/\($a)\(if ($a | endswith("/")) then "**" else "" end))";
    ((.allow.tools // []) | map(select(. != "Write" and . != "Edit"))) as $bare
    | (((.allow.tools // []) | any(. == "Write" or . == "Edit"))) as $edits
    | {permissions: {defaultMode: .permission_mode,
        allow: ($bare + (if $edits then [(.allow.paths // [])[] | rule("Edit")] else [] end) + [(.allow.commands // [])[] | cmd]),
        deny: ((.deny.tools // []) + [(.deny.commands // [])[] | cmd] + [(.deny.paths // [])[] | rule("Edit")])}}' "$role_file"
}

load_seat() {
  seat_file="$(sl_seat_record "$1")"
  [ -f "$seat_file" ] || refuse "no seat named $1 under $STATE/seats"
  sd="$(dirname "$seat_file")"
  name="$(jq -r .name "$seat_file")"; id="$(jq -r '.ticket // empty' "$seat_file")"; role="$(jq -r .role "$seat_file")"
  role_file="$(jq -r .role_file "$seat_file")"; runtime="$(jq -r .runtime "$seat_file")"
  MODEL="$(jq -r .model "$seat_file")"; effort="$(jq -r .effort "$seat_file")"; wt="$(jq -r .worktree "$seat_file")"
  layout_file="$(jq -r .layout_file "$seat_file")"; ws="$(jq -r .workspace "$seat_file")"; tab="$(jq -r .tab "$seat_file")"
  settings="$(jq -r .settings "$seat_file")"; HS="$(jq -r .session "$seat_file")"; agent_pane="$(jq -r '.pane // empty' "$seat_file")"
  ended_at="$(jq -r '.ended_at // empty' "$seat_file")"
  lease_holder="$(jq -r '.lease.holder // empty' "$seat_file")"; lease_owned="$(jq -r '.lease.owned // false' "$seat_file")"
  adopted="$(jq -r '.adopted // false' "$seat_file")"
}
# agent_label: the label the layout gives its agent slot, with this seat's tokens filled in. An adopted seat owns that one pane.
agent_label() {
  local i n; n="$(slot_count)"
  for ((i = 0; i < n; i++)); do [ "$(slot_field "$i" kind)" = agent ] && { slot_field "$i" label; return 0; }; done
  return 1
}
# pane_row P: the pane list entry for pane P as one JSON object, empty when the pane is gone.
pane_row() { sl_h pane list 2>/dev/null | jq -c --arg p "$1" 'first((.result.panes // [])[] | select(.pane_id == $p)) // empty'; }
tab_live() { sl_h tab list --workspace "$ws" 2>/dev/null | jq -e --arg t "$tab" '[(.result.tabs // [])[] | select(.tab_id == $t)] | length > 0' >/dev/null 2>&1; }

# BREADCRUMB 2026-10-11 - WO-20261010-a429, the treehouse lease. What broke: AGENTS.md (Where your workspace comes from) allows
#   one source of worktrees, the treehouse pool, but this script took --worktree and defaulted to the main checkout, so the
#   architect hand-rolled /home/luna/worktrees/<ticket> for WO-20261010-c274 and WO-20261010-8fa8, and playbooks/worker.md
#   step 1 named slot.sh, which never existed, so the 8fa8 worker sat at step 1 from 21:47 to 22:2x UTC until the architect
#   answered by hand. Why this fix: a ticket seat with no --worktree leases its slot here, with the ticket id as the lease
#   holder (`treehouse get --lease --lease-holder <ticket> --no-fetch --json`), so `treehouse status` is keyed by ticket as
#   AGENTS.md says and the worker finds its lease with a read, never an acquire: the slot is the seat's, not the agent's.
#   The path and lease id are read back from `treehouse status --json` (a shape seen live: name, path, lease_id,
#   lease_holder), not from get's own output, whose keys this script never had to guess. seat.json carries
#   lease {holder, id, owned}, null for --worktree (AC-H4): --down and --check need to know whether this seat leased the
#   slot, and a plain directory must never reach `treehouse return`. A ticket that already holds a lease (hydration-prompt
#   leased it for the architect) is reused with owned false, so --down never returns a workbench another process leased.
#   Rejected: the worker running `treehouse get` itself (two parties leasing one slot, and the 8fa8 stall again if it
#   fails), the hydration-prompt lease path (an interactive skill, not a command a seat can call), and returning every
#   lease the ticket holds on --down (it would wipe the architect's workbench). Cost: `treehouse return --force` resets
#   the slot and ends every process in it, so --down runs it after retire.sh and the tab close, and anything the worker
#   left uncommitted in the slot is gone; a lease that will not come back keeps the seat un-ended so a rerun retries.
# th_row HOLDER [PATH]: the newest lease row held by HOLDER (at PATH), empty when none; status 1 when treehouse status failed.
th_row() {
  local st; st="$(treehouse status --json 2>/dev/null)" || return 1
  jq -c --arg h "$1" --arg p "${2:-}" '[.[]? | select(.lease_holder == $h and ($p == "" or .path == $p))] | sort_by(.leased_at) | last // empty' <<<"$st"
}
# lease_abandon: the EXIT trap of a run that leased a slot and died before seat.json recorded it, so a refused or failed
# bring-up leaves no lease behind.
lease_abandon() {
  # lease_new goes to 0 once the slot is back: lease_up calls this before refusing and the EXIT trap calls it again, and
  # the second `treehouse return` (found by case 08 on WO-20261011-c077, which counts calls) failed on a slot already gone.
  if [ "$lease_new" = 1 ] && [ "$recorded" != 1 ]; then treehouse return "$wt" --if-lease-holder "$id" --force >/dev/null 2>&1 || true; lease_new=0; fi
}
# slot_to_branch: put the leased slot on the ticket's branch (BREADCRUMB 2026-10-11 above, the ticket's branch). A fresh slot
# is detached at origin/main. git fetch origin first, then the local branch when the repository has it (a slot is a linked
# worktree of the main checkout, so it shares that checkout's branches), else a new local branch tracking origin/<branch>.
# A local branch that has no upstream while origin has the branch is pointed at it, so the worker's push goes to origin.
# Prints the reason and returns 1 when the slot cannot be put there. Under DRY_RUN it prints the two git calls and runs none.
slot_to_branch() {
  local g=(git -C "$wt") out
  if [ "$DRY" = 1 ]; then sl_run "${g[@]}" fetch origin; sl_run "${g[@]}" checkout "$branch"; return 0; fi
  out="$("${g[@]}" fetch --quiet origin 2>&1)" || { echo "git fetch origin failed in $wt: $out"; return 1; }
  if "${g[@]}" show-ref --verify --quiet "refs/heads/$branch"; then out="$("${g[@]}" checkout --quiet "$branch" 2>&1)"
  elif "${g[@]}" show-ref --verify --quiet "refs/remotes/origin/$branch"; then out="$("${g[@]}" checkout --quiet -b "$branch" --track "origin/$branch" 2>&1)"
  else echo "branch $branch is on neither the repository nor origin"; return 1; fi \
    || { echo "git checkout $branch failed in $wt: $out"; return 1; }
  if ! "${g[@]}" rev-parse --abbrev-ref --symbolic-full-name "$branch@{upstream}" >/dev/null 2>&1 \
    && "${g[@]}" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    "${g[@]}" branch --quiet --set-upstream-to="origin/$branch" "$branch" >/dev/null 2>&1 || true
  fi
}
# lease_up: sets wt, lease and lease_new for door 1 without --worktree, then puts the slot on the ticket's branch.
lease_up() {
  local row owned=true
  command -v treehouse >/dev/null 2>&1 || refuse "treehouse is not on PATH; a ticket seat without --worktree leases its slot from the pool"
  row="$(th_row "$id")" || refuse "treehouse status failed; cannot tell whether $id already holds a lease"
  if [ -n "$row" ]; then
    owned=false
    if [ -f "$seat_file" ] && [ -z "$(jq -r '.ended_at // empty' "$seat_file")" ]; then owned="$(jq -r '.lease.owned // false' "$seat_file")"; fi
    sl_log "seat $name: ticket $id already holds a treehouse lease, using it"
  else
    sl_run treehouse get --lease --lease-holder "$id" --no-fetch --json >/dev/null || refuse "no treehouse slot for $id: treehouse get --lease failed"
    row="$(th_row "$id")" || refuse "treehouse status failed after leasing a slot for $id"
    if [ -z "$row" ]; then
      [ "$DRY" = 1 ] || refuse "treehouse get --lease succeeded but treehouse status lists no lease held by $id"
      wt="/dry-run/treehouse-slot"; lease="$(jq -nc --arg h "$id" '{holder:$h,id:"dry-run",owned:true}')"; slot_to_branch; return 0
    fi
    lease_new=1; trap lease_abandon EXIT
  fi
  wt="$(jq -r .path <<<"$row")"; [ -d "$wt" ] || { lease_abandon; refuse "treehouse leased $wt to $id but it is not a directory"; }
  # A fresh lease that cannot reach the branch is given back by the EXIT trap; a lease the ticket already held is left alone.
  why="$(slot_to_branch)" || { lease_abandon; refuse "slot $wt could not be put on $branch for $id: $why"; }
  lease="$(jq -nc --arg h "$id" --arg i "$(jq -r .lease_id <<<"$row")" --argjson o "$owned" '{holder:$h,id:$i,owned:$o}')"
}
# BREADCRUMB 2026-10-11 - WO-20261011-36d7, the pane `treehouse return --force` killed twice. What broke: lease_down below ran
#   `treehouse return --force`, which ends every process whose cwd is in the slot, without looking at what those were; during
#   the PR 6 review it ended the zsh of the architect's test pane (wD3:pF, then wD3:p1R) and herdr closed the pane, so the
#   architect tab lost its "test - herdr" pane and the next ticket seat would have been refused. Why this fix: before the
#   return, the processes `treehouse status --json` lists for the slot are written to the log, one line each with pid and name,
#   and `--force` is refused (exit 3, the seat stays un-ended) when any live one is not this seat's own, so the architect sees
#   the list and decides; moving the shell out of the slot or ending the process and rerunning --down is the decision. "Own"
#   is every pane shell of the seat's tab plus everything under those shells, read from `herdr pane process-info` BEFORE
#   retire.sh and the tab close, because afterwards the tree is gone; this run's own children (the treehouse status call)
#   are never foreign, and a pid that has already exited by the time it is read is not listed (the status call lists itself).
#   Rejected: an override flag that forces past a foreign process (no caller needs it: the refusal names what to move, and a
#   flag is what the next hurried run would reach for) and killing the foreign process here (it is somebody's shell). Cost:
#   treehouse lists by cwd, so a process holding the slot only through a bind mount or an open file is not listed and the
#   return can still end it; the ticket's second kill looked like that, with nothing listed. This guards the listed case only.
# pid_tree PID: PID and every process under it, one pid per line (empty when ps is unavailable).
pid_tree() {
  ps -e -o pid= -o ppid= 2>/dev/null | awk -v r="$1" 'BEGIN { keep[r] = 1 } { p[NR] = $1; q[NR] = $2 }
    END { do { ch = 0; for (i = 1; i <= NR; i++) if (!(p[i] in keep) && (q[i] in keep)) { keep[p[i]] = 1; ch = 1 } } while (ch); for (k in keep) print k }'
}
# pid_live PID: true while PID exists and is not a zombie.
pid_live() { local st; st="$(ps -o stat= -p "$1" 2>/dev/null)" || return 1; case "$st" in "" | Z*) return 1 ;; esac; }
# seat_pids: the pane shells of this seat's tab and everything under them, space separated. Taken before the panes are closed.
seat_pids() {
  local p sp out=""
  [ "$DRY" != 1 ] || return 0
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    sp="$(sl_h pane process-info --pane "$p" 2>/dev/null | jq -r '.result.process_info.shell_pid // empty' 2>/dev/null)" || sp=""
    [ -z "$sp" ] || out="$out $(pid_tree "$sp" | tr '\n' ' ')"
  done < <(sl_panes_of_tab "$ws" "$tab" | jq -r '.[].pane_id')
  printf '%s' "$out"
}
# lease_down: give back the slot this seat leased. A slot treehouse no longer lists for the holder counts as returned.
# Returns 0 when the slot is back, 1 when treehouse failed, 2 when a live process that is not this seat's is still in the slot.
lease_down() {
  local row pr pid nm kind foreign=0 mine; row="$(th_row "$lease_holder" "$wt")" || return 1
  [ -n "$row" ] || { sl_log "seat $name: $wt is no longer leased to $lease_holder, nothing to return"; return 0; }
  if [ "$DRY" != 1 ]; then
    mine=" $(pid_tree $$ | tr '\n' ' ') "
    while IFS= read -r pr; do
      [ -n "$pr" ] || continue
      pid="$(jq -r .pid <<<"$pr")"; nm="$(jq -r .name <<<"$pr")"
      pid_live "$pid" || continue
      case " $seat_own $mine" in *" $pid "*) kind="this seat's own" ;; *) kind="FOREIGN"; foreign=1 ;; esac
      sl_log "seat $name: slot $wt holds process $pid $nm ($kind); treehouse return --force ends it"
    done < <(jq -c '(.processes // [])[]' <<<"$row")
    if [ "$foreign" = 1 ]; then
      sl_log "seat $name: refusing treehouse return --force on $wt while a foreign process is in it; move that shell out of the slot or end it, then rerun --down"
      return 2
    fi
  fi
  sl_run treehouse return "$wt" --if-lease-holder "$lease_holder" --force
}

# ---- --check ----
if [ "$mode" = check ]; then
  load_seat "$name_arg"; diffs=0
  say() { echo "$name: $*"; diffs=$((diffs + 1)); }
  if [ -n "$ended_at" ]; then echo "$name: down since $ended_at"; exit 3; fi
  [ -f "$layout_file" ] || say "layout missing: $layout_file"
  if ! tab_live; then say "tab $tab is gone from workspace $ws"
  elif [ "$adopted" = true ]; then
    # An adopted seat owns the one pane it was adopted in; the layout's other panes were never built (WO-20261011-8fb3).
    want="$(agent_label)"; prow="$(pane_row "$agent_pane")"
    if [ -z "$prow" ]; then say "pane gone: $agent_pane"
    elif [ "$(jq -r '.label // ""' <<<"$prow")" != "$want" ]; then say "pane $agent_pane label is '$(jq -r '.label // ""' <<<"$prow")', want '$want'"; fi
  elif [ -f "$layout_file" ]; then
    live="$(sl_panes_of_tab "$ws" "$tab")"
    while IFS= read -r want; do jq -e --arg l "$want" 'any(.[]; .label == $l)' <<<"$live" >/dev/null || say "pane missing: $want"; done < <(want_labels)
    want="$(want_labels | jq -Rn '[inputs]')"
    while IFS= read -r l; do jq -e --arg l "$l" 'index($l) != null' <<<"$want" >/dev/null || say "pane unexpected: $l"; done < <(jq -r '.[].label' <<<"$live")
  fi
  sl_agent_live "$name" || say "agent not running"
  if [ "$adopted" = true ] && sl_agent_live "$name" \
    && [ "$(sl_h agent get "$name" 2>/dev/null | jq -r '.result.agent.pane_id // empty')" != "$agent_pane" ]; then say "agent $name is no longer in pane $agent_pane"; fi
  if [ ! -f "$role_file" ]; then say "role file missing: $role_file"
  elif [ ! -f "$settings" ]; then say "settings missing: $settings"
  elif ! render_settings | cmp -s - "$settings"; then say "settings drifted from $role_file: $settings"; fi
  if [ -n "$lease_holder" ]; then
    if ! row="$(th_row "$lease_holder" "$wt")"; then say "treehouse status failed; the lease on $wt is unchecked"
    elif [ -z "$row" ]; then say "lease missing: treehouse status lists no lease held by $lease_holder at $wt"; fi
  fi
  [ "$diffs" = 0 ]; exit $?
fi

# ---- --down ----
if [ "$mode" = down ]; then
  load_seat "$name_arg"
  if [ -n "$ended_at" ]; then echo "$name: already down since $ended_at"; exit 0; fi
  if [ "$adopted" = true ]; then
    # BREADCRUMB 2026-10-11 - WO-20261011-8fb3. What broke (would break): the sequence below is retire.sh (/exit), tab close and
    #   `treehouse return --force`, all of which end the agent, and an adopted seat is the owner's own live session in a pane
    #   seat.sh did not build: running it would kill the architect session the adoption exists to keep. Why this fix: --down of
    #   an adopted seat only undoes what --adopt did, the herdr agent name and the pane label go back to what adopt read, the
    #   record is retired and seat.down 100 is written; the agent, the pane and its tab are never touched. Rejected: a --force
    #   path that kills an adopted agent (retire.sh on its own already does that for anyone who wants it) and leaving the label
    #   and name on the pane (a downed seat would keep claiming a name that the next adopt then refuses as taken). Cost: the
    #   agent keeps running with the role's name gone, so it is unmanaged again until the next --adopt.
    prior_label="$(jq -r '.prior.label // empty' "$seat_file")"; prior_name="$(jq -r '.prior.agent_name // empty' "$seat_file")"
    if [ -n "$prior_name" ]; then sl_mut agent rename "$agent_pane" "$prior_name" >/dev/null 2>&1 || true
    else sl_mut agent rename "$agent_pane" --clear >/dev/null 2>&1 || true; fi
    if [ -n "$prior_label" ]; then sl_mut pane rename "$agent_pane" "$prior_label" >/dev/null 2>&1 || true
    else sl_mut pane rename "$agent_pane" --clear >/dev/null 2>&1 || true; fi
    sl_record seat.down 100 "$name" ${id:+--ticket "$id"} --pane "$agent_pane" --note "adopted seat retired in place; the agent keeps running in $agent_pane"
    [ "$DRY" = 1 ] || { jq --arg at "$(sl_now)" '.ended_at=$at' "$seat_file" > "$seat_file.tmp" && mv "$seat_file.tmp" "$seat_file"; }
    jq -nc --arg name "$name" '{name:$name,down:true,adopted:true}'; exit 0
  fi
  [ "$lease_owned" != true ] || sl_require treehouse
  seat_own=""; [ "$lease_owned" != true ] || seat_own="$(seat_pids)"
  "$SL_HERE/retire.sh" "$name" --pane "$agent_pane" || sl_log "seat $name: retire did not finish cleanly; closing the tab anyway"
  sl_run sleep "$(sl_cfg .down_wait_seconds)"
  sl_mut tab close "$tab" >/dev/null 2>&1 || true
  if [ "$lease_owned" = true ]; then
    lease_down && rc=0 || rc=$?
    case "$rc" in
      0) ;;
      2) SL_EXIT=3 sl_die "seat $name: slot $wt still holds a foreign process (listed above); the seat stays un-ended, rerun --down once it is out of the slot" ;;
      *) SL_EXIT=4 sl_die "seat $name: slot $wt would not come back to the pool; the seat stays un-ended, rerun --down once treehouse return works" ;;
    esac
  fi
  sl_record seat.down 100 "$name" ${id:+--ticket "$id"} --pane "$agent_pane" --note "seat retired"
  [ "$DRY" = 1 ] || { jq --arg at "$(sl_now)" '.ended_at=$at' "$seat_file" > "$seat_file.tmp" && mv "$seat_file.tmp" "$seat_file"; }
  jq -nc --arg name "$name" '{name:$name,down:true}'; exit 0
fi

# ---- --audit ----
# BREADCRUMB 2026-10-10 - AC-H2: a hand-started agent is recorded 500. Reads /proc (SEAT_PROC is a fixture in tests) and
#   the seat records only, no herdr call, so it runs anywhere. A process is an agent when its argv names claude or codex
#   directly or through an interpreter (the test stub is `bash .../claude`). It is compliant when COQ_SEAT names a live
#   record and its flags are the record's; otherwise the reason is printed and seat.stalled 500 recorded, unless
#   herdr/config/exemptions.json lifts seat.audit for that pane or seat.
if [ "$mode" = audit ]; then
  proc="${SEAT_PROC:-/proc}"; bad=0; n=0
  for d in "$proc"/[0-9]*; do
    [ -r "$d/cmdline" ] || continue
    pid="${d##*/}"; mapfile -d '' -t argv < "$d/cmdline" || true
    [ "${#argv[@]}" -gt 0 ] || continue
    a0="${argv[0]##*/}"; a1="${argv[1]:-}"; a1="${a1##*/}"
    case "$a0" in claude|codex) bin="$a0"; flags=("${argv[@]:1}") ;;
      bash|sh|node) case "$a1" in claude|codex) bin="$a1"; flags=("${argv[@]:2}") ;; *) continue ;; esac ;;
      *) continue ;; esac
    case "${flags[0]:-}" in bg-*) continue ;; esac
    n=$((n + 1))
    envof() { tr '\0' '\n' < "$d/environ" 2>/dev/null | sed -n "s/^$1=//p" | head -1; }
    pane="$(envof HERDR_PANE_ID)"; seatn="$(envof COQ_SEAT)"; rec=""
    [ -z "$seatn" ] || { rec="$(sl_seat_record "$seatn")"; [ -f "$rec" ] && [ -z "$(jq -r '.ended_at // empty' "$rec")" ] || rec=""; }
    why=""
    # An adopted agent was started by hand before seat.sh knew it, so its environment has no COQ_SEAT and its flags are whatever the
    # owner typed; it is matched by the pane herdr gave it instead, and only the role's settings at the next restart bind it.
    adopted_seat=""
    if [ -z "$rec" ] && [ -n "$pane" ]; then
      for ar in "$STATE"/seats/*/seat.json; do
        [ -f "$ar" ] || continue
        jq -e --arg p "$pane" '(.adopted // false) == true and .ended_at == null and .pane == $p' "$ar" >/dev/null 2>&1 && { adopted_seat="$(jq -r .name "$ar")"; break; }
      done
    fi
    if [ -n "$adopted_seat" ]; then echo "COMPLIANT ${pane:--} $adopted_seat pid $pid (adopted: mode and settings apply at the next restart)"; continue
    elif [ -z "$rec" ]; then why="hand-started: no live seat record (COQ_SEAT=${seatn:-unset})"
    else
      rf="$(jq -r .role_file "$rec")"; want_mode="$(jq -r .permission_mode "$rf" 2>/dev/null || echo "?")"
      want_set="$(jq -r .settings "$rec")"; want_model="$(jq -r .model "$rec")"; pm=""; st=""; md=""; i=0
      while [ "$i" -lt "${#flags[@]}" ]; do
        case "${flags[i]}" in
          --permission-mode) pm="${flags[i + 1]:-}"; i=$((i + 1)) ;; --permission-mode=*) pm="${flags[i]#*=}" ;;
          --settings) st="${flags[i + 1]:-}"; i=$((i + 1)) ;; --settings=*) st="${flags[i]#*=}" ;;
          --model|-m) md="${flags[i + 1]:-}"; i=$((i + 1)) ;; --model=*) md="${flags[i]#*=}" ;;
        esac; i=$((i + 1))
      done
      if [ "$bin" = claude ]; then
        if [ "$pm" != "$want_mode" ]; then why="permission mode $pm, role says $want_mode"
        elif [ "$st" != "$want_set" ]; then why="settings $st, seat.sh rendered $want_set"
        elif [ ! -f "$want_set" ] || ! (role_file="$rf"; wt="$(jq -r .worktree "$rec")"; render_settings) | cmp -s - "$want_set"; then why="settings drifted from $rf"
        elif [ "$md" != "$want_model" ]; then why="model $md, seat record says $want_model"; fi
      elif [ "$md" != "$want_model" ]; then why="model $md, seat record says $want_model"; fi
    fi
    if [ -z "$why" ]; then echo "COMPLIANT ${pane:--} $seatn pid $pid"
    elif sl_exempt seat.audit "$seatn" "$pane"; then echo "EXEMPT ${pane:--} ${seatn:-$bin} pid $pid: $why"
    else
      echo "OUT OF COMPLIANCE ${pane:--} ${seatn:-$bin} pid $pid: $why"; bad=1
      sl_record seat.stalled 500 "${seatn:-hand-$bin-$pid}" ${pane:+--pane "$pane"} --note "audit: $why"
    fi
  done
  echo "audited: $n agent processes"
  exit "$bad"
fi

# ---- doors ----
[ -n "$role" ] || usage
if [ -n "$ticket" ]; then [ -z "$task" ] || sl_die "--ticket and --task are different doors"; id="$ticket"
else [ -n "$task" ] || [ "$mode" = adopt ] || usage; id=""; fi
role_file="$(sl_role_file "$role")"
# Door 1 needs a ticket file to brief from; refused before anything is built rather than after the agent is up.
branch=""
if [ -n "$ticket" ] && [ "$mode" != adopt ]; then
  ticket_file="$(find "$SL_REPO/work-orders" -name "$ticket-*.md" -not -path '*/archive/*' 2>/dev/null | head -1)"
  [ -n "$ticket_file" ] || refuse "no ticket $ticket under work-orders/ (archived or never cut)"
  # BREADCRUMB 2026-10-11 - WO-20261011-c077, the ticket's branch. What broke: a slot leased below comes up detached at
  #   origin/main while `work-order start` made feat/<slug> in the main checkout, and the worker role may run git add,
  #   commit and push only, so the architect ran `git checkout` in the slot by hand before seating WO-20261010-2d04, and
  #   that hand step left the lease owned false (so --down would not return it). Why this fix: the branch is read from
  #   the ticket frontmatter (`branch`, stamped by work-order start) here, with the other refusals, so a ticket not yet
  #   started is refused before any lease or herdr call (AC-H2); lease_up then checks the slot out onto it. Only a seat
  #   that leases its own slot is touched: --worktree names a directory the caller already prepared and stays as given.
  #   Rejected: the worker running git checkout (the role denies it by design, and the 2d04 stall again if it is
  #   forgotten) and falling back to a detached slot when the branch is null (the worker would commit on no branch).
  #   Cost: a door 1 seat without --worktree now needs the ticket started first; `work-order start` is the step before
  #   seating anyway.
  if [ "$wt_given" = 0 ]; then
    branch="$(awk '/^---$/{c++; next} c==1' "$ticket_file" | jq -r '.branch // empty' 2>/dev/null)" || branch=""
    [ -n "$branch" ] || refuse "ticket $ticket has no branch yet (frontmatter branch is null); run work-order start first, nothing leased"
    git check-ref-format "refs/heads/$branch" || refuse "ticket $ticket names branch '$branch', which is not a valid branch name; nothing leased"
  fi
fi
rname="$(jq -r .name "$role_file")"; [ "$rname" = "$role" ] || refuse "role file $role_file names $rname, not $role"
runtime="${runtime_arg:-$(jq -r .runtime.default "$role_file")}"
jq -e --arg r "$runtime" '.runtime.allowed | index($r) != null' "$role_file" >/dev/null || refuse "role $role does not allow runtime $runtime"
[ -z "$resume_id" ] || [ "$runtime" = claude ] || refuse "--resume restarts a claude session; runtime $runtime has none"
[ -z "$resume_id" ] || [[ "$resume_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || sl_die "--resume $resume_id is not a session id"
[ "$mode" != adopt ] || [ -z "$resume_id" ] || sl_die "--adopt takes the session of a live agent with --session; --resume starts a new one"
[ "$mode" != adopt ] || [ "$runtime" = claude ] || refuse "--adopt is for a claude session; runtime $runtime has no session id to keep"
MODEL="$(jq -r --arg r "$runtime" '.model[$r] // empty' "$role_file")"; [ -n "$MODEL" ] || refuse "role $role names no model for $runtime"
effort="$(jq -r .effort "$role_file")"; pmode="$(jq -r .permission_mode "$role_file")"; layout_id="$(jq -r .pane_layout "$role_file")"
max_seats="$(jq -r .max_seats "$role_file")"; label="$(jq -r .label "$role_file")"
layout_file="$SL_HERDR/layouts/$layout_id.json"; [ -f "$layout_file" ] || refuse "no layout $layout_file"
bin="$(sl_cfg ".runtime_bin.\"$runtime\"")"

# The name: door 1 fills ${ticket} in the role's label; door 2 uses a label with no token as is, else role-<slug>.
# herdr agent names are lowercase (invalid_agent_name on the first live run, 2026-10-10), so the ticket id is lowered: worker-wo-20261010-8777.
if [ -n "$ticket" ]; then name="${label//\$\{ticket\}/${ticket,,}}"
elif [[ "$label" != *'${'* ]]; then name="$label"
else [ "$mode" != adopt ] || refuse "role $role names its seat from a ticket (label $label); give --ticket"
  slug="$(tr 'A-Z' 'a-z' <<<"$task" | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')"; name="$role-$slug"; fi
name="${name,,}"
if [ "${#name}" -gt 32 ] && [ -z "$ticket" ]; then h="$(printf %s "$name" | sha256sum | cut -c1-4)"; name="$(cut -c1-27 <<<"$name" | sed 's/-$//')-$h"; fi
[ "${#name}" -le 32 ] && [[ "$name" =~ ^[a-z][a-z0-9_-]*$ ]] || refuse "seat name $name is ${#name} characters; herdr agent names are 1 to 32 of a-z 0-9 _ - starting with a letter"
sd="$(sl_seat_dir "$name")"; settings="$sd/settings.json"; seat_file="$sd/seat.json"

# Gates, all before any herdr call: the guard, the bring-up order, the role cap, the system cap.
if [ "$(sl_cfg .require_guard)" = true ] && [ "$runtime" = claude ] && ! command -v compaction-guard >/dev/null 2>&1; then
  refuse "compaction-guard is not on PATH; a seat never starts without the guard (RSK-compaction-sensor)"
fi
monitor_seat="$(sl_cfg .monitor_seat)"
if [ "$(sl_cfg .bringup_gate)" = true ] && [ "$name" != "$monitor_seat" ] && [ "$DRY" != 1 ] && ! sl_exempt bringup.gate "$name" ""; then
  mrec="$(sl_seat_record "$monitor_seat")"
  { [ -f "$mrec" ] && [ -z "$(jq -r '.ended_at // empty' "$mrec")" ] && sl_agent_live "$monitor_seat"; } \
    || refuse "bring-up order: monitor seat $monitor_seat is down; run herdr/bin/bringup.sh first (DEC-system-before-agents)"
fi
if [ "$DRY" != 1 ] && ! sl_agent_live "$name"; then
  live_role="$(sl_live_seats "$role" | wc -l | tr -d ' ')"
  if [ "$live_role" -ge "$max_seats" ]; then
    sl_record note 429 "$name" ${id:+--ticket "$id"} --note "seat refused: $live_role $role seats live, role max_seats $max_seats"
    refuse "seat $name refused: $live_role $role seats already live (max_seats $max_seats); the queue holds the ticket"
  fi
  live_all="$(sl_live_seats | wc -l | tr -d ' ')"; max_all="$(sl_cfg .max_agents)"
  if [ "$live_all" -ge "$max_all" ]; then
    sl_record note 429 "$name" ${id:+--ticket "$id"} --note "seat refused: $live_all agents live, max_agents $max_all"
    refuse "seat $name refused: $live_all agents already live (max_agents $max_all); nothing built"
  fi
fi

# ---- --adopt ----
# BREADCRUMB 2026-10-11 - WO-20261011-8fb3, DEC-architect-becomes-interface-agent. What broke (would break): the owner ordered the
#   architect session to become the interface agent with everything the day put in its context, and every door above ends in
#   `herdr agent start`, a fresh claude with none of it; the only way to "become a seat" was to lose the session. Why this fix:
#   --adopt does the bookkeeping of a seat-up and none of the starting. It reads the agent herdr already runs in --pane,
#   names it for the role (`herdr agent rename`, which is what makes --check, --down and the monitor's wakes find it), labels
#   the pane with the layout's agent slot, writes the role's settings.json and a seat.json marked adopted with the session id and
#   what the pane was called before, and records seat.up 100. Nothing is typed into the pane, so the session, its context and
#   its permission mode are untouched; the owner changes mode and model in the pane (the ticket's non-goal), and the settings
#   file takes effect at the next start of this seat. --session is checked against the session herdr reports for the pane when
#   it reports one, because a wrong id would make that next start resume somebody else's conversation. Rejected: a second
#   script (two writers for seat.json) and `agent start` on the running pane (it types into the live TUI). Cost: the agent's
#   environment has no COQ_SEAT, COQ_ROLE or COQ_EVENTS_ROOT (a process cannot be given them from outside), so it posts records
#   with its own --seat, and --audit matches it by pane instead of by environment; the other layout panes are not built.
if [ "$mode" = adopt ]; then
  [ -n "$adopt_pane" ] || sl_die "--adopt needs --pane"
  [ -n "$claude_sid" ] || sl_die "--adopt needs --session (the claude session id the live agent runs)"
  [[ "$claude_sid" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || sl_die "--session $claude_sid is not a session id"
  ag="$(sl_h agent list 2>/dev/null | jq -c --arg p "$adopt_pane" 'first((.result.agents // [])[] | select(.pane_id == $p)) // empty')"
  [ -n "$ag" ] || refuse "no agent runs in pane $adopt_pane; --adopt keeps a live session and starts nothing"
  [ "$(jq -r .agent <<<"$ag")" = claude ] || refuse "the agent in pane $adopt_pane is $(jq -r .agent <<<"$ag"), not claude"
  cur_name="$(jq -r '.name // empty' <<<"$ag")"
  [ -z "$cur_name" ] || [ "$cur_name" = "$name" ] || refuse "the agent in pane $adopt_pane is already named $cur_name; rename it first or adopt under that role"
  seen_sid="$(jq -r '.agent_session.value // empty' <<<"$ag")"
  [ -z "$seen_sid" ] || [ "$seen_sid" = "$claude_sid" ] || refuse "pane $adopt_pane runs session $seen_sid, not $claude_sid"
  if [ -z "$cur_name" ] && sl_agent_live "$name"; then refuse "seat name $name is taken by the agent in pane $(sl_h agent get "$name" | jq -r '.result.agent.pane_id // "?"')"; fi
  if [ -f "$seat_file" ] && [ -z "$(jq -r '.ended_at // empty' "$seat_file")" ] && [ "$(jq -r '.pane // empty' "$seat_file")" != "$adopt_pane" ] && sl_agent_live "$name"; then
    refuse "seat $name is live in pane $(jq -r .pane "$seat_file"); --down it first"
  fi
  prow="$(pane_row "$adopt_pane")"; [ -n "$prow" ] || refuse "pane $adopt_pane is not in herdr session $HS"
  ws="$(jq -r .workspace_id <<<"$prow")"; tab="$(jq -r .tab_id <<<"$prow")"
  # A rerun keeps what the first adopt read, or --down would "restore" the role's own label.
  prior_label="$(jq -r '.label // ""' <<<"$prow")"; prior_name="$cur_name"; first=1
  if [ -f "$seat_file" ] && [ "$(jq -r '.adopted // false' "$seat_file")" = true ] && [ -z "$(jq -r '.ended_at // empty' "$seat_file")" ]; then
    prior_label="$(jq -r '.prior.label // ""' "$seat_file")"; prior_name="$(jq -r '.prior.agent_name // ""' "$seat_file")"; first=0
  fi
  layout_file="$SL_HERDR/layouts/$layout_id.json"; [ -f "$layout_file" ] || refuse "no layout $layout_file"
  a="$adopt_pane"; want_label="$(agent_label)" || refuse "layout $layout_id has no agent slot"
  [ "$cur_name" = "$name" ] || sl_mut agent rename "$adopt_pane" "$name" >/dev/null || SL_EXIT=4 sl_die "herdr agent rename $adopt_pane $name failed"
  [ "$(jq -r '.label // ""' <<<"$prow")" = "$want_label" ] || sl_mut pane rename "$adopt_pane" "$want_label" >/dev/null || SL_EXIT=4 sl_die "herdr pane rename $adopt_pane failed"
  if [ "$DRY" != 1 ]; then
    render_settings > "$settings.tmp" && mv "$settings.tmp" "$settings"
    jq -n --arg name "$name" --arg ticket "$id" --arg role "$role" --arg role_file "$role_file" --arg runtime "$runtime" --arg model "$MODEL" \
      --arg effort "$effort" --arg wt "$wt" --arg layout_file "$layout_file" --arg ws "$ws" --arg tab "$tab" --arg hs "$HS" \
      --arg settings "$settings" --arg pane "$a" --arg at "$(sl_now)" --arg sid "$claude_sid" --arg pl "$prior_label" --arg pn "$prior_name" \
      '{name:$name,ticket:$ticket,task:"",role:$role,role_file:$role_file,runtime:$runtime,model:$model,effort:$effort,worktree:$wt,
        lease:null,layout_file:$layout_file,workspace:$ws,tab:$tab,session:$hs,settings:$settings,pane:$pane,started_at:$at,ended_at:null,
        adopted:true,claude_session:$sid,prior:{label:$pl,agent_name:(if $pn == "" then null else $pn end)}}' > "$seat_file.tmp" \
      && mv "$seat_file.tmp" "$seat_file"
  fi
  [ "$first" = 0 ] || sl_record seat.up 100 "$name" ${id:+--ticket "$id"} --pane "$a" \
    --note "adopt: live claude session $claude_sid in $a becomes the $role seat; settings apply at the next restart"
  jq -nc --arg name "$name" --arg ticket "$id" --arg role "$role" --arg pane "$a" --arg sid "$claude_sid" --arg settings "$settings" --arg wt "$wt" \
    --argjson first "$first" '{name:$name,ticket:$ticket,role:$role,pane:$pane,claude_session:$sid,settings:$settings,worktree:$wt,adopted:true,started:false,new:($first==1)}'
  exit 0
fi

# A ticket seat needs a labelled test pane: it is how the worker proves its acceptance criteria, and the brief names it.
# A layout with a slot of kind test builds the seat's own (resolved after the panes exist, below); only a layout without one
# falls back to the 'test - herdr' pane of the architect tab, and a ticket seat is refused before any lease when that is
# missing too. Door 2 seats (monitor, merger, orchestrator) run no suite, so an absent pane is not a refusal there.
tpane=""
if [ "$(jq -r 'any(.panes[]; .kind == "test")' "$layout_file")" != true ]; then
  tpane="$(test_pane)"
  if [ -n "$ticket" ] && [ -z "$tpane" ]; then
    [ "$DRY" = 1 ] && tpane=dry-test-pane || refuse "no pane labelled 'test - herdr' in the tab this was started from (HERDR_TAB_ID=${HERDR_TAB_ID:-unset}); start seats from the architect tab"
  fi
fi

# Door 1 without --worktree: lease the ticket's slot now, after every refusal above so a refused seat leases nothing, and
# before the first herdr call that names a directory. --worktree leases nothing and returns nothing (AC-H4).
lease=null; lease_new=0; recorded=0
if [ -n "$ticket" ] && [ "$wt_given" = 0 ]; then lease_up; fi

# Workspace by label else create; tab by label else create. A fresh workspace's root tab is renamed and used.
sl_h workspace list >/dev/null 2>&1 || { [ "$DRY" = 1 ] || { SL_EXIT=4 sl_die "herdr session $HS is not running; bringup.sh starts it"; }; }
ws="$(sl_ws_id || true)"; tab=""
if [ -z "$ws" ]; then
  r="$(sl_mut workspace create --label "$WS_LABEL" --cwd "$wt" --no-focus)" || SL_EXIT=4 sl_die "workspace create failed"
  ws="$(jq -r '.result.workspace.workspace_id // empty' <<<"${r:-$EMPTY}")"; tab="$(jq -r '.result.tab.tab_id // empty' <<<"${r:-$EMPTY}")"
  [ -z "$tab" ] || sl_mut tab rename "$tab" "$name" >/dev/null
fi
[ "$DRY" = 1 ] && ws="${ws:-dry-workspace}"
[ -n "$ws" ] || SL_EXIT=4 sl_die "no workspace id for $WS_LABEL"
[ -n "$tab" ] || tab="$(sl_tab_id "$ws" "$name" || true)"
if [ -z "$tab" ]; then
  r="$(sl_mut tab create --workspace "$ws" --cwd "$wt" --label "$name" --no-focus)" || SL_EXIT=4 sl_die "tab create failed"
  tab="$(jq -r '.result.tab.tab_id // empty' <<<"${r:-$EMPTY}")"
fi
[ "$DRY" = 1 ] && tab="${tab:-dry-tab}"
[ -n "$tab" ] || SL_EXIT=4 sl_die "no tab id for $name"

# Slots to panes: a pane carrying a template label keeps its slot, any other pane fills a free slot and is relabelled
# (the repair), slots still empty are split per sl_grid_step. Fresh non-agent panes get their layout command.
n="$(slot_count)"; ngrid="$(grid_count)"; rows="$(jq -r '.grid | split("x")[0]' "$layout_file")"; cols="$(jq -r '.grid | split("x")[1]' "$layout_file")"
[ $((rows * cols)) = "$ngrid" ] || refuse "layout $layout_id: grid ${rows}x${cols} does not match its $ngrid grid panes"
# A slot with a split comes after every grid slot and splits from an earlier slot (WO-20261011-f896).
jq -e --argjson g "$ngrid" '.panes as $p | all(range(0; $g); ($p[.] | has("split") | not))
  and all(range($g; ($p | length)); . as $i | ($p[$i].split.from as $f | [$p[0:$i][].slot] | index($f) != null))' "$layout_file" >/dev/null \
  || refuse "layout $layout_id: a split slot must follow every grid slot and split from an earlier slot"
live="$([ "$DRY" = 1 ] && echo '[]' || sl_panes_of_tab "$ws" "$tab")"; [ -n "$live" ] || live='[]'
declare -a want pane fresh
for ((i = 0; i < n; i++)); do want[i]="$(slot_field "$i" label)"; pane[i]=""; fresh[i]=0; done
used=" "
for ((i = 0; i < n; i++)); do
  p="$(jq -r --arg l "${want[i]}" 'first(.[] | select(.label == $l) | .pane_id) // empty' <<<"$live")"
  [ -z "$p" ] || { pane[i]="$p"; used+="$p "; }
done
for ((i = 0; i < n; i++)); do
  [ -z "${pane[i]}" ] || continue
  p="$(jq -r --arg u "$used" 'first(.[] | select(. as $x | ($u | contains(" " + $x.pane_id + " ")) | not) | .pane_id) // empty' <<<"$live")"
  [ -z "$p" ] || { pane[i]="$p"; used+="$p "; fresh[i]=1; }
done
[ "$DRY" != 1 ] || [ -n "${pane[0]}" ] || pane[0]=dry-pane-0
for ((i = 0; i < n; i++)); do
  [ -z "${pane[i]}" ] || continue
  [ "$i" -gt 0 ] || SL_EXIT=4 sl_die "tab $tab holds no pane to build the layout from"
  if [ "$i" -lt "$ngrid" ]; then read -r dir from_i ratio < <(sl_grid_step "$i" "$rows" "$cols")
  else dir="$(slot_split "$i" direction)"; ratio="$(slot_split "$i" ratio)"; from_i="$(slot_index "$(slot_split "$i" from)")"; fi
  from="${pane[from_i]}"
  [ -n "$from" ] || { [ "$DRY" = 1 ] && from="dry-pane-$((i - 1))"; }
  out="$(sl_mut pane split "$from" --direction "$dir" --ratio "$ratio" --no-focus)" || SL_EXIT=4 sl_die "pane split from $from failed"
  pane[i]="$(jq -r '.result.pane.pane_id // empty' <<<"${out:-$EMPTY}")"
  [ "$DRY" = 1 ] && pane[i]="${pane[i]:-dry-pane-$i}"
  [ -n "${pane[i]}" ] || SL_EXIT=4 sl_die "pane split from $from returned no pane id"
  fresh[i]=1
done
for ((i = 0; i < n; i++)); do
  cur="$(jq -r --arg p "${pane[i]}" 'first(.[] | select(.pane_id == $p) | .label) // empty' <<<"$live")"
  [ "$cur" = "${want[i]}" ] || sl_mut pane rename "${pane[i]}" "${want[i]}" >/dev/null
  cmd="$(slot_field "$i" command)"
  [ "${fresh[i]}" = 1 ] && [ -n "$cmd" ] && [ "$(slot_field "$i" kind)" != agent ] && sl_mut pane run "${pane[i]}" "$cmd" >/dev/null
done
a=""; for ((i = 0; i < n; i++)); do [ "$(slot_field "$i" kind)" = agent ] && { a="${pane[i]}"; break; }; done
[ -n "$a" ] || refuse "layout $layout_id has no agent slot"
agent_pane="$a"
# The seat's own test pane, when the layout has the slot: its id is what the environment line exports and the brief names.
for ((i = 0; i < n; i++)); do [ "$(slot_field "$i" kind)" = test ] && { tpane="${pane[i]}"; break; }; done

if [ "$DRY" != 1 ]; then
  render_settings > "$settings.tmp" && mv "$settings.tmp" "$settings"
  # nudged_at (WO-20261011-dc0d) survives a repair rerun of a live seat; a record that was ended starts over, null.
  prev_nudged=""; [ ! -f "$seat_file" ] || prev_nudged="$(jq -r 'if .ended_at then empty else .nudged_at // empty end' "$seat_file" 2>/dev/null || true)"
  jq -n --arg nudged "$prev_nudged" --arg name "$name" --arg ticket "$id" --arg role "$role" --arg role_file "$role_file" --arg runtime "$runtime" --arg model "$MODEL" \
    --arg effort "$effort" --arg wt "$wt" --arg layout_file "$layout_file" --arg ws "$ws" --arg tab "$tab" --arg hs "$HS" \
    --arg settings "$settings" --arg pane "$a" --arg tpane "$tpane" --arg at "$(sl_now)" --arg task "$task" --argjson lease "$lease" \
    '{name:$name,ticket:$ticket,task:$task,role:$role,role_file:$role_file,runtime:$runtime,model:$model,effort:$effort,worktree:$wt,
      lease:$lease,layout_file:$layout_file,workspace:$ws,tab:$tab,session:$hs,settings:$settings,pane:$pane,test_pane:$tpane,started_at:$at,ended_at:null,nudged_at:(if $nudged == "" then null else $nudged end)}' > "$seat_file.tmp" \
    && mv "$seat_file.tmp" "$seat_file"
  recorded=1
fi

# BREADCRUMB 2026-10-10 20:5x UTC - first live bring-up: the monitor seat's claude opened the "Is this a project you trust?"
#   dialog in its pane (the main checkout had no entry in ~/.claude.json), never reached idle, and `herdr agent start`
#   failed after agent_start_timeout_ms. Claude Code keeps the answer per project path in ~/.claude.json as
#   projects.<path>.hasTrustDialogAccepted, so the seat writes that flag for its worktree before the start, which is the
#   same answer the owner would give for a worktree of this repo. Rejected: answering the dialog with send-keys (a race
#   against agent start, and one more dialog shape to recognise). Cost: one jq pass over ~/.claude.json per seat start.
ensure_trust() {
  local f="$HOME/.claude.json"; [ "$runtime" = claude ] || return 0
  [ -f "$f" ] || printf '{}\n' > "$f"
  jq -e --arg p "$wt" '.projects[$p].hasTrustDialogAccepted == true' "$f" >/dev/null 2>&1 && return 0
  jq --arg p "$wt" '.projects[$p] = ((.projects[$p] // {}) + {hasTrustDialogAccepted: true})' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}
# BREADCRUMB 2026-10-11 - WO-20261011-dc0d, the seat that acks the guard memo and stops. What broke: compaction-guard sends every
#   new session a GOV-100 memo whose last action is "reply with the ack line below and nothing else". A worker whose turn had
#   already ended (brief read, first record posted) acked and stopped dead, because the memo's last word was the last thing it
#   was told; it sat idle on 2026-10-10 (WO-20261010-8fa8) and 2026-10-11 (WO-20261010-a429, -2d04, WO-20261011-4c5e) until the
#   architect ran `herdr agent prompt` by hand, 3 of the 4 ticket seats that day. A worker mid-turn acks and carries on, so only
#   the idle case needs help. Why this fix: this script is the party that knows a brief is pending, so after the brief it
#   watches the agent pane for the ack line "● ACK compaction-guard " (herdr pane wait-output, bounded by nudge_wait_seconds),
#   then polls agent_status through `herdr pane list` for nudge_settle_seconds; two idle reads in a row mean the turn ended, and
#   one `herdr agent prompt` tells the seat to continue; still working at the end of the window means no prompt. seat.json
#   carries nudged_at (UTC) or null. Rejected: changing the guard or its memo (outside this repo, its wording is its own), a
#   timer that nudges every seat blind (it would interrupt a seat that is working), and a standing watcher that nudges for as
#   long as the seat lives (the ticket says once). Cost: seat.sh blocks up to nudge_wait_seconds on a claude seat whose guard
#   sends no memo, which is logged and not an error; a seat that finishes real work inside the settle window and idles is
#   nudged too, which is harmless because the text only says to continue the brief; a stale ack line left in the pane's
#   scrollback by an earlier agent would match, and then the idle poll still decides. The nudge text comes from
#   roles/bin/nudge.sh (--role, --ticket, --project; one line) so render-playbook's directory owns the wording next to the
#   brief; that file is outside the worker fence, so until it exists the inline text below is used. Record: WO-20261011-dc0d.
nudged_set() { jq --arg at "$1" '.nudged_at = (if $at == "" then null else $at end)' "$seat_file" > "$seat_file.tmp" && mv "$seat_file.tmp" "$seat_file"; }
agent_status() {
  sl_h pane list ${ws:+--workspace "$ws"} 2>/dev/null | jq -r --arg p "$a" 'first((.result.panes // [])[] | select(.pane_id == $p) | .agent_status) // empty'
}
nudge_text() {
  local t title
  if [ -n "$id" ] && t="$("$SL_REPO/roles/bin/nudge.sh" --role "$role" --ticket "$id" --project "$SL_REPO" 2>/dev/null)" && [ -n "$t" ]; then printf '%s' "$t"; return 0; fi
  if [ -n "$id" ]; then
    title="$(awk '/^---$/{c++; next} c==1' "$ticket_file" | jq -r '.title // empty' 2>/dev/null)" || title=""
    printf '%s - %s. Continue your brief from the step you reached. Playbook playbooks/%s.md.' "$id" "$title" "$role"
  else printf 'Continue your task from the step you reached. Playbook playbooks/%s.md.' "$role"; fi
}
# nudge_seat: after the brief, one continue prompt when the seat acked the guard memo and went idle. A claude seat only: the
# guard binds no other runtime, so there is no ack to wait for.
nudge_seat() {
  local wait settle s idle=0 st
  [ "$runtime" = claude ] || return 0
  if [ "$DRY" = 1 ]; then printf 'DRY: nudge %s once after the line "● ACK compaction-guard " when the seat is idle\n' "$name" >&2; return 0; fi
  wait="$(sl_cfg .nudge_wait_seconds)"; settle="$(sl_cfg .nudge_settle_seconds)"
  nudged_set ""
  if ! sl_h pane wait-output "$a" --regex '● ACK compaction-guard ' --source recent-unwrapped --timeout "$((wait * 1000))" >/dev/null 2>&1; then
    sl_log "seat $name: no guard ack within ${wait}s, no nudge"; return 0
  fi
  for ((s = 0; s < settle; s++)); do
    st="$(agent_status)" || st=""
    if [ "$st" = idle ]; then idle=$((idle + 1)); [ "$idle" -lt 2 ] || break; else idle=0; fi
    sleep 1
  done
  if [ "$idle" -lt 2 ]; then sl_log "seat $name: still working after the guard ack, no nudge"; return 0; fi
  if sl_h agent prompt "$name" "$(nudge_text)" >/dev/null; then nudged_set "$(sl_now)"; sl_log "seat $name: idle after the guard ack, nudged once"
  else sl_log "seat $name: idle after the guard ack but the nudge could not be sent; the monitor will re-prompt"; fi
}
started=0
if [ "$DRY" != 1 ] && sl_agent_live "$name"; then sl_log "seat $name: agent already running, left as is (its test pane is ${tpane:-none}; a running agent keeps the COQ_TEST_PANE it started with, so after a repair that rebuilt the pane it needs --down and a fresh up)"
else
  # The environment rides one physical line into the agent pane only. The Claude Code markers a pane may have
  # inherited from a server started inside a Claude shell are unset first (bearings-v2 F-45), or the seat's transcript
  # saving is off and the guard's sensor reads nothing. RAIL_SURFACE: artifact for a Claude seat, lavish for any other
  # runtime (dotfiles Rule 19; owner 2026-09-22).
  surface=lavish; [ "$runtime" = claude ] && surface=artifact
  unset_markers='for v in $(env | sed -n '\''s/^\(CLAUDECODE\|CLAUDE_CODE_[A-Z0-9_]*\|CLAUDE_PID\|CLAUDE_EFFORT\|AI_AGENT\)=.*/\1/p'\''); do unset "$v"; done; '
  line="$unset_markers$(printf 'cd %q && export COQ_SEAT=%q COQ_TEST_PANE=%q COQ_ROLE=%q COQ_TICKET=%q COQ_ROLE_FILE=%q COQ_WORKTREE=%q COQ_REPO=%q RAIL_SURFACE=%q PATH=%q:"$PATH"' \
    "$wt" "$name" "$tpane" "$role" "$id" "$role_file" "$wt" "$SL_REPO" "$surface" "$SL_REPO/bin")"
  sl_mut pane wait-output "$a" --regex "$SL_PROMPT_RE" --timeout "$(sl_cfg .prompt_timeout_ms)" >/dev/null 2>&1 \
    || { [ "$DRY" = 1 ] || { SL_EXIT=4 sl_die "pane $a showed no shell prompt within $(sl_cfg .prompt_timeout_ms) ms; rerun to repair"; }; }
  sl_mut pane run "$a" "$line" >/dev/null
  [ "$DRY" = 1 ] || ensure_trust
  case "$runtime" in
    claude) flags=(--model "$MODEL" --effort "$effort" --permission-mode "$pmode" --settings "$settings"); [ -z "$resume_id" ] || flags+=(--resume "$resume_id") ;;
    codex) flags=(-m "$MODEL" -c "model_reasoning_effort=\"$effort\"") ;;
    *) refuse "runtime $runtime is not launched by this door" ;;
  esac
  sl_mut agent start "$name" --kind "$bin" --pane "$a" -- "${flags[@]}" >/dev/null || SL_EXIT=4 sl_die "herdr agent start $name failed in pane $a"
  started=1
  sl_record seat.up 100 "$name" ${id:+--ticket "$id"} --pane "$a" --note "$role seat up: $MODEL $effort $pmode"
fi
if [ "$started" = 1 ]; then
  # A resumed session already holds its brief, so a second one would only make it post a second work.started.
  if [ -n "$resume_id" ]; then prompt="seat.sh resumed session $resume_id as the $role seat $name${id:+ on $id}. Playbook playbooks/$role.md. Carry on from where the session stopped."
  elif [ -n "$ticket" ]; then prompt="$("$SL_REPO/roles/bin/brief.sh" --role "$role" --ticket "$id" --project "$SL_REPO" --test-pane "$tpane")" \
      || prompt="$id. Playbook playbooks/$role.md. The ticket file could not be read; post blocked 423 before anything else."
  else prompt="You are the $role seat named $name. Read playbooks/$role.md first. Your task: $task. Post your first record before anything else."; fi
  prompt+=" Work only in $wt."
  if sl_mut agent prompt "$name" "$prompt" >/dev/null; then nudge_seat
  else sl_log "seat $name: brief could not be sent; the monitor will re-prompt"; fi
fi
jq -nc --arg name "$name" --arg ticket "$id" --arg role "$role" --arg ws "$ws" --arg tab "$tab" --arg agent "$a" --arg settings "$settings" \
  --arg model "$MODEL" --arg effort "$effort" --arg panes "${pane[*]}" --argjson started "$started" --arg wt "$wt" --argjson lease "$lease" --arg tpane "$tpane" \
  '{name:$name,ticket:$ticket,role:$role,workspace:$ws,tab:$tab,agent:$agent,test_pane:$tpane,panes:($panes|split(" ")),settings:$settings,model:$model,effort:$effort,worktree:$wt,lease:$lease,started:($started==1)}'
