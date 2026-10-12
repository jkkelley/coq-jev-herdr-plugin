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
#   rec KIND CODE SEAT [TICKET] [ATTEMPT]   one record through the copy's event.sh; prints its id; REC_SHA=<hex> and REC_PR=<n> in the
#                            environment add --sha and --pr (a review.passed is held by gate.sh unless a test.passed names the same head)
#   evo ARGS                 event.sh add, with an id strictly after every record already in the world; rec goes through it
#   run_once [flags]         route.sh once --from-start --repo $R --state $STATE
#   rec_json ID              the record's JSON
#   hcalls                   how many times the runner called herdr
#   ids_of KIND              ids of the records of that kind in the copy's event log, one per line
# Records are written one second apart by the cases that depend on order: ids sort by UTC second, then a random suffix.
# BREADCRUMB 2026-10-12 - WO-20261012-7e13 (Roadmap A1), architect ruling on blocked record 20261012T231224Z-423-8cv0o. What broke: event.sh add
#   now writes <state>/records/YYYY/MM/<timestamp>-<name>.json, and this world copied only events/bin and events/schema, so event.sh
#   exited 4 (bin/state-root.sh missing) and 17 of 21 cases failed; and even with the resolver the belt would not see the record:
#   route.sh keys its ledger on the record's file name (route.sh line ~264) and gate.sh finds a record by `find -name "$ID.json"`
#   (gate.sh line 97), so a file that is not named by its id is lost to them until item A2 moves the belt onto the state root.
#   Why this fix: the world copies the resolver and its config and runs the REAL event.sh as event-real.sh with its own temp
#   COQ_STATE (recstate), and event.sh in the world is a ten line shim that runs it and moves the new record to the events/YYYY/MM/
#   <id>.json place the belt reads, printing the id as before. Every case and the unmodified runner keep their old view; the real
#   writer is still what makes the record. Rejected: a legacy switch in event.sh (AC-H1 forbids it) and editing cases (not this
#   ticket's files). Cost: the world proves the belt against the old layout, not the state root, until A2 deletes this shim and
#   points events_dir at the state root. A case that calls event.sh list sees only the moved records (the old tree), as before.
world_event_shim() {
  cp "$1/bin/state-root.sh" "$R/bin/"; cp "$1/config/state.json" "$1/config/state.schema.json" "$R/config/"
  mv "$R/events/bin/event.sh" "$R/events/bin/event-real.sh"
  sed -e "s|__RECSTATE__|$W/recstate|g" > "$R/events/bin/event.sh" <<'SHIM'
#!/usr/bin/env bash
# world shim for events/bin/event.sh (factory/tests/lib/world.sh, world_event_shim): the real writer into a temp state root, then the old place.
ROOT=$(cd "$(dirname "$0")/.." && pwd); real=$ROOT/bin/event-real.sh
export COQ_STATE=__RECSTATE__
[ "${1:-}" = add ] || exec "$real" "$@"
args=(); json=0; for a in "$@"; do if [ "$a" = --json ]; then json=1; else args+=("$a"); fi; done
p=$("$real" "${args[@]}") || exit $?
id=$(jq -r .id "$p"); ym=$(basename "$(dirname "$(dirname "$p")")")/$(basename "$(dirname "$p")")
mkdir -p "$ROOT/$ym" && mv "$p" "$ROOT/$ym/$id.json" || exit 4
if [ "$json" = 1 ]; then cat "$ROOT/$ym/$id.json"; else printf '%s\n' "$id"; fi
SHIM
  chmod +x "$R/events/bin/event.sh"
}
world_up() {
  W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/$1"; R="$W/repo"; STATE="$W/state"; HLOG="$W/herdr.log"
  rm -rf "$W"; mkdir -p "$R/events" "$R/queue" "$R/factory" "$R/bin" "$R/config" "$W/bin" "$STATE" "$W/recstate"; : > "$HLOG"
  local src="${REPO_ROOT:-/repo}"
  cp -r "$src/events/bin" "$src/events/schema" "$R/events/"; world_event_shim "$src"; cp -r "$src/roles" "$src/playbooks" "$R/"
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
  [ -z "${REC_SHA:-}" ] || args+=(--sha "$REC_SHA"); [ -z "${REC_PR:-}" ] || args+=(--pr "$REC_PR")
  evo "${args[@]}"
}
# evo EVENT.SH-ARGS: event.sh add, but the id sorts strictly after the id of every other record in this world; prints the id.
# Ids sort by UTC second then a random suffix, and the runner routes in id order. The host clock steps back about a second every ~35 s
# (06-belt breadcrumb), so "sleep 1 between records" does not keep them in order: 02-no-route, 08-break-glass and 10-sha each failed
# about one run in four on 2026-10-12 (backlog disva) when a later record landed in the same second as, and sorted before, an earlier one.
# A record that would not sort after the last is deleted and written again a moment later. event.sh's own exit code is passed on.
evo() {
  local id last rc
  for _ in $(seq 1 20); do
    id=$("$R/events/bin/event.sh" add "$@"); rc=$?; [ "$rc" = 0 ] || return "$rc"
    # the newest id of ANY other record in the world: the runner's own escalated and receipt records count too, since the table's
    # `escalations` counts the ones with an id before the record (03-escalate failed when a blocked 423 sorted before one).
    last=$(find "$R/events" -path '*/20*/*.json' -name '*.json' ! -name "$id.json" -printf '%f\n' 2>/dev/null | sort | tail -n 1); last=${last%.json}
    if [[ -z "$last" || "$id" > "$last" ]]; then printf '%s\n' "$id"; return 0; fi
    find "$R/events" -name "$id.json" -delete; sleep 0.3
  done
  return 1
}
run_once() { "$ROUTE" once --from-start --repo "$R" --state "$STATE" "$@"; }
ids_of() { "$R/events/bin/event.sh" list --json | jq -r --arg k "$1" 'select(.kind == $k) | .id'; }
rec_json() { find "$R/events" -name "$1.json" -exec cat {} +; }
hcalls() { wc -l < "$HLOG" | tr -d ' '; }

