# L07 - CI and pods

Investigated 2026-10-14T02:40Z (UTC) by the L07 investigator, step R-01.
All paths are relative to `/home/luna/projects/coq-jev-herdr-plugin` unless they start with `~` or `/`.
Line numbers are per file, from the main checkout at HEAD `5ad1996` (2026-10-14T01:44:08Z).

## 1. Contents

1. Contents
2. What it is
3. Where it lives
4. What works
5. What broke and why
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

The CI layer is a Jenkins pipeline (`Jenkinsfile`) plus a shared library step `coqGate()` that plans test suites from a pull request diff, runs each suite or herdr case as one Kubernetes pod on the owner's three-node Raspberry Pi cluster, and posts a GitHub commit status named `coq/gate` on the head sha.
It was designed on 2026-10-13 to replace tester seats that polled a test pane and stalled 9 to 14 minutes on a one-minute lint (`~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md` lines 20-23).
Three of its pieces are merged: the test image (PR 156), the gate library (PR 179) and the webhook listener (PR 177).
The evidence says the gate has never run: the library's Groovy was never executed on Jenkins (PR 179 body, "The Groovy has not run on Jenkins"), the repository has no webhook, no `coq/gate` status exists on any recent commit, and the two handlers that would act on a status do not exist.
So what "already runs as pods" is only the lint pod (since 2026-10-10) and hand-run proof pods created with `kubectl`.
The brief's framing that a system should drive the factory matches the design intent here.
The evidence disagrees with any assumption that this part is finished: it is a designed, merged, unwired and untriggered system.

## 3. Where it lives

- `Jenkinsfile` (87 lines): loads library `coq-ci`, runs a lint pod and calls `coqGate()` in parallel.
- `ci/jenkins-lib/vars/coqGate.groovy` (326 lines): the gate step, the pod spec, the retry ladder and the plan script.
- `ci/image/Containerfile`, `ci/image/build.sh`, `ci/config/images.json` (+ schema): the test image `ghcr.io/jkkelley/coq-test:1`.
- `ci/pod/herdr-suite.pod.yaml`: the manual one-shot pod spec used by the proof test.
- `ci/tests/cases/01-test-image.test.sh` and `02-gate-pipeline.test.sh`: static checks plus an opt-in live pod run (`CI_POD=1`).
- `ci/README.md` (202 lines) and `ci/image/README.md` (82 lines): the setup runbook, with the Jenkins steps that were not done.
- `lint/lint.sh`, `lint/Containerfile`, `lint/check-conflict-markers.sh`: the static checks and the lint image `ghcr.io/jkkelley/coq-lint:1`.
- `factory/bin/suites.sh` and `factory/config/suites.json`: the diff-to-suites planner that `coqGate()` calls.
- `bin/test-cases.sh` and `config/tests.json`: the host-side parallel case runner (cap 4).
- `line/bin/hook-listener.sh`, `line/config/hook.json`, `line/units/coq-hook-*.service`: the GitHub event listener (PR 177).
- `line/bin/verify-main.sh`: the host-side full-suite run on main, still the live path.
- `Makefile`: the human entry points (`make lint`, `make test`, `make lint-image-push`).
- `tools/` holds only `tools/bearings` (the owner page server and its playwright suite).
- `tools/` contains no CI tooling, so the brief's `tools/` item is bearings, covered by L08.
- Design: `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md` (149 lines, four amendments).
- Test-speed design: `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013160000-test-speed-design.md`.
- The cluster: kubeconfig contexts `homelab-admin` (default, `https://192.168.1.248:6443`), `mcp-viewer@homelab`, an EKS context `eks-upgrade-dev` and a local kind context.
- Jenkins UI: `jenkins.homelab.local`, ingress class haproxy, address `192.168.1.245` (a private LAN address).
- Registry: `ghcr.io/jkkelley/coq-test:1` (pushed 2026-10-13T22:00:13Z) and `ghcr.io/jkkelley/coq-lint:1` (pushed 2026-10-10T20:04:34Z).
- Repository: `jkkelley/coq-jev-herdr-plugin`, public, default branch `main`.

### The cluster, read live on 2026-10-14

