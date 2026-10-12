#!/usr/bin/env bash
# 10 - tickets.jq: each ticket with the Components it names. A Component is named in the title, Problem or Scope, nowhere else.
. "$(dirname "$0")/../lib/assert.sh"
. "$REPO_ROOT/report/loop/lib/blueprint/gather.sh"
B="$FIX/blueprint"; J="$REPO_ROOT/report/loop/lib/blueprint/tickets.jq"
bp_tickets "$B/work-orders" > "$W/raw.json"; jq -f "$J" "$W/raw.json" > "$W/out.json"
c() { jq -r "$1" "$W/out.json"; }
eq "gather reads every WO file, archive included" "5" "$(jq length "$W/raw.json")"
eq "a ticket per file, id from the frontmatter" "WO-20260101-0001 WO-20260101-0002 WO-20260101-0003 WO-20260101-0004 WO-20260101-0005" "$(c '[.[].id] | sort | join(" ")')"
eq "a Component named in the title counts" '["CMP-beta"]' "$(jq -c '.[] | select(.id == "WO-20260101-0001") | .cmps' "$W/out.json")"
eq "a Component named in Scope counts" '["CMP-gamma"]' "$(jq -c '.[] | select(.id == "WO-20260101-0002") | .cmps' "$W/out.json")"
eq "Notes and criteria are not read: 0003 names CMP-delta there and CMP-gamma in Scope, so only CMP-gamma counts" '["CMP-gamma"]' "$(jq -c '.[] | select(.id == "WO-20260101-0003") | .cmps' "$W/out.json")"
eq "status, pr and parent are carried" 'in-progress null WO-20260101-aaaa' "$(c '.[] | select(.id == "WO-20260101-0001") | "\(.status) \(.pr) \(.parent)"')"
printf -- '---\n{not json}\n---\n' > "$W/WO-20260101-bad.md"; mkdir -p "$W/bad"; mv "$W/WO-20260101-bad.md" "$W/bad/"
expect_exit 3 "a frontmatter that is not JSON stops the gather with 3" bash -c ". '$REPO_ROOT/report/loop/lib/blueprint/gather.sh'; set -o pipefail; bp_tickets '$W/bad' >/dev/null"
eq "a directory with no tickets is an empty list" "[]" "$(bp_tickets "$W/none" | jq -c .)"
done_case
