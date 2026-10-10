#!/usr/bin/env bash
# Podman test harness for tools/bearings (Rule 14: all testing in Podman).
# Builds the pinned image once, then runs tests/inside.sh in it with the tool
# mounted read-only and a scratch dir for state, network disabled.
#   tests/run-tests.sh                 run everything
#   tests/run-tests.sh --image-only    build the image and stop
#   tests/run-tests.sh --lint-only     schema-validate config only
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); TOOL=$(cd "$HERE/.." && pwd)
IMAGE=localhost/coq-bearings-test:1
command -v podman >/dev/null || { echo "podman is required" >&2; exit 4; }
if ! podman image exists "$IMAGE"; then
  podman build -q -t "$IMAGE" -f "$HERE/Containerfile" "$HERE" >/dev/null
fi
[ "${1:-}" = --image-only ] && { echo "image $IMAGE ready"; exit 0; }
SCRATCH=$(mktemp -d); trap 'rm -rf "$SCRATCH"' EXIT
MODE=${1:-all}
podman run --rm --network=none --userns=keep-id -e HOME=/work -e MODE="$MODE" \
  -v "$TOOL:/skill:ro,Z" -v "$SCRATCH:/work:Z" -w /work "$IMAGE" bash /skill/tests/inside.sh
