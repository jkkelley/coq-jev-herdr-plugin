// coqGate.groovy - the shared-library step the Jenkinsfile calls: plan the suites from the diff, fan them out as pod containers, post
// coq/gate on the head sha (WO-20261013-ab25, design 20261013194800-ci-gate-design.md ticket 2 and its 20:00Z, 20:04Z and 20:07Z amendments).
//
//   coqGate(image: 'ghcr.io/jkkelley/coq-test:1', hostOnly: ['scheduler'], maxPods: 4, budgetMinutes: [default: 30, herdr: 15])
//
//   image          required; the test image (ci/config/images.json names it, the Jenkinsfile passes it, ci/tests/cases/02 checks they agree)
//   hostOnly       suites with no pod image: planned, listed in the final description, never run here (ci/README.md, "Suites with no pod image")
//   maxPods        pods running at once (default 4, the jobs.cap of config/tests.json: every herdr case starts its own herdr server)
//   budgetMinutes  a map of suite name to minutes, with a `default` key: the timeout of one pod's test command
//   credentialsId, account, repo   passed to githubNotify only when given; a GitHub Branch Source job infers them
//   connectMinutes, retryWaitSeconds, cleanRerunWaitSeconds   the ladder; defaults below
// The status is `coq/gate` on the head sha: PENDING at the start, then SUCCESS, FAILURE (a test failed) or ERROR (superseded, or the
// infrastructure ladder ran out). When the ladder runs out a second status, `coq/gate-page`, goes ERROR on the same sha: that is the page.
//
// BREADCRUMB 2026-10-14 - WO-20261013-ab25. What broke: nothing posted a status the line could key on. The Jenkinsfile linted on a
//   push of main only (pollSCM every 10 minutes, one single-branch job), so a pull request had no gate, and merge.sh, the main verdict
//   and the tester seats (design tickets 3 to 5) had nothing to read. Why this shape, and the lines that look arbitrary:
//   1. Library, not Jenkinsfile stages: the library is registered as a Jenkins global library at a fixed ref (ci/README.md), so a pull
//      request cannot change the code that gates it. A library loaded from the pull request's own branch would let any branch run
//      arbitrary Groovy on the controller. Cost: a change to this file takes effect after it is merged, and the pull request that
//      changes it is gated by the old one.
//   2. The head sha comes from the build's SCMRevisionAction, not env.GIT_COMMIT and not a checkout: GIT_COMMIT is the merge commit
//      under the "merge with target" strategy, and a checkout needs a node, which is a pod that can itself fail before any status
//      could be posted. Rejected: ls-remote refs/pull/N/head inside the plan pod (the PENDING status would wait for a pod start).
//   3. Failures sort into two kinds by where they happen. A pod that does not come up, a checkout that fails, an agent that dies: the
//      step threw before or around the test, so it is infrastructure and climbs the ladder. The test command's own exit code is read
//      with returnStatus, so a failing assertion is a result, never an exception, never retried. A test that outlives its budget is a
//      failing test (the budget is the timeout step), not infrastructure. An abort (FlowInterruptedException that is not our timeout)
//      is rethrown: it is abortPrevious, and the older sha ends ERROR "superseded", never left PENDING.
//   4. Rungs 1 to 3 are the first three retries after a wait of 10, 30 and 90 seconds. Rung 4 is the clean re-run: one more fresh pod
//      (every attempt is a new pod, the plugin names them) after a five minute cool-down, so a node or a registry that is briefly
//      sick has time to recover. Rung 5 is red plus the page. Nothing here loops: the number of attempts is fixed at 5.
//   5. The page is a commit status, not a call out of the cluster. The cluster cannot reach the line (this host has no ingress), and
//      the line already receives GitHub status events by webhook (design amendment 20:20Z, ticket 6). Rejected: a Slack or HTTP page
//      (a new secret in a public repository's pipeline) and a PR comment (needs a token with write scope in the pod's reach).
//      Cost: the orchestrator's listener has to key on the `coq/gate-page` context, which ticket 6 owns.
//   6. The pod spec is built here and not read from ci/pod/herdr-suite.pod.yaml: that file is a one-shot pod whose container runs the
//      command and exits, and the Kubernetes plugin needs a container that stays up (`cat`) so it can exec the steps. The security
//      lines are the same ones (no service account token, no env from a secret, runAsUser 1000, imagePullPolicy Always).
//      Cost: two places say it; ci/tests/cases/02-gate-pipeline.test.sh checks both.
//   7. Every unit's checkout fetches the commit by sha from the public repository (the pod holds no credential), and /repo is a
//      writable emptyDir, not the read-only mount of the manual pod: the plugin execs in the container, there is no init container.
//   8. Fail-open for `hostOnly` suites, loudly: a full run would otherwise be red forever (scheduler and bearings have no image in
//      GHCR). The description names them on every status. Rejected: failing closed (merge.sh would never see a green main).
//
// The plan script below is plain bash and is run by ci/tests/cases/02-gate-pipeline.test.sh against a scratch repository.

