# decisions.jq - the locked Decision nodes of the graph (WO-20261011-ceea). Pure: nodes in, JSON out.
#   jq -f decisions.jq nodes.json           nodes.json is an array of graph nodes (graph/nodes/*.json slurped)
# Output: [{id, title}] sorted by id: every Decision whose status is locked. A draft, proposed or superseded one is not a decision yet.

map(select(.type == "Decision" and .status == "locked") | {id, title}) | sort_by(.id)
