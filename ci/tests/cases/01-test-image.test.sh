#!/usr/bin/env bash
# 01-test-image.test.sh - the CI test image carries what the suites need, no case needs podman, and (CI_POD=1) the herdr suite runs green in
# Kubernetes pods (WO-20261013-8573, acceptance AC-H1 to AC-H3).
#   bash ci/tests/cases/01-test-image.test.sh                 static checks, plus the tool check in the local image when one is built
#   CI_POD=1 bash ci/tests/cases/01-test-image.test.sh        also: every herdr case in its own pod in the cluster, and the pod environment check
#     CI_NAMESPACE=jenkins   namespace that holds ghcr-pull-secret   CI_SHA=<sha>  commit under test (pushed to origin; default HEAD)
#     JOBS=4                 pods at once                           CI_KEEP=1     leave the pods for inspection (default: deleted)
# Exit: 0 every check passed, 1 a check failed, 4 a needed tool is missing.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
CFG="$REPO_ROOT/ci/config/images.json"
POD_YAML="$REPO_ROOT/ci/pod/herdr-suite.pod.yaml"
CF="$REPO_ROOT/ci/image/Containerfile"
FAILED=0
ok() { echo "  ok   - $1"; }
bad() { echo "  FAIL - $1"; FAILED=1; }
check() { if [ "$2" = 1 ]; then ok "$1"; else bad "$1"; fi; }
for t in jq grep; do command -v "$t" >/dev/null || { echo "need $t" >&2; exit 4; }; done

name=coq-test
image="$(jq -r --arg n "$name" '.registry + "/" + $n + ":" + .images[$n].version' "$CFG")"
echo "== config: $image"
check "images.json names the registry, version, base digest and herdr checksums" "$(jq -e --arg n "$name" '.images[$n] | (.base | test("@sha256:[0-9a-f]{64}$")) and (.herdr.sha256.amd64 | length == 64) and (.herdr.sha256.arm64 | length == 64)' "$CFG" >/dev/null && echo 1 || echo 0)"
check "images.json builds for amd64 and arm64 (the cluster is arm64)" "$(jq -e '.platforms | index("linux/amd64") and index("linux/arm64")' "$CFG" >/dev/null && echo 1 || echo 0)"
if python3 -c 'import jsonschema' 2>/dev/null; then
  check "images.json matches images.schema.json" "$(python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$CFG" "${CFG%.json}.schema.json" 2>/dev/null && echo 1 || echo 0)"
fi

echo "== Containerfile and build.sh"
check "the Containerfile takes the base and herdr version from build args, never a literal" "$(grep -q '^FROM \${BASE}$' "$CF" && grep -q '^ARG HERDR_VERSION' "$CF" && ! grep -qE '^FROM .*@sha256' "$CF" && echo 1 || echo 0)"
check "herdr is checked against its sha256 before it is installed" "$(grep -q 'sha256sum -c' "$CF" && echo 1 || echo 0)"
check "the image installs no podman" "$(grep -vE '^\s*#' "$CF" | grep -qi podman && echo 0 || echo 1)"
check "build.sh reads the version from images.json (no literal ghcr tag)" "$(grep -vE '^\s*#' "$REPO_ROOT/ci/image/build.sh" | grep -qE 'ghcr\.io/jkkelley/coq-test|:1\b' && echo 0 || echo 1)"
check "build.sh retries 3 times" "$(grep -q 'for n in 1 2 3' "$REPO_ROOT/ci/image/build.sh" && echo 1 || echo 0)"

echo "== pod spec"
check "imagePullPolicy is Always on every container" "$(c=$(grep -c 'image: ' "$POD_YAML"); a=$(grep -c 'imagePullPolicy: Always' "$POD_YAML"); [ "$c" -ge 2 ] && [ "$c" = "$a" ] && echo 1 || echo 0)"
check "the pod pulls with ghcr-pull-secret" "$(grep -q 'name: ghcr-pull-secret' "$POD_YAML" && echo 1 || echo 0)"
check "the pod holds no service account token" "$(grep -q 'automountServiceAccountToken: false' "$POD_YAML" && echo 1 || echo 0)"
check "the pod takes no env from a secret or configmap" "$(grep -vE '^\s*#' "$POD_YAML" | grep -qE 'secretKeyRef|configMapKeyRef|envFrom|secretRef|AWS_|PAGE_KEY|BEARINGS' && echo 0 || echo 1)"
check "the pod runs the case with no podman" "$(grep -vE '^\s*#' "$POD_YAML" | grep -qi podman && echo 0 || echo 1)"

# "No case needs podman" is proved by running every case in a pod whose image has none (CI_POD=1 below), not by grepping herdr/bin: supervisor.sh
# does call `podman ps` on a real host, and case 19 runs it against herdr/tests/stubs/podman, which is why a grep would be a false alarm.

if command -v podman >/dev/null && podman image exists "$image" 2>/dev/null; then
  echo "== tools in the local image $image"
  tools="bash jq git python3 shellcheck make xmllint herdr procps pgrep tput"
  have="$(podman run --rm --network=none "$image" bash -c 'for t in '"$tools"'; do command -v "$t" >/dev/null && echo "$t"; done; command -v podman >/dev/null && echo PODMAN; herdr --version' 2>&1)"
  for t in $tools; do [ "$t" = procps ] && continue; check "image has $t" "$(printf '%s\n' "$have" | grep -qx "$t" && echo 1 || echo 0)"; done
  check "image has no podman" "$(printf '%s\n' "$have" | grep -qx PODMAN && echo 0 || echo 1)"
  want="$(jq -r --arg n "$name" '.images[$n].herdr.version' "$CFG")"
  check "herdr is $want" "$(printf '%s\n' "$have" | grep -q "^herdr $want" && echo 1 || echo 0)"