- Three nodes, all arm64 Raspberry Pi (kernel `6.8.0-1064-raspi`), Ubuntu 24.04.3, Kubernetes v1.32.13, containerd 2.2.1: `k8s-control-01` (192.168.1.248), `k8s-worker-01` (.249), `k8s-worker-02` (.250).
- Node load at the time: control 348m CPU and 4944Mi, worker-01 570m and 5410Mi, worker-02 223m and 4004Mi.
- Those percentages (8%, 14%, 5% CPU; 31%, 34%, 25% memory) imply roughly 4 cores and 16 GiB per node.
- Namespaces include `jenkins`, `argocd`, `vault`, `monitoring`, `longhorn-system`, `external-secrets`, `cert-manager`, `haproxy-ingress`, `metallb-system`, and app namespaces `resume-star`, `yieldpoint-ai`, `dev`, `development`.
- Jenkins is one pod, image `jenkins/jenkins:lts`, version 2.541.3 (response header `x-jenkins`), pinned by nodeSelector to `k8s-worker-01`, no resource requests or limits, a 50Gi `jenkins-pvc` bound to a local PV, a host-path mount of `/var/run/docker.sock`, service account `jenkins-admin` (Deployment `jenkins` in namespace `jenkins`).
- Almost every platform pod (argocd, prometheus, vault injector, cert-manager, haproxy, metrics-server) runs on `k8s-worker-01`, the same node as Jenkins.
- Argo CD is installed and healthy with 13 Applications, all Synced (`root-application`, `crypto-max-root`, `yieldpoint-root`, `tokenautopsy-appofapps`, `resume-star*`, `vault`, `argocd-avp`, `coredns-qos`).
- No Argo Workflows, Argo Events, Tekton, Kueue or Argo Rollouts CRDs are installed (full CRD list read).
- GitHub Actions Runner Controller CRDs exist (`autoscalingrunnersets.actions.github.com`, `ephemeralrunners.actions.github.com`, created 2026-07-20T01:23Z) but no controller pod and no AutoscalingRunnerSet exist, so they are leftovers of an earlier attempt.
- No ResourceQuota in namespace `jenkins` and no NetworkPolicy outside `argocd` and `calico-apiserver`, so test pods have no quota and no egress restriction.
- Namespace `jenkins` holds a `jenkins-agent` service account with Role `jenkins-agent-role`: get, list, watch, create, delete, patch on pods, pods/log and secrets.
- No `coq-ci` pod exists now (label `app.kubernetes.io/part-of=coq-ci` returned nothing), so nothing has been left running.
- The Jenkins MCP tools (job list, build log) were not used: their descriptions say to invoke only on the user's explicit request, and this task did not ask for them, so the job type, build history and credentials inside Jenkins are unverified (see section 10).

## 4. What works

