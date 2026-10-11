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
