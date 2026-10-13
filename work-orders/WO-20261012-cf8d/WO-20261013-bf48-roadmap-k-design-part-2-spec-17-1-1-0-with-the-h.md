---
{
  "id": "WO-20261013-bf48",
  "slug": "roadmap-k-design-part-2-spec-17-1-1-0-with-the-h",
  "title": "Roadmap K design, part 2: SPEC-17 1.1.0 with the hierarchy and flow diagrams, the two loops of card C26, the maintenance-worker role, the Kubernetes controller model and probes as code, input-to-output nodes, the one-minute idle limit, seats that leave after their output, and systemd supervision",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T02:23:48+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner card C27 (record gxmaw), all four levers; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "specs/SPEC-17-orchestrator-and-agent-health.xml",
    "specs/SPEC-00-index.xml",
    "ROADMAP.md"
  ]
}
---

# WO-20261013-bf48 - Roadmap K design, part 2: SPEC-17 1.1.0 with the hierarchy and flow diagrams, the two loops of card C26, the maintenance-worker role, the Kubernetes controller model and probes as code, input-to-output nodes, the one-minute idle limit, seats that leave after their output, and systemd supervision

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

After SPEC-17 1.0.0 was accepted (card C25) the owner ruled on 2026-10-13 between 01:15Z and 02:30Z: system and product tickets never mix and run on their own loops (card C26, records 3a18l, 16o3w); a maintenance worker restarts stuck seats and processes and files each cause as a system ticket (cp6cv); systemd user units supervise every line process and the health watch (kvloh); the health design follows the Kubernetes controller pattern; probes are code, never a model's judgement; every build node declares its input and output; the idle limit is one minute and seats come up on demand; every playbook ends with post the result record, then down yourself (3h4ih); the spec opens with a hierarchy tree and a flow diagram the owner can see live on the factory board. Card C27 (gxmaw) froze pull request 84 to its review fixes and asked for one follow-up design ticket holding all of it, running beside K1 and never before it. The research of 2026-10-13 at $COQ_STATE/plans/2026/10/20261013021500-best-practices-agent-line.md is the reference. A well-formed draft of 1.1.0 is parked outside git at $COQ_STATE/plans/2026/10/20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.xml with a README beside it; it has not been linted and lacks the diagrams, the research adoption and the last rulings.

## Scope

**In**

- the first section after the contents holds two mermaid diagrams: the hierarchy tree (owner, then architect, then orchestrator, then the maintenance worker and the seats of both loops, with the system underneath: patrol, belt, health watch, supervisor) and the flow (one node per step with its input, output, owner seat and status codes); both are rendered live on the factory board by a build ticket named in s-build, since report/loop renders mermaid already and is K8's file (WO-20261013-89c7)
- the research adopted: section 9's twelve rules and its mermaid control loop are the target architecture (one record root as the single source of truth; small level-triggered reconcilers, one systemd unit each, ticking every 15 seconds; seat-up and reaper; every record kind declaring input, output codes, next kind, start-to-close, heartbeat and max attempts in one table; seats as jobs, one record in and one output record out then gone; liveness by heartbeat or pane change plus a repeat-action fingerprint, checked by script; three retries with exponential backoff and jitter, then dead and one owner card; every seat, worktree and process records its owner record and a garbage collector deletes orphans; symptom alerts on the four signals; a dead man's switch outside the line; LLMs do work and rulings only), and section 8's table is the inventory of failures; the key rule is written as a law of the spec: no LLM sits in routing, health, retry or cleanup, reconcilers are small systemd units
- specs/SPEC-17-orchestrator-and-agent-health.xml version 1.1.0, under 1000 lines, starting from the parked draft: s-loops (which tickets are system by their top-level epic, seats and labels per loop, wip_tickets and seats budgets linted against max_agents, no borrowing, routing by loop, the bootstrap during the drain); s-maintenance (the role, duties M1 to M6, the maintenance epic, cause codes, a DAG with a checklist per node); s-health rewritten on the controller pattern (desired state, reconcile loop, liveness and readiness probes, the ladder with backoff and three tries, capacity per loop, exactly one of each unit) with the h-k8s table naming every piece after its Kubernetes counterpart, and the rule that probes are code (screen unchanged, idle, blocked words, process count) while a model only explains a finding the code raised
- the input-to-output table of the build DAG: one row per node with node, input (the record or artifact that starts it), output (the record that ends it), seat and code; a seat comes up when its input arrives and goes down when its output is posted, nothing in between waits on anyone; the health watch checks only input present and no output within the deadline (stuck) and output present with the seat still up (down it)
- the one-minute idle limit: a seat idle sixty seconds with no work is downed or given work within the minute, seats come up on demand from the board, only the standing seats (architect, monitor, orchestrator) stand by; every playbook ends with post the result record, then down yourself (seat.sh --down on its own name), the health watch downs a seat whose output exists and that is still up after one tick, follow-ups re-seat fresh by route (record 3h4ih)
- s-supervision: every line process and the health watch as systemd user units with restart on failure and a start limit of three, rendered from the repository; the grid slots follow their journals; the compliance officer's one-minute patrol over every screen and every unit, raising candidates by code; the chain of watchers so no agent is the last line
- the inventory rows H27 to H32 and the research's section 8 table, the cross-walk rows X14 to X17 to SPEC-16, s-config, s-tests T16 to T30, and s-build revised: K1 to K8 as they stand on main plus their revisions as follow-up tickets (amend works only on drafts), K9 maintenance worker role, K10 units and patrol, K11 loop seats, K12 the diagrams on the factory board
- specs/SPEC-00-index.xml row for 1.1.0; ROADMAP.md: cards C25, C26 and C27 in the locked decisions, the K rows in the items table, the system-first paragraph

**Out - non-goals**

- building anything; every build is a ticket cut from this spec after the owner accepts it on a card
- changing the K1 to K8 ticket files on main; their revisions are cut as follow-up tickets
- the revision of pull request 37 (SPEC-16), roadmap phase 4
- any change to the compliance officer ticket WO-20261013-5b33 beyond citing it
- any change to pull request 84, which is frozen (card C27)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* SPEC-17 1.1.0 validates against spec.xsd, stays under 1000 lines, every pointer resolves and make lint passes in Podman
- [ ] `AC-H2` *(human)* the spec opens with the hierarchy tree and the flow diagram, each a mermaid block, and s-build names the ticket that renders both on the factory board
- [ ] `AC-H3` *(human)* every node of every DAG in the spec (bring-up, line, maintenance) has a checklist with proofs and a row in the input-to-output table; every rule of section 9 of the research is a clause of the spec with a section pointer or a named exception with its reason
- [ ] `AC-H4` *(human)* every status code names who acts and the retry; every probe is a measurement against a config key and no probe is a model's judgement; no LLM sits in routing, health, retry or cleanup anywhere in the spec
- [ ] `AC-H5` *(human)* the owner reads it on the bearings page and accepts it on a card

## Test plan

```sh
make lint, in Podman through the repository target
```

## Assumptions

1. this ticket starts when pull request 84 merges, because that pull request holds SPEC-17, SPEC-00 and ROADMAP.md; it runs beside K1 and never before it (card C27)
1. the parked draft and the research file are its inputs and the draft is deleted from the state root once this ticket's pull request merges

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
