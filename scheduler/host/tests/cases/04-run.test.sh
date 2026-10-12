#!/usr/bin/env bash
# Catches: the scheduler wrapper dropping a flag of the run contract (SPEC-16.H h-run-flags), mounting something the
# contract does not name or mounting a path somewhere other than its own path, passing an environment the config does not
# read, carrying a literal path, host or digest (AC-H3), or starting with no executor, no image or a bad config instead
# of refusing with the code that says why.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=../../../../herdr/tests/lib/assert.sh
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"
# shellcheck source-path=SCRIPTDIR source=../lib/world.sh
. "$HERE/../lib/world.sh"
world_up run
RUN="$SCHED/host/bin/run.sh"; F="$SCHED/config/scheduler.json"
edit() { jq "$1" "$F" > "$W/f.json" && cp "$W/f.json" "$F"; }   # one change to the rendered config
restore() { render_scheduler_json > "$F"; }

echo "-- the full podman line: contract flags, values from the config, env the config reads, each path at its own path"
executor_socket_up
out=$(bash "$RUN"); assert_eq "exit 0, podman's" "$?" 0
assert_eq "one log line names the image and the digest it resolved" \
  "$(jq -r '[.level, .comp, .msg, .image, .digest, .container] | join(" ")' <<<"$out")" \
  "info run image resolved coq-scheduler:1 $DIGEST coq-scheduler"
assert_match "the log line's ts is UTC with seconds" "$(jq -r .ts <<<"$out")" '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
want=(run --rm --init --network=none --userns=keep-id --sig-proxy=true
  --name coq-scheduler --memory 256m --stop-timeout 30
  -e "HOME=$W/home" -e COQ_HERDR_SESSION=scratch -e "COQ_REPO=$R" -e "COQ_SCHED_IMAGE_DIGEST=$DIGEST"
  -e COQ_SCHED_MODE=shadow -e "COQ_SCHED_REPO=$R"
  -e "COQ_SCHED_STATE_DIR=$W/state" -e "XDG_RUNTIME_DIR=$W/run"
  -v "$R:$R:ro" -v "$W/state:$W/state" -v "$W/run/coq-scheduler:$W/run/coq-scheduler"
  -v "$W/home/.local/state/coq:$W/home/.local/state/coq:ro"
  -v "$W/home/.treehouse/pool-a/slot/events:$W/home/.treehouse/pool-a/slot/events:ro"
  -v "$W/home/.treehouse/pool-b/slot/events:$W/home/.treehouse/pool-b/slot/events:ro"
  "coq-scheduler@$DIGEST" run --config "$F")
assert_eq "argv" "$(argv_of "$W/podman.argv")" "${want[*]}"
assert_eq "the repo's own log is not mounted twice" "$(grep -c "^$R/events" "$W/podman.argv")" 0
assert_eq "nothing else under HOME" "$(grep "^$W/home" "$W/podman.argv" | grep -cv -e '/.local/state/coq:' -e '/.treehouse/pool-')" 0
assert_eq "the state directories exist" "$(test -d "$W/state/shadow" && echo yes)" yes

echo "-- the mode is the pane's environment, read through the config's variable"
COQ_SCHED_MODE=active bash "$RUN"; assert_eq "exit 0" "$?" 0
assert_eq "active reaches the container" "$(grep -cx COQ_SCHED_MODE=active "$W/podman.argv")" 1

echo "-- AC-H3: no literal path, host or digest in run.sh outside its comments"
code=$(grep -v '^\s*#' "$RUN" | sed 's/ # .*$//')
assert_eq "no absolute path" "$(grep -cE "(^|[ \"'=(])/[A-Za-z]" <<<"$code")" 0
assert_eq "no host or registry" "$(grep -ciE 'localhost|docker\.io|ghcr\.io|\.local\b' <<<"$code")" 0
assert_eq "no digest" "$(grep -cE 'sha256:[0-9a-f]' <<<"$code")" 0

echo "-- refusals, each before podman runs"
rm -f "$W/podman.argv"
bash "$RUN" --detach 2>/dev/null; assert_eq "an argument is usage" "$?" 2
edit '."runtime.image" = "coq-scheduler@'"$DIGEST"'"'
err=$(bash "$RUN" 2>&1); assert_eq "an image by digest in the file is validation" "$?" 3; assert_match "naming the rule" "$err" "name and tag with no digest"
restore; edit '."runtime.image" = "coq-scheduler"'
bash "$RUN" 2>/dev/null; assert_eq "an image with no tag is validation" "$?" 3
restore; edit '."runtime.image_digest" = "sha256:1234"'
err=$(bash "$RUN" 2>&1); assert_eq "a digest key that is not a variable is validation" "$?" 3; assert_match "naming it" "$err" "runtime.image_digest"
restore; edit '."runtime.memory" = "${ENV:MEM}"'
err=$(bash "$RUN" 2>&1); assert_eq "a variable in a runtime key is validation" "$?" 3; assert_match "naming the key" "$err" "runtime.memory"
restore; edit 'del(."runtime.container_name")'
err=$(bash "$RUN" 2>&1); assert_eq "a missing runtime key is validation" "$?" 3; assert_match "naming it" "$err" "runtime.container_name missing"
restore; edit '."intake.roots" += ["${HOME}/nowhere-*/events"]'
err=$(bash "$RUN" 2>&1); assert_eq "a root that matches nothing is validation" "$?" 3; assert_match "naming it" "$err" 'nowhere-\*/events'
restore; unset COQ_HERDR_SESSION
err=$(bash "$RUN" 2>&1); assert_eq "an unset ENV name is validation" "$?" 3; assert_match "naming it" "$err" "COQ_HERDR_SESSION"
export COQ_HERDR_SESSION=scratch
COQ_REPO="$W/elsewhere" bash "$RUN" 2>/dev/null; assert_eq "a wrapper outside host_repo is validation" "$?" 3
: > "$W/podman.images"
err=$(bash "$RUN" 2>&1); assert_eq "an image not in local storage is io" "$?" 4; assert_match "and says how to build it" "$err" "make -C scheduler image"
echo "coq-scheduler:1 <none>" > "$W/podman.images"
err=$(bash "$RUN" 2>&1); assert_eq "an inspect with no digest is io" "$?" 4; assert_match "naming what it got" "$err" "<none>"
echo "coq-scheduler:1 $DIGEST" > "$W/podman.images"; rm "$XDG_RUNTIME_DIR/coq-scheduler/executor.sock"
err=$(bash "$RUN" 2>&1); assert_eq "no executor socket is io" "$?" 4; assert_match "and says to start the executor" "$err" "run-exec"
assert_eq "podman never ran" "$(test -e "$W/podman.argv" && echo ran || echo no)" no
case_done