import groovy.json.JsonSlurperClassic
import org.jenkinsci.plugins.github_branch_source.PullRequestSCMRevision
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException
import org.jenkinsci.plugins.workflow.steps.TimeoutStepExecution

def call(Map args = [:]) {
    Map cfg = settings(args)
    // The fork guard. The Jenkinsfile skips the whole stage for a fork so no agent pod starts; this refuses the same head if a
    // Jenkinsfile forgets to, so the step on its own never runs fork code.
    if (env.CHANGE_FORK) {
        error("coqGate: refusing a fork head (${env.CHANGE_FORK}); a fork pull request reaches no pod and no agent")
    }
    String sha = headSha()
    String repoUrl = scm.userRemoteConfigs[0].url
    String target = env.CHANGE_ID ? env.CHANGE_TARGET : ''
    String failure = null
    try {
        postStatus(cfg, sha, 'PENDING', 'planning the suites')
        Map planEnv = [COQ_TARGET: target, COQ_HOST_ONLY: cfg.hostOnly.join(' '), COQ_FETCH_ARGS: '']
        Map planned = runUnit(cfg, sha, repoUrl, [name: 'plan', suite: 'plan', dir: '/repo', cmd: planScript(), capture: true, env: planEnv])
        if (!planned.ok) {
            failure = finish(cfg, sha, [planned], [])
        } else {
            List runnable = []
            List skipped = []
            List units = parseUnits(planned.out)
            for (int i = 0; i < units.size(); i++) {
                Map u = units[i]
                if (u.skip) { if (!skipped.contains(u.suite)) { skipped << u.suite } } else { runnable << u }
            }
            postStatus(cfg, sha, 'PENDING', "running ${runnable.size()} pods" + (skipped ? " (not run: ${skipped.join(', ')})" : ''))
            List results = []
            List queue = new ArrayList(runnable)
            Map branches = [:]
            for (int i = 0; i < Math.min(cfg.maxPods, runnable.size()); i++) {
                branches["pod-slot-${i + 1}"] = {
                    while (true) {
                        Map u = queue.isEmpty() ? null : queue.remove(0)
                        if (u == null) { break }
                        results << runUnit(cfg, sha, repoUrl, u)
                    }
                }
            }
            if (!branches.isEmpty()) { parallel branches }
            failure = finish(cfg, sha, results, skipped)
        }
    } catch (FlowInterruptedException e) {
        // abortPrevious (or a person) ended this build: the sha must not stay PENDING.
        postStatus(cfg, sha, 'ERROR', 'superseded by a newer build')
        throw e
    } catch (Exception e) {
        postStatus(cfg, sha, 'ERROR', "coqGate failed: ${e.message}")
        throw e
    }
    // Raised here and not inside the try: the catch above would overwrite the FAILURE or ERROR that finish just posted.
    if (failure) { error(failure) }
}

// finish: the one place the verdict is chosen; returns the build's failure message, or null on success. A test failure is FAILURE; a unit whose infrastructure ladder ran out is ERROR, and
// pages. Several of each: the first failing unit names the status, the rest are counted.
private String finish(Map cfg, String sha, List results, List skipped) {
    List tests = []
    List infra = []
    for (int i = 0; i < results.size(); i++) {
        Map r = results[i]
        if (r.ok) { continue }
        if (r.infra) { infra << r } else { tests << r }
    }
    String note = skipped ? " (not run: ${skipped.join(', ')} - no pod image)" : ''
    if (!infra.isEmpty()) {
        Map r = infra[0]
        String d = "${r.name}: infrastructure failed after the ladder (${r.why})" + (infra.size() > 1 ? " +${infra.size() - 1} more" : '')
        postStatus(cfg, sha, 'ERROR', d)
        postStatus(cfg, sha, 'ERROR', "page the orchestrator: ${d}", 'coq/gate-page')
        return "coqGate: ${d}"
    }
    if (!tests.isEmpty()) {
        Map r = tests[0]
        postStatus(cfg, sha, 'FAILURE', "${r.name} failed" + (tests.size() > 1 ? " +${tests.size() - 1} more" : '') + note)
        return "coqGate: ${r.name} failed"
    }
    postStatus(cfg, sha, 'SUCCESS', (results.isEmpty() ? 'nothing to run' : "${results.size()} pods passed") + note)
    return null
}

