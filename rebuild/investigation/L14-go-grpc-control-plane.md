# L14 - Go control plane with gRPC

Investigator: area L14, step R-01.
Written 2026-10-14 UTC.
Status: ok.

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

Per-source sections inside section 3 and section 4:

- 3.1 The Go scheduler in this repository (the live design, SPEC-16)
- 3.2 jkkelley/rime (Go, gRPC, paused)
- 3.3 jkkelley/bearings-core (Go, NATS, no gRPC)
- 3.4 Stable v3 Go core (design only, never built)
- 3.5 Google Drive control_plane.proto (Bootstrap With Agent, design only)
- 3.6 Google Doc "31 gRPC Go Rust and requirements driven tooling"
- 3.7 lucaGazzola/forgeo (the thing the owner now calls forgeo)
- 3.8 Other owner Go repos and searches that came back empty

## 2. What it is

Answer to the owner's question "why isn't a system design by go still here?": the Go and gRPC system design is still here.
It is `scheduler/` and `specs/scheduler/` on main, and the roadmap names it the end state of the line (`ROADMAP.md` line 136, phase 4 "Go scheduler: the scheduler runs the small loop and the factory DAG"; `20261013025600-priority-list.md` line 6, "Engine: the Go scheduler (SPEC-16, PR 37) is the end state (ruling lvvtd); everything else is interim glue").
What is not here is a running Go system.
Only the skeleton of it was ever merged: 3,804 lines under `scheduler/`, of which 2,336 are generated protobuf code, and no goroutine, no gRPC server and no tick loop exist in it.
The 14 build tickets that would write the server, the loop and the executor are all in status `ready` and none has a branch or a pull request (`work-orders/WO-20261010-329d/WO-20261012-ea33/`, listing below in 4.1).

The owner has asked for the same idea four times and each time it was designed but not built to the point of running:

| #   | Date (UTC) | Name                                                       | Go and gRPC?                                   | Built?                                                                                   |
| --- | ---------- | ---------------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------- |
| 1   | 2026-09-14 | stable v3 Go core (stable-core, connect-go)                | yes, approved as D-4                           | no Go file exists in `jkkelley/stable`                                                   |
| 2   | 2026-09-17 | Bootstrap With Agent control plane (`control_plane.proto`) | yes, 4 gRPC services                           | proto only, repo `bootstrap-with-agent` does not exist                                   |
| 3   | 2026-09-20 | bearings-core                                              | Go yes, gRPC no (NATS JetStream)               | 1,498 Go lines, 3 commits                                                                |
| 4   | 2026-09-21 | rime ("GO gprc central system")                            | yes, buf and grpc v1.64.1                      | contract, store, stream and transition built; gRPC server never built; paused 2026-10-06 |
| 5   | 2026-10-12 | coq Go scheduler (SPEC-16)                                 | yes, but only a unix socket between two halves | skeleton only                                                                            |

The closest match to the owner's sentence "lite weight go concurrency with grpc" is row 4 plus row 5.
Row 4 is the one the owner spelled out on 2026-09-21T01:23Z: "i want a GO gprc central system to route to all this shit ... GO GRPC concurrent system that drives everything" (`~/.claude/history.jsonl`, project bearings-v2).
Row 5 is the one the owner ordered on 2026-10-12T18:34Z ("build a lightweight Go scheduler, run it in Podman on WSL", `specs/scheduler/SPEC-16-scheduler-overview.xml` line 30, `p-order`).
"Forgeo" is none of them (section 3.7).

## 3. Where it lives

### 3.1 The Go scheduler in this repository (SPEC-16)

- Code: `/home/luna/projects/coq-jev-herdr-plugin/scheduler/` on main.
  - `go.mod` line 1 `module coq/scheduler`, `go 1.26`, requires `google.golang.org/grpc v1.84.0` and `google.golang.org/protobuf v1.36.12`.
  - `api/scheduler/v1/scheduler.proto` (package `coq.scheduler.v1`), generated `scheduler.pb.go` (1,904 lines) and `scheduler_grpc.pb.go` (432 lines).
  - `internal/core/` (types and interfaces, 12 files), `internal/testkit/` (fake clock, records, executor, world), `internal/cli/` (subcommand registry), `cmd/scheduler/main.go` (14 lines).
  - `config/scheduler.json`, `config/executor.json` and their schemas; `host/bin/{inbox,run,run-exec}.sh`; `RUNBOOK.md`; `Makefile`; `Containerfile`.
- Specs: `specs/scheduler/SPEC-16-scheduler-overview.xml` (283 lines) and `SPEC-16.G-config-schema.xml` (180 lines) on main.
  The other nine domain specs (A intake, B routing, C seats, D jobs, E policies, F health, H runtime and executor, I observability, J cut-over, K testing) exist only on the remote branch `origin/feat/go-scheduler-design-one-xml-spec-per-domain-unde`, 261 lines for the overview alone in its first draft.
- Pull requests: PR 37 (design, 42 files, +2,585 lines) was CLOSED unmerged on 2026-10-13T13:06Z and split into per-file tickets (PR 89, merged 16:16Z).
  Landed so far: PR 38 config files (2026-10-12T22:10Z), PR 39 skeleton (2026-10-12T20:23Z), PR 41 host files, PR 100 graph nodes, PR 102 spec toolchain, PR 114 overview, PR 123 config schema.
