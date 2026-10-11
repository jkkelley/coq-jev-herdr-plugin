#!/usr/bin/env bash
# run.sh - the SITREP renderer's suite (WO-20261011-3d78). Runs inside the lint image (python3 + jsonschema) via `make test`,
# or on any host that has both. Each check prints ok/FAIL; exit 1 if any failed.
#   case 1: the 003 entry renders the locked shape (title, phase strip, id chips, blocks, question, legend)
#   case 2: a ticket id with no legend title is refused with exit 3 and the message names the id
#   case 3: an entry that fails the schema is refused with exit 3 and the message names the path
#   case 4: [[kind:text]] and `code` render as pill and code; raw < in a cell is escaped
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; S="$HERE/.."; SITREP="$S/sitrep.sh"
ENTRY="$S/entries/2026/10/20261011-sitrep-003.json"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
ok() { printf '  ok   - %s\n' "$1"; }
bad() { printf '  FAIL - %s (got %s)\n' "$1" "${2:-?}"; fail=1; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "'$2' wanted '$3'"; fi; }
count() { grep -o "$1" "$2" | wc -l | tr -d ' '; }

echo "-- case 1: the 003 entry renders the locked shape"
"$SITREP" render "$ENTRY" --out "$T/003.html" 2>"$T/err"; check "render exits 0" "$?" 0
check "title is the SITREP number" "$(grep -c '<title>Qud Factory SITREP 003</title>' "$T/003.html")" 1
check "eyebrow carries UTC and the state" "$(grep -c 'SITREP 003 · 2026-10-11 13:30 UTC · architect wD3:p2 · HELD' "$T/003.html")" 1
check "six phases, one lit" "$(count "<small>" "$T/003.html")/$(count '<div class="ph now"' "$T/003.html")" "6/1"
check "phase grid is sized to the phases" "$(grep -c 'repeat(6, 1fr)' "$T/003.html")" 1
check "seven id chips on the board" "$(count '<td class="id">' "$T/003.html")" 15
check "three row blocks" "$(count '<section class="blk" data-s="risk">\|<section class="blk" data-s="hold">' "$T/003.html")" 4
check "question has three options and a rec pill" "$(count '<div class="opt">' "$T/003.html")/$(count '>rec<' "$T/003.html")" "3/1"
check "legend is folded" "$(grep -c '<details>' "$T/003.html")" 1
check "no placeholder survives" "$(grep -c '__[A-Z_]*__' "$T/003.html")" 0

echo "-- case 2: a ticket id with no legend title is refused"
python3 - "$ENTRY" "$T/nolegend.json" <<'PY'
import json, sys
e = json.load(open(sys.argv[1])); e["tickets"].append({"id": "beef", "what": "no legend", "state": "x", "kind": "plain"})
json.dump(e, open(sys.argv[2], "w"))
PY
"$SITREP" render "$T/nolegend.json" --out "$T/x.html" 2>"$T/err"; check "exit 3" "$?" 3
check "the refusal names the id" "$(grep -c 'ticket id beef has no legend title' "$T/err")" 1
check "nothing was written" "$([ -f "$T/x.html" ] && echo yes || echo no)" no

echo "-- case 3: an entry that fails the schema is refused"
python3 - "$ENTRY" "$T/dense.json" <<'PY'
import json, sys
e = json.load(open(sys.argv[1])); e["tickets"][0]["what"] = "x" * 49
json.dump(e, open(sys.argv[2], "w"))
PY
"$SITREP" render "$T/dense.json" --out "$T/y.html" 2>"$T/err"; check "exit 3" "$?" 3
check "the refusal names the path" "$(grep -c 'fails the schema at tickets/0/what' "$T/err")" 1

echo "-- case 4: cell markup"
python3 - "$ENTRY" "$T/markup.json" <<'PY'
import json, sys
e = json.load(open(sys.argv[1])); e["blocks"][0]["rows"][0] = ["Key", "[[risk:hot]] `a<b` <script>"]
json.dump(e, open(sys.argv[2], "w"))
PY
"$SITREP" render "$T/markup.json" --out "$T/m.html" 2>"$T/err"; check "render exits 0" "$?" 0
check "pill rendered" "$(grep -c '<span class="pill risk">hot</span>' "$T/m.html")" 1
check "code rendered with the < escaped" "$(grep -c '<code>a&lt;b</code>' "$T/m.html")" 1
check "raw script tag escaped" "$(grep -c '&lt;script&gt;' "$T/m.html")" 1

if [ "$fail" = 0 ]; then echo "sitrep tests: pass"; else echo "sitrep tests: FAIL"; exit 1; fi
