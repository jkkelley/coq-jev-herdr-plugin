---
{
  "id": "WO-20261012-df2b",
  "slug": "scheduler-host-files-the-pane-wrappers-for-the-c",
  "title": "Scheduler host files: the pane wrappers for the container and the executor, the inbox script, a test harness with a stub binary, and the operations runbook",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:36:59+00:00",
  "parent": "WO-20261012-ea33",
  "branch": "feat/scheduler-host-files-the-pane-wrappers-for-the-c",
  "pr": 41,
  "closed": "2026-10-12",
  "approval": {
    "via": "override",
    "reason": "architect: lavish is prohibited for Claude seats; cut from SPEC-16 by the scheduler architect with disjoint files and a generated test plan; owner order on the bearings page 2026-10-12 18:34Z, CRITICAL",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-fa36"
  ]
}
---

# WO-20261012-df2b - Scheduler host files: the pane wrappers for the container and the executor, the inbox script, a test harness with a stub binary, and the operations runbook

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

The scheduler and the executor live in labelled herdr panes started by wrappers the supervisor can restart; the wrappers, the inbox script the quiet window needs, and the runbook that operates them can be written and tested from the specs before the binary exists.

## Scope

**In**

- Owns: scheduler/host/, scheduler/RUNBOOK.md
- scheduler/host/bin/run.sh: the container in the foreground with every flag and mount of SPEC-16.H h-run read from the config files with jq, nothing typed in
- scheduler/host/bin/run-exec.sh: the executor in the foreground with its config; scheduler/host/bin/inbox.sh DIR TEXT: one UTC-named file per call (SPEC-16.H h-verbs inbox)
- scheduler/host/tests/run.sh with cases that run the wrappers against a stub scheduler binary and a stub podman on the path inside the lint image, asserting the argv (SPEC-16.H h-t7)
- scheduler/RUNBOOK.md with the sections RUN-scheduler-operate names: build and test, bring up, status, modes off shadow active, parity, rollback, when something goes wrong, GOOD and NEVER; contents list first

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- editing herdr/config/monitors.json or herdr/config/herdr.json (the cut-over ticket, once those files are not in flight)
- systemd units (a later row)

## Degrees of freedom

- [free] the stub mechanism in the harness, as long as no real podman or binary runs

## Acceptance criteria

- [x] `AC-H1` *(human)* bash scheduler/host/tests/run.sh prints tests: N passed, 0 failed inside Podman
  - observed `2026-10-12` bash scheduler/host/tests/run.sh at 0415b1c re-execs in Podman (localhost/coq-lint:1, digest sha256:d2f6ded8, --network=none, repo read-only) and prints tests: 5 passed, 0 failed: 00-shellcheck, 01-inbox, 02-run-exec, 03-config-lib, 04-run; no real podman, binary or herdr runs (stub dist/scheduler and stub podman log argv)
- [x] `AC-H2` *(human)* make lint passes shellcheck on every script under scheduler/host
  - observed `2026-10-12` make lint at 0415b1c in localhost/coq-lint:1: shell: shellcheck ok, lint: all ok; shellcheck -S warning covers run.sh, run-exec.sh, inbox.sh, lib/config.sh and the tests; case 00 of the suite runs the same severity with -x so sourced files are followed
- [x] `AC-H3` *(human)* run.sh carries no literal path, host or image digest: every value comes from scheduler/config or the environment variables SPEC-16.H h-run-env names
  - observed `2026-10-12` run.sh reads runtime.image, runtime.memory, runtime.container_name (plain strings), drain_seconds and every path key from scheduler/config/scheduler.json with jq, and passes every ${ENV:NAME} the file references; case 04 greps run.sh code lines for an absolute path, localhost/docker.io/ghcr.io/.local and sha256:<hex> and finds none, and asserts the full podman argv against a rendered fixture
- [x] `AC-H4` *(human)* scheduler/RUNBOOK.md opens with a contents list, has every section RUN-scheduler-operate names, and cites the spec section each step comes from
  - observed `2026-10-12` scheduler/RUNBOOK.md opens with a Contents list matching its headings (checked by diff); it has Build and test, Bring up, Status, Modes: off, shadow, active, Parity, Rollback, When something goes wrong, GOOD and NEVER, and 46 bracketed SPEC-16 section citations, one per step

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The host wrappers, the inbox script and the runbook.

**Cases**

- `TP-1`
  - intent: Host files are tested too. (spec case h-t7)
  - command: `bash scheduler/host/tests/run.sh`
  - expected: tests: N passed, 0 failed: the wrappers and inbox script pass shellcheck and run against a stub binary in the test image

**Isolation**

- runtime: podman
- image: `localhost/coq-lint@sha256:d2f6ded8d64627b8e7c02552431a4205431312d2570f1562313d8d26dc815077` (coq-lint:1, the repository lint image)

**Out of scope - CI covers**

- CI runs make -C scheduler test over the whole module on every change under scheduler/
- make lint on the repository validates every config file against its schema

## Assumptions

1. Worker seat: runtime claude, model claude-opus-5-5, effort high (the architect's pick for this epic).
1. The scheduler specs live under specs/scheduler/ on branch feat/go-scheduler-design-one-xml-spec-per-domain-unde until its pull request lands on main; until then read them with git show origin/<that branch>:specs/scheduler/<file>.
1. The config files come from the config ticket of the same wave; until they land, the harness renders a fixture copy of them from SPEC-16.G.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Evidence update after two corrections. AC-H1: tests: 5 passed, 0 failed again, and the same with PATH holding only bash and a podman shim, so the test-plan command needs nothing on the host but bash and podman (rule 20261012T201732Z-100-239yt; a missing lint image is built with podman build, no make, no dirname). AC-H3: runtime.image is now a name and tag (correction 20261012T201032Z-100-yqm2x); run.sh resolves it with podman image inspect, logs the digest, passes COQ_SCHED_IMAGE_DIGEST and runs <name>@<digest>; case 04 still finds no absolute path, host or sha256 digest in run.sh code. A bulk python replace once rewrote run.sh's header comment as code; cases 00 and 04 caught it before commit.
- `2026-10-12` Retro: the specs had no key for the image, memory limit and container name, so run.sh blocked once (20261012T195358Z-423-8ffcd) until sched-architect answered with runtime.* keys (20261012T200406Z-100-xzrpm); SPEC-16.G 1.1.0 carrying them had not landed on PR 37 when this PR opened, so the fixture follows the answer record. Every host path is mounted at its own path, so no container path is a literal. The exec and run subcommands are assumed to take --config <file>; WO-20261012-d7f4 and WO-20261012-1ccf must match or the wrappers change. No test pane was named for this seat, so the suite ran in the foreground in Podman.
- `2026-10-12` Ownership: this ticket owns scheduler/host/bin/run.sh, run-exec.sh, inbox.sh, scheduler/host/tests/ and scheduler/RUNBOOK.md; scheduler/host/bin/cutover.sh belongs to WO-20261012-fa36 and must not be created here.

## Outcome

_Written by `work-order done`. Empty until then._
