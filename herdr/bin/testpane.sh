#!/usr/bin/env bash
# testpane.sh - the one way a worker seat runs a command in a herdr pane: only in the labelled test pane its brief names.
#   testpane.sh <pane> <command...>     herdr pane run <pane> <command...>, when <pane> is exactly $COQ_TEST_PANE
# Exit: 0 ok, 2 usage, 3 refused (any other pane, or no test pane in this seat's environment), 4 herdr failure.
#
# BREADCRUMB 2026-10-10 - WO-20261010-8fa8. What broke: playbooks/worker.md forbade `herdr pane run` outright, so a worker
#   could not satisfy an acceptance criterion that says "green from the labelled test pane" and the architect had to run
#   the suite for it (found closing WO-20261010-c274; its AC-H4 waited on the architect's pane). Why this fix: a role's
#   allow and deny are static Claude Code rules (seat.sh render_settings) and a seat runs under bypassPermissions, where an
#   allow rule restricts nothing and a deny of `herdr pane run *` would also deny the one pane we want, so no rule can say
#   "this pane only". The role therefore denies `herdr pane run *` and allows this script, which compares the pane to
#   COQ_TEST_PANE, a value seat.sh resolves from the architect tab and exports into the seat's environment line, so the
#   worker reads it in its brief and never chooses it. Rejected: allowing `herdr pane run *` and trusting the playbook (AC-H3
#   asks for a refusal, not a promise), and baking the pane id into the role (it changes with every herdr restart).
#   Cost: this fences `pane run` only; `herdr pane send-text` and `send-keys` are not denied, and a worker that rewrites its
#   own COQ_TEST_PANE defeats the check, so the fence is still the role's deny list plus the playbook, as seat.sh says.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

[ $# -ge 2 ] || { sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
pane="$1"; shift
if [ -z "${COQ_TEST_PANE:-}" ]; then printf 'testpane: refused - this seat has no COQ_TEST_PANE; seat.sh exports it from the architect tab\n' >&2; exit 3; fi
if [ "$pane" != "$COQ_TEST_PANE" ]; then printf 'testpane: refused - %s is not the test pane your brief names (%s)\n' "$pane" "$COQ_TEST_PANE" >&2; exit 3; fi
sl_mut pane run "$pane" "$*" || { printf 'testpane: herdr pane run %s failed\n' "$pane" >&2; exit 4; }