- The lint pod through the Jenkins Kubernetes plugin worked as of 2026-10-10: the multi-arch lint image was pushed after build 1 died with `exec format error` on an amd64-only image (`lint/Containerfile` lines 3-5; commits `f5649a8`, `ae67c62` on 2026-10-10T20:05Z-20:06Z).
- `lint/lint.sh` is a pure function of the tree with no network: it checks spec XML and schema, spec pointers, graph, config schemas, herdr layouts, roles and playbooks sync, changelog, events, shellcheck, conflict markers and Markdown contents (`lint/lint.sh` lines 9-44).
- The Jenkinsfile comment records why a clean-clone lint exists: a `.gitignore` rule dropped every factory script from PR 1 while local lint still passed (`Jenkinsfile` lines 3-5).
- The multi-arch test image is real and was pulled by the cluster: GHCR shows tag `1` created 2026-10-13T22:00:13Z, and the PR 156 body states "multi-arch image pulled by the cluster with the secret, ran on aarch64 nodes".
- The image is pinned by digest and checksum: base index digest and herdr 0.9.0 sha256 for both architectures are read from `ci/config/images.json` lines 6-13 by `build.sh` lines 144-152, so no script holds a second copy; `Containerfile` lines 27-33 verify the herdr binary with `sha256sum -c`.
- `build.sh` retries build and push 3 times and then exits 4 (`ci/image/build.sh` lines 155-163, 176, 184), which matches the owner's "retry 3 times then report" rule.
- Per-case pod isolation reproduces what `podman run` per case gave on the host: PR 156 reports 30 of 31 herdr cases passing in pods in every full run, and PR 176 (merged 2026-10-14T01:44:08Z) fixed the last known pod-only failure (`11-guard-ack-nudge`, 2 of 6 before and 6 of 6 after, same sha).
- The cause found for that failure is a good example of a real system-level fix: the pod's herdr fetched a remote agent-detection manifest and re-detected the agent, so the pod was made hermetic with a closed catalog URL (`ci/pod/herdr-suite.pod.yaml` line 78, breadcrumb lines 19-32), instead of raising a timing window.
- The pod spec is sound for running repository code from a public repo: no service account token, no service links, no env from secrets, runAsUser 1000, `imagePullPolicy: Always`, restartPolicy Never, active deadline, memory limit 1Gi, cpu request 1000m (`ci/pod/herdr-suite.pod.yaml` lines 43-46, 58, 80-81; `coqGate.groovy` lines 229-265).
- The 1Gi memory limit is a structural answer to the 31.8G herdr death on 2026-10-13 (`bin/test-cases.sh` breadcrumb): a runaway server is now killed by the kubelet instead of the host.
- The retry ladder classifies correctly in the code: infrastructure (pod does not schedule, image pull, checkout, agent dies) is retried 10, 30, 90 seconds and once more after 300 seconds, while a test's own exit code is read with `returnStatus` and never retried (`coqGate.groovy` lines 134-188, 200-201).
- A test that outlives its budget is a failing test, not infrastructure (`coqGate.groovy` lines 179-182), and the pod deadline is longer than the timeout so the timeout always fires first (lines 229-233).
- The status posting retries 3 times and a fourth failure fails the build loudly (`coqGate.groovy` line 194 and comment line 190).
- The plan step is deterministic: `factory/bin/suites.sh plan` maps changed paths to suites by data in `factory/config/suites.json`, unions rows, and plans the full set for any unmapped path (`suites.sh` breadcrumb lines 16-51).
- The diff-based plan is the right idea and is where the field also lands (change-based test selection), see the shelf areas.
- The fork guard is double: the `when` on the Checks stage and a refusal inside `coqGate()` (`Jenkinsfile` lines 34-35, `coqGate.groovy` lines 55-59).
- `agent none` at pipeline level so a fork pull request cannot reach a pod before the guard (`Jenkinsfile` lines 15-17, 29).
- The static test for the gate passes by the author's report (38 checks, PR 179 body) and the Groovy parses (`CI_GROOVY=1`), but it was not re-run by this investigator because the brief forbids running repo scripts.
- The lint pod and the new gate stages run in parallel so lint's three minutes do not delay the gate (`Jenkinsfile` lines 36-84).
- GHCR pull from the cluster works with `ghcr-pull-secret` in namespace `jenkins` (`ci/image/README.md` lines 34-38), and the pod fetches the commit anonymously by sha from the public repository (`coqGate.groovy` lines 268-279), so a pod holds no repository credential.
- The Jenkins controller posts the status, so the GitHub token never enters a pod (`coqGate.groovy` lines 190-195, run on the controller; `ci/README.md` line 89 "The runner has no page key and no AWS profile").
- The listener design avoids public ingress: `gh webhook forward` is an outbound connection and a local python socket writes records (`line/bin/hook-listener.sh` header lines 1-40), and its breadcrumb explains why records are kind `note`.

## 5. What broke and why

The central finding: the new CI gate is merged but dark, because the chain from a push to a verdict has at least five missing links, and the one doing the most damage was removed on purpose.

1. Nothing triggers a build.
   - PR 179 deleted `pollSCM` on purpose ("pollSCM goes", `Jenkinsfile` lines 12-14), relying on a GitHub webhook.
   - The repository has no webhook: `gh api repos/jkkelley/coq-jev-herdr-plugin/hooks` returned `[]` on 2026-10-14, the same as `ci/README.md` lines 102-105 and the PR 179 body.
   - A webhook cannot be created that works: the Jenkins address `jenkins.homelab.local` does not resolve from this host (curl returned 000) and its ingress is `192.168.1.245`, a LAN address GitHub cannot reach (reachable here only with a `Host:` header, which returned the Jenkins login page for `/login` and "Authentication required" for `/api/json`).
   - `ci/README.md` line 104 says "Whether GitHub can reach that name is not verified here".
   - The design's 20:20Z amendment solved ingress only for the line side (`gh webhook forward` to a localhost listener), and says nothing about how GitHub reaches Jenkins; `hook-listener.sh forward` aims at the listener, not at Jenkins.
   - Net effect: since PR 179 merged at 2026-10-14T01:18:28Z, main pushes and pull requests have no path to trigger a Jenkins build.
   - Even the old lint-on-main-push, which polled every 10 minutes, no longer fires (whether the old single-branch job had its trigger removed in Jenkins cannot be confirmed without Jenkins access).
