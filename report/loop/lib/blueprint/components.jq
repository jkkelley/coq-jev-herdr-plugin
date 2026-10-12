# components.jq - the Component nodes of the graph, each with its runbook and its decisions (WO-20261011-ceea). Pure: nodes in, JSON out.
#   jq -f components.jq nodes.json          nodes.json is an array of graph nodes (graph/nodes/*.json slurped)
# Output: [{id, title, status, runbook, decisions}] sorted by id, a superseded Component left out.
#   runbook    {id, title} of the Runbook node the Component is defined in, or null. Both directions count: the Component's own
#              `defined_in` edge to a Runbook node, and a Runbook node's `defined_in` edge to the Component (RUN-bearings-promote
#              is written that way round). The first by id wins when there are several.
#   decisions  one {id, status, title} per `decided_by` edge; a decision the graph has no node for reads status "missing".

. as $nodes
| ($nodes | map({key: .id, value: .}) | from_entries) as $by
| def runbooks($c):
    ( [$c.edges[]? | select(.kind == "defined_in") | .to | select(($by[.].type // "") == "Runbook")]
    + [$nodes[] | select(.type == "Runbook") | select(any(.edges[]?; .kind == "defined_in" and .to == $c.id)) | .id] ) | unique;
  $nodes
| map(select(.type == "Component" and .status != "superseded"))
| sort_by(.id)
| map(. as $c
    | runbooks($c) as $r
    | { id, title, status,
        runbook: (if ($r | length) > 0 then {id: $r[0], title: ($by[$r[0]].title // "")} else null end),
        decisions: [ $c.edges[]? | select(.kind == "decided_by") | .to as $d | {id: $d, status: ($by[$d].status // "missing"), title: ($by[$d].title // "")} ] })
