#!/usr/bin/env bash
# factory/tests/lib/world.sh - one throwaway world per case: only the pieces the runner touches, copied from the repo, plus a
# stub herdr first on PATH that appends its argv to $W/herdr.log and exits 1 when $W/herdr.fail exists, and a stub seat.sh in the
# copy (herdr/bin/seat.sh, what runner.json's seat_bin names) that appends its argv to $W/seat.log. Both also append one tagged line
# to $W/order.log, so a case can prove which came first. The stub seat.sh behaves like the real one where the runner can see it:
#   --ticket T --role R   brings seat <R>-<t> up (name "merger" for the merger, the label in roles/merger.json), writes a seat.up 100
#                         record, and on a seat already up prints "left as is" and writes nothing
#   --down NAME           writes a seat.down 100 record for NAME, once; a second --down prints "already down" and writes nothing
#   $W/seat.fail          its text is the refusal: stderr, exit 3, nothing written   $W/seat.slow  writes the belt's mtime (ns) to $W/seat.belt, then sleeps a second
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
ev() { "__R__/events/bin/event.sh" add --code 100 --seat "$1" --kind "$2" ${3:+--ticket "$3"} --note "stub seat.sh"; }
case "$1" in
  --down) name=$2; [ ! -e "__W__/seats/$name.down" ] || { echo "$name: already down since stub"; exit 0; }
    : > "__W__/seats/$name.down"; t=$(sed -n 's/.*\(wo-[0-9]\{8\}-[0-9a-f]\{4\}\)$/\1/p' <<<"$name" | tr a-z A-Z)
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
