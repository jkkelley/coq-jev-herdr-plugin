# CI test image

## Contents

- What this is
- Build and push
- Pulling it: the ghcr-pull-secret
- Run one case in a pod by hand
- Run the whole herdr suite in pods
- Cleanup
- What the image does not cover
- Bumping herdr or the base

## What this is

`ghcr.io/jkkelley/coq-test:1` is the image the shell-family suites run in as Kubernetes pod containers: herdr, factory, line, events, loop, sitrep, scheduler-host and reindex.
It holds bash, jq, git, python3 with jsonschema, procps, ncurses, make, shellcheck, xmllint and a pinned herdr release.
It holds no podman: the pod is the isolation that `podman run` per case gave on the host.
It is built for linux/amd64 and linux/arm64, because the cluster nodes are arm64 Raspberry Pis (see the breadcrumb in `Containerfile`).
Every version, digest and checksum it is built from is in `ci/config/images.json`.
Design: `plans/2026/10/20261013194800-ci-gate-design.md` in the state root, ticket 1.

## Build and push

```sh
bash ci/image/build.sh --no-push   # build the multi-arch manifest locally, push nothing
bash ci/image/build.sh             # build, then push to ghcr.io/jkkelley/coq-test:<version>
```

The push logs in with `gh auth token` (scope `write:packages`) into a throw-away authfile.
Build and push each retry 3 times, then report with exit 4.
Cross-building arm64 on this amd64 host needs qemu-user binfmt, which `make lint-image-push` needs too.

## Pulling it: the ghcr-pull-secret

The pods pull with `imagePullSecrets: ghcr-pull-secret`, which exists in the `jenkins` namespace.
Pods must therefore run in that namespace, or the secret must be copied into the one they use.
The pod spec sets `imagePullPolicy: Always`, because a node once reused a cached amd64 image under the same tag after a multi-arch push.

## Run one case in a pod by hand

```sh
export COQ_IMAGE=ghcr.io/jkkelley/coq-test:1 COQ_REPO_URL=https://github.com/jkkelley/coq-jev-herdr-plugin.git \
  COQ_SHA=$(git rev-parse HEAD) COQ_SUITE=herdr COQ_CASE=05-recover COQ_WORKDIR=/repo/herdr/tests \
  COQ_CMD='bash /repo/herdr/tests/run.sh --case 05-recover'
envsubst '${COQ_IMAGE} ${COQ_REPO_URL} ${COQ_SHA} ${COQ_SUITE} ${COQ_CASE} ${COQ_WORKDIR} ${COQ_CMD}' < ci/pod/herdr-suite.pod.yaml \
  | kubectl -n jenkins create -f - -o name
kubectl -n jenkins logs -f pod/<name printed above> -c case
```

The commit must be pushed: the init container fetches it by sha from the public repository.

## Run the whole herdr suite in pods

```sh
CI_POD=1 bash ci/tests/cases/01-test-image.test.sh     # JOBS=4 pods at once; CI_SHA=<sha> to pick the commit
```

Each case is its own pod, so each has its own `/proc`, `HOME`, `/tmp` and herdr sessions (the reason is the breadcrumb in `bin/test-cases.sh`).
The test also runs a pod that prints its environment and asserts it holds no AWS variable, token or page key.

## Cleanup

```sh
kubectl -n jenkins delete pod -l app.kubernetes.io/part-of=coq-ci
podman rmi ghcr.io/jkkelley/coq-test:1   # the local manifest, on the host that built it
```

The test deletes its own pods when it ends unless `CI_KEEP=1`.

## What the image does not cover

- The Go scheduler suite (`make -C scheduler test`) needs a Go toolchain: its family keeps `scheduler/tests/Containerfile`, built on the golang image.
- The bearings browser suite (`tools/bearings`) needs playwright: it keeps its own image.
- Ticket 2 (the shared-library step) chooses whether those two run as further pod containers; neither needs this image's herdr.
- A case that proves it cannot run in a pod goes to the Jenkins host-agent fallback; none is known (see the test run in the ticket's notes).

## Bumping herdr or the base

Edit `ci/config/images.json` only: the herdr version and both checksums (`gh api repos/herdrdev/herdr/releases/tags/v<version> -q '.assets[]|[.name,.digest]|@tsv'`), or the base index digest (command in the `Containerfile` header), and the image `version`.
Then `build.sh`, and the test.
