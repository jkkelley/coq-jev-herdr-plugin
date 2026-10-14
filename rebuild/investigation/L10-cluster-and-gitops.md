# L10 - The cluster and gitops the owner has

Investigator: area L10, Factory Rebuild step R-01.
First written 2026-10-14T02:50Z by the previous attempt (the attempt 1 text is kept in the scratchpad of this session, not in the investigation root).
Revised in attempt 2, 2026-10-14T02:49Z to 03:05Z by `date -u` on this machine, to close the critic's gaps.
Live cluster reads were made with read-only kubectl (get, top, `get --raw` to the Prometheus query API, and `exec` that only listed and read Jenkins job files) and were re-run in attempt 2 unless a line says otherwise.
Every live claim cites a reproducible command from the table "Live read commands" in section 11, by id R1 to R32.
No mutating command was run anywhere.
Corrections to attempt 1 are marked "Corrected in attempt 2".

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

The owner has one real Kubernetes cluster: three Raspberry Pi 5 nodes (arm64, 4 cores and 16 GB each) running kubeadm Kubernetes v1.32.13, with Argo CD v3.3.5 (GitOps), Jenkins (CI, with the Kubernetes plugin spawning pod agents), Vault, External Secrets, Longhorn, Calico, MetalLB, HAProxy ingress and Prometheus/Grafana.
It is a working, mostly healthy platform: all 12 Argo applications are Synced and Healthy and the only live workloads are `resume-star` and `yieldpoint-ai`.
There is no Argo Workflows, Argo Events, Tekton, Kueue, Forgejo or any workflow/queue CRD installed (R34: the only CRDs matching `argoproj|tekton|kueue|forgejo|workflow|keda|jobset` are `applications`, `applicationsets` and `appprojects` of `argoproj.io`), so the only "run a pod per job" engine on the cluster is Jenkins with the Kubernetes plugin.
GitOps is done by a repeating pattern: app-of-apps in per-tenant repos, Helm charts, one literal `imageTag` that Jenkins writes with `yq` and pushes, and Argo auto-sync with prune and self-heal.
The cluster was deliberately emptied on 2026-09-12 (14 namespaces retired) "for the new autonomous system lab", which is the owner's own words for what this rebuild is supposed to use it for.
The coq factory CI gate (PR 179) was merged to run on this cluster, but as of 2026-10-14T02:49Z it does not work: the Jenkins side of it was never set up, and the lint job it replaced had been timing out on every build for about 31 hours before that for a different reason, with no GitHub status ever posted for it.

## 3. Where it lives

Local paths (all read only):

- `~/Documents/local-k8s-docs` (branch main, 25 commits behind `origin/main`; `origin/main` is at `329118e`, 2026-10-11): runbooks, system notes, an earlier agent-run program, architect designs.
- `~/projects/homelab-gitops` (branch `feat/ntfy-alerts`, head `88f27e4`, 2026-09-15): the live Argo root `root-application`, `apps/`, `helm/`, `argocd-apps/`. NOT in the brief's list but it is the real cluster gitops repo, so it is covered here.
- `~/projects/jenkins-shared-lib` (head `5d2cc9f`, 2026-08-20): the `jenkins-shared-lib` global library Jenkins loads (`buildKaniko`, `updateGitOpsManifest`, `agentPodYaml`, scans).
- `~/projects/crypto-max-gitops` (head `3399141`, 2026-09-12): tenant zone for TokenAutopsy, examiner-bot retired.
- `~/projects/dropship-01-gitops` (head `a149f47`, 2026-08-14, 4 behind origin): tenant zone for dropship-01, its namespace retired.
- `~/projects/forge-config`, `~/projects/forge-gitops`, `~/projects/forge-eks-infra` (all last touched 2026-05-20 to 2026-05-25): a Forgejo self-hosted git forge project for homelab and EKS. Never deployed to the cluster (no `forgejo` namespace exists live).
- `~/projects/gitops-builder` (head `c9ff5db`, 2026-06-01): the golden build image `ghcr.io/jkkelley/gitops-builder` used in Jenkins pods.

Remote:

- GitHub `jkkelley/homelab-gitops`, `yieldpoint-gitops` (private, pushed 2026-10-11, not on this machine), `crypto-max-gitops`, `dropship-01-gitops`, `local-k8s-docs`, `jenkins-shared-lib`, `aws-lightsail-k8s-router` (private edge router design, "designed and proven, not built"), `forge-*`.

Live cluster (kubectl context `homelab-admin`, API on k8s-control-01 192.168.1.248):

- Nodes `k8s-control-01` .248, `k8s-worker-01` .249, `k8s-worker-02` .250; Ubuntu 24.04.3, containerd 2.2.1, 258 days old.
- Namespaces now: argocd, calico-*, cert-manager, default, dev, development, external-secrets, haproxy-ingress, jenkins, longhorn-system, metallb-system, monitoring, resume-star, vault, yieldpoint-ai.
- Jenkins: `jenkins.homelab.local` via HAProxy at 192.168.1.245; Argo UI `argo.homelab.local`. Neither name resolves from the public internet.

## 4. What works

Cluster health, read live at 2026-10-14T02:37Z (attempt 1) and re-read at 02:46Z to 02:49Z (attempt 2) where an R id says so:

- All 3 nodes Ready, v1.32.13 (R1). Node CPU 5 to 10 percent, memory 25 to 33 percent at 2026-10-14T02:48Z (R2).
- Requests are low: node 1 30 percent CPU, node 2 40 percent, node 3 22 percent; memory requests 2 to 15 percent (R3, read in attempt 1 at 02:37Z, not re-run). Allocatable per node is 4 CPU, about 15.5 GiB, 110 pods (R3).
- Disk: control 15/246 GB, worker-01 111/246 GB, worker-02 108/246 GB used (R4, read in attempt 1, not re-run). The worker-01 82 percent disk crisis of 2026-09-12 is gone.
- All 12 Argo Applications Synced and Healthy, with `reconciledAt` between 02:45:35Z and 02:48:13Z when read at 02:48:16Z (R5, R6). 4 Longhorn volumes, all attached and healthy: Vault 10 Gi, resume-star postgres 2 Gi, Jenkins kaniko workspace 1 Gi, Prometheus 50 Gi (R7).
- Nightly CronJobs `jenkins-daily-backup` (Longhorn) and `vault-snapshot` last scheduled 48 minutes before the read at 02:49Z (R8).

GitOps pattern, the part that is proven and repeated across repos:

