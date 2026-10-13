#!/usr/bin/env bash
# Catches: the runner reading anything of this repo when pointed at another events dir and routes file with --repo, --routes
# and --state (AC-H7: the RUNBOOK's "run it against another repo" recipe).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up home
O="$W/other"; cp -r "$R" "$O"; mkdir -p "$W/other-state"
printf '%s\n' '{"routes": [{"match": {"kind": "gate", "code": 150}, "do": "wake", "to": "architect", "with": "record"}]}' > "$W/other-routes.json"

echo "-- AC-H7: another repo's events dir and routes file"
id=$(COQ_STATE="$W/other-state" "$O/events/bin/event.sh" add --code 150 --seat someone --kind gate --ticket $T)
rec pr.opened 100 worker-wo-20261011-aaaa $T >/dev/null
"$ROUTE" once --from-start --repo "$O" --routes "$W/other-routes.json" --state "$W/other-state"; assert_eq "exit 0" "$?" 0
assert_match "the other repo's row was performed, with the other repo's playbook path" "$(cat "$HLOG")" "^--session stable agent prompt architect-wo-20261011-aaaa record $id playbook $O/playbooks/architect.md$"
assert_eq "its receipt is in the other events dir" "$(STATE="$W/other-state" files_code 300 | wc -l | tr -d ' ')" 1
assert_eq "this repo's event log was not touched: only the one pr.opened" "$(rec_files | wc -l | tr -d ' ')" 1
assert_eq "this repo's state dir was not touched" "$(ls "$STATE")" records
case_done
