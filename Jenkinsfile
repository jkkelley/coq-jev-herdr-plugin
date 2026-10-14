// Jenkinsfile - lint on every push and the coq/gate status on every pull request and main push, in Jenkins, never in a pane by hand.
// Owner, chat 2026-10-10 UTC: "No way AWS do any of this by hand. We shouldn't either."
// `**/bin/` in .gitignore dropped every factory script from PR #1 and local lint
// still passed, because the worktree had the files; a clean clone in CI is the only
// lint that proves the repository. Same steps as `make lint` (lint/lint.sh), run
// inside the same image, built from lint/Containerfile and pushed to GHCR as
// ghcr.io/jkkelley/coq-lint:1. Job: coq-jev-herdr-plugin, scriptPath Jenkinsfile; a multibranch job with the GitHub Branch Source
// builds pull requests too (ci/README.md says how it is set up).
//
// BREADCRUMB 2026-10-14 - WO-20261013-ab25 (CI gate ticket 2). What broke: this file linted a push of main and nothing else, and it
//   polled (pollSCM every 10 minutes), so a pull request had no gate and a merge waited on a tester seat. Why this fix:
//   1. coqGate() (ci/jenkins-lib/vars/coqGate.groovy, registered as the global library `coq-ci`) plans the suites from the diff,
//      runs them as pods and posts coq/gate on the head sha. A GitHub webhook triggers the job (githubPush stays; pollSCM goes), so
//      nothing polls. Rejected: a second Jenkinsfile for the gate (two jobs to keep in step, and two statuses on one sha).
//   2. `agent none` at the top and the lint pod on its own stage: with a pipeline-level agent the lint pod starts before any `when`
//      runs, so a fork pull request would reach a pod. The fork guard is the `when` on Checks; coqGate() refuses a fork head too.
//      Cost: Lint and Blueprint are nested stages of one parent so they still share one pod, and cleanWs moved into that stage.
//   3. disableConcurrentBuilds(abortPrevious: true): a newer push to a branch aborts the older build and coqGate() ends the older
//      sha's status ERROR "superseded". Cost: a push to main can abort the build of the previous main push; the newest sha is the one
//      that matters.
//   4. Lint and the gate run side by side (parallel), so the lint pod's three minutes do not delay the gate. coq/gate also runs
//      `make lint` from the plan, so the two overlap on purpose: this stage keeps the existing lint pod and Blueprint stage as they were.
//   5. The test image below is the one ci/config/images.json builds; ci/tests/cases/02-gate-pipeline.test.sh fails when they differ.
//      The budgets are first guesses (herdr's pod deadline was 15 minutes in ci/pod/herdr-suite.pod.yaml) until WO-20261013-74b6
//      measures them. scheduler and bearings have no pod image, so they are planned and reported but not run (ci/README.md).
//   6. The timeout is 90 minutes, not 15: it now covers the gate, and a full run is about 50 pods, four at a time.
@Library('coq-ci') _
pipeline {
    agent none
    options { timestamps(); timeout(time: 90, unit: 'MINUTES'); disableConcurrentBuilds(abortPrevious: true) }
    triggers { githubPush() }
    stages {
        stage('Checks') {
            // A fork pull request builds nothing: no stage below starts, so no pod and no agent is allocated (CHANGE_FORK is set only for a fork).
            when { expression { !env.CHANGE_FORK } }
            parallel {
                stage('Lint and Blueprint') {
                    agent {
                        kubernetes {
                            defaultContainer 'lint'
                            yaml '''
apiVersion: v1
kind: Pod
spec:
  imagePullSecrets:
    - name: ghcr-pull-secret
  containers:
    - name: lint
      image: ghcr.io/jkkelley/coq-lint:1
      # Always: build 2 reused the node's cached amd64 image under the same tag after the
      # multi-arch push and died again with exec format error (2026-10-10 UTC).
      imagePullPolicy: Always
      command: [cat]
      tty: true
'''
                        }
                    }
                    stages {
                        stage('Lint') {
                            steps { sh 'bash lint/lint.sh "$WORKSPACE"' }
                        }
                        // WO-20261011-ceea. The blueprint (report/loop view, report/blueprint tiers) reads graph/ and work-orders/, so a change to
                        // any of the three can break it; a change elsewhere cannot, so the suite runs only then ("when smartly needed", owner
                        // 2026-10-11 18:47Z). The pod is already the lint image (jq, python3 jsonschema, shellcheck), so run.sh runs its cases
                        // directly (LOOP_TEST_IN_CONTAINER=1) instead of re-executing itself in Podman, which the pod does not have. Rejected: the
                        // suite on every push (the board suite is the slow part of the run) and `make -C report/loop test` (the image has no make).
                        stage('Blueprint') {
                            when { anyOf { changeset 'report/**'; changeset 'graph/**'; changeset 'work-orders/**' } }
                            steps { sh 'LOOP_TEST_IN_CONTAINER=1 REPO_ROOT="$WORKSPACE" HOME=/tmp/home bash report/loop/tests/run.sh' }
                        }
                    }
                    post { cleanup { cleanWs() } }
                }
                stage('Gate') {
                    steps {
                        coqGate(
                            image: 'ghcr.io/jkkelley/coq-test:1',
                            hostOnly: ['scheduler', 'bearings'],
                            maxPods: 4,
                            budgetMinutes: [default: 30, herdr: 15, factory: 10]
                        )
                    }
                }
            }
        }
    }
}