# --- the flow watch (WO-20261011-6842) ---
#   flow_world               after world_up: FLOW (the watcher), FSTATE, a herdr stub that answers pane list and process-info
#                            from $W/panes.json and $W/procinfo.json, a fresh belt file, and a runner pane that is up
#   runner_pane up|idle|gone the runner pane running a job, its shell sitting at a prompt, or no such pane
#   agent_state working|idle|gone   the answer of `herdr agent get` for any seat (the flow watch skips a gate whose consumer seat is working)
#   backdate ID SECONDS      rewrite the record's "at" to SECONDS ago (ids keep their order; the watcher judges age by "at")
#   flow_once [flags]        flow.sh once --from-start --repo $R --state $FSTATE
#   flow_notes               the 500 notes the watcher wrote, as JSON lines
flow_world() {
  FLOW="$R/factory/bin/flow.sh"; FSTATE="$W/fstate"; mkdir -p "$R/factory/state"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\ncase "$*" in\n *"pane list"*) cat "%s/panes.json" ;;\n *"process-info"*) cat "%s/procinfo.json" ;;\n *"agent get"*) [ -f "%s/agent.json" ] && cat "%s/agent.json" || exit 1 ;;\nesac\n' "$HLOG" "$W" "$W" "$W" "$W" > "$W/bin/herdr"
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
# agent_state working|idle|gone   what `herdr agent get <any seat>` answers: that agent_status, or an error when there is no such agent
agent_state() { if [ "$1" = gone ]; then rm -f "$W/agent.json"; else printf '{"result":{"agent":{"agent_status":"%s"}}}\n' "$1" > "$W/agent.json"; fi; }
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
