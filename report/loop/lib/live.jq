# live.jq - the board's tickets from the live line, not only from the main checkout (WO-20261013-89c7, Roadmap K8).
#   jq -n -f live.jq --slurpfile tickets_f TICKETS --slurpfile live_f LIVE
# Inputs: the ticket frontmatters read from main; LIVE = {ok, prs:[{number, headRefName, title}], branches:[name]}, the open pull
# requests and the ticket branches on origin. Output: {tickets, stale}.
#
# BREADCRUMB 2026-10-13 - WO-20261013-89c7. What broke: collect read ticket status only from the main checkout (loop.sh, the
#   find over work-orders), so a ticket started on its own branch (status lives on that branch, PR 83 for WO-20261012-7e13) never
#   showed, and tickets left in-progress on main long ago (WO-20261010-eaa3, WO-20261011-38c7) showed as live lines. Why this
#   fix: an open pull request makes its ticket in-review with that number and branch, a ready ticket whose branch is on origin is
#   in-progress, and a pull request naming a ticket main has no file for is drawn from its title. `stale` lists the tickets main
#   holds in-progress that have neither an open pull request nor a branch on origin; loop.sh validate fails on one. Rejected:
#   calling the GitHub API per ticket (one gh call and one ls-remote per pass is enough). Cost: with LIVE.ok false (no gh, no
#   network) the pull requests are unknown, so only a ticket with no branch at all is stale, and nothing is promoted.
($tickets_f[0]) as $tk | ($live_f[0]) as $lv
| def prid: ((.title // "") | capture("^(?<id>WO-[0-9]{8}-[0-9a-f]{4})")? | .id);
  ($lv.prs // []) as $prs | ($lv.branches // []) as $br | ($lv.ok == true) as $ok
| def open_pr($t): first($prs[] | select(prid == $t.id or (.headRefName == $t.branch and $t.branch != null))) // null;
  def ended: .status == "done" or .status == "cancelled" or .closed != null;
  ($tk | map(. as $t | if ($t | ended) then $t
      else (open_pr($t)) as $p
        | if $p != null then $t + {status: "in-review", pr: $p.number, branch: $p.headRefName}
          elif $ok and $t.status == "ready" and $t.branch != null and ($br | index($t.branch)) != null then $t + {status: "in-progress"}
          else $t end end)) as $merged
| ([$merged[].id]) as $ids
| ($prs | map(select(prid != null and ((prid as $i | $ids | index($i)) == null)))
    | map({id: prid, title: (.title | sub("^WO-[0-9]{8}-[0-9a-f]{4} - "; "")), status: "in-review", parent: null, branch: .headRefName, pr: .number, closed: null})) as $extra
| {tickets: ($merged + $extra),
   stale: [$merged[] | select(.status == "in-progress" and .pr == null
       and (.branch as $b | $b == null or ($ok and (($br | index($b)) == null)))) | .id] | sort}
# BREADCRUMB 2026-10-13 - WO-20261013-89c7, review.changes 422 on PR 93 (AC-H2). What broke: the stale filter above read
#   `$br | index(.branch)`, and inside that pipe `.` is the branches array, so jq died with "Cannot index array with string branch"
#   whenever an in-progress ticket with a branch met LIVE.ok true; `loop.sh collect` on the repo with the live gh and ls-remote
#   data exited 3 ("the live line could not be merged into the tickets") and the board went dark. Why this fix: bind the ticket's
#   branch to $b before the pipe, the same shape open_pr already uses with $t. Rejected: indexing with `$t.branch` through a second
#   def (a binding in place is smaller). Cost: none. tests/cases/16-live.test.sh now covers the path that failed (ok true, branch
#   set, in progress), in the fixture and on the live collect.