2. The library and the job are not set up.
   - The `Jenkinsfile` begins `@Library('coq-ci') _`; `ci/README.md` lines 51-77 say the library must be registered first or "the build fails at compile time with 'No library named coq-ci found'".
   - The PR 179 body lists as "Needed before the human criteria can be observed": the library registered, the multibranch job with the trust setting, a reachable webhook, and the listener ticket keyed on `coq/gate-page`.
   - `ci/README.md` line 48-49 states the existing job is a single-branch pipeline job that "has to become a multibranch job to see pull requests".
   - `triggers { githubPush() }` in a multibranch Jenkinsfile is not how a multibranch job is triggered (branch scanning and the Branch Source handle webhooks); this is from general Jenkins knowledge and is unverified here.
3. No status has ever been posted.
   - `gh api .../commits/<sha>/statuses` returned nothing for `5ad1996`, `c9b6f9f` and `2247679` (the merge of PR 179), and `statusCheckRollup` has zero entries on PRs 156, 163, 176, 178, 179, 180.
   - `gh run list` returns nothing (no GitHub Actions), and branch protection for `main` has only `required_linear_history` and no required status checks.
   - So GitHub does not enforce any gate; the only gate is `line/bin/merge.sh`, which still keys on `test.passed` and `review.passed` records (`line/bin/merge.sh` lines 3, 337-352).
4. The consumers do not exist.
   - `line/config/hook.json` lines 31-40 name handlers `ci/bin/pr-gate-hook.sh` and `ci/bin/main-gate.sh`; `ci/bin/` does not exist.
   - Tickets `WO-20261013-3217 - CI gate 3: line/bin/merge.sh keys on the coq/gate status of the head sha plus review.passed, triggered by the GitHub status event, not on a test.passed record`, `WO-20261013-aff2 - CI gate 4: a green coq/gate status on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold, triggered by the GitHub status event` and `WO-20261013-3eac - CI gate 5: pr.opened routes to the reviewer only; the tester role is retired and its playbook marked retired` are all status `ready` with `pr: null` (ticket files, `"status"` field).
   - `factory/config/routes.json` still seats a tester on `pr.opened` and a reviewer only on `test.passed` (routes lines 8-9), so the old tester path is still the live gate.
   - The listener's header and unit comment claim a fallback where `merge-watch` reads the PR's `coq/gate` status each minute (`line/units/coq-hook-forward.service` lines 4-5; design line 148); `line/bin/merge-watch.sh` contains no reference to `coq/gate` or any status (grep), so the fallback is documentation only.
5. The listener is not installed.
   - `systemctl --user list-unit-files 'coq*'` returned nothing on 2026-10-14, and `gh extension list` is empty, so neither `coq-hook-listener.service`, `coq-hook-forward.service` nor the `gh webhook` extension exists on this host (`line/bin/hook-listener.sh` lines 20-24 say install is manual, "as the owner or orchestrator").

Defects found by reading `coqGate.groovy` and the planner, which will make the first live run fail once the above is fixed (code-derived, not run):

