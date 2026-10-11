#!/usr/bin/env bash
# loop.sh - the factory board (WO-20261011-616c): one data entry drawn as the owner-locked page (report/loop/design).
#   loop.sh validate FILE                     FILE against schema/loop.schema.json, plus the cross-checks a schema cannot say
#   loop.sh render [--in FILE] [--out DIR]    validate, then write DIR/data.json and DIR/index.html, each atomically
#                                             (--in default: DIR/data.json; --out default: out_dir from config/board.json)
# Env: LOOP_CONFIG overrides config/board.json (the tests point it at a fixture).
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
usage() { sed -n '2,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }

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
except jsonschema.ValidationError as e:
    path = "/".join(str(p) for p in e.absolute_path) or "(root)"
    print(f"loop: {sys.argv[1]}: {path}: {e.message[:300]}", file=sys.stderr)
    sys.exit(3)
PY
}

# config_check: the config against its schema, and the one rule a schema cannot say: a record is drawn within
# poll_seconds + watch_seconds, and AC-H3 promises 30.
config_check() {
  schema_check "$CONFIG" "${CONFIG%.json}.schema.json" || return 3
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

verb=${1:-}; [ $# -eq 0 ] || shift
case $verb in
  validate) [ $# -eq 1 ] || usage; validate "$1" ;;
  render) cmd_render "$@" ;;
  *) usage ;;
esac
