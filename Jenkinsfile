// Jenkinsfile - lint on every push, in Jenkins, never in a pane by hand.
// Owner, chat 2026-10-10 UTC: "No way AWS do any of this by hand. We shouldn't either."
// `**/bin/` in .gitignore dropped every factory script from PR #1 and local lint
// still passed, because the worktree had the files; a clean clone in CI is the only
// lint that proves the repository. Same steps as `make lint` (lint/lint.sh), run
// inside the same image, built from lint/Containerfile and pushed to GHCR as
// ghcr.io/jkkelley/coq-lint:1. Job: coq-jev-herdr-plugin, single-branch, scriptPath Jenkinsfile.
pipeline {
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
    options { timestamps(); timeout(time: 15, unit: 'MINUTES'); disableConcurrentBuilds() }
    triggers { githubPush(); pollSCM('H/10 * * * *') }
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
