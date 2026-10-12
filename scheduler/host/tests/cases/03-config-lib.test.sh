#!/usr/bin/env bash
# Catches: the wrappers' variable resolution drifting from SPEC-16.G g-vars - an unknown variable or an unset ENV name
# becoming an empty path instead of exit 3, a missing key read as empty, nested variables left unresolved, or a value
# holding & mangled by bash's pattern replacement.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=../../../../herdr/tests/lib/assert.sh
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"
# shellcheck source-path=SCRIPTDIR source=../lib/world.sh
. "$HERE/../lib/world.sh"
world_up config-lib
# shellcheck source-path=SCRIPTDIR source=../../lib/config.sh
. "$SCHED/host/lib/config.sh"
F="$SCHED/config/scheduler.json"

echo "-- every form of g-vars resolves"
assert_eq "ENV" "$(cfg_resolve "$F" '${ENV:COQ_SCHED_MODE}')" shadow
assert_eq "HOME" "$(cfg_resolve "$F" '${HOME}/x')" "$W/home/x"
assert_eq "state_dir through its own ENV" "$(cfg_resolve "$F" '${state_dir}/belt')" "$W/state/belt"
assert_eq "host_repo" "$(cfg_resolve "$F" '${host_repo}/playbooks')" "$R/playbooks"
assert_eq "two in one string" "$(cfg_resolve "$F" '${host_repo}:${state_dir}')" "$R:$W/state"
assert_eq "CFG_REPO stands in for repo" "$(CFG_REPO=/r cfg_resolve "$F" '${repo}/events')" /r/events
assert_eq "an & in a value survives" "$(COQ_SCHED_MODE='a&b' cfg_resolve "$F" '${ENV:COQ_SCHED_MODE}')" 'a&b'
assert_eq "a key's raw value" "$(cfg_raw "$F" executor.socket)" '${ENV:XDG_RUNTIME_DIR}/coq-scheduler/executor.sock'
assert_eq "an array key, one item per line" "$(cfg_raw "$F" intake.roots | wc -l)" 2
assert_eq "the ENV names the file uses" "$(cfg_env_names "$F" | paste -sd' ')" \
  "COQ_HERDR_SESSION COQ_REPO COQ_SCHED_IMAGE_DIGEST COQ_SCHED_MODE COQ_SCHED_REPO COQ_SCHED_STATE_DIR XDG_RUNTIME_DIR"

echo "-- every failure is exit 3 naming what failed"
err=$( (cfg_resolve "$F" '${repo}/events') 2>&1); assert_eq "repo through an unset ENV" "$?" 3
assert_match "names the ENV" "$err" "ENV:COQ_SCHED_REPO is unset"
err=$( (cfg_resolve "$F" '${nope}/x') 2>&1); assert_eq "an unknown variable" "$?" 3
assert_match "names it" "$err" 'unknown variable \$\{nope\}'
err=$( (cfg_raw "$F" no.such.key) 2>&1); assert_eq "a missing key" "$?" 3
assert_match "names it" "$err" "key no.such.key missing"
jq 'del(.host_repo)' "$F" > "$W/s.json"
err=$( (cfg_resolve "$W/s.json" '${host_repo}/x') 2>&1); assert_eq "a variable whose key is missing" "$?" 3
assert_match "names the key" "$err" "key host_repo missing"
case_done
