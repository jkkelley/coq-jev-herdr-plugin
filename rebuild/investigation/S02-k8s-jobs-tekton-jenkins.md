# S02 - Kubernetes Jobs, CronJobs, Kueue, operators, Tekton and Jenkins

Investigator: area S02, step R-01 of the Factory Rebuild investigation.
Written 2026-10-14 UTC (investigation clock 02:3x to 02:5x UTC).
Attempt 2 revised the file from 02:51Z and re-read the cluster and the Jenkins home at 02:51Z.
Attempt 2 closes the critic's gaps: it reconciles this file with `L07-ci-and-pods.md` and `L10-cluster-and-gitops.md` (new section 5.1), corrects the line citations, names the exact log sources, and adds dated field evidence (section 8).
Read-only throughout: no commit, no branch switch, no line script, no herdr mutation, no bearings or event script, no scheduler run.
Cluster and Jenkins were read through `kubectl` get, logs and exec-for-cat only, under the read-only `mcp-viewer@homelab` context; nothing was created, scaled, deleted or triggered.
The Jenkins MCP tools were not used, because their own descriptions say to call them only when the user explicitly asks; the same facts were read from the Jenkins home directory on its volume instead.
Credentials in `credentials.xml`, secrets and tokens were not opened and none appears in this file.

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

This area asks whether Kubernetes' own batch primitives (Jobs, CronJobs, Kueue, JobSet, operators), a Kubernetes-native pipeline engine (Tekton), or the Jenkins the owner already runs should be the execution layer under the factory: ephemeral worker pods, queueing, quotas and pipelines.
The owner already runs Jenkins on a three-node Raspberry Pi arm64 cluster, and the project's CI gate (PR 179, `coqGate()`) is built on it, so the live finding is about that gate: it has never run once.
Since 2026-10-12T18:01Z every Jenkins build of this repository has been either aborted by timeout (54 in a row, builds 39 to 92) or failed in under two seconds (10 in a row, builds 93 to 102 at the 02:51Z re-read), and not one commit status `coq/gate` has ever reached GitHub.
The shelf candidates are measured against that reality: each is judged on what job it does, maturity, whether it runs on this cluster, what it would replace locally, and what it does not do.
Short version of the verdicts: Kubernetes Jobs and CronJobs are already in the cluster and are the right primitive for a worker pod; Jenkins is the owner's chosen control plane and is broken in three independent ways that are all fixable; Tekton is mature and arm64-capable but would be a second CI system; Kueue is not supported on this cluster's Kubernetes version and solves a problem the cluster does not yet have; operators are a pattern, and the scheduler is already shaped like one.

## 3. Where it lives

Local repository (main checkout, read only): `/home/luna/projects/coq-jev-herdr-plugin`.

| Thing             | Path                                                                                        | Note                                                                                        |
| ----------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Pipeline          | `Jenkinsfile` (87 lines)                                                                    | declares `@Library('coq-ci')`, `agent none`, `triggers { githubPush() }`, 90 minute timeout |
| Gate step         | `ci/jenkins-lib/vars/coqGate.groovy` (326 lines)                                            | plan, fan out pods, post `coq/gate`, ladder 10/30/90 s then 300 s                           |
| Gate docs         | `ci/README.md`, `ci/image/README.md`                                                        | plugin inventory, webhook, statuses, ladder                                                 |
| Pod spec          | `ci/pod/herdr-suite.pod.yaml`                                                               | one case as one pod, hermetic                                                               |
| Image pins        | `ci/config/images.json`, `ci/image/Containerfile`                                           | `ghcr.io/jkkelley/coq-test:1`, multi-arch, herdr 0.9.0 baked in                             |
| Design            | `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md`    | 149 lines, amendments 20:00Z, 20:04Z, 20:07Z, 20:20Z                                        |
| Test speed design | `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013160000-test-speed-design.md` | path-to-suite map, parallel case runner                                                     |

The cluster (read with `kubectl --context mcp-viewer@homelab`, 2026-10-14T02:41Z):

| Fact                    | Value                                                                                                                                                                                                                                                                                                                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nodes                   | `k8s-control-01`, `k8s-worker-01`, `k8s-worker-02`; each 4 CPU, about 15.5 GiB, arm64, Ubuntu 24.04, kernel 6.8.0-1064-raspi, containerd 2.2.1, age 258 days                                                                                                                                                                                                                  |
| Server version          | v1.32.13 (client v1.31.14)                                                                                                                                                                                                                                                                                                                                                    |
| Schedulable capacity    | 8 CPU on the two workers; the control plane carries the `NoSchedule` taint                                                                                                                                                                                                                                                                                                    |
| Requests already placed | worker-01 1630m CPU (40 percent), worker-02 880m (22 percent), per `kubectl describe nodes`                                                                                                                                                                                                                                                                                   |
| Namespaces              | argocd, calico-system, cert-manager, external-secrets, haproxy-ingress, jenkins, longhorn-system, metallb-system, monitoring, resume-star, vault, yieldpoint-ai, dev, development                                                                                                                                                                                             |
| Ingress                 | HAProxy at `192.168.1.245` (MetalLB LAN address); `jenkins.homelab.local`, `argo.homelab.local` and others                                                                                                                                                                                                                                                                    |
| Storage                 | `longhorn` (default) and `longhorn-static`; Jenkins uses PV `jenkins-local-pv` (50 Gi, `hostPath` `/mnt/jenkins-data`, from `kubectl get pv jenkins-local-pv -o jsonpath='{.spec}'`), and inside the pod `/var/jenkins_home` is a CIFS mount of `//192.168.1.74/k8s-jenkins`, the owner's Windows PC (`mount` run in the pod, 2026-10-14T02:51Z; agrees with L10 section 5.3) |
| CRD families            | argoproj.io (Application, ApplicationSet, AppProject only), cert-manager, external-secrets, longhorn, metallb, monitoring.coreos.com, calico, haproxy, and `actions.github.com` (ARC) with no controller running                                                                                                                                                              |
| Absent                  | Tekton, Kueue, JobSet, Argo Workflows, Argo Events, KEDA, Volcano, Agent Sandbox: `kubectl get crd` lists none of them                                                                                                                                                                                                                                                        |
| PriorityClasses         | `homelab-high` (100000) plus the system ones                                                                                                                                                                                                                                                                                                                                  |

Jenkins in the cluster (namespace `jenkins`):

