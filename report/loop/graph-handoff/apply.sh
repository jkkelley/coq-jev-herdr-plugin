#!/usr/bin/env bash
# apply.sh - the graph half of WO-20261011-616c, ready to apply by someone whose role may write graph/ (a worker may not).
#   bash report/loop/graph-handoff/apply.sh [--repo DIR]     default: the repository this file is in
# It (1) adds graph/config/component-runbook-grandfathered.json, (2) patches graph/bin/graph.sh so `check` fails a Component
# with no defined_in edge to a RUN node unless it is on that closed list, (3) adds the nodes CMP-factory-board and RUN-factory-board
# with the edge, (4) regenerates graph/INDEX.md and GRAPH.mmd, (5) runs `graph.sh check`. Then delete this directory and move
# 08-graph.test.sh to report/loop/tests/cases/. Exit: 0 ok, 3 a step failed.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
[ "${1:-}" != --repo ] || REPO=$(cd "$2" && pwd)
G=$REPO/graph/bin/graph.sh
mkdir -p "$REPO/graph/config"
cp "$HERE/component-runbook-grandfathered.json" "$REPO/graph/config/component-runbook-grandfathered.json"
patch -p0 -d "$REPO" --forward --quiet < "$HERE/graph.sh.patch" || { echo "apply: graph.sh.patch did not apply" >&2; exit 3; }
"$G" add --id RUN-factory-board --type Runbook --status proposed \
  --title "report/loop/RUNBOOK.md: set up the factory board on a repository by editing report/loop/config/board.json, run loop.sh watch in a labelled pane, serve out_dir at /board" \
  --schema report/loop/config/board.schema.json --data report/loop/config/board.json \
  --edge depends_on:CMP-bearings-tool
"$G" add --id CMP-factory-board --type Component --status proposed \
  --title "report/loop: the factory board, loop.sh collect derives one entry from records, tickets, roles, routes and herdr panes, render and watch draw it, bearings serves it at /board" \
  --schema report/loop/schema/loop.schema.json --data report/loop/tests/fixtures/design-iteration-5.json \
  --edge defined_in:RUN-factory-board --edge depends_on:CMP-bearings-tool
"$G" index
"$G" check