6. Three planned suites cannot run in the pod as written.
   - `lint` is `make lint` (`factory/config/suites.json` line 3) and it is in `always`, so every plan includes it; `Makefile` line 24 runs `podman image exists ... || podman build` (the `images` prerequisite) and line 27 `podman run`, and the test image installs no podman (`ci/image/Containerfile` apt list; `01-test-image.test.sh` checks "the image installs no podman").
   - `sitrep` is `make -C report/sitrep test` which runs `podman run` (`report/sitrep/Makefile` line 15).
   - `reindex` is `bash .claude/skills/work-order/scripts/work-order.sh reindex --check` and `.gitignore` line 91 (`**/.claude/skills/`) ignores that path, so it is absent from a fresh checkout by sha (the same hazard `suites.sh` breadcrumb item 6 records for worktrees).
   - `coqGate` reads a non-zero exit of the test command as a failing test, never as infrastructure (`coqGate.groovy` lines 171, 186), so these would turn `coq/gate` red as FAILURE on valid pull requests, not retry and page.
   - The other families are container-aware (`COQ_TEST_IN_CONTAINER` in `herdr/tests/run.sh` line 30, `factory/tests/run.sh` line 18, `events/tests/run.sh` line 14, `line/tests/run.sh` line 17), which is why only these three stand out.
7. Scheduler (Go) and bearings (playwright) have no pod image, so they are planned but never run (`Jenkinsfile` line 78 `hostOnly`, `ci/README.md` lines 160-166).
   - The gate fails open for them by design; a change that only breaks scheduler or bearings goes green.
   - `ci/image/README.md` lines 73-75 says a ticket decides this; none exists.
8. The sizing numbers are wrong or guesses.
   - The Jenkinsfile says "a full run is about 50 pods" (line 26 comment); counting case files gives herdr 34 plus factory 27 = 61 case pods, plus the other suites, about 68.
   - Budgets (30, 15, 10 minutes) are "first guesses until WO-20261013-74b6 measures them" (`Jenkinsfile` line 24); `WO-20261013-74b6 - Test speed: every case prints its wall time and fails over its budget, from config/tests.json` is still `ready`.
   - The host serial baseline recorded in `bin/test-cases.sh` breadcrumb was herdr 18m25s and factory 3m58s on 2026-10-13, so pod time is unmeasured.
9. A Makefile bug breaks the documented image push.
   - `Makefile` line 17 sets `LINT_IMAGE := localhost/coq-lint:1` and line 47 `LINT_IMAGE ?= ghcr.io/jkkelley/coq-lint:1` is a no-op because the variable is already set; `make -n lint-image-push` prints `podman manifest push --all localhost/coq-lint:1 docker://localhost/coq-lint:1`, not GHCR.
   - The header (Makefile line 6) says it pushes `ghcr.io/jkkelley/coq-lint:1`; introduced in commit `f5649a8` (2026-10-10).
10. Capacity risk on a three-Pi cluster.
    - Up to 4 pods at once each request 1000m CPU (`coqGate.groovy` line 261), about half of the two workers' ~8 cores, on nodes that also host Jenkins (no limits), Argo CD, Prometheus, Vault injectors and haproxy, almost all on `k8s-worker-01`.
    - `imagePullPolicy: Always` makes every one of ~68 pods pull the image manifest and `git fetch` from GitHub, over a home connection, 4 at a time.
    - No quota, no priority class and no node selector separate test pods from the platform pods, so a heavy run can starve Argo CD or Vault on the same node (inference from the specs above, not measured).
11. Jenkins runs `jenkins/jenkins:lts` as a single pod with a host-path `docker.sock` mount and an init container that curls `stable.txt` kubectl and installs tools at every start (Deployment `jenkins`, init container `install-docker-cli`), so the controller is a mutable, unpinned, single-instance pet, in contrast to the digest-pinned images the owner insists on for tests (Rule 15 cited in `lint/Containerfile` line 2).
12. A cross-link the design depends on and cannot meet yet: the gate-page is a second commit status (`coq/gate-page`) so the cluster need not reach the line (`coqGate.groovy` lines 33-36), but that status only reaches the line through the not-installed `gh webhook forward` and the not-yet-written handlers.

What the pods do when the first live build finally runs, as designed: plan pod, then 60+ unit pods 4 at a time, then `SUCCESS`, `FAILURE`, or `ERROR` plus `coq/gate-page` (`ci/README.md` lines 109-122).
What actually gates a merge today: the tester seat path (`routes.json` lines 8-9) plus `verify-main.sh` on the host (`line/bin/verify-main.sh` header), both unchanged by the CI work.

## 6. Waits, polls, sleeps and leases

Cloud side (Jenkins and pods):