| Fact                 | Value                                                                                                                                                                                                                                                                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Deployment           | `jenkins`, image `jenkins/jenkins:lts` (a floating tag; digest `sha256:c409808...`), no resource requests or limits, `nodeSelector` pinned to `k8s-worker-01`, started 2026-09-19T17:49Z, host-path `/var/run/docker.sock` mounted, init container `install-docker-cli`, service account `jenkins-admin` bound to `cluster-admin` (`clusterrolebinding jenkins-admin-binding`, read 2026-10-14T02:51Z) |
| Version              | `x-jenkins: 2.541.3` in the login response header; the Jenkins update site lists `2.580.1` as latest stable on 2026-10-14                                                                                                                                                                                                                                                                              |
| Controller executors | `numExecutors` 2 in `config.xml`                                                                                                                                                                                                                                                                                                                                                                       |
| Jobs                 | 28 under `/var/jenkins_home/jobs`, among them 4 multibranch projects (`astro-template-factory-dev`, `job-hunter`, `prospector-be-multi-branch`, `yieldpoint-client-provisioner`) and one folder                                                                                                                                                                                                        |
| Global library       | one, `jenkins-shared-lib` (repo `jkkelley/jenkins-shared-lib`, file dated 2026-07-24); `coq-ci` is not in it                                                                                                                                                                                                                                                                                           |
| This repo's job      | `jobs/coq-jev-herdr-plugin`, a single-branch `flow-definition`, branch `*/main`, triggers `GitHubPushTrigger` plus `SCMTrigger` spec `H/10 * * * *`, `DisableConcurrentBuilds` with `abortPrevious` false; `config.xml` last modified Oct 10 20:01 (`ls -la` in the pod, 2026-10-14T02:51Z), so nobody has edited the job since the gate was merged                                                                                                                                                                                              |
| Agent pods           | Kubernetes plugin; agent service account `jenkins-agent` with a Role over pods, pods/log and secrets (get, list, watch, create, delete, patch)                                                                                                                                                                                                                                                         |
| CronJobs             | `jenkins/jenkins-backup` (`0 2 * * *`, suspended); `vault/vault-snapshot-*` completed pods at 41 minutes, 24 hours and 2 days old                                                                                                                                                                                                                                                                      |

Clones for this area (data only), under `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/`:
`kueue` (ef7413e, 2026-10-13), `pipeline` (90b2235, 2026-10-12), `triggers` (514103f, 2026-10-09), `pipelines-as-code` (8181703, 2026-10-12), `kubernetes-plugin` (c25b838, 2026-10-07), `jobset` (6bc9485, 2026-10-12), `agent-sandbox` (6a8234b, 2026-10-13).
Kubernetes documentation sources fetched on 2026-10-14 are under `.../investigation/k8s-docs/`.

Other places the owner already tried this layer: `~/projects/arbitrage-proxy/infra/github-runners/` (Actions Runner Controller via Argo CD, committed 2026-07-19), `~/projects/k8s-jenkins-agents`, and the other Jenkins jobs above.

## 4. What works

1. Jenkins on the cluster ran this repository's lint reliably until 2026-10-12.
   Builds 3 to 38 are all SUCCESS, 72 to 160 seconds each (`/var/jenkins_home/jobs/coq-jev-herdr-plugin/builds/<n>/build.xml`, durations 84, 72, 76 ... 160 seconds).
   The pod model itself is sound: build 92's log shows `Created Pod` at 01:12:36 and `Pod is running` at 01:12:39 with a cached image (Jenkins controller log, 2026-10-14).
2. A pod per unit of work, hermetic and arm64-clean, is proven for the herdr suite.
   `ci/pod/herdr-suite.pod.yaml` sets `restartPolicy: Never`, `activeDeadlineSeconds: 900`, `automountServiceAccountToken: false`, no env from secrets, `runAsUser: 1000`, `imagePullPolicy: Always`, cpu request 1000m and memory limit 1Gi.
   Commits `db1a95c` (WO-20261013-8573, PR 156) and `5ad1996` (WO-20261013-0b48, PR 176) show the image and the arm64 timing fix landing; `ci/image/README.md:19` records that the nodes are Raspberry Pis.
3. The gate's design separates infrastructure failure from a failing test, which is exactly the split Kubernetes now offers natively.
   `coqGate.groovy:25-32` sorts failures into infra (retried 10, 30, 90 seconds, then one clean re-run after 300 seconds) and test (a result, never retried); lines 135-150 implement it.
   Kubernetes Job `podFailurePolicy` does the same split declaratively: `FailJob` on a test exit code, `Ignore` for a `DisruptionTarget` pod condition (`k8s-docs/job.md:609-680`).
4. The plan step is plain bash and testable.
   `coqGate.groovy:286-325` runs `factory/bin/suites.sh` on the diff and emits one JSON unit per case; `ci/tests/cases/02-gate-pipeline.test.sh` exercises it against a scratch repository.
   This part is portable to any executor (Job, Tekton, Argo): it is a planner, not a Jenkins feature.
5. Kubernetes CronJobs run on this cluster today: `vault-snapshot-29865720-t95mk` is `Completed` 41 minutes before the read, with earlier ones at 24 hours and 2 days (`kubectl get pods -A`).
6. Argo CD manages 12 Applications, all Synced and Healthy (`kubectl get applications -n argocd`), so gitops delivery is already a working path.
7. The owner already has the multibranch plus shared-library pattern working for other projects: `astro-template-factory-dev` is a `WorkflowMultiBranchProject` with a `PeriodicFolderTrigger` (`jobs/astro-template-factory-dev/config.xml`), and `jenkins-shared-lib` is registered through `GitHubSCMSource`.
8. Shelf maturity, from primary sources:
   - Kubernetes Job features relevant here are stable or beta-on-by-default on this cluster's 1.32: `JobPodFailurePolicy` stable from 1.31, `JobBackoffLimitPerIndex` beta (default on) 1.29 to 1.32 and stable 1.33, `JobSuccessPolicy` beta 1.31 to 1.32 and stable 1.33, `JobPodReplacementPolicy` beta 1.29 to 1.33, `JobManagedBy` beta 1.32 to 1.34 (`k8s-docs/fg-*.md`, fetched 2026-10-14).
   - Tekton Pipelines v1.17.0 (2026-10-01), Triggers v0.36.4 (2026-10-09), Pipelines-as-Code v0.52.0 (2026-10-13); images are published for linux/arm64 (`clones/pipeline/tekton/publish.yaml:35`, `release-pipeline.yaml:38`; `clones/triggers/tekton/publish.yaml:38`); Kubernetes 1.28 or later required (`clones/pipeline/docs/install.md`, prerequisites); Tekton became a CNCF Incubating project, accepted 2026-03-13 (CNCF post 2026-03-24, Tekton post 2026-03-25).
   - Kueue v0.20.1 (2026-10-08), Apache-2.0, arm64 in `PLATFORMS` (`clones/kueue/Makefile:28`).
   - JobSet v0.13.0 (2026-10-12), arm64 in `PLATFORMS` (`clones/jobset/Makefile:18`).
   - Agent Sandbox v1.0.6 (2026-10-08), API `agents.x-k8s.io/v1beta1` (`clones/agent-sandbox/api/v1beta1/groupversion_info.go:32`), a SIG Apps project; arm64 images not verified.
   - Jenkins Kubernetes plugin 4560.vc25b_83890c34 (2026-10-08); the cluster has 4423.vb_59f230b_ce53 (`ci/README.md:40`).