- App-of-apps root per tenant: `root-application` recurses `argocd-apps/` (`~/projects/homelab-gitops/bootstrap/root-application.yaml:17-22`), `yieldpoint-root` and `crypto-max-root` do the same for their repos. Adding an Application file is the whole deploy step (`~/Documents/local-k8s-docs/runbooks/cluster-app-workflow/cluster_app_workflow.md:203`).
- Image tag is the interface: Jenkins builds with Kaniko, scans with Trivy, then `updateGitOpsManifest` clones the gitops repo, `yq`-writes `imageTag`, commits `ci(gitops): roll <image> to tag N` and pushes in a loop of 5 attempts (`~/projects/jenkins-shared-lib/vars/updateGitOpsManifest.groovy`, head `5d2cc9f`: commit message at line 64, `for i in 1 2 3 4 5` at line 65, `git pull --rebase` and `git push` at lines 66-67, the echo and `sleep $((i * 3))` at lines 72-73, the failure exit at line 75; the Kustomize branch repeats the loop at lines 91-101 with the sleep at lines 98-99; flow summary at `cluster_app_workflow.md:321-334`). The commit convention doubles as the record of which builds succeeded (`~/projects/dropship-01-gitops/README.md`, section "The image tag is the interface").
- Fence per tenant: an AppProject limits `sourceRepos` and `destinations` (`dropship-01-gitops/README.md` intro; live AppProjects `crypto-max`, `default`, `prospector`, `resume-star`, `yieldpoint`, R10).
- Auto-sync with prune and self-heal on 38 of 39 Applications at the time of the cleanup (`system-notes/2026-09-12-cleanup-inventory.md:38`); all 12 live Applications show `prune: true` and `selfHeal: true` today (R5).
- Secrets never in git: SSM to Vault to AVP placeholders (`cluster_app_workflow.md:9-11`), ESO ExternalSecrets for runtime secrets, `ghcr-pull-secret` synced by ESO into the `jenkins` namespace (`externalsecret/ghcr-pull-secret` SecretSynced True, refresh 168h, R9).
- Sync waves order ESO resources (-2 SecretStore, -1 ExternalSecret, 0 workload) (`cluster_app_workflow.md:142-163`).

CI on the cluster, the part that is proven:

- Jenkins runs pod agents through the Kubernetes plugin: cloud name `kubernetes` (`/var/jenkins_home/config.xml:29`), namespace `jenkins` (line 35), `containerCap` 10 (line 40), `retentionTimeout` 5, `connectTimeout` 5, `readTimeout` 15 (lines 41-43), read with R11. The Role is named `jenkins-agent-role` (corrected in attempt 2: attempt 1 called it `jenkins-agent`), bound by `rolebinding/jenkins-agent-binding` to ServiceAccount `jenkins-agent`; it allows pods, pods/log and secrets with verbs get, list, watch, create, delete, patch (R12).
- 36 of the first 38 builds of the coq job passed (builds 3 to 38, started 2026-10-10T20:06:10Z to 2026-10-12T17:51:07Z; builds 1 and 2 were ABORTED) (R13). The lint pod `ghcr.io/jkkelley/coq-lint:1` runs the full `lint/lint.sh` in about 2.25 minutes (build 39 log lines 115-129, 18:01:21.985Z to 18:03:36.777Z) (R14).
- A pod that takes a repo needs no secret when the repo is public: the coq pod spec fetches `${COQ_SHA}` with an init container, mounts no service account token and sets `automountServiceAccountToken: false` (`~/projects/coq-jev-herdr-plugin/ci/pod/herdr-suite.pod.yaml:44,55-65`). The image pull uses `ghcr-pull-secret`, which exists in `jenkins` (`ci/image/README.md`, section "Pulling it").
- Runbooks are strong where they were exercised: `runbooks/cluster-backup`, `cluster-health`, `k8s-upgrade` (Run 2, 1.31 to 1.32.13, completed) and `vault-recovery`. The cluster really is at 1.32.13 while `README.md:34` and `runbooks/k8s-jenkins/README.md:3` still say 1.31.14.
- The owner's make habit is present. `~/projects/forge-config/Makefile:3` declares `.PHONY: up down nuke diff status lint logs runner-token rotate-secrets`, with `up` at lines 5-6 (`kubectl apply -k overlays/$(ENV)/`), `down` at 8-9, `diff` at 17-18, `status` at 20-21, `lint` at 23-24 and `rotate-secrets` at 38-40. `~/projects/aws-lightsail-k8s-router/README.md:53-54` says "Nothing is installed on the host. Everything runs in a container pinned by digest, and the Makefile is the only supported interface"; lines 58-60 list `make test`, `make render` and `make lab`; line 33 calls the design "Designed and proven, not built".

## 5. What broke and why

Each item states the cause, with evidence.

### 5.1 The coq lint job timed out on every build for 31 hours and nothing noticed

Counts below were re-read in attempt 2 at 02:47Z with R13 and differ from attempt 1 only because more builds had run since.

