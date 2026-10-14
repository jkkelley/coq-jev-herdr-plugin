#!/usr/bin/env bash
# 02-gate-pipeline.test.sh - the Jenkinsfile and the shared library coqGate() are what the ticket says (WO-20261013-ab25, AC-H1 to AC-H4
# are proven live, see ci/README.md "Proving the human criteria"; this is the part a shell can prove).
#   bash ci/tests/cases/02-gate-pipeline.test.sh               static checks, and the plan script run against a scratch repository
#   CI_GROOVY=1 bash ci/tests/cases/02-gate-pipeline.test.sh   also parses coqGate.groovy and the Jenkinsfile in a groovy container
# Exit: 0 every check passed, 1 a check failed, 4 a needed tool is missing.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
JF="$REPO_ROOT/Jenkinsfile"
LIB="$REPO_ROOT/ci/jenkins-lib/vars/coqGate.groovy"
CFG="$REPO_ROOT/ci/config/images.json"
FAILED=0
ok() { echo "  ok   - $1"; }
bad() { echo "  FAIL - $1"; FAILED=1; }
check() { if [ "$2" = 1 ]; then ok "$1"; else bad "$1"; fi; }
for t in jq git grep sed; do command -v "$t" >/dev/null || { echo "need $t" >&2; exit 4; }; done
# code NAME FILE: the file without whole-line comments, so a breadcrumb that names a forbidden thing does not trip a check for it
code() { grep -vE '^\s*//' "$1"; }
has() { code "$2" | grep -qE -- "$1" && echo 1 || echo 0; }
lacks() { code "$2" | grep -qE -- "$1" && echo 0 || echo 1; }

echo "== Jenkinsfile"
check "no pollSCM: the webhook is the trigger" "$(lacks 'pollSCM' "$JF")"
check "githubPush stays, so the single-branch job keeps its trigger" "$(has 'githubPush\(\)' "$JF")"
check "a newer push aborts the older build (abortPrevious)" "$(has 'disableConcurrentBuilds\(abortPrevious: true\)' "$JF")"
check "it loads the library and calls coqGate()" "$([ "$(has "@Library\\('coq-ci'\\) _" "$JF")" = 1 ] && [ "$(has 'coqGate\(' "$JF")" = 1 ] && echo 1 || echo 0)"
check "no pipeline-level agent, so a fork reaches no pod before the guard" "$(code "$JF" | sed -n '/^pipeline {/,/options/p' | grep -qE 'agent none' && echo 1 || echo 0)"
check "the stage that holds every pod is guarded by CHANGE_FORK" "$(code "$JF" | sed -n "/stage('Checks')/,/parallel/p" | grep -qE 'when \{ expression \{ !env\.CHANGE_FORK \} \}' && echo 1 || echo 0)"
check "the lint pod and the Blueprint stage are still there" "$([ "$(has 'ghcr.io/jkkelley/coq-lint:1' "$JF")" = 1 ] && [ "$(has "stage\\('Blueprint'\\)" "$JF")" = 1 ] && [ "$(has 'bash lint/lint.sh' "$JF")" = 1 ] && echo 1 || echo 0)"
want="$(jq -r '.registry + "/coq-test:" + .images["coq-test"].version' "$CFG")"
check "the Jenkinsfile passes the test image ci/config/images.json builds ($want)" "$(code "$JF" | grep -qF "image: '$want'" && echo 1 || echo 0)"
hostonly="$(code "$JF" | grep -o "hostOnly: \[[^]]*\]" | sed 's/hostOnly: //' | tr "'" '"')"
check "every hostOnly suite in the Jenkinsfile is a suite of factory/config/suites.json" "$(jq -e --argjson h "${hostonly:-[]}" '.commands as $c | ($h | length > 0) and all($h[]; . as $x | $c | has($x))' "$REPO_ROOT/factory/config/suites.json" >/dev/null 2>&1 && echo 1 || echo 0)"