- Work orders: epic `WO-20261012-ea33 - Go scheduler: a lightweight Go service in Podman on WSL schedules the small loop and the software factory DAG, designed by a Fable architect and built by four Opus workers` (status ready, approved by owner order 2026-10-12T18:34Z, "CRITICAL").
- Graph nodes: `graph/nodes/DEC-scheduler-go-podman.json` (status `proposed`), `DEC-scheduler-two-processes.json`, `CMP-scheduler.json`, `CMP-scheduler-executor.json`, `IFC-scheduler-executor.json`, `RUN-scheduler-operate.json`.
- Not running: there is no `scheduler` directory in the state root `/home/luna/.local/state/coq/coq-jev-herdr-plugin/`, and the roadmap holds all line work until `USERGO` (`ROADMAP.md` line 31).

### 3.2 jkkelley/rime (Go, gRPC, paused)

- GitHub `jkkelley/rime`, private, Go, last push 2026-10-06; clone at `.../investigation/clones/rime`, HEAD `994a614` (2026-10-06 "A-19 - Transition table with ordered gates"), 20 commits, first commit 2026-09-21 (`git log`).
- `go.mod`: `module github.com/jkkelley/rime`, `go 1.23`, `google.golang.org/grpc v1.64.1`, `google.golang.org/protobuf v1.34.2`, `github.com/redis/go-redis/v9`.
  The comment block in `go.mod` explains the pins: grpc v1.84.0 needs Go 1.25 and the build image is golang:1.23.1.
- Proto files: `proto/rime/v1/rime.proto`, `role.proto`, `health.proto`, generated into `gen/go/rime/v1/rime_grpc.pb.go` and `health_grpc.pb.go`.
- Local copy `/home/luna/projects/rime-gate-proof` (go.mod `module github.com/jkkelley/rime`, HEAD `e4eb1bd` 2026-09-21) is an older checkout of the same repo and `/home/luna/projects/rime` is older still (see L09).
- Design: `/home/luna/tools/bearings-v2/CORE-DESIGN.md` (record BV2-CORE-20260921) and `DESIGN.md` lines 205-207; ADR `docs/ADR/0001-rime-go-grpc.md` in the clone.

### 3.3 jkkelley/bearings-core (Go, NATS, no gRPC)

- GitHub `jkkelley/bearings-core`, private, Go, last push 2026-09-20; clone at `.../investigation/clones/bearings-core`, HEAD `d69375d`, 3 commits (`0c33542` bootstrap, `8726263` "the bus and the core", `d69375d` Forgejo deploy).
- `go.mod`: `module github.com/jkkelley/bearings-core`, `go 1.22`, `nats-server/v2 v2.10.14`, `nats.go v1.34.1`.
  `google.golang.org/grpc` is absent (checked with `gh api repos/jkkelley/bearings-core/contents/go.mod`, count 0); `google.golang.org/protobuf v1.33.0` is only an indirect dependency.
  No `.proto` file in the tree.
- `README.md`: "a NATS JetStream bus carrying a single envelope schema, and one Go core service that is the only writer of task state" with a lease and a fencing token per task, invalid messages dead-lettered with `ERR_SCHEMA`.

### 3.4 Stable v3 Go core (design only)

- `jkkelley/stable`, clone at `.../investigation/clones/stable`; plan `docs/superpowers/specs/2026-09-14-stable-v3-battle-plan.md`.
- Line 15: "A Go control plane on the cluster and a Go bridge on the WSL host run a stable of schema-bound Claude Code agents from queues".
- Line 215: RPC is `connect-go` ("One handler serves gRPC, gRPC-Web, and JSON on one port, pure Go on arm64").
- Line 232: phase S1 "`stable-core` skeleton on the cluster: registry, health RPCs, Postgres".
- Line 426: "D-4 Go and gRPC replace the bash exporter and Tailwind page - approved 2026-09-14".
  The owner's answer is in `~/.local/state/stable/decisions/2026-09-14-round-1.jsonl`: D-4 "yes" at 2026-09-14T16:52:19Z.
- Research that fed it: `~/.local/state/stable/research/2026-09-14-go-control-plane/SUMMARY.md` and `ARCHITECT.md` (26,249 bytes): "No existing open source project does all of this together."
  Also `2026-09-14-rust-vs-go-underneath/SUMMARY.md` (Rust clients can call a Go core through tonic or connect-rust).
- Owner statements 2026-09-14: "we have GO pods that can act as all of this ... GO pods allow for gRPC from one machine to another" (14:11Z, project stable) and "we know we need GO for concurrency/ gRPC what we're building, i'm not deviating from that" (18:28Z).
- No `.go`, `go.mod` or `.proto` file exists in the stable clone (`find` returned nothing).

### 3.5 Google Drive control_plane.proto (Bootstrap With Agent)

- File id `1t_suhhfbwzZg_pCDXg_QrUkafqMsh7Io`, created and modified 2026-09-17T00:23:38Z, 8,611 bytes, owner jkkelley86@gmail.com, in folder `1OflD-qTSq7VARvf7eDcE24zWB9_uA6C2`.
- Sibling files in the folder: `BOOTSTRAP-SUPERVISOR-PROMPT.md` (id `1ENi8LnewYdoRDFIzs3dYIGmI7TIlhVS2`), `COMPACT.md` (`13Mb05Co705eGgaKAtqYGgrJbpWgdciOe`), `model-routing-policy.json` (`1C-lWcgs1O_vEhxdUWza4Vk37BgEEmVGh`), `agent-spec.json` (`176KkUoifC-oLZT11xcxRefTJKhr3ZkEk`); the folder listing has a further page I did not open.
  `launch-message.min.json` was not in the first page of the listing.
- Parent blueprint: Google Doc "START HERE - Bootstrap With Agent Blueprint v0.1.0" (id `1L2D-xaqBxxbpnNBh4jbxUenawOAo-l6udd_RnAFKEx4`, 582,005 bytes, created 2026-09-17T00:22Z).
  I did not read it: it is 582 KB and the proto, the supervisor prompt and the compact context already state the design.