- Jenkins job `coq-jev-herdr-plugin` (R13): 101 builds, 36 SUCCESS, 56 ABORTED, 9 FAILURE. The last SUCCESS is build 38, started 2026-10-12T17:51:07Z. Builds 39 to 92 (started 2026-10-12T18:01:07Z to 2026-10-14T01:12:33Z) are all ABORTED, 54 in a row. Builds 93 to 101 (2026-10-14T01:27:53Z to 02:41:11Z) are FAILURE. Corrected in attempt 2: attempt 1 said 100 builds and 8 FAILURE.
- Every one of the 54 ABORTED builds ends with the log line "Timeout has been exceeded" (R15, `grep -c` returned 1 for each of builds 39 to 92). The last suite started in the log was `08-graph` in 52 of them and `15-bp-serve` in 2 (R15). So the 15 minute timeout, not a test failure, is the cause of all 54.
- Build 39 is the first of them. Its checkout is `f329478c20561989d46afba6fa46916399379140` (build 39 log line 99), the commit `WO-20261011-ceea ... (#24)` that added the Blueprint stage to the Jenkinsfile (`git log -- Jenkinsfile` lists `f329478`; old Jenkinsfile lines 35-43 hold the stage).
- Build 39 timeline from its log (R14, line numbers of the log file with the ANSI hyperlink markers stripped as in R14). The 15 minute timeout starts at line 110, 18:01:21.111Z. The lint script runs lines 115-129 and ends 18:03:36.777Z. The Blueprint suite starts at 18:03:38Z (line 135). Suite `08-graph` starts at line 313, 18:04:54.042Z, and its "pass" is at line 330, 18:15:31.721Z: 10 minutes 37 seconds for one suite. Suites `09` to `12` pass within 3 seconds (lines 331-395). Suite `13-bp-view` passed at 18:15:48.696Z (line 412) and `14-bp-promote` at 18:15:59.201Z (line 437). Suite `15-bp-serve` started at line 438 and was still running when the timeout fired: "Cancelling nested steps due to timeout" at 18:16:21.111Z (line 450), "Timeout has been exceeded" at line 480, "Finished: ABORTED" at line 482. Corrected in attempt 2: attempt 1 said the suite "stopped at == 13-bp-view"; that suite had passed 33 seconds earlier, and the suite running at the cancel was `15-bp-serve`.
- Build 60 shows the shape that killed 52 builds. Timeout set at 15:31:23.743Z (build 60 log line 110). `08-graph` starts at 15:35:45.429Z (line 313). Its cases land at 15:37:21Z, 15:38:43Z, 15:40:19Z and 15:41:56Z (lines 314, 318, 320, 322), 82 to 97 seconds apiece. The cancel is at 15:46:23.743Z (line 327), still inside `08-graph`.
- The timeout is `timeout(time: 15, unit: 'MINUTES')` at line 29 of the Jenkinsfile that ran builds 1 to 92 (`git show 2247679^:Jenkinsfile`, 46 lines). Build durations confirm it: builds 39, 40, 60 and 92 ran 916180, 916131, 917122 and 919882 ms (R13), which is 900 s plus teardown.
- Why `08-graph` is slow, measured. Prometheus (R16) shows the `lint` container of build 39's pod using 1.0 CPU core flat for the whole run (rate of `container_cpu_usage_seconds_total` sampled every 120 s from 18:03Z to 18:15Z: 1.01, 1.08, 1.00, 1.00, 1.00, 1.00, 1.00). The node it ran on, `k8s-worker-02` (R19), was 32 percent busy (about 1.3 of 4 cores) during the run and the other two nodes 11 to 12 percent (R17). So the suite was one serial single-threaded process holding one Pi core, with about 2.7 cores of its node idle. It was slow because it is serial work on a slow core, not because neighbours starved it. Corrected in attempt 2: attempt 1 said "the graph check is CPU bound on a Pi" with no measurement; the measurement supports a narrower claim (one core saturated, node not).
- Pod class, measured. The build 39 pod was `Burstable` (R18), not BestEffort. Only the `jnlp` sidecar the Kubernetes plugin adds had requests (cpu 0.1, memory 268435456 bytes, R19); the `lint` container declares no resources (old Jenkinsfile lines 19-25 have no `resources:` key). Corrected in attempt 2: attempt 1 said "BestEffort" and cited `Jenkinsfile:49-54`, which is the new Jenkinsfile; its lines 48-54 are the same container and PR 179 did not change that.
- Why nobody saw it, evidence not inference. The old Jenkinsfile (`git show 2247679^:Jenkinsfile`, lines 1-46) has no `githubNotify`, no status step and no `post` block other than `cleanup { cleanWs() }` (line 45). GitHub confirms nothing was ever published for this job: for commits `ae67c62` (built in the early successful run), `f329478` (build 39), `3419b86` and `17df7c9` (both inside the 31 hour window) the combined status is `pending` with `total_count` 0 and the check-runs list is empty (R20, run 2026-10-14T02:49Z). So the failure was not hidden by ABORTED versus FAILURE; the job never reported to GitHub at all, green or red. Corrected in attempt 2: attempt 1 asserted "ABORTED is not FAILURE so a red check never reached anyone", which implied a check existed.
- Did the line notice? A case-insensitive search for "jenkins" in `~/.local/state/coq/coq-jev-herdr-plugin/{records,ledger,plans}` finds the roadmap amendments of 2026-10-13T20:01Z and 20:04Z (`plans/2026/10/20261012212500-roadmap.md:329-330`), the CI gate design (`plans/2026/10/20261013194800-ci-gate-design.md:41`, which lists the Jenkinsfile as "lint on main in k8s", "unchanged"), the line-ops design (`20261014004500-line-ops-are-code-design.md:35`) and four records of the PR 130 and PR 179 tickets. None records a red or timed-out lint. That is absence of evidence from a text search, not proof that no human looked.
- Each aborted build held one Jenkins pod agent for 15 minutes (R13 durations).
- Cost: for about 31 hours (build 39 start 2026-10-12T18:01Z to build 92 end 2026-10-14T01:27Z) lint on main gave no result, while 112 commits landed on main between 2026-10-12T17:51Z and 2026-10-14T01:18Z (R33, counted in attempt 2). The line carried on with tester seats and local `make lint` (see L06 and L07).
- Not caused by agents or herdr: the mechanism is a fixed 15 minute budget set before the Blueprint suite was added, a suite that needs more than 10.6 minutes on one Pi core, and a job that reported to no one.

### 5.2 PR 179 (the pod gate) merged but its Jenkins prerequisites do not exist

PR 179 was merged 2026-10-14T01:18Z (`git log` of `2247679`, "2026-10-13T20:18:28-05:00").
What the code needs, from its own README, versus what the cluster has:

| Need (ci/README.md) | Live state | Evidence |
| --- | --- | --- |
| Global library `coq-ci` registered, loaded before the Jenkinsfile builds (`ci/README.md:51-77`) | Not registered. Only `jenkins-shared-lib` exists. | R21: `GlobalLibraries.xml:5` is the only `<name>`, `jenkins-shared-lib`; builds 93 to 101 FAIL with "ERROR: Could not find any definition of libraries [coq-ci]" (R14 on build 101, log line 3) |
| Multibranch job so PRs are seen (`ci/README.md:49,79-89`) | Still a single-branch pipeline job: `CpsScmFlowDefinition` at line 35, branch `*/main` at line 45, `scriptPath` Jenkinsfile at line 52, `GitHubPushTrigger` at lines 25-27 and `SCMTrigger` with spec `H/10 * * * *` at lines 28-31 | R22 on `/var/jenkins_home/jobs/coq-jev-herdr-plugin/config.xml` |
| GitHub webhook, "no polling" (`ci/README.md:93-105`) | No webhook: the hooks list has length 0; Jenkins `github-plugin-configuration.xml` has `<configs class="empty-list"/>` and an empty `<hookSecretConfigs/>` | R23 and R24, run 2026-10-14T02:49Z |
| GitHub can reach Jenkins | No. `jenkinsUrl` is `https://jenkins.homelab.local/` (`jenkins.model.JenkinsLocationConfiguration.xml`); the README itself says reachability "is not verified here" (`ci/README.md:103-104`). Ingress is the LAN MetalLB address 192.168.1.245 | R25 |
| Gate status `coq/gate` on the head sha | Never posted. `main` has combined status `pending` and `total_count` 0 | R20 |

- Result: since the merge, SCM polling starts a build every 10 minutes (builds 94 to 101 at 01:31:11, 01:41:11, 01:51:11, 02:01:11, 02:11:11, 02:21:11, 02:31:11 and 02:41:11Z; build 93 at 01:27:53Z started the moment build 92 timed out; R13), each failing in 0.5 to 1.7 seconds on the missing library (1706 ms for build 93, 521 ms for build 100, R13).
- The job's live trigger config still polls, because the new `Jenkinsfile:31` `triggers { githubPush() }` can only replace the job's stored triggers once a run gets past library loading, and every run since the merge fails at library loading. This is my reading of how declarative `triggers` behave, not something I tested. The lint stage now sits inside `Checks` (`Jenkinsfile:33-70`) which is never reached, so the old lint no longer runs at all and main has no CI.
- Why it merged: the ticket's acceptance criteria that touch Jenkins are "human criteria" (AC-H1 to AC-H4, `ci/README.md` "Proving the human criteria"); the code and the README shipped, the Jenkins setup was left as manual steps. This is the same shape as the brief's complaint: a step that needs a human or an agent to do something outside the repo, merged as if done.
- Alternatives the design already noted: the repo's own ticket 6 (`3584b1e`, PR for the listener) plans `gh webhook forward` as the listener on the WSL side (`plans/2026/10/20261013194800-ci-gate-design.md:141-144`). The cluster to line direction is the real gap: "the cluster cannot reach the line" (`ci/README.md:144`) and GitHub cannot reach the cluster.

