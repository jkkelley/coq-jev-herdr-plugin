#!/usr/bin/env bash
# Catches: the compliance officer role (roles/compliance-officer.json), its playbook or its report schema drifting from what
# WO-20261013-5b33 asks: a role that can write or nudge, a playbook out of sync with the role, a finding code with no GOOD or
# NEVER example, a report schema that accepts an unknown finding code. The assertions live in roles/tests/compliance-officer.test.sh
# so they run from a plain shell too; this case is the one line that puts them in `make -C herdr test`, in Podman, with no herdr.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"
out="$(bash "${REPO_ROOT:-/repo}/roles/tests/compliance-officer.test.sh" "${REPO_ROOT:-/repo}" 2>&1)"; rc=$?
printf '%s\n' "$out" | tail -5
check "roles/tests/compliance-officer.test.sh passes" "$([ "$rc" = 0 ] && echo 1 || echo 0)"
assert_match "it ran every assertion, none failed" "$out" 'compliance officer: [0-9]+ passed, 0 failed'
case_done
