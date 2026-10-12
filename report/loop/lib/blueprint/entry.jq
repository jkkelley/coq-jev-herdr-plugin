# entry.jq - the blueprint as one board entry (WO-20261011-ceea). Pure: the collectors' outputs and the view config in, one entry out.
#   jq -n -f entry.jq --slurpfile cfg_f CONFIG --slurpfile comps_f state.json --slurpfile decs_f decisions.json
#         --slurpfile tickets_f tickets.json --rawfile mermaid GRAPH.mmd --argjson nodes N --arg now UTC --argjson number N
# Output: an entry for report/loop/schema/loop.schema.json, drawn by the same template as the factory board. Nothing here is typed in.
#
# How the board's words come out of the graph and the tickets:
#   a line      one Component (CMP node). Its badge is C01.. in id order; its name is the node id, its sub line the node title.
#   a station   one gate the Component passes, in this order: node (the graph node is locked), decision (every decided_by Decision
#               is locked; blocked while one is not), runbook (a RUN node defines it), work (tickets: done, in flight, or none).
#   line status done is live, in flight is building, coming up is queued (state.jq decides, its header holds the rule).
#   work here   the station that needs work next: work while a ticket is open, else the first gate that is not live.
#   a belt      runs for a done or in-flight Component and is stopped for one that is coming up.
#   the board   the tickets: open ones first (in progress, in review, ready, draft), then the newest board_done_max done ones.
#   the legend  every locked Decision, id and title.
# A free-text value is scrubbed of absolute paths and capped, as collect.jq does, so no path reaches the page whatever a title says.

($cfg_f[0]) as $cfg | ($comps_f[0]) as $comps | ($decs_f[0]) as $decs | ($tickets_f[0]) as $tk
| def clean: gsub("(?<p>^|[\\s\"'(=:])/[A-Za-z0-9._~-]+/[^\\s\"')]*"; "\(.p)<path>") | .[0:380];
  def short($n): if length > $n then .[0:$n - 1] + "…" else . end;
  def pad2: tostring | if length < 2 then "0" + . else . end;
  def lstat: {"done": "live", "in-flight": "building", "coming-up": "queued"}[.];
  def sta($id): first($cfg.stations[] | select(.id == $id));
  def decision_part: if .status == "locked" then ["ok", "\(.id) - \(.title | short(80))"] else ["bad", "\(.id) is \(.status), not locked"] end;
  def ticket_part: [(if .status == "done" then "ok" else "todo" end), "\(.id) - \(.title | short(80))"];
  def work_parts($c):
    if ($c.tickets | length) == 0 then [if $c.state == "done" then ["ok", "locked in the graph; no ticket names it"] else ["todo", "no ticket names this component"] end]
    else ($c.tickets | sort_by(.status == "done", .id)) as $t
      | [$t[:6][] | ticket_part] + (if ($t | length) > 6 then [["todo", "+\(($t | length) - 6) more"]] else [] end)
    end;
  def gates($c):
    { node: { status: (if $c.status == "locked" then "live" else "queued" end),
              parts: [[(if $c.status == "locked" then "ok" else "todo" end), "graph node \($c.status)"]] },
      decision: (if ($c.decisions | length) == 0 then { status: "queued", parts: [["todo", "no decision recorded"]] }
                 else { status: (if all($c.decisions[]; .status == "locked") then "live" else "blocked" end), parts: [$c.decisions[:8][] | decision_part] } end),
      runbook: (if $c.runbook != null then { status: "live", parts: [["ok", "\($c.runbook.id) - \($c.runbook.title | short(80))"]] }
                else { status: "queued", parts: [["bad", "no runbook: add a RUN node with a defined_in edge"]] } end),
      work: { status: ($c.state | lstat), parts: work_parts($c) } };
  def line($c; $i):
    gates($c) as $g
    | ([($cfg.stations[].id) as $s | select($g[$s].status != "live") | $s] | first // null) as $next
    | { id: "C\($i + 1 | pad2)", name: $c.id, sub: ($c.title | clean), sim: false,
        status: ($c.state | lstat), belt: (if $c.state == "coming-up" then "stopped" else "live" end),
        here: (if $c.state == "in-flight" then "work" else $next end),
        st: $g };
  def step: if .status == "done" then 4 elif .status == "in-review" or (.pr != null and .status != "done") then 3 elif .status == "in-progress" then 2 elif .status == "ready" then 1 else 0 end;
  def rank: {"in-progress": 0, "in-review": 0, "ready": 1, "draft": 2}[.status] // 3;
  def row: { k: .id[-4:], ticket: .id, t: (.title | clean), sub: (.status + (if (.cmps | length) > 0 then " · " + (.cmps | join(", ")) else "" end)), step: step };

  ([$comps[] | select(.state == "done")] | length) as $nd
| ([$comps[] | select(.state == "in-flight")] | length) as $nf
| ([$comps[] | select(.state == "coming-up")] | length) as $nc
| ([$comps[] | select(.missing_runbook)] | length) as $nm
| ($tk | map(select(.status != "cancelled"))) as $live
| ([$live[] | select(.status != "done")] | sort_by(rank, .id)) as $open
| ([$live[] | select(.status == "done")] | sort_by(.closed // "", .id) | reverse | .[:$cfg.board_done_max]) as $fin
| { schema_version: "1.0.0", number: $number, at: $now, actor: $cfg.actor, state: "system design",
    headline: "\($comps | length) components: \($nd) done, \($nf) in flight, \($nc) coming up\(if $nm > 0 then ", \($nm) without a runbook" else "" end)",
    poll_seconds: $cfg.poll_seconds,
    title: $cfg.title, label: $cfg.label,
    stations: [$cfg.stations[] | {id, role, model, does, out}],
    kickbacks: [],
    lines: [range(0; $comps | length) as $i | line($comps[$i]; $i)],
    board_title: $cfg.board_title,
    board: [($open + $fin)[] | row],
    key: $cfg.key,
    legend_title: "\($cfg.legend_title) · \($decs | length)",
    legend_open: true,
    legend: ([$decs[] | [.id, (.title | clean)]] + $cfg.legend_notes),
    diagram: { title: $cfg.diagram_title, source: $mermaid },
    sources: "\($cfg.inputs.graph_nodes_dir): \($nodes) nodes · \($cfg.inputs.work_orders_dir): \($tk | length) tickets · \($cfg.inputs.graph_mermaid)" }
  + (if $cfg.links != null then {links: $cfg.links} else {} end)
