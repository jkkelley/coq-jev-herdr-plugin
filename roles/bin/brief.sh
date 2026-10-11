#!/usr/bin/env bash
# brief.sh - the one-line brief a seat receives (SPEC-03: a brief names the ticket,
# its title and the playbook; nothing else). Pure: role + ticket file in, one line out.
#   brief.sh --role <role> --ticket <WO-ID> [--project DIR] [--test-pane ID]
# --test-pane (WO-20261010-8fa8): the labelled test pane seat.sh resolved from the architect tab. The brief prints it so a
# worker reads the pane there and never chooses one; herdr/bin/testpane.sh refuses any other.
set -euo pipefail
ROLE=""; ID=""; PROJ=.; TP=""
while [ $# -gt 0 ]; do case $1 in --role) ROLE=$2; shift 2;; --ticket) ID=$2; shift 2;; --project) PROJ=$2; shift 2;; --test-pane) TP=$2; shift 2;; *) echo "usage: brief.sh --role R --ticket WO-ID [--project DIR] [--test-pane ID]" >&2; exit 2;; esac; done
[ -n "$ROLE" ] && [ -n "$ID" ] || { echo "usage: brief.sh --role R --ticket WO-ID [--project DIR]" >&2; exit 2; }
[ -f "$PROJ/roles/$ROLE.json" ] || { echo "no role $ROLE" >&2; exit 6; }
F=$(find "$PROJ/work-orders" -name "$ID-*.md" -not -path '*/archive/*' | head -1)
# BREADCRUMB 2026-10-11 - WO-20261011-23df. What broke: the close-out law archives a ticket on its branch before the PR lands, so
#   on a checkout carrying PR 13's branch this find missed WO-20261011-9639, brief.sh exited 6 with "no ticket", and seat.sh
#   sent the tester a fallback prompt with no title, plan or record id; the seat then stalled asking what it should test.
#   Why this fix: tester, reviewer and merger act on a PR whose ticket is done on its branch by design, so for every role but
#   worker the archive is searched second (seat.sh does the same at its ticket check). Rejected: letting seat.sh pass the path
#   in (two callers to keep in step; this script is also run by hand). Cost: one more find for three roles.
[ -n "$F" ] || [ "$ROLE" = worker ] || F=$(find "$PROJ/work-orders/archive" -name "$ID-*.md" | head -1)
[ -n "$F" ] || { echo "no ticket $ID" >&2; exit 6; }
TITLE=$(awk '/^---$/{c++; next} c==1' "$F" | jq -r .title 2>/dev/null || sed -n 's/^# [^ ]* - //p' "$F" | head -1)
# The brief names what the role denies, so a seat that meets one denial does not conclude the whole tool is gone
# (2026-10-11: the PR 13 tester ran `git status`, hit the role's Bash(git *) deny and stopped, saying "Bash is denied").
DENY=$(jq -r '[(.deny.tools[]?), (.deny.commands[]? | "Bash(" + . + ")")] | join(", ")' "$PROJ/roles/$ROLE.json" 2>/dev/null)
printf '%s - %s. Playbook playbooks/%s.md.%s%s Post your first record before anything else.\n' "$ID" "$TITLE" "$ROLE" "${TP:+ Your test pane is $TP; run commands only there, through herdr/bin/testpane.sh.}" "${DENY:+ Your role denies only: $DENY; every other tool and Bash command is yours.}"