### 5.3 Jenkins is the one platform piece that is not gitops and is tied to the desktop

- Jenkins is deployed imperatively and is not in homelab-gitops (`local-k8s-docs/runbooks/k8s-jenkins/README.md:5,11`). Its config is hand set in the UI: JCasC plugin `configuration-as-code@2053.vb_0da_47381a_25` is installed but `CasCGlobalConfig.xml:3` has an empty `<configurationPath></configurationPath>` and no `casc_configs` directory exists in `/var/jenkins_home` (R26). So every setting the CI gate needs (the `coq-ci` library, the multibranch job, the webhook) is a UI step. That is exactly the "by hand" the owner forbids.
- `JENKINS_HOME` is an SMB mount of `//192.168.1.74/k8s-jenkins`, the owner's Windows 11 PC - inside the pod `mount` shows `//192.168.1.74/k8s-jenkins on /var/jenkins_home type cifs (rw,...,vers=3.0,...,username=k8s-svc,...,soft,...)` (R27; `k8s-jenkins/README.md` "SMB share" table). The PersistentVolume `jenkins-local-pv` (50 Gi, claim `jenkins/jenkins-pvc`) is a `hostPath` of `/mnt/jenkins-data` (R28), so the CIFS mount sits under that host path on `k8s-worker-01`. The PC is the same machine the factory's WSL runs on and had eleven bugchecks between 2026-07-24 and 2026-09-11 (`architect/design/long-running-steps/DESIGN.md`, gap G1, citing `INV-20260911-w11x`). If the PC sleeps or reboots, all Jenkins state and every build log write stops.
- The Jenkins Deployment is hard pinned to `k8s-worker-01` (`nodeSelector {"kubernetes.io/hostname":"k8s-worker-01"}`, R28), and in attempt 1 worker-01 ran 46 of the 87 running pods (R29, not re-run). The `jenkins-backup` CronJob in namespace `jenkins` is suspended (SUSPEND True, last schedule 178 days ago); `jenkins-daily-backup` in `longhorn-system` is active and last ran 48 minutes before the read (R8).
- The Jenkins controller ServiceAccount `jenkins-admin` is bound to `cluster-admin` (`clusterrolebinding/jenkins-admin-binding`, R12; the Deployment runs as `jenkins-admin`, R28). The agent Role can create and read secrets in `jenkins` (R12). Pod agents of a public-repo suite therefore sit in a namespace holding `ghcr-pull-secret`, `jenkins-backup-aws`, `jenkins-tls-cert` and 9 leftover `kaniko-ghcr-*` secrets (R30).

### 5.4 Small leaks and drift

- 9 leftover `kaniko-ghcr-<project>-<build>` secrets in `jenkins`, aged 82 to 167 days (R30, 2026-10-14T02:49Z). Corrected in attempt 2: attempt 1 said 11; the live list has 9 (kaniko-ghcr-1, -2, -3, -26, astro-template-factory-2 and -24, prospector-go-scraper-1 and -2, yieldpoint-ai-platform-18). `buildKaniko.groovy:35` names the secret per build, line 53 creates it with `kubectl create secret generic`, and line 97 deletes it with `|| true` inside the same `sh` block, after `kubectl wait` (lines 89-92) and `kubectl logs` (line 94). It is not in a `post` or `finally`, and Jenkins runs `sh` with `-e`, so a build that fails or is aborted before line 97 leaves its secret.
- Docs drift: `local-k8s-docs/README.md` says Kubernetes 1.31.14 and Flannel; the live cluster is 1.32.13 on Calico (live nodes; `runbooks/cni-calico-migration`). The local checkout of `local-k8s-docs` is 25 commits behind origin and holds 5 untracked compaction records plus an `oom` file (`git status`).
- Wrong retirement: on 2026-09-12 the agent program retired the `yieldpoint-ai` namespace after judging the public site was "served from AWS". It was served from this cluster through the Lightsail VPS and WireGuard, and the public site returned 404 for about 29 days with no alert (`origin/main:system-notes/2026-10-11-yieldpoint-ai-retirement-reversed.md`, "Timeline"). The namespace exists again, age 2d12h.
- Argo has no GitHub webhook secret (`argocd-secret` keys: `admin.password`, `admin.passwordMtime`, `server.secretkey`, R31), `homelab-gitops` has 0 webhooks (R24), and `argocd-cm` has no `timeout.reconciliation` key (R31), so Argo polls at its default. Argo CD documents that default as 120 s plus up to 60 s jitter: `docs/faq.md:177-178` and `docs/operator-manual/argocd-cm.yaml:388` in the clone `investigation/clones/argo-cd` at commit `6e7006b` (2026-10-13), and https://argo-cd.readthedocs.io/en/stable/faq/ fetched 2026-10-14 ("Argo CD checks (polls) Git repositories every 3 minutes"; with polling set to 0 it will "only detect changes when triggered through webhooks or a manual refresh").
- Hygiene seen live in attempt 1 (R32, not re-run in attempt 2): `etcdMembersDown`, `etcdInsufficientMembers` and four `TargetDown` alerts firing in kube-system for the control plane scrape targets (Prometheus API, `/api/v1/alerts`). Single etcd member on one control plane node (`local-k8s-docs/README.md` table). Not caused by this investigation and not evidence of a fault in the cluster itself, but a standing alert noise source.

### 5.5 Where the brief's diagnosis and the evidence differ

- The brief frames herdr and agents as the cause. For the cluster side the evidence says something narrower: the cluster is healthy and underused; what holds the CI gate back is a manual Jenkins setup step (library, multibranch, webhook, public reachability) that was never turned into code. It is a wiring gap, not a capacity gap. The 31 hour lint outage (5.1) is the same kind of gap: a fixed budget and a job that posted nothing, found by reading build logs and GitHub, with a measured 1.0 core in use on a node that had 2.7 cores idle.
- The older "agent program" in `local-k8s-docs` (2026-09-09 to 2026-09-14) shows the same failure shape on this same cluster, with herdr, an orchestrator, an architect and workers (see section 8). It was halted on 2026-09-13 for "review and audit" after about 260 pull requests, so the pattern the owner is escaping predates the coq repo by a month.

## 6. Waits, polls, sleeps and leases

This is a cluster area, so the local-line rows are limited to what the cluster and its gitops flow do.