## 5. What broke and why

The brief's diagnosis for this layer is that the factory needs a system, not agents, driving it; the owner then chose Jenkins as that system on 2026-10-13 (design amendments 20:00Z and 20:04Z).
The evidence says the system was chosen and built but never switched on, and the part of it that was already running had silently been red for a day and a half.

**B1. Every build since 2026-10-12T18:01Z timed out in the Blueprint stage, and nobody saw it.**

- Builds 39 to 92 (54 builds) are all `ABORTED` after 915 to 939 seconds with the log ending `Timeout has been exceeded` (`builds/92/log`, `builds/*/build.xml` durations).
- Build 38 (2026-10-12T17:51Z, commit `78ae088`) is the last SUCCESS at 160 seconds.
- Build 39 is the first build of commit `f329478` (WO-20261011-ceea, Blueprint stage, committed 2026-10-12T12:58-05:00), and its log shows `(Blueprint)` and a `Timeout set to expire in 15 min`; builds 28 and 38 have no Blueprint stage.
- Build 92's log shows lint finishing in about 3 minutes (01:12:47 to 01:15:51) and the `report/loop/tests/run.sh` suite still running at the 15 minute mark, for example `08-graph` taking 96 seconds on one check (01:17:26 to 01:19:02).
- The pre-gate Jenkinsfile set a 15 minute timeout (build 92 log: "Timeout set to expire in 15 min"); the new Jenkinsfile (line 30, comment line 26) sets 90 minutes. The Blueprint suite was never measured on a Raspberry Pi before it was added to the gate.
- Cost: about 13.8 pod-hours of Pi time (54 builds times about 917 seconds) produced no verdict, and no seat, record or status noticed, because nothing keys on the Jenkins result.
- The lint itself also drifted from 72 seconds (build 4) to 160 seconds (build 38) as the repository grew, which is the pre-existing slow burn.
- The Blueprint stage is still in the new Jenkinsfile (`Jenkinsfile:62-70`, `when { anyOf { changeset 'report/**'; changeset 'graph/**'; changeset 'work-orders/**' } }`, which nearly every commit satisfies) and now sits inside the 90 minute build timeout instead of the 15 minute one, so once the library exists the slow suite stops aborting but still runs on a Pi for 10 or more minutes per push.
- L10 section 5.1 reached the same cause independently from the build 39 log: `08-graph` ran 18:04:54Z to 18:15:31Z, about 10.6 minutes, and the 15 minute timeout killed the stage at `13-bp-view`; L07 had no Jenkins access and does not see B1 at all (L07 section 10, question 3).

**B2. The shipped gate fails at compile time because the library `coq-ci` is not registered.**

- Builds 93 to 102 (10 builds at the 02:51Z re-read, 2026-10-14T01:21Z onward) are all `FAILURE` in 478 to 1706 milliseconds (`<duration>` in each `builds/<n>/build.xml`) with `ERROR: Could not find any definition of libraries [coq-ci]` (`builds/93/log`).
- Totals at 02:51Z from the same files: 102 builds, 36 SUCCESS (builds 3 to 38), 56 ABORTED (builds 1, 2 and 39 to 92), 10 FAILURE (builds 93 to 102); L10 section 5.1, read about 20 minutes earlier, reports 100 builds, 36, 56 and 8, which is the same series.
- `GlobalLibraries.xml` holds exactly one `<name>`: `jenkins-shared-lib`.
- `ci/README.md:51-77` says to register the library before the Jenkinsfile is built ("Register the library before the `Jenkinsfile` of this ticket is built, or the build fails at compile time with 'No library named coq-ci found'"), and the commit `2247679` (PR 179) merged at 2026-10-13T20:18-05:00 with the Jenkinsfile in place; the registration is a manual UI or CasC step that no ticket executed.
- Why it repeats every 10 minutes, now read directly: `jobs/coq-jev-herdr-plugin/scm-polling.log` at 02:51Z says `[poll] Last Built Revision: Revision 3584b1e...` and `[poll] Latest remote head revision on refs/heads/main is: b7a3c5d...` then `Changes found`, because a build that dies before checkout never advances the polled revision.
- Every one of the 102 builds was started by the poll: `grep -o '[A-Za-z.]*Cause[A-Za-z$]*' builds/*/build.xml` finds 99 `SCMTriggerCause` matches, 6 `UserIdCause` matches (a person) and no `GitHubPushCause`.
- A broken Jenkinsfile therefore re-triggers a failing build every 10 minutes for as long as the job's poll trigger exists.
- Disagreement with L07 section 5 item 1: L07 wrote that the old lint-on-main-push, which polled, "no longer fires" and that it could not confirm whether the job still polled.
  Read from Jenkins, it still fires: the poll trigger lives in the job's `config.xml` (last modified Oct 10 20:01), not in the Jenkinsfile that PR 179 edited (`Jenkinsfile:10-14` says pollSCM goes), so deleting it from the file changed nothing in Jenkins, and L10 section 5.2 agrees (builds 94 to 100 at 10 minute spacing).

**B3. There is no webhook, so the design's "nothing polls" is false and cannot become true without a path in.**

