#!/usr/bin/env bash
# loop.sh - the factory board (WO-20261011-616c): one data entry drawn as the owner-locked page (report/loop/design).
#   loop.sh collect [--root DIR] [--now UTC] [--number N] [--panes FILE | --no-panes] [--live FILE | --no-live] [--out FILE]
#                                             derive the entry from events, tickets, roles, routes, the herdr pane list and the
#                                             open pull requests, ticket branches and belt file; validate it; print it (or write --out). No value is typed in.
#   loop.sh validate FILE                     FILE against schema/loop.schema.json, plus the cross-checks a schema cannot say, and exit 3 naming
#                                             every ticket the entry lists as stale (in-progress with no branch and no pull request)
#   loop.sh render [--in FILE] [--out DIR]    validate, then write DIR/data.json and DIR/index.html, each atomically
#                                             (--in default: DIR/data.json; --out default: out_dir from config/board.json)
#   loop.sh watch [--out DIR] [--iterations N] [--sleep S] [collect's --root --now --panes --no-panes]
#                                             collect every watch_seconds and rewrite DIR only when the entry changed apart from
#                                             `at` and `number`; run it in a labelled herdr pane (monitors.sh take), never detached
# Views: loop.sh --view NAME VERB ... reads config/NAME.json instead of config/board.json. The config's `view` key names how collect
#   derives the entry: absent is the factory board above, `blueprint` is the system design from graph/ and work-orders/
#   (WO-20261011-ceea, lib/blueprint). Validate, render and watch are the same for every view, so a view is a config and a collect,
#   never a second renderer.
# Env: LOOP_CONFIG overrides the config file (and --view), LOOP_ROOT the tree collect reads, LOOP_PANES_FILE a saved herdr pane list,
#   LOOP_LIVE_FILE a saved {prs, branches} (the tests; the board otherwise asks gh and git).
# Exit: 0 ok, 2 usage, 3 validation, 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CONFIG=${LOOP_CONFIG:-$HERE/config/board.json}
SCHEMA=$HERE/schema/loop.schema.json
TEMPLATE=$HERE/assets/template.html

die() { local c=$1; shift; printf 'loop: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
command -v python3 >/dev/null || die 4 "python3 with jsonschema is required"
usage() { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }

# schema_check INSTANCE SCHEMA: exit 3 with the first violation on stderr.
schema_check() {
  python3 - "$1" "$2" <<'PY' || return 3
import json, sys
try:
    import jsonschema
except ImportError:
    print("loop: python3 jsonschema is not installed; the entry cannot be validated", file=sys.stderr)
    sys.exit(3)
try:
    jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))
except (OSError, ValueError) as e:
    print(f"loop: cannot read {sys.argv[1]} or {sys.argv[2]}: {e}", file=sys.stderr)
    sys.exit(3)
except jsonschema.ValidationError as e:
    path = "/".join(str(p) for p in e.absolute_path) or "(root)"
    print(f"loop: {sys.argv[1]}: {path}: {e.message[:300]}", file=sys.stderr)
    sys.exit(3)
PY
}

# view_of: the view the config names; a config with no `view` key is the factory board.
view_of() { jq -r '.view // "board"' "$CONFIG" 2>/dev/null || echo board; }

# config_check: the config against its schema, and the one rule a schema cannot say: a record is drawn within
# poll_seconds + watch_seconds, and AC-H3 promises 30.
config_check() {
  # The config's schema is the tool's, found beside loop.sh and not beside whichever config LOOP_CONFIG names. The view picks it.
  local schema=$HERE/config/board.schema.json
  [ "$(view_of)" != blueprint ] || schema=$HERE/config/blueprint.schema.json
  schema_check "$CONFIG" "$schema" || return 3
  jq -e '.poll_seconds + .watch_seconds <= 30' "$CONFIG" >/dev/null \
    || { printf 'loop: %s: poll_seconds + watch_seconds must be 30 or less\n' "$CONFIG" >&2; return 3; }
}

