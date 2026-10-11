# collect.jq - every value on the factory board, derived (WO-20261011-616c). Nothing here is a hand-written status.
#   jq -n -f collect.jq --slurpfile cfg_f .. events_f tickets_f roles_f routes_f playbooks_f panes_f belt_f --arg now .. --argjson number ..
# Inputs: the board config; the event records of the last events_days; the ticket frontmatters; the role files; the routes
# table; the playbook names; the herdr pane list ({ok, panes}); the belt ({running, age}). Output: one entry, loop.schema.json.
#
# How the page's words come out of the records:
#   a record's kind     its own kind, or the "kind:" a seat wrote at the head of a note (event.sh has no factory kinds, so seats
#                       post kind note with "pr.opened: ..."), when that word is a kind routes.json or a role file knows.
#   where the work is   the route row the ticket's newest work record matches, first match wins, as the orchestrator reads it:
#                       the row's target station. A record no row matches is still with the station that emitted it.
#   by hand             a ticket with a PR in its frontmatter and no pr.opened record: the worker station says so, and the PR
#                       waits at the tester.
#   a seat is up        its newest record is not seat.down and, when the pane list is available, its pane is still in it.
#   the belt            the route runner's state file is no older than belt_max_age_seconds.

($cfg_f[0]) as $cfg | ($routes_f[0]) as $routes | ($roles_f[0]) as $roles | ($playbooks_f[0]) as $playbooks
| ($panes_f[0]) as $pn | ($pn.ok) as $panes_ok | ($pn.panes) as $panes | ($belt_f[0]) as $belt
| ($tickets_f[0]) as $tickets