- Package `bootstrap.control.v1`, `go_package = "github.com/jkkelley/bootstrap-with-agent/gen/go/bootstrap/control/v1;controlv1"`.
  That GitHub repo does not exist (`gh repo view jkkelley/bootstrap-with-agent`: "Could not resolve to a Repository"), and no local file contains `bootstrap-with-agent` or `BWA-REL` (grep over `~/projects`, `~/Documents`, `~/tools`, `~/.local/state/stable`, `~/dotfiles`).

### 3.6 Google Doc "31 gRPC Go Rust and requirements driven tooling"

- Id `1UMHjoU-su0Ufjsu3ZAcc2HVodaefYwg_m1OT9D0f5LY`, created 2026-09-16T01:18:12Z, in the "Systems Architect" project folder `1M01-vsUQcnncxtorUDEgVTj8dJYcbj1G`, 2,883 bytes.

### 3.7 lucaGazzola/forgeo

- GitHub `lucaGazzola/forgeo`, public, MIT, not the owner's.
  Description: "A scheduled, agent-driven software factory. Keep a plain JSON backlog; Forgeo runs your coding agent (Claude Code, Codex, opencode) on each task and commits to main. Refactors when idle. No branches, no PRs."
- Clone (made by L12): `.../investigation/clones/forgeo`, HEAD `5766da1` (2026-09-30 21:41 +0200), 50 commits, all on 2026-09-30, one author (Luca Gazzola), package `forgeo-cli` version 1.12.1, classifier "Development Status :: 3 - Alpha", Python 3.11+ (`pyproject.toml`).
  GitHub search metadata lists the repo as pushed 2026-09-30 and the coordinator reports an update on 2026-10-09; the local clone's last commit is 2026-09-30.
- Size: 14,050 lines of Python in `src/forgeo/` (largest `cli.py` 3,063, `central.py` 1,515, `backlog.py` 1,096), 27,679 lines with tests.
- Dependencies: pydantic, rich, PyYAML only (`pyproject.toml` lines 18-22).

### 3.8 Other owner Go repos and searches that came back empty

- Owner repos whose primary language is Go (from `gh repo list jkkelley --limit 300`, 196 repos): rime (2026-10-06), bearings-core (2026-09-20), yieldpoint-ai-platform (2026-07-23), yieldpoint-client-provisioner (2026-07-21), prospector-events (2026-07-07), job-hunter and job-hunter-api (2026-06-01), prospector-scraper (2026-05-08), prospector-go-scraper (2026-05-02), golang (2021-12-08).
  gatehouse-click is labelled Shell but has a Go `go.mod` (`gatehouse.click/gatehouse`, go 1.26.0, client-go, go-oidc, no gRPC).
- Only rime among them has `google.golang.org/grpc` in a root `go.mod` (`gh api repos/jkkelley/<repo>/contents/go.mod`, grep count 1 for rime, 0 for the rest checked: bearings-core, gatehouse-click, prospector-events, yieldpoint-ai-platform, yieldpoint-client-provisioner, job-hunter, job-hunter-api, prospector-scraper, prospector-go-scraper, golang; yieldpoint-ai-orchestrator, yieldpoint-ai-auth and yieldpoint-ai-pkg-core have no root `go.mod`).
- `.proto` files owned by the owner on this machine: `/home/luna/projects/rime-gate-proof/proto/rime/v1/*.proto`, the clone of rime, and `/home/luna/projects/coq-jev-herdr-plugin/scheduler/api/scheduler/v1/scheduler.proto`.
  GitHub code search `extension:proto user:jkkelley` returned total_count 0 (the search index does not cover private repos, so this is not proof of absence).