# validate FILE: the entry against the schema, then station ids unique, every reference (here, waiting, a line's
# states, a kickback end) naming a station, line ids unique.
validate() {
  [ -f "$1" ] || die 4 "no entry at $1"
  schema_check "$1" "$SCHEMA" || exit 3
  local bad
  bad=$(jq -r '
    ([.stations[].id]) as $ids
    | [ (if ($ids | length) != ($ids | unique | length) then "station ids are not unique" else empty end),
        (if ([.lines[].id] | length) != ([.lines[].id] | unique | length) then "line ids are not unique" else empty end),
        (.kickbacks[] | select(([.from, .to] - $ids) | length > 0) | "kickback \(.from) to \(.to) names no station"),
        (.lines[] | . as $l
          | (select($l.here != null and (($ids | index($l.here)) == null)) | "line \($l.id): here \($l.here) names no station"),
            (select($l.waiting != null and (($ids | index($l.waiting)) == null)) | "line \($l.id): waiting \($l.waiting) names no station"),
            (($l.st | keys) - $ids | map("line \($l.id): state for \(.) names no station") | .[]))
      ] | .[]' "$1")
  [ -z "$bad" ] || { printf 'loop: %s: %s\n' "$1" "$bad" >&2; exit 3; }
}

# check_stale FILE: exit 3 naming every ticket the entry lists as stale. Only the verb calls it: render and watch draw the page
# with the stale tickets on it (the headline says how many) rather than going dark, and the repository's tests and lint fail on one.
check_stale() {
  local bad
  bad=$(jq -r '(.stale // []) | map(. + " is in-progress with no branch on origin and no open pull request") | .[]' "$1")
  [ -z "$bad" ] || { printf 'loop: %s: %s\n' "$1" "$bad" >&2; exit 3; }
}

# splice DATAFILE TEMPLATE: the template with @@DATA@@ replaced by the one-line JSON in DATAFILE. awk reads both files, so the
# data is never an argument or an environment value (a long entry would pass the size limit of either) and no character in
# it is special to the substitution.
splice() { awk 'FNR == NR { d = d $0; next } { i = index($0, "@@DATA@@"); if (i) print substr($0, 1, i - 1) d substr($0, i + 8); else print }' "$1" "$2"; }

cmd_render() {
  local in="" out="" tmp
  while [ $# -gt 0 ]; do case $1 in
    --in) in=${2:-}; shift 2 ;;
    --out) out=${2:-}; shift 2 ;;
    *) usage ;;
  esac; done
  config_check || exit 3
  [ -n "$out" ] || out=$ROOT/$(jq -er .out_dir "$CONFIG")
  [ -n "$in" ] || in=$out/data.json
  validate "$in"
  mkdir -p "$out" || die 4 "cannot create $out"
  tmp=$(mktemp -d "$out/.render.XXXXXX") || die 4 "cannot write in $out"
  # `<` is written as < so no string in the data can close the script element; it is still the same JSON.
  jq -c . "$in" | sed 's/</\\u003c/g' > "$tmp/data.line"
  splice "$tmp/data.line" "$TEMPLATE" > "$tmp/index.html"
  jq . "$in" > "$tmp/data.json"
  mv "$tmp/index.html" "$out/index.html" && mv "$tmp/data.json" "$out/data.json" || die 4 "cannot place the page in $out"
  rm -rf "$tmp"
  printf 'rendered %s\n' "$out/index.html"
}

# --- collect: every value from the records, the ticket files and the herdr pane list ---

