---
{
  "id": "WO-20261013-7631",
  "slug": "roadmap-k9-spec-16-revision-on-pull-request-37-t",
  "title": "Roadmap K9 - SPEC-16 revision on pull request 37: the scheduler is the engine and the end state; cards C10 to C18 applied; the SPEC-17 board folded into intake and routing; the research's reconcilers, probes, reaper, garbage collector and dead man's switch placed in the intake, seats and health domains with a rule-to-domain table; systemd over the binary and the interim belt only; and the K1 to K8 shims named",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T02:54:27+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 02:41Z (record ay9lm) and 02:50Z (record lvvtd) via the architect: the herdr board is the delivery model and SPEC-16 is the engine; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "specs/scheduler/*"
  ]
}
---

# WO-20261013-7631 - Roadmap K9 - SPEC-16 revision on pull request 37: the scheduler is the engine and the end state; cards C10 to C18 applied; the SPEC-17 board folded into intake and routing; the research's reconcilers, probes, reaper, garbage collector and dead man's switch placed in the intake, seats and health domains with a rule-to-domain table; systemd over the binary and the interim belt only; and the K1 to K8 shims named

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

On 2026-10-13 at 02:50Z the owner ruled that the Go scheduler design SPEC-16 (twelve specs under specs/scheduler on pull request 37 at 012fa41, the deliverable of WO-20261012-5826, in review since 2026-10-12) is the engine and the end state (record lvvtd, relayed by the architect). It predates cards C10 to C18 of 2026-10-12 (records and intake roots in the state root, seats kept with the merger verifying on main, no NATS, the changelog from pull request titles, the backlog as issues), SPEC-17 1.0.x (the board, the health watch, the orchestrator seat) and the research of 2026-10-13 at $COQ_STATE/plans/2026/10/20261013021500-best-practices-agent-line.md, whose section 9 rules were about to be built as new bash reconcilers and systemd units. The owner wants them placed in SPEC-16's domains instead, systemd kept to the scheduler binary and the interim bash belt until cut-over, and every K ticket whose job the scheduler already does shrunk to a shim. The prepared inventory of spec lines to change for the cards is at $COQ_STATE/archive/2026/10/20261012225500-coq-watch-one-off-scripts-and-logs/sched-backup/pr37-revision-inventory-20261012T2145Z.md. SPEC-17's s-build 1.0.x row K8 named this revision; the cut K8 ticket (WO-20261013-89c7) is the factory board, so the revision is K9.

## Scope

**In**

- cards C10 to C18 applied across the twelve specs from the prepared inventory, each with the card id on the clause it changes: records and intake roots under the state root (A a-roots, G), seats kept with the merger verifying on main (C, B), no NATS (overview s-shape, H), the changelog from pull request titles and the backlog as issues (I, J)
- the SPEC-17 board folded into A and B: the record root is the board, lanes are record kinds, leases live in the routed ledger (a-ledger), pull is routing by route row (B), done and sweep are the ledger's close and housekeeping (F f-housekeeping); K1's bash board becomes the interim and a view
- the research's twelve rules placed in SPEC-16: reconcilers as the domain loops of the one binary under one unit (s-shape, no unit per reconciler); seat-up and the reaper in C (c-caps, c-up, c-down, c-leases; lease expiry and the orphan seat sweep added, a seat downed within one tick of its output record); probes in F (f-stall gains the SPEC-17 measurements as config keys: screen unchanged, idle, blocked words, process count, plus the repeat-action fingerprint); the garbage collector in F f-housekeeping with the owner record id on every seat, worktree and process (C c-leases, H); the dead man's switch as the f-belt heartbeat whose age bearings stable checks outside the line; retry, backoff, dead letter and wake confirmation stay in D; one record root with atomic writes stays in A; the per-kind table (input, output codes, next kind, start-to-close, heartbeat, max attempts) in B routes rows with D and G
- the rule-to-domain table in the overview: one row per rule of section 9 with the rule, its SPEC-16 domain and section, status covered or gap closed by this revision, and the interim script until that domain is active (named by its repository path or by the roadmap item I that moves it into line/)
- F f-supervisor names exactly two supervised things, the scheduler binary (H) and the interim bash belt until J j-retire; every other unit is struck from the design, and the compliance officer's patrol (WO-20261013-5b33) is listed as an interim probe F replaces at cut-over
- the delivery model of 2026-10-13 02:41Z: B's wake is the one herdr agent prompt to the seat that owns the item, D confirms it (d-confirm), C holds it while the seat is busy or compacting (c-status), I's board view is rendered in one herdr pane (i-board, i-status); the patrol, the rounds and the digest collapse into it
- the overview's s-build: a shim column for K1 to K8 saying what the scheduler does and what remains as interim or view (K1 board view and interim, K2 interim probe on F's keys, K3 rulings only, K4 the flag files F reads, K5 the writer until A's executor takes it with its schema aligned to a-validate, K6 stays outside the line, K7 is B's data, K8 is I's view), the K9 row, and the rule that the fourteen unstarted scheduler build tickets are re-cut from the revised specs after the owner accepts them

**Out - non-goals**

- building the scheduler or changing the Go skeleton of pull request 39
- changing SPEC-17 (WO-20261013-bf48 owns it), SPEC-00 or ROADMAP.md (pull request 84 holds them)
- starting or re-cutting the fourteen scheduler build tickets before the owner accepts the revision
- a second pull request for specs/scheduler: the work lands on pull request 37

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* every one of the twelve specs validates against the specs/scheduler XSD through check.sh in Podman, each stays under 1000 lines and generic (no paths, keys or hostnames), every element cites its source, and make lint passes
- [ ] `AC-H2` *(human)* the overview carries the rule-to-domain table with twelve rows, no row assigned to a new bash or systemd piece, every gap row naming the section this revision adds, and every interim row naming a script
- [ ] `AC-H3` *(human)* cards C10 to C18 each appear by id on the clause they change; F names exactly two supervised units; C downs a seat on its output record and on lease expiry; A reads the state root; B's wake is the herdr prompt and I's board is the herdr pane view
- [ ] `AC-H4` *(human)* the s-build shim column covers K1 to K8 and the K9 row, and the fourteen build tickets are listed as to be re-cut
- [ ] `AC-H5` *(human)* the owner reads it on the bearings page and accepts it on a card

## Test plan

```sh
podman run --rm --network=none --userns=keep-id -v "$PWD:/repo:ro,Z" localhost/coq-lint:1 bash /repo/specs/scheduler/bin/check.sh check --repo /repo, then make lint in Podman through the repository target
```

## Assumptions

1. the work lands on pull request 37's branch (feat/go-scheduler-design-one-xml-spec-per-domain-unde, head 012fa41), the deliverable of WO-20261012-5826, so no second pull request holds specs/scheduler; claims.sh start will name pull request 37 as the hold and that hold is this ticket's own target; work-order.sh start cannot adopt an existing branch today, so the orchestrator routes the sched-architect seat onto that branch and that tool gap is filed as a system ticket for the maintenance lane
1. it is startable beside K1 (WO-20261013-f268): it claims only specs/scheduler, which no K ticket touches
1. the written design is the sched-architect's work (design and route only, never Go); the owner accepts the revision on a card before any scheduler build ticket is re-cut

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
