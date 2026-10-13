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
    "reason": "owner 2026-10-13 02:41Z (record ay9lm) and 02:50Z (record lvvtd) via the architect: the herdr board is the delivery model and SPEC-16 is the engine; lavish prohibited for Claude seats",
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

After SPEC-17 1.0.0 was accepted (card C25) the owner ruled on 2026-10-13 between 01:15Z and 02:30Z: system and product tickets never mix and run on their own loops (card C26, records 3a18l, 16o3w); a maintenance worker restarts stuck seats and processes and files each cause as a system ticket (cp6cv); systemd user units supervise every line process and the health watch (kvloh); the health design follows the Kubernetes controller pattern; probes are code, never a model's judgement; every build node declares its input and output; the idle limit is one minute and seats come up on demand; every playbook ends with post the result record, then down yourself (3h4ih); the spec opens with a hierarchy tree and a flow diagram the owner can see live on the factory board. Card C27 (gxmaw) froze pull request 84 to its review fixes and asked for one follow-up design ticket holding all of it, running beside K1 and never before it. The research of 2026-10-13 at $COQ_STATE/plans/2026/10/20261013021500-best-practices-agent-line.md is the reference. A well-formed draft of 1.1.0 is parked outside git at $COQ_STATE/plans/2026/10/20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.xml with a README beside it; it has not been linted and lacks the diagrams, the research adoption and the last rulings. Then two more rulings: at 02:41Z the owner asked for the line on a monitoring board in a herdr pane, with herdr notifying the respective agent when a status changes (record ay9lm), which is the delivery model of this design; and at 02:50Z the owner ruled that the Go scheduler design SPEC-16 (pull request 37, WO-20261012-5826) is the engine and the end state (record lvvtd): the research's reconcilers, probes, reaper, garbage collector and dead man's switch are SPEC-16 domains (A intake, C seats, F health), not new bash or systemd pieces, and systemd only supervises the scheduler binary and the interim bash belt until the SPEC-16.J cut-over. The SPEC-16 revision itself lands as one ticket per file under WO-20261012-5826 on pull request 89, the overview in WO-20261013-c17f.

## Scope

**In**