# panes_json FILE: {ok, panes:[{pane_id, label}]}. From FILE when given (the tests, and a pane list saved for a bug report);
# otherwise from herdr, naming the session as seat-lib.sh does, and {ok:false} when herdr is not there or does not answer: the
# board then says its panes are unavailable and trusts the seat records alone instead of hanging or inventing a pane list.
panes_json() {
  local file=$1 session label ws herdr_cfg
  if [ "$file" = none ]; then echo '{"ok":false,"panes":[]}'; return 0; fi
  if [ -n "$file" ]; then
    jq '{ok: true, panes: [(.result.panes // [])[] | {pane_id, label: (.label // "")}]}' "$file" || return 3
    return 0
  fi
  herdr_cfg=$ROOT/$(jq -er .inputs.herdr_config "$CONFIG")
  if ! command -v herdr >/dev/null || [ ! -f "$herdr_cfg" ]; then echo '{"ok":false,"panes":[]}'; return 0; fi
  session=${COQ_HERDR_SESSION:-$(jq -r .session "$herdr_cfg")}; label=$(jq -r .workspace_label "$herdr_cfg")
  # The same environment seat-lib.sh's sl_h uses: HERDR_PANE_ID and its siblings are unset so --current can never leak in.
  hq() { timeout 10 env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$session" "$@" 2>/dev/null; }
  ws=$(hq workspace list | jq -r --arg l "$label" 'first((.result.workspaces // [])[] | select(.label == $l) | .workspace_id) // empty' 2>/dev/null) || ws=""
  if [ -z "$ws" ]; then echo '{"ok":false,"panes":[]}'; return 0; fi
  hq pane list --workspace "$ws" | jq '{ok: true, panes: [(.result.panes // [])[] | {pane_id, label: (.label // "")}]}' 2>/dev/null || echo '{"ok":false,"panes":[]}'
}

# live_json FILE: {ok, prs:[{number, headRefName, title}], branches:[name]}. From FILE when given (the tests), {ok:false} for `none`,
# otherwise the open pull requests from gh and the ticket branches from origin, and {ok:false} when either does not answer: the board
# then promotes nothing and calls only a ticket with no branch at all stale, instead of hanging or inventing a pull request.
live_json() {
  local file=$1 prs br
  if [ "$file" = none ]; then echo '{"ok":false,"prs":[],"branches":[]}'; return 0; fi
  if [ -n "$file" ]; then jq '{ok: true, prs: (.prs // []), branches: (.branches // [])}' "$file" || return 3; return 0; fi
  if ! command -v gh >/dev/null; then echo '{"ok":false,"prs":[],"branches":[]}'; return 0; fi
  prs=$(cd "$ROOT" && timeout 20 gh pr list --state open --limit 200 --json number,headRefName,title 2>/dev/null) || prs=""
  br=$(git -C "$ROOT" ls-remote --heads origin 2>/dev/null | sed -n 's#.*refs/heads/##p' | jq -R . | jq -s .) || br=""
  if [ -z "$prs" ] || [ -z "$br" ] || [ "$br" = "[]" ]; then echo '{"ok":false,"prs":[],"branches":[]}'; return 0; fi
  jq -n --argjson p "$prs" --argjson b "$br" '{ok: true, prs: $p, branches: $b}'
}

# belt_file ROOT: the route runner's belt file, found the way route.sh finds it: runner.json's state_dir plus /belt. The config key
# names runner.json with ${repo}; state_dir may say ${repo} or ${tree:NAME} (the state root, bin/state-root.sh).
belt_file() {
  local root=$1 rc sd t
  rc=$(jq -r '.inputs.runner_config' "$CONFIG"); rc=${rc//\$\{repo\}/$root}
  sd=$(jq -r '.state_dir // empty' "$rc" 2>/dev/null) || sd=""
  [ -n "$sd" ] || return 1
  sd=${sd//\$\{repo\}/$root}
  if [[ $sd =~ \$\{tree:([a-z]+)\} ]]; then
    t=$("$ROOT/bin/state-root.sh" tree "${BASH_REMATCH[1]}") || return 1
    sd=${sd//\$\{tree:${BASH_REMATCH[1]}\}/$t}
  fi
  printf '%s/belt\n' "$sd"
}

# collect_blueprint ROOT NOW NUMBER OUT: the blueprint view's collect (WO-20261011-ceea). The impure reads are lib/blueprint/gather.sh,
# every derivation is a pure jq file beside it, and the entry is the same shape the board draws, so validate and render are shared.
collect_blueprint() {
  local root=$1 now=$2 number=$3 out=$4 t L=$HERE/lib/blueprint mmd
  # shellcheck source=lib/blueprint/gather.sh
  . "$L/gather.sh"
  t=$(mktemp -d) || die 4 "no scratch directory"
  # shellcheck disable=SC2064 # $t is expanded now on purpose: the trap must remove this run's directory
  trap "rm -rf '$t'" EXIT
  mmd=$root/$(jq -r .inputs.graph_mermaid "$CONFIG")
  [ -f "$mmd" ] || die 4 "no mermaid graph at $(jq -r .inputs.graph_mermaid "$CONFIG")"
  bp_nodes "$root/$(jq -r .inputs.graph_nodes_dir "$CONFIG")" > "$t/nodes.json" || die 4 "cannot read the graph nodes"
  bp_tickets "$root/$(jq -r .inputs.work_orders_dir "$CONFIG")" | jq -f "$L/tickets.jq" > "$t/tickets.json" || die 3 "a ticket's frontmatter is not valid JSON"
  jq -f "$L/components.jq" "$t/nodes.json" > "$t/components.json" || die 3 "the graph nodes could not be read as components"
  jq -f "$L/decisions.jq" "$t/nodes.json" > "$t/decisions.json" || die 3 "the graph nodes could not be read as decisions"
  jq -n --slurpfile c "$t/components.json" --slurpfile k "$t/tickets.json" '{components: $c[0], tickets: $k[0]}' | jq -f "$L/state.jq" > "$t/state.json" || die 3 "component states could not be derived"
  jq -n -f "$L/entry.jq" --slurpfile cfg_f "$CONFIG" --slurpfile comps_f "$t/state.json" --slurpfile decs_f "$t/decisions.json" --slurpfile tickets_f "$t/tickets.json" \
    --rawfile mermaid "$mmd" --argjson nodes "$(jq length "$t/nodes.json")" --arg now "$now" --argjson number "$number" > "$t/entry.json" || die 3 "the entry could not be derived (see above)"
  validate "$t/entry.json"
  if [ -n "$out" ]; then mkdir -p "$(dirname "$out")" && mv "$t/entry.json" "$out" || die 4 "cannot write $out"; else cat "$t/entry.json"; fi
}

# cmd_collect [--root DIR] [--now UTC] [--number N] [--panes FILE | --no-panes] [--out FILE]
cmd_collect() {
  local root=${LOOP_ROOT:-$ROOT} now="" number=1 panes_file=${LOOP_PANES_FILE:-} live_file=${LOOP_LIVE_FILE:-} out="" t cutoff now_epoch mtime age max days bf
  while [ $# -gt 0 ]; do case $1 in
    --root) root=${2:-}; shift 2 ;;
    --now) now=${2:-}; shift 2 ;;
    --number) number=${2:-}; shift 2 ;;
    --panes) panes_file=${2:-}; shift 2 ;;
    --no-panes) panes_file=none; shift ;;
    --live) live_file=${2:-}; shift 2 ;;
    --no-live) live_file=none; shift ;;
    --out) out=${2:-}; shift 2 ;;
    *) usage ;;
  esac; done
  [[ $number =~ ^[0-9]+$ ]] && [ "$number" -ge 1 ] || die 2 "--number must be a positive integer"
  config_check || exit 3
  [ -n "$now" ] || now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  now_epoch=$(date -u -d "$now" +%s) || die 2 "--now must be a UTC time like 2026-10-11T14:21:00Z"
  if [ "$(view_of)" = blueprint ]; then collect_blueprint "$root" "$now" "$number" "$out"; return $?; fi
  t=$(mktemp -d) || die 4 "no scratch directory"
  # shellcheck disable=SC2064 # $t is expanded now on purpose: the trap must remove this run's directory whatever $t is later
  trap "rm -rf '$t'" EXIT
  days=$(jq -r .inputs.events_days "$CONFIG"); max=$(jq -r .inputs.belt_max_age_seconds "$CONFIG")
  cutoff=$(date -u -d "$now - $days days" +%Y%m%d)
  # events: one file per record under YYYY/MM; the file name starts with the UTC date, so the window is a name comparison.
  find "$root/$(jq -r .inputs.events_dir "$CONFIG")" -type f -path '*/20??/??/*.json' 2>/dev/null | sort \
    | awk -F/ -v c="$cutoff" 'substr($NF, 1, 8) >= c' | xargs -d '\n' -r cat | jq -s . > "$t/events.json" || die 4 "cannot read the event records"
  # tickets: the JSON frontmatter between the first two --- lines of every WO-*.md, in every subdirectory (archive included:
  # a merged ticket is how the board knows its bar is full).
  find "$root/$(jq -r .inputs.work_orders_dir "$CONFIG")" -type f -name 'WO-*.md' 2>/dev/null | sort \
    | xargs -d '\n' -r awk 'FNR == 1 { n = 0 } /^---$/ { n++; next } n == 1 { print }' \
    | jq -s 'map({id, title, status, parent, branch, pr, closed})' > "$t/main-tickets.json" || die 3 "a ticket's frontmatter is not valid JSON"
  live_json "$live_file" > "$t/live.json" || die 3 "cannot read the live line"
  jq -n -f "$HERE/lib/live.jq" --slurpfile tickets_f "$t/main-tickets.json" --slurpfile live_f "$t/live.json" > "$t/merged.json" || die 3 "the live line could not be merged into the tickets"
  jq .tickets "$t/merged.json" > "$t/tickets.json"; jq .stale "$t/merged.json" > "$t/stale.json"
  jq -s . "$root/$(jq -r .inputs.roles_dir "$CONFIG")"/*.json > "$t/roles.json" || die 4 "cannot read the role files"
  jq . "$root/$(jq -r .inputs.routes "$CONFIG")" > "$t/routes.json" || die 4 "cannot read the routes table"
  find "$root/$(jq -r .inputs.playbooks_dir "$CONFIG")" -maxdepth 1 -name '*.md' 2>/dev/null | sed 's#.*/##; s#\.md$##' | sort | jq -R . | jq -s . > "$t/playbooks.json"
  # BREADCRUMB 2026-10-13 - WO-20261013-89c7. What broke: this read inputs.belt_state, factory/state/runner.json, which route.sh never
  #   writes (it touches $STATE/belt, route.sh belt_touch), so the belt always read stopped. Why this fix: the belt file comes from
  #   runner.json's state_dir, the one definition route.sh uses, so it follows the state root when A2 moves it. Rejected: a second
  #   path in board.json (it drifted once already). Cost: a missing or unreadable runner.json reads as an absent belt.
  mtime=""; bf=$(belt_file "$root") && mtime=$(stat -c %Y "$bf" 2>/dev/null || true)
  if [ -n "$mtime" ]; then age=$((now_epoch - mtime)); jq -n --argjson age "$age" --argjson max "$max" '{running: ($age <= $max), age: $age}' > "$t/belt.json"
  else echo '{"running":false,"age":null}' > "$t/belt.json"; fi
  panes_json "$panes_file" > "$t/panes.json" || die 3 "cannot read the pane list"
  jq -n -f "$HERE/lib/collect.jq" \
    --slurpfile cfg_f "$CONFIG" --slurpfile events_f "$t/events.json" --slurpfile tickets_f "$t/tickets.json" --slurpfile roles_f "$t/roles.json" \
    --slurpfile routes_f "$t/routes.json" --slurpfile playbooks_f "$t/playbooks.json" --slurpfile panes_f "$t/panes.json" --slurpfile belt_f "$t/belt.json" --slurpfile stale_f "$t/stale.json" --slurpfile live_f "$t/live.json" \
    --arg now "$now" --argjson number "$number" > "$t/entry.json" || die 3 "the entry could not be derived (see above)"
  validate "$t/entry.json"
  if [ -n "$out" ]; then mkdir -p "$(dirname "$out")" && mv "$t/entry.json" "$out" || die 4 "cannot write $out"; else cat "$t/entry.json"; fi
}

