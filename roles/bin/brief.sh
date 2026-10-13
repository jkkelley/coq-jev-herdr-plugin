#!/usr/bin/env bash
# brief.sh - the one-line brief a seat receives (SPEC-03: a brief names the ticket,
# its title and the playbook; a test pane and a tester's plan are data, never prose). Role + ticket file in, one line out.
#   brief.sh --role <role> --ticket <WO-ID> [--project DIR] [--test-pane ID] [--worktree DIR]
# --test-pane (WO-20261010-8fa8): the labelled test pane seat.sh resolved from the architect tab. The brief prints it so a
# worker reads the pane there and never chooses one; herdr/bin/testpane.sh refuses any other.
# --worktree (WO-20261013-b6f3): the checkout seat.sh put at the pull request's head. A tester's brief then names that head and
# lists, verbatim and in order, the commands <project>/factory/bin/suites.sh plan prints for it. Any other role, no --worktree, or
# a plan that cannot be made leaves the brief as it was, with the reason on stderr; the tester's playbook plans for itself then.
# Exit: 0 brief printed, 2 usage, 6 no such role or ticket.
#
# BREADCRUMB 2026-10-13 - WO-20261013-b6f3 (cause z, architect ruling 22:28Z). What broke: roles/tester.json told the tester to
#   run the ticket's test plan and this brief said nothing about tests, so two testers on PR 136 (WO-20261013-d127) each ran the
#   whole herdr suite (about 25 minutes), at 21:56Z and at 22:28Z, the second after an order to run lint and the render check only.
#   Why it mattered: the tester was the slowest gate of the build loop, and an order in prose did not hold. Why this fix: the
#   plan arrives as data the seat cannot skip. suites.sh is the project's own copy (the checkout seat.sh runs from), never the
#   pull request's: a pull request cannot shrink its own plan by editing factory/config/suites.json, and no code under test runs
#   in the belt's process. --head pins the plan to the commit read here, so the head the brief names is the head it planned.
#   Rejected: the wake line in factory/bin/route.sh (its 38c7 cap: new behaviour is a routes.json row; the file is held by
#   WO-20261013-e2c3), the worktree's own suites.sh (the reason above), and refusing the brief when the plan fails (a seat with no
#   brief stalls, and the playbook's fallback plans again in the seat). Cost: a tester's brief grows by its plan; a stale
#   origin/main in the worktree plans a superset, never a subset. Until herdr/bin/seat.sh passes --worktree (its brief.sh call,
#   a one-line change held behind WO-20261013-7af7, which owns that file) no brief carries a plan and every tester takes the
#   fallback. Proof: roles/tests/tester-plan.test.sh.
set -euo pipefail
USAGE="usage: brief.sh --role R --ticket WO-ID [--project DIR] [--test-pane ID] [--worktree DIR]"
ROLE=""; ID=""; PROJ=.; TP=""; WT=""
while [ $# -gt 0 ]; do case $1 in --role) ROLE=$2; shift 2;; --ticket) ID=$2; shift 2;; --project) PROJ=$2; shift 2;; --test-pane) TP=$2; shift 2;; --worktree) WT=$2; shift 2;; *) echo "$USAGE" >&2; exit 2;; esac; done
[ -n "$ROLE" ] && [ -n "$ID" ] || { echo "$USAGE" >&2; exit 2; }
[ -f "$PROJ/roles/$ROLE.json" ] || { echo "no role $ROLE" >&2; exit 6; }
F=$(find "$PROJ/work-orders" -name "$ID-*.md" -not -path '*/archive/*' | head -1); [ -n "$F" ] || { echo "no ticket $ID" >&2; exit 6; }
TITLE=$(awk '/^---$/{c++; next} c==1' "$F" | jq -r .title 2>/dev/null || sed -n 's/^# [^ ]* - //p' "$F" | head -1)

# plan_of DIR: the plan sentence for the head checked out in DIR on stdout, or the reason on stderr and status 1.
plan_of() {
  local wt=$1 head out err n=0 list="" c
  head=$(git -C "$wt" rev-parse --verify --quiet HEAD 2>/dev/null) || { echo "brief: no plan for $ID: no HEAD in $wt" >&2; return 1; }
  err=$(mktemp) || { echo "brief: no plan for $ID: mktemp failed" >&2; return 1; }
  if ! out=$("$PROJ/factory/bin/suites.sh" plan --repo "$wt" --head "$head" 2>"$err"); then
    echo "brief: no plan for $ID: suites.sh plan failed: $(tail -n 1 "$err")" >&2; rm -f "$err"; return 1
  fi
  rm -f "$err"
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [[ $c != *'`'* ]] || { echo "brief: no plan for $ID: a planned command holds a backtick, which the brief quotes with" >&2; return 1; }
    n=$((n + 1)); list+=" $n) \`$c\`"
  done <<<"$out"
  [ "$n" -gt 0 ] || { echo "brief: no plan for $ID: suites.sh plan printed nothing" >&2; return 1; }
  printf ' Test plan for head %s, printed by factory/bin/suites.sh plan; run exactly these %s commands in order and nothing else:%s.' "$head" "$n" "$list"
}
PLAN=""
if [ "$ROLE" = tester ] && [ -n "$WT" ]; then PLAN=$(plan_of "$WT") || PLAN=""; fi
printf '%s - %s. Playbook playbooks/%s.md.%s%s Post your first record before anything else.\n' "$ID" "$TITLE" "$ROLE" "${TP:+ Your test pane is $TP; run commands only there, through herdr/bin/testpane.sh.}" "$PLAN"