- the first section after the contents holds two mermaid diagrams: the hierarchy tree (owner, then architect, then orchestrator, then the maintenance worker and the seats of both loops, with the system underneath: the scheduler SPEC-16 as the engine, the interim bash belt beside it until cut-over, the supervisor, bearings stable) and the flow (one node per step with its input, output, owner seat, status codes and the SPEC-16 domain that opens and closes it); both are rendered live on the factory board by a build ticket named in s-build, since report/loop renders mermaid already and is K8's file (WO-20261013-89c7)
- the research adopted and placed: section 9's twelve rules are the target architecture and section 8's table is the inventory of failures, and every rule is placed in SPEC-16 by the rule-to-domain table (columns: rule, SPEC-16 domain and section, status covered or gap, interim script until that domain is active), the first mapping being: 1 record root and atomic writes to A (a-roots, a-ledger, a-writer; gap: lease and attempt count on the record); 2 reconcilers to the one binary's domain loops under one unit (overview s-shape), never one unit per reconciler; 3 seat-up to C (c-caps hold never refuse, c-up, c-absent) with B; 4 the reaper to C (c-down, c-leases; gap: lease expiry and the orphan seat sweep); 5 the per-kind table to B routes rows with D d-attempts and G (gap: start-to-close and heartbeat per kind); 6 seats as jobs to C (down on the output record, the standing seats excepted); 7 liveness to F (f-belt, f-stall, f-latch; gap: the repeat-action fingerprint); 8 retry, backoff and dead letter to D (d-backoff, d-dead, d-confirm); 9 the owner record id on every seat, worktree and process to C c-leases and F f-housekeeping (gap: the orphan sweep of worktrees and processes); 10 symptom alerts to F f-notify and I i-status, i-metrics (gap: unseated records as the alert, idle seats never); 11 the dead man's switch to F f-belt and f-supervisor with the age check on bearings stable outside the line (gap); 12 LLMs do work and rulings only to the overview s-laws; the law of the spec: no LLM and no new bash unit sits in routing, health, retry or cleanup, the scheduler does, and until cut-over the named interim script does
- specs/SPEC-17-orchestrator-and-agent-health.xml version 1.1.0, under 1000 lines, starting from the parked draft with its units and patrol sections rewritten on SPEC-16 as the engine: s-loops (which tickets are system by their top-level epic, two intake labels in A and two capacity budgets in C linted against max_agents, no borrowing, routing by loop, the bootstrap during the drain); s-maintenance (the role: the maintenance worker explains a finding the code raised and files the cause as a system ticket, the reaper in C and the retries in D restart; duties M1 to M6, the maintenance epic, cause codes, a DAG with a checklist per node); s-health as the controller pattern mapped onto F and C (desired state, reconcile loop, liveness and readiness probes, the ladder with backoff and three tries, capacity per loop, exactly one of each) with the h-k8s table naming every piece after its Kubernetes counterpart and its SPEC-16 section, and the rule that probes are code (F's two stall signals plus screen unchanged, idle, blocked words and process count as F config keys) while a model only explains a finding the code raised
- the input-to-output table of the build DAG: one row per node with node, input (the record or artifact that starts it), output (the record that ends it), seat, code and the SPEC-16 domain that opens and closes it; a seat comes up when its input arrives and goes down when its output is posted, nothing in between waits on anyone; the health check is only input present and no output within the deadline (stuck) and output present with the seat still up (down it)
- the one-minute idle limit: C downs a seat idle sixty seconds with no open record or gives it work within the minute, seats come up on demand from the record root, only the standing seats (architect, monitor, orchestrator) stand by; every playbook ends with post the result record, then down yourself (seat.sh --down on its own name), the reaper downs a seat whose output exists and that is still up after one tick, follow-ups re-seat fresh by route (record 3h4ih)
- s-delivery, the delivery model (owner 02:41Z): the board is SPEC-16.I's view (i-board, i-status) rendered live in one herdr pane of the monitoring workspace, every item with its lane, owner seat, status code, age and deadline, read from the record root and never composed by a model; a change of an item's status is the one event, and the scheduler's wake (B routing, confirmed by D d-confirm) is exactly one herdr agent prompt to the seat that owns the item (the owner named in the input-to-output table, by role lane when the seat is not up yet) carrying the item, the record id, the new code and the one next step; delivery is held while that seat is mid-turn or compacting (C c-status busy, or the compaction guard's marker) and made on its next idle, with a deadline after which the item goes to the maintenance lane; codes for queued, held, delivered and undeliverable (seat down or missing: re-seat by route, then deliver); a collapse table shows how the patrol, the rounds and the digest fold into this one mechanism (what each did, which board column and which prompt replaces it) so no agent polls records, no agent is woken for an item it does not own and no summary is written by a model; until B and D are active the interim is one bash notifier script named in the rule-to-domain table
- s-supervision: systemd user units supervise exactly two things, the scheduler binary (SPEC-16.F f-supervisor, H) and the interim bash belt until the J cut-over retires it; no other unit; the compliance officer's patrol (WO-20261013-5b33) is an interim probe that F replaces at cut-over and is listed as such; the chain of watchers: systemd over the binary, the binary over the seats, bearings stable's dead man's switch over the binary's heartbeat, so no agent is the last line
- the shim rule in s-build: a column saying what SPEC-16 already does and what each K ticket keeps: K1 board (WO-20261013-f268) shrinks to a view of the record root and an interim bash board until cut-over; K2 health watch (WO-20261013-ba44) to the interim probe on F's config keys; K3 orchestrator seat (WO-20261013-14f9) keeps rulings only, routing and health are the scheduler's; K4 halt, drain, resume and line check (WO-20261013-f52a) to the flag files F reads (f-halt, f-drain, f-recovery), one mechanism; K5 writer refusals (WO-20261013-f298) stays as A's writer until the executor takes it, its schema aligned to a-validate; K6 owner lane (WO-20261013-b221) stays, the owner page is outside the line; K7 routes and lint (WO-20261013-70c4) stays as B's data; K8 factory board (WO-20261013-89c7) stays as I's view and reads the status answer once active; K9 is the per-file SPEC-16 tickets under WO-20261012-5826 (pull request 89); the revisions of K1 to K8 are follow-up tickets since amend works only on drafts
- the inventory rows H27 to H32 and the research's section 8 table; the cross-walk X14 to X17 to SPEC-16, which is the spine of the spec: every SPEC-17 section names its SPEC-16 domain; s-config; s-tests T16 to T30; specs/SPEC-00-index.xml row for 1.1.0; ROADMAP.md: cards C25, C26 and C27 in the locked decisions, the K rows in the items table including K9, the system-first paragraph, and the 02:50Z ruling that SPEC-16 is the engine and the end state

