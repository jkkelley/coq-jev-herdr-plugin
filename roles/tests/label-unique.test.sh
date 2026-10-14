#!/usr/bin/env bash
# roles/tests/label-unique.test.sh - WO-20261013-dec6 (cause ag). Proves a seat name resolves to one addressable role: no two roles
# the record writer can address (the --to enum in events/schema/event.schema.json) share a label, and a role outside that enum that
# shares a label (spec-author shares worker-${ticket} on purpose, see its breadcrumb "the label") shares it with exactly one
# addressable role. factory/bin/policy.sh role_of_seat answers from that rule; two addressable roles on one label would make the
# answer depend on file order, which is how case 12-policy went red on main from PR 136.
#   bash roles/tests/label-unique.test.sh [repo-root]     default: two levels above this file
# Exit 0 all pass, 1 any fail. Needs jq only.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="${1:-$(cd "$HERE/../.." && pwd)}"
SCHEMA="$R/events/schema/event.schema.json"
pass=0; fail=0
ok() { pass=$((pass + 1)); echo "ok   $1"; }
no() { fail=$((fail + 1)); echo "FAIL $1"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# clashes ROLES_DIR: one line per label that breaks the rule, empty when none
clashes() {
  local f
  for f in "$1"/*.json; do jq -c --arg n "$(basename "$f" .json)" '{name: $n, label: (.label // "")}' "$f"; done \
    | jq -rs --argjson to "$(jq -c '.properties.to.enum' "$SCHEMA")" '
      map(select(.label != "")) | group_by(.label)[] | select(length > 1)
      | ([.[] | select(.name as $n | $to | index($n))] | map(.name)) as $addr
      | select(($addr | length) != 1)
      | "\(.[0].label): \(map(.name) | join(", ")) (addressable: \($addr | join(", ") | if . == "" then "none" else . end))"'
}

to="$(jq -c '.properties.to.enum // empty' "$SCHEMA" 2>/dev/null)"
if [ -n "$to" ]; then ok "the writer's --to enum is readable from events/schema/event.schema.json"; else no "the writer's --to enum is readable from events/schema/event.schema.json"; fi

out="$(clashes "$R/roles")"
if [ -z "$out" ]; then ok "every shared label resolves to exactly one addressable role"; else no "labels that do not resolve to one addressable role: $out"; fi

# The predicate must fail when two addressable roles share a label, or it could pass by accident: give the tester the worker's label.
mkdir -p "$tmp/two"; cp "$R"/roles/*.json "$tmp/two/"
jq --arg l "$(jq -r .label "$R/roles/worker.json")" '.label = $l' "$R/roles/tester.json" > "$tmp/two/tester.json"
out="$(clashes "$tmp/two")"
if [ -n "$out" ]; then ok "a tester under the worker's label is caught ($out)"; else no "a tester under the worker's label is not caught"; fi

# And when a shared label has no addressable role at all: take the worker away, leaving spec-author alone on worker-${ticket}.
mkdir -p "$tmp/none"; cp "$R"/roles/*.json "$tmp/none/"
jq '.label = "spec-author-${ticket}"' "$R/roles/spec-author.json" > "$tmp/none/worker.json"
jq '.label = "worker-${ticket}"' "$R/roles/spec-author.json" > "$tmp/none/other-author.json"
out="$(clashes "$tmp/none")"
if [ -n "$out" ]; then ok "a label shared by roles none of which is addressable is caught ($out)"; else no "a label shared only by unaddressable roles is not caught"; fi

echo "label unique: $pass passed, $fail failed"
[ "$fail" = 0 ]