// runUnit: one pod's work through the ladder. Returns [ok, infra, why, out]; never throws for a failure, only for an abort.
private Map runUnit(Map cfg, String sha, String repoUrl, Map unit) {
    List waits = cfg.retryWaitSeconds
    int attempts = waits.size() + 2    // the first try, rungs 1 to 3, rung 4
    Map r = [:]
    for (int i = 0; i < attempts; i++) {
        if (i > 0) {
            int wait = i <= waits.size() ? waits[i - 1] : cfg.cleanRerunWaitSeconds
            String rung = i <= waits.size() ? "rung ${i}: retry" : 'rung 4: clean re-run on a fresh pod'
            echo "coqGate ${unit.name}: infrastructure failure (${r.why}); ${rung} in ${wait}s"
            sleep time: wait, unit: 'SECONDS'
        }
        r = runPod(cfg, sha, repoUrl, unit)
        if (r.ok || !r.infra) { return r }
    }
    echo "coqGate ${unit.name}: rung 5, the ladder is spent (${r.why})"
    return r
}

private Map runPod(Map cfg, String sha, String repoUrl, Map unit) {
    int budget = (cfg.budgetMinutes[unit.suite] ?: cfg.budgetMinutes.default) as int
    String phase = 'provision'
    String out = ''
    int rc = -1
    List podEnv = ['HOME=/tmp/home', 'REPO_ROOT=/repo', 'SHELL=/bin/bash', 'COQ_TEST_IN_CONTAINER=1', 'LOOP_TEST_IN_CONTAINER=1',
                "COQ_REPO_URL=${repoUrl}", "COQ_SHA=${sha}", 'COQ_FETCH_ARGS=--depth 1']
    Map extra = unit.env ?: [:]
    for (String k : extra.keySet()) { podEnv << "${k}=${extra[k]}" }
    try {
        podTemplate(yaml: podYaml(cfg, unit.suite, budget), slaveConnectTimeout: cfg.connectMinutes * 60) {
            timeout(time: cfg.connectMinutes + budget, unit: 'MINUTES') {
                node(POD_LABEL) {
                    container('case') {
                        withEnv(podEnv) {
                            phase = 'checkout'
                            sh checkoutScript()
                            phase = 'test'
                            timeout(time: budget, unit: 'MINUTES') {
                                rc = sh(returnStatus: true, script: "cd ${unit.dir} && " + (unit.capture ? "{ ${unit.cmd}\n} > \"\$WORKSPACE/out.json\"" : unit.cmd))
                            }
                            if (unit.capture && rc == 0) { out = readFile('out.json') }
                        }
                    }
                }
            }
        }
    } catch (FlowInterruptedException e) {
        if (!timedOut(e)) { throw e }    // an abort, not our timeout
        if (phase == 'test') { return [name: unit.name, ok: false, infra: false, why: "test timed out after ${budget} minutes"] }
        return [name: unit.name, ok: false, infra: true, why: "${phase} timed out"]
    } catch (Exception e) {
        return [name: unit.name, ok: false, infra: true, why: "${phase}: ${e.message}"]
    }
    if (rc != 0) { return [name: unit.name, ok: false, infra: false, why: "exit ${rc}"] }
    return [name: unit.name, ok: true, infra: false, why: '', out: out]
}

// postStatus: a commit status on the head sha, retried 3 times (the GitHub API is a network call); a fourth failure fails the build loudly.
private void postStatus(Map cfg, String sha, String status, String description, String context = 'coq/gate') {
    Map a = [context: context, status: status, description: description.take(140), sha: sha, targetUrl: "${env.BUILD_URL}console"]
    for (String k : ['credentialsId', 'account', 'repo']) { if (cfg[k]) { a[k] = cfg[k] } }
    retry(3) { githubNotify(a) }
}

@NonCPS
private Map settings(Map args) {
    if (!args.image) { throw new IllegalArgumentException('coqGate: image is required (ci/config/images.json names it)') }
    Map cfg = [hostOnly: [], maxPods: 4, budgetMinutes: [default: 30], connectMinutes: 5,
               retryWaitSeconds: [10, 30, 90], cleanRerunWaitSeconds: 300]
    cfg.putAll(args)
    Map budgets = [default: 30]
    budgets.putAll(args.budgetMinutes ?: [:])    // a Jenkinsfile that names only some suites keeps the default
    cfg.budgetMinutes = budgets
    return cfg
}