**Out - non-goals**

- building anything; every build is a ticket cut from this spec after the owner accepts it on a card
- changing the K1 to K8 ticket files on main; their revisions are cut as follow-up tickets
- writing the SPEC-16 revision itself: that is the per-file SPEC-16 tickets under WO-20261012-5826 on pull request 89; this spec cites its sections and takes them as given
- any change to the compliance officer ticket WO-20261013-5b33 beyond citing it as an interim probe
- any change to pull request 84, which is frozen (card C27)
- a notification channel other than herdr agent prompt, and any systemd unit beyond the scheduler binary and the interim belt

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* SPEC-17 1.1.0 validates against spec.xsd, stays under 1000 lines, every pointer resolves and make lint passes in Podman
- [ ] `AC-H2` *(human)* the spec opens with the hierarchy tree and the flow diagram, each a mermaid block with SPEC-16 drawn as the engine layer, and s-build names the ticket that renders both on the factory board
- [ ] `AC-H3` *(human)* every node of every DAG in the spec (bring-up, line, maintenance) has a checklist with proofs and a row in the input-to-output table; every rule of section 9 of the research has a row in the rule-to-domain table with its SPEC-16 section, a status (covered or gap) and the interim script, and no rule is assigned to a new bash or systemd piece
- [ ] `AC-H4` *(human)* every status code names who acts and the retry; every probe is a measurement against a SPEC-16.F or G config key and no probe is a model's judgement; no LLM sits in routing, health, retry or cleanup anywhere in the spec
- [ ] `AC-H5` *(human)* s-delivery defines the delivery model in one section: the board in a herdr pane as I's view, a status change as the only event, exactly one herdr agent prompt per change to the item's owner, held while that seat is mid-turn or compacting with a deadline to the maintenance lane, the collapse table for the patrol, the rounds and the digest, and the interim notifier named
- [ ] `AC-H6` *(human)* s-build carries the shim column for K1 to K8 and the K9 row, and s-supervision names exactly two supervised things
- [ ] `AC-H7` *(human)* the owner reads it on the bearings page and accepts it on a card

## Test plan

```sh
make lint, in Podman through the repository target
```

## Assumptions

1. this ticket starts when pull request 84 merges, because that pull request holds SPEC-17, SPEC-00 and ROADMAP.md; it runs beside K1 and the per-file SPEC-16 tickets and never before K1 (card C27, owner 02:50Z)
1. the parked draft and the research file are its inputs; the draft's units and patrol sections are superseded by the 02:50Z ruling and rewritten, the rest is reused; the draft is deleted from the state root once this ticket's pull request merges
1. herdr agent prompt is the notification channel and herdr agent get the readiness probe (busy or idle); where herdr cannot tell compaction apart from a turn, the compaction guard's session marker in the state root is the second check
1. the SPEC-16 sections cited exist on the pull request 37 branch at 012fa41; if a per-file SPEC-16 ticket renames one, this spec follows the merged name

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
