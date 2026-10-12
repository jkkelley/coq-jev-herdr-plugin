#!/usr/bin/env bash
# run.sh - the scheduler container in the foreground of its herdr pane (SPEC-16.H h-run, h-pane). The command of the
# scheduler's monitors slot; bring-up and the supervisor restart it by running it again, with no verb of their own.
#
#   run.sh          exec podman run of the runtime image's run subcommand on scheduler/config/scheduler.json
#
# Every flag comes from scheduler.json or the environment it names, never from this file (h-run-wrapper, AC-H3):
#   runtime.image, runtime.memory, runtime.container_name   plain strings, read with jq: the image by name and tag, --memory,
#                                                           --name; the tag is resolved to a digest at start (h-run-digest)
#   drain_seconds                                           --stop-timeout, so a podman stop waits for the drain (f-drain)
#   every ${ENV:NAME} the file references                   passed into the container with the pane's value
# Fixed by the run contract (h-run-flags): rootless, --network=none, --userns=keep-id, --init, --rm, signals proxied.
#
# BREADCRUMB 2026-10-12 - WO-20261012-df2b. Why every host path is mounted at the same path inside the container: the
#   config's variables (g-vars) must resolve to the same directories on both sides, and any container path the wrapper
#   chose (/repo, /state) would be a literal path AC-H3 forbids and a second spelling of each directory the scheduler logs.
#   So repo, host_repo, state_dir and the socket's directory name one path each, inside and out; the variable that feeds
#   repo is set to the repository's mount point, which is host_repo. Rejected: mounting $HOME or the whole treehouse pool
#   (h-run-mounts: nothing from the home directory beyond the named paths) and mounting intake roots by their glob's
#   static prefix (it would bind every worktree's source, not only its log). Cost: intake root globs are expanded when
#   the wrapper starts, so a slot added to the pool later is read only after the scheduler pane restarts (RUNBOOK.md).
#   Record: blocked 20261012T195358Z-423-8ffcd, answered by sched-architect in 20261012T200406Z-100-xzrpm (runtime.* keys
#   and the ENV names).
# BREADCRUMB 2026-10-12 - WO-20261012-df2b. Why the tag is resolved here and not pinned in the file: a digest in
#   scheduler.json would go stale on every make -C scheduler image and is a literal the copy rule forbids, so the file names
#   the image by name and tag and the wrapper asks podman image inspect for the digest, logs it, runs <name>@<digest> and
#   passes it as the variable runtime.image_digest reads, so Status names the running build. A tag rebuilt while the
#   container runs does not change it; the next start picks the new build up. Rejected: running by tag (the build that
#   runs would be unknown to Status) and by image id (not a digest, and not what the spec names).
#   Record: correction 20261012T201032Z-100-yqm2x (SPEC-16.H 1.1.0 h-run-digest, SPEC-16.G 1.1.0 g-vars-env-digest).
#
# Exit codes: 0 ok, 2 usage, 3 validation (a key, a variable, a root that matches nothing), 4 io (no socket, no image),
# else podman's or the scheduler's.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); SCHED=$(cd "$HERE/../.." && pwd)
# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
. "$SCHED/host/lib/config.sh"
CFG_WHO=run