- `gh api repos/jkkelley/coq-jev-herdr-plugin/hooks` returns `[]` (2026-10-14T02:3xZ), as `ci/README.md:102` already says.
- The job config still carries `SCMTrigger` `H/10 * * * *` (`jobs/coq-jev-herdr-plugin/config.xml`).
- The Jenkins controller log read for this claim is `kubectl --context mcp-viewer@homelab -n jenkins logs deploy/jenkins -c jenkins --tail=20000`, run 2026-10-14T02:51Z, which returns 20000 lines (output line 12 is dated 2026-09-27 23:15Z and output line 20000 is dated 2026-10-14 02:51:01Z).
  In that output `grep -c 'SCM changes detected in coq-jev-herdr-plugin'` returns 103, from `Triggering  #4` at output line 2764 (2026-10-10 20:11:01Z) to `Triggering  #102` at output line 20000; `grep -c 'SCM changes detected'` over all jobs returns 105; `grep -c -i -E 'github-webhook|Received POST|GitHubWebHook'` returns 0.
  A first read in attempt 1 reported 104 lines in a window that had shifted by one poll; the 02:51Z read above is the one to re-verify against.
- The single file `jobs/coq-jev-herdr-plugin/scm-polling.log` holds only the last poll (652 bytes, started 02:51:00Z); it shows `git ls-remote -h` against `https://github.com/jkkelley/coq-jev-herdr-plugin.git` taking 0.37 seconds.
- The Jenkins URL is `jenkins.homelab.local` on the private LAN address `192.168.1.245` (MetalLB, HAProxy ingress); it does not resolve from this WSL host without an explicit `--resolve`, and `ci/README.md:104` says GitHub reachability "is not verified here".
- The job is also still a single-branch pipeline job, not a multibranch job (`ci/README.md:48-49`), so even a working webhook would see no pull requests.
- The design's decisions rest on three assumptions that the cluster does not meet: an inbound webhook that triggers Jenkins (design lines 131-133, amendment 20:07Z), a registered library (`ci/README.md:51-77`), and a multibranch job (`ci/README.md:81`).

**B4. No commit status has ever been posted.**

- The six newest main commits (`ae0140e`, `5ad1996`, `c9b6f9f`, `17df7c9`, `2247679`, `3419b86`) each return no statuses and no check runs from the GitHub API (2026-10-14).
- So `merge.sh`, the verify-main flow and the tester retirement that the design keys on `coq/gate` (design tickets 3 to 5) have nothing to read.

**B5. The control plane is a shared, unpinned, single-pod Jenkins on one Raspberry Pi.**

- `jenkins/jenkins:lts` floats (a restart can change the major version), no requests or limits are set, the pod is pinned to `k8s-worker-01` with a local PV, and the controller serves 28 jobs with 2 executors.
- One restart or one node failure stops every one of the owner's projects' CI, not just this factory.
- L10 section 5.3 adds, and the 02:51Z re-read confirms, that the controller's home is not on the cluster's storage: `/var/jenkins_home` is a CIFS mount of `//192.168.1.74/k8s-jenkins`, the owner's Windows PC, which L10 ties to eleven bugchecks between 2026-07-24 and 2026-09-11; the pod also mounts the host `docker.sock`, runs as service account `jenkins-admin` bound to `cluster-admin`, and the `jenkins-backup` CronJob is suspended (S02 section 3, L10 section 5.3).
- The agent pods this gate creates run in the same `jenkins` namespace as those secrets; the Role `jenkins-agent-role` allows get, list, watch, create, delete and patch on secrets there.
- The gate adds up to 4 concurrent pods at 1000m CPU plus the JNLP sidecar's 100m each, on 8 schedulable cores that already carry about 2.5 cores of requests; a full run is documented as about 50 pods (`Jenkinsfile:26`) and the case counts add to 68 test files (herdr 34, factory 27, line 3, events 4), each with `imagePullPolicy: Always` against GHCR from a home connection.

**B6. The gate is designed to fail open on two suites.**

- `hostOnly: ['scheduler', 'bearings']` (`Jenkinsfile:78`) means a green `coq/gate` does not cover the scheduler or the bearings page; the text is at `ci/README.md:160-164`, and line 164 says every status description lists them as "not run".

**B7. A planned suite cannot run in the pod image, so the first live build would go red on valid pull requests (found by L07, re-verified here).**

- `factory/config/suites.json:3` maps `lint` to `make lint`, and `suites.json:18-20` puts `lint` in `always`, so every plan contains it.
- `Makefile:24-27` makes `lint` depend on `images`, which runs `podman image exists` and `podman run`; `ci/image/Containerfile` lines 1-2 say the pod runs "without podman on the host or in the pod", so `make lint` cannot succeed there.
- `coqGate.groovy` reads a non-zero exit of the test command as a failing test and never as infrastructure (lines 25-28), so this would post `coq/gate` FAILURE and never retry or page.
- L07 section 5 item 6 also names `sitrep` (`podman run` in `report/sitrep/Makefile`) and `reindex` (its script path is under the ignored `.claude/skills/`, `.gitignore:91`); S02 re-read `suites.json` and the Makefile and agrees on `lint`, and did not re-verify the other two.
- So the library registration (B2) is the first of at least four independent gates between this repository and a first green `coq/gate`: B2, B3, B7, and a measured budget (B1).

**Where the evidence disagrees with the diagnosis in the brief.**

- The brief frames the problem as agents driving the line; for CI the owner had already moved the verdict to a system (Jenkins), but the system is not running, so tester seats and verify-main seats are still the only gate in practice, and the stall evidence in the design (Haiku testers polling, 9 to 14 minute stalls, `20261013194800-ci-gate-design.md:20-23`) is still the live state.
- The design says "nothing polls or waits" (amendment 20:07Z, line 131 of `20261013194800-ci-gate-design.md`); the running system polls every 10 minutes and the new gate's ladder sleeps 10, 30, 90 and 300 seconds (section 6).
- The design says Jenkins is "free in my k8s cluster" (line 121 of the same file); it is free in money, but it is shared with 27 other jobs and has no resource isolation, and it was red for 32 hours without anyone being told.

### Cross-check against L07 and L10

Both files were read in full on 2026-10-14 after they landed (`L07-ci-and-pods.md`, 258 lines; `L10-cluster-and-gitops.md`, 221 lines).
The cluster and Jenkins numbers were then re-read at 02:51Z to settle the differences.

