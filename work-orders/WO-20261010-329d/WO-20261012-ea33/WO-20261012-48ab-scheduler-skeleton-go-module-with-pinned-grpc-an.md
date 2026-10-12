---
{
  "id": "WO-20261012-48ab",
  "slug": "scheduler-skeleton-go-module-with-pinned-grpc-an",
  "title": "Scheduler skeleton: Go module with pinned gRPC and protobuf, Makefile and Containerfile that build and test only in Podman, the core contracts and testkit of SPEC-16, the executor proto with its generated code, and the subcommand registry",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:36:48+00:00",
  "parent": "WO-20261012-ea33",
  "branch": "feat/scheduler-skeleton-go-module-with-pinned-grpc-an",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect: lavish is prohibited for Claude seats; cut from SPEC-16 by the scheduler architect with disjoint files and a generated test plan; owner order on the bearings page 2026-10-12 18:34Z, CRITICAL",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-5a3d",
    "WO-20261012-32fe",
    "WO-20261012-9790",
    "WO-20261012-d7f4",
    "WO-20261012-8e69",
    "WO-20261012-7a9a",
    "WO-20261012-6e43",
    "WO-20261012-3c7a",
    "WO-20261012-b12c",
    "WO-20261012-0113"
  ]
}
---

# WO-20261012-48ab - Scheduler skeleton: Go module with pinned gRPC and protobuf, Makefile and Containerfile that build and test only in Podman, the core contracts and testkit of SPEC-16, the executor proto with its generated code, and the subcommand registry

## Contents

- Problem
- Scope
- Degrees of freedom
- Acceptance criteria
- Test plan
- Assumptions
- Open questions
- Notes
- Outcome

## Problem

Nothing can be built against the scheduler design until the shared contracts exist as Go: every domain package imports core and testkit, every wave needs make targets that run in Podman, and the executor contract needs its generated code checked in.

## Scope

**In**

- Owns: scheduler/go.mod, scheduler/Makefile, scheduler/Containerfile, scheduler/.dockerignore, scheduler/cmd/, scheduler/internal/core/, scheduler/internal/cli/registry.go, scheduler/internal/cli/version.go, scheduler/internal/testkit/, scheduler/api/, scheduler/tests/Containerfile
- scheduler/go.mod pinning google.golang.org/grpc and google.golang.org/protobuf and nothing else outside the standard library (SPEC-16.H h-build-deps)
- scheduler/Makefile targets build, test (PKG=./... overridable), lint, image, proto, run, run-exec, status, clean, every one a podman run of the pinned Go image or the test image (SPEC-16.H h-build-targets); the module cache in a named volume
- scheduler/Containerfile: two stages per SPEC-16.H h-image, digests pinned; scheduler/tests/Containerfile: the pinned Go image plus bash, jq and shellcheck (SPEC-16.K k-images)
- scheduler/internal/core: every type and interface of SPEC-16 s-contracts (Record, Row, Plan, JobSpec, Job, Verdict, Seat, Source, Ledger, Executor, Clock, Table, JobStore, SeatObserver, Latches) plus Counters and StatusSnapshot for the status answer (SPEC-16.I i-status)
- scheduler/internal/testkit: FakeExecutor, World, Clock and the record builder of SPEC-16.K k-testkit, with their own tests
- scheduler/api/scheduler/v1/scheduler.proto exactly as SPEC-16.H h-proto states, generated once in the build container, the generated files checked in
- scheduler/cmd/scheduler/main.go calling the cli package's dispatch; scheduler/internal/cli/registry.go with init-time registration and a version subcommand (SPEC-16.H h-cli)

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- any domain package, any subcommand but version
- the config files (another ticket) and the host wrappers (another ticket)

## Degrees of freedom

- [free] Go package and file names inside the directories owned, as long as the package names match SPEC-16.H h-layout-pkgs
- [free] the exact Makefile recipe lines, as long as every target runs in Podman and nothing on the host

## Acceptance criteria

- [x] `AC-H1` *(human)* make -C scheduler build, test, lint and image each exit 0 and each runs inside a podman container (the recipe shows podman run; nothing invokes go on the host)
  - observed `2026-10-12` 2026-10-12 UTC in ~/.cache/wt-sched-w1: make -C scheduler build, test, lint and image each exit 0. Every Go command is a podman run of golang@sha256:116d58cb (build, lint, proto) or localhost/coq-scheduler-test:1 built FROM it (test); test and lint run --network=none -e GOPROXY=off. build: file reports dist/scheduler ELF 64-bit statically linked. image: 1.6 MB scratch image, user 65532, entrypoint /scheduler; 'version' answers and --entrypoint /bin/sh fails, checked inside the target.
