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
#   world_up <name>          sets W (case root), R (repo copy), ROUTE (the runner), STATE (the world's state root, exported as COQ_STATE:
#                            records in $STATE/records, the ledger in $STATE/ledger/routed, belt and since in $STATE/run), HLOG (herdr log)
#   rec KIND CODE SEAT [TICKET] [ATTEMPT]   one record through the copy's event.sh; prints its id; REC_SHA=<hex> and REC_PR=<n> in the
#                            environment add --sha and --pr (a review.passed is held by gate.sh unless a test.passed names the same head)
#   evo ARGS                 event.sh add, with an id strictly after every record already in the world; rec goes through it
#   run_once [flags]         route.sh once --from-start --repo $R --state $STATE
#   rec_json ID              the record's JSON
#   rec_file ID              the record file whose id field is ID (a file is named <timestamp>-<name>, never by its id)
#   rec_files                every record file in the state root's records tree
#   files_code CODE          the record files with that code (the runner's 500 notes are code 500)
#   notes_code CODE          the notes of those records, one per line
#   ledger_of ID             the path of the runner's ledger entry for that record (it is named like the record's file)
#   hcalls                   how many times the runner called herdr
#   ids_of KIND              ids of the records of that kind in the copy's event log, one per line
# Records are written one second apart by the cases that depend on order: ids sort by UTC second, then a random suffix.
# BREADCRUMB 2026-10-13 - WO-20261012-0229 (Roadmap A2). What broke: this world used to copy the resolver and run the REAL event.sh into
#   a private temp root (recstate), then move each record to <repo copy>/events/YYYY/MM/<id>.json, because the belt read the old
#   events/ tree and keyed its ledger on a file named by the id (the A1 breadcrumb, architect ruling on blocked record
#   20261012T231224Z-423-8cv0o). The belt now reads the state root, so the move is a lie: the world proved the belt against a layout
#   it no longer has. Why this fix: the world exports COQ_STATE=$W/state (AC-H3), the real event.sh writes there as it does on the
#   host, and the unmodified runner, gate.sh, flow.sh and policy.sh read it from there. event.sh in the world stays a wrapper over
#   the real one (event-real.sh) for one reason: `add` prints the new record's id, not its path, and about 130 assertions in the
#   cases hold an id. Every other verb, and --json, are the real ones. Rejected: rewriting the cases to take paths (an id is what
#   the wake line, the receipts and gate.sh --id carry) and keeping the move (it hides exactly the A2 defect). Cost: a case that
#   needs the path of a record asks rec_file; a record file is named <timestamp>-<kind>-..., so find -name '*-500-*' no longer
#   finds the runner's 500 notes, files_code does.
# BREADCRUMB 2026-10-13 - WO-20261013-f298 (Roadmap K5 reland). What broke: K5 (PR 90) made the real writer refuse a gate record with no --sha
#   and any --code outside SPEC-17 s-codes, and this world's cases post bare gate records and probe codes the routes file maps to nothing
#   (deploy 250, note 299, work.started 101, gate 150 in 01-wake .. 22-no-route-noise), so 16 cases failed and main broke (revert PR 95).
#   Why this fix: the world keeps posting the records it always posted, through event-fixture.sh, a wrapper that hands the real writer a
#   record it accepts and then undoes the difference: a gate kind with no --sha is written with a placeholder sha and the key deleted, and a
#   code outside the schema's enum is written as 100 and the code and the id's code part rewritten. The runner under test then reads exactly
#   the records it reads on the host from a seat that predates K5 or a hand-edited file, which is what 22-no-route-noise and 10-sha prove.
#   The refusals themselves are proven where they live, events/tests/cases/04-refusals.test.sh. Rejected: giving every fixture a sha (10-sha
#   asserts the plain wake line of a record that has none), a bypass flag in the real writer (a flag that skips the refusal is the hole K5
#   closes) and rewriting 16 cases (the cases are about routing, not about posting). Cost: a fixture record can be one the real writer
#   would refuse, so a case that wants the writer's behaviour calls event-real.sh itself, as 10-sha does for the malformed sha.
world_event_shim() {
  cp "$1/bin/state-root.sh" "$R/bin/"; cp "$1/config/state.json" "$1/config/state.schema.json" "$R/config/"
  mv "$R/events/bin/event.sh" "$R/events/bin/event-real.sh"
  cat > "$R/events/bin/event-fixture.sh" <<'FIX'
#!/usr/bin/env bash
# event-fixture.sh add ARGS: event-real.sh add, but a gate record with no --sha and a code outside the schema's enum are accepted; prints the path.
ROOT=$(cd "$(dirname "$0")/.." && pwd); real=$ROOT/bin/event-real.sh
code=""; kind=""; sha=0; args=(); set -- "$@"; [ "${1:-}" != add ] || shift
while [ $# -gt 0 ]; do case $1 in --code) code=$2; shift 2;; --kind) kind=$2; args+=(--kind "$2"); shift 2;; --sha) sha=1; args+=(--sha "$2"); shift 2;; *) args+=("$1"); shift;; esac; done
unmapped=0; jq -e --argjson c "${code:-0}" '.properties.code.enum | index($c) | not' "$ROOT/schema/event.schema.json" >/dev/null 2>&1 && unmapped=1
bare=0; [[ $kind =~ ^(pr\.opened|test\.passed|test\.failed|review\.passed|review\.changes|merged|merge\.conflict|verified|rejected)$ && $sha = 0 ]] && bare=1
[ "$unmapped" = 0 ] || args+=(--code 100); [ "$unmapped" = 1 ] || args+=(--code "$code")
[ "$bare" = 0 ] || args+=(--sha 0000000)
p=$("$real" add "${args[@]}") || exit $?
if [ "$unmapped" = 1 ] || [ "$bare" = 1 ]; then
  jq --argjson c "${code:-100}" --argjson un "$unmapped" --argjson bare "$bare" '(if $un == 1 then .code = $c | .id |= sub("-100-"; "-\($c)-") else . end) | (if $bare == 1 then del(.sha) else . end)' "$p" > "$p.t" && mv "$p.t" "$p"
fi
printf '%s\n' "$p"
FIX
  chmod +x "$R/events/bin/event-fixture.sh"
  cat > "$R/events/bin/event.sh" <<'SHIM'
#!/usr/bin/env bash
# world wrapper for events/bin/event.sh (factory/tests/lib/world.sh, world_event_shim): add goes through event-fixture.sh and prints the record's id.
ROOT=$(cd "$(dirname "$0")/.." && pwd); real=$ROOT/bin/event-real.sh
[ "${1:-}" = add ] || exec "$real" "$@"
args=(); json=0; for a in "$@"; do if [ "$a" = --json ]; then json=1; else args+=("$a"); fi; done
p=$("$ROOT/bin/event-fixture.sh" "${args[@]}") || exit $?
if [ "$json" = 1 ]; then cat "$p"; else jq -r .id "$p"; fi
SHIM
  chmod +x "$R/events/bin/event.sh"
}
world_up() {
  W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/$1"; R="$W/repo"; STATE="$W/state"; HLOG="$W/herdr.log"; export COQ_STATE="$STATE"
  rm -rf "$W"; mkdir -p "$R/events" "$R/queue" "$R/factory" "$R/bin" "$R/config" "$W/bin" "$STATE"; : > "$HLOG"
  local src="${REPO_ROOT:-/repo}"
  cp -r "$src/events/bin" "$src/events/schema" "$R/events/"; world_event_shim "$src"; cp -r "$src/roles" "$src/playbooks" "$R/"
  cp -r "$src/queue/bin" "$src/queue/config" "$R/queue/"; cp -r "$src/factory/bin" "$src/factory/config" "$R/factory/"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\nprintf "herdr %%s\\n" "$*" >> "%s/order.log"\n[ ! -e "%s/herdr.fail" ] || exit 1\n' "$HLOG" "$W" "$W" > "$W/bin/herdr"; chmod +x "$W/bin/herdr"
  mkdir -p "$R/herdr/bin" "$W/seats"; : > "$W/seat.log"; : > "$W/order.log"
  sed -e "s|__W__|$W|g" -e "s|__R__|$R|g" -e "s|__STATE__|$STATE|g" > "$R/herdr/bin/seat.sh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "__W__/seat.log"; printf 'seat %s\n' "$*" >> "__W__/order.log"
[ ! -e "__W__/seat.slow" ] || { date -r "__STATE__/run/belt" +%s%N > "__W__/seat.belt"; sleep 1; }
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
  local id last rc p
  for _ in $(seq 1 20); do
    p=$("$R/events/bin/event-fixture.sh" add "$@"); rc=$?; [ "$rc" = 0 ] || return "$rc"
    id=$(jq -r .id "$p")
    # the newest id of ANY other record in the world: the runner's own escalated and receipt records count too, since the table's
    # `escalations` counts the ones with an id before the record (03-escalate failed when a blocked 423 sorted before one).
    last=$(rec_files | while read -r f; do [ "$f" = "$p" ] || jq -r .id "$f" 2>/dev/null; done | sort | tail -n 1)
    if [[ -z "$last" || "$id" > "$last" ]]; then printf '%s\n' "$id"; return 0; fi
    rm -f "$p"; sleep 0.3
  done
  return 1
}
run_once() { "$ROUTE" once --from-start --repo "$R" --state "$STATE" "$@"; }
ids_of() { "$R/events/bin/event.sh" list --json | jq -r --arg k "$1" 'select(.kind == $k) | .id'; }
rec_files() { find "$STATE/records" -mindepth 3 -maxdepth 3 -name '*.json' 2>/dev/null | sort; }
rec_file() { grep -rlF --include='*.json' "\"id\": \"$1\"" "$STATE/records" 2>/dev/null | head -n 1; }
rec_json() { cat "$(rec_file "$1")"; }
files_code() { rec_files | while read -r f; do jq -e --argjson c "$1" 'select(.code == $c)' "$f" >/dev/null 2>&1 && printf '%s\n' "$f"; done; true; }
ledger_of() { printf '%s/ledger/routed/%s' "$STATE" "$(basename "$(rec_file "$1")" .json)"; }
notes_code() { files_code "$1" | while read -r f; do jq -r .note "$f"; done; }
hcalls() { wc -l < "$HLOG" | tr -d ' '; }

# --- the flow watch (WO-20261011-6842) ---
#   flow_world               after world_up: FLOW (the watcher), FSTATE (the state root, so the latches are $STATE/run/flow), a herdr stub that answers pane list and process-info
#                            from $W/panes.json and $W/procinfo.json, a fresh belt file, and a runner pane that is up
#   runner_pane up|idle|gone the runner pane running a job, its shell sitting at a prompt, or no such pane
#   agent_state working|idle|gone   the answer of `herdr agent get` for any seat (the flow watch skips a gate whose consumer seat is working)
#   backdate ID SECONDS      rewrite the record's "at" to SECONDS ago (ids keep their order; the watcher judges age by "at")
#   flow_once [flags]        flow.sh once --from-start --repo $R --state $FSTATE
#   flow_notes               the 500 notes the watcher wrote, as JSON lines
flow_world() {
  FLOW="$R/factory/bin/flow.sh"; FSTATE="$STATE"; mkdir -p "$STATE/run"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\ncase "$*" in\n *"pane list"*) cat "%s/panes.json" ;;\n *"process-info"*) cat "%s/procinfo.json" ;;\n *"agent get"*) [ -f "%s/agent.json" ] && cat "%s/agent.json" || exit 1 ;;\nesac\n' "$HLOG" "$W" "$W" "$W" "$W" > "$W/bin/herdr"
  chmod +x "$W/bin/herdr"; runner_pane up; : > "$STATE/run/belt"
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
backdate() { local f; f=$(rec_file "$1"); jq --arg at "$(date -u -d "-$2 seconds" +%Y-%m-%dT%H:%M:%SZ)" '.at = $at' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; }
flow_once() { "$FLOW" once --from-start --repo "$R" --state "$FSTATE" "$@"; }
flow_notes() { "$R/events/bin/event.sh" list --json | jq -c 'select(.seat == "flow-watch")'; }

# --- the policy watch (WO-20261012-9b2c) ---
#   policy_world             after world_up: POLICY (the watcher) and PSTATE (the state root, latches in $STATE/run/policy); the herdr stub world_up made stays (it logs argv, exits 1 when $W/herdr.fail exists)
#   policy_once [flags]      policy.sh once --from-start --repo $R --state $PSTATE
#   policy_records           the policy.applied records the watcher wrote, as JSON lines
#   backdate ID SECONDS      (defined with the flow watch above) rewrite a record's "at"; the watcher judges a deadline by "at"
policy_world() { POLICY="$R/factory/bin/policy.sh"; PSTATE="$STATE"; }
policy_once() { "$POLICY" once --from-start --repo "$R" --state "$PSTATE" "$@"; }
policy_records() { "$R/events/bin/event.sh" list --json | jq -c 'select(.kind == "policy.applied")'; }