echo "== library: status, fork guard, ladder"
check "it posts the coq/gate status through githubNotify, on the head sha" "$([ "$(has "String context = 'coq/gate'" "$LIB")" = 1 ] && [ "$(has 'githubNotify\(' "$LIB")" = 1 ] && [ "$(has 'sha: sha' "$LIB")" = 1 ] && echo 1 || echo 0)"
check "it posts pending first and every final state: success, failure, error" "$([ "$(has "'PENDING'" "$LIB")" = 1 ] && [ "$(has "'SUCCESS'" "$LIB")" = 1 ] && [ "$(has "'FAILURE'" "$LIB")" = 1 ] && [ "$(has "'ERROR'" "$LIB")" = 1 ] && echo 1 || echo 0)"
check "a superseded build ends not-success with the description 'superseded', never pending" "$(code "$LIB" | grep -A2 'catch (FlowInterruptedException e)' | grep -qE "'ERROR', 'superseded" && echo 1 || echo 0)"
check "an abort is rethrown, only our timeout is a result" "$(code "$LIB" | grep -qE 'if \(!timedOut\(e\)\) \{ throw e \}' && echo 1 || echo 0)"
check "the fork guard refuses a CHANGE_FORK head before any pod" "$(code "$LIB" | sed -n '/^def call/,/String sha/p' | grep -qE 'if \(env\.CHANGE_FORK\)' && echo 1 || echo 0)"
check "the test command's exit code is a result (returnStatus), so an assertion is never retried" "$([ "$(has 'sh\(returnStatus: true' "$LIB")" = 1 ] && [ "$(has 'if \(r\.ok \|\| !r\.infra\) \{ return r \}' "$LIB")" = 1 ] && echo 1 || echo 0)"
check "rungs 1 to 3: three waits" "$(code "$LIB" | grep -qE 'retryWaitSeconds: \[[0-9]+, [0-9]+, [0-9]+\]' && echo 1 || echo 0)"
check "rung 4: one clean re-run on a fresh pod after a cool-down" "$([ "$(has 'cleanRerunWaitSeconds: [0-9]+' "$LIB")" = 1 ] && [ "$(has 'rung 4: clean re-run' "$LIB")" = 1 ] && [ "$(has 'int attempts = waits\.size\(\) \+ 2' "$LIB")" = 1 ] && echo 1 || echo 0)"
check "rung 5: red, the log link as the target URL, and a page" "$([ "$(has 'targetUrl: "\$\{env\.BUILD_URL\}console"' "$LIB")" = 1 ] && [ "$(has "'coq/gate-page'" "$LIB")" = 1 ] && echo 1 || echo 0)"
check "the status post itself retries 3 times" "$(has 'retry\(3\) \{ githubNotify' "$LIB")"
check "the library has no pollSCM and one loop only: the queue the pod slots drain" "$([ "$(lacks 'pollSCM' "$LIB")" = 1 ] && [ "$(code "$LIB" | grep -c 'while (true)')" = 1 ] && echo 1 || echo 0)"
check "the image comes from the caller; the library names no registry and no tag" "$(lacks 'ghcr\.io|coq-test:' "$LIB")"

echo "== library: pod spec"
spec="$(code "$LIB" | sed -n '/private String podYaml/,/^"""/p')"
check "no service account token, no service links" "$(printf '%s\n' "$spec" | grep -q 'automountServiceAccountToken: false' && printf '%s\n' "$spec" | grep -q 'enableServiceLinks: false' && echo 1 || echo 0)"
check "imagePullPolicy Always and the ghcr pull secret" "$(printf '%s\n' "$spec" | grep -q 'imagePullPolicy: Always' && printf '%s\n' "$spec" | grep -q 'name: ghcr-pull-secret' && echo 1 || echo 0)"
check "runs as user 1000, not root" "$(printf '%s\n' "$spec" | grep -q 'runAsUser: 1000' && printf '%s\n' "$spec" | grep -q 'runAsNonRoot: true' && echo 1 || echo 0)"
check "no env from a secret or config map, no AWS or page key, no podman" "$(printf '%s\n' "$spec" | grep -qiE 'secretKeyRef|configMapKeyRef|envFrom|secretRef|AWS_|PAGE_KEY|BEARINGS|podman' && echo 0 || echo 1)"
check "the container stays up for the plugin to exec in it (command cat), as the lint pod does" "$(printf '%s\n' "$spec" | grep -q 'command: \[cat\]' && echo 1 || echo 0)"
pod_manual="$REPO_ROOT/ci/pod/herdr-suite.pod.yaml"
check "the security lines match the manual pod spec of ticket 1" "$(for l in 'automountServiceAccountToken: false' 'enableServiceLinks: false' 'runAsUser: 1000' 'imagePullPolicy: Always' 'name: ghcr-pull-secret'; do grep -q "$l" "$pod_manual" || echo no; done | grep -q no && echo 0 || echo 1)"

