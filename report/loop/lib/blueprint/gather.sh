#!/usr/bin/env bash
# gather.sh - read the blueprint's two inputs off disk into the JSON the collectors take (WO-20261011-ceea). Sourced by loop.sh
# and by the tests, so the tests run the code the page is built with. These are the only impure steps; every .jq beside this file
# is a pure function of what these print.
#   bp_nodes GRAPH_NODES_DIR      every *.json in the directory, as one array
#   bp_tickets WORK_ORDERS_DIR    every WO-*.md under the directory (archive included), as an array of {fm, text}: the JSON
#                                 frontmatter between the first two --- lines, and the whole file
bp_nodes() { find "$1" -maxdepth 1 -type f -name '*.json' 2>/dev/null | sort | xargs -d '\n' -r cat | jq -s .; }
bp_tickets() {
  local f fm
  find "$1" -type f -name 'WO-*.md' 2>/dev/null | sort | while IFS= read -r f; do
    fm=$(awk 'FNR == 1 { n = 0 } /^---$/ { n++; next } n == 1 { print }' "$f" | jq -c .) || { printf 'gather: %s: the frontmatter is not valid JSON\n' "$f" >&2; exit 3; }
    jq -n --rawfile text "$f" --argjson fm "$fm" '{fm: $fm, text: $text}'
  done | jq -s .
}
