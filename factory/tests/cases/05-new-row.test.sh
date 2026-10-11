#!/usr/bin/env bash
# Catches: new behaviour needing runner code. A routes.json row for a new kind is performed with route.sh untouched; the
# enqueue action writes the queue; the same record before the row existed stays a 500 (AC-H5).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up newrow
sum_before=$(sha256sum "$ROUTE" | cut -d' ' -f1)

echo "-- AC-H5: a deploy 250 record has no row, then gets one"
rec deploy 250 someone $T >/dev/null; run_once
assert_eq "no row: a 500, no herdr call" "$(hcalls)" 0
jq '.routes = [{"match": {"kind": "deploy", "code": 250}, "do": "wake", "to": "monitor", "with": "record"}] + .routes' "$R/factory/config/routes.json" > "$W/routes.new" && mv "$W/routes.new" "$R/factory/config/routes.json"
sleep 1; id=$(rec deploy 250 someone $T); run_once
assert_match "the new row was performed" "$(cat "$HLOG")" "^--session stable agent prompt monitor record $id playbook $R/playbooks/monitor.md$"
assert_eq "route.sh is byte for byte what it was" "$(sha256sum "$ROUTE" | cut -d' ' -f1)" "$sum_before"

echo "-- enqueue: a request.forwarded 300 record lands in the queue"
sleep 1; id=$(rec request.forwarded 300 interface $T); run_once
items=$(find "$R/queue/items" -name "p*-$T.json" 2>/dev/null)
assert_eq "one queue item for the ticket" "$(printf '%s\n' "$items" | grep -c .)" 1
assert_eq "it remembers the record it came from" "$(jq -r .from <<<"$(cat "$items")")" "$id"
case_done
