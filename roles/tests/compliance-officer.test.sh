#!/usr/bin/env bash
# roles/tests/compliance-officer.test.sh - WO-20261013-5b33. Proves the compliance officer role and its report schema:
# the role validates, its playbook is in sync, the fence is read-only, every agent is watched, every finding code has a
# GOOD and a NEVER example, and a sample report validates while an unknown finding code, a wrong "who acts" and a
# missing field fail.
#   bash roles/tests/compliance-officer.test.sh [repo-root]     default: two levels above this file
# Exit 0 all pass, 1 any fail. Runs with no network and no herdr; python3 with jsonschema and jq are the only needs.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="${1:-$(cd "$HERE/../.." && pwd)}"
ROLE="$R/roles/compliance-officer.json"; PB="$R/playbooks/compliance-officer.md"
RS="$R/roles/schema/role.schema.json"; CS="$R/roles/schema/compliance-report.schema.json"; SAMPLE="$HERE/compliance-report.sample.json"
pass=0; fail=0
ok() { pass=$((pass + 1)); echo "ok   $1"; }
no() { fail=$((fail + 1)); echo "FAIL $1"; }
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else no "$name"; fi; }
# refuse <name> validate <file> <schema>: the file must parse first, so a broken jq filter cannot pass a refusal by accident
refuse() { local name="$1"; shift
  jq -e . "$2" >/dev/null 2>&1 || { no "$name (variant file is not JSON)"; return; }
  if "$@" >/dev/null 2>&1; then no "$name (accepted, should be refused)"; else ok "$name"; fi; }