- [x] `AC-H2` *(human)* scheduler/internal/core declares every type and interface named in SPEC-16 s-contracts with the fields listed there, and nothing a domain spec does not name
  - observed `2026-10-12` scheduler/internal/core declares Record (every c-record field, Attempt 1 when absent), Ref and ErrUnreadable (SPEC-16.A a-source), Row with Match and its Canonical identity (c-row), Plan with PlanVerdict routed/ignored/unrouted/own/unreadable (c-plan), JobSpec and Job with JobState and JobKey (c-job, 16.D d-states, d-idem-key), Verdict (c-verdict), Seat with SeatStatus (c-seat), the eight interfaces Source, Ledger, Executor, Clock, Table, JobStore, SeatObserver, Latches, plus Counters and StatusSnapshot (16.I i-status). Row deliberately has no When/Supersede: routes.schema.json has them but no spec names them.
- [x] `AC-H3` *(human)* the generated code equals a fresh generation (make -C scheduler proto leaves git diff empty) and the proto matches SPEC-16.H h-proto service by service and field by field
  - observed `2026-10-12` make -C scheduler proto && git -C scheduler diff --exit-code exits 0 on the committed tree (protoc 3.21.12 asserted, protoc-gen-go v1.36.12 from go.mod, protoc-gen-go-grpc v1.6.2 pinned in the Makefile); a second regeneration was also cmp-identical. scheduler.proto: package coq.scheduler.v1; Executor Run/Health; Scheduler Health/Status/Reload/Drain/Retry, no streaming; RunRequest, RunResponse, ExecutorHealth, SchedulerHealth, ReloadResponse and RetryRequest field by field as h-proto; StatusResponse carries the i-status counters and lists.
- [x] `AC-H4` *(human)* go test ./internal/testkit passes case k-t1 and the record builder's output is accepted by events/bin/event.sh check
  - observed `2026-10-12` make -C scheduler test PKG='-v ./internal/testkit' passes 9 cases: answers by pattern, refuses, logs calls in order, injects a timeout (scripted and by context), health on demand, clock advances, the builder's 6 records (every optional field, break.glass and policy.applied included) pass the real events/bin/event.sh check ('events ok: 6 files'), and the builder's file equals the real writer's byte for byte apart from id and at.

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The scheduler module skeleton: build and test targets, core, testkit, proto.

**Cases**

- `TP-1`
  - intent: The fakes are trustworthy. (spec case k-t1)
  - command: `go test ./internal/testkit`
  - expected: exit 0: the fake executor answers by pattern, logs calls in order, injects a timeout; the clock advances; the builder writes a record the writer's check accepts
- `TP-2`
  - intent: Built in Podman only. (spec case h-t1)
  - command: `make -C scheduler build`
  - expected: exit 0: a static binary in dist, built inside the pinned Go image; file reports statically linked
- `TP-3`
  - intent: Tested in Podman only. (spec case h-t2)
  - command: `make -C scheduler test`
  - expected: exit 0: go test over the module inside the image with the network off
- `TP-4`
  - intent: Nothing but the binary. (spec case h-t6)
  - command: `make -C scheduler image`
  - expected: exit 0: the runtime image holds one binary and no shell; running it with a shell as the command fails
- `TP-5`
  - intent: the acceptance criterion this command proves, as the ticket states it
  - command: `make -C scheduler proto && git -C scheduler diff --exit-code`
  - expected: exit 0: regenerating the api changes nothing

**Isolation**

- runtime: podman
- image: `docker.io/library/golang@sha256:116d58cbd88c1297624acc6e967a060012422bacf9930927e23fb719189c6f36` (golang:1.26-bookworm, pulled 2026-08)

**Out of scope - CI covers**

- CI runs make -C scheduler test over the whole module on every change under scheduler/
- make lint on the repository validates every config file against its schema

## Assumptions

1. Worker seat: runtime claude, model claude-opus-5-5, effort high (the architect's pick for this epic).
1. The scheduler specs live under specs/scheduler/ on branch feat/go-scheduler-design-one-xml-spec-per-domain-unde until its pull request lands on main; until then read them with git show origin/<that branch>:specs/scheduler/<file>.
1. Go builds and tests run only in Podman through make -C scheduler targets; nothing runs on the host.
1. go.sum is ignored by the repository's .gitignore (that file is in flight in another pull request); versions are exact in go.mod and the builder verifies checksums against the Go checksum database; a later ticket un-ignores go.sum.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro: built and tested only in Podman; every case green on the first full run. Three decisions a later ticket should know. (1) tests/Containerfile adds python3-jsonschema beside bash, jq and shellcheck, because events/bin/event.sh check needs it; breadcrumb in the file. (2) core.Row omits when and supersede, which routes.schema.json gained in WO-20261012-3bb0 but SPEC-16 c-row does not name; the routes ticket WO-20261012-32fe needs them, so that is a question for the architect, not an edit of core. (3) The Makefile has a contract target running tests/contract/run.sh for WO-20261012-379f to own, and status needs STATE_DIR=<dir>; go.mod carries four // indirect requires that go mod tidy adds for grpc, direct requires are grpc and protobuf only.

## Outcome

_Written by `work-order done`. Empty until then._
