#!/usr/bin/env bash
# Catches: the tester or merger role running on claude-haiku-5-5 again. Haiku testers and mergers misread test plans and gate
# records on 2026-10-12 and 2026-10-13, and the owner moved both roles to claude-sonnet-5-5 (WO-20261013-0f18). roles/ has no
# suite of its own, so the herdr suite pins the models the way 23-compliance-officer pins its role. Rejected alternative: pinning
# only the role JSON; the playbook is what a seat reads, so the rendered playbook is pinned too. Costs nothing: pure jq and grep.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"
R="${REPO_ROOT:-/repo}"
for role in tester merger; do
  assert_eq "roles/$role.json model.claude" "$(jq -r .model.claude "$R/roles/$role.json")" "claude-sonnet-5-5"
  pb="$(grep -m1 '^Runtime ' "$R/playbooks/$role.md")"
  assert_match "playbooks/$role.md names the sonnet model" "$pb" 'Model claude-sonnet-5-5'
  check "playbooks/$role.md never names haiku" "$(grep -qi haiku "$R/playbooks/$role.md" && echo 0 || echo 1)"
done
check "playbooks match the roles (no render drift)" "$(bash "$R/roles/bin/render-playbook.sh" "$R/roles" "$R/playbooks" --check >/dev/null 2>&1 && echo 1 || echo 0)"
case_done