- `Jenkinsfile` line 30 `timeout(time: 90, unit: 'MINUTES')`: whole build; bound 90 minutes.
- `coqGate.groovy` line 163 `timeout(time: connectMinutes + budget)` per pod, connectMinutes default 5 (line 200): waits for the agent to connect and then the test; bound 5 plus the suite budget.
- `coqGate.groovy` line 170 `timeout(time: budget)` for the test command; budgets 30 minutes default, herdr 15, factory 10 (`Jenkinsfile` line 80); bound = budget, first guesses.
- `coqGate.groovy` line 143 `sleep` between infrastructure retries: 10, 30, 90 seconds, then 300 seconds (lines 201); waits on a fresh pod after infra failure; bound 5 attempts per unit, so at most 430 seconds of sleep per unit.
- `coqGate.groovy` line 232 `activeDeadlineSeconds = (connect + budget + 5) * 60`: the kubelet's kill if the timeout fails; bound set.
- `coqGate.groovy` line 194 `retry(3)` on every status post; bound 3 then fail.
- `coqGate.groovy` line 82-90 `maxPods` 4 slots draining a queue with `while (true)`: waits on a free slot; bound is the queue length (one loop, checked by test 02).
- `Jenkinsfile` line 30 `disableConcurrentBuilds(abortPrevious: true)`: a newer push aborts the older build, so an older build never waits on a newer one; bound immediate.
- `ci/pod/herdr-suite.pod.yaml` line 43 `activeDeadlineSeconds: 900`: manual pod; bound 15 minutes.
- `ci/tests/cases/01-test-image.test.sh` lines 79-80 poll `kubectl get` every 3 seconds up to 400 times (20 minutes): the proof test polls instead of using `kubectl wait`; bound 20 minutes.
- `ci/image/build.sh` lines 155-163, 40: `sleep $((n * 5))` between 3 build or push attempts; bound 3 attempts.
- The webhook trigger is a wait with no bound: the whole design waits on GitHub to call Jenkins (section 5 item 1), and nothing ever times that out because no polling remains.

Host side (still the live gate):

- `line/bin/verify-main.sh` `VERIFY_SUITE_TIMEOUT` default 1800 seconds per suite, `VERIFY_RETRIES` 3, `VERIFY_BACKOFF_SECONDS` 2 (header lines 22-24, line 51); bound set.
- `line/bin/merge-watch.sh` line 41 `INTERVAL=${MERGE_WATCH_SECONDS:-60}` and `sleep "$INTERVAL"` (lines 78, 91): polls GitHub every minute for merges; bound is an infinite loop that "cleans itself up" only when a named ticket merges (lines 19, 86).
- `bin/test-cases.sh` runs `JOBS` = min(cores, cap 4) cases at once (`config/tests.json`); bound set, cases have budgets only once `WO-20261013-74b6` lands.
- The tester seat (the path still live) waits on a test pane; design lines 20-23 record stalls of 9 to 14 minutes on a one-minute lint with no bound except a human noticing.

## 7. Decisions an LLM makes that a rule could make

- Running the tests for a pull request: today a tester seat (an LLM) starts the plan in a pane (`factory/config/routes.json` line 8 `pr.opened -> seat tester`); the rule is already written: `coqGate()` plus `suites.sh plan`.
  - Replacement: a Jenkins job triggered by a push event, with the verdict in a commit status and no seat.
  - Blocked on: the webhook, the library registration and the multibranch job (section 5).
- Noticing that a suite ended: tester stalls came from a model polling a pane (design lines 20-22); the replacement is an event, the GitHub `status` event through `hook-listener.sh`.
- Deciding that a failing suite should be retried or reported: today a tester or the orchestrator reads the log; the ladder in `coqGate.groovy` lines 134-150 already encodes it, and the page is `coq/gate-page`.
- Deciding the merge: `line/bin/merge.sh` is already code over records; the change is to read the status instead of a `test.passed` record (`WO-20261013-3217`), a pure rule.
- Deciding that main is verified: `verify-main.sh` is a script that posts `verified` or `rejected` and writes the hold; the replacement trigger is `coq/gate` on a main sha (`WO-20261013-aff2`), also a pure rule.
- Choosing which suites to run: already a rule in `suites.json`; the remaining LLM step is nothing, but adding a row for a new path is a hand edit when a path is unmapped (it plans the full set instead, `suites.sh` breadcrumb item 1).
- Deciding when to up-size or re-seat after an `ERROR` page: the design table says "orchestrator seats a worker" on FAILURE (`ci/README.md` line 139); a rule can do it from the status: FAILURE routes to a worker wake with the log URL, ERROR pages once.
- Choosing a budget per suite: today a guess in the `Jenkinsfile`; the rule is a measured p95 per suite stored in `config/tests.json`, which `WO-20261013-74b6` is meant to feed.
- Choosing whether a suite with no pod image counts: today a person set `hostOnly` for scheduler and bearings; the rule is a data field in `images.json` listing a suite's image and failing closed when it has none.