[ $# -eq 0 ] || cfg_die 2 "usage: run.sh (no arguments; everything comes from $SCHED/config/scheduler.json)"
CFG=$SCHED/config/scheduler.json
[ -f "$CFG" ] || cfg_die 4 "no config at $CFG"
command -v jq >/dev/null || cfg_die 4 "jq is not on PATH"
command -v podman >/dev/null || cfg_die 4 "podman is not on PATH"

plain() { # KEY: a runtime string, which carries no variable (SPEC-16.G g-runtime-group)
  local v; v=$(cfg_raw "$CFG" "$1") || exit $?
  [ -n "$v" ] && [[ $v != *'${'* ]] || cfg_die 3 "scheduler.json: $1 must be a plain non-empty string"
  printf '%s\n' "$v"
}
image=$(plain runtime.image); memory=$(plain runtime.memory); name=$(plain runtime.container_name)
[[ $image =~ ^[a-z0-9][a-z0-9._/-]*:[A-Za-z0-9_][A-Za-z0-9._-]*$ ]] ||
  cfg_die 3 "scheduler.json: runtime.image must be a name and tag with no digest (g-keys), got $image"
drain=$(cfg_raw "$CFG" drain_seconds); [[ $drain =~ ^[0-9]+$ ]] || cfg_die 3 "scheduler.json: drain_seconds is not an integer"

path_of() { local r; r=$(cfg_raw "$CFG" "$1") || exit $?; cfg_resolve "$CFG" "$r"; }
host_repo=$(path_of host_repo)
case $SCHED/ in "$host_repo"/*) ;; *) cfg_die 3 "this wrapper ($SCHED) is not inside host_repo ($host_repo); the container would read another config" ;; esac
export CFG_REPO=$host_repo
state=$(path_of state_dir); sock=$(path_of executor.socket); control=$(path_of control.socket)
belt=$(path_of belt.file); shadow=$(path_of shadow.dir); halt=$(path_of halt_flag)
[ -S "$sock" ] || cfg_die 4 "no executor socket at $sock; bring the executor pane up first (make -C scheduler run-exec)"
digest=$(podman image inspect --format '{{.Digest}}' "$image" 2>/dev/null) ||
  cfg_die 4 "image $image is not in local storage; run make -C scheduler image"
[[ $digest =~ ^sha256:[0-9a-f]{64}$ ]] || cfg_die 4 "podman image inspect gave no digest for $image (got '$digest')"
digest_raw=$(cfg_raw "$CFG" runtime.image_digest)
[[ $digest_raw =~ ^\$\{ENV:([A-Za-z_][A-Za-z0-9_]*)\}$ ]] ||
  cfg_die 3 "scheduler.json: runtime.image_digest must be one \${ENV:NAME} variable (g-vars-env-digest)"
digest_env=${BASH_REMATCH[1]}

# Mounts, each at its own path. A path inside one already mounted is skipped when that mount is read-write or both are
# read-only, so each directory is bound once with the strongest mode it needs.
mounts=(); mounted=()
mount_at() { # PATH ro|rw
  local p=$1 m=$2 e
  [[ $p == /* ]] || cfg_die 3 "scheduler.json: $p is not an absolute path"
  [[ $p != *[:,]* ]] || cfg_die 3 "scheduler.json: $p holds a ':' or ',' that a podman mount cannot carry"
  for e in "${mounted[@]}"; do
    case $p/ in "${e% *}"/*) [ "${e##* }" = rw ] || [ "$m" = ro ] && return 0 ;; esac
  done
  mounted+=("$p $m"); if [ "$m" = ro ]; then mounts+=(-v "$p:$p:ro"); else mounts+=(-v "$p:$p"); fi
}
mkdir -p "$state" "$(dirname "$control")" "$(dirname "$belt")" "$shadow" "$(dirname "$halt")" ||
  cfg_die 4 "cannot create the state directories under $state"
mount_at "$host_repo" ro
mount_at "$state" rw
mount_at "$(dirname "$control")" rw
mount_at "$(dirname "$belt")" rw
mount_at "$shadow" rw
mount_at "$(dirname "$sock")" rw
mount_at "$(dirname "$halt")" ro
roots=$(cfg_raw "$CFG" intake.roots)
while IFS= read -r raw; do
  pat=$(cfg_resolve "$CFG" "$raw"); n=0
  while IFS= read -r d; do [ -d "$d" ] || continue; mount_at "$d" ro; n=$((n + 1)); done < <({ compgen -G "$pat" || true; } | LC_ALL=C sort)
  [ "$n" -gt 0 ] || cfg_die 3 "scheduler.json: intake root $raw matches no directory (g-val-cross)"
done <<< "$roots"

# The environment: every name the file reads through ${ENV:...}, with the pane's value; the one that feeds repo gets the
# repository's mount point, which is host_repo (breadcrumb above). HOME passes through so ${HOME} resolves the same.
repo_env=""; repo_raw=$(cfg_raw "$CFG" repo)
[[ $repo_raw =~ ^\$\{ENV:([A-Za-z_][A-Za-z0-9_]*)\}$ ]] && repo_env=${BASH_REMATCH[1]}
envs=(-e "HOME=$HOME")
while IFS= read -r v; do
  if [ "$v" = "$repo_env" ]; then envs+=(-e "$v=$host_repo"); continue; fi
  if [ "$v" = "$digest_env" ]; then envs+=(-e "$v=$digest"); continue; fi
  [ -n "${!v:-}" ] || cfg_die 3 "scheduler.json: ENV:$v is unset in this pane"
  envs+=(-e "$v=${!v}")
done < <(cfg_env_names "$CFG")

# One log line in the shape of SPEC-16.I i-log-shape, so the pane shows which build starts before the scheduler's own lines.
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg image "$image" --arg digest "$digest" --arg name "$name" \
  '{ts: $ts, level: "info", comp: "run", msg: "image resolved", image: $image, digest: $digest, container: $name}'
exec podman run --rm --init --network=none --userns=keep-id --sig-proxy=true \
  --name "$name" --memory "$memory" --stop-timeout "$drain" \
  "${envs[@]}" "${mounts[@]}" \
  "${image%:*}@$digest" run --config "$CFG"
