#!/usr/bin/env bash
# 08 - the graph rule: a Component node without a defined_in edge to a RUN node fails graph.sh check (AC-H6), and the board's own
# Component has that edge. Each case works on a copy of graph/ beside symlinks to everything else, so the schemas and data paths
# the nodes attach still resolve and nothing in the repository is written.
# In tests/cases the library is ../lib; while this file still sits in graph-handoff/ it is ../tests/lib.
L="$(dirname "$0")/../lib"; [ -f "$L/assert.sh" ] || L="$(dirname "$0")/../tests/lib"
. "$L/assert.sh"
R="$W/repo"; G="$R/graph/bin/graph.sh"; N="$R/graph/nodes"
fresh() { rm -rf "$R"; mkdir -p "$R"; cp -r "$REPO_ROOT/graph" "$R/graph"; for e in "$REPO_ROOT"/*; do [ "$(basename "$e")" = graph ] || ln -s "$e" "$R/$(basename "$e")"; done; }
node() { printf '{"id":"%s","type":"Component","title":"t","status":"draft","text":"","sources":[],"edges":%s,"created":"2026-10-12T00:00Z","updated":"2026-10-11T00:00Z"}\n' "$1" "$2" > "$N/$1.json"; }

fresh
t "the graph as committed passes check" "$G" check
has "and says how many nodes" "$W/.out" 'graph ok: [0-9]+ nodes'
eq "the board's Component is defined_in the board's runbook" "RUN-factory-board" "$(jq -r '.edges[] | select(.kind == "defined_in") | .to' "$N/CMP-factory-board.json")"
eq "the runbook node is a Runbook" "Runbook" "$(jq -r .type "$N/RUN-factory-board.json")"

# AC-H6: remove the edge and check fails, naming the Component.
jq '.edges |= map(select(.kind != "defined_in"))' "$N/CMP-factory-board.json" > "$W/n.json" && mv "$W/n.json" "$N/CMP-factory-board.json"
expect_exit 3 "removing the defined_in edge fails check" "$G" check
has "and names the Component" "$W/.out" 'CMP-factory-board: a Component needs a defined_in edge to a RUN node'

fresh
node CMP-new-thing '[]'
expect_exit 3 "a new Component with no edge fails" "$G" check
has "and names it" "$W/.out" 'CMP-new-thing: a Component needs a defined_in edge'
node CMP-new-thing '[{"kind":"defined_in","to":"RUN-factory-board"}]'
t "the same Component with a defined_in edge to a RUN node passes" "$G" check
node CMP-new-thing '[{"kind":"defined_in","to":"DEC-functional-style"}]'
expect_exit 3 "a defined_in edge to something that is not a RUN node does not count" "$G" check

# The grandfather list is closed: a listed Component that gains the edge has to leave it; a listed id must be a Component.
fresh
jq '.edges += [{"kind":"defined_in","to":"RUN-factory-board"}]' "$N/CMP-queue.json" > "$W/n.json" && mv "$W/n.json" "$N/CMP-queue.json"
expect_exit 3 "a grandfathered Component that gained its edge must leave the list" "$G" check
has "and the message says which" "$W/.out" 'CMP-queue: has its defined_in edge now'
fresh
jq '.components += ["CMP-no-such-thing"]' "$R/graph/config/component-runbook-grandfathered.json" > "$W/n.json" && mv "$W/n.json" "$R/graph/config/component-runbook-grandfathered.json"
expect_exit 3 "a listed id that is no Component node fails" "$G" check
fresh
node CMP-new-thing '[]'
jq '.components += ["CMP-new-thing"]' "$R/graph/config/component-runbook-grandfathered.json" > "$W/n.json" && mv "$W/n.json" "$R/graph/config/component-runbook-grandfathered.json"
jq '.created = "2026-10-12T00:00Z"' "$N/CMP-new-thing.json" > "$W/n.json" && mv "$W/n.json" "$N/CMP-new-thing.json"
expect_exit 3 "a Component created after the rule cannot join the list" "$G" check
has "and the message says why" "$W/.out" 'CMP-new-thing: created after the rule'
eq "the list holds the 19 Components that predate the rule" "19" "$(jq -r '.components | length' "$REPO_ROOT/graph/config/component-runbook-grandfathered.json")"
done_case
