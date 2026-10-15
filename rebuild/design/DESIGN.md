# Factory rebuild design

The rebuilt factory, in one document, for the owner's read.
The XML volumes beside this file stay the agents' source; every section here points into them by anchor for depth.
Written 2026-10-14 (UTC) by the R-03 spec-author seat from the spec book on branch `rebuild/design` (PR 189).
Version 1.1.0, issued 2026-10-15T06:00:00Z: the review fixes are folded in ([what changed](#21-what-changed-in-110)).

## 1. Contents

1. [Contents](#1-contents)
2. [Status](#2-status)
3. [Goal](#3-goal)
4. [What is reused](#4-what-is-reused)
5. [Architecture](#5-architecture)
6. [DAG](#6-dag)
7. [Workflows and flows](#7-workflows-and-flows)
8. [File format and data shapes](#8-file-format-and-data-shapes)
9. [Commands](#9-commands)
10. [Inputs and outputs](#10-inputs-and-outputs)
11. [Status and exit codes](#11-status-and-exit-codes)
12. [Tool choices](#12-tool-choices)
13. [Standing rules after build](#13-standing-rules-after-build)
14. [Files created](#14-files-created)
15. [Decisions for the owner](#15-decisions-for-the-owner)

## 2. Status

DRAFT for the owner's read.
Nothing in this design is built yet: every one of the 52 nodes ships dark and goes live by its own ticket with a named proof.
The order is one state machine, [bootstrap](shared/cut-over.xml#bootstrap), states B0 to B8.
B0 is this design approved (the owner closes R-03).
B1 is the foundation only: the store, the schemas, the fixtures and dark binaries run against a test state root, with no live unit and no forge or Jenkins effect; B1 tickets may be cut and built before GOFACTORY.
Every runtime ticket, every live unit and every external effect waits for the owner's GOFACTORY ruling, which moves the line to B2.
B3 to B6 are cut-over steps, each entered by the proof of the one before.
B7 is ready: the proofs of cut-over steps 2, 6 and 7 are recorded.
USERGO is accepted only at B7 and moves the line to B8, live; a USERGO before B7 is refused 412 not-ready, naming the missing proofs.

What exists today on main (`4f7f44c`, 2026-10-14):

- The old line: `line/bin/` (`merge.sh`, `verify-main.sh`, `route-retry.sh`), `factory/bin/` (`route.sh`, `suites.sh`, `claims.sh`), herdr seats (`herdr/bin/seat.sh`), the event files under `events/`.
- The bearings page as a Node server (`tools/bearings/scripts/server.mjs`, `wait.mjs`, `front-door.mjs`), with this week's fixes merged: the live strip (PR 184, PR 185), the Tailscale front door (PR 186, PR 187), the Krastorio skin (PR 188), and stable never idling (PR 190).
- The Go scheduler skeleton: `scheduler/api/scheduler/v1/scheduler.proto`, the core interfaces, the fake clock and a CLI (the 1,468-line skeleton named on card C41).
- The CI library `ci/jenkins-lib/vars/coqGate.groovy` and `ci/config/images.json`, which have never posted a verdict to GitHub.
- The rebuild plan (`rebuild/factory-rebuild-plan.xml`, PR 182) and the investigation (`rebuild/investigation/`, PR 183).

What this branch adds (PR 189, branch `rebuild/design`):

- 52 DAG nodes (N-01 to N-52) in seven groups, written as XML volumes (the 52 node volumes, the shared volumes and the index) with a JSON schema beside each node; [`index.xml`](index.xml) lists every volume with its line count.
- `check.sh` with the checks listed at the top of [`bin/check-book.py`](bin/check-book.py), each proven to fire by `bin/test-checks.py`.
- The no-cog review of 1.0.0 (no cog, many agents at once, pointers resolve, 1000-line cap), proof at `$HOME/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/proofs/R-03-no-cog-review.md`.
- This file, the owner's read of the whole design.

What waits for the owner, in order:

1. Read this file and close R-03 (decision 1 in [section 15](#15-decisions-for-the-owner)): the bootstrap enters B0, and B1 foundation tickets may be cut.
2. GOFACTORY is yours alone, given when you choose: it moves the line to B2, which starts the runtime, the unlanded cleanup as a dry run first, and the cut-over steps.
3. USERGO is yours alone too, and is accepted only once the line reports B7 with the proofs of cut-over steps 2, 6 and 7; it moves the line to B8 and clears the hold.
4. Answer the open decisions of [section 15](#15-decisions-for-the-owner) (probe Pi, GitHub App, WSL interop, bootstrap merge path, Kaniko fork pin).

The line is held today: the owner's USERHALT stands, product work is frozen (D19), and the stable bearings page is the one monitor that never stops.
GOFACTORY, USERGO and USERHALT are the owner's words only: they count only as the whole trimmed message of an owner principal on the owner page or the owner CLI, and relayed, defaulted, imported or seat-produced text never becomes one ([owner words](shared/authority.xml#owner-words)).

### 2.1 What changed in 1.1.0

An outside review of 1.0.0 raised findings F01 to F26, and the verification of that review raised more from F27 onward.
Each finding has one disposition, with its evidence and the anchor that fixes it, in [review dispositions](shared/review-dispositions.xml).
The architecture is unchanged: one Go service, one SQLite store with one writer, level-triggered reconciliation, one-shot seats, the SHA-bound gate, independent Jenkins CI, systemd units and gRPC on unix sockets.
What 1.1.0 adds is one authority for each contract the volumes used to restate:

- [Contracts](shared/contracts.xml#roles): the store `Commit` transaction, operation keys with a request hash, the lease machine and fencing, ticket transitions, claims, the retry owner, the outbox, the epoch and the timing table; the JSON shapes are [`contracts.schema.json`](shared/contracts.schema.json).
- [Authority](shared/authority.xml#principals): separate Unix users for the service, the launcher and pooled seats; the store derives the caller from the socket peer uid; credentials per job; the owner words.
- [Bootstrap](shared/cut-over.xml#bootstrap): B0 to B8, so the foundation can be built before GOFACTORY and nothing goes live before USERGO at B7.
- [CI capacity](shared/ci-capacity.xml#model): pod sizes, quota and admission in one place, and the pinned image builder.
- [Retry budget](shared/retry-budget.xml#layers): which layer retries what, and the budgets and deadlines that bound every loop.
- [Outside probe](shared/outside-probe.xml#probe): a store outage is seen and pushed from a machine outside the host.
- The page's [web security](nodes/N-32/spec.xml#web-security) and the phone's [instant push delivery](nodes/N-52/spec.xml#push-delivery).

The runtime loops the DAG cannot draw are shown as state machines in [section 8.4](#84-runtime-state-machines).

## 3. Goal

Replace the herdr-driven line, where an LLM seat is the trigger for every mechanical step, with a Go service that drives the line by records, so that a ticket moves from cut to merged with no agent and no human typing anything in between.

The problem, measured by the R-01 investigation ([01-ROOT-CAUSES](../investigation/01-ROOT-CAUSES.md#3-root-causes)):

| Fact | Number | Root cause |
| --- | --- | --- |
| `merged 200` records posted by hand by the acting orchestrator LLM | 43 of 92 (merge.sh 44, merger seat 5) | RC1 |
| `verified 201` records posted by one LLM seat, a median 28 minutes after the merge, though `verify-main.sh` exists | 66 of 66 | RC1 |
| `route failed` notes, 2026-10-13T15:29Z to 2026-10-14T02:22Z | 391 (212 of them addressing errors a broker would only store) | RC2 |
| Records that wanted an action and got it | 74 of 880 (8 percent) | RC2 |
| Untracked record copies in the owner checkout | 5,812 | RC3 |
| Seat refusals per day from ticket status living in a git front-matter field | 132 | RC3 |
| Lettered "Cause" tickets cut in one stretch | 51 in 12.6 hours (37 of 101 commits mention a cause) | RC5 |
| Commits of the last 60 that touch the product | 0 (28 change only `work-orders/` and `changelog/`) | RC5 |
| herdr 0.9.0 segfault at 2026-10-13T03:32:18Z, line dark until the owner noticed | about 9.5 hours | RC6 |
| CI builds aborted in a row by a 15-minute timeout, with no status ever posted to GitHub | 54 (builds 39 to 92, about 31 hours) | RC7 |
| Ticket approvals that were overrides | 238 of 238 | RC8 |
| Readers and producers of the owner's page | one each, both agents | RC9 |

The outcome:

- A Go service with gRPC owns scheduling, leases, heartbeats and state; code does every mechanical job (dispatch, merge, verify, retry, stall, cleanup, cards).
- One SQLite store on the host holds every record; nothing runtime lives in the repository; every state path has a cleanup command.
- Seats are one-shot `claude -p` runs that start from a record and end in a machine-readable result; a seat is never typed to, nudged or kept idle.
- The gate verdict is the GitHub required status `coq/gate`, posted by pods on the cluster, readable by an agent and never editable by one.
- The machine merges on a green gate plus a reviewer record and verifies main after every merge; a red main holds every merge but its fix.
- The owner reads and decides on one surface, the bearings page, as cards with receipts; his messages are routed by rule with four acknowledgements.
- The command center map (Factorio and Krastorio 2 look, phone first) replaces `/board` on every tier and is public at `map.gatehouse.click`.
- Every wait has a timeout and a fallback, every failure has exactly one retry owner inside a bounded budget ([retry owner](shared/contracts.xml#retry-owner), [budgets](shared/retry-budget.xml#budgets)), and the line proves itself with a daily exit test.
- Authority comes from the operating system, not from a seat's word: seats run as separate users with no store socket and no forge credential ([authority](shared/authority.xml#seat-isolation)).

## 4. What is reused

Working code and working infrastructure are copied, not reinvented.

| Source | What is copied |
| --- | --- |
| [`scheduler/api/scheduler/v1/scheduler.proto`](../../scheduler/api/scheduler/v1/scheduler.proto) | Kept and extended, never rewritten. Today it has `Executor{Run, Health}` and `Scheduler{Health, Status, Reload, Drain, Retry}`, and nothing streams. The book adds three services: `coq.store.v1.Store` (`Commit`, `Get`, `List`, `Tail`, `Snapshot`, `Health`; a single put is a `Commit` of one record), `Lease` (`Renew`, `Release`, `Start`) and `Intake` (`Answer`); `Tail` is the stream older text called Subscribe (D09, [store transaction](shared/contracts.xml#batch), [N-01](nodes/N-01/spec.xml#mechanism)). |
| [`scheduler/internal/core/`](../../scheduler/internal/core/) and [`scheduler/internal/testkit/`](../../scheduler/internal/testkit/) | The `Clock`, `JobStore`, `Ledger` and `Executor` interfaces and the fake clock every node's tests run on (the D09 small cut, [N-07](nodes/N-07/spec.xml#mechanism)). |
| [`line/bin/merge.sh`](../../line/bin/merge.sh) | Ported to Go as N-09 with the same choices: squash with the head sha guard, already-merged is success, hold read twice, never match refusal text ([N-09](nodes/N-09/spec.xml#mechanism)). |
| [`line/bin/verify-main.sh`](../../line/bin/verify-main.sh) | Its verdict and hold logic, ported as N-10, with the hold file turned into a `merge.hold` record and the suites moved to pods ([N-10](nodes/N-10/spec.xml#mechanism)). |
| [`ci/jenkins-lib/vars/coqGate.groovy`](../../ci/jenkins-lib/vars/coqGate.groovy) | The `runUnit` and `runPod` infrastructure ladder (lines 134 to 188); the plan script and status posts move into the Go service ([N-24](nodes/N-24/spec.xml#mechanism)). |
| [`ci/config/images.json`](../../ci/config/images.json) | The one image config, extended with digests, platforms and suites ([N-22](nodes/N-22/spec.xml#mechanism)). |
| [`factory/bin/suites.sh`](../../factory/bin/suites.sh) and [`factory/config/suites.json`](../../factory/config/suites.json) | The diff to suite map, read from main, never from the head ([N-23](nodes/N-23/spec.xml#mechanism)). |
| [`factory/bin/claims.sh`](../../factory/bin/claims.sh) | The file overlap rule, kept verbatim, for readiness, workspace claims and the validator ([N-03](nodes/N-03/spec.xml#mechanism)). |
| [`events/schema/event.schema.json`](../../events/schema/event.schema.json) | The record id form `YYYYMMDDTHHMMSSZ-CODE-xxxxx` and the HTTP-shaped code enum ([state store envelope](shared/state-store.xml#envelope)). |
| [`tools/bearings/`](../../tools/bearings/) | `page.html` and `theme.css` (the owner's), the key and cookie model, `bearings.json` and its schema, the Playwright suite, the front door of PR 187, the ask, wait and reply contract of `AGENTS.md` ([N-32](nodes/N-32/spec.xml#mechanism), [N-34](nodes/N-34/spec.xml#mechanism)). |
| `herdr/config/leases.json` | The seat lease ttl, now one key of the [timing table](shared/contracts.xml#timing) ([N-02](nodes/N-02/spec.xml#mechanism)). |
| [jenkins-shared-lib](https://github.com/jkkelley/jenkins-shared-lib) | `buildKaniko`, `updateGitOpsManifest` and `agentPodYaml`, as the yieldpoint-ai pipeline uses them ([N-22](nodes/N-22/spec.xml#mechanism), [N-35](nodes/N-35/spec.xml#mechanism)). |
| [homelab-gitops](https://github.com/jkkelley/homelab-gitops) | The JCasC seed `apps/jenkins/jenkins.yaml`, the ESO secret `jenkins-eso/externalsecret-ghcr.yaml`, the Application shape of `resume-star.yaml`, the ntfy deployment on branch `feat/ntfy-alerts` ([N-20](nodes/N-20/spec.xml#mechanism), [N-21](nodes/N-21/spec.xml#mechanism), [N-52](nodes/N-52/spec.xml#provider)). |
| Argo CD app-of-apps, HAProxy ingress, WireGuard to `${SITE_K8S_WORKER}`, Lightsail VPS `${SITE_VPS_ADDR}` (Nginx, Let's Encrypt), Route 53 zone `gatehouse.click`; the site values resolve from the owner's site file `$HOME/.config/coq/site.env`, never from the repository ([config keys](shared/state-store.xml#config-keys)) | The public path for the map, exactly as yieldpoint-ai runs today: one more name on the existing Nginx server block (owner note 5, [N-35](nodes/N-35/spec.xml#mechanism)). |
| `ghcr.io/jkkelley` | The image registry for every image, pinned by digest. |
| Tailscale user-space front door (PR 186, PR 187) | Ported to Go as the unit `coq-front-door@<page>`, same behaviour ([N-34](nodes/N-34/spec.xml#mechanism)). |
| [Krastorio2Assets v2.0.5](https://codeberg.org/raiguard/Krastorio2Assets) and the vanilla GUI palette | Palette values only, as CSS custom properties (`--k2-frame #313031`, `--k2-accent #FAA838`, `--k2-green #2BE327`, `--k2-red #DA4535` and the rest), and the 260 high-confidence Krastor original sprites with attribution ([principles](shared/principles.xml#krastorio-look), [N-36](nodes/N-36/spec.xml#mechanism)). |
| Titillium Web (SIL Open Font License 1.1) | The Factorio GUI face, allowed on a public page. |
| The Execution Rail status codes (`rebuild/factory-rebuild-plan.xml#status-codes`) | Carried unchanged, so the rail becomes a panel of the page without translation ([N-33](nodes/N-33/spec.xml#mechanism)). |
| SPEC-16.F and SPEC-16.G (branch `feat/go-scheduler-design-one-xml-spec-per-domain-unde`) | The belt heartbeat and stall latch (N-12), the config schema (state store config keys), hypotheses H01 to H26 and bounds B1 to B10 as test names. |
| `tools/bearings/standards/STD-owner-comms-001.json` | The card and bubble wording rules the card checker and the comms checker enforce ([seat contract](shared/seat-contract.xml#standing-policies)). |

Not copied, with the reason ([rejected with reason](shared/rejected-with-reason.xml#rejected)):

- The fourteen SPEC-16 build tickets: cancelled after GOFACTORY by N-50, because the small Go cut on the same proto replaces them (D09, card C41).
- PR 35 and its v2.0 export, SPEC-17 1.0.1 and its 1.1.0 draft: sources, never authority (D14, card C42); PR 35 is closed by N-50.
- Wube-derived and BiusArt sprites (inventory classes 2 to 4: 443, 8 and 131 files): never ship; belts, inserters, lamps and pipes are original art.
- A broker (NATS): one store, no broker; 212 of the 391 route failures were addressing errors a broker would only store (D10, card C34).
- `route.sh` and its routes table, the tester, merger and verifier seats, and the idle alarm with its patrol watches: code does the mechanical jobs and a stall timer replaces the alarm (D11, D17).
- The webhook listener (`line/bin/hook-listener.sh`, PR 177): GitHub cannot reach the host on its private LAN address; the poll is the correctness path (D06).
- herdr as scheduler, router or store: herdr is the owner's window only (D08).
- The page polling loop as transport and the Execution Rail as a second page: push for everything, one surface (D20, D21).
- Drive as the source of truth: the repository is the truth, Drive gets copies (D24).
- `bin/work-order.sh` cleanup and approve clauses, the dead hooks `no-hand-start.mjs` and `shell-lex.mjs`, the GitHub Actions Runner Controller CRDs, the r-prefixed record id form.
- The `aws-lightsail-k8s-router` design: the existing Nginx server block gets one more name instead (owner note 5).
- Forgejo now: GitHub now, Forgejo later behind the one forge interface of N-04 (D18).

## 5. Architecture

One Go binary (`coq-service`) runs on the WSL host as a systemd user unit of its own service user and owns every decision.
Seats run on the host as one-shot processes under pooled seat users, each in its own transient unit.
Tests, lint and image builds run as pods on the owner's cluster.
The owner sees everything through the bearings page.
Who may do what is one volume, [authority](shared/authority.xml#principals): the service user `coq-svc` alone owns the state root and the service credentials, the launcher user `coq-launch` starts seats through the root-owned helper `coq-seat-exec`, and the seat users `coq-seat-01` to `coq-seat-16` run one run at a time and hold no store socket and no forge credential.

```mermaid
flowchart LR
  subgraph OWN["Owner"]
    PH["iPhone 16 Pro Max"]
    DT["Desktop browser"]
    HW["herdr panes: the owner's window only"]
  end
  subgraph HOST["WSL host: systemd units with linger, WSL interop off"]
    FD["coq-front-door@coq-stable N-34: Tailscale bind"]
    PG["coq-bearings@tier N-32: loopback, SSE /events, POST /answer /message"]
    WT["coq-watcher@page N-27: the watcher lamp"]
    subgraph SVC["coq-service as user coq-svc: one Go binary, gRPC on unix sockets"]
      CORE["N-06 clock and health, N-01 store API, N-02 leases, N-43 code table, N-44 flags"]
      LINE["N-03 intake, N-07 scheduler, N-08 gate, N-09 merge, N-10 verify, N-11 retry, N-12 stall"]
      SEATL["N-13 seat layer, N-14 workspace, N-15 launcher, N-18 validator"]
      CIQ["N-22 image jobs, N-23 suite planner, N-25 status post, N-26 main verify"]
      OWNS["N-28 cards, N-29 intake, N-30 inbox, N-31 push, N-52 phone bridge"]
      GOV["N-45 cleanup, N-47 Drive publish, N-48 promote, N-49 unlanded, N-50 cut-over, N-51 exit test"]
      POLL["N-04 GitHub poll every 30 s"]
    end
    DB[("COQ_STATE/store/coq.db: SQLite WAL, one writer, epoch")]
    BK[("N-05 backups: classes tick, daily, monthly, manual")]
    SEATS["one-shot claude -p seats as users coq-seat-NN: worker N-16, spec-author N-17, reviewer N-19"]
    WS[("COQ_CACHE: git mirror and workspace slots")]
  end
  PROBE["coq-probe on one Raspberry Pi: outside the host, no store"]
  UP["ntfy.sh upstream: message id and topic hash only"]
  subgraph GHB["GitHub"]
    REPO["jkkelley/coq-jev-herdr-plugin: PRs, coq/gate required on main"]
  end
  subgraph K8S["Home cluster, synced by Argo CD from homelab-gitops"]
    JK["Jenkins as code: namespace jenkins, JCasC, Longhorn home"]
    POD["namespace coq-factory: test pods, quota, no secrets"]
    KAN["Kaniko image builds"]
    MAPP["coq-map nginx pod: static map"]
    NTFY["ntfy"]
  end
  GHCR[("ghcr.io/jkkelley")]
  LS["Lightsail VPS Nginx: map.gatehouse.click"]
  GD[("Google Drive: version-named copies")]

  PH -->|"tailnet"| FD
  FD -->|"loopback pipe"| PG
  DT -->|"loopback or tailnet"| PG
  PG <-->|"gRPC Intake, Inbox, Push"| OWNS
  WT -->|"stream owner.answer and owner.message"| OWNS
  CORE -->|"every record"| DB
  DB --> BK
  LINE --> CORE
  OWNS --> CORE
  SEATL -->|"coq-launch via coq-seat-exec: one transient unit per run"| SEATS
  SEATS -->|"result file only, no store socket"| SEATL
  SEATL --> WS
  SEATL -->|"push branch, open PR as coq-svc, forge-pr"| REPO
  POLL -->|"REST with ETag, forge-read"| REPO
  LINE -->|"squash merge, forge-merge"| REPO
  CIQ -->|"buildWithParameters with COQ_OP_ID"| JK
  CIQ -->|"coq/gate status, coq-gate GitHub App"| REPO
  JK --> POD
  JK --> KAN
  KAN --> GHCR
  POD -->|"pull by digest"| GHCR
  GOV -->|"rclone, scope drive.file"| GD
  GOV -->|"job coq-map, gitops tag"| JK
  JK -->|"Argo sync"| MAPP
  LS -->|"WireGuard, HAProxy"| MAPP
  OWNS -->|"POST card"| NTFY
  NTFY -->|"poll request"| UP
  UP -->|"APNs wake"| PH
  PH -->|"fetch the body over the tailnet"| NTFY
  PROBE -->|"GET /livez and the stable page"| FD
  PROBE -->|"its own topic and token"| NTFY
  HW -.->|"agent status events only"| LINE
```

How to read it:

- Every arrow into `coq-service` lands as a record in the store through one `Commit` transaction; every arrow out of it is a step a node takes on a record, never a prompt ([store transaction](shared/contracts.xml#batch)).
- The store socket accepts only the users of group `coq-store`; the server reads the peer uid from the socket and derives the caller's node and permitted kinds from it ([peer credentials](shared/authority.xml#peer-credentials)).
- An external effect (a push, a PR, a status, a merge, a Jenkins build) is first an outbox row written in the same transaction as the record that decided it, so after a crash the row is reconciled by its external id before anything is sent again ([outbox](shared/contracts.xml#outbox)).
- Each forge job has its own credential, and seats hold none ([credential matrix](shared/authority.xml#credential-matrix), [GitHub App](shared/authority.xml#github-app)).
- The page service, the watcher and the front door are separate units with separate lifetimes, so a page upgrade never stops the owner's intake ([N-27](nodes/N-27/spec.xml#mechanism)).
- The cluster never reaches the host: pods have egress to cluster DNS, the Jenkins controller, GitHub and GHCR only, so the public map is static and live state reaches the phone over the tailnet ([pod template](shared/ci-capacity.xml#pod-template), [N-21](nodes/N-21/spec.xml#mechanism), [N-38](nodes/N-38/spec.xml#mechanism)).
- A store or host outage is seen from outside: `coq-probe` on a Raspberry Pi of the cluster checks the host and alerts on its own ntfy topic, with no store in its path ([outside probe](shared/outside-probe.xml#probe)).
- A card reaches a locked iPhone at once: the cluster ntfy forwards only a poll request through ntfy.sh, and the phone fetches the body from the cluster over the tailnet ([push delivery](nodes/N-52/spec.xml#push-delivery)).
- herdr sends exactly one thing to the line: the agent status event N-12 uses to see a long-lived seat parked on a prompt.

Depth: [state store](shared/state-store.xml#purpose), [seat contract](shared/seat-contract.xml#run), [command center](shared/command-center.xml#hosting), [N-06 unit](nodes/N-06/spec.xml#mechanism), [WSL host](shared/authority.xml#wsl-host).

## 6. DAG

Every node turns one input record into one output record; a seat or a process on a node exists only between the two.
An edge means the output record of the source is the input record of the target.
The store (N-01) carries every record and the push transport (N-31) carries every page-bound record; their return edges are not drawn, because they would make every node a cycle through the store.
Time loops (a retry, a phase change, an owner answer) are re-entries into the sink `RE` with a counter that only grows, so the graph stays acyclic: 52 nodes, 129 drawn edges, 12 re-entries, checked by Kahn's algorithm in [`bin/dag-check.py`](bin/dag-check.py) (check C16).
Since 1.1.0 the same check compares the drawing with the edges every node volume declares, so a node cannot name an input the DAG does not show ([dag.md section 2.1](dag.md#21-declared-edges-that-are-not-drawn)).
The acyclic drawing does not prove that the loops end: the [retry owner](shared/contracts.xml#retry-owner) and the [budgets](shared/retry-budget.xml#budgets) do, and the loops themselves are drawn as state machines in [section 8.4](#84-runtime-state-machines).

```mermaid
flowchart LR
  subgraph G1["G1 Store and leases"]
    N-01["N-01 State store"]
    N-02["N-02 Lease service"]
    N-03["N-03 Ticket intake and readiness"]
    N-04["N-04 GitHub poll"]
    N-05["N-05 Backups"]
    N-06["N-06 Service unit, clock and health"]
  end
  subgraph G2["G2 Scheduler and verdicts"]
    N-07["N-07 Scheduler tick and dispatch"]
    N-08["N-08 Gate check"]
    N-09["N-09 Merge"]
    N-10["N-10 Main verdict and hold"]
    N-11["N-11 Retry and backoff"]
    N-12["N-12 Stall timer"]
  end
  subgraph G3["G3 Seats"]
    N-13["N-13 Seat layer render"]
    N-14["N-14 Workspace provision"]
    N-15["N-15 One-shot seat launcher"]
    N-16["N-16 Worker run"]
    N-17["N-17 Spec-author run"]
    N-18["N-18 Validator"]
    N-19["N-19 Reviewer run"]
  end
  subgraph G4["G4 CI as code and pods"]
    N-20["N-20 Jenkins as code"]
    N-21["N-21 Factory namespace"]
    N-22["N-22 Image build"]
    N-23["N-23 Suite planner"]
    N-24["N-24 Pod run"]
    N-25["N-25 Gate status post"]
    N-26["N-26 Main verify pipeline"]
  end
  subgraph G5["G5 Owner surface"]
    N-27["N-27 Watcher lamp"]
    N-28["N-28 System lane card builder"]
    N-29["N-29 Owner answer intake"]
    N-30["N-30 Go inbox with acks"]
    N-31["N-31 Push transport"]
    N-32["N-32 Bearings page service"]
    N-33["N-33 Rail panel"]
    N-34["N-34 Tailnet front door"]
    N-52["N-52 Phone push bridge"]
  end
  subgraph G6["G6 Command center map"]
    N-35["N-35 Hello page deploy"]
    N-36["N-36 Art pipeline"]
    N-37["N-37 Panel binding registry"]
    N-38["N-38 Map screen"]
    N-39["N-39 Machine screen"]
    N-40["N-40 Stats screen"]
    N-41["N-41 Alerts screen"]
    N-42["N-42 Controls screen"]
  end
  subgraph G7["G7 Governance and cut-over"]
    N-43["N-43 Status code map loader"]
    N-44["N-44 Build-mode flag"]
    N-45["N-45 Cleanup registry and runs"]
    N-46["N-46 Spec book check"]
    N-47["N-47 Drive publish"]
    N-48["N-48 Tier promotion with screenshot"]
    N-49["N-49 Unlanded cleanup"]
    N-50["N-50 Cut-over records"]
    N-51["N-51 Exit test"]
  end
  RE(["RE re-entry: a new traversal starts at the named node"])
  N-01 --> N-02
  N-01 --> N-03
  N-01 --> N-05
  N-01 --> N-31
  N-02 --> N-07
  N-02 --> N-12
  N-03 --> N-02
  N-03 --> N-07
  N-03 --> N-09
  N-04 --> N-08
  N-04 --> N-35
  N-04 --> RE
  N-05 --> N-45
  N-06 --> N-02
  N-06 --> N-03
  N-06 --> N-04
  N-06 --> N-05
  N-06 --> N-07
  N-06 --> N-12
  N-06 --> N-28
  N-06 --> N-41
  N-06 --> N-42
  N-06 --> N-43
  N-06 --> N-44
  N-06 --> N-45
  N-06 --> N-49
  N-06 --> N-51
  N-07 --> N-11
  N-07 --> N-12
  N-07 --> N-13
  N-07 --> N-14
  N-07 --> N-15
  N-07 --> N-28
  N-07 --> N-40
  N-08 --> N-09
  N-08 --> N-11
  N-08 --> N-48
  N-08 --> RE
  N-09 --> N-11
  N-09 --> N-26
  N-09 --> N-35
  N-09 --> N-45
  N-09 --> N-47
  N-09 --> N-48
  N-09 --> N-50
  N-10 --> N-28
  N-10 --> N-41
  N-10 --> N-51
  N-10 --> RE
  N-11 --> N-28
  N-11 --> N-41
  N-11 --> RE
  N-12 --> N-11
  N-12 --> N-28
  N-12 --> N-41
  N-13 --> N-11
  N-13 --> N-15
  N-14 --> N-11
  N-14 --> N-15
  N-15 --> N-11
  N-15 --> N-12
  N-15 --> N-16
  N-15 --> N-17
  N-15 --> N-19
  N-16 --> N-11
  N-16 --> N-23
  N-16 --> N-48
  N-17 --> N-11
  N-17 --> N-18
  N-18 --> N-11
  N-18 --> RE
  N-19 --> N-09
  N-19 --> N-11
  N-20 --> N-22
  N-20 --> N-23
  N-20 --> N-26
  N-21 --> N-24
  N-21 --> N-26
  N-22 --> N-24
  N-22 --> N-35
  N-23 --> N-24
  N-23 --> N-36
  N-23 --> N-46
  N-24 --> N-25
  N-25 --> N-04
  N-26 --> N-10
  N-27 --> N-28
  N-27 --> N-29
  N-27 --> N-30
  N-27 --> N-42
  N-28 --> N-32
  N-28 --> N-52
  N-28 --> RE
  N-29 --> N-10
  N-29 --> N-44
  N-29 --> N-49
  N-29 --> N-50
  N-29 --> RE
  N-30 --> N-32
  N-30 --> RE
  N-31 --> N-32
  N-31 --> N-33
  N-31 --> N-38
  N-31 --> N-39
  N-31 --> N-40
  N-31 --> N-41
  N-31 --> N-42
  N-32 --> N-34
  N-32 --> RE
  N-33 --> N-32
  N-33 --> N-40
  N-35 --> N-38
  N-35 --> N-48
  N-36 --> N-38
  N-36 --> N-39
  N-36 --> N-40
  N-36 --> N-41
  N-36 --> N-42
  N-37 --> N-38
  N-37 --> N-39
  N-37 --> N-40
  N-37 --> N-41
  N-37 --> N-42
  N-38 --> N-39
  N-41 --> N-39
  N-41 --> N-52
  N-42 --> RE
  N-43 --> N-07
  N-43 --> N-28
  N-43 --> N-37
  N-44 --> N-07
  N-44 --> N-13
  N-44 --> N-42
  N-46 --> N-25
  N-48 --> N-28
  N-48 --> N-32
  N-49 --> N-45
  N-49 --> RE
  N-50 --> N-45
  N-50 --> RE
  N-51 --> N-28
```

### 6.1 Every node with its input and output

The wave column is the build order of [section 6.3](#63-build-order-as-numbered-waves); the volume column links the node's spec.

| Id | Name | Group | Input record | Output record | Wave | Volume |
| --- | --- | --- | --- | --- | --- | --- |
| N-01 | State store | G1 | Commit request over gRPC from an authenticated principal (operation key with request hash, fence, preconditions, entity writes, records, outbox effects) | commit reply (seq, epoch, hash, versions) or a refusal: 403 record.refused, 409 conflict, 412 stale token | 1 | [spec](nodes/N-01/spec.xml#N-01) |
| N-02 | Lease service | G1 | ticket.ready record (claimable node and attempt) | lease row (class, state, non-empty holder, integer token, generation, expiry) reserved in N-07's GrantDispatch, or lease.refused | 1 | [spec](nodes/N-02/spec.xml#N-02) |
| N-03 | Ticket intake and readiness | G1 | ticket record (validated, files declared, deps named; re-entry from N-18 or an owner cut) or a ticket.request admitted as a spec-phase cut request | ticket.ready record (deps done, no file claimed by another in-flight ticket) or ticket.waiting | 7 | [spec](nodes/N-03/spec.xml#N-03) |
| N-04 | GitHub poll | G1 | tick record (every tick from N-06, plus coq/gate statuses posted by N-25) | forge.snapshot record (open PRs, head shas, coq/gate status, mergeability, main sha) | 4 | [spec](nodes/N-04/spec.xml#N-04) |
| N-05 | Backups | G1 | backup.tick record (schedule from N-06) over the live store | backup record (snapshot path, checksum, class tick, daily, monthly or manual) or backup.failed | 1 | [spec](nodes/N-05/spec.xml#N-05) |
| N-06 | Service unit, clock and health | G1 | unit.start (systemd user unit of the Go service) | tick record (scheduler, poll, backup, stall and daily ticks) and health record (gRPC Health, counters) | 1 | [spec](nodes/N-06/spec.xml#N-06) |
| N-07 | Scheduler tick and dispatch | G2 | lease record plus tick record (level-triggered: compare open work with live runs before any dispatch) | dispatch record (the contracts dispatch body: ticket, phase, role, attempt, lease key and token, deadline_at, repo_sha, brief path), committed with the lease and the ticket transition in one GrantDispatch | 7 | [spec](nodes/N-07/spec.xml#N-07) |
| N-08 | Gate check | G2 | forge.snapshot record for a PR head sha | gate.verdict record (green, red or pending for the head sha, from the coq/gate status the agent can read but not edit) | 4 | [spec](nodes/N-08/spec.xml#N-08) |
| N-09 | Merge | G2 | gate.verdict green plus review.passed on the same head sha | merge record (merge sha, PR number) or merge.conflict 409 | 7 | [spec](nodes/N-09/spec.xml#N-09) |
| N-10 | Main verdict and hold | G2 | main.gate.status record (coq/gate on the main sha after a merge) | verified 201 record, or rejected 422 plus merge.hold record (no merge until a green main) | 5 | [spec](nodes/N-10/spec.xml#N-10) |
| N-11 | Retry and backoff | G2 | failure record (seat.result blocked or failed, review.changes, merge.conflict, stall, validator refusal) | attempt record n+1 when the [retry owner](shared/contracts.xml#retry-owner) table charges it, or dead record with one escalation | 7 | [spec](nodes/N-11/spec.xml#N-11) |
| N-12 | Stall timer | G2 | lease record plus heartbeat records plus stall tick | stall record (lease revoked, kill:run_id written for the launcher, reason) when no progress within the stall bound | 7 | [spec](nodes/N-12/spec.xml#N-12) |
| N-13 | Seat layer render | G3 | dispatch record (role, repo, build-mode state) | seat.bundle record (settings.json from the role, deny list from declared files, brief, hash) | 6 | [spec](nodes/N-13/spec.xml#N-13) |
| N-14 | Workspace provision | G3 | dispatch record | workspace record (worktree path, branch from origin/main, slot, file claims checked and recorded) or workspace.refused | 6 | [spec](nodes/N-14/spec.xml#N-14) |
| N-15 | One-shot seat launcher | G3 | seat.bundle plus workspace record | seat.result record always (outcome, cost, turns, terminal reason, session id; a dead run yields blocked) and heartbeat records while it runs | 6 | [spec](nodes/N-15/spec.xml#N-15) |
| N-16 | Worker run | G3 | worker brief inside a seat run (ticket, workspace) | pr.opened record (branch pushed, PR number, head sha) or seat.result blocked | 6 | [spec](nodes/N-16/spec.xml#N-16) |
| N-17 | Spec-author run | G3 | spec-author brief inside a seat run (design anchor, group, verdict from a failed attempt when retried) | ticket-set.draft record (tickets as data: files, acceptance commands, input and output declared) | 6 | [spec](nodes/N-17/spec.xml#N-17) |
| N-18 | Validator | G3 | ticket-set.draft record | ticket records accepted (acceptance commands run on main with observed exit codes) or validator.refused with the failing command | 6 | [spec](nodes/N-18/spec.xml#N-18) |
| N-19 | Reviewer run | G3 | reviewer brief inside a seat run (PR, gate green, diff) | review.passed 201 or review.changes 422 record on the head sha | 6 | [spec](nodes/N-19/spec.xml#N-19) |
| N-20 | Jenkins as code | G4 | jenkins config record (JCasC, job by config, pinned image, resources, Longhorn home; a commit in gitops) | job.registered record (config hash, image digest, resource limits, home volume) | 4 | [spec](nodes/N-20/spec.xml#N-20) |
| N-21 | Factory namespace | G4 | namespace manifest record (ResourceQuota, LimitRange, PriorityClass, service account with no secret access, egress to cluster DNS, the Jenkins controller, GitHub and GHCR; a commit in gitops) | namespace.ready record (Argo synced, quota and policy present) | 4 | [spec](nodes/N-21/spec.xml#N-21) |
| N-22 | Image build | G4 | image config record (images.json or Containerfile change, digest pins) | image record (ghcr digest, pinned in config, checksum-verified binaries) | 4 | [spec](nodes/N-22/spec.xml#N-22) |
| N-23 | Suite planner | G4 | pr.opened record (head sha, diff) | suite.plan record (suites from the diff; an unmapped path plans the full set) | 4 | [spec](nodes/N-23/spec.xml#N-23) |
| N-24 | Pod run | G4 | suite.plan entry (one case) | pod.run record (exit code, log path, infrastructure retries by the ladder; an assertion failure never retried) | 4 | [spec](nodes/N-24/spec.xml#N-24) |
| N-25 | Gate status post | G4 | pod.run records for one head sha | commit status coq/gate on the head sha (success, failure, error superseded) plus the gate page link | 4 | [spec](nodes/N-25/spec.xml#N-25) |
| N-26 | Main verify pipeline | G4 | merge record (main push sha) | main.gate.status record (coq/gate on the main sha, full suite set) | 5 | [spec](nodes/N-26/spec.xml#N-26) |
| N-27 | Watcher lamp | G5 | tier unit start (the wait loop of a bearings tier as its own supervised unit) | watcher.alive record (lock with heartbeat per tier); a card cannot post without it | 3 | [spec](nodes/N-27/spec.xml#N-27) |
| N-28 | System lane card builder | G5 | record whose status code maps to owner-acts (dead, rejected main, exit test, unhealthy) plus watcher.alive | card record (one decision: about, decide, options with what happens, recommendation) posted to the tier | 3 | [spec](nodes/N-28/spec.xml#N-28) |
| N-29 | Owner answer intake | G5 | answer record (the owner's pick and words on the page, re-entry from N-32, or relayed from chat and recorded) | ruling record in the store (card id, pick, words, at) that gates and cut-over nodes read | 2 | [spec](nodes/N-29/spec.xml#N-29) |
| N-30 | Go inbox with acks | G5 | message record (the owner's message on the page, re-entry from N-32) | routed.message record (lane and consumer by rule) and ack record delivered back to the page | 3 | [spec](nodes/N-30/spec.xml#N-30) |
| N-31 | Push transport | G5 | record.committed seq from the store | pushed.frame record per client (delivered seq; full state re-read on reconnect) | 3 | [spec](nodes/N-31/spec.xml#N-31) |
| N-32 | Bearings page service | G5 | pushed.frame record (cards, messages, acks, panels, staleness) | page.state record (rendered page, staleness shown); the owner's answers and messages leave as new traversals at N-29 and N-30 | 3 | [spec](nodes/N-32/spec.xml#N-32) |
| N-33 | Rail panel | G5 | plan ledger row (pushed) | rail.panel frame (plan steps, ledger, status codes) inside the page | 3 | [spec](nodes/N-33/spec.xml#N-33) |
| N-34 | Tailnet front door | G5 | page.up record (tier server listening on loopback) | front-door record (tailnet bind, port, pid; retried 3 times then exit 4) | 3 | [spec](nodes/N-34/spec.xml#N-34) |
| N-35 | Hello page deploy | G6 | map app commit (Jenkinsfile with jenkins-shared-lib, image on ghcr.io/jkkelley, app entry in homelab-gitops) | deploy record (image digest, Argo synced, HAProxy route, Lightsail name map.gatehouse.click answering 200) | 8 | [spec](nodes/N-35/spec.xml#N-35) |
| N-36 | Art pipeline | G6 | art inventory record (Krastor class 1 files, original art for belts, inserters, lamps and pipes) | sprite.sheet record (atlas, attribution text, license text; no Wube-derived or BiusArt file) | 8 | [spec](nodes/N-36/spec.xml#N-36) |
| N-37 | Panel binding registry | G6 | screen spec volume (every panel of the five screens) | binding record (panel to store record kind) and binding.check result; an unbound panel fails the build | 8 | [spec](nodes/N-37/spec.xml#N-37) |
| N-38 | Map screen | G6 | pushed.frame record (DAG nodes with status and heartbeat, queues with depth, seats in flight, the hold lamp: HOLD and the owner word it waits on) | map.frame (machines, belts, inserters, lamps at the frame budget) and selection record | 8 | [spec](nodes/N-38/spec.xml#N-38) |
| N-39 | Machine screen | G6 | selection record plus the node's state frame | machine.panel frame (one node: input, output, attempt, lease, last records) | 8 | [spec](nodes/N-39/spec.xml#N-39) |
| N-40 | Stats screen | G6 | counters frame (records, jobs, wakes, seats, pods, cost) | stats.frame (production statistics panel) | 8 | [spec](nodes/N-40/spec.xml#N-40) |
| N-41 | Alerts screen | G6 | alert records (stall, dead, rejected main, unhealthy) | alerts.frame and alert.ack record | 8 | [spec](nodes/N-41/spec.xml#N-41) |
| N-42 | Controls screen | G6 | controls frame (hold flag, build-mode state, watcher lamp, health) | control.action record (owner-initiated: hold, resume, build-mode, one-time break glass) as a new traversal at N-29 | 8 | [spec](nodes/N-42/spec.xml#N-42) |
| N-43 | Status code map loader | G7 | shared/status-codes.xml commit | code.table record (version hash loaded by Reload; every code names who acts) | 1 | [spec](nodes/N-43/spec.xml#N-43) |
| N-44 | Build-mode flag | G7 | ruling record that sets the flag (with expiry) | build-mode.state record (on or off, expiry; cleared by the system at expiry) | 2 | [spec](nodes/N-44/spec.xml#N-44) |
| N-45 | Cleanup registry and runs | G7 | trigger record (merge record for branch and worktree release, backup record for retention, timer for state paths named in runbook volumes) | cleanup.run record (dry-run listing, then deletions, 3 attempts then reported) | 1 | [spec](nodes/N-45/spec.xml#N-45) |
| N-46 | Spec book check | G7 | spec volume commit in a suite plan (rebuild/design paths) | check.verdict record (XSD, every pointer resolves, 1000-line cap, contents element, parent pointer, many agents section) | 4 | [spec](nodes/N-46/spec.xml#N-46) |
| N-47 | Drive publish | G7 | merge record touching rebuild/design | drive.copy record (version-named file ids, immutable) | 8 | [spec](nodes/N-47/spec.xml#N-47) |
| N-48 | Tier promotion with screenshot | G7 | pr.opened or merge record touching tools/bearings or the map app | promotion record (dev then uat then stable swapped in place without stopping the waits) with the screenshot record attached | 8 | [spec](nodes/N-48/spec.xml#N-48) |
| N-49 | Unlanded cleanup | G7 | GOFACTORY ruling record | disposition records, one per 04-UNLANDED entry (land, supersede, close), dry-run listing first | 2 | [spec](nodes/N-49/spec.xml#N-49) |
| N-50 | Cut-over records | G7 | GOFACTORY ruling plus the D09 and D14 rulings | cancel records for the fourteen SPEC-16 tickets, PR 35 close record, design branch delete record | 2 | [spec](nodes/N-50/spec.xml#N-50) |
| N-51 | Exit test | G7 | daily tick plus the day's verified records, line-ops audit and git status | exit.verdict record (zero agent line operations and a clean checkout, or not); product freeze lifts only on pass | 9 | [spec](nodes/N-51/spec.xml#N-51) |
| N-52 | Phone push bridge | G5 | card record | push.receipt record (the provider accepted it) and push.observed (the phone fetched it); ships dark until the Go inbox is live | 9 | [spec](nodes/N-52/spec.xml#N-52) |

### 6.2 Re-entries

| Source | What re-enters | Enters at | Bound |
| --- | --- | --- | --- |
| N-04 | a commit to `shared/status-codes.xml` seen on main | N-43, which loads the new table by hash | one load per table hash |
| N-08 | `gate.verdict` green | N-03, which moves the ticket to the reviewer phase | one phase change per phase: worker, reviewer, merge |
| N-10 | `rejected` 422 on main, and the hold | N-03 as a fix-for-hold `ticket.request`, cut by a spec-author; N-09 reads the hold and merges only the fix | the hold stands until a green main; 3 fix tickets, then one owner card |
| N-11 | `attempt` n+1 | N-02 as a fresh claim; N-07 reads it for `not_before` | the [retry owner](shared/contracts.xml#retry-owner) charge, then `dead` and one card |
| N-18 | accepted `ticket` records | N-03 as new tickets | a ticket set is finite and every ticket names its files |
| N-28 | a card's policy default at its deadline | N-29 as a defaulted answer | never on an owner-only card; one ruling per card id |
| N-29 | `ruling` | N-03 (unblock a dead ticket) or N-44 (a flag) | one ruling per card id |
| N-30 | `routed.message` | N-03 as a `ticket.request` (rule R05) | one request per message id |
| N-32 | the owner's answer or message | N-29 or N-30 | the owner acts; nothing loops without him |
| N-42 | `control.action` | N-29 as an owner action | break glass is one time |
| N-49 | LAND dispositions | N-03 as `ticket.request`s | one ticket per LAND row of 04-UNLANDED |
| N-50 | the archive of the fourteen cancels | N-03 as one `ticket.request` | one request per cancel set |

Depth: [dag.md section 4](dag.md#4-re-entries).

### 6.3 Build order as numbered waves

A wave is a set of build tickets that run in parallel under the one-file, one-in-flight-ticket rule; a wave starts when the waves it depends on have merged dark.
Wave 1 is the [bootstrap](shared/cut-over.xml#bootstrap) foundation B1 and may be built before GOFACTORY, against a test state root with no live unit and no forge or Jenkins effect; waves 2 to 9 are cut only after the GOFACTORY ruling (B2).
Building is never going live: every wave merges dark, the cut-over steps turn flags on, and the build order ends at USERGO, accepted only at B7, which makes the line live (B8).
Each node is built and tested against record fixtures of its input on the fake clock, so a consumer may be built before its producer (for example N-28 cards before N-11 retry), because its input is a record with a schema, not a running node.
The go-live column is the step of the one cut-over order ([cut-over](shared/cut-over.xml#order)) that turns the wave's flags on.

```mermaid
flowchart LR
  B0(["B0 design approved: R-03 closed"]) --> W1["Wave 1 foundation, B1, dark on a test state root: N-01 N-43 N-06 N-05 N-02 N-45"]
  W1 --> GF{"GOFACTORY ruling: B2"}
  GF --> W2["Wave 2 rulings and the cut: N-29 N-44 N-49 N-50"]
  W2 --> W3["Wave 3 owner surface: N-31 N-30 N-27 N-28 N-33 N-32 N-34"]
  W2 --> W4["Wave 4 CI as code: N-20 N-21 N-22 N-23 N-24 N-25 N-04 N-08 N-46"]
  W4 --> W5["Wave 5 main verify: N-26 N-10"]
  W2 --> W6["Wave 6 seats: N-13 N-14 N-15 N-16 N-17 N-18 N-19"]
  W5 --> W7["Wave 7 stall, retry, intake, scheduler, merge: N-12 N-11 N-03 N-07 N-09"]
  W6 --> W7
  W3 --> W8["Wave 8 command center and promotion: N-35 N-36 N-37 N-38 N-39 N-40 N-41 N-42 N-47 N-48"]
  W4 --> W8
  W3 --> W9["Wave 9 built dark, live after B8: N-51 N-52"]
  W7 --> R(["B3 to B6 cut-over steps by proofs, then B7 ready: proofs of steps 2, 6 and 7"])
  W8 --> R
  W9 --> R
  R --> U{"USERGO at B7 only: B8 live"}
```

| Wave | Nodes | Why here | Goes live at cut-over step |
| --- | --- | --- | --- |
| 1 | N-01 State store, N-43 Status code map loader, N-06 Service unit, clock and health, N-05 Backups, N-02 Lease service, N-45 Cleanup registry and runs | The system comes up before anyone works; every later node writes to the store, reads the clock and registers a cleanup; built in B1 before GOFACTORY, dark | 0, after GOFACTORY |
| 2 | N-29 Owner answer intake, N-44 Build-mode flag, N-49 Unlanded cleanup, N-50 Cut-over records | The rulings C34 to C58 and the standing USERHALT are imported as records; GOFACTORY needs the cleanup plan and the cancels | 0 and 1 |
| 3 | N-31 Push transport, N-30 Go inbox with acks, N-27 Watcher lamp, N-28 System lane card builder, N-33 Rail panel, N-32 Bearings page service, N-34 Tailnet front door | The owner must see the new line before it moves | 2 |
| 4 | N-20 Jenkins as code, N-21 Factory namespace, N-22 Image build, N-23 Suite planner, N-24 Pod run, N-25 Gate status post, N-04 GitHub poll, N-08 Gate check, N-46 Spec book check | A verdict on GitHub before any machine merge; runs beside wave 3 | 3 |
| 5 | N-26 Main verify pipeline, N-10 Main verdict and hold | Main is verified in pods before the merge path goes live | 4 |
| 6 | N-13 Seat layer render, N-14 Workspace provision, N-15 One-shot seat launcher, N-16 Worker run, N-17 Spec-author run, N-18 Validator, N-19 Reviewer run | Seats are built dark; nothing dispatches them until step 6 | 6 (through N-07) |
| 7 | N-12 Stall timer, N-11 Retry and backoff, N-03 Ticket intake and readiness, N-07 Scheduler tick and dispatch, N-09 Merge | The line itself, live under the hold first | 5 and 6 |
| 8 | N-35 Hello page deploy, N-36 Art pipeline, N-37 Panel binding registry, N-38 Map screen, N-39 Machine screen, N-40 Stats screen, N-41 Alerts screen, N-42 Controls screen, N-47 Drive publish, N-48 Tier promotion with screenshot | The command center needs the page, the push stream and the image path; the hello page proves the plumbing before any map code | after 2, beside 4 to 7 |
| 9 | N-51 Exit test, N-52 Phone push bridge | The exit test counts days of the running line; the phone push waits for a day of inbox acks on stable | 11 and 9 |

## 7. Workflows and flows

Eight flows, one sequence diagram each.
Every message is a record put in the store or a call a node makes on a record; nothing is typed into a pane.

### 7.1 Ticket intake to merge

A validated ticket becomes ready, a fresh worker seat writes the change, pods judge it, a fresh reviewer seat judges the diff, and the machine merges.
Each status change is a row of [ticket transitions](shared/contracts.xml#ticket-transitions), and each effect on GitHub carries its [operation key](shared/contracts.xml#operation-keys).

```mermaid
sequenceDiagram
  autonumber
  participant V as N-18 Validator
  participant I as N-03 Intake
  participant L as N-02 Lease
  participant S as N-07 Scheduler
  participant B as N-13 and N-14 Bundle and workspace
  participant R as N-15 Launcher
  participant W as N-16 Worker seat
  participant GH as GitHub
  participant C as N-23 to N-25 CI pods
  participant P as N-04 Poll
  participant G as N-08 Gate check
  participant RV as N-19 Reviewer seat
  participant M as N-09 Merge
  participant X as N-45 Cleanup
  V->>I: ticket 201, files, deps, acceptance observed on main
  I->>I: tick Evaluate, deps done, claims free in the same Commit, no hold
  I->>S: ticket.ready 200
  S->>S: gap equals desired minus live, caps, budgets, address check
  S->>L: GrantDispatch, one Commit: lease reserved with a new token, dispatch 100, ticket ready to in_flight
  S->>B: dispatch body: lease key and token, deadline_at, repo_sha, bundle brief path
  B->>R: seat.bundle and workspace on branch wo/ticket
  R->>L: Lease.Start, reserved to running
  R->>W: claude -p as a pooled seat user in its own transient unit
  loop every heartbeat of the timing table
    R->>L: seat.heartbeat and Lease.Renew with the token
  end
  W-->>R: structured output in result.json, worker.result ready
  R->>I: seat.result 200 with the token, accepted while the lease is current
  I->>GH: N-16 close-out as coq-svc with forge-pr: push wo/ticket, open the PR; the seat never pushes
  I->>I: pr.opened 100 with head sha, ticket pr_open
  I->>C: pr.opened starts the suite plan from the diff
  C->>GH: coq/gate pending, then success or failure on the head sha
  P->>GH: GET main ref, open PRs, statuses, with ETag
  P->>G: forge.snapshot 200
  G->>I: gate.verdict green 201 on the head
  I->>S: phase reviewer, ticket.ready
  S->>L: GrantDispatch for the reviewer phase
  S->>RV: dispatch, bundle, read-only workspace at the head sha
  RV-->>R: review.result with evidence per criterion
  R->>M: review.passed 201 on the head sha, GitHub approve mirrored
  M->>M: both records name the current head, no hold, no unverified merge on main, merge.lock lease
  M->>GH: squash merge with sha equal to the head, outbox row first
  GH-->>M: merge sha, read back
  M->>I: merge 200 with merge_sha, parent_main and base_sha, ticket merged
  Note over M,I: the ticket becomes done only when N-10 verifies main (7.2)
  M->>X: branch, worktree and slot cleanup from the merge record
```

Depth: [N-03](nodes/N-03/spec.xml#mechanism), [N-07](nodes/N-07/spec.xml#mechanism), [N-08](nodes/N-08/spec.xml#mechanism), [N-09](nodes/N-09/spec.xml#mechanism), [N-16](nodes/N-16/spec.xml#mechanism), [N-19](nodes/N-19/spec.xml#mechanism).

### 7.2 Gate verdict, main verify and hold

Every merge is verified on main in pods; a red main holds every merge but the fix, and the owner hears only after three fixes fail.
At most one merge on main is unverified at a time, so a newer merge never starves the verification of an older one ([ticket transitions](shared/contracts.xml#ticket-transitions)).

```mermaid
sequenceDiagram
  autonumber
  participant M as N-09 Merge
  participant MV as N-26 Main verify
  participant J as Jenkins coq-gate pods
  participant ST as N-25 Status post
  participant GH as GitHub
  participant VH as N-10 Verdict and hold
  participant I as N-03 Intake
  participant SA as N-17 and N-18 Fix cut
  participant CB as N-28 Card builder
  participant O as Owner
  M->>MV: merge 200, merge_sha, parent_main, merge_seq k
  M->>M: awaiting-verify, no next merge until the verdict
  MV->>J: main.plan with every suite of suites.json full
  J-->>ST: pod.run per unit, infrastructure retried by the ladder
  ST->>GH: coq/gate on the main sha
  ST->>MV: gate.run with the result set
  MV->>VH: main.gate.status with the range of merges
  alt success
    VH->>VH: verified 201, ticket merged to done
    VH->>M: awaiting-verify cleared, merge.hold.lifted when one stood
  else failure, or error once N-25 has spent its retry budget
    VH->>VH: rejected 422 with the red suites
    VH->>M: merge.hold 423, no merge but the fix
    loop fix_attempt 1 to 3
      VH->>I: ticket.request fix-for-hold with hold_id
      I->>SA: cut request at phase spec, spec-author cuts, validator admits
      SA->>M: fix PR gated and reviewed, merged by the hold exception
      M->>MV: merge 200 with fix_for_hold_id
    end
    VH->>CB: fix_attempt 4, rejected is owner-acts
    CB->>O: one card with the sha, the suites, the three fixes and a recommendation
  end
  Note over M,CB: a hold standing past 14400 s writes merge.hold.aged, folded into the same card
```

Depth: [N-10](nodes/N-10/spec.xml#mechanism), [N-26](nodes/N-26/spec.xml#mechanism), [N-25](nodes/N-25/spec.xml#mechanism).

### 7.3 Seat launch, run, stall timer and retry

A seat is fenced before it is killed and killed before it is retried.
A late terminal report carrying the revoked token is accepted once per run with `fenced: true`, and N-11 treats it as an echo, never as a new failure ([terminal report](shared/contracts.xml#terminal-report), [kill authority](shared/contracts.xml#kill-authority)).

```mermaid
sequenceDiagram
  autonumber
  participant S as N-07 Scheduler
  participant B as N-13 Seat layer
  participant WS as N-14 Workspace
  participant R as N-15 Launcher
  participant CL as claude -p process group
  participant DB as N-01 Store
  participant L as N-02 Lease
  participant ST as N-12 Stall timer
  participant RT as N-11 Retry
  participant CB as N-28 Card builder
  S->>B: dispatch, ticket, phase, attempt n, deadline_at, lease token
  B->>DB: seat.bundle, settings.json, mcp.json, brief.md, output.schema.json, bundle_hash
  S->>WS: dispatch
  WS->>DB: the ticket holds its claims or 412 claim_missing, slot by CAS, worktree from the mirror, workspace 100
  R->>R: preflight, bundle hash, base sha, lease reserved and current
  R->>L: Lease.Start, reserved to running, run state spawning
  R->>CL: systemd-run unit coq-seat-run_id as a seat user, claude -p with dontAsk, max-turns, max-budget-usd, json-schema
  loop every heartbeat of the timing table
    R->>DB: seat.heartbeat, progress_at from the transcript mtime
    R->>L: Lease.Renew with key and token
  end
  loop every stall.tick_seconds, 15 s
    ST->>DB: read leases, heartbeats, dispatches
    ST->>ST: judge progress age, launcher age, deadline, first heartbeat grace
  end
  alt run ends inside its bounds
    CL-->>R: result.json.partial validated, renamed result.json, fsync, sha256
    R->>DB: seat.result 200 done, or 423 blocked with terminal_reason
  else stalled
    ST->>L: Revoke by CAS on the lease version, state revoked
    ST->>DB: entity kill:run_id
    R->>CL: systemctl stop the unit, kill grace of the timing table
    R->>DB: seat.result 423 killed_by_record with the revoked token, accepted once, fenced true
    ST->>DB: stall 500 keyed by lease key and token
  end
  RT->>DB: CAS handled_by on the failure record, a fenced echo is not charged
  alt the retry owner charges an attempt and the budget allows it
    RT->>L: attempt n+1 with not_before from the retry-owner backoff
    S->>L: the next tick's GrantDispatch issues a new token to a fresh seat
  else attempts or budget spent
    RT->>CB: dead 500, exactly one card
  end
```

Depth: [N-15](nodes/N-15/spec.xml#mechanism), [N-12](nodes/N-12/spec.xml#mechanism), [N-11](nodes/N-11/spec.xml#mechanism), [seat contract](shared/seat-contract.xml#launch-flags).

### 7.4 Owner card and answer with acks

The system builds the card from a record; a card never posts unwatched; the owner's answer is persisted before it is acknowledged.
The page accepts the answer only from an authenticated same-origin request ([web security](nodes/N-32/spec.xml#web-security)), and the phone push path is [push delivery](nodes/N-52/spec.xml#push-delivery).

```mermaid
sequenceDiagram
  autonumber
  participant SRC as N-11 Retry
  participant CB as N-28 Card builder
  participant WL as N-27 Watcher lamp
  participant DB as N-01 Store
  participant PU as N-31 Push
  participant PG as N-32 Page service
  participant FD as N-34 Front door
  participant O as Owner
  participant PB as N-52 Phone push
  participant IN as N-29 Intake
  participant TI as N-03 Intake
  SRC->>DB: dead 500, acts owner in the code table
  CB->>DB: tick query, owner-acts records with no card
  CB->>DB: read watcher.alive for coq-stable
  alt lamp alive, beat under 15 s
    CB->>DB: card 300, C-number, about, decide, options, recommendation; an owner-only card has no default and no deadline
  else lamp not alive
    CB->>DB: card.held 423 with backoff, card.unwatched 500 at attempt 3
  end
  DB->>PU: record.committed seq
  PU->>PG: SSE frame, the card joins the deck
  PG->>O: card drawn, card.shown 200 recorded
  PU->>PB: card frame, dark until cut-over step 9
  PB->>O: ntfy publish; ntfy.sh forwards only a poll request that wakes the locked iPhone
  PB->>DB: push.receipt when the provider accepted, push.observed when the phone fetched the body
  O->>FD: taps an option on the phone over Tailscale
  FD->>PG: bytes piped to loopback unchanged
  PG->>IN: Intake.Answer, card, pick, words, source page
  IN->>DB: owner.answer 100 persisted first
  IN->>DB: ruling 200, create only, one per card
  IN-->>PG: receipt with the ruling id
  PG-->>O: answer receipt on the card
  WL->>DB: Tail owner.answer from its cursor, epoch and seq
  WL->>IN: Intake.Answer again, idempotent no-op, watermark advances
  CB->>DB: card.done 200 naming the ruling
  TI->>DB: effect ticket.unblock, re-entry with the attempt reset
```

Depth: [N-28](nodes/N-28/spec.xml#mechanism), [N-27](nodes/N-27/spec.xml#mechanism), [N-29](nodes/N-29/spec.xml#mechanism), [N-31](nodes/N-31/spec.xml#mechanism), [N-52](nodes/N-52/spec.xml#mechanism).

### 7.5 Owner message through the Go inbox

Every message gets four receipts (accepted, routed, consumed, answered), or a fifth (stale) that says the system knows it is late.

```mermaid
sequenceDiagram
  autonumber
  participant O as Owner
  participant PG as N-32 Page service
  participant IN as N-30 Inbox
  participant DB as N-01 Store
  participant CN as Consumer node N-29, N-03 or N-06
  participant DG as Digest builder in N-30
  participant AR as Architect session, owner host CLI
  participant PU as N-31 Push
  participant ST as Stall clock every 10 s
  O->>PG: message text, POST /message
  PG->>IN: Inbox.Message
  IN->>DB: owner.message and ack accepted 100 in one transaction
  IN-->>PG: ack accepted
  PG-->>O: first receipt mark
  IN->>IN: rule table R01 to R99, top to bottom
  IN->>DB: routed.message 300 and ack routed
  Note over IN: an owner word counts only as the whole trimmed message of an owner principal
  alt R01 USERHALT, R02 USERGO, R03 GOFACTORY, R04 card reply
    IN->>CN: N-29 within 5 s
  else R05 cut or ticket
    IN->>CN: N-03 ticket.request within 60 s
  else R08 a PR or ticket id, R99 anything else
    IN->>DG: digest.item 100, ack consumed at once
    AR->>DG: coq inbox digest, read in one batch
    AR->>IN: Inbox.Reply, comms checker passes
  end
  CN->>DB: ack consumed with the consumer's record
  IN->>DB: reply and ack answered 200
  DB->>PU: frames
  PU->>PG: reply bubble and the answered mark
  opt no reply within the lane sla of 1800 s
    DG->>IN: templated reply, ack answered with reason digest-timeout
  end
  opt a node consumer silent past its sla
    ST->>DB: ack stale 500 and message.stale on the Alerts screen
  end
```

Depth: [N-30](nodes/N-30/spec.xml#mechanism), [lanes](shared/seat-contract.xml#lanes).

### 7.6 Spec cut by AI and validator

An LLM cuts tickets as data; code admits them only after their acceptance commands ran on main.

```mermaid
sequenceDiagram
  autonumber
  participant SRC as Source N-10, N-30 R05, N-49 LAND
  participant I as N-03 Intake
  participant L as N-02 Lease
  participant S as N-07 Scheduler
  participant R as N-13 to N-15 Seat bring-up
  participant SA as N-17 Spec-author seat
  participant V as N-18 Validator
  participant MR as Git mirror at origin/main
  participant PM as Podman on the host
  participant RT as N-11 Retry
  SRC->>I: ticket.request 100
  I->>I: admit as cut request CR-id at phase spec, no files
  I->>L: claimable spec lease
  L->>S: lease.granted, CR-id, spec, attempt 1
  S->>R: dispatch role spec-author, brief target the design anchor
  R->>SA: claude -p, read-only workspace, Write and Edit denied
  SA-->>R: structured output, tickets as data
  R->>V: ticket-set.draft 100
  V->>V: schema, files declared and disjoint, records registered, deps acyclic, size, duplicate
  V->>MR: the anchor volume is not newer than the draft repo_sha
  V->>PM: run every acceptance command on main, record the observed exit
  alt every check passes
    V->>I: mint ids, ticket 201 each, ticket-set.accepted 201, all or none
    I->>I: tickets enter cut, then waiting or ready
  else a check fails
    V->>RT: validator.refused 422 with the failing check and command
    RT->>L: attempt n+1, the verdict rides in the next brief
  end
```

Depth: [N-17](nodes/N-17/spec.xml#mechanism), [N-18](nodes/N-18/spec.xml#mechanism), [N-03 input](nodes/N-03/spec.xml#input).

### 7.7 Prompt-parked detection and the model-limit auto-answer

A long-lived seat parked on a prompt is seen within one minute; a model-limit prompt is answered by the role's ruled model and never by spending extra credits.

```mermaid
sequenceDiagram
  autonumber
  participant AS as Long-lived seat, architect pane
  participant HK as Harness Notification hook
  participant HD as herdr status event
  participant ST as N-12 Stall tick, 15 s
  participant PR as scheduler/config/prompt-rules.json
  participant RF as roles/architect.json
  participant CT as N-42 Controls
  participant CB as N-28 Card builder
  participant O as Owner
  AS->>HK: blocking prompt, model or usage limit choice
  HK->>HD: status blocked with the notification message
  HD->>ST: pane.agent_status_changed blocked, the clock starts
  ST->>ST: blocked and transcript older than 30 s
  ST->>PR: match the message in order
  alt model-limit and the role has a ruled model
    ST->>RF: read model.claude, claude-opus-5-5 today
    ST->>CT: prompt.parked 423, action answer, answer_model
    CT->>AS: switch model by control.action, the harness model command
    alt status leaves blocked
      ST->>ST: prompt.cleared 200 closes the episode
    else still blocked after 900 s
      ST->>CB: falls through to a card under the same key
    end
  else no standing answer, only extra-credit options, or unmatched
    ST->>CB: prompt.parked 423, action card
    CB->>O: one card, re-posted every 900 s while parked
  end
  Note over AS,O: prompt to record within 45 s, card within 60 s, no keystroke, no pane read
```

Depth: [N-12 prompt-parked](nodes/N-12/spec.xml#prompt-parked), [failure case](shared/failure-cases.xml#prompt-parked).

### 7.8 Bootstrap and cut-over, GOFACTORY to USERGO

The one order from the approved design to the old line retired; each step starts on its trigger record and ends on its proof record, and the bootstrap state moves one step at a time on those proofs ([bootstrap](shared/cut-over.xml#bootstrap)).
Under the hold, merges follow the [bootstrap merge path](shared/cut-over.xml#bootstrap-merge): by default N-09 merges only pull requests of the current bootstrap step with a green gate and review.passed on the same head, and the owner's break glass merges the pull requests that come before the first gate; the owner's pick is still open ([section 15](#15-decisions-for-the-owner)).

```mermaid
sequenceDiagram
  autonumber
  participant O as Owner
  participant IN as N-29 Intake
  participant N50 as N-50 Cut-over records
  participant N49 as N-49 Unlanded cleanup
  participant N45 as N-45 Cleanup
  participant GH as GitHub
  participant RS as Rebuild seats under build mode
  participant PG as N-32 coq-cutover unit
  participant CI as N-20 to N-26 CI as code
  participant SC as N-07 to N-12 line
  participant EX as N-51 Exit test
  Note over O,EX: B0 design approved; B1 foundation built dark on a test state root, no live unit, no forge or Jenkins effect
  O->>IN: GOFACTORY typed by the owner into the owner CLI after the N-49 dry-run listing: B2
  IN->>IN: step 0, the live store is created held, every flag false, the rulings C34 to C58 imported with no effects
  IN->>N50: gofactory effect
  N50->>N50: D09 and D14 rulings present, cancel set equals 14
  N50->>GH: close PR 35 with the comment
  N50->>N45: 14 cancel 200 and pr.close 200
  IN->>N49: gofactory effect
  N49->>N49: replan, the hash equals the listing on the card
  N49->>N45: step 1 backups, then steps 2 to 7 in order
  par step 2, owner surface
    RS->>PG: push, intake, inbox, watcher, cards, rail go live
    PG->>PG: coq-cutover@coq-stable swaps the page, stops wait.mjs and server.mjs
  and step 3, CI as code
    RS->>CI: job.registered, namespace.ready, images pinned, coq/gate required
  end
  CI->>CI: step 4, main verify live, verify-main.sh retired
  RS->>SC: step 5, stall in shadow for 24 h then live, retry on
  RS->>SC: step 6, sched and merge on under the hold
  Note over RS,SC: step 7, records leave git, events out of the repository
  Note over RS,SC: B3 to B6 advance only on the proofs of steps 3, 4 and 5; merges by the bootstrap merge path
  SC->>O: B7 ready, bootstrap.ready names the proofs of steps 2, 6 and 7, one owner-only card, no default, no deadline
  O->>IN: USERGO at B7, refused 412 not-ready before B7
  IN->>SC: B8 live, flag hold cleared, first dispatch, first machine merge
  SC->>SC: step 8, merge.sh and the old roles retired
  EX->>O: step 11, daily exit test, the product freeze lifts on the first pass
```

Depth: [cut-over order](shared/cut-over.xml#order), [N-49 order](nodes/N-49/spec.xml#order), [N-50](nodes/N-50/spec.xml#mechanism).

## 8. File format and data shapes

### 8.1 State root

All runtime data lives outside the repository, resolved by [`bin/state-root.sh`](../../bin/state-root.sh) (`COQ_STATE` and `COQ_CACHE` win when set).
The state root belongs to the service user `coq-svc` alone, mode 0700; no seat user can read it ([principals](shared/authority.xml#principals)):

```text
$HOME/.local/state/coq/coq-jev-herdr-plugin/      COQ_STATE, $HOME of coq-svc
  store/coq.db, coq.db-wal, coq.db-shm             the one store (N-01)
  backup/store/YYYY/MM/*.zst                       snapshots, classes tick, daily, monthly, manual (N-05)
  config/service.env                               tokens and keys, mode 0600 (N-04, N-06)
  run/service.lock, service.pid, scheduler.heartbeat
  logs/<node area>/YYYY/MM/*.jsonl                 service, scheduler, gate, merge, verify, retry, stall, cleanup, publish, promote
  briefs/YYYY/MM/<at>-WO-<id>-<phase>-<n>.md       rendered briefs (N-07, N-13)
  seats/bundles/<run_id>/                          settings.json, mcp.json, brief.md, output.schema.json
  seats/runs/<run_id>/                             started.json, result.json, stderr.log, provision.log
  validator/<set_id>/                              validate.log and acceptance outputs
  ci/mirror/repo.git, ci/plan/, ci/logs/gate/, ci/gate/, ci/verify/, ci/image/
  bearings/<page>/server.json, files/, screenshots/, front-door.json
  map/art/, map/dist/<sha>/, map/deploy/, map/registry/, map/screenshots/
  svc/codes/table-<hash>.json                      the loaded code table (N-43)
  cleanup/plans/*.json                             cleanup dry-run listings (N-45)
  publish/<sha>/, publish/manifests/               Drive exports (N-47)
  secrets/rclone.conf, owner/push/token            mode 0600
  tiers/<tier>/src@<sha>, screenshots/<tier>/<sha>/
  unlanded/plan-*.json, backup/unlanded/, cutover/cancel-set-<sha>.json, exittest/<day>.json
  tickets/export/WO-*.md                           read-only exports for humans
$HOME/.cache/coq/coq-jev-herdr-plugin/             COQ_CACHE, safe to delete
  git/<slug>.git                                   the bare mirror (N-14)
  ws/<slot>/                                       workspace slots
  ci/image/<name>/, cleanup/registry-<sha>.json
/run/coq/store.sock                                the store socket, 0660, group coq-store; seats get none
$HOME/.config/systemd/user/coq-service.service, coq-bearings@.service, coq-watcher@.service, coq-front-door@.service, coq-cutover@.service
```

### 8.2 State store tables

One SQLite file in WAL mode, opened by the Go service alone; every table has one owning node and a forward-only migration ([state store](shared/state-store.xml#records)).

| Table | Owner | Mode | Holds |
| --- | --- | --- | --- |
| `records` | N-01 | append-only | Every record of every kind; `seq` strictly increasing but not gapless, and every record carries the store epoch ([epoch](shared/contracts.xml#epoch-cursor)); indexes (kind, seq), (ticket, seq), (code, seq) |
| `entities` | N-01 | compare-and-swap | Current state by key (flags, `store:epoch`, `bootstrap:state`, `kill:<run_id>`, `run:<run_id>`); a write is also a record unless the kind is registered entity-only ([entity-only](shared/contracts.xml#entity-only)) |
| `idempotency` | N-01 | append-only | One row per operation key with kind, node and request hash: the same hash replays 200, another hash is 409 idempotency_mismatch ([operation keys](shared/contracts.xml#operation-keys)) |
| `effects` | N-01 | compare-and-swap | The outbox: one row per external effect, written in the Commit that decided it ([outbox](shared/contracts.xml#outbox)) |
| `principals` | N-01 | compare-and-swap | Socket peer uid to node, role and permitted kinds ([principals](shared/authority.xml#principals)) |
| `code_table` | N-43 | append-only | The status code map loaded from `shared/status-codes.xml` by hash |
| `leases` | N-02 | compare-and-swap | One row per key: class, state, integer token, holder never empty, generation, expiry ([lease machine](shared/contracts.xml#lease-machine)) |
| `heartbeats` | N-15 | upsert | Newest heartbeat per run: pid, progress_at, transcript_bytes, adopted |
| `attempts` | N-11 | append-only | One row per charged attempt of a ticket phase with its backoff ([retry owner](shared/contracts.xml#retry-owner)) |
| `slots` | N-14 | compare-and-swap | Workspace slots 1 to `workspace_slots` |
| `tickets` | N-03 | compare-and-swap | The whole ticket; a status column and a separate phase column, changed only by a row of [ticket transitions](shared/contracts.xml#ticket-transitions) |
| `claims` | N-03 | append-only | The one claims authority: overlap is checked inside the Commit, and N-14 only verifies the ticket holds its claims ([claims](shared/contracts.xml#claims)) |
| `ticket_sets`, `id_mint` | N-18 | compare-and-swap, append-only | Drafts and accepted sets; reserved ids so a crashed mint resumes with the same ids |
| `flags` | N-44 | compare-and-swap | build-mode, hold, freeze, each with scope, expiry, card and ruling |
| `forge_history` | N-04 | append-only | GitHub snapshots on hash change, 30 days |
| `backups` | N-05 | append-only | Snapshot path, checksums, class (tick, daily, monthly, manual), epoch, verified ([restore](shared/contracts.xml#restore)) |
| `plans`, `suite_budget` | N-23, N-06 | compare-and-swap, upsert | Suite and main plans with Jenkins build numbers; per-suite time budgets |
| `cards`, `rulings`, `messages`, `acks`, `replies`, `routed_messages` | N-28, N-29, N-30 | mixed | The owner surface; one ruling per card id |
| `watcher_alive`, `page_state`, `front_door`, `cutover` | N-27, N-32, N-34 | compare-and-swap | Unit liveness and the page's own staleness |
| `plan_steps`, `plan_sides`, `ledger_rows`, `push_receipts` | N-33, N-52 | mixed | The rail panel and phone receipts |
| `cleanup_runs`, `dispositions`, `publish_cursor`, `promotions`, `exit_verdicts` | N-45, N-49, N-47, N-48, N-51 | mixed | Governance and cut-over |
| `deploy_records`, `sprite_sheets`, `binding_records`, `frame_reports`, `selections`, `counters_frames`, `alert_acks`, `control_actions`, `break_glass_tokens` | G6 nodes | mixed | The command center |
| `counters` | N-40 | view | Windows 1 h, 6 h, 24 h, 7 d: tickets per stage, bring-up median and p95, stalls, cost |

### 8.3 Record examples

Every record carries the envelope `id` (UTC stamp, code, five characters), `at` (UTC), `kind`, `code` and `node`, plus `seq` and the store `epoch` assigned by the store at commit ([envelope](shared/state-store.xml#envelope), [epoch](shared/contracts.xml#epoch-cursor), [N-01 schema](nodes/N-01/record.schema.json)).
The operation key and the lease fence ride on the `Commit` request, not in the record ([store transaction](shared/contracts.xml#batch), [operation keys](shared/contracts.xml#operation-keys)).
The examples below are one ticket's path as committed records; each one validates against its node's `record.schema.json`, and `bin/check-examples.py` (C22) checks that.

The lease and the dispatch are written in one `Commit`, N-07's GrantDispatch, under operation key `N-07/dispatch/WO-20261014-ab12:worker:1@184/r1`, together with the ticket's move from ready to in_flight ([lease machine](shared/contracts.xml#lease-machine)).
The lease is reserved, its holder is the dispatch id, and it expires after the start grace unless the launcher starts it ([N-02 schema](nodes/N-02/record.schema.json)):

```json
{
  "id": "20261014T063000Z-201-k3v9q",
  "at": "2026-10-14T06:30:00Z",
  "kind": "lease.granted",
  "code": 201,
  "node": "N-02",
  "seq": 5101,
  "epoch": 1,
  "key": "WO-20261014-ab12:worker:1",
  "class": "seat",
  "state": "reserved",
  "ticket": "WO-20261014-ab12",
  "phase": "worker",
  "role": "worker",
  "attempt": 1,
  "holder": "d-20261014063000-p2m7dq",
  "token": 184,
  "generation": 1,
  "granted_at": "2026-10-14T06:30:00Z",
  "expires_at": "2026-10-14T06:32:00Z",
  "version": 1
}
```

The dispatch in the same `Commit`: the envelope plus the one dispatch body every consumer reads ([dispatch](shared/contracts.xml#dispatch), [`dispatch_body`](shared/contracts.schema.json), [N-07 schema](nodes/N-07/record.schema.json)):

```json
{
  "id": "20261014T063000Z-100-p2m7d",
  "at": "2026-10-14T06:30:00Z",
  "kind": "dispatch",
  "code": 100,
  "node": "N-07",
  "seq": 5102,
  "epoch": 1,
  "dispatch_id": "d-20261014063000-p2m7dq",
  "ticket": "WO-20261014-ab12",
  "phase": "worker",
  "role": "worker",
  "attempt": 1,
  "lane": "build",
  "lease": {
    "key": "WO-20261014-ab12:worker:1",
    "token": 184,
    "generation": 1
  },
  "deadline_at": "2026-10-14T08:00:00Z",
  "repo": {
    "slug": "jkkelley/coq-jev-herdr-plugin",
    "origin": "https://github.com/jkkelley/coq-jev-herdr-plugin.git"
  },
  "repo_sha": "4f7f44c0d2a9e1b6c3f8a5d7e9b2c4a6f1d3e5b7",
  "build_mode": {
    "on": false,
    "scope": "rebuild",
    "version": 3
  },
  "target": {
    "type": "wo",
    "ticket": "WO-20261014-ab12"
  },
  "session": {
    "mode": "new"
  },
  "brief_path": "bundle/d-20261014063000-p2m7dq/brief.md"
}
```

The seat result the launcher parses from the harness envelope, committed under `N-15/seat.result/d-20261014063000-p2m7dq/r1` while the lease token is current ([N-15 schema](nodes/N-15/record.schema.json)):

```json
{
  "id": "20261014T064212Z-200-x81fe",
  "at": "2026-10-14T06:42:12Z",
  "kind": "seat.result",
  "code": 200,
  "node": "N-15",
  "seq": 5188,
  "epoch": 1,
  "run_id": "d-20261014063000-p2m7dq",
  "dispatch_id": "d-20261014063000-p2m7dq",
  "ticket": "WO-20261014-ab12",
  "role": "worker",
  "phase": "worker",
  "attempt": 1,
  "lease": {
    "key": "WO-20261014-ab12:worker:1",
    "token": 184
  },
  "outcome": "done",
  "terminal_reason": "success",
  "exit_code": 0,
  "cost_usd": 1.84,
  "turns": 37,
  "session_id": "5b0e2c1a-6d7f-4f3e-9a51-0c2d8e4b7a10",
  "model": "claude-sonnet-5-5",
  "harness": {
    "version": "2.1.0",
    "sha256": "9d3f1c0b7a2e4d6f8a1b3c5d7e9f0a2b4c6d8e0f1a3b5c7d9e1f2a4b6c8d0e2f"
  },
  "started_at": "2026-10-14T06:30:07Z",
  "finished_at": "2026-10-14T06:42:12Z",
  "duration_seconds": 725,
  "permission_denials": {
    "count": 0,
    "first": []
  },
  "denied_line_ops": {
    "count": 0,
    "commands": []
  },
  "structured": {
    "status": "ready",
    "head_sha": "3f9c2e7a1b04d6e58c9f20b7e4a1d3c6f8b05e92"
  },
  "result_path": "$COQ_STATE/seats/runs/d-20261014063000-p2m7dq/result.json",
  "result_sha256": "4a7c1e9b3d5f2a8c6e0b4d2f9a1c3e5b7d9f0a2c4e6b8d1f3a5c7e9b2d4f6a8c",
  "stderr_path": "$COQ_STATE/seats/runs/d-20261014063000-p2m7dq/stderr.log"
}
```

The gate verdict on that head, keyed by the head and the status time it judged ([N-08 schema](nodes/N-08/record.schema.json)):

```json
{
  "id": "20261014T065130Z-201-q7c4n",
  "at": "2026-10-14T06:51:30Z",
  "kind": "gate.verdict",
  "code": 201,
  "node": "N-08",
  "seq": 5240,
  "epoch": 1,
  "idempotency_key": "N-08/gate.verdict/201@3f9c2e7a1b04d6e58c9f20b7e4a1d3c6f8b05e92@2026-10-14T06:51:02Z/r1",
  "pr": 201,
  "ticket": "WO-20261014-ab12",
  "head_sha": "3f9c2e7a1b04d6e58c9f20b7e4a1d3c6f8b05e92",
  "verdict": "green",
  "reason": "status",
  "gate_url": "http://jenkins.jenkins.svc.cluster.local:8080/job/coq-gate/412/",
  "main_sha": "4f7f44c0d2a9e1b6c3f8a5d7e9b2c4a6f1d3e5b7",
  "status_updated_at": "2026-10-14T06:51:02Z",
  "snapshot_seq": 5120
}
```

The merge, read back from GitHub with the main sha it landed on (`parent_main`) and the base the pull request had when the merge was decided (`base_sha`); N-26 and N-47 read the same record ([N-09 schema](nodes/N-09/record.schema.json)):

```json
{
  "id": "20261014T070410Z-200-m5a0r",
  "at": "2026-10-14T07:04:10Z",
  "kind": "merge",
  "code": 200,
  "node": "N-09",
  "seq": 5301,
  "epoch": 1,
  "idempotency_key": "N-09/merge/201@3f9c2e7a1b04d6e58c9f20b7e4a1d3c6f8b05e92/r1",
  "pr": 201,
  "ticket": "WO-20261014-ab12",
  "head_sha": "3f9c2e7a1b04d6e58c9f20b7e4a1d3c6f8b05e92",
  "base_sha": "4f7f44c0d2a9e1b6c3f8a5d7e9b2c4a6f1d3e5b7",
  "merge_sha": "a71d0b4e2c9f8a6d5b3e1c7f9a2d4b6e8c0f1a3d",
  "parent_main": "4f7f44c0d2a9e1b6c3f8a5d7e9b2c4a6f1d3e5b7",
  "merge_seq": 93,
  "branch": "wo/WO-20261014-ab12",
  "paths": [
    "scheduler/internal/lease/lease.go",
    "scheduler/internal/lease/lease_test.go"
  ],
  "gate_verdict_id": "20261014T065130Z-201-q7c4n",
  "review_record_id": "20261014T070122Z-201-v6t2b"
}
```

A card about a dead ticket ([N-28 schema](nodes/N-28/record.schema.json)) and the owner's ruling on it ([N-29 schema](nodes/N-29/record.schema.json)):

```json
{
  "id": "20261014T081500Z-300-c9k2w",
  "at": "2026-10-14T08:15:00Z",
  "kind": "card",
  "code": 300,
  "node": "N-28",
  "card": "C-60",
  "tier": "stable",
  "cause": "20261014T081455Z-500-d4t8h",
  "about": "Lease service - failed three attempts",
  "decide": "Re-cut the ticket smaller, or cancel it?",
  "options": [
    {
      "label": "Re-cut smaller",
      "then": "spec-author cuts a smaller ticket"
    },
    {
      "label": "Cancel",
      "then": "ticket closed, files released"
    }
  ],
  "rec": 0,
  "ticket": {
    "id": "WO-20261014-ab12",
    "title": "Lease service claim, renew, release and sweep"
  },
  "owner_only": false,
  "deadline": "2026-10-15T08:15:00Z",
  "default": 0,
  "watcher": 7,
  "posted_at": "2026-10-14T08:15:00Z",
  "idempotency_key": "N-28/card.post/20261014T081455Z-500-d4t8h/r1",
  "seq": 5402,
  "epoch": 1
}
```

```json
{
  "id": "20261014T082233Z-200-r3v6y",
  "at": "2026-10-14T08:22:33Z",
  "kind": "ruling",
  "code": 200,
  "node": "N-29",
  "card": "C-60",
  "cause": "20261014T081455Z-500-d4t8h",
  "pick": 0,
  "choice": "Re-cut smaller",
  "words": "",
  "source": "page",
  "by": "owner",
  "principal_role": "owner",
  "answer": "20261014T082231Z-100-k2p4z",
  "effects": [
    {
      "kind": "ticket.unblock",
      "ticket": "WO-20261014-ab12"
    }
  ],
  "idempotency_key": "N-29/ruling/C-60/r1",
  "seq": 5417,
  "epoch": 1
}
```

One acknowledgement of an owner message, an upsert keyed by the message whose state only moves forward ([N-30 schema](nodes/N-30/record.schema.json)):

```json
{
  "id": "20261014T090102Z-100-a1s8k",
  "at": "2026-10-14T09:01:02Z",
  "kind": "ack",
  "code": 100,
  "node": "N-30",
  "message": "20261014T090101Z-100-h2k9q",
  "state": "routed",
  "by": "inbox",
  "ref": "20261014T090102Z-300-l0r5u",
  "version": 2,
  "seq": 5502,
  "epoch": 1
}
```

### 8.4 Runtime state machines

The DAG is acyclic on purpose; the runtime is not, and these three diagrams show its loops.
Each is a picture of a table that lives in one place, and the table wins wherever they differ: [ticket transitions](shared/contracts.xml#ticket-transitions), [lease machine](shared/contracts.xml#lease-machine) and [bootstrap](shared/cut-over.xml#bootstrap).
What bounds each loop is the [retry owner](shared/contracts.xml#retry-owner) and the [budgets](shared/retry-budget.xml#budgets), never the drawing.

A ticket: status and phase are separate columns, and a transition not in the table is refused 412 `ticket.transition_refused`.

```mermaid
stateDiagram-v2
  [*] --> cut: admitted by N-03
  cut --> refused: ticket.refused
  cut --> waiting: ticket.waiting
  cut --> ready: ticket.ready, claims taken
  waiting --> ready: ticket.ready, claims taken
  ready --> waiting: ticket.waiting, claims released
  ready --> in_flight: dispatch, N-07 GrantDispatch
  in_flight --> ready: free regrant, no attempt charged
  in_flight --> retry_wait: attempt n+1 charged by N-11
  retry_wait --> ready: not_before passed
  in_flight --> pr_open: pr.opened
  pr_open --> in_flight: dispatch of the reviewer or gate phase
  pr_open --> retry_wait: review.changes, gate red or merge.conflict
  pr_open --> merged: merge by N-09
  merged --> done: verified main contains the merge
  in_flight --> dead: attempts spent
  pr_open --> dead: attempts spent
  waiting --> dead: ticket.stale
  dead --> waiting: owner ruling ticket.unblock, attempt reset
  waiting --> cancelled
  ready --> cancelled
  in_flight --> cancelled
  retry_wait --> cancelled
  pr_open --> cancelled
  done --> [*]
  cancelled --> [*]
  refused --> [*]
```

A lease: one row per key with an integer token that only grows; a stale or non-current token is refused 412 ([fencing](shared/contracts.xml#fencing)).

```mermaid
stateDiagram-v2
  [*] --> reserved: GrantDispatch by N-07, new token, holder the dispatch id
  reserved --> reserved: Renew
  reserved --> running: Start by N-15
  running --> running: Renew with the token
  reserved --> released: Release
  running --> released: Release
  reserved --> expired: Sweep after the start grace, no attempt charged
  running --> expired: Sweep after the ttl, kill and charge per retry owner
  reserved --> revoked: Revoke by N-12, CAS on the version
  running --> revoked: Revoke by N-12, kill entity in the same Commit
  released --> reserved: free regrant only, new token
  expired --> reserved: free regrant only, new token
  released --> [*]
  expired --> [*]
  revoked --> [*]
  note right of revoked
    one late terminal report with the
    revoked token is accepted once,
    fenced, and is an echo to N-11
  end note
```

The line's bootstrap: one entity, moved forward one state at a time on proof records; only the two owner words are steps an agent cannot cause.

```mermaid
stateDiagram-v2
  [*] --> B0: this book merged, check.sh green
  B0 --> B1: foundation tickets cut
  B1 --> B2: GOFACTORY, with the foundation proven
  B2 --> B3: proofs of steps 0 and 1
  B3 --> B4: proof of step 3
  B4 --> B5: proof of step 4
  B5 --> B6: proof of step 5
  B6 --> B7: proofs of steps 2, 6 and 7, bootstrap.ready
  B7 --> B8: USERGO
  B8 --> [*]
  note right of B6
    USERGO in B0 to B6 is refused
    412 not-ready, naming the
    missing proofs; the hold
    stands from B2 to B7
  end note
```

A restore is the one way back: it starts a new store epoch held with every flag off, expires every lease, moves the token counter past every token issued, reconciles GitHub, Jenkins and merges, and only an owner ruling releases the hold ([restore](shared/contracts.xml#restore)).

### 8.5 Config keys that matter most

Every value is a key in `STATE/config/service.env` or the config table, applied by `Reload` without a restart ([config keys](shared/state-store.xml#config-keys)).
The lease, heartbeat, grace, stall, deadline, tick, cap and budget defaults are one table, [timing](shared/contracts.xml#timing), and the CI sizes are [CI capacity](shared/ci-capacity.xml#model); this section names the keys and leaves the numbers there.

| Key | Default | Owner |
| --- | --- | --- |
| `lease.ttl_seconds`, `lease.heartbeat_seconds`, `start.grace_seconds`, `kill.grace_seconds` | [timing](shared/contracts.xml#timing) | N-02, N-12, N-15 |
| tick intervals | scheduler 5 s, poll 30 s, stall 15 s, health 15 s, backup 6 h, daily 00:05Z | N-06 |
| `forge.poll_seconds`, `forge.calls_per_poll_max` | 30 s, 60 (halves under 1000 remaining) | N-04 |
| `gate.absent_seconds`, `gate.pending_seconds` | derived from the inner bounds ([deadlines](shared/retry-budget.xml#deadlines)) | N-08 |
| `merge.hold_age_alert_seconds` | 14400 s | N-09 |
| `stall.seconds.<role>`, `run.deadline_seconds.<role>` | [timing](shared/contracts.xml#timing) | N-12 |
| `stall.prompt_park_seconds`, `stall.prompt_recard_seconds` | 30 s, 900 s | N-12 |
| retry backoff and attempts | [retry owner](shared/contracts.xml#retry-owner) | N-11 |
| `caps.max_seats`, `workspace_slots`, `budget.*` | [timing](shared/contracts.xml#timing), enforced at GrantDispatch ([budgets](shared/retry-budget.xml#budgets)) | N-07 |
| gate runs in flight and pod sizes | [CI capacity](shared/ci-capacity.xml#model) | N-07, N-22, N-24 |
| `flags.build_mode.max_duration` | P7D | N-44 |
| `tiers.stable.port`, `tiers.uat.port_range`, `tiers.dev.port_range` | 44900, 44910 to 44919, 44920 to 44939 | N-48 |
| `map.frame_budget_ms`, `map.stale_after_s` | 16 ms, 90 s | N-38 |
| every `*.enabled` flag | false: each node ships dark and goes live by its own ticket | per node |

## 9. Commands

Every command that deletes, publishes, promotes or changes the line is a dry run unless it is given its apply flag, and the apply refuses when the plan it was shown has changed (409).
The line runs these by itself as `Executor.Run` verbs; the owner runs the break glass ones, once, and each is recorded and counted by the exit test.
No seat may run anything in the "owner only" or "service only" rows: the seat layer denies them and the store refuses the record (403).

| Command | What it does | Dry run and apply | Who runs it |
| --- | --- | --- | --- |
| `make -C scheduler build` then `make -C scheduler install-unit` | Builds `coq-service`, installs `$HOME/.config/systemd/user/coq-service.service`, prints the `loginctl enable-linger` line | none; install is the owner's one-time step | owner, once |
| `systemctl --user status coq-service`, `journalctl --user -u coq-service -f` | Unit state and the process journal | read-only | anyone |
| `scheduler ctl health`, `scheduler ctl status` | gRPC health with reasons; counters, ticks, held and dead jobs | read-only | anyone |
| `scheduler ctl store status`, `scheduler ctl record get ID`, `scheduler ctl record list --since SEQ --kind KIND` | Store size, top seq, tail clients; read records | read-only | anyone |
| `scheduler ctl reload` | Applies a merged config change by hash, writes `reload.applied` | none; the config change is a merged PR | service, after a merge |
| `scheduler ctl hold set --reason TEXT`, `scheduler ctl hold clear` | Sets or clears `flag:hold` as a `control.action` through N-29 | none; recorded | owner (or the Controls screen) |
| `scheduler/host/bin/restore-store.sh --from BACKUP --dry-run`, then `--apply` | Restores the store from a backup into a new epoch, held, with every lease expired and the token counter moved past every token issued, then reconciles GitHub, Jenkins and merges ([restore](shared/contracts.xml#restore)) | `--dry-run` lists, `--apply` moves the live file aside with a UTC stamp; only an owner ruling releases the hold | owner, unit stopped |
| `line/bin/cleanup.sh plan --entry ID`, then `line/bin/cleanup.sh apply --plan HASH --fence TOKEN` | Expands a registry entry, lists what would go, then deletes exactly that | `plan` is the dry run; `apply` refuses if the expansion changed | service (N-45); `apply` outside a plan is owner break glass |
| `line/bin/cleanup.sh --entry ID` | The registry verb for one state path (176 entries) | plan first, always | service (N-45) |
| `coq owner answer --relay --card C-42 --pick 3 --words "..."` | Records an answer the owner gave in chat or on the phone, verbatim, before any gate reads it; a relayed answer may only carry effects none or ticket.unblock and never becomes an owner word ([relayable rulings](shared/authority.xml#relayable-rulings)) | none; the store derives the caller from the socket peer uid, so a seat user is refused 403 whatever its environment (`COQ_SEAT` is diagnostic only, never authority) | owner or the owner's own architect session |
| `coq owner import-answers --file $HOME/.bearings/coq-stable/answers.jsonl` | Imports the legacy answers once at cut-over | `--dry-run`, then `--yes`; refuses an existing id unless `--skip-existing` | owner, once |
| `coq owner import-messages --file $HOME/.bearings/coq-stable/messages.jsonl` | Imports legacy messages once | `--dry-run`, then `--yes` | owner, once |
| `coq owner reply --to m-ID "text"` | Replies on the page through `Inbox.Reply` with the comms checker | refused with the violations | the only way a seat speaks on the page |
| `coq owner inbox --tier stable --open`, `coq inbox digest --since T` | Open messages with ack state; the architect digest | read-only | owner, architect |
| `coq owner url --page coq-stable` | Prints the loopback and tailnet URLs with the key, to the terminal only | read-only | owner |
| `coq owner rotate-key --page coq-stable` | Mints a new page key | none | owner break glass |
| `tools/bearings/scripts/promote.sh --tier stable --sha SHA` | Promotes a page build to stable by hand | none | owner break glass, counted by the exit test |
| `systemctl --user start coq-cutover@coq-stable` | Runs the one-shot page cut-over by hand | none | owner break glass |
| `rebuild/bin/unlanded.sh plan`, `apply --step N --plan HASH`, `status` | The 04-UNLANDED cleanup in its seven steps | `plan` is the dry run on the GOFACTORY card; `apply` refuses a changed hash | service (N-49); `apply` by hand is owner break glass |
| `rebuild/design/bin/publish-drive.sh` | Publishes version-named copies of this book to Drive | skips titles already present; refuses an unbumped version | service (N-47) |
| `rclone config create drive-coq drive scope=drive.file` | Authorises the Drive publisher once | none | owner, once |
| `ci/bin/branch-protection.sh --check` | Asserts `coq/gate` is a required, strict check on main | `--check` is read-only | service, daily |
| `factory/bin/suites.sh plan --repo DIR --base SHA --head SHA` | Prints the suites a diff needs; runs nothing | read-only | service (N-23), worker locally |
| `make -C tools/map build`, `make -C tools/map test`, `make -C tools/map lint`, `make -C tools/map art` | Builds and checks the map bundle and the atlas | none | pods; worker locally |
| `rebuild/design/check.sh` | Validates the spec book; exit 0 pass, 1 failures, 2 cannot run | read-only | anyone; N-46 in a pod |
| `uv run --with xmlschema --with jsonschema python3 -I rebuild/design/bin/test-checks.py` | Proves every check fires on a mutated copy of the book | read-only, works on a temporary copy | anyone |
| `python3 rebuild/design/bin/make-index.py`, `make-kinds.py`, `registry.py` | Regenerate `index.xml`, `shared/record-kinds.xml`, `shared/cleanup-registry.json` | `--check` reports staleness without writing | spec-author, in the same PR |

Depth: [N-01 runbook](nodes/N-01/spec.xml#runbook), [N-06 runbook](nodes/N-06/spec.xml#runbook), [N-29 runbook](nodes/N-29/spec.xml#runbook), [N-30 runbook](nodes/N-30/spec.xml#runbook), [N-45 runbook](nodes/N-45/spec.xml#runbook), [break glass](shared/seat-contract.xml#break-glass).

## 10. Inputs and outputs

| Item | Direction | Shape |
| --- | --- | --- |
| GitHub main ref, open PRs, combined statuses | in | REST v3 with ETag, budgeted 60 calls per 30 s poll, into `forge:snapshot` (N-04) |
| `coq/gate` commit status | out | GitHub status on the head or main sha: pending, success, failure, error with the gate page link (N-25) |
| Squash merge | out | GitHub merge API with `sha` equal to the head (N-09) |
| PR review mirror | out | `gh pr review --approve` or `--request-changes` with the reviewer's body (N-19) |
| Jenkins jobs `coq-gate`, `coq-image`, `coq-map` | out | `buildWithParameters` with SHA, ATTEMPT, plan; followed by build number (N-22, N-24, N-35) |
| Pod results | in | `pod.run` per unit: exit code, log path, wall time (N-24) |
| `roles/<role>.json` and `scheduler/config/seats.json` | in | Role model, allow and deny lists, limits `max_turns`, `max_budget_usd`, `wall_clock_seconds`, `stall_seconds` (N-13) |
| Seat bundle | out | `settings.json`, `mcp.json`, `brief.md`, `output.schema.json` with a bundle hash (N-13) |
| `claude -p` JSON envelope | in | `type`, `subtype`, `is_error`, `total_cost_usd`, `num_turns`, `session_id`, `structured_output`, `permission_denials` (N-15) |
| `scheduler/config/retry.json` | in | Retry table per failure kind (N-11) |
| `scheduler/config/prompt-rules.json` | in | Ordered match rules: id, regex, action answer, card or down (N-12) |
| `shared/status-codes.xml` and `shared/record-kinds.xml` | in | The live code table and kinds registry, loaded by hash (N-43) |
| `tools/bearings/config/cards.template.json`, `answer-effects.json`, `inbox-rules.json`, `bearings.json` | in | Card templates, answer effects, message routing rules, tier config, each schema-checked at lint (N-28, N-29, N-30, N-32) |
| Owner answer, message, file | in | `POST /answer {card, pick, words}`, `POST /message {id, text, files, reply_to}`, `POST /file` (N-32) |
| Page stream | out | Server-sent events on `/events`: `id` = seq, snapshot on reconnect, 1 s heartbeat (N-31, N-32) |
| herdr agent status event | in | `pane.agent_status_changed` with the harness notification text, for registered long-lived seats only (N-12) |
| Phone push | out | ntfy POST with title, body, priority by code, click to the tailnet page without the key; ntfy forwards only a poll request through the ntfy.sh upstream so a locked iPhone wakes at once, and the body stays on the cluster ([push delivery](nodes/N-52/spec.xml#push-delivery)) |
| Map public page | out | Static bundle at `map.gatehouse.click` with `healthz.json` naming the sha (N-35) |
| Drive copies | out | Version-named immutable files with a manifest, scope `drive.file` (N-47) |
| Screenshots | out | PNG at 1280x800 and 430x932 under `$COQ_STATE/screenshots/<tier>/<sha>/` (N-48) |
| Service credentials | in | One credential per job, held by `coq-svc` only, never by a seat and never in a record: forge-read (N-04), the coq-gate GitHub App (N-25), forge-merge (N-09), forge-pr (N-16 close-out); forge-admin stays in the owner's keyring ([credential matrix](shared/authority.xml#credential-matrix)) |
| Outside probe alerts | out | `coq-probe` on a Pi posts to its own ntfy topic with its own token when the host stops answering, and its outage journal is imported on recovery as `host.outage` ([outside probe](shared/outside-probe.xml#alerting)) |
| Backups | out | Snapshots taken on a reader connection, compressed to `.zst` with checksums, classes tick, daily, monthly and manual, carrying the epoch ([restore](shared/contracts.xml#restore), N-05) |

## 11. Status and exit codes

### 11.1 Record status codes

Every record carries one of these codes; the code decides the lamp every screen draws and who moves next.
A code whose actor is the owner becomes exactly one card; nothing else reaches the owner ([status codes](shared/status-codes.xml#codes), [owner-acts](shared/status-codes.xml#owner-acts)).

| Code | Name | Lamp | Meaning | Who acts |
| --- | --- | --- | --- | --- |
| 100 | accepted | amber | Exists or in progress: the record opens a traversal or marks a step still running; the next node on the edge acts on the next tick. | system: the next node on the DAG edge; never a wait by a seat. |
| 200 | done | green | Done or applied: the step finished and its output is the record; a replayed idempotent put also answers 200 with the first response. | system: the phase post step; nobody waits on it. |
| 201 | passed | green | Accepted, passed, verified or published: a gate or a validator said yes, or a row was created the first time. | system: N-03 on an accepted ticket, N-09 on review.passed, N-10 on verified, N-26 on job and namespace readiness. |
| 204 | nothing-to-do | green | Nothing to do, released or not run: a terminal transition with no output to act on. | nobody; N-45 releases claims and slots on it. |
| 206 | degraded | amber | Partial: a frame rendered with some panels stale or missing; the screen says so instead of hiding it. | system: the next pushed frame replaces it; N-41 lists it when it persists past map.stale_after_s. |
| 300 | routed | amber | Routed or informational: a card was posted, a message was routed by rule, a question is open, or a rule bit a rebuild ticket under build mode. | owner for a card (card, break.glass, promotion.confirm, art.gap); system for routed.message, rule.bit, plan.question routing; the owner answers on the page, never in a reply. |
| 400 | invalid | red | Bad record: schema refused, unknown code, bad map or registry entry, unkeyable row; the writer is wrong, not the system. | system: N-11 on a validator refusal, plus a defect on N-15 when two schema checks disagree; owner only for a code map that fails to load (N-43 keeps the previous table). |
| 403 | refused-by-role | red | A seat put a line-operation kind (code.table, build-mode.state, rule.bit, cleanup.run, disposition, cancel, pr.close, branch.delete, promotion, exit.verdict, freeze.state, any flag): refused by N-01 and counted. | system: N-11 records it on the run; N-51 counts it as an agent line operation for the day; a seat never retries it. |
| 404 | not-found | amber | The selection names a node or record that does not exist in the frame; the screen shows the miss. | nobody; the next frame or selection replaces it. |
| 409 | conflict | amber | Conflict: a compare-and-swap miss, an idempotency key seen with a different payload, a claim race, a duplicate ruling, a second instance, a dirty checkout or a cancel-set mismatch; the loser re-reads and retries or reports. | system: the writer re-reads the current version and retries within its 3 attempts; N-11 on merge.conflict; a second answer or a second instance is refused for good (owner on a cancel-set mismatch). |
| 410 | superseded | grey | A newer head sha, main sha, gitops sha or frame replaced this run or check; the superseded work stops and nobody acts on it; the one exception is alert.aged, an open alert past its escalation bound. | nobody for supersession (N-07 stops the Jenkins build, N-25 posts error superseded); owner for alert.aged. |
| 412 | precondition-refused | amber | A precondition failed: stale lease or fencing token, missing ruling, frozen intake, claim overlap, head moved, bundle or workspace mismatch, import not recorded, a seat trying a verdict write; the step did not run. | system: N-11 by reason, or N-03 for claim_overlap without an attempt; owner only when the reason is a missing ruling or a frozen intake that needs the freeze lifted. |
| 422 | failed-with-evidence | red | Rejected with evidence: a check ran and said no (a red gate, a failed test, review changes, a failed promotion attempt, an invalid frame); the evidence is in the record; a result is never retried, only infrastructure is (V05). | system: N-11 cuts the next attempt or the dead record; owner when it is rejected on main (N-10 opens the merge.hold and one card) or an exit test day fails every third time. |
| 423 | blocked | amber | Blocked or held: a lease is held by another, a merge hold stands, a card is held, a run ended blocked with a terminal reason, a promotion or a Drive publish needs set-up; the work waits on a named condition with a bound. | system: N-11 by terminal reason (success, error_max_turns, error_max_budget_usd, error_during_execution, error_max_structured_output_retries, killed_deadline, killed_stall, killed_lease_lost, killed_by_record, crashed, no_result, schema_invalid, output_rejected, seat_blocked); owner at a second 423 on the same key, on a prompt.parked long-lived seat that no standing answer covers (one card; a model-limit prompt of a role with a ruled model is answered by the system and is no card), on a stable promotion, on Drive auth and on other-repository rows. |
| 429 | no-capacity | amber | Refused for capacity: a cap on leases, slots, ports or push clients; the request is not queued, the next tick asks again. | system: N-07 on a later tick, never a waiting loop; nobody is told unless it persists past the stall bound (then N-41). |
| 500 | failed | red | Failed after 3 attempts, stalled, dead, corrupt or a defect: the system has recovered what it can and reports; the kinds marked system-handled below are counted and watched, the rest become one card. | owner for dead, stall.kill.failed, store.corrupt, unit.crashloop, ticket.stale, backup.failed, backup.rotten, forge.overflow, watcher.dead, cutover.failed, hold.ignored, counters.failed after three skipped ticks, merge.hold.aged, main.verify.missing; system-handled with a counter and an N-41 row: tick.missed, lease.expired, lease.failed under three in ten minutes, intake.slow, forge.slow, backup.mirror_failed under a day, gate.write.failed, status.post.failed, verify.write.failed, deploy.build-failed, art.failed, binding.failed, push.stalled, push.failed, reply.failed, delivery.failed, inbox.unroutable, message.stale. |
| 502 | unreachable | red | A front door or upstream did not answer: the map is offline or the gitops front door did not serve the new digest. | system for the first three attempts; owner after 3 (deploy.front-door-unreachable). |
| 503 | unavailable | red | Unavailable or halted: the store, disk, forge, stream, mirror, checker, publisher or intake is not serving, or the line is halted by the owner; monitoring never stops under it. | system: refuse the put once, skip the run, keep ticking; owner for line.halted (a card), store.unavailable, store.disk and backup.disk after N-45 ran, forge.unreachable after three failed polls past forge.stale_after_seconds, Drive not set up. |
| 504 | timeout | amber | A bounded wait expired: a deploy, a first frame, a view or a counters tick did not finish inside its bound; the fallback named by the wait runs. | system: the wait's fallback; N-41 lists it; owner never, unless the same key times out three times (then 500 by the three-attempts rule). |

### 11.2 Script and unit exit codes

| Exit | Meaning | Who acts |
| --- | --- | --- |
| 0 | OK, or the dry run was shown | nobody |
| 1 | Checks failed (one `FAIL` line each), or a unit was fenced by a newer lease generation and exits for systemd to restart | the writer of the failing file; systemd for a fenced unit |
| 2 | Usage, or the checker cannot run (no validator) | the caller |
| 3 | Refused: a second instance of a unit (systemd `RestartPreventExitStatus=3` stops the loop), a validation failure, an unknown config variable | nobody for a second instance; the config author otherwise |
| 4 | I/O or a step failed after its 3 attempts (bind, cleanup, publish, promotion), or an owner-only verb was called by a caller whose peer uid is not the owner principal | the system reports it as a record; the owner only through the card it produces |

## 12. Tool choices

| Job | Tool | Why |
| --- | --- | --- |
| Control plane | One Go service with gRPC on unix sockets | Owner ruling 2026-10-14 ~04:00Z ("GO ... handles this, agents and humans dont", "grpc for the win"); the proto and the fake clock already exist; one binary, one test harness (D01, D09) |
| State | SQLite in WAL mode, one file, one writer | One host, no broker to run; compare-and-swap and idempotency keys give the many-writer safety; a broker would only have stored 212 of the 391 misaddressed wakes (D10, card C34) |
| Supervision | systemd user units with linger, `Restart=always`, `WatchdogSec=60`, each seat in its own transient unit outside the service's cgroup | A crash restarts in 5 s and a hang is killed by the watchdog, never by a pane reader; a restart repeats no effect, because every effect carries an operation key with a request hash and an outbox row ([operation keys](shared/contracts.xml#operation-keys)); a whole-host or store outage like the 9.5 hour dark one is detected from outside by the probe within its bound ([alerting](shared/outside-probe.xml#alerting)) |
| Gate verdict | GitHub required status `coq/gate` | Readable by an agent, editable by none; GitHub itself refuses a merge without it (D05, card C43) |
| GitHub events | Poll every 30 s with ETags | GitHub cannot reach the host on its private LAN address; a missed webhook is never redelivered; a webhook may only call `poll_now` later (D06, card C44) |
| CI executor | Jenkins as code: JCasC, job by config, image pinned by digest, Longhorn home, synced by Argo | The owner's working pipeline, fixed instead of replaced; no UI clicks; no CIFS home on a Windows PC (D07, card C45) |
| Tests, lint, image builds | Pods in namespace `coq-factory`: quota and sizes from [CI capacity](shared/ci-capacity.xml#quota), priority -100, no secrets, egress to cluster DNS, the Jenkins controller, GitHub and GHCR only | Pod tests already pass 30 of 31 herdr cases; the WSL host had eleven crashes in seven weeks (D22, D23, cards C38, C53) |
| Image builds | Kaniko through `jenkins-shared-lib`, pushed to `ghcr.io/jkkelley`, the builder image pinned by digest to the maintained fork with a fallback ([builder pin](shared/ci-capacity.xml#builder-pin)) | The yieldpoint-ai path, already working; the upstream Kaniko project is archived, so the pin and its fallback are written down |
| Seats | `claude -p` one-shot with `--json-schema`, `--permission-mode dontAsk`, limits as flags | Result, cost, turns and terminal state come from the harness, not the model; a miss is a recorded denial, not a prompt (D02, card C36) |
| Seat credential | Subscription login on the host; API key only for pod seats | No new bill now; exact caps when seats move to pods (D03, card C37) |
| Model per seat | The role file's model; Sonnet by default; Opus only by a ruling | Right-size rule (owner 2026-10-13); a model-limit prompt switches to the ruled model, never spends extra credits |
| Ticket cutting | An LLM spec-author cuts tickets as data; a code validator runs every acceptance command on main first | Judgement where it helps, proof before admission (D16, card C48) |
| Validator runtime | Podman on the host with the pinned images | An exit code within a minute; the same digests the pods use |
| Owner's window | herdr panes, for viewing only | herdr is not a bus, store or supervisor; its crash took the whole line (D08, card C46) |
| Owner surface | The bearings page as the one surface, rail folded in as a panel | One place to read and decide (D20, card C51) |
| Page transport | Server-sent events from the Go page service, full state on reconnect | `EventSource` reconnects by itself with `Last-Event-ID`; WebSocket only if a measured phone frame-time miss demands it (D21, card C52) |
| Phone access | Tailscale front door unit `coq-front-door@<page>` | Works today (PR 186, PR 187), no root, rebinds by itself when the tailnet address changes |
| Phone push | Self-hosted ntfy on the cluster, with `upstream-base-url` set to ntfy.sh for instant iOS delivery | No app to build, one POST per push (C58); the owner wants pushes instant, and iOS wakes a locked phone only through Apple's push service, so ntfy.sh sees a message id and a topic hash, never a card title or body ([push delivery](nodes/N-52/spec.xml#push-delivery)) |
| Public map hosting | Jenkins, `jenkins-shared-lib`, ghcr, homelab-gitops Helm chart, Argo, HAProxy, Lightsail Nginx, Route 53 | Owner note 5: "the plumbing needs to work first ... lets not make this hard"; a hello page proves it before map code |
| Map rendering | TypeScript, Canvas 2D, fixed 60 Hz simulation, 16 ms frame budget | 60 fps pushed state on a phone; no framework beyond the renderer |
| Look | Krastorio 2 token table as CSS custom properties, Titillium Web, original art only | Owner rule "all views shown to me better have that krastorio look"; Titillium is SIL OFL 1.1; no Wube or BiusArt file ships |
| Screenshots | Playwright in a pinned container at 1280x800 and 430x932 | Every page change is pictured before the owner is asked |
| Specs and schemas | XML volumes of 1000 lines or fewer with one XSD; JSON Schema 2020-12; Mermaid; this Markdown for the owner | Owner rules: specs are XML, schemas are JSON, diagrams are Mermaid, the owner reads one design file |
| Drive copies | `rclone` pinned by sha256, scope `drive.file` | The repository is the truth; Drive gets immutable version-named copies (D24, card C54) |
| Cleanup | One script, `line/bin/cleanup.sh`, driven by a generated registry | Owner (C35): "keep all artifacts out of the git repo ... just ensure we have cleanup scripts" |
| Forge | GitHub now, behind the one `Forge` interface of N-04 | Forgejo later is one node, off the critical path (D18, card C55) |

## 13. Standing rules after build

These bind every agent once the rebuilt line runs; each is enforced by a node, not by memory.

- Never type into a seat, nudge a seat or keep a seat waiting; a seat exists only between its input record and its output record.
- Never write a line-operation record (`merge`, `verified`, `dispatch`, `cleanup.run`, `promotion`, `exit.verdict`, any flag, any lease); the store refuses it from a seat with 403 and the exit test counts it.
- Never merge, close a PR, delete a branch, post a commit status, restart a unit or run `make upgrade`, `make stop` or `systemctl --user` from a seat.
- Read state only through the store (`scheduler ctl record get`, `record list`, `ticket get`); never open the SQLite file and never write runtime data under the repository.
- Cut tickets only through the spec-author and validator path; a ticket names its files, its input and output records, and acceptance commands with their observed exit on main.
- Name every ticket with its id and its full title, in every reply and every card.
- Touch only the files your ticket declares; one file, one in-flight ticket.
- Every new state path ships with its `state-paths` entry, a cleanup script and a regenerated `shared/cleanup-registry.json` in the same pull request.
- Every new record kind ships as a row in its node volume and in `shared/status-codes.xml`, with `shared/record-kinds.xml` regenerated; `check.sh` refuses it otherwise.
- Every change to the book edits the volumes, regenerates `index.xml`, bumps `BOOK_VERSION` and passes `rebuild/design/check.sh` in the same pull request.
- Every design ships one design `.md` in this fifteen-section format (owner order 2026-10-14 ~17:35Z), beside its XML.
- Every page change is screenshotted at 1280 and 430 wide and the picture is read before any card asks the owner about it.
- Talk to the owner only on the page: a card for a decision, `coq owner reply` for a reply; an answer he gives in chat is recorded with `coq owner answer --relay` before anyone acts on it.
- A model-limit prompt is answered with the role's ruled model; never pick an option that spends extra credits.
- A rule that blocks a rebuild ticket under build mode is a defect in the rule (`rule.bit` 300), not a failure of the ticket.
- A hand fix is a defect: turn it into a ticket that makes the system do it.
- Leave the breadcrumb at the fix site: what broke, why it mattered, why this fix, what it costs.
- Never select the privileged AWS profile the owner's site file names.

## 14. Files created

### 14.1 In the repositories

| Path | Purpose |
| --- | --- |
| `scheduler/internal/store`, `lease`, `intake`, `forge`, `backup`, `unit` | G1: the store with migrations under `store/migrations/`, leases, ticket intake, the GitHub poll, backups, the unit and ticks |
| `scheduler/internal/sched`, `gate`, `merge`, `verify`, `retry`, `stall` | G2: the scheduler tick, the gate check, the merge, the main verdict and hold, retry, the stall timer |
| `scheduler/internal/seatlayer`, `workspace`, `launcher` (with `worker.go`, `specauthor.go`, `reviewer.go`), `validator` | G3: bundle render, workspace provision, the one-shot launcher and post steps, the validator |
| `scheduler/internal/owner/watcher`, `cards`, `intake`, `inbox`, `push`, `pushbridge` | G5: the owner surface inside the Go module, plus the commands `coq-bearings` and `coq-watcher` |
| `scheduler/internal/flags`, `cleanup`, `promote`, `cutover`, `exittest` | G7: build mode and hold flags, cleanup runs, tier promotion, cut-over records, the exit test |
| `scheduler/host/systemd/coq-service.service` | The service unit |
| `scheduler/config/principals.json`, `/etc/coq/seat-users`, the root-owned helper `coq-seat-exec`, the WSL host settings | The principals, the seat user pool, the seat launcher helper and the host checks of [authority](shared/authority.xml#wsl-host), each planned there |
| `scheduler/api/store/v1/`, `lease/v1/`, `intake/v1/` protos | The new Store, Lease and Intake services beside the existing `scheduler.proto` ([N-01](nodes/N-01/spec.xml#mechanism)) |
| `coq-probe` on one Pi, with its own ntfy topic and token | The outside probe ([outside probe](shared/outside-probe.xml#probe)) |
| `scheduler/host/bin/restore-store.sh` and `cleanup-*.sh` (store, run, logs, leases, forge, backups, unit, seat-bundles, seat-runs, workspaces, validator, git-mirror, tickets, branches) | Restore and the per-area cleanup scripts the registry calls |
| `scheduler/config/seats.json`, `retry.json`, `prompt-rules.json`, `cleanup.json` | Seat limits and git identity, the retry table, prompt routing, cleanup config |
| `roles/schema/role.schema.json` gains `max_turns`, `max_budget_usd`, `wall_clock_seconds`, `stall_seconds` | Limits as fields, never prose ([N-13](nodes/N-13/spec.xml#mechanism)) |
| `line/bin/cleanup.sh` | The one cleanup verb: `plan`, `apply`, `--entry` |
| `ci/jenkins/Containerfile`, `plugins.txt`, `gate.Jenkinsfile`, `image.Jenkinsfile`, `migrate-home.sh` | The Jenkins controller image, plugins, job files, the one-time home move from CIFS to Longhorn |
| `ci/bin/plan-units.sh`, `unit-wrap.sh`, `images.sh`, `branch-protection.sh`, `jenkins-check.sh`, `namespace-check.sh`, `egress-policy.sh`, `cleanup-ci-state.sh`, `cleanup-cluster.sh`, `cleanup-ghcr.sh` | CI planning, checks and cleanup |
| `ci/config/images.lock.json`, `ci/image/manifest.sh`, `ci/image/verify.sh` | Image pins and verification |
| `tools/bearings/units/coq-bearings@.service`, `coq-watcher@.service`, `coq-front-door@.service` | The page, watcher and front door units |
| `tools/bearings/config/cards.template.json` (and schema), `answer-effects.json`, `inbox-rules.json`, `plans.json` | Card templates, answer effects, message rules, rail plans |
| `tools/bearings/bin/install-units.sh`, `cutover.sh`, `cleanup-tier.sh`, `cleanup-files.sh`, `cleanup-journal.sh`, `cleanup-push.sh` | Install, cut-over and page cleanup |
| `tools/bearings/scripts/promote.sh`, `screenshot.sh` | Tier promotion and the screenshot proof |
| `tools/map/` (`Makefile`, `Containerfile`, `Jenkinsfile`, `src/`, `registry/`, `art/`, `bin/`) | The command center map: bundle, registries, art pipeline, look and binding checks |
| `rebuild/bin/unlanded.sh`, `rebuild/design/bin/publish-drive.sh` | The unlanded cleanup and the Drive publisher |
| homelab-gitops `apps/jenkins/`, `argocd-apps/infrastructure/jenkins-app.yaml` | Jenkins as code |
| homelab-gitops `apps/coq-factory/`, `argocd-apps/workloads/coq-factory.yaml` | The factory namespace |
| homelab-gitops `apps/coq-map/`, `argocd-apps/coq-map.yaml` | The public map |

Built by tickets cut from this book after GOFACTORY, each shipped dark and turned on by its own go-live ticket.

### 14.2 Outside git, with the cleanup command

Every state path a volume names is an entry of [`shared/cleanup-registry.json`](shared/cleanup-registry.json) (176 entries, generated by `bin/registry.py`); the one verb is `line/bin/cleanup.sh --entry <id>`, and every run lists first.

| Path | Purpose | Cleanup |
| --- | --- | --- |
| `$COQ_STATE/store/coq.db` and its WAL | The one store | Never deleted live; rows by retention class: `line/bin/cleanup.sh --entry N-01.store`, leases `--entry N-02.store-coq-db-table-leases-entity-counter` |
| `$COQ_STATE/backup/store/YYYY/MM/*.zst` | Snapshots | `--entry N-05.backup-store-yyyy-mm-zst` (keeps each class tick, daily, monthly and manual by its own rule and a free-space floor, never the newest verified; [N-05](nodes/N-05/spec.xml#mechanism)) |
| `$COQ_STATE/logs/**/*.jsonl` | Structured logs by node | `--entry N-01.logs-service-store-jsonl`, `N-07.logs`, `N-08.logs`, `N-09.logs` and the other `.logs` entries |
| `$COQ_STATE/briefs/` | Rendered briefs | `--entry N-07.briefs` (30 days after verified) |
| `$COQ_STATE/seats/bundles/<run_id>/`, `seats/runs/<run_id>/` | Seat bundles and run files | `--entry N-13.seats-bundles-run-id`, `--entry N-15.seats-runs-run-id` |
| `$COQ_CACHE/ws/<slot>/`, `$COQ_CACHE/git/<slug>.git` | Workspaces and the mirror | `--entry N-14.workspace`, `--entry N-14.git-slug-git` |
| `$COQ_STATE/validator/<set_id>/` | Validator runs | `--entry N-18.validator-set-id` |
| `$COQ_STATE/ci/` (mirror, plan, logs, gate, verify, image) | CI planning and results | `--entry N-23.ci-plan-sha12-attempt`, `N-24.ci-logs-gate-yyyy-mm-sha12-attempt-units`, `N-25.ci-gate-yyyy-mm-sha12-attempt-json` |
| `$COQ_STATE/bearings/<page>/` | Page key, files, screenshots, front door lock | `--entry N-32.bearings-page-files`, `N-32.bearings-page-screenshots`, `N-34.bearings-page-front-door-json` |
| `$COQ_STATE/map/` | Art work, dist, deploy probes, registry checks, screenshots | `--entry N-36.map-art-work-sha`, `N-38.map-dist-sha`, `N-38.map-screenshots-yyyy-mm-sha-tier-device` |
| `$COQ_STATE/svc/codes/`, `cleanup/plans/`, `publish/`, `tiers/`, `screenshots/` | Code tables, cleanup plans, Drive exports, tier sources, promotion pictures | `--entry N-43.table`, `N-45.plans`, `N-47.export`, `N-48.tier-src`, `N-48.screenshots` |
| `$COQ_STATE/unlanded/`, `backup/unlanded/`, `cutover/`, `exittest/` | Cut-over and exit-test working files | `--entry N-49.plan`, `N-49.backup`, `N-50.cancel-set`, `N-51.rows` |
| `$COQ_STATE/secrets/rclone.conf`, `owner/push/token`, `config/service.env` | Secrets, mode 0600 | `--entry N-47.secret`, `N-52.owner-push-token`, `N-06.config-service-env` (owner only) |
| `$HOME/.config/systemd/user/coq-*.service`, `$HOME/.local/bin/coq-service` | Units and the binary | `--entry N-06.config-systemd-user-coq-service-service`, `tools/bearings/bin/install-units.sh --remove` |
| `$HOME/.bearings/coq-stable/` | The legacy page state, retired at cut-over step 10 | `tools/bearings/bin/cleanup-tier.sh coq-stable --legacy` |
| Cluster: namespace `coq-factory` pods, Kaniko pods, ghcr package versions | Test pods and images | `ci/bin/cleanup-cluster.sh --what`, `ci/bin/cleanup-ghcr.sh --image NAME` |
| GitHub: branches `wo/<ticket>` | Ticket branches | Deleted on merge (`forge.delete_branch_on_merge`), checked by `scheduler/host/bin/cleanup-branches.sh` |

## 15. Decisions for the owner

Only the open ones; the R-02 rulings (C34 to C58) are closed and not asked again.
Each goes on the stable page as its own card, one at a time, in this order; the same list is kept in [owner decisions](shared/review-dispositions.xml#owner-decisions).
GOFACTORY and USERGO are not on this list: they stay your words, given when you choose, and nothing in this book grants, implies, defaults or relays either ([owner words](shared/authority.xml#owner-words)).

1. **Close R-03 on this read?**
   Recommendation: close it.
   Then: PR 189 merges, this book becomes the one design on main, the bootstrap enters B0, and only the B1 foundation tickets may be cut; every runtime ticket waits for your GOFACTORY ([bootstrap](shared/cut-over.xml#bootstrap)).

2. **Is one Raspberry Pi of the cluster free for the outside probe?**
   Today nothing outside the WSL host notices when the host or the store is down, which is how the line once stayed dark for hours.
   Recommendation: give one Pi to `coq-probe`, with its own ntfy topic and token; until you confirm one, the probe is designed and its proof is not-run ([availability](shared/outside-probe.xml#availability)).

3. **Create the coq-gate GitHub App?**
   The gate status must be posted by a credential that can write statuses and checks and nothing else, and the required check on main names that App by its id.
   Recommendation: create it with statuses and checks write only and record its app id; no other credential can post `coq/gate` ([GitHub App](shared/authority.xml#github-app)).

4. **Turn WSL interop off and mount the Windows drives with umask 077?**
   Separate users only isolate seats if a seat cannot start Windows programs or read the Windows drives; both settings change how you use the host yourself.
   Recommendation: turn interop off and set the umask; GOFACTORY is refused while the host checks fail ([WSL host](shared/authority.xml#wsl-host)).

5. **Which bootstrap merge path?**
   Under the hold no machine merge happens, yet the cut-over's own pull requests must land before USERGO.
   Recommendation: the default, where N-09 merges under the hold only pull requests of the current bootstrap step with a green gate and review.passed on the same head, and your break glass merges the few that come before the first gate; the alternative is your break glass for every one ([bootstrap merge](shared/cut-over.xml#bootstrap-merge)).

6. **Accept the Kaniko pin to the maintained fork?**
   The upstream Kaniko project is archived, so image builds need a maintained source pinned by digest.
   Recommendation: accept the pinned fork with rootless BuildKit as the written fallback ([builder pin](shared/ci-capacity.xml#builder-pin)).

7. **Ship only the 260 high-confidence Krastor originals until the rest are confirmed?**
   The art inventory found 766 Krastor originals, but only 260 have commit-level proof, and whether the LGPLv3 grant covers a public web page is a question for you or a lawyer.
   Recommendation: ship the 260 with the conservative notice and the license text, hold the 506 medium files until each is checked by eye, and draw belts, inserters, lamps and pipes as original art.

8. **Accept a static map at map.gatehouse.click, with live state only over the tailnet, for now?**
   Cluster pods cannot reach the host, so a live public map needs a cluster to host tunnel with your key's auth, which is a node of its own.
   Recommendation: accept; your phone already gets the live map anywhere through Tailscale, and the tunnel is cut as its own design later.

9. **Which Google Drive folder gets the version-named copies of the book?**
   The publisher needs a folder id and one browser consent for `rclone` with scope `drive.file`; until then the repository stays the truth and publishing simply waits.
   Recommendation: a new folder named "coq spec book", authorised once with scope `drive.file`, so the token can touch only what it created.

Not asked now: the second repository for R-10 is asked when R-09 completes.