validate() { python3 -I -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$1" "$2"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
# variant <jq filter> -> a copy of the sample with the filter applied, path on stdout
variant() { local f="$tmp/v$RANDOM.json"; jq "$1" "$SAMPLE" > "$f"; echo "$f"; }

# AC-H1: the role validates against the role schema and the playbook is the render of the role
check "role validates against role.schema.json" validate "$ROLE" "$RS"
mkdir -p "$tmp/pb"; cp "$R"/playbooks/*.md "$tmp/pb/"
check "playbook in sync with the role (render --check)" bash "$R/roles/bin/render-playbook.sh" "$R/roles" "$tmp/pb" --check
check "role is claude haiku, read only, one seat" jq -e '.runtime.default=="claude" and .model.claude=="claude-haiku-5-5" and .read_only==true and .max_seats==1 and .permission_mode=="dontAsk"' "$ROLE"

# AC-H3: read only fence, nothing that writes, nudges or fixes
check "allow is exactly the read, process and report commands" jq -e '.allow.commands|sort==["events/bin/event.sh add","herdr agent get","herdr agent list","herdr pane list","herdr pane process-info","herdr pane read","ps -eo pid,ppid,args","tools/bearings/scripts/bearings.sh stable status"]' "$ROLE"
check "allow names no Write, Edit or Agent tool" jq -e '(.allow.tools|index("Write")|not) and (.allow.tools|index("Edit")|not) and (.allow.tools|index("Agent")|not)' "$ROLE"
check "deny covers Write Edit Agent git gh and every nudge" jq -e '(["Write","Edit","Agent"]-.deny.tools|length==0) and (["git *","gh *","herdr agent prompt","herdr agent send-keys","herdr pane run","herdr pane send-text","herdr pane send-keys","herdr pane close"]-.deny.commands|length==0)' "$ROLE"
check "playbook watches the architect and the orchestrator" grep -qE 'architect and the orchestrator' "$PB"
check "playbook forbids write, nudge and fix" bash -c "grep -q 'any write' '$PB' && grep -q 'any nudge' '$PB' && grep -q 'any fix' '$PB'"
check "playbook names turnwatch.sh, herdr and event.sh" bash -c "grep -q 'turnwatch.sh' '$PB' && grep -q 'herdr pane read' '$PB' && grep -q 'herdr agent list' '$PB' && grep -q 'events/bin/event.sh add' '$PB'"
check "playbook carries a per patrol checklist" bash -c "[ \"\$(grep -c '^[0-9]*\. \[ \] ' '$PB')\" -ge 8 ]"
# the one-minute tick (owner order 2026-10-13): driven by the system, covers screens and processes, in the playbook
check "the system tick is 60 seconds in herdr.json" jq -e '.watches.patrol_seconds==60 and .watches.compliance_agent=="compliance-officer"' "$R/herdr/config/herdr.json"
check "the tick has a reserved monitor slot that runs patrolwatch.sh" jq -e '[.tabs[].reserved[]?|select(.name=="patrolwatch" and (.command|test("herdr/bin/patrolwatch.sh$")))]|length==1' "$R/herdr/config/monitors.json"
check "playbook names the tick, its script and its 60 seconds" bash -c "grep -q 'patrolwatch.sh' '$PB' && grep -q 'watches.patrol_seconds, 60' '$PB' && grep -q 'PATROL' '$PB'"
check "playbook checks processes: ps, the runbook list, exactly one" bash -c "grep -q 'ps -eo pid,ppid,args' '$PB' && grep -q 'line-restart-runbook' '$PB' && grep -q 'route.sh run' '$PB' && grep -q 'flow.sh run' '$PB' && grep -q 'unfreeze.sh --watch' '$PB' && grep -q 'exactly once' '$PB'"
check "playbook routes findings to the orchestrator lane and process findings to the maintenance worker" bash -c "grep -q 'orchestrator lane' '$PB' && grep -q 'maintenance worker' '$PB'"
check "process findings act through the maintenance worker, the rest of the screen findings through the orchestrator" jq -e '."$defs".finding_codes.default|(.["CO-PROC-DEAD"].acts=="maintenance-worker" and .["CO-PROC-DUPLICATE"].acts=="maintenance-worker" and .["CO-HUNG"].acts=="orchestrator")' "$CS"

# every finding code: in the enum, in the map, and a GOOD and a NEVER example in the playbook
check "finding enum equals the finding-code map keys" python3 -I -c "
import json,sys
s=json.load(open(sys.argv[1])); sys.exit(0 if sorted(s['properties']['finding']['enum'])==sorted(s['\$defs']['finding_codes']['default']) else 1)" "$CS"
for code in $(jq -r '.properties.finding.enum[]' "$CS"); do
  check "playbook has a GOOD example for $code" grep -q "GOOD $code:" "$PB"
  check "playbook has a NEVER example for $code" grep -q "NEVER $code:" "$PB"
done
check "architect broke a law is a finding that the owner acts on" jq -e '."$defs".finding_codes.default["CO-LAW-ARCHITECT"].acts=="owner"' "$CS"

# AC-H2: the report schema accepts the sample and refuses what it should
check "the schema is itself a valid schema" python3 -I -c "import json,jsonschema,sys; jsonschema.Draft202012Validator.check_schema(json.load(open(sys.argv[1])))" "$CS"
check "sample report validates" validate "$SAMPLE" "$CS"
refuse "unknown finding code fails" validate "$(variant '.finding="CO-MADE-UP"')" "$CS"
refuse "wrong who-acts for a finding fails" validate "$(variant '.acts="owner"')" "$CS"
refuse "architect law break acted on by the orchestrator fails" validate "$(variant '.finding="CO-LAW-ARCHITECT" | .acts="orchestrator" | .key="x|CO-LAW-ARCHITECT"')" "$CS"
check "architect law break acted on by the owner validates" validate "$(variant '.finding="CO-LAW-ARCHITECT" | .acts="owner" | .key="architect|CO-LAW-ARCHITECT" | .seat="architect" | .ticket=null')" "$CS"
check "a dead belt process reported to the maintenance worker validates" validate "$(variant '.finding="CO-PROC-DEAD" | .acts="maintenance-worker" | .seat="belt" | .pane=null | .ticket=null | .key="belt|CO-PROC-DEAD" | .evidence=["no route.sh run in ps"]')" "$CS"
refuse "a dead process acted on by the orchestrator fails" validate "$(variant '.finding="CO-PROC-DEAD" | .acts="orchestrator" | .seat="belt" | .pane=null | .key="belt|CO-PROC-DEAD"')" "$CS"
refuse "a screen finding acted on by the maintenance worker fails" validate "$(variant '.acts="maintenance-worker"')" "$CS"
check "a hung seat reported to the orchestrator validates" validate "$(variant '.finding="CO-HUNG" | .key="tester-wo-20261013-aaaa|CO-HUNG" | .evidence=["Running... (23m 40s)"]')" "$CS"
refuse "missing evidence fails" validate "$(variant 'del(.evidence)')" "$CS"
refuse "empty evidence fails" validate "$(variant '.evidence=[]')" "$CS"
refuse "a local time stamp fails" validate "$(variant '.first_seen="2026-10-13T01:00:00+02:00"')" "$CS"
refuse "a ticket without its id shape fails" validate "$(variant '.ticket="WO-1"')" "$CS"
refuse "an extra field fails" validate "$(variant '.fix="restarted it"')" "$CS"
refuse "another reporter fails" validate "$(variant '.reporter="monitor"')" "$CS"

echo "compliance officer: $pass passed, $fail failed"
[ "$fail" = 0 ]