| Item | S02 | L07 | L10 | Verdict |
| ---- | --- | --- | --- | ------- |
| Cluster shape | 3 arm64 Pis, Kubernetes v1.32.13, containerd 2.2.1 (`kubectl get nodes -o wide`, 02:51Z) | same (section 3) | same (section 2, section 3) | agree |
| Raspberry Pi model | "Raspberry Pi" only | "Raspberry Pi" | "Raspberry Pi 5" | not verified by S02; the node info shows only `6.8.0-1064-raspi` |
| Argo CD Applications | 12 (`kubectl -n argocd get applications --no-headers \| wc -l` returns 12 at 02:51Z) | 13 | 12 in section 2 and section 3 | L07 miscounted or counted a header; 12 |
| No Tekton, Kueue, Argo Workflows, Argo Events | confirmed from the CRD list | confirmed | confirmed | agree (B1 to B3 of L10 depend on the same read) |
| ARC CRDs with no controller | found | found | found (created 2026-07-20T01:23Z) | agree |
| Build series 39 to 92 aborted, 93 onward failed | 54 ABORTED, then FAILURE | not visible; L07 had no Jenkins access (L07 section 10, question 3) | 54 ABORTED, builds 93 to 100 FAILURE | agree with L10; dependency for L07 |
| Cause of the aborts | Blueprint stage over the 15 minute timeout, build 39 first | not found | same cause, with the 10.6 minute `08-graph` timing | agree with L10 |
| Does Jenkins still poll | yes, `SCMTrigger H/10 * * * *` live, 99 builds caused by it | "cannot be confirmed" | yes, builds every 10 minutes | S02 and L10 settle it; L07 item 1 should read "polls and fails" |
| Library `coq-ci` registered | no, `GlobalLibraries.xml` has one name | not verified | no | agree |
| Webhook on the repository | none (`hooks` returns `[]`) | none | none | agree |
| Jenkins version | 2.541.3 | 2.541.3 | 2.541.3 | agree |
| Jenkins state volume | PV is `hostPath` `/mnt/jenkins-data`, but the pod mounts a CIFS share from `192.168.1.74` | "50Gi `jenkins-pvc` bound to a local PV" | SMB share on the owner's PC | S02 attempt 1 said "local PV" and was wrong about where the bytes live; L10 is right, S02 corrected |
| Jenkins service account | `jenkins-admin` is `cluster-admin`, `docker.sock` mounted | `jenkins-admin`, `docker.sock` | `cluster-admin` | agree |
| Planned `make lint` cannot run in the pod | confirmed for `lint` only (B7) | item 6 | not examined | agree with L07 |
| Gate capacity | up to 4 pods at 1000m on 8 schedulable cores | same | no quota, no taint, `containerCap 10` | agree |

The reconciliation above leaves S02 and L07 with one dependency: L07's section 5 items 1 and 2 are written as "unverified" and S02's B2 and B3 are the Jenkins-side evidence that closes them.
The lead should cite S02 B1 to B3 and L10 section 5.1 and 5.2 for Jenkins state, and L07 for the code-derived defects (items 6 to 9).

## 6. Waits, polls, sleeps and leases

| Where                                                                                                                | What it waits on                          | Bound                                                                                                |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `jobs/coq-jev-herdr-plugin/config.xml` SCMTrigger `H/10 * * * *`                                                     | Jenkins polls GitHub with `git ls-remote` | every 10 minutes (log lines at :01, :11, :21 ...); a poll takes about 0.4 seconds                    |
| `Jenkinsfile:30` `timeout(90 MINUTES)`                                                                               | whole build                               | 90 minutes (old file: 15 minutes)                                                                    |
| `coqGate.groovy:143` `sleep time: wait`                                                                              | infrastructure retry                      | 10, 30, 90 seconds, then 300 seconds (`settings()` line 200-201)                                     |
| `coqGate.groovy:162` `slaveConnectTimeout: connectMinutes * 60`                                                      | agent pod coming online                   | 5 minutes                                                                                            |
| `coqGate.groovy:163,170` `timeout`                                                                                   | pod provision plus test                   | connect 5 minutes plus the suite budget (default 30, herdr 15, factory 10 minutes, `Jenkinsfile:80`) |
| `coqGate.groovy:232` `activeDeadlineSeconds`                                                                         | the pod's own life                        | (connect + budget + 5 minutes) times 60                                                              |
| `coqGate.groovy:82-91` `parallel` slot loop                                                                          | a free one of `maxPods` slots             | 4 slots; the bound is the queue length, since the loop ends when the queue is empty (L07 section 6 reads it the same way)                    |
| `Jenkinsfile:30` `disableConcurrentBuilds(abortPrevious: true)` (new) versus job config `abortPrevious` false (live) | a running older build                     | live job serialises builds, so a 15 minute build blocks the next ones                                |
| `ci/pod/herdr-suite.pod.yaml` `activeDeadlineSeconds: 900`                                                           | one case's pod                            | 15 minutes                                                                                           |
| Kubernetes Job backoff (`k8s-docs/job.md:512-518`)                                                                   | pod replacement                           | `backoffLimit` default 6, exponential 10 s, 20 s, 40 s capped at 6 minutes                           |
| Kubernetes CronJob (`k8s-docs/cron-jobs.md:229-244`)                                                                 | missed schedules                          | more than 100 missed start times stops scheduling; `startingDeadlineSeconds` changes the window      |

Leases: none in this area.
The Jenkins agent pod is the only lease-like object, and it is released by the plugin when the build ends (log lines `Terminating Kubernetes instance for agent` and `Terminated Kubernetes instance`).

## 7. Decisions an LLM makes that a rule could make

This is a shelf area, so no LLM decision lives in the files read here.
One observation for the lead: the gate already replaces the tester seat's decision "did the suite pass" with an exit code and a commit status, and rung 5 pages "the orchestrator" (`coqGate.groovy:121`; `ci/README.md:141-142` name the orchestrator as who acts; `ci/README.md:156` is the rung 5 row).
That page is the one remaining place where a status becomes an LLM wake-up; a rule (status `ERROR` on context `coq/gate-page` creates a ticket and re-runs the build once) would remove the human-or-agent step, and it needs the same inbound webhook that B3 shows is missing.

## 8. What to carry forward

Each candidate: job it does, maturity, how it runs on this cluster, what it would replace locally, what it does not do.

**Kubernetes Job (batch/v1) - the worker-pod primitive.**

