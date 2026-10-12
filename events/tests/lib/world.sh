#!/usr/bin/env bash
# events/tests/lib/world.sh - one throwaway world per case: only the pieces the state root and the event log touch, copied from the
# repository, plus a private HOME and XDG tree so a default root lands inside the world and never in the real one.
#   world_up <name>     sets W (case root), R (repo copy), SR (R/bin/state-root.sh), EV (R/events/bin/event.sh); HOME, XDG_STATE_HOME and
#                       XDG_CACHE_HOME point inside W, COQ_STATE, COQ_CACHE and COQ_REPO are unset, so a case sets what it tests
#   freeze_clock SEC    a `date` first on PATH that reports one fixed UTC second (2026-10-12 22:00:SEC), so two writes share a second
#   validate FILE       0 when FILE matches events/schema/event.schema.json (python3 jsonschema), the same check `event.sh check` runs
# shellcheck disable=SC2034  # SR, EV, W and R are the handles every case sourcing this file uses; shellcheck cannot see the cases
world_up() {
  W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/$1"; R="$W/repo"; rm -rf "$W"; mkdir -p "$R/bin" "$R/config" "$R/events" "$W/bin" "$W/home"
  local src="${REPO_ROOT:-/repo}"
  cp "$src/bin/state-root.sh" "$R/bin/"; cp "$src/config/state.json" "$src/config/state.schema.json" "$R/config/"
  cp -r "$src/events/bin" "$src/events/schema" "$R/events/"
  SR="$R/bin/state-root.sh"; EV="$R/events/bin/event.sh"
  export HOME="$W/home" XDG_STATE_HOME="$W/home/.local/state" XDG_CACHE_HOME="$W/home/.cache"
  unset COQ_STATE COQ_CACHE COQ_REPO
  export PATH="$W/bin:$PATH"
}
freeze_clock() {
  printf '#!/usr/bin/env bash\nexec /bin/date -d "2026-10-12 22:00:%02d UTC" "$@"\n' "${1:-0}" > "$W/bin/date"; chmod +x "$W/bin/date"
}
validate() { python3 -c 'import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))' "$1" "$R/events/schema/event.schema.json" 2>/dev/null; }