- Empty results, with the commands:
  - `gh api 'search/code?q=forgeo+user:jkkelley'` returned 0.
  - `gh api 'search/code?q=forge-o+user:jkkelley'` returned 0.
  - `grep -il 'grpc\|golang\|goroutine\|forgeo' ~/.claude/projects/*/memory/*.md` returned nothing: no memory file mentions Go, gRPC or forgeo.
  - `grep -il 'forgeo\|grpc' ~/.zsh_history ~/.bash_history` returned nothing.
  - `find /home/luna -iname '*forgeo*'` found only this investigation's own L12 file and the clone.
  - `~/Documents/herdr` and `~/Documents/investigations` contain no `grpc` string.
  - `git log --all -S forgeo` on the main checkout returned one commit, `b7a3c5d` (2026-10-13, Factory Rebuild Plan, #182), whose only match is the plan's own deliverable name `05-FORGEO.md`; `-S forge-o` returned none. No commit holds a forgeo design.
- Starred repos (`gh api user/starred`) and forks (`gh repo list --fork`): none named forgeo or Go control planes.
  The only agent-factory related ones are `kunchenguid/firstmate` (fork and star), `affaan-m/ECC` (fork and star) and `codewhale-hq/Codewhale` (Rust, star).
- `forge-config`, `forge-gitops`, `forge-eks-infra` are Forgejo (git forge) deployments, not a Go control plane (L12 and L10); `cortex-hub` holds the Forgejo design.

## 4. What works

### 4.1 The Go scheduler (SPEC-16)

What is real and tested on main:

- A pinned Go module that builds and tests in Podman only (`scheduler/Makefile`, `scheduler/Containerfile`, RUNBOOK rule 1, `RUNBOOK.md` lines on `make -C scheduler test`).
  CI ran it green: priority list row 0, "main GREEN at 964e464 ... (lint, factory, herdr, scheduler exit 0)" (`20261013025600-priority-list.md`).
- A typed contract in `internal/core/interfaces.go`: `Source`, `Ledger` (claim before act), `Executor` (`Run(ctx, Job) Verdict`, `Health`), `Clock`, `Table`, `JobStore`, `SeatObserver`, `Latches`.
  These are small interfaces with fakes in `internal/testkit/` (`world.go`, `executor.go`, `clock.go`, `records.go`).
- A proto of two services over unix sockets, `Executor` (Run, Health) and `Scheduler` (Health, Status, Reload, Drain, Retry), no streaming (`scheduler.proto` lines 1-30).
- A design that answers the facts the bash belt gets wrong: one loop where "ticks never block on a job" (`SPEC-16-scheduler-overview.xml` line 106), "no LLM in routing, health, retry or cleanup" (line 40, `l-llm`), pure core with injected clock, file system, socket and executor (line 44, `l-pure`), domain loops as goroutines of one binary under one systemd user unit (line 105, `sh-unit`), one Go package per spec and one ticket per package (line 182, `d-rule`).
- Config as variables only, validated by schema in repository lint (`scheduler/config/*.schema.json`, PR 38).
- Git trail of the work: `git log --all -S grpc` on the main checkout lists `2c3ce00` (2026-10-10, WO-20261010-539f cut), `2ceb3c7`/`af01719` (2026-10-12 roadmap), `40825f5` (2026-10-12 design), `fc16622` (2026-10-12 skeleton #39), `667e3d2` (2026-10-13 re-cut #89), `1c56a98` (2026-10-13 graph nodes #100).
  `-S golang` lists `fc16622`, `2ceb3c7`, `af01719`, `db1a95c`; `-S go.mod` lists `dd5268a`, `fc16622`, `d268fe9`, `c22cb99`, `2c11986`, `5e5d902`.

The 14 unbuilt tickets, all `ready`, none with a pull request (`work-orders/WO-20261010-329d/WO-20261012-ea33/`):

- `WO-20261012-9790 - Scheduler config package: the loader for scheduler.json and executor.json, variables, no defaults, cross checks at start`
- `WO-20261012-5a3d - Scheduler intake package: roots, id order, the routed ledger with claim before act, the first-start boundary, interrupted ...`
- `WO-20261012-32fe - Scheduler routes package: the table loaded and checked, the first-row match, the plan with ordered job specs, the wake line and the receipt shape`
- `WO-20261012-7a9a - Scheduler job package: the durable store, idempotency keys and unknown-outcome discovery, states and order, backoff, dead ...`
- `WO-20261012-8e69 - Scheduler seat package: names from role labels, the observer with three signals, cap holds, bring-up and down through the ...`
- `WO-20261012-6e43 - Scheduler policy package: the policies table with the break glass refusal, open escalations, the default as a record ...`
- `WO-20261012-3c7a - Scheduler health package: the belt heartbeat from the tick loop, two-signal stalls, latches, executor health, the halt flag ...`
- `WO-20261012-d7f4 - Scheduler executor package: the gRPC server on the host with the verb table, refusals, timeouts and tails, the client ...`
- `WO-20261012-b12c - Scheduler observe package and the status subcommand: JSON log lines per change, the Scheduler gRPC service with Health ...`
- `WO-20261012-1ccf - Scheduler engine and the run, check and retry subcommands: the tick loop composing intake, routing, jobs, seats, policies ...`
- `WO-20261012-fa36 - Scheduler cut-over: shadow mode and its decision files, the parity report and subcommand, going active with the belt pan...`
- `WO-20261012-379f - Scheduler contract tests: every record kind the scheduler emits through the real event writer and its check, every verb ...`
- `WO-20261012-8d87 - Replay fixtures: one golden case per routes row and per policies row under scheduler/testdata/replay ...`
- `WO-20261012-0113 - Scheduler lint and CI wiring: lint/lint.sh runs specs/scheduler/bin/check.sh and the Jenkinsfile runs make -C scheduler ...`
- `WO-20261012-1635 - Scheduler end-to-end acceptance: in a scratch herdr session with a stub agent a pr.opened routes to a seated tester with ...`

Titles above are truncated at the point the ticket file's own title was long; the full titles are in the ticket files.

### 4.2 jkkelley/rime

- Contract `rime.v1`: envelopes, HTTP-shaped numeric status codes (100, 101, 200, 201, 300, 400, 401, 404, 409, 412, 422, 423, 429, 500), typed payloads, protovalidate (`rime-bootstrap/CORE-DESIGN.md` lines 56-73, commit `38adb4a`).
- `internal/store/store.go` (533 lines): SQLite record store with outbox retry and concurrency tests (commit `22646ef`).
- `internal/stream/redis.go` (276 lines): Redis Streams watch with cursor ids, trim detection, drop on full (commit `894b4f4`).
- `internal/transition/transition.go` (297 lines): the ordered-gates transition table with a 422 strike count and supersede routing, 1,009 lines of tests including mutants (commit `994a614`; L09 section 4.2).
- `docs/FAILURE-MODES.md` F-01 to F-20 and ADRs 0001-0004 (`docs/ADR/`).
- Build: `Makefile` Podman targets, `buf.gen.yaml`, `make gen-check` for generated-code freshness.
- Is it the owner's "lightweight Go concurrency with gRPC" design?
  By intent, yes: `CORE-DESIGN.md` line 9 reads "One Go gRPC concurrent system drives everything", and its topology is Bearings page, agents and Herdr all talking to one Go gRPC core with SQLite and Redis behind it.
  By code, no: `grep 'go func'` over non-test code found nothing, and the only importer of grpc outside generated code is `internal/transition/transition.go`.
  `internal/server/doc.go` and `internal/route/doc.go` are two-line stubs, so the gRPC server (ticket A-08 "gRPC server: Submit and Watch wired through auth, store, transition, and stream", `REPLAN.md` line 433) was never written.

### 4.3 jkkelley/bearings-core

- 1,498 Go lines: `cmd/core` (consumes `bearings.tasks`, validates against `schemas/envelope.schema.json`, in-memory task table with lease and fencing token, publishes to `bearings.events`), `cmd/publisher`, `internal/{nats,envelope,schema,task,tracker,metrics}`.
- Concurrency via NATS JetStream consumers, not gRPC.
  Its NATS client was lifted from `jkkelley/prospector-events` with a source header (README Layout).
- It is not the gRPC design the owner remembers, but it is the one with working message-bus code.

### 4.4 Stable v3 Go core

- A plan only: tracks, decisions D-4 (Go and gRPC, approved), D-11 (Go-served plain HTML and JavaScript over SSE, no Rust underneath), D-12 (living map built once in the Go core), and a table of libraries with sources (River for Postgres queues, Casbin for permissions, connect-go, a2a-go).
- It stopped as a Go design because the stable was shut down and replaced: the last stable commit is `4d60e5c` 2026-09-16 and the owner started bearings-core four days later.

### 4.5 Drive control_plane.proto (Bootstrap With Agent, release BWA-REL-2026-09-17-V0.1.0, status PROPOSED)

What the proto defines (read in full, 8,611 bytes):

- Four services:
  - `WorkOrderService`: `GetWorkOrder`, `ListWorkOrders`, `ClaimWorkOrder` (returns a `Lease`), `HeartbeatLease`, `ProposeTransition` (returns `TransitionDecision`), `WatchWorkOrder` (server stream of `WorkOrderEvent`).
  - `EffectService`: `SubmitEffect` (returns an `EffectReceipt`), `ReconcileEffect`.
  - `VerificationService`: `Verify`.
  - `ReadinessService`: `Readiness`, separate from `grpc.health.v1`.
- 15 `WorkState` values (PROPOSED, QUEUED, CLAIMED, PLANNING, AWAITING_APPROVAL, EXECUTING, VERIFYING, BLOCKED, COMPLETED, FAILED, CANCELED, QUARANTINED, REJECTED, ROLLED_BACK).
- Enums `RiskClass` R0 to R3, `EffectKind` (git proposal, terraform plan and apply, Argo sync request, Kubernetes break glass, Jenkins build, secret rotation, rollback), `EffectOutcome` including `UNKNOWN`, and `TruthClass` (desired, observed, verified, derived, unknown).
- Messages for `WorkOrder` (version, policy revision, idempotency key hash, budget, accountability, acceptance checks), `Lease` with a renewal token, `TransitionProposal` with `expected_version` and a transition token, `EffectRequest` with an idempotency key and rollback ref, `EffectReceipt` with desired and observed digests and a signature ref, `Budget` with token, cost, deadline and retry limits.
  What system it belonged to:

- "Bootstrap With Agent" (BWA): a governed bootstrap supervisor.
  `BOOTSTRAP-SUPERVISOR-PROMPT.md` (artifact BWA-AGENT-PROMPT-001, v1.0.0, PROPOSED) makes the supervisor an LLM that proposes work orders and effect requests while a deterministic controller executes them: "Submit an EffectRequest to the deterministic controller", "Treat all queues as at-least-once", "Fail closed on missing policy, signature, owner, evidence, budget", authority chain "User > Lead > Orchestrator > Architect or Designer > Worker > Tester > Reviewer > deterministic gate".
  `model-routing-policy.json` (BWA-MODEL-POLICY-001) routes planning through an LLM gateway to `moonshotai/kimi-k3` via openrouter with a hard cost cap of 2.00 USD per request and no provider credentials to agents.
- Is it the Go gRPC design the owner remembers?
  It is a Go gRPC control plane by intent (the `go_package` option, the four services, the work-order state machine, leases and idempotency), written five days after the stable v3 Go plan and four days before rime.
  It is the most complete gRPC contract the owner has: nothing else on this machine models leases with heartbeats, effect requests with receipts, and unknown-outcome reconciliation as RPCs.
  It is a contract only: no Go code, no repo, and no sign it was built.
  Its work-order and ticket vocabulary (WorkOrder, claim, lease, evidence, acceptance checks, verifier independent of worker) is the same one `rime` and the coq work orders later used, which suggests it fed rime, but I found no document that says so.

### 4.6 Google Doc "31 gRPC Go Rust and requirements driven tooling"

This is the owner's stated policy, not code.
Binding sentences (quoted from the doc, read 2026-10-14):

- "Prefer gRPC with Protobuf for typed internal machine-to-machine RPC, Go for concurrent network services and controllers, and Go or Rust for distributable terminal tools."
- "gRPC streaming alone is not a persistent job queue." Use a durable event transport when work must survive disconnection, replay or consumer downtime.
- Every RPC needs authenticated workload identity, per-method authorization, a propagated deadline, cancellation, trace context, status mapping and idempotency semantics. "A deadline failure does not prove a side effect never happened: reconcile operation status by stable idempotency key before replaying a mutation."
- Go profile: "cancellation-aware goroutines, bounded worker pools ... Do not start one unbounded goroutine per queued item. Test data races and goroutine leaks".
- "Keep protocol handling, polling, retries, filtering and state transitions deterministic."
  This is the clearest written source of "lightweight Go concurrency with gRPC" as a preference, and it is the written rule behind designs 1 to 5.

### 4.7 lucaGazzola/forgeo

What it is, checked in the clone:

- Language: Python only. There are no Go files, no `go.mod`, no `.proto`; `grep -i grpc` over the tree finds nothing; concurrency is `asyncio` plus `asyncio.to_thread` and a few `threading.Lock`s (`src/forgeo/git.py`, `backlog.py`, `oauth.py`).
  There are no goroutines and no gRPC, so it is not a "Go concurrency with gRPC" system.
- Scheduler model: a daemon wakes every `interval_minutes`, picks the oldest runnable `OPEN` task whose dependencies are all `COMPLETED` or whose `run_at` has passed (`docs/backlog.md` lines 108-133), runs one agent at a time ("One agent per Forgeo: backlog.lock prevents a second start/once", `docs/agent-contract.md`, Concurrency).
  A run that overruns the interval is never killed; the next cycle is skipped.
- Backlog model: a JSON file (`.forgeo/backlog.json`) or an issue provider (GitHub, GitLab, Jira, HTTP) with statuses OPEN, REVIEW, BLOCKED, COMPLETED, FAILED (`docs/backlog.md` lines 34-74).
- How it runs an agent: any shell command with the task in `FORGEO_TASK`; exit code decides the outcome: 0 commit and push, `no_changes_exit_code` (3) complete without commit, `blocked_exit_code` (2) BLOCKED with partial commit, anything else discard (`git reset --hard`, `clean -fd`) and FAILED (`docs/agent-contract.md`, Exit codes).
  Optional Docker sandbox with `network: none` by default (`README.md` Docker sandbox).
- Retries: `failed_retry_max` and `failed_retry_wait_cycles` (a retry is a later cycle, not a backoff in seconds), `no_changes_retry_max`, per-task `retries_left` (`docs/configuration.md` lines 37-39, `docs/backlog.md` lines 83-94).
  BLOCKED is never auto-retried.
- Timeouts: `agent_timeout_seconds`, unset by default; per-task override (`docs/configuration.md` line 23, `docs/backlog.md` line 42).
- State: plain files (`backlog.lock`, `backlog.run`, `runs.jsonl`, snapshots) in `state_dir`; for remote backlogs the engine state lives in issue labels and a hidden comment block.
- What it does not do:
  - No test gate or reviewer role of its own: the only gate is the agent's own exit code (`src/forgeo/check.py` runs configured gate commands, but there is no independent verifier).
  - No pull requests: default commits straight to main; `review_mode: branch` pushes a branch and waits for a human to merge and click Complete (`docs/backlog.md` lines 77-81).
  - No parallelism: one task at a time per repo; a second repo needs a second instance.
  - No DAG beyond `dependencies`, no fan-out, no queue, no cluster or pod awareness, no idempotency keys, no leases or heartbeats.
- License MIT. Maturity: alpha classifier, 50 commits in one day (2026-09-30), the log is entirely `refactor: inline single-use ...` commits, one contributor, no tags examined.
- Verdict as a control plane candidate for this factory: no.
  It is a single-repo, single-agent, cron-style loop that commits to main, which is the opposite of this factory's rules (small PRs, test and review gates, 4 to 16 seats at once, one merge owner).
  Against Argo Workflows (DAG, retries with backoff, timeouts, artifacts, parallel pods) and Kubernetes Jobs (`backoffLimit`, `activeDeadlineSeconds`, `ttlSecondsAfterFinished`) it has strictly fewer of the features that matter.
  The one idea worth reading is its exit-code contract (0, 2 blocked, 3 no change, else discard), which maps onto the seat contract of S04 and the rime status codes.
- Name check: `forgeo` appears in none of the owner's repos, notes, memory files or shell history before 2026-10-14 (section 3.8), and the owner has typed Forgejo correctly at least five times (L12).
  The sentence "i have forgeo already" is therefore not explained by any file the owner owns.
  The best-supported reading is that the owner is recalling the Go gRPC system (rime or the SPEC-16 scheduler) under a different name, or recalling Forgejo; the public Python project is a coincidence of spelling.
  This is a judgment; the evidence does not settle it.

## 5. What broke and why

### 5.1 Why the Go scheduler is not running (evidence per step)

1. Ordered and designed in a day.
   Owner order 2026-10-12T18:34Z (`p-order`, ticket `WO-20261012-ea33` created_at 2026-10-12T18:35:49Z).
   A Fable architect and four Opus workers produced PR 37 at 19:41Z (42 files) and the skeleton merged at 20:23Z (PR 39).
2. Halted before it was built.
   The line was halted 2026-10-12 20:42Z (record `20261012T204509Z-200-cx2xw`, quoted in `history.jsonl` 2026-10-12T21:59Z); `20261012222000-retro-architect-flood-and-halt.md` lists the cause as architect flood (watches copying every record to the architect, git as message bus, architect as gate, no halt command).
   `ROADMAP.md` lines 62-73: C15 dropped NATS, C16 ordered PR 37 revised before merge, and "the scheduler team kept up and idle until its design is revised".
3. Redesigned in review instead of built.
   The 14 build tickets were never started; PR 37 was closed 2026-10-13T13:06Z and re-cut one file per pull request under the owner's rule "tickets are small" (`SPEC-16-scheduler-overview.xml` line 250, `w-land`, owner 2026-10-13T03:00Z).
   Only four of the twelve spec files have landed on main after about 30 hours (overview, config schema, toolchain, graph nodes).
4. The line stayed on bash and its own repair work took the slots.
   The priority list (`20261013025600-priority-list.md`) puts the engine in P2 behind the CI gate, test speed, verify node and the system loop; `SPEC-17-orchestrator-and-agent-health.xml` s-crosswalk (lines 297-310) names the bash belt "now" and the Go scheduler "later" and records contradictions X01 to X12 between the two designs, including X09 "the bus: SPEC-16 overview l-bus names NATS JetStream; card C15 drops it".
5. Stale decision records still contradict the plan.
   `graph/nodes/DEC-nats-jetstream-grpc.json` is still status `locked` on main (introduced `bec8276`, 2026-10-10) while `AGENTS.md` line 119 and `ROADMAP.md` C15 say NATS is deferred; `DEC-scheduler-go-podman.json` is still `proposed`; PR 35 (factory design spec v2.0, open since 2026-10-12T18:28Z, `specs/exports/factory-spec.xml` line 257, rule S2-051) still states "NATS JetStream carries records ... gRPC only the synchronous control plane" and does not mention the Go scheduler.
   Ticket `WO-20261010-539f - NATS JetStream is the producer-consumer bus and gRPC the control plane: amend SPEC-03, stand up the bus, port the queue` was cancelled 2026-10-13 by duplicate-audit ruling F6 (`work-orders/archive/2026/WO-20261010-539f-...md`, Outcome), "superseded by WO-20261012-be64".

### 5.2 Why the earlier Go designs stopped

- Stable v3 Go core: no record of a decision to drop it.
  The stable repo's last commit is `4d60e5c` 2026-09-16 and its Go plan has no code; the next Go work is bearings-core on 2026-09-20.
  An honest statement: no document I found says why stable-core was not built.
- Bootstrap With Agent proto: no record at all of what happened to it after 2026-09-17.
  The Drive files were created in one minute (00:22Z to 00:23Z), the `bootstrap-with-agent` repo was never created, and four days later the owner started `jkkelley/rime` with the bootstrap-style names (`rime-bootstrap`).
- bearings-core: superseded the next day by rime; rime `docs/ADR/0002-sqlite-plus-redis.md` and `CORE-DESIGN.md` line 138 say "no message broker beyond Redis Streams" (L09 section 5).
  The reason for dropping NATS is not stated in either file.
- rime: owner halted the loop 2026-10-06T11:41Z; the ledger does not record a reason (`EXECUTION-LEDGER.tsv` row 503, `~/.local/state/rime/PAUSED` reads 2026-10-06T11:41:11Z).
  Evidence of why confidence fell is the loop-repair ratio: 32 loop-fix commits against 17 product commits, 6 merges in the first 424 minutes and none in the last 364 (L09 section 5.2).
  The gRPC server was ticket A-08 and the cause of its absence is the same slow run: the repo reached the store, stream and transition table (A-15, A-17, A-19) and the contract (A-13) before the owner stopped the loop.
  The Go code did not fail; the bash and LLM loop that was building it did.

### 5.3 What the pattern shows

Every Go and gRPC design failed to run for the same reason: the system that was supposed to build it was the very bash-and-LLM line it was meant to replace.
The Go core has never been built by a system that does not need the Go core.
That is a judgment from the five rows in section 2, not a quote from any record.

## 6. Waits, polls, sleeps and leases

Not a local-factory area, but these are the waits in the Go designs, as designed and not yet running:

- SPEC-16 loop: one tick, "ticks never block on a job" (`SPEC-16-scheduler-overview.xml` line 106); jobs retried with backoff and a dead state (ticket `WO-20261012-7a9a`, SPEC-16.D); every wake confirmed rather than assumed (`DEC-scheduler-go-podman` text, `CMP-scheduler`).
- Executor call: `RunRequest.timeout_seconds` per call, `idempotency_key` for replays (`scheduler.proto`).
- Control plane has no streaming call, so no long-held stream (`scheduler.proto` header, `h-proto-stream`).
- rime: heartbeats every 5 minutes and 15-minute silence detection (`FAILURE-MODES.md` F-09, L09 section 4.3), token TTL in Redis.
- Drive proto: leases with a renewal token and `HeartbeatLease`, `Budget.effect_timeout`, `retry_max` and a deadline.
- forgeo: a single wall-clock interval, a lock file and a run marker; no heartbeat.

## 7. Decisions an LLM makes that a rule could make

This area is design history, but one result bears on it: every one of the five Go designs moves routing, retries, stall detection and merging from an LLM seat to code.
The rule is stated in SPEC-16 `l-llm` ("No LLM in routing, health, retry or cleanup"), in Drive doc 31 ("Keep protocol handling, polling, retries, filtering and state transitions deterministic"), and in the Drive supervisor prompt ("Fail closed ... Do not self-approve").
Details of the current decisions live in L13.

## 8. What to carry forward

Judged against Argo Workflows and Kubernetes Jobs as the shelf alternatives (the shelf facts come from L10 and S01 and are not re-researched here).

Carry:

- The contract of `control_plane.proto`: a work order with `version` and `expected_version`, a `Lease` with heartbeat and renewal token, `ProposeTransition` returning an accepted or refused decision with unmet gate ids, and `EffectReceipt` with desired and observed digest.
  Argo and Jobs do not give these; they schedule pods, they do not own the ticket state machine, fencing or independent verification.
  Use it as the schema of the ticket and seat record whatever runs the pods.
- The rime transition table (`internal/transition/transition.go`, 297 lines, tests with mutants) and the status-code vocabulary; the codes already survived into `events/schema/event.schema.json`.
- The SPEC-16 shape: pure core, injected clock, ledger with claim-before-act, executor with an allowlisted verb table and idempotency keys (`scheduler/internal/core/interfaces.go`, `scheduler.proto` Executor service).
  This is the part Argo and Jobs do not provide: a thing that acts on herdr panes and seat scripts, which are not pods.
- The testkit pattern (fake clock, fake executor, replay fixtures from `routes.json`): it is what lets the belt be replaced without running the line.
- Doc 31's rules as the checklist for any control plane: deadlines, idempotency, bounded queues, "gRPC streaming alone is not a persistent job queue".
- forgeo's exit-code contract (0, 2, 3, else discard) as the seat result code set, for comparison with rime's.

Recommendation on the control plane shape (judgment, with the reasons):

- For DAG ordering, retries, timeouts, fan-out, parallel workers and pods per agent step, use Argo Workflows and Kubernetes Jobs where the cluster already runs them or can (L10, S01, S02 findings).
  A Go scheduler written from scratch would have to re-implement DAG execution, backoff, activeDeadline, pod lifecycle and a UI: 14 tickets and four spec domains to match what `Job.backoffLimit`, `activeDeadlineSeconds` and an Argo `retryStrategy` give declaratively.
- Keep Go only for the gap the shelf leaves: the executor that drives herdr seats, and the ledger that owns ticket state and verification.
  The SPEC-16 plane that is a unix socket between a container and a host pane exists to isolate the scheduler from the host; Argo and Jobs make that boundary a pod and an RBAC rule.
- Goroutines are not what the owner's pain needs.
  The slow parts documented elsewhere (tester stalls of 14 minutes, 20-minute herdr suite, per-seat bring-up waits) are waits on external processes, and a Go loop waits on them exactly as bash does unless it can run them in parallel pods, which is the shelf's strength.
  This is a judgment, with the supporting numbers in the priority list (`20261013025600-priority-list.md` rows 00 and 0a).

## 9. What to kill

- The 14 SPEC-16 build tickets as written, unless the owner picks a Go scheduler: they spend a week (`ROADMAP.md` line 143, "phase 4 about a week") rebuilding intake, routing, retries and health that Argo, Jobs or a small ledger service give.
  Re-cut only the executor, ledger and verification packages if Go is kept.
- The NATS decision node left at `locked` (`graph/nodes/DEC-nats-jetstream-grpc.json`) while the roadmap defers it, and PR 35's rule S2-051: one source of truth for the bus.
- forgeo as a candidate: wrong language, wrong shape, one author, commits straight to main.
- Any further Go control-plane design document before one Go piece runs: five designs in 28 days, none running (section 2).

## 10. Open questions for the owner

1. Which Go design do you mean by "forgeo": rime (the 2026-09-21 Go gRPC central system), the SPEC-16 scheduler, or the public Python project lucaGazzola/forgeo?
   The answer decides whether the rebuild reuses rime's contract and transition table, finishes SPEC-16, or starts from Argo and Jobs.
   (Only this question changes the design; the others in the audit are about tickets.)

## 11. Sources

Local files (all read 2026-10-14 UTC):

- `/home/luna/projects/coq-jev-herdr-plugin/scheduler/` (go.mod, Makefile, RUNBOOK.md, api/scheduler/v1/scheduler.proto, internal/core/interfaces.go, internal/cli/registry.go, cmd/scheduler/main.go)
- `/home/luna/projects/coq-jev-herdr-plugin/specs/scheduler/SPEC-16-scheduler-overview.xml`, `SPEC-16.G-config-schema.xml`; branch `origin/feat/go-scheduler-design-one-xml-spec-per-domain-unde`
- `/home/luna/projects/coq-jev-herdr-plugin/ROADMAP.md`, `AGENTS.md`, `specs/SPEC-17-orchestrator-and-agent-health.xml`, `graph/nodes/DEC-*.json`
- `/home/luna/projects/coq-jev-herdr-plugin/work-orders/WO-20261010-329d/WO-20261012-ea33/` and `work-orders/archive/2026/WO-20261010-539f-*.md`
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/` (`20261013025600-priority-list.md`, `20261012222000-retro-architect-flood-and-halt.md`, `20261013-duplicate-work-audit.md`)
- `/home/luna/.claude/history.jsonl` (owner messages 2026-09-12, 2026-09-14T14:11Z, 18:28Z, 2026-09-21T01:18Z, 01:23Z, 2026-10-14T02:45Z)
- `/home/luna/tools/bearings-v2/CORE-DESIGN.md`, `DESIGN.md`, `REPLAN.md`
- `/home/luna/.local/state/stable/research/2026-09-14-go-control-plane/`, `2026-09-14-rust-vs-go-underneath/`, `/home/luna/.local/state/stable/decisions/2026-09-14-round-1.jsonl`, `round-4.jsonl`
- Clones under `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/`: `rime`, `bearings-core`, `stable`, `forgeo`
- Other investigation files: `L09-earlier-factory-iterations.md`, `L12-forgeo.md`

Git commands run on `/home/luna/projects/coq-jev-herdr-plugin`: `git log --all --format='%h %ad %s' --date=short -S grpc`, `-S golang`, `-S go.mod`; `git show origin/feat/factory-design-spec-v2-0-every-agent-workflow-ru:specs/exports/factory-spec.xml`.

GitHub (read 2026-10-14): `gh repo list jkkelley --limit 300`; `gh pr view 35`, `gh pr view 37`; `gh api repos/jkkelley/<repo>/contents/go.mod`; `gh api 'search/repositories?q=forgeo'` (732 results, top relevant `lucaGazzola/forgeo`, pushed 2026-09-30); `gh api user/starred`.

Google Drive (read via Drive MCP 2026-10-14): `control_plane.proto` (`1t_suhhfbwzZg_pCDXg_QrUkafqMsh7Io`, 2026-09-17), `BOOTSTRAP-SUPERVISOR-PROMPT.md` (`1ENi8LnewYdoRDFIzs3dYIGmI7TIlhVS2`), `COMPACT.md` (`13Mb05Co705eGgaKAtqYGgrJbpWgdciOe`), `model-routing-policy.json` (`1C-lWcgs1O_vEhxdUWza4Vk37BgEEmVGh`), Google Doc 31 (`1UMHjoU-su0Ufjsu3ZAcc2HVodaefYwg_m1OT9D0f5LY`, 2026-09-16).
Not read: the Blueprint v0.1.0 doc (`1L2D-xaqBxxbpnNBh4jbxUenawOAo-l6udd_RnAFKEx4`, 582 KB), `agent-spec.json` (`176KkUoifC-oLZT11xcxRefTJKhr3ZkEk`), `launch-message.min.json` (not found in the first listing page).