echo "== the plan script, against a scratch repository"
W="$(mktemp -d /tmp/coq-gate-XXXX)"; trap 'rm -rf "$W"' EXIT
sed -n '/^# BEGIN-PLAN-SCRIPT/,/^# END-PLAN-SCRIPT/p' "$LIB" | sed 's/\\\\/\\/g' > "$W/plan.sh"
check "the plan script was found in the library" "$([ -s "$W/plan.sh" ] && echo 1 || echo 0)"
if command -v shellcheck >/dev/null; then check "the plan script is shellcheck clean" "$(shellcheck -s bash "$W/plan.sh" >/dev/null 2>&1 && echo 1 || echo 0)"; fi
R="$W/repo"; mkdir -p "$R/factory/bin" "$R/factory/config"
cp "$REPO_ROOT/factory/bin/suites.sh" "$R/factory/bin/"; cp "$REPO_ROOT/factory/config/suites.json" "$R/factory/config/"
for s in herdr factory; do mkdir -p "$R/$s/tests/cases"; ( cd "$REPO_ROOT/$s/tests/cases" && ls ./*.test.sh ) | while read -r f; do : > "$R/$s/tests/cases/${f#./}"; done; done
git -C "$R" init -q -b main && git -C "$R" config user.email t@t && git -C "$R" config user.name t
git -C "$R" add -A && git -C "$R" commit -qm base && git -C "$R" update-ref refs/remotes/origin/main HEAD
nherdr="$(ls "$R"/herdr/tests/cases | wc -l)"; nfactory="$(ls "$R"/factory/tests/cases | wc -l)"
plan() { # plan FILE...: commit a change to FILE... on top of origin/main and print the plan script's JSON; HOSTONLY from the caller
  git -C "$R" reset -q --hard origin/main
  local f; for f in "$@"; do mkdir -p "$R/$(dirname "$f")"; echo x >> "$R/$f"; done
  git -C "$R" add -A && git -C "$R" commit -qm change
  ( cd "$W" && COQ_PLAN_REPO="$R" COQ_TARGET=main COQ_SHA="$(git -C "$R" rev-parse HEAD)" COQ_HOST_ONLY="${HOSTONLY:-}" bash "$W/plan.sh" 2>"$W/err" )
}
out="$(plan README.md)"
check "a markdown-only change plans lint and nothing else: one pod" "$(jq -e 'map(.suite) == ["lint"] and .[0].cmd == "make lint" and .[0].skip == false' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
out="$(plan changelog/2026/10/x.md)"
check "a changelog-only change plans lint and reindex and no pod for herdr" "$(jq -e 'map(.suite) == ["lint","reindex"]' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
out="$(plan work-orders/WO-1.md)"
check "a ticket change plans reindex and exactly herdr case 12, one pod, run by --case" "$(jq -e '[.[] | select(.suite=="herdr")] | length == 1 and .[0].cmd == "bash /repo/herdr/tests/run.sh --case 12-blueprint-panes" and .[0].dir == "/repo/herdr/tests" and .[0].name == "herdr:12-blueprint-panes"' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
out="$(plan herdr/bin/seat.sh)"
check "a herdr change plans one pod for every herdr case ($nherdr)" "$(jq -e --argjson n "$nherdr" '[.[] | select(.suite=="herdr")] | length == $n and all(.[]; .cmd | test("^bash /repo/herdr/tests/run.sh --case "))' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
out="$(plan factory/bin/route.sh)"
check "a factory change plans one pod for every factory case ($nfactory)" "$(jq -e --argjson n "$nfactory" '[.[] | select(.suite=="factory")] | length == $n' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
check "every other suite is one pod running its planned command from /repo" "$(jq -e 'all(.[] | select(.suite != "herdr" and .suite != "factory"); .dir == "/repo" and .cmd != "" and .name == .suite)' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
out="$(cd "$W" && COQ_PLAN_REPO="$R" COQ_SHA=x COQ_HOST_ONLY="scheduler bearings" bash "$W/plan.sh" 2>"$W/err")"
check "a push to main (no target) plans the full set" "$(jq -e --argjson h "$nherdr" --argjson f "$nfactory" '([.[] | select(.suite=="herdr")] | length == $h) and ([.[] | select(.suite=="factory")] | length == $f) and (map(.suite) | index("loop") != null)' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
check "hostOnly suites are marked skip, the rest are not" "$(jq -e 'all(.[]; .skip == (.suite == "scheduler" or .suite == "bearings")) and ([.[] | select(.skip)] | length == 2)' <<<"$out" >/dev/null 2>&1 && echo 1 || echo 0)"
( cd "$W" && COQ_PLAN_REPO="$R" COQ_TARGET=main COQ_SHA=0000000000000000000000000000000000000000 bash "$W/plan.sh" >"$W/bad.out" 2>"$W/err" ); rc=$?
check "a plan that cannot be made fails the pod with a message and no output, it is not an empty plan" "$([ "$rc" != 0 ] && [ -s "$W/err" ] && [ ! -s "$W/bad.out" ] && echo 1 || echo 0)"

if [ "${CI_GROOVY:-0}" = 1 ]; then
  echo "== groovy parse (CI_GROOVY=1)"
  command -v podman >/dev/null || { echo "CI_GROOVY=1 needs podman" >&2; exit 4; }
  parse='import org.codehaus.groovy.control.*; for (f in args) { def cu = new CompilationUnit(); cu.addSource(new File(f)); cu.compile(Phases.CONVERSION) }'
  check "coqGate.groovy and the Jenkinsfile parse as Groovy" "$(podman run --rm -v "$REPO_ROOT:/r:ro" docker.io/library/groovy:4 groovy -e "$parse" /r/ci/jenkins-lib/vars/coqGate.groovy /r/Jenkinsfile >"$W/groovy.log" 2>&1 && echo 1 || { sed 's/^/         /' "$W/groovy.log" | tail -20 >&2; echo 0; })"
fi

[ "$FAILED" = 0 ] && { echo "gate pipeline: all ok"; exit 0; } || { echo "gate pipeline: failures" >&2; exit 1; }
