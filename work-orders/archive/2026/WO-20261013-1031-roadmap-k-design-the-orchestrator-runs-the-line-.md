---
{
  "id": "WO-20261013-1031",
  "slug": "roadmap-k-design-the-orchestrator-runs-the-line-",
  "title": "Roadmap K - Design: the orchestrator runs the line and the system checks every agent, written as SPEC-17 with an inventory of every hand fix, a mermaid DAG with a checklist per node and a status code map, lined up with the SPEC-16 scheduler design",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:10:01+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-k-design-the-orchestrator-runs-the-line-",
  "pr": 84,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner cards C23 and C24 on Getting My Bearings 2026-10-13; lavish is prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "specs/SPEC-17-*",
    "specs/SPEC-00-index.xml",
    "ROADMAP.md"
  ]
}
---

# WO-20261013-1031 - Roadmap K - Design: the orchestrator runs the line and the system checks every agent, written as SPEC-17 with an inventory of every hand fix, a mermaid DAG with a checklist per node and a status code map, lined up with the SPEC-16 scheduler design

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

Owner 2026-10-12 23:54Z to 2026-10-13 00:09Z: the chain is owner, architect, orchestrator, system; the architect fixed the line by hand six times in an hour; nobody checks the agents. Cards C23 (K first, doc design first, 'this shit better line up') and C24 (drain the line and design the system first). The global rule 'design first, system first, never by hand' in ~/AGENTS.md governs this design.

## Scope

**In**

- specs/SPEC-17-orchestrator-and-agent-health.xml, valid against specs/schema/spec.xsd: the orchestrator seat's job (re-route refused seats, down finished seats, branch cleanup, verify main after merge, capacity), the system's mechanical checks on every agent (alive, stuck, out of context, at capacity) with 3 retries and graceful recovery, what reaches the architect (rulings only) and the owner (cards), break glass, halt, and the system-up-before-the-line bringup with its own checklist
- an inventory section listing every hand fix and line operation the architect did on 2026-10-12, from the roadmap progress file, each mapped to the rule, seat or system check that replaces it
- a mermaid DAG of the line from cut to verified on main, a checklist on every node, and a status code map (code, meaning, who acts, retry)
- a cross-walk to specs/scheduler SPEC-16 (PR 37): which parts the Go scheduler will own, which the bash belt owns until then, no contradiction left unnamed
- specs/SPEC-00-index.xml row for SPEC-17; ROADMAP.md: item K and the C24 order (drain, design the system, build and check it, then resume)

**Out - non-goals**

- building the orchestrator or the checks (build tickets are cut from this design after the owner reads it)
- editing SPEC-16 files (PR 37 holds them)

## Degrees of freedom

- [free] the spec's internal section layout, as long as every In item has its own anchored section an agent can retrieve on its own

## Acceptance criteria

- [x] `AC-H1` *(human)* SPEC-17 validates against spec.xsd and make lint passes in Podman
  - observed `2026-10-13` specs/SPEC-17-orchestrator-and-agent-health.xml (367 lines) is on main via PR 84 merge d3e5c6a; make lint in Podman on origin/main 964e464 prints 'specs: well-formed + schema ok' and 'lint: all ok'
- [x] `AC-H2` *(human)* every hand fix in the inventory maps to a named rule, seat or check
  - observed `2026-10-13` SPEC-17 s-inventory lists H01 to H26, every 2026-10-12 hand fix, each with 'Replaced by' a named rule, seat or check (halt/resume command, O2-O7 orchestrator duties, checks C1-C5, board lanes, roadmap items A to J)
- [x] `AC-H3` *(human)* every DAG node has a checklist and every status code in the map names who acts and the retry
  - observed `2026-10-13` SPEC-17 s-dag has node sections n-cut through n-card each with a checklist, b-nodes holds the bring-up checklist, and s-codes maps 100 to 503 with who acts and the retry per code
- [x] `AC-H4` *(human)* the owner reads it on the bearings page and accepts it on a card
  - observed `2026-10-13` Owner answered Accept on bearings card C25 at 2026-10-13T00:48:02Z; the coq architect posted record 20261013T004802Z-100-12wlf on this ticket: AC-H4 met

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` SPEC-17 written 2026-10-13 00:50Z by sched-architect: 17 sections, 361 lines, no new graph nodes (graph/ is item L's), SPEC-16 cited by path; make lint all ok in Podman; SPEC-00 row added; ROADMAP.md gains C23, C24, item K and the system-first order.

## Outcome

_Written by `work-order done`. Empty until then._
