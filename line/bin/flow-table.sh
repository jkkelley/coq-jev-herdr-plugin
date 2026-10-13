#!/usr/bin/env bash
# Interim flow table: one row per ticket with the time of each stage, the stage it is in now, and the minutes it has sat there.
# Why: owner order 2026-10-13 03:12Z (architect brief to flowbuilder): "a monitoring agent checking every piece of this factory as
# things move through it, so we can identify the bottleneck". patrol-tick.sh probes seats (alive, stuck, idle); nothing measured
# where the TICKETS wait, so the slow stage was found by eye.
# Why this fix: a table computed from the records alone, by code, no model judgement (the patrol lesson, 02:10Z: an LLM opinion is
# not a probe). Stage = the newest lifecycle record of the ticket; minutes in stage = now minus that record. The bottleneck is the
# stage with the most summed waiting minutes. Records are read from BOTH trees (the checkout events/ and the state root; Roadmap A1
# split them): $COQ_STATE/events and $COQ_STATE/records, last 12 hours.
# Stage map (record kind -> stage entered): ticket.cut queued; worker seat.up or work.started working; pr.opened awaiting-test;
# test.passed awaiting-review; test.failed, review.changes, merge.conflict rework; review.passed awaiting-merge; merged
# awaiting-verify; verified, rejected done. Only a worker-* seat's seat.up/work.started count (a tester's seat.up is not work).
# A record with a PR and no ticket is attributed through any other record that carries both.
# Rejected: counting "queued" in the bottleneck. A cut ticket waits by design (one file, one in-flight ticket), so queued is
# printed but never named BOTTLENECK; every other waiting stage can be. Rejected: the first record of a kind as the stage time
# (a reworked ticket would show its first test pass); the latest is used, and stage minutes sum every pass.
# Cost: a ticket whose last record is older than 12 hours is not shown, even if it is stuck. An unlisted kind (note, record.routed,
# seat.down) does not move a ticket, so a lost handoff shows as minutes in the stage, which is the point.
# 03:16Z fix (architect, after p0 14ba0 named e618, 72a0, 5826 as waiting 400 to 540 min: stale PRs and tickets, no live work): an item
# counts toward the summary and the BOTTLENECK only when it has an OPEN PR (gh pr list --state open) or a worker started in the last
# 2 hours (STARTED_HOURS). Anything else is listed under NOT COUNTED. PRs in HELD_PRS (default 35 37, HELD in the priority list
# $STATE/plans/2026/10/20261013025600-priority-list.md) go in a HELD block and are never ranked. If gh fails, nothing is filtered and the
# header says so (a silent filter would hide the very stall this table exists to show). Backup: flow-table.sh.bak-0316.
# Replaced by: the K2 health watch (SPEC-17) and SPEC-16.F. Reads records and runs gh; its scratch rows live under the state root.
# Test: NOW=EPOCH flow-table.sh sets the clock; HOURS=N sets the window. line/tests/cases/flow-table.sh runs it on fixture records.
# BREADCRUMB 2026-10-13 - WO-20261013-ccb8 (Roadmap I, ruling ykne9). What broke: this script ran the line from
#   the owner's watch directory under the user cache, outside git, so it was never tested or reviewed, and it carried a literal
#   absolute path of the owner's home as the fallback checkout and a literal state directory of one repository name as the
#   fallback state root (owner 2026-10-12 22:49Z, m-20261012224955626-rjghl: every script lives in the project, only its artifacts
#   outside). Why this fix: the file moved here unchanged in behaviour; the checkout is found from the script's own location and
#   the state root through bin/state-root.sh (COQ_STATE, then the config default), so a second clone or a test world resolves its
#   own. The scratch row files (/tmp/flow-rows.$$, flow-sum.$$) now live in one mktemp directory under the state root's run tree and
#   a trap removes it, so a run writes only under the state root, as the ticket requires; /tmp was the only other place it wrote.
#   Rejected: keeping $COQ_REPO as the checkout (a seat exports it to the main checkout, so a worktree's own events/ would never be
#   read) and a shared fixed scratch name (two runs, the patrol and an owner, would overwrite each other). Cost: the script now needs
#   bin/state-root.sh beside it and exits 4 without it; HELD_PRS still defaults to "35 37" as before (changing what the script does
#   is out of scope). The old copy and its .bak-0316 backup are archived under the state root and deleted from the cache after the merge (orchestrator lane).
set -uo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
# shellcheck source=../../bin/state-root.sh
. "$REPO/bin/state-root.sh" 2>/dev/null || { echo "flow-table: bin/state-root.sh is missing beside this checkout" >&2; exit 4; }
STATE=$(coq_state_root) || exit 4
RUN=$(coq_tree run) || exit 4
mkdir -p "$RUN" && SCRATCH=$(mktemp -d "$RUN/flow-table.XXXXXX") || { echo "flow-table: cannot create a scratch directory under $RUN" >&2; exit 4; }
trap 'rm -rf "$SCRATCH"' EXIT
NOW=${NOW:-$(date -u +%s)}; HOURS=${HOURS:-12}; HELD_PRS=${HELD_PRS:-"35 37"}; STARTED_HOURS=${STARTED_HOURS:-2}
CUT=$((NOW - HOURS * 3600))
# files are never edited after they are written, so mtime bounds the parse; 60 extra minutes cover clock and copy skew
find "$REPO/events" "$STATE/events" "$STATE/records" -path '*/[0-9][0-9][0-9][0-9]/[0-9][0-9]/*' -name '*.json' -mmin "-$((HOURS * 60 + 60))" -print0 2>/dev/null \
  | xargs -0 -r -n 200 jq -c 'try {at: (.at | fromdateiso8601), kind, seat: (.seat // ""), ticket, pr} catch empty' 2>/dev/null \
  | jq -rs --argjson now "$NOW" --argjson cut "$CUT" '
  def stage:
    if .kind == "ticket.cut" then "queued"
    elif (.kind == "seat.up" or .kind == "work.started") and (.seat | startswith("worker-")) then "working"
    elif .kind == "pr.opened" then "awaiting-test"
    elif .kind == "test.passed" then "awaiting-review"
    elif (.kind == "test.failed" or .kind == "review.changes" or .kind == "merge.conflict") then "rework"
    elif .kind == "review.passed" then "awaiting-merge"
    elif .kind == "merged" then "awaiting-verify"
    elif (.kind == "verified" or .kind == "rejected") then "done"
    else null end;
  def hm: if . == null then "-" else (. | strftime("%H:%M")) end;
  def last_of(f): (map(select(f)) | map(.at) | max);
  . as $all
  | ([$all[] | select(.pr != null and .ticket != null) | {key: (.pr | tostring), value: .ticket}] | from_entries) as $pr2t
  | [$all[] | select(.at >= $cut) | .ticket = (.ticket // (if .pr != null then $pr2t[.pr | tostring] else null end))
      | select(.ticket != null) | . + {stage: stage} | select(.stage != null)]
  | group_by(.ticket)[]
  | sort_by(.at) as $ev
  # collapse consecutive records of the same stage (repeated work.started) to the first
  | (reduce $ev[] as $e ([]; if length > 0 and .[-1].stage == $e.stage then . else . + [$e] end)) as $tl
  | ($tl | length) as $n
  | ($tl | to_entries | map(select(.key < $n - 1) | {s: .value.stage, m: (($tl[.key + 1].at - .value.at) / 60 | floor)})
      | group_by(.s) | map("\(.[0].s)=\(map(.m) | add)") | join(" ")) as $spent
  | [ .[0].ticket,
      ($ev | map(select(.pr != null) | .pr) | last // "-"),
      ($ev | last_of(.kind == "ticket.cut") | hm),
      ($ev | last_of(.stage == "working") | hm),
      ($ev | last_of(.kind == "pr.opened") | hm),
      ($ev | last_of(.kind == "test.passed" or .kind == "test.failed") | hm),
      ($ev | last_of(.kind == "review.passed" or .kind == "review.changes") | hm),
      ($ev | last_of(.kind == "merged") | hm),
      ($ev | last_of(.kind == "verified" or .kind == "rejected") | hm),
      $tl[-1].stage,
      ((($now - $tl[-1].at) / 60) | floor),
      ($spent | if . == "" then "-" else . end),
      ($ev | last_of(.stage == "working") // 0) ] | @tsv' \
  | sort -t$'\t' -k10,10 -k11,11nr > "$SCRATCH/flow-rows"

now_hm=$(date -u -d "@$NOW" +%H:%MZ)
R=$SCRATCH/flow-rows
if open=$(cd "$REPO" && gh pr list --state open --limit 200 --json number --jq '.[].number' 2>/dev/null) && [ -n "$open" ]; then ghnote="open PRs: $(echo $open | tr ' ' ',')"
else open=""; ghnote="WARNING gh pr list failed, nothing filtered"; fi
# column 14 = class: done | held | live | stale. No gh answer: every non-done, non-held row is live.
awk -F'\t' -v OFS='\t' -v open="$open" -v held="$HELD_PRS" -v now="$NOW" -v sh="$STARTED_HOURS" -v nogh="$([ -z "$open" ] && echo 1 || echo 0)" '
  BEGIN { n = split(open, a, " "); for (i = 1; i <= n; i++) O[a[i]] = 1; n = split(held, b, " "); for (i = 1; i <= n; i++) HP[b[i]] = 1 }
  { c = "live"
    if ($10 == "done") c = "done"
    else if ($2 in HP) c = "held"
    else if (!nogh && !($2 in O) && !($13 + 0 >= now - sh * 3600)) c = "stale"
    print $0, c }' "$R" > "$R.cls"
echo "FLOW TABLE $now_hm (UTC), window ${HOURS}h, records from checkout events/ and $STATE/{events,records}; $ghnote; started-in-last ${STARTED_HOURS}h counts"
show() {   # CLASS TITLE: rows of that class, columns 1-12
  local rows; rows=$(awk -F'\t' -v c="$1" '$14 == c' "$R.cls" | cut -f1-12)
  [ -n "$rows" ] || return 0
  echo; echo "$2"
  { printf 'TICKET\tPR\tCUT\tSTART\tPR.OPEN\tTEST\tREVIEW\tMERGED\tVERIFIED\tNOW-IN\tMIN\tMINUTES-PER-COMPLETED-STAGE\n'; echo "$rows"; } | column -t -s$'\t'
}
show live "LIVE (open PR or started in the last ${STARTED_HOURS}h; counted)"
show held "HELD (priority list; shown, never ranked)"
show stale "NOT COUNTED (no open PR, not started in the last ${STARTED_HOURS}h)"
show "done" "DONE"   # quoted: an unquoted done reads as the shell keyword (shellcheck SC1010 under make lint, WO-20261013-ccb8)
echo
echo "STAGE SUMMARY (live items only; waiting = newest record put the ticket in the stage)"
awk -F'\t' '$14 == "live" { c[$10]++; s[$10] += $11; if ($11 > m[$10]) m[$10] = $11; v[$10] = v[$10] " " $11 }
  END { for (k in c) { n = split(v[k], a, " "); for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) if (a[j] + 0 < a[i] + 0) { t = a[i]; a[i] = a[j]; a[j] = t }
        med = (n % 2) ? a[(n + 1) / 2] : int((a[n / 2] + a[n / 2 + 1]) / 2)
        print k "\t" c[k] "\t" med "\t" m[k] "\t" s[k] } }' "$R.cls" | sort -t$'\t' -k5,5nr > "$SCRATCH/flow-sum"
top=$(awk -F'\t' '$1 != "queued" { print $1; exit }' "$SCRATCH/flow-sum")
{
  printf 'STAGE\tWAITING\tMEDIAN-MIN\tMAX-MIN\tTOTAL-WAIT-MIN\t\n'
  awk -F'\t' -v t="$top" '{ print $0 "\t" ($1 == t ? "BOTTLENECK" : ($1 == "queued" ? "(backlog by design, not ranked)" : "")) }' "$SCRATCH/flow-sum"
} | column -t -s$'\t'
echo
if [ -n "$top" ]; then
  echo "BOTTLENECK: $top - items: $(awk -F'\t' -v t="$top" '$14 == "live" && $10 == t { printf "%s(%sm) ", $1, $11 }' "$R.cls")"
else
  echo "BOTTLENECK: none (no live ticket is waiting outside the backlog)"
fi
