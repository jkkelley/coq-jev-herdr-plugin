#!/usr/bin/env bash
# 12 - the blueprint entry: loop.sh --view blueprint collect against the fixture graph and tickets, then render. Every assertion is on the
# entry the page is drawn from; nothing is typed in, so the fixture's words are the only source of any value checked here.
. "$(dirname "$0")/../lib/assert.sh"
R="$FIX/blueprint"
bp() { LOOP_ROOT="$R" "$LOOP" --view blueprint collect --now 2026-10-11T15:00:00Z "$@"; }
t "collect validates against the entry schema" bp --out "$W/entry.json"
q() { jq -e "$1" "$W/entry.json" >/dev/null 2>&1; }
RES() { if q "$2"; then pass "$1"; else flunk "$1 ($2)"; fi; }
RES "one line per non-superseded Component, badges C01.. in id order" '[.lines[] | "\(.id) \(.name)"] == ["C01 CMP-alpha","C02 CMP-beta","C03 CMP-delta","C04 CMP-epsilon","C05 CMP-gamma"]'
RES "the line's sub is the node title" '.lines[0].sub == "Alpha: built and documented"'
RES "four gates in the config's order" '[.stations[].id] == ["node","decision","runbook","work"]'
RES "line status follows the state: done live, in flight building, coming up queued" '[.lines[].status] == ["live","building","queued","building","live"]'
RES "a done Component's belt runs, a coming-up Component's is stopped" '[.lines[].belt] == ["live","live","stopped","live","live"]'
RES "node gate: locked is live, proposed is queued" '.lines[0].st.node.status == "live" and .lines[1].st.node.status == "queued"'
RES "decision gate: every decision locked is live" '.lines[0].st.decision.status == "live" and .lines[0].st.decision.parts[0][1] == "DEC-one - One is locked"'
RES "decision gate: a decision not locked blocks the gate and says which" '.lines[1].st.decision.status == "blocked" and (.lines[1].st.decision.parts | map(.[1]) | any(. == "DEC-two is proposed, not locked"))'
RES "decision gate: a decision with no node reads missing, not locked" '.lines[1].st.decision.parts | map(.[1]) | any(. == "DEC-gone is missing, not locked")'
RES "decision gate: none recorded is queued" '.lines[2].st.decision.status == "queued"'
RES "runbook gate: a RUN node is live and named" '.lines[0].st.runbook.status == "live" and .lines[0].st.runbook.parts[0][1] == "RUN-alpha - Alpha runbook"'
RES "runbook gate: none is queued and says so with a bad part" '.lines[1].st.runbook.status == "queued" and .lines[1].st.runbook.parts[0][0] == "bad"'
RES "work gate lists the tickets with id and full title" '.lines[1].st.work.parts[0] == ["todo","WO-20260101-0001 - Build CMP-beta"]'
RES "work gate with no ticket on a locked Component says so" '.lines[0].st.work.parts[0][1] == "locked in the graph; no ticket names it"'
RES "work is here while a ticket is open" '.lines[1].here == "work" and .lines[3].here == "work"'
RES "with no ticket open the first gate not live is next" '.lines[2].here == "node" and .lines[4].here == "node"'
RES "every gate live and no ticket open: nothing is next" '.lines[0].here == null'
RES "the board lists open tickets first, then done" '[.board[].ticket] == ["WO-20260101-0001","WO-20260101-0005","WO-20260101-0003","WO-20260101-0002"]'
RES "board steps follow status" '[.board[].step] == [2,3,0,4]'
RES "a cancelled ticket is not on the board" '[.board[].ticket] | index("WO-20260101-0004") == null'
RES "a board row names the Components its ticket names" '.board[0].sub == "in-progress · CMP-beta"'
RES "the legend is the locked decisions, then the config's notes" '.legend[0] == ["DEC-one","One is locked"] and .legend[1][0] == "DEC-three" and (.legend | length) == 4'
RES "a proposed decision is not in the legend" '[.legend[][0]] | index("DEC-two") == null'
RES "the headline counts what the lines say" '.headline == "5 components: 2 done, 2 in flight, 1 coming up, 3 without a runbook"'
RES "the diagram is the graph's mermaid, verbatim" '.diagram.source == "flowchart LR\n  CMP-alpha[\"CMP-alpha<br/>Alpha\"]\n  CMP-beta[\"CMP-beta<br/>Beta\"]\n  CMP-alpha --> CMP-beta\n"'
RES "the view's words come from the config" '.title == "System blueprint" and .label == "BLUEPRINT" and .links.node != null'
RES "the sources line counts nodes and tickets" '.sources | contains("13 nodes") and contains("5 tickets")'
RES "no board lane or kickback" '.kickbacks == []'
t "render writes the page and the data" "$LOOP" --view blueprint render --in "$W/entry.json" --out "$W/out"
has "the page carries the entry" "$W/out/index.html" 'CMP-epsilon'
has "the page loads data.json for its poll" "$W/out/index.html" 'data\.json'
# A free-text title with an absolute path must not reach the page.
mkdir -p "$W/root2"; cp -r "$R/graph" "$W/root2/"; cp -r "$R/work-orders" "$W/root2/"
jq '.title = "Alpha at /home/luna/secret/place"' "$R/graph/nodes/CMP-alpha.json" > "$W/root2/graph/nodes/CMP-alpha.json"
LOOP_ROOT="$W/root2" "$LOOP" --view blueprint collect --now 2026-10-11T15:00:00Z --out "$W/entry2.json" 2>/dev/null
eq "an absolute path in a title is scrubbed" "0" "$(grep -c '/home/luna' "$W/entry2.json")"
# An empty graph is a page, not a crash.
mkdir -p "$W/root3/graph/nodes" "$W/root3/work-orders"; : > "$W/root3/graph/GRAPH.mmd"
LOOP_ROOT="$W/root3" "$LOOP" --view blueprint collect --now 2026-10-11T15:00:00Z --out "$W/entry3.json" 2>"$W/err3"
eq "an empty graph still collects" "0 components: 0 done, 0 in flight, 0 coming up" "$(jq -r .headline "$W/entry3.json")"
done_case