| Where | What it waits on | Bound |
| --- | --- | --- |
| Jenkins job `coq-jev-herdr-plugin` SCM poll (job `config.xml:28-31`, `H/10 * * * *`, R22) | GitHub head of main, every 10 minutes | none, runs forever; now yields a failing build every 10 min |
| `Jenkinsfile:30` `timeout(time: 90, unit: 'MINUTES')` | whole gate run | 90 min; was 15 min until PR 179 (old `Jenkinsfile:29`) |
| `coqGate()` ladder (`ci/README.md:147-156`; `ci/jenkins-lib/vars/coqGate.groovy:135-143` waits, `:163-170` timeouts, `:194` `retry(3)` on `githubNotify`) | an infrastructure failure (unschedulable pod, pull failure) | retries after 10, 30, 90 s, a 5 min cool-down, then ERROR; test failures are never retried |
| `ci/pod/herdr-suite.pod.yaml:44` `activeDeadlineSeconds: 900` | a hung herdr server in a pod | 900 s |
| Argo CD repo polling | new commit in a gitops repo | default 120 s plus up to 60 s jitter (no `timeout.reconciliation` in `argocd-cm`, no webhook secret, R31; default per Argo docs, see 5.4); `reconciledAt` values 02:45:35Z to 02:48:13Z (R6) |
| `updateGitOpsManifest` push loop (`jenkins-shared-lib/vars/updateGitOpsManifest.groovy:65-75`; kustomize copy `:91-101`; `sleep $((i * 3))` at lines 73 and 99) | push race to the gitops repo | 5 attempts, sleeps 3, 6, 9, 12 and 15 s (up to 45 s of sleep), then `exit 1` at line 75 (line 101 in the kustomize copy) |
| `~/projects/forge-config/base/actrunner-deployment.yaml:27-34` init container `wait-for-token` (`until [ -f /secrets/runner/registration-token ]` at line 33, `sleep 5` at line 34) | a runner token file | `sleep 5` loop with no bound (never deployed) |
| ESO refresh | Vault 1h, SSM 168h (`cluster_app_workflow.md:305-313`) | fixed intervals; SSM is billable per read |
| Jenkins K8s cloud | pod agent connect | `connectTimeout 5`, `readTimeout 15`, `retentionTimeout 5`, `containerCap 10` (`/var/jenkins_home/config.xml:40-43`, R11) |
| Jenkins `abortPrevious` | a newer push to the branch | immediate abort of the older build (`Jenkinsfile:30`, `disableConcurrentBuilds(abortPrevious: true)`) |
| earlier agent program, `architect/design/long-running-steps/DESIGN.md` (Pick, mechanism 4) | a job exit file | `POLL` 10 s, `SLICE` 600 s per call, the work itself unbounded |

Notes:

- Every wait above is either an event (webhook, pod phase, exit file) or has a stated bound, except the Jenkins SCM poll, which is a poll with no stop condition, and the unbounded runner-token wait in never-deployed forge manifests.
- The Argo and Jenkins webhooks do not exist, so both GitHub-to-cluster directions are polling today. Removing polling needs a path from GitHub to the cluster. One already exists for another purpose: the Lightsail VPS terminates public names and forwards over WireGuard to HAProxy (`runbooks/yieldpoint-ai-ingress/yieldpoint-ai-ingress.md`), and `aws-lightsail-k8s-router` designs a tenant table for that front door but is "designed and proven, not built". Whether a Jenkins or Argo webhook should ride that path is a decision, not a fact.

## 7. Decisions an LLM makes that a rule could make

Seen in the cluster and gitops layer:

| Decision | Where | Rule that would replace it |
| --- | --- | --- |
| Is it safe to retire a namespace (does anything public route to it) | `system-notes/2026-09-12-cleanup-inventory.md` "Seventh lesson", lines 231-259; reversed in `2026-10-11-yieldpoint-ai-retirement-reversed.md` | A script that, for every Ingress host, requests it through the real public path and fails if a forced Host to 192.168.1.245 returns 200. The README now states this as prose (`README.md` "Before retiring a namespace that has an Ingress"); a gate script would remove the judgment. |
| Which node to drain, whether a PDB blocks it | earlier Run 2 hand decisions, now in `runbooks/k8s-upgrade/drain-node.sh` | Already code; keep. |
| Whether a Jenkins/Argo setting exists before merge | PR 179 (`ci/README.md` human criteria) | A post-merge check job that fails red when `coq-ci` library, multibranch job or webhook is missing, run by the system. |
| Whether a build timeout is long enough | `Jenkinsfile` (15 min, then 90 min) | Set the timeout from a measured p95 of the suite and alert when a run exceeds 80 percent of it. `WO-20261013-74b6` is named for measuring budgets (`Jenkinsfile:24`). Section 5.1 shows the measurement that was already in the build logs: `08-graph` cases of 82 to 97 s each in builds 39 and 60. |
| Which gitops repo and path an app belongs to | `cluster_app_workflow.md` checklist, 13 manual steps (lines 357-373) | `make new-app APP=<name>` generating the chart, Application and Vault seed stubs; checklist items 8, 9 and 13 are pure rules. |
| Doc index upkeep after any chart change | `homelab-gitops/AGENTS.md:6-14` "MANDATORY - keep the runbook index in sync" | A pre-merge lint comparing `argocd-apps/` to `homelab-gitops-index.md` rows. |

The gitops pattern itself has almost no LLM decisions left: the build, tag bump, sync and health are all event or rule driven. The LLM decisions were in the surrounding program (orchestrator rulings, review rounds), which is L13.

## 8. What to carry forward

Keep, in priority order:

1. The cluster itself as the factory floor. 3 nodes, about 8 CPU of unrequested headroom (12 allocatable, 3.7 requested) and about 32 GiB of memory not in use by `kubectl top`. It was emptied for "the autonomous system lab" (`2026-09-11-project-namespace-retirement.md`, "Why this happened"). Arm64 is the constraint: every image must be multi-arch (the build 2 `exec format error`, `Jenkinsfile` breadcrumb), and Pi CPU is slow (graph check 80 s per case).
2. Argo CD plus app-of-apps plus an AppProject fence plus a single tag-bump commit, as the only write path to cluster config. It is proven for 12 live apps, and `dropship-01-gitops/README.md` states the rule cleanly: "CI commits, Argo deploys. A human running `kubectl apply` ... is a defect". S01 records the same idea, "git the only write path for cluster config" (`investigation/S01-argo.md:108` and `:224`, written by another investigator and not independently verified by me); the claim here rests on the owner's own file, not on S01.
3. Jenkins pod agents with a shared library as a working executor today (`jenkins-shared-lib`, `containerCap 10`), the owner's own words: "jenkins is free in my k8s cluster with a shared-lib we control" (owner message `m-20261013195258508-vjudu`, quoted at `plans/2026/10/20261013194800-ci-gate-design.md:121`). Do not rip it out before a replacement runs the same jobs; do put its configuration in code.
4. The pod-per-case isolation pattern in `ci/pod/herdr-suite.pod.yaml` (no token, no secret env, public fetch by sha, `restartPolicy Never`, `activeDeadlineSeconds`, `imagePullPolicy Always` for multi-arch). It is the same shape as an Argo Workflows step or a Kubernetes Job, so it ports with no change of idea.
5. Machine-readable failure semantics from `coqGate()`: a failing test is a result, never retried; only infrastructure climbs the ladder, 10/30/90 s then clean re-run then page (`ci/README.md:147-157`). Argo Workflows has the same split: `retryStrategy` with `retryPolicy` values `Always`, `OnFailure` (main container failed), `OnError` (controller errors or failed init or wait containers) and `OnTransientError`, and a `backoff` setting (https://argo-workflows.readthedocs.io/en/latest/retries/ fetched 2026-10-14; clone `investigation/clones/argo-workflows` commit `4192c5b`, 2026-10-13, `docs/retries.md:7-42`). Whether that maps cleanly onto the `coqGate()` ladder (fixed waits of 10, 30, 90 s then a 300 s clean re-run) is NOT verified here; S01 (`S01-argo.md:171,214,252`) makes the same mapping and I have not checked its work.
6. Cluster runbooks with scripted, verified checks: `health-check.sh`, `backup-cluster.sh` with sha256 re-download, `drain-node.sh`, `upgrade-minor.sh`. These are the system-first machinery the owner says he wants.
7. The `vault-snapshot` and `jenkins-daily-backup` CronJobs, working and recent.
8. Lessons from the retirement series that map directly to a rebuild (`system-notes/2026-09-12-cleanup-inventory.md`): deleting an app-of-apps orphans children unless the Application has `resources-finalizer.argocd.argoproj.io`; deleting an AppProject in the same commit deadlocks the cascade; Argo refuses to auto-prune the last resource in an Application; GitOps first, namespace delete second. Anyone building workflow pods that are Argo-managed must read these.
9. The earlier agent program as a lesson set, from `origin/main` of `local-k8s-docs` (about 200 commits 2026-09-12 to 2026-09-14, PR numbers up to 260): it already contained an orchestrator, an architect pair, numbered worker seats, a work queue of briefs with review rotation, a watchdog, an alerter, "tattle" compliance rounds, a halt banner and herdr pane control (`runbooks/agent-run-protocol/README.md`, scripts list). It stopped with the program halted for audit on 2026-09-13/14 (`runbooks/system-audit-startup/README.md`), and its design had the same hotfix chain as the coq line today (briefs 131, 132, 136, 137 are hotfixes of hotfixes; `git log origin/main` 2026-09-14). The owner's rules there are the same ones now: "Agents trigger processes; deterministic scripts do the work. Any design placing an agent inside an execution loop is wrong by construction" (`architect/intake/document-first-system-design-docs/REVIEW-BRIEF.md`, "Design constraints"). It also had an unbuilt SOS design (Redis Streams ingress, schema validation, Go knowledge graph, ephemeral workspaces) whose R-04 ruling asked "Jenkins `kubectl apply` versus Argo CD ... will fight over reconciliation" and was never decided. For L09 and the lead: this is a prior iteration on the same hardware.

## 9. What to kill

- The 15 minute lint timeout and the Blueprint suite living inside the lint pod. `08-graph` alone took 10 min 37 s of the 15 minute budget in build 39 (log lines 313 and 330) and 52 builds were cut inside it. The 90 minute timeout at `Jenkinsfile:30` replaced it, but it is also a first guess (`Jenkinsfile:24`). Replace with pods sized by measurement.
- SCM polling every 10 minutes on a job that cannot build (`config.xml` `hudson.triggers.SCMTrigger`). It produces a failing build every 10 minutes until the gate is wired.
- Jenkins state on an SMB share served by the owner's Windows PC (`JENKINS_HOME`). Kill the dependency, not necessarily Jenkins: move the PV to Longhorn (the cluster already has the `longhorn` StorageClass, default) or make Jenkins stateless via JCasC plus the job definitions in git.
- Imperatively applied Jenkins manifests (`runbooks/k8s-jenkins/jenkins-rebuild-from-scratch.md`). Put them under Argo like every other platform piece (`argocd-avp`, `vault`, `coredns-qos` already are).
- Hand-maintained Jenkins UI configuration that the repo then assumes (the `coq-ci` library, multibranch job, webhook). Replace with JCasC or a Jenkins job-DSL seed living in a repo.
- Per-build `kaniko-ghcr-*` secrets created by `kubectl create secret` inside the build (`buildKaniko.groovy:53`), 9 leaked (R30). Replace with the existing `ghcr-pull-secret`/ESO or a docker-config mounted from one ExternalSecret.
- `jenkins-admin` bound to `cluster-admin`, plus `jenkins-agent` able to read all secrets in `jenkins`, while public-repo suites run as pods in the same namespace. Isolate suite pods in a separate namespace with no secret access (the pod spec already assumes this, `ci/image/README.md` says "Pods must therefore run in that namespace, or the secret must be copied").
- The forge trio (`forge-config`, `forge-gitops`, `forge-eks-infra`) as a path for the factory. It is a Forgejo git forge with placeholders (`PLACEHOLDER_FORGE_CONFIG_REPO_URL`, `forge-gitops/argocd-apps/workloads/forgejo.yaml`), never applied, last touched in May. Keep it as a reference (its ESO health checks `argocd-cm-patch/health-checks.yaml` and Kustomize overlays are good), do not build on it. Note it is the most plausible meaning of "forgeo" for L12: the three repos are named `forge-*` and the product is Forgejo, and `rime-bootstrap/streams/B-infrastructure.md` (clone under the investigation root) plans Forgejo on this cluster as ticket B-02/B-08.
- The dormant tenant repos' leftovers: `crypto-max-gitops` still has live Argo Applications (`crypto-max-root`, `tokenautopsy-appofapps`) for a retired tenant, and `dropship-01-gitops` has unmerged retire branches. They waste Argo reconcile cycles only; low priority.

## 10. Open questions for the owner

Only ones that change the design.

1. Should the factory's executors be Argo Workflows steps (new install, an Argo Events or webhook path in) or stay on Jenkins pod agents (already installed, hand-configured, JENKINS_HOME on the PC)? The cluster has Argo CD but not Argo Workflows; nothing else installs workflow pods.
2. Must GitHub events reach the cluster (webhook), or may the system pull (Argo/Jenkins polling, or a `gh webhook forward` style outbound listener running inside the cluster)? Today neither direction has a push path, and the only existing public path is the Lightsail VPS and WireGuard tunnel.
3. Is the cluster allowed to hold factory job pods next to `resume-star` and the live `yieldpoint-ai` site (production-like tenants), or does the factory get its own node(s) or namespace with quotas? There is no taint, quota or LimitRange on any node, and `containerCap` is 10 pods for all of Jenkins.
4. Does the owner want JENKINS_HOME (or its replacement) on Longhorn replicas instead of the Windows PC share, given the PC's bugcheck history?

## 11. Sources

Local files and live reads, all read 2026-10-14 unless stated:

- `~/Documents/local-k8s-docs/README.md`, `CLAUDE.md`, `agents/RULES.md`, `agents/RULE-LOG.md`
- `~/Documents/local-k8s-docs/runbooks/cluster-app-workflow/cluster_app_workflow.md` (lines 9-11, 142-163, 203, 305-334, 357-373)
- `~/Documents/local-k8s-docs/runbooks/k8s-jenkins/README.md` (lines 3-11), `runbooks/homelab-gitops-index.md`, `runbooks/yieldpoint-ai-ingress/yieldpoint-ai-ingress.md`, `runbooks/agent-run-protocol/README.md`, `runbooks/agent-run-protocol/queue/README.md`, `runbooks/system-audit-startup/README.md`
- `~/Documents/local-k8s-docs/system-notes/2026-09-11-project-namespace-retirement.md`, `2026-09-12-cleanup-inventory.md` (lines 36-38, 49-103, 231-259), `2026-09-12-long-step-bottleneck.md`
- `~/Documents/local-k8s-docs/architect/design/long-running-steps/DESIGN.md`, `architect/intake/2026-09-14-supervisor-owners-protocol/README.md`, `architect/intake/document-first-system-design-docs/REVIEW-BRIEF.md`, `SOS-DIAGRAMS-2026-V1.md`, the SOS docx (text extracted in the scratchpad, not in any repo)
- `git -C ~/Documents/local-k8s-docs log origin/main` (head `329118e`, 2026-10-11T13:40Z) and `git show origin/main:system-notes/2026-10-11-yieldpoint-ai-retirement-reversed.md`
- `~/projects/homelab-gitops` (`AGENTS.md`, `COMPASS.md`, `bootstrap/root-application.yaml`, `argocd-apps/`, `git log`)
- `~/projects/jenkins-shared-lib/vars/agentPodYaml.groovy`, `buildKaniko.groovy`, `updateGitOpsManifest.groovy`
- `~/projects/crypto-max-gitops/README.md`, `~/projects/dropship-01-gitops/README.md`
- `~/projects/forge-config/CLAUDE.md`, `Makefile`, `docs/adr/0004-eks-vs-homelab.md`, `.forgejo/workflows/ci.yaml`, `base/actrunner-deployment.yaml`; `~/projects/forge-gitops/argocd-apps/`, `bootstrap/`, `argocd-cm-patch/`; `~/projects/forge-eks-infra/README.md`, `CONTEXT_STATE.md`
- `~/projects/coq-jev-herdr-plugin/Jenkinsfile`, `ci/README.md`, `ci/image/README.md`, `ci/pod/herdr-suite.pod.yaml`, `ci/jenkins-lib/vars/coqGate.groovy`, commit `2247679` and `git show 2247679^:Jenkinsfile`
- `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md` (lines 114-144)
- `~/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/rime-bootstrap/streams/B-infrastructure.md` (clone by another investigator, read only)
- Live kubectl reads, attempt 1 at 2026-10-14T02:37Z to 02:41Z and attempt 2 at 02:46Z to 02:49Z, against context `homelab-admin`. The reproducible commands are in the table "Live read commands" below. Credentials files were not read.
- `gh api` reads (R20, R23, R24, 2026-10-14T02:49Z) and in attempt 1 repo visibility (public), `gh repo list jkkelley` (names and push dates) and the `aws-lightsail-k8s-router` README.
- Web, fetched 2026-10-14: https://argo-workflows.readthedocs.io/en/latest/retries/ and https://argo-cd.readthedocs.io/en/stable/faq/. Clone data under `investigation/clones/argo-workflows` (commit `4192c5b`, 2026-10-13T15:18+01:00) and `investigation/clones/argo-cd` (commit `6e7006b`, 2026-10-13T20:30-04:00), made by the S01 investigator and read only here.
- Other investigator files cited as unverified pointers: `investigation/S01-argo.md` lines 108, 171, 214, 224, 252.
- Attempt 1 text of this file, saved in the session scratchpad (not in the investigation root).
- The Jenkins MCP tools were deliberately not used because their descriptions restrict them to explicit user request; the same facts were read through kubectl instead.

### Live read commands

Every command is read-only. `<pod>` is `jenkins-659c5bcb6-mwbfn` in namespace `jenkins` (container `jenkins`) at the time of the read. `H` is `/var/jenkins_home`. Prometheus is reached with `kubectl get --raw "/api/v1/namespaces/monitoring/services/prometheus-stack-kube-prom-prometheus:9090/proxy/api/v1/<query>"` (call it `PROM`).

| Id | Command | What it returned (2026-10-14) |
| --- | --- | --- |
| R1 | `kubectl get nodes` | 3 nodes Ready, v1.32.13, age 258d |
| R2 | `kubectl top nodes` | 02:48Z: control 8 percent CPU 30 percent mem, worker-01 10 and 33, worker-02 5 and 25 |
| R3 | `kubectl describe nodes` | requests and allocatable (attempt 1 only) |
| R4 | `kubectl get --raw /api/v1/nodes/<node>/proxy/stats/summary` | disk usage (attempt 1 only) |
| R5 | `kubectl -n argocd get applications.argoproj.io -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,PRUNE:.spec.syncPolicy.automated.prune,SELF:.spec.syncPolicy.automated.selfHeal` | 12 applications, all Synced, Healthy, true, true |
| R6 | `kubectl -n argocd get applications.argoproj.io -o jsonpath='{range .items[*]}{.metadata.name} {.status.reconciledAt}{"\n"}{end}'` | reconciledAt 02:45:35Z to 02:48:13Z |
| R7 | `kubectl -n longhorn-system get volumes.longhorn.io -o custom-columns=NAME:.metadata.name,STATE:.status.state,ROBUST:.status.robustness,SIZE:.spec.size,NODE:.status.currentNodeID` and `kubectl get pv -o custom-columns=NAME:.metadata.name,CLAIM:.spec.claimRef.name,NS:.spec.claimRef.namespace,SC:.spec.storageClassName,SIZE:.spec.capacity.storage` | 4 volumes attached and healthy, claims data-vault-0, data-resume-star-postgresql-0, kaniko-workspace, prometheus db |
| R8 | `kubectl get cronjob -A \| grep -i -E "jenkins\|vault"` | `jenkins-backup` suspended True, `jenkins-daily-backup` and `vault-snapshot` 48m since last schedule |
| R9 | `kubectl -n jenkins get externalsecret ghcr-pull-secret` | SecretSynced, READY True, refresh 168h |
| R10 | `kubectl -n argocd get appprojects.argoproj.io -o name` | crypto-max, default, prospector, resume-star, yieldpoint |
| R11 | `kubectl -n jenkins exec <pod> -c jenkins -- grep -n "containerCap\|<name>kubernetes\|<namespace>\|connectTimeout\|readTimeout\|retentionTimeout" H/config.xml` | lines 29, 35, 39-43 |
| R12 | `kubectl -n jenkins get role jenkins-agent-role -o jsonpath='{range .rules[*]}{.apiGroups} {.resources} {.verbs}{"\n"}{end}'`; `kubectl -n jenkins get rolebinding jenkins-agent-binding -o jsonpath='{.subjects}'`; `kubectl get clusterrolebinding jenkins-admin-binding -o jsonpath='{.roleRef.name} {.subjects}'` | pods, pods/log, secrets with get, list, watch, create, delete, patch; subject SA `jenkins-agent`; `cluster-admin` for SA `jenkins-admin` |
| R13 | `kubectl -n jenkins exec <pod> -c jenkins -- sh -c 'cd H/jobs/coq-jev-herdr-plugin/builds; for n in $(ls \| grep -E "^[0-9]+$" \| sort -n); do grep -o "<result>[A-Z]*</result>" $n/build.xml; grep -o "<startTime>[0-9]*" $n/build.xml; grep -o "<duration>[0-9]*" $n/build.xml; done'` | 101 builds: 36 SUCCESS, 56 ABORTED, 9 FAILURE; runs 1-2 ABORTED, 3-38 SUCCESS, 39-92 ABORTED, 93-101 FAILURE |
| R14 | `kubectl -n jenkins exec <pod> -c jenkins -- cat H/jobs/coq-jev-herdr-plugin/builds/<N>/log`, then `sed 's/\x1b\[8m[^\x1b]*\x1b\[0m//g'` to strip the ANSI hyperlink markers | line numbers in section 5.1 are from this stripped file; builds 39, 60, 101 |
| R15 | `kubectl -n jenkins exec <pod> -c jenkins -- sh -c 'cd H/jobs/coq-jev-herdr-plugin/builds; for n in $(seq 39 92); do grep -a "== " $n/log \| tail -1; grep -a -c "Timeout has been exceeded" $n/log; done'` | all 54 count 1; last suite 08-graph x52, 15-bp-serve x2 |
| R16 | `PROM/query_range?query=sum by (pod,container)(rate(container_cpu_usage_seconds_total{namespace="jenkins",container!=""}[1m]))&start=1791828060&end=1791829020&step=120` | lint container of pod `coq-jev-herdr-plugin-39-wjhmk-0fh9j-hlbrt`: 1.01, 1.08, 1.0, 1.0, 1.0, 1.0, 1.0, last point 0.39 |
| R17 | `PROM/query_range?query=1 - avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[2m]))&start=1791828060&end=1791829020&step=180` | .248 0.10-0.12, .249 0.12, .250 0.32 (from 0.06 at the first point) |
| R18 | `PROM/query?query=kube_pod_status_qos_class{namespace="jenkins",pod=~"coq-jev-herdr-plugin-39.*"} == 1&time=1791828360` | `Burstable` |
| R19 | `PROM/query?query=kube_pod_container_resource_requests{namespace="jenkins",pod=~"coq-jev-herdr-plugin-39.*"}&time=1791828360` | only `jnlp` has requests (cpu 0.1, memory 268435456); node label `k8s-worker-02` |
| R20 | `gh api repos/jkkelley/coq-jev-herdr-plugin/commits/<sha>/status` and `.../check-runs` for `f329478`, `ae67c62`, `3419b86`, `17df7c9`, and `commits/main/status` | state pending, total_count 0, no check runs, every sha |
| R21 | `kubectl -n jenkins exec <pod> -c jenkins -- grep -n "<name>" H/org.jenkinsci.plugins.workflow.libs.GlobalLibraries.xml` | line 5 `jenkins-shared-lib` only |
| R22 | `kubectl -n jenkins exec <pod> -c jenkins -- grep -n "class=\|<spec>\|<name>\*\|scriptPath\|url>" H/jobs/coq-jev-herdr-plugin/config.xml` | lines 25-31, 35, 40, 45, 52 |
| R23 | `kubectl -n jenkins exec <pod> -c jenkins -- cat H/github-plugin-configuration.xml` | empty `configs`, empty `hookSecretConfigs` |
| R24 | `gh api repos/jkkelley/coq-jev-herdr-plugin/hooks --jq length` and the same for `repos/jkkelley/homelab-gitops/hooks` | 0 and 0 |
| R25 | `kubectl get ingress -A \| grep -i -E "jenkins\|argo"` | `jenkins.homelab.local` and `argo.homelab.local` on 192.168.1.245; and `kubectl -n jenkins exec <pod> -c jenkins -- grep -n jenkinsUrl H/jenkins.model.JenkinsLocationConfiguration.xml` gives `https://jenkins.homelab.local/` at line 4 |
| R26 | `kubectl -n jenkins exec <pod> -c jenkins -- cat H/io.jenkins.plugins.casc.CasCGlobalConfig.xml` and `ls H \| grep -i casc` | empty configurationPath; only the XML file name matches |
| R27 | `kubectl -n jenkins exec <pod> -c jenkins -- sh -c 'mount \| grep jenkins_home'` | cifs mount from `//192.168.1.74/k8s-jenkins` |
| R28 | `kubectl get pv jenkins-local-pv -o jsonpath='{.spec.hostPath}'`; `kubectl -n jenkins get deploy jenkins -o jsonpath='{.spec.template.spec.nodeSelector} {.spec.template.spec.serviceAccountName}'` | hostPath `/mnt/jenkins-data`; nodeSelector worker-01; SA `jenkins-admin` |
| R29 | `kubectl get pods -A -o wide` counted by node | 46 of 87 on worker-01 (attempt 1 only) |
| R30 | `kubectl -n jenkins get secret --no-headers` | 9 `kaniko-ghcr-*` secrets, 82d to 167d; plus ghcr-pull-secret, jenkins-backup-aws, jenkins-tls-cert |
| R31 | `kubectl -n argocd get cm argocd-cm -o jsonpath='{.data}'` (keys only) and `kubectl -n argocd get secret argocd-secret -o jsonpath='{.data}'` (key names only) | no `timeout.reconciliation`; secret keys admin.password, admin.passwordMtime, server.secretkey |
| R32 | `PROM/alerts` (`/api/v1/alerts`) | etcd and TargetDown alerts (attempt 1 only) |
| R33 | `git -C ~/projects/coq-jev-herdr-plugin log main --since=2026-10-12T17:51:00Z --until=2026-10-14T01:18:00Z --format=%h \| wc -l` | 112 |
| R34 | `kubectl get crd -o name \| grep -i -E "argoproj\|tekton\|kueue\|forgejo\|workflow\|keda\|jobset"` | three `argoproj.io` CRDs: applications, applicationsets, appprojects |