- Job: run one pod to completion with retries, a deadline and cleanup; Indexed mode runs N cases with a per-index backoff.
- Maturity: stable; the pieces the gate needs (`podFailurePolicy`, `backoffLimit`, `activeDeadlineSeconds`, `ttlSecondsAfterFinished`, Indexed completion) are stable on 1.32 or beta-on-by-default (section 4, item 8).
- On this cluster: already available, no install; the existing pod spec in `ci/pod/herdr-suite.pod.yaml` is one `Job.spec.template` away from a Job.
- Replaces locally: the Groovy ladder in `runUnit`/`runPod` (`coqGate.groovy:134-188`) and the hand-written slot loop (82-91); `ttlSecondsAfterFinished` replaces the cleanup command.
- Does not do: queueing across many Jobs, fair sharing, dependency order between Jobs, a GitHub status, or a trigger. Something must create the Job and post the result.
- Field evidence for coding agents on this primitive (all read 2026-10-14):
  - `chrisflav/orchestra` pull request 184 (opened 2026-08-30, merged 2026-09-23) adds a Kubernetes backend that creates one pod per task and runs the Claude Code CLI in it with `kubectl exec`; the image must not run as root because Claude Code refuses `--dangerously-skip-permissions` under uid 0; tests were run against k3s 1.34.9 (https://github.com/chrisflav/orchestra/pull/184). This is a single-maintainer project, so it shows the pattern works, not that anyone runs it at scale.
  - A Kubernetes Job per unit of agent-generated code in a restricted namespace with a narrow Role, quotas and a default-deny NetworkPolicy is described in a security guide (https://kubezilla.io/dont-let-your-ai-agent-run-kubectl-sandboxing-llm-generated-code-on-kubernetes/, undated in the search result, so treated as unverified guidance).
  - No published engineering account of a company running Claude Code or Codex fleets as batch Jobs was found by two extended searches on 2026-10-14; the larger fleets in I01 use their own control planes.

**Kubernetes CronJob - time-driven, last resort.**

- Job: create Jobs on a cron schedule with `concurrencyPolicy` and `startingDeadlineSeconds`; the docs say a Job may run more than once, so the work must be idempotent (`k8s-docs/cron-jobs.md:214-222`).
- On this cluster: in use today (vault snapshots).
- Replaces locally: only true periodic work (reaper, sweep). It is not an event source; using it to poll GitHub would recreate the 10 minute poll in B3.

**Kueue - quota and queueing in front of Jobs.**

- Job: ClusterQueue and LocalQueue with quotas, borrowing across a cohort, priorities and preemption, admission checks; supports batch Job, JobSet, plain pods and groups (`clones/kueue/site/content/en/docs/concepts/cluster_queue.md`, `.../tasks/run/plain_pods.md`; overview page last modified 2026-10-09).
- Maturity: v0.20.1 (2026-10-08), API `kueue.x-k8s.io/v1beta2`; Kubernetes 1.34 or newer is the officially supported and tested range (`clones/kueue/site/content/en/docs/getting-started/installation.md:39`).
- On this cluster: server is v1.32.13, so it is below the supported range; arm64 is built (`Makefile:28`). Not verified to run.
- Would map to: the owner's "2 worker slots reserved for system fixes" rule (memory `three-loops-always.md`) is a ClusterQueue with a reserved nominal quota and a higher WorkloadPriorityClass.
- Does not do: build the pods, post statuses, or decide what to run. With 8 schedulable cores and `maxPods: 4`, a fixed slot count already does its job; Kueue pays off when several tenants contend, which is not the case here yet.
- Field evidence: no source showing Kueue running coding-agent workers was found in two extended web searches on 2026-10-14.
  The dated evidence for Kueue is all GPU batch work: AI21 moved a shared GKE cluster of about 10,000 GPUs to Kueue and reports manual interventions down from 20 to 0 per week and GPU fragmentation from 15 percent to 8 percent (https://www.ai21.com/blog/how-ai21-manages-its-gpu-fleet-with-kueue/, published 2026-10-04), and an arXiv paper runs inference as Jobs that become Kueue Workloads (https://arxiv.org/html/2602.04900v1, 2026-02).
  So Kueue is proven for scarce shared accelerators and unproven for the factory's workload, which is the reason the verdict above is not to adopt it now.

**JobSet - a group of Jobs as one unit.**

- Job: leader/worker groups with a shared failure and success policy (`clones/jobset/README.md`). v0.13.0 (2026-10-12), arm64 built.
- Not needed by this factory: its target is distributed training; no factory step is a leader-worker group.

**Agent Sandbox (kubernetes-sigs) - a long-lived, stateful agent pod.**

- Job: a `Sandbox` CRD for a singleton pod with stable identity and storage, with `SandboxTemplate`, `SandboxClaim` and `SandboxWarmPool` for pre-warmed pods; delegates isolation to gVisor or Kata through `RuntimeClass` (`clones/agent-sandbox/README.md`; Kubernetes blog "Running Agents on Kubernetes with Agent Sandbox", 2026-03-20).
- Maturity: v1.0.6 (2026-10-08), API `v1beta1`, 4243 stars.
- Relevance: this is the closest shelf match to a "seat" (a long-lived agent process with a stable name and disk), which is what herdr panes are today. It does not give a terminal UI, a Claude login, or a GitHub push credential; those would still have to be injected. Cross-reference S04 and I01 for the seat contract.
- Not run here: no sandbox runtime (gVisor, Kata) is installed on the Pi nodes (`kubectl get runtimeclass` returns no resources); arm64 images not verified.
- Field evidence: the project's own coding-agents page (https://agent-sandbox.sigs.k8s.io/docs/use-cases/coding-agents/, last modified 2026-04-23) names one example, a LangGraph coding agent running a 350M parameter model on Kind, and names no production user, so no field use of Agent Sandbox for coding-agent seats was found.

**Operators and the operator pattern.**

- Job: a custom resource plus a controller that reconciles it (`k8s-docs/operator.md`).
- The cluster already runs operators (Prometheus, cert-manager, external-secrets, Tigera, Longhorn) so the machinery exists.
- The owner's `scheduler/` is a Go program shaped like a reconciler. Making it an operator (a `Ticket` or `Seat` custom resource) would move state into etcd on a three-node Pi cluster, which is a design decision, not a free win: the state stores are the subject of L02, not this area.
- Does not do: provide any behaviour by itself; every operator is code the owner must write and operate.

**Tekton - Kubernetes-native pipelines.**

- Job: `Task`, `Pipeline`, `TaskRun`, `PipelineRun` as custom resources; each Task runs in its own pod; `retries` and `timeout` per pipeline task (`clones/pipeline/docs/pipelines.md:714-737,1196-1209`); Triggers start runs from events; Pipelines-as-Code reads `.tekton/` from the repository and posts GitHub Checks; Chains signs provenance; LTS releases four times a year (`clones/pipeline/releases.md:10-14`).
- Maturity: v1.17.0 (2026-10-01), 9081 stars, CNCF Incubating since 2026-03.
- On this cluster: needs Kubernetes 1.28 or later (met), arm64 images published (section 4, item 8). Not installed. Installing Pipelines, Triggers, Interceptors and PaC is four controllers on Pis that already run Jenkins, Argo CD, Prometheus and Vault.
- Would replace: Jenkins as the executor and `coqGate.groovy` as the orchestrator; `concurrency_limit` on a PaC `Repository` replaces `maxPods` (`clones/pipelines-as-code/docs/content/docs/concepts.md:111-118`).
- Does not do: remove the inbound-webhook requirement. Pipelines-as-Code's controller "receives webhook events from Git providers" (`concepts.md`, controller section) and needs a GitHub App webhook that GitHub can reach, so B3 would be reproduced exactly.
- The honest cost: it would be a second CI system next to a Jenkins that serves 27 other jobs, to fix a problem (no inbound path, no registered library, a too-slow suite) that Tekton does not solve.
- Field evidence for coding agents on Tekton, found and thin:
  - `shamuraix/image-hardening-factory-starter` pull request 16 (opened and merged 2026-10-08) replaces Jenkins with Tekton plus Pipelines-as-Code and adds Claude Code agents as a Tekton Task (`.tekton/tasks/factory-claude-agent.yaml`), run headless with `claude --bare -p`, turn and budget caps, strict JSON schemas, pods that reach only the LLM gateway, and a fresh-clone re-validation before a bot opens a draft pull request; its own text says "Not yet done: a real-cluster run" (https://github.com/shamuraix/image-hardening-factory-starter/pull/16). This is a design and test-harness result, not production use.
  - `konflux-ci/konflux-ci` issue 9484 (2026-10-07) records a code agent editing `.tekton/` pipeline files to fix a 70 percent e2e failure rate by adding a retry and raising a timeout from 15m to 25m, which a maintainer rejected because it masked the failures (https://github.com/konflux-ci/konflux-ci/issues/9484). It is a field warning that an agent given a pipeline will tune retries instead of finding causes, which supports keeping the retry ladder as data the agent cannot edit.
  - Pipelines-as-Code v0.50.0 added an AI review PipelineRun triggered by `/paco review` (release notes at https://github.com/tektoncd/pipelines-as-code/releases, seen 2026-10-14).
  - No source was found showing Tekton running a fleet of coding-agent workers in production.

**Jenkins (existing) - control plane today.**

- Strengths that are evidenced: already installed and backed up, the Kubernetes plugin gives one pod per build, multibranch plus a shared library pattern already works for other projects, GitHub status posting is `githubNotify` from `github-branch-source` (`ci/README.md:45-47`).
- Weaknesses that are evidenced: section 5, B1 to B6.
- What would make it a system and not a hope: register `coq-ci`, turn the job into a multibranch job, give GitHub a reachable path (or poll deliberately and name it a poll), pin the image, set resources, and treat the Blueprint suite as a measured budget. All six are configuration, not a rewrite.

**Actions Runner Controller (ARC) - found, not in the area list, relevant.**

- The owner tried it on this cluster on 2026-07-19 (`arbitrage-proxy` commits `99a8e94` and `de19a74`): ARC charts 0.14.2 delivered by Argo CD, `minRunners: 0`, arm64 runner image (`infra/github-runners/README.md`).
- It is not running now: four `actions.github.com` CRDs remain from 2026-07-20 but no controller, listener or runner namespace exists.
- Why it matters: ARC runners open an outbound connection to GitHub, so they need no inbound webhook, which is the one thing B3 shows the cluster lacks. The design rejected Actions on cost grounds ("it will cost me invocations", owner message m-20261013195238090-9nxe1), and a public repository on self-hosted runners bills no minutes (design amendment 20:00Z, line 105 of the design); the owner has the call.

**Code and ideas worth keeping from the owner's own gate, whichever executor wins.**

- The planner (`coqGate.groovy:286-325` with `factory/bin/suites.sh` and `factory/config/suites.json`): input a diff, output units. Executor-independent.
- The hermetic pod spec lines and the reasons breadcrumbed beside them (`ci/pod/herdr-suite.pod.yaml`, `HERDR_AGENT_DETECTION_MANIFEST_CATALOG_URL`).
- The two-kind failure split and the fixed attempt count (`coqGate.groovy:25-32`).
- The multi-arch pinned image with checksums (`ci/config/images.json`).
- The fork guard and trusted-library rule (`Jenkinsfile:34`, `coqGate.groovy:55-59`).

## 9. What to kill

- The 10 minute SCM poll as a trigger that is described as "event driven": either deliver a real event path or keep the poll and say so (B3).
- A gate with no registered library: a pipeline that references `@Library('coq-ci')` must not merge before the library exists, which is a precondition check the CI test `02-gate-pipeline.test.sh` could assert against the live Jenkins (it is static today, `ci/README.md:191-192`).
- Unmonitored CI: 54 consecutive aborts with no alarm. Any executor needs a rule that a red or aborted main build opens a ticket by itself.
- The fail-open `hostOnly` list as a permanent state; it keeps two suites outside every gate (B6).
- Adding a second CI engine (Tekton) or a queue layer (Kueue) before the first one is switched on; neither removes B1, B2 or B3 (section 8).
- The floating `jenkins/jenkins:lts` tag and the absence of resource requests on the controller (B5).
- Hand registration of the shared library: the `ci/README.md` YAML is a CasC fragment; applying it by hand is the do-it-by-hand defect the owner's rules forbid.

## 10. Open questions for the owner

1. How should GitHub events reach the line: a public path into the cluster (HAProxy at `192.168.1.245` exposed or tunnelled), an outbound-only mechanism (Actions Runner Controller, or `gh webhook forward` into the host listener as design amendment 20:20Z chose), or a deliberate poll named as one?
   The answer decides whether Jenkins, Tekton Pipelines-as-Code or ARC is viable at all.
2. Is the shared Jenkins (28 jobs, floating image, one pod on one Pi, home directory on the owner's Windows PC, service account `cluster-admin`) acceptable as the factory's control plane, or does the factory get its own small executor namespace and its own state so a broken Jenkins upgrade or a PC reboot cannot stop the line?
3. Should the factory's seats stay processes in herdr panes on the host, or move toward Kubernetes workloads (Jobs for test pods as today, Agent Sandbox for seats)?
   This is mostly an S04 and L04 question; it is listed here because it determines whether Kueue-style quota ever matters.

## 11. Sources

Local files and records (all read 2026-10-14 UTC):

- `/home/luna/projects/coq-jev-herdr-plugin/Jenkinsfile` (lines 1-87)
- `/home/luna/projects/coq-jev-herdr-plugin/ci/jenkins-lib/vars/coqGate.groovy` (lines 1-326)
- `/home/luna/projects/coq-jev-herdr-plugin/ci/README.md` (lines 1-202; cited lines 36-49, 51-77, 81, 93-105, 141-142, 156, 160-164, 191-192), `factory/config/suites.json` (lines 1-30), `Makefile` (lines 20-30), `.gitignore` line 91
- `/home/luna/projects/coq-jev-herdr-plugin/ci/image/README.md`, `ci/image/Containerfile`, `ci/pod/herdr-suite.pod.yaml`, `ci/config/images.json`
- `/home/luna/projects/coq-jev-herdr-plugin/config/tests.json`
- Git history: commits `2247679` (PR 179), `db1a95c` (PR 156), `5ad1996` (PR 176), `f329478` (WO-20261011-ceea), `c79e862`, `ae67c62`
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md`, `20261013160000-test-speed-design.md`, `20261014-factory-rebuild-plan.md`; design lines cited and re-checked against the 149-line file on 2026-10-14: 20-23, 104-106, 121, 131-133, 141-149
- Memory: `three-loops-always.md`, `right-size-agent-models.md`
- `/home/luna/projects/arbitrage-proxy/infra/github-runners/README.md` and its Argo CD manifests (commits `99a8e94`, `de19a74`, 2026-07-19)
- Cluster state via `kubectl --context mcp-viewer@homelab` get/describe/logs, 2026-10-14T02:41Z to 02:50Z: nodes, namespaces, CRDs, pods, applications, ingress, priority classes, deployment `jenkins`, Role `jenkins-agent-role`
- Jenkins controller log: `kubectl --context mcp-viewer@homelab -n jenkins logs deploy/jenkins -c jenkins --tail=20000`, 2026-10-14T02:51Z (counts and line numbers in section 5, B3).
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/L07-ci-and-pods.md` and `L10-cluster-and-gitops.md`, read in full 2026-10-14 (cross-check table in section 5).
- Jenkins home on the volume, read with `cat`/`ls`/`grep` through `kubectl exec`: `jobs/coq-jev-herdr-plugin/{config.xml,builds/*/build.xml,builds/{92,93,101}/log,scm-polling.log}` (builds listing re-read 02:51Z: `build.xml` `<result>`, `<duration>` and cause class for builds 1 to 102), `org.jenkinsci.plugins.workflow.libs.GlobalLibraries.xml`, `config.xml`, `jobs/*/config.xml` (job classes only); Jenkins controller log, last 20000 lines
- GitHub API reads with `gh`: `repos/jkkelley/coq-jev-herdr-plugin/hooks`, commit statuses and check runs for six main commits, release metadata for the shelf repos

Clones (data only), under `.../investigation/clones/`: `kueue`, `pipeline`, `triggers`, `pipelines-as-code`, `kubernetes-plugin`, `jobset`, `agent-sandbox`.

Web sources:

- Kubernetes Job documentation, source `https://raw.githubusercontent.com/kubernetes/website/main/content/en/docs/concepts/workloads/controllers/job.md`, fetched 2026-10-14
- Kubernetes CronJob documentation, `.../cron-jobs.md`, fetched 2026-10-14
- Kubernetes feature gate pages `JobPodFailurePolicy`, `JobBackoffLimitPerIndex`, `JobSuccessPolicy`, `JobManagedBy`, `JobPodReplacementPolicy` under `https://raw.githubusercontent.com/kubernetes/website/main/content/en/docs/reference/command-line-tools-reference/feature-gates/`, fetched 2026-10-14
- Kubernetes operator pattern, `.../concepts/extend-kubernetes/operator.md`, fetched 2026-10-14
- Kueue overview, `https://kueue.sigs.k8s.io/docs/overview/`, page last modified 2026-10-09, read 2026-10-14
- Tekton overview, `https://tekton.dev/docs/concepts/overview/`, page last modified 2026-03-24, read 2026-10-14
- "Tekton Joins the CNCF as an Incubating Project", `https://tekton.dev/blog/2026/03/25/tekton-joins-the-cncf-as-an-incubating-project/`, 2026-03-25; "Tekton becomes a CNCF incubating project", `https://www.cncf.io/blog/2026/03/24/tekton-becomes-a-cncf-incubating-project/`, 2026-03-24
- "Running Agents on Kubernetes with Agent Sandbox", `https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox`, 2026-03-20 (introduction only was readable)
- Jenkins stable core version, `https://updates.jenkins.io/stable/latestCore.txt`, read 2026-10-14 (2.580.1)
- Attempt 2 web searches, mode extended, 2026-10-14: "running AI coding agents as Kubernetes Jobs Kueue queue quota agent workers case study" (found only GPU Kueue sources, no coding-agent source), "Tekton pipelines AI coding agent PipelineRun Claude Code" (found the two Tekton items in section 8), "coding agents run as Kubernetes Jobs one pod per task" (found the orchestra pull request and the Agent Sandbox pages).
- AI21, "How AI21 manages its GPU fleet with Kueue", https://www.ai21.com/blog/how-ai21-manages-its-gpu-fleet-with-kueue/, published 2026-10-04, read 2026-10-14
- Collabnix, Cast AI and Red Hat Kueue write-ups and the arXiv paper 2602.04900 were returned by search and are cited only as search results for Kueue use on GPU batch work
- `chrisflav/orchestra` pull request 184, https://github.com/chrisflav/orchestra/pull/184, merged 2026-09-23, read 2026-10-14
- `shamuraix/image-hardening-factory-starter` pull request 16, https://github.com/shamuraix/image-hardening-factory-starter/pull/16, merged 2026-10-08, read 2026-10-14
- `konflux-ci/konflux-ci` issue 9484, https://github.com/konflux-ci/konflux-ci/issues/9484, 2026-10-07, read 2026-10-14
- Agent Sandbox coding agents page, https://agent-sandbox.sigs.k8s.io/docs/use-cases/coding-agents/, last modified 2026-04-23, read 2026-10-14
- Attempt 1 searches (Kueue with agents, Tekton versus Jenkins versus Argo on arm64 homelabs) returned generic or dated SEO material; the one Tekton arm64 warning found was a 2020 post. The arm64 claims in section 4 come from the repositories' own build files instead.
- Field evidence on agent fleets is I01 and I02 territory and is not repeated here.