else
  echo "== tools in the image: skipped (no local $image; run ci/image/build.sh --no-push, or CI_POD=1)"
fi

if [ "${CI_POD:-0}" = 1 ]; then
  command -v kubectl >/dev/null && command -v envsubst >/dev/null || { echo "CI_POD=1 needs kubectl and envsubst" >&2; exit 4; }
  NS="${CI_NAMESPACE:-jenkins}"; SHA="${CI_SHA:-$(git -C "$REPO_ROOT" rev-parse HEAD)}"; JOBS="${JOBS:-4}"
  OUT="$(mktemp -d /tmp/coq-ci-pod-XXXX)"
  cleanup() { [ "${CI_KEEP:-0}" = 1 ] || kubectl -n "$NS" delete pod -l app.kubernetes.io/part-of=coq-ci --wait=false >/dev/null 2>&1; rm -rf "$OUT"; }
  trap cleanup EXIT
  VARS='${COQ_IMAGE} ${COQ_REPO_URL} ${COQ_SHA} ${COQ_SUITE} ${COQ_CASE} ${COQ_WORKDIR} ${COQ_CMD}'
  export COQ_IMAGE="$image" COQ_REPO_URL="${CI_REPO_URL:-https://github.com/jkkelley/coq-jev-herdr-plugin.git}" COQ_SHA="$SHA" COQ_SUITE=herdr COQ_WORKDIR=/repo/herdr/tests

  # run_pod LABEL CMD: one pod, wait for it, keep its log; returns 0 only when the case container exits 0.
  run_pod() {
    local label="$1" pod phase reason n=0
    export COQ_CASE="$label" COQ_CMD="$2"
    pod="$(envsubst "$VARS" < "$POD_YAML" | kubectl -n "$NS" create -f - -o name 2>"$OUT/$label.err")" \
      || { echo "create failed: $(cat "$OUT/$label.err")" > "$OUT/$label.log"; return 1; }
    while :; do
      phase="$(kubectl -n "$NS" get "$pod" -o jsonpath='{.status.phase}' 2>/dev/null)"
      case "$phase" in Succeeded|Failed) break ;; esac
      reason="$(kubectl -n "$NS" get "$pod" -o jsonpath='{.status.containerStatuses[*].state.waiting.reason}{.status.initContainerStatuses[*].state.waiting.reason}' 2>/dev/null)"
      case "$reason" in *ImagePullBackOff*|*ErrImagePull*|*CreateContainerConfigError*) echo "$pod stuck: $reason" > "$OUT/$label.log"; return 1 ;; esac
      n=$((n + 1)); [ "$n" -lt 400 ] || { echo "$pod still $phase after 20 minutes" > "$OUT/$label.log"; return 1; }
      sleep 3
    done
    kubectl -n "$NS" logs "$pod" -c case > "$OUT/$label.log" 2>&1
    kubectl -n "$NS" logs "$pod" -c checkout >> "$OUT/$label.log" 2>&1
    kubectl -n "$NS" get "$pod" -o jsonpath='{.spec.nodeName} {.status.containerStatuses[0].state.terminated.exitCode}{"\n"}' > "$OUT/$label.node" 2>/dev/null
    [ "$phase" = Succeeded ]
  }

  echo "== pod: tools, architecture and environment of $image at $SHA in namespace $NS"
  if run_pod tools "command -v podman && exit 9; uname -m; herdr --version; env | sort"; then
    envs="$(cat "$OUT/tools.log")"
    ok "a pod runs the image (no podman in it); node $(awk '{print $1}' "$OUT/tools.node"), $(printf '%s\n' "$envs" | grep -E '^(x86_64|aarch64)$' | head -1)"
    check "the pod environment holds no AWS variable" "$(printf '%s\n' "$envs" | grep -qE '^AWS_' && echo 0 || echo 1)"
    check "the pod environment holds no page key or token" "$(printf '%s\n' "$envs" | grep -qiE '^[A-Z_]*(PAGE_KEY|TOKEN|SECRET|PASSWORD|KEY)[A-Z_]*=' && echo 0 || echo 1)"
    check "the pod has no service account token mounted" "$(printf '%s\n' "$envs" | grep -qE '^KUBERNETES_SERVICE_HOST=' && echo 0 || echo 1)"
  else bad "the tools pod ran"; cat "$OUT/tools.log"; fi

  echo "== pod: every herdr case in its own pod, $JOBS at a time"
  mapfile -t cases < <(cd "$REPO_ROOT/herdr/tests/cases" && ls ./*.test.sh | sed 's|^\./||; s|\.test\.sh$||')
  running=0
  for c in "${cases[@]}"; do
    ( run_pod "$c" "bash /repo/herdr/tests/run.sh --case $c" && echo pass > "$OUT/$c.result" || echo FAIL > "$OUT/$c.result" ) &
    running=$((running + 1)); [ "$running" -lt "$JOBS" ] || { wait -n; running=$((running - 1)); }
  done
  wait
  pass=0; fail=0
  for c in "${cases[@]}"; do
    if [ "$(cat "$OUT/$c.result" 2>/dev/null)" = pass ]; then pass=$((pass + 1)); echo "  ok   - $c ($(awk '{print $1}' "$OUT/$c.node"))"
    else fail=$((fail + 1)); echo "  FAIL - $c"; sed 's/^/         /' "$OUT/$c.log" | tail -40; fi
  done
  echo "tests: $pass passed, $fail failed"
  [ "$fail" = 0 ] || FAILED=1
fi

[ "$FAILED" = 0 ] && { echo "ci image: all ok"; exit 0; } || { echo "ci image: failures" >&2; exit 1; }