## 8. What to carry forward

- The pod-per-case isolation and the test image: it is the one piece with measured proof (30 of 31 cases, then 6 of 6 on the last), it works on the owner's arm64 cluster, and it needs no host podman.
- The retry ladder semantics (infrastructure retried, assertions never): this is exactly the retry-versus-fail split that Kubernetes Jobs (`backoffLimit`, `activeDeadlineSeconds`) and Argo Workflows (`retryStrategy`) provide natively, per S01 and S02; keep the semantics, and decide who runs them.
- The data-driven planner (`suites.json` with union rows, unmapped path means full set): a gap costs time and never a missed suite, which is a sound failure direction.
- The fork and secret hygiene of the pod spec: no service account token, no env from secrets, public-repo fetch by sha, pull secret only; reusable in any runner.
- Digest pins and checksum-verified binaries in `images.json`, one config, no second copy in scripts.
- Status-on-sha as the verdict channel: a commit status or check on the head sha is how the field exposes CI results, and it needs no new secret or ingress.
- The `coq/gate-page` idea that a page is just another status on the same sha.
- `bin/test-cases.sh`'s buffered, name-ordered output with `JOBS` cap; when pods run the cases it is the host fallback only.
- The hermetic-pod fix pattern: make the environment match the proven host environment instead of widening a timing window (`herdr-suite.pod.yaml` breadcrumb).
- Argo CD already on the cluster (13 Applications, all Synced) as the gitops path for anything the factory deploys; see L10 and S01.

## 9. What to kill

- `pollSCM` removal without a replacement trigger: restore a bounded poll as the fallback until a reachable webhook exists, or move the trigger to where it can be reached (see section 10); an event-only design with no event path is a silent halt.
- The tester seat as the long-term gate: the design already retires it (`WO-20261013-3eac`), but retire it only after the gate posts a status that something reads.
- `make lint` and `podman` targets inside CI units: lint should run in the existing lint pod only, and the gate's `lint` unit should be that command, not `make lint`.
- The manual hand-install steps (library registration, job conversion, systemd units, `gh extension install`) as tickets for humans: each should be a tracked, idempotent script or JCasC file, per the owner's "a hand fix is a defect" rule (global CLAUDE.md, design-first section).
- The fail-open `hostOnly` for scheduler and bearings: either build the two images or run them on the cluster another way; green with silent skips teaches nothing.
- The duplicate lint (the lint pod and `make lint` in the gate overlap on purpose, `Jenkinsfile` lines 21-23): one of them goes once the gate works.
- The Makefile double definition of `LINT_IMAGE` (lines 17 and 47).
- The unused GitHub Actions Runner Controller CRDs (created 2026-07-20) unless the owner wants ARC: stale CRDs with no controller are noise.
- Jenkins as a mutable `lts` pet with an installer init container: if Jenkins stays, pin it and manage it by JCasC from git; whether it stays is a design decision, not a given (section 10).

## 10. Open questions for the owner

1. How should GitHub events reach the CI controller from a home LAN: run the controller where GitHub can call it (public ingress or a tunnel the owner accepts), or keep everything outbound by having the host or an in-cluster component pull the events (for example `gh webhook forward` aimed at the controller, or a reconciler that watches the repository), and which of those does the owner accept given the "no public ingress" ruling in the design?
2. Should the factory's CI controller stay Jenkins (already running, version 2.541.3, single pet on a Pi) or move to a workflow engine already half present on the cluster (Argo CD is installed; Argo Workflows is not)? This changes whether `coqGate.groovy` is carried forward or its semantics are re-expressed as workflow templates.
3. Will the owner let the investigation read Jenkins (job type, build history, credentials names, library registration) with the Jenkins tools? Without it the job state in section 5 items 1-2 cannot be confirmed or refuted.
4. Is a private repository ever going to happen? The pods fetch by sha anonymously, so a private repo would need a credential in the pod path and would reopen the secrets-in-pods question.