@NonCPS
private String headSha() {
    def rev = currentBuild.rawBuild.getAction(jenkins.scm.api.SCMRevisionAction)?.revision
    String sha = rev instanceof PullRequestSCMRevision ? rev.pullHash : rev?.hash
    if (!sha) { throw new IllegalStateException('coqGate: the build has no SCM revision, so there is no head sha to post on') }
    return sha
}

@NonCPS
private boolean timedOut(FlowInterruptedException e) {
    for (def c : e.causes) { if (c instanceof TimeoutStepExecution.ExceededTimeout) { return true } }
    return false
}

@NonCPS
private List parseUnits(String json) {
    return new JsonSlurperClassic().parseText(json) as List
}

@NonCPS
private String podYaml(Map cfg, String suite, int budget) {
    // The deadline is the budget plus the connect time plus slack, so the timeout step (a test failure) always fires before the
    // kubelet kills the pod (which would read as a lost agent, that is infrastructure, and be retried).
    int deadline = (cfg.connectMinutes + budget + 5) * 60
    return """\
apiVersion: v1
kind: Pod
metadata:
  labels:
    app.kubernetes.io/part-of: coq-ci
    coq-ci/suite: "${suite.replaceAll('[^A-Za-z0-9_.-]', '-')}"
spec:
  restartPolicy: Never
  activeDeadlineSeconds: ${deadline}
  automountServiceAccountToken: false
  enableServiceLinks: false
  imagePullSecrets:
    - name: ghcr-pull-secret
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
  volumes:
    - name: repo
      emptyDir: {}
  containers:
    - name: case
      image: ${cfg.image}
      imagePullPolicy: Always
      command: [cat]
      tty: true
      resources:
        requests: { cpu: 1000m, memory: 256Mi }
        limits: { memory: 1Gi }
      volumeMounts:
        - { name: repo, mountPath: /repo }
"""
}

@NonCPS
private String checkoutScript() {
    return '''\
set -e
mkdir -p "$HOME"
cd /repo
git init -q .
git remote add origin "$COQ_REPO_URL"
git fetch -q $COQ_FETCH_ARGS origin "$COQ_SHA"
git checkout -q FETCH_HEAD
if [ -n "${COQ_TARGET:-}" ]; then git fetch -q origin "+refs/heads/$COQ_TARGET:refs/remotes/origin/$COQ_TARGET"; fi
'''
}

// The plan: what suites.sh says the diff needs, as JSON units for the pods. herdr and factory fan out to one pod per case (the
// per-case isolation of bin/test-cases.sh: a case audits /proc and kills processes); every other command is one pod. A suite named in
// COQ_HOST_ONLY is marked skip. Output is one JSON array on stdout and nothing else.
@NonCPS
private String planScript() {
    return '''\
# BEGIN-PLAN-SCRIPT
set -euo pipefail
cd "${COQ_PLAN_REPO:-/repo}"
if [ -n "${COQ_TARGET:-}" ]; then
  plan=$(bash factory/bin/suites.sh plan --base "origin/$COQ_TARGET" --head "$COQ_SHA")
else
  plan=$(bash factory/bin/suites.sh full)
fi
cfg=factory/config/suites.json
unit() { jq -cn --arg name "$1" --arg suite "$2" --arg dir "$3" --arg cmd "$4" --argjson skip "$5" '{name:$name,suite:$suite,dir:$dir,cmd:$cmd,skip:$skip}'; }
cases() { # cases SUITE ID...: one unit per case file whose name starts with an id, or per case when there is no id
  local s=$1 f c; shift
  for id in "${@:-}"; do
    for f in "$s"/tests/cases/"$id"*.test.sh; do
      c=$(basename "$f" .test.sh)
      unit "$s:$c" "$s" "/repo/$s/tests" "bash /repo/$s/tests/run.sh --case $c" false
    done
  done
}
{
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case $line in
      "make -C herdr test"|"make -C factory test")
        s=${line#make -C }; cases "${s%% *}" "" ;;
      CASES=*" bash "*"/tests/run.sh")
        rest=${line#CASES=}; ids=${rest%% bash *}; ids=${ids//\\"/}; s=${rest##* bash }
        # shellcheck disable=SC2086
        cases "${s%%/*}" $ids ;;
      *)
        s=$(jq -r --arg c "$line" '[.commands|to_entries[]|select(.value==$c)|.key][0] // "other"' "$cfg")
        case " ${COQ_HOST_ONLY:-} " in *" $s "*) skip=true ;; *) skip=false ;; esac
        unit "$s" "$s" /repo "$line" "$skip" ;;
    esac
  done <<<"$plan"
} | jq -cs '.'
# END-PLAN-SCRIPT
'''
}
