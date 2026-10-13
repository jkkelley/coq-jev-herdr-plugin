#!/usr/bin/env bash
# build.sh - build the CI test image for every platform in ci/config/images.json and push it to GHCR (WO-20261013-8573).
#   build.sh [--image NAME] [--no-push]      NAME defaults to coq-test; --no-push builds the manifest locally and stops
# The registry, the version, the base digest and the herdr release are read from ci/config/images.json; this script holds none of them.
# Push credentials come from `gh auth token` (scope write:packages) into a throw-away authfile, so nothing is left in podman's own login store.
# Each build and push is tried up to 3 times (an apt mirror or a registry blip is an infrastructure failure, never a reason to hand-run it),
# then it reports and stops. Cross-building arm64 on an amd64 host needs qemu-user binfmt (/proc/sys/fs/binfmt_misc/qemu-aarch64), as `make lint-image-push` does.
# Exit: 0 ok, 2 usage, 3 invalid config, 4 build or push failed after 3 attempts.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
CONFIG="${COQ_IMAGES_CONFIG:-$REPO_ROOT/ci/config/images.json}"

name="coq-test"; push=1
while [ $# -gt 0 ]; do
  case "$1" in
    --image) [ $# -ge 2 ] || { echo "build.sh: --image needs a name" >&2; exit 2; }; name="$2"; shift 2 ;;
    --no-push) push=0; shift ;;
    -h|--help) sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "build.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

cfg() { jq -er "$1" "$CONFIG" 2>/dev/null; }
registry="$(cfg .registry)" || { echo "build.sh: no registry in $CONFIG" >&2; exit 3; }
version="$(cfg ".images[\"$name\"].version")" || { echo "build.sh: no image '$name' in $CONFIG" >&2; exit 3; }
containerfile="$(cfg ".images[\"$name\"].containerfile")" || exit 3
base="$(cfg ".images[\"$name\"].base")" || exit 3
herdr_version="$(cfg ".images[\"$name\"].herdr.version")" || exit 3
sha_amd64="$(cfg ".images[\"$name\"].herdr.sha256.amd64")" || exit 3
sha_arm64="$(cfg ".images[\"$name\"].herdr.sha256.arm64")" || exit 3
platforms="$(cfg '.platforms | join(",")')" || exit 3
ref="$registry/$name:$version"

retry() { # retry CMD... : 3 attempts, then report
  local n
  for n in 1 2 3; do
    "$@" && return 0
    echo "build.sh: attempt $n of 3 failed: $*" >&2
    sleep $((n * 5))
  done
  return 1
}

build() {
  podman manifest rm "$ref" >/dev/null 2>&1 || true
  podman build -q --platform "$platforms" --manifest "$ref" -f "$REPO_ROOT/$containerfile" \
    --build-arg "BASE=$base" --build-arg "HERDR_VERSION=$herdr_version" \
    --build-arg "HERDR_SHA256_AMD64=$sha_amd64" --build-arg "HERDR_SHA256_ARM64=$sha_arm64" "$REPO_ROOT/ci/image"
}

push() {
  podman manifest push --all --authfile "$AUTH" "$ref" "docker://$ref"
}

retry build || { echo "build.sh: could not build $ref after 3 attempts" >&2; exit 4; }
echo "built $ref ($platforms)"
[ "$push" = 1 ] || exit 0

AUTH="$(mktemp)"; echo "{}" > "$AUTH"; trap 'rm -f "$AUTH"' EXIT
user="$(gh api user -q .login 2>/dev/null)" || { echo "build.sh: gh is not logged in (gh auth login, scope write:packages)" >&2; exit 4; }
gh auth token 2>/dev/null | podman login ghcr.io -u "$user" --password-stdin --authfile "$AUTH" >/dev/null \
  || { echo "build.sh: podman login to ghcr.io failed" >&2; exit 4; }
retry push || { echo "build.sh: could not push $ref after 3 attempts" >&2; exit 4; }
echo "pushed $ref"