## 11. Sources

Repository files (main checkout at `5ad1996`, read 2026-10-14):

- `Jenkinsfile`, lines 1-87.
- `ci/jenkins-lib/vars/coqGate.groovy`, lines 1-326.
- `ci/README.md`, lines 1-202; `ci/image/README.md`, lines 1-82; `ci/image/Containerfile`; `ci/image/build.sh`; `ci/pod/herdr-suite.pod.yaml`; `ci/config/images.json`.
- `ci/tests/cases/01-test-image.test.sh`; `ci/tests/cases/02-gate-pipeline.test.sh`.
- `lint/lint.sh`; `lint/Containerfile`; `Makefile`; `config/tests.json`; `bin/test-cases.sh`; `bin/test-cases.sh` breadcrumb on the 31.8G herdr death.
- `factory/bin/suites.sh`; `factory/config/suites.json`; `factory/config/routes.json`.
- `line/bin/hook-listener.sh`; `line/config/hook.json`; `line/units/coq-hook-forward.service`; `line/bin/merge.sh`; `line/bin/merge-watch.sh`; `line/bin/verify-main.sh`.
- `report/sitrep/Makefile`; `report/loop/Makefile`; `.gitignore` line 91.
- `work-orders/WO-20261013-16f1/` ticket files for `WO-20261013-3217`, `WO-20261013-aff2`, `WO-20261013-3eac`; `work-orders/WO-20261012-cf8d/` ticket file for `WO-20261013-74b6`.

State-root documents:

- `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md` (approved 2026-10-13T19:48Z with amendments 20:00Z, 20:04Z, 20:07Z, 20:20Z).
- `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013160000-test-speed-design.md`.
- `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013-duplicate-work-audit.md` (F15 tickets coupled to the tester role).

Commits and pull requests (GitHub, queried 2026-10-14 with `gh`):

- PR 156 (merged 2026-10-14T00:14:03Z, commit `db1a95c`): CI gate 1, the test image.
- PR 176 (merged 2026-10-14T01:44:08Z, commit `5ad1996`): pod fix for herdr case 11.
- PR 177 (merged): CI gate 6, the webhook listener, commit `3584b1e`.
- PR 179 (merged 2026-10-14T01:18:28Z, commit `2247679`): CI gate 2, `coqGate()`.
- Commits `f5649a8`, `ae67c62`, `c79e862` (2026-10-10): the lint image and the first Jenkinsfile.
- GitHub API reads on 2026-10-14: `repos/jkkelley/coq-jev-herdr-plugin/hooks` returned `[]`; `.../commits/<sha>/statuses` returned empty for the last three commits of main; `.../branches/main/protection` shows only linear history; `gh run list` returned nothing; `/user/packages/container/coq-test/versions` shows tag `1` created 2026-10-13T22:00:13Z and `coq-lint` tag `1` created 2026-10-10T20:04:34Z.

Live cluster reads (read-only Kubernetes tools, default context `homelab-admin`, 2026-10-14):

- Contexts, namespaces, nodes (arch, kernel, version), node top, all pods, `jenkins` namespace Deployment, PVCs, Ingress, ConfigMaps, ServiceAccounts, RoleBinding and Role `jenkins-agent-role`, ResourceQuota (none), NetworkPolicy (argocd and calico-apiserver only), the CRD list (Argo CD, actions.github.com, no Argo Workflows, Tekton or Kueue), Argo CD Applications.
- `curl -k -H 'Host: jenkins.homelab.local' https://192.168.1.245/login` returned 200 and header `x-jenkins: 2.541.3` on 2026-10-14; `getent hosts jenkins.homelab.local` returned nothing.

Host state checks (read-only, 2026-10-14): `systemctl --user list-unit-files 'coq*'` returned nothing; `gh extension list` returned nothing; `ls ci/bin` does not exist; `make -n lint-image-push` printed the `localhost/coq-lint:1` push.

No web sources were used for this local area.
