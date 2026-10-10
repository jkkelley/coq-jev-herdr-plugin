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
    }
    post { cleanup { cleanWs() } }
}
