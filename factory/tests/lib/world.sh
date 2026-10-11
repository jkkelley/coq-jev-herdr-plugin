#!/usr/bin/env bash
# factory/tests/lib/world.sh - one throwaway world per case: only the pieces the runner touches, copied from the repo, plus a
# stub herdr first on PATH that appends its argv to $W/herdr.log and exits 1 when $W/herdr.fail exists.
#   world_up <name>          sets W (case root), R (repo copy), ROUTE (the runner), STATE (runner state dir), HLOG (herdr log)
#   rec KIND CODE SEAT [TICKET] [ATTEMPT]   one record through the copy's event.sh; prints its id
#   run_once [flags]         route.sh once --from-start --repo $R --state $STATE
#   rec_json ID              the record's JSON
#   hcalls                   how many times the runner called herdr
#   ids_of KIND              ids of the records of that kind in the copy's event log, one per line
# Records are written one second apart by the cases that depend on order: ids sort by UTC second, then a random suffix.
world_up() {
  W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/$1"; R="$W/repo"; STATE="$W/state"; HLOG="$W/herdr.log"
  rm -rf "$W"; mkdir -p "$R/events" "$R/queue" "$R/factory" "$W/bin" "$STATE"; : > "$HLOG"
  local src="${REPO_ROOT:-/repo}"
  cp -r "$src/events/bin" "$src/events/schema" "$R/events/"; cp -r "$src/roles" "$src/playbooks" "$R/"
  cp -r "$src/queue/bin" "$src/queue/config" "$R/queue/"; cp -r "$src/factory/bin" "$src/factory/config" "$R/factory/"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\n[ ! -e "%s/herdr.fail" ] || exit 1\n' "$HLOG" "$W" > "$W/bin/herdr"; chmod +x "$W/bin/herdr"
  export PATH="$W/bin:$PATH"; unset COQ_HERDR_SESSION
  ROUTE="$R/factory/bin/route.sh"
}
rec() {
  local args=(--code "$2" --seat "$3" --kind "$1"); [ -z "${4:-}" ] || args+=(--ticket "$4"); [ -z "${5:-}" ] || args+=(--attempt "$5")
  "$R/events/bin/event.sh" add "${args[@]}"
}
run_once() { "$ROUTE" once --from-start --repo "$R" --state "$STATE" "$@"; }
ids_of() { "$R/events/bin/event.sh" list --json | jq -r --arg k "$1" 'select(.kind == $k) | .id'; }
rec_json() { find "$R/events" -name "$1.json" -exec cat {} +; }
hcalls() { wc -l < "$HLOG" | tr -d ' '; }

# --- the flow watch (WO-20261011-6842) ---
#   flow_world               after world_up: FLOW (the watcher), FSTATE, a herdr stub that answers pane list and process-info
#                            from $W/panes.json and $W/procinfo.json, a fresh belt file, and a runner pane that is up
#   runner_pane up|idle|gone the runner pane running a job, its shell sitting at a prompt, or no such pane
#   backdate ID SECONDS      rewrite the record's "at" to SECONDS ago (ids keep their order; the watcher judges age by "at")
#   flow_once [flags]        flow.sh once --from-start --repo $R --state $FSTATE
#   flow_notes               the 500 notes the watcher wrote, as JSON lines
flow_world() {
  FLOW="$R/factory/bin/flow.sh"; FSTATE="$W/fstate"; mkdir -p "$R/factory/state"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\ncase "$*" in\n *"pane list"*) cat "%s/panes.json" ;;\n *"process-info"*) cat "%s/procinfo.json" ;;\nesac\n' "$HLOG" "$W" "$W" > "$W/bin/herdr"
  chmod +x "$W/bin/herdr"; runner_pane up; : > "$R/factory/state/belt"
}
runner_pane() {
  case $1 in
    gone) echo '{"result":{"panes":[{"pane_id":"w1:p1","label":"2.1.1 event log tail - events"}]}}' > "$W/panes.json" ;;
    *) echo '{"result":{"panes":[{"pane_id":"w1:p9","label":"2.2.2 route runner - runner"}]}}' > "$W/panes.json"
       if [ "$1" = up ]; then echo '{"result":{"process_info":{"foreground_process_group_id":200,"shell_pid":100}}}' > "$W/procinfo.json"
       else echo '{"result":{"process_info":{"foreground_process_group_id":100,"shell_pid":100}}}' > "$W/procinfo.json"; fi ;;
  esac
}
backdate() { local f; f=$(find "$R/events" -name "$1.json"); jq --arg at "$(date -u -d "-$2 seconds" +%Y-%m-%dT%H:%M:%SZ)" '.at = $at' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; }
flow_once() { "$FLOW" once --from-start --repo "$R" --state "$FSTATE" "$@"; }
flow_notes() { "$R/events/bin/event.sh" list --json | jq -c 'select(.seat == "flow-watch")'; }