# --- watch: keep the page current, and touch nothing when nothing changed ---

# cmd_watch [--out DIR] [--iterations N] [--sleep S] [--root DIR] [--now UTC] [--panes FILE | --no-panes]
# One pass = collect into a scratch file, compare it with DIR/data.json ignoring `at` and `number`, and only when it differs
# render it into DIR (render places data.json and index.html atomically) and then record the new build number in DIR/.watch.json.
# A pass that finds nothing changed leaves every file under DIR alone, mtime included: that is what lets the page's own poll, a monitor
# and a reader's eye trust "the file moved" to mean "the floor moved".
# --iterations N stops after N passes (0, the default, never stops) and --sleep S replaces watch_seconds: both are the seam the
# tests use, so no test needs a background process or a real ten-second wait. A pass that cannot collect (a ticket caught
# half-written, herdr slow) says so on stderr, keeps the last good page, and the loop goes on; a finite run exits with the
# last pass's status.
cmd_watch() {
  local out="" iterations=0 sleep_s="" pass=0 rc=0 last=0 passthrough=() cur_number t cand a b state
  while [ $# -gt 0 ]; do case $1 in
    --out) out=${2:-}; shift 2 ;;
    --iterations) iterations=${2:-}; shift 2 ;;
    --sleep) sleep_s=${2:-}; shift 2 ;;
    --root|--now|--panes|--live) passthrough+=("$1" "${2:-}"); shift 2 ;;
    --no-panes|--no-live) passthrough+=("$1"); shift ;;
    *) usage ;;
  esac; done
  [[ $iterations =~ ^[0-9]+$ ]] || die 2 "--iterations must be a number (0 runs until stopped)"
  [ -z "$sleep_s" ] || [[ $sleep_s =~ ^[0-9]+$ ]] || die 2 "--sleep must be whole seconds"
  config_check || exit 3
  [ -n "$out" ] || out=$ROOT/$(jq -er .out_dir "$CONFIG")
  mkdir -p "$out" || die 4 "cannot create $out"
  state=$out/.watch.json
  t=$(mktemp -d "$out/.watch.XXXXXX") || die 4 "cannot write in $out"
  # shellcheck disable=SC2064 # $t is expanded now on purpose
  trap "rm -rf '$t'" EXIT
  printf 'watch: %s every %ss into %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${sleep_s:-$(jq -r .watch_seconds "$CONFIG")}" "$out" >&2
  while :; do
    pass=$((pass + 1)); rc=0
    # The number is the count of builds: the one the last build recorded (or the page's own, if the record is gone), plus one.
    cur_number=$(jq -r '.number // empty' "$state" 2>/dev/null || true)
    [ -n "$cur_number" ] || cur_number=$(jq -r '.number // 0' "$out/data.json" 2>/dev/null || echo 0)
    cand=$t/entry.json
    # In a subshell: collect ends in `exit`, and an exit there must end the pass, not the loop.
    if ( cmd_collect "${passthrough[@]}" --number "$((cur_number + 1))" --out "$cand" ) 2>"$t/err"; then
      a=$(jq -S -c 'del(.at, .number)' "$cand"); b=$(jq -S -c 'del(.at, .number)' "$out/data.json" 2>/dev/null || true)
      if [ "$a" != "$b" ] || [ ! -f "$out/index.html" ]; then
        if (cmd_render --in "$cand" --out "$out" >/dev/null) 2>"$t/err"; then
          printf '{"number":%s}\n' "$((cur_number + 1))" > "$t/state" && mv "$t/state" "$state" || rc=4
          printf 'watch: %s build %s written (%s lines)\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$((cur_number + 1))" "$(jq '.lines | length' "$cand")" >&2
        else rc=$?; fi
      fi
    else rc=$?; fi
    if [ "$rc" != 0 ]; then printf 'watch: %s pass %s failed (%s), keeping the last page\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$pass" "$rc" >&2; sed 's/^/watch:   /' "$t/err" >&2; fi
    last=$rc
    [ "$iterations" = 0 ] || [ "$pass" -lt "$iterations" ] || break
    sleep "${sleep_s:-$(jq -r .watch_seconds "$CONFIG")}"
  done
  return "$last"
}

if [ "${1:-}" = --view ]; then
  [[ ${2:-} =~ ^[a-z][a-z0-9-]*$ ]] || usage
  [ -n "${LOOP_CONFIG:-}" ] || CONFIG=$HERE/config/$2.json
  [ -f "$CONFIG" ] || die 4 "no config for the view $2 at $CONFIG"
  shift 2
fi
verb=${1:-}; [ $# -eq 0 ] || shift
case $verb in
  validate) [ $# -eq 1 ] || usage; validate "$1"; check_stale "$1" ;;
  render) cmd_render "$@" ;;
  collect) cmd_collect "$@" ;;
  watch) cmd_watch "$@" ;;
  *) usage ;;
esac