# A free-text value from a record or a ticket: a leading-slash path is replaced and the length is capped, so no absolute path
# reaches the page whatever a seat wrote in a note.
| def clean: gsub("(?<p>^|[\\s\"'(=:])/[A-Za-z0-9._~-]+/[^\\s\"')]*"; "\(.p)<path>") | .[0:200];
  def kset: ([$routes.routes[].match.kind // empty] + [$roles[] | (.records // {}) | keys[]] + ["seat.up", "seat.down"]) | unique;
  # A seat is named <role> or <role>-<ticket>. The role name is bound first: inside `$seat | startswith(...)` a bare `.` is the seat.
  def role_of($seat): ([$roles[].name] | map(. as $n | select($seat == $n or ($seat | startswith($n + "-")))) | sort_by(length) | last);
  def fkind:
    . as $r | kset as $K
    | if ($r.kind != "note") and ($K | index($r.kind)) then $r.kind
      else ((($r.note // "") | capture("^(?<k>[a-z]+(\\.[a-z]+)*): ")? | .k) // $r.kind) as $p
        | if $K | index($p) then $p else $r.kind end
      end;
  def matches($r; $esc):
    . as $m
    | ($m.kind == null or $m.kind == $r.fk)
      and ($m.code == null or $m.code == $r.code)
      and ($m.code_gte == null or $r.code >= $m.code_gte)
      and ($m.attempt == null or $m.attempt == $r.att)
      and ($m.attempt_lt == null or $r.att < $m.attempt_lt)
      and ($m.escalations == null or $m.escalations == $esc)
      and ($m.escalations_lt == null or $esc < $m.escalations_lt);
  def route_of($r; $esc): first($routes.routes[] | select(.match | matches($r; $esc))) // null;
  def role_file($role): first($roles[] | select(.name == $role)) // null;
  def scoped($role): ((role_file($role) // {}) | (.label // "") | contains("${ticket}"));
  def family($role): ((role_file($role) // {}) | (.model // {}) | (.claude // .codex // "")) | split("-") | (if .[0] == "claude" then .[1] else .[0] end);
  def tag($row):
    "\($row.match.kind) \($row.match.code)"
    + (if $row.match.attempt_lt != null then " · attempt < \($row.match.attempt_lt)" else "" end)
    + (if $row.match.attempt != null then " · attempt \($row.match.attempt)" else "" end)
    + (if $row.match.escalations != null then " · escalations \($row.match.escalations)" else "" end)
    + (if $row.do == "escalate" then " · \($row.code) escalate" elif $row.do == "notify_owner" then " · owner card" else "" end);
  def step($t):
    if $t == null then 0
    elif $t.status == "done" or $t.closed != null then 4
    elif $t.pr != null or $t.status == "in-review" then 3
    elif $t.status == "in-progress" then 2
    elif $t.status == "ready" then 1
    else 0 end;

  # --- the records, normalised and in order ---
  ([$events_f[0][] | . + {fk: fkind, rl: (.role // role_of(.seat)), att: (.attempt // 1)}] | sort_by(.at, .id)) as $ev
  | ($ev | map(select(.seat != null)) | group_by(.seat) | map(sort_by(.at, .id) | last | {seat, rl, pane, up: (.fk != "seat.down"), ticket})) as $seatst
  | ($panes_ok | not) as $nopanes
  | ($panes_ok and ($panes | any(.label | contains($cfg.inputs.owner_pane_label)))) as $owner_up

  | def pane_ok($p): $nopanes or ($p != null and ($panes | any(.pane_id == $p)));
    def seats_for($role; $tid): $seatst | map(select(.rl == $role and .up and (if scoped($role) then .ticket == $tid else true end)));
    def station_for($row):
      ($cfg.stations | map(select(.role == $row.to))) as $c
      | ((($c | map(select(.takes != null and (.takes | to_entries | all(.value == $row[.key]))))) | first)
         // (($c | map(select(.takes == null))) | first) // null) | if . == null then null else .id end;
    def emitter_of($r):
      ($cfg.stations | map(select(.role == $r.rl and .takes == null))) as $c
      | ((($c | map(select(.emits != null and .emits.kind == $r.fk))) | first) // ($c | first) // null) | if . == null then null else .id end;
    def station_of_role($role): (($cfg.stations | map(select(.role == $role and .takes == null)) | first) // null) | if . == null then null else .id end;
    def seat_parts($role; $tid):
      seats_for($role; $tid) as $up
      | ($up | map(select(pane_ok(.pane)))) as $live
      | ($up - $live) as $gone
      | if ($live | length) > 0 then [["ok", "seat up: \($live[0].seat | clean)\(if $live[0].pane != null then ", \($live[0].pane)" else "" end)"]]
        elif ($gone | length) > 0 then [["bad", "seat record says up but pane \($gone[0].pane) is gone"]]
        else [["todo", "seat up"]] end;
    def rec_part($s; $recs):
      ($recs | map(select(.rl == $s.role and ($s.emits == null or .fk == $s.emits.kind))) | last) as $r
      | if $r != null then [["ok", "\($r.fk) \($r.code) at \($r.at[11:16])Z"]] else [] end;

    def sstate($s; $T; $recs; $here; $blocked; $byhand; $last):
      ($s.id == $here) as $at
      | (if $s.role == null then $owner_up else (seats_for($s.role; $T.id) | map(select(pane_ok(.pane))) | length > 0) end) as $alive
      | ((if $s.role == null then [if $owner_up then ["ok", "bearings stable up"] else ["todo", "bearings stable not running"] end]
          else [(if role_file($s.role) != null then ["ok", "role file"] else ["todo", "role file"] end),
                (if ($playbooks | index($s.role)) != null then ["ok", "playbook"] else ["todo", "playbook"] end)]
               + seat_parts($s.role; $T.id) + rec_part($s; $recs) end)
         + (if $s.role == "worker" and $byhand then [["hand", "PR \($T.pr) opened by hand, no pr.opened record"]] else [] end)
         + (if $at and $blocked then [["bad", "\($last.fk) \($last.code): \(($last.note // "") | clean | .[0:80])"]]
            elif $at and ($alive | not) then [["bad", "work is here, no seat up"]] else [] end)) as $parts
      | {status: (if $at and $blocked then "blocked" elif $alive then "live" elif $at then "building" else "queued" end), parts: $parts}
        + (if $s.role == "worker" and $byhand then {hand: true} else {} end);

    def line($T):
      ($ev | map(select(.ticket == $T.id))) as $recs
      | ($recs | map(select(.fk | IN("seat.up", "seat.down", "compaction", "note") | not))) as $work
      | ($recs | map(select(.fk == "escalated")) | length) as $esc
      | ($work | last) as $last
      | (if $last != null then route_of($last; $esc) else null end) as $row
      | ($work | any(.fk == "pr.opened")) as $pro
      | ($T.pr != null and ($pro | not) and ($last == null or $last.fk == "work.started")) as $byhand
      | (if $byhand then station_of_role("tester")
         elif $last == null then (if $T.branch != null then station_of_role("worker") else station_of_role("architect") end)
         elif $row != null then (station_for($row) // emitter_of($last))
         else emitter_of($last) end) as $here
      | ($last != null and ($last.code == 423 or $last.fk == "blocked" or $last.fk == "escalated")) as $blocked
      | (if $row != null and ($belt.running | not) then emitter_of($last) else null end) as $waiting
      | {id: ($T.id | split("-") | last), ticket: $T.id, name: ($T.title | clean),
         sub: ("\($T.status) · \($T.branch // "no branch")\(if $T.pr != null then " · PR \($T.pr)" else "" end)" | clean),
         sim: false, status: (if $blocked then "blocked" else "building" end),
         belt: (if $belt.running then "live" else "stopped" end), here: $here}
        + (if $waiting != null then {waiting: $waiting} else {} end)
        + {st: ($cfg.stations | map(. as $s | {key: $s.id, value: sstate($s; $T; $recs; $here; $blocked; $byhand; $last)}) | from_entries)};

    ($tickets | map(select(.status | IN($cfg.line_statuses[]))) | sort_by(.id) | map(line(.))) as $lines
  | ($lines | map(select(.status == "blocked")) | length) as $nblocked
  | ($ev | map(. as $r | select(route_of($r; 0) != null)) | length) as $routed
  | ($cfg.board | map(. as $b | ($tickets | map(select(.id == $b.ticket)) | first) as $t
      | {k: $b.k, ticket: $b.ticket, t: (if $t != null then ($t.title | clean) else "ticket file not found" end),
         sub: "\($b.ticket) · \($t.status // "missing")", step: step($t)})) as $board
  | ([$lines[].ticket] + [$cfg.board[].ticket] | unique | map(. as $id | ($tickets | map(select(.id == $id)) | first) as $t
      | select($t != null) | [($id | split("-") | last), "\($id) - \($t.title | clean)"])) as $legend

  | {schema_version: "1.0.0", number: $number, at: $now, actor: $cfg.actor,
     state: (if $panes_ok then "LIVE" else "HERDR PANES UNAVAILABLE" end),
     headline: (if ($lines | length) == 0
                then "Floor: no ticket in progress or in review, belt \(if $belt.running then "running" else "stopped" end)"
                else "Floor: \($lines | length) \(if ($lines | length) == 1 then "line" else "lines" end), \($nblocked) blocked, belt \(if $belt.running then "running" else "stopped" end)" end),
     poll_seconds: $cfg.poll_seconds,
     stations: ($cfg.stations | map(. as $s | (role_file($s.role)) as $rf
       | {id: $s.id, role: ($s.title // ($rf | .title) // $s.role // $s.id),
          model: ($s.model // (if $rf != null then "\(family($s.role)) · \($rf.effort)" else "" end)),
          does: $s.does, out: $s.emits})),
     kickbacks: ($cfg.kickbacks | map(. as $k
       | (first($routes.routes[] | select(.match.kind == $k.route.kind and .match.code == $k.route.code and .do == $k.route.do))
          // error("kickback \($k.from) to \($k.to) names no row of the routes table")) as $row
       | {from: $k.from, to: $k.to, tag: tag($row)} + (if $k.esc == true then {esc: true} else {} end))),
     lines: $lines}
    + (if $cfg.board_title != null then {board_title: $cfg.board_title} else {} end)
    + {board: $board,
       legend: ($legend + $cfg.legend_notes),
       # BREADCRUMB (WO-20261011-616c, step 3): a stale belt used to print its age in seconds here ("stale, 105s old"). The
       # age grows every pass, so loop.sh watch saw a changed entry every watch_seconds while the belt sat stopped (its normal
       # state until the route runner exists) and rewrote the page for nothing, which AC-H4 forbids. The age is not in the entry
       # at all now: "over N s old" says the same thing and holds still. Rejected: ignoring `sources` in watch's comparison, which
       # would hide a real change in what was read. Cost: the page no longer says how stale; the state file's mtime does.
       sources: ("\($cfg.inputs.events_dir) (\($ev | length) records in \($cfg.inputs.events_days) days, \($routed) with a route) · \($cfg.inputs.work_orders_dir) (\($tickets | length) tickets) · \($cfg.inputs.roles_dir)/*.json · \($cfg.inputs.routes) · herdr pane list (\(if $panes_ok then "\($panes | length) panes" else "unavailable" end)) · belt state (\(if $belt.running then "running" elif $belt.age != null then "stale, over \($cfg.inputs.belt_max_age_seconds)s old" else "absent" end))")}
