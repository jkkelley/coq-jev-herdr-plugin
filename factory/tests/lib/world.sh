#!/usr/bin/env bash
# factory/tests/lib/world.sh - one throwaway world per case: only the pieces the runner touches, copied from the repo, plus a
# stub herdr first on PATH that appends its argv to $W/herdr.log and exits 1 when $W/herdr.fail exists, and a stub seat.sh in the
# copy (herdr/bin/seat.sh, what runner.json's seat_bin names) that appends its argv to $W/seat.log. Both also append one tagged line
# to $W/order.log, so a case can prove which came first. The stub seat.sh behaves like the real one where the runner can see it:
#   --ticket T --role R   brings seat <R>-<t> up (name "merger" for the merger, the label in roles/merger.json), writes a seat.up 100
#                         record, and on a seat already up prints "left as is" and writes nothing
#   --down NAME           writes a seat.down 100 record for NAME, once; a second --down prints "already down" and writes nothing
#   $W/seat.fail          its text is the refusal: stderr, exit 3, nothing written   $W/seat.fail.down  the same, for --down only
#   $W/seat.slow  writes the belt's mtime (ns) to $W/seat.belt, then sleeps a second
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
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\nprintf "herdr %%s\\n" "$*" >> "%s/order.log"\n[ ! -e "%s/herdr.fail" ] || exit 1\n' "$HLOG" "$W" "$W" > "$W/bin/herdr"; chmod +x "$W/bin/herdr"
  mkdir -p "$R/herdr/bin" "$W/seats"; : > "$W/seat.log"; : > "$W/order.log"
  sed -e "s|__W__|$W|g" -e "s|__R__|$R|g" -e "s|__STATE__|$STATE|g" > "$R/herdr/bin/seat.sh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "__W__/seat.log"; printf 'seat %s\n' "$*" >> "__W__/order.log"
[ ! -e "__W__/seat.slow" ] || { date -r "__STATE__/belt" +%s%N > "__W__/seat.belt"; sleep 1; }
if [ -e "__W__/seat.fail" ]; then cat "__W__/seat.fail" >&2; exit 3; fi
if [ "$1" = --down ] && [ -e "__W__/seat.fail.down" ]; then cat "__W__/seat.fail.down" >&2; exit 3; fi
ev() { "__R__/events/bin/event.sh" add --code 100 --seat "$1" --kind "$2" ${3:+--ticket "$3"} --note "stub seat.sh"; }
case "$1" in
  --down) name=$2; [ ! -e "__W__/seats/$name.down" ] || { echo "$name: already down since stub"; exit 0; }
    : > "__W__/seats/$name.down"; t=$(sed -n 's/.*-wo-\([0-9]\{8\}-[0-9a-f]\{4\}\)$/WO-\1/p' <<<"$name")
    ev "$name" seat.down "$t" >/dev/null; printf '{"name":"%s","down":true}\n' "$name" ;;
  --ticket) t=$2; r=$4; name=$(jq -r .label "__R__/roles/$r.json"); name=${name//\$\{ticket\}/${t,,}}
    [ ! -e "__W__/seats/$name.up" ] || { echo "seat $name: agent already running, left as is" >&2; printf '{"name":"%s"}\n' "$name"; exit 0; }
    : > "__W__/seats/$name.up"; rm -f "__W__/seats/$name.down"; ev "$name" seat.up "$t" >/dev/null; printf '{"name":"%s"}\n' "$name" ;;
  *) echo "stub seat.sh: unexpected $*" >&2; exit 2 ;;
esac
STUB
  chmod +x "$R/herdr/bin/seat.sh"
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

# --- the policy watch (WO-20261012-9b2c) ---
#   policy_world             after world_up: POLICY (the watcher) and PSTATE; the herdr stub world_up made stays (it logs argv, exits 1 when $W/herdr.fail exists)
#   policy_once [flags]      policy.sh once --from-start --repo $R --state $PSTATE
#   policy_records           the policy.applied records the watcher wrote, as JSON lines
#   backdate ID SECONDS      (defined with the flow watch above) rewrite a record's "at"; the watcher judges a deadline by "at"
policy_world() { POLICY="$R/factory/bin/policy.sh"; PSTATE="$W/pstate"; }
policy_once() { "$POLICY" once --from-start --repo "$R" --state "$PSTATE" "$@"; }
policy_records() { "$R/events/bin/event.sh" list --json | jq -c 'select(.kind == "policy.applied")'; }
