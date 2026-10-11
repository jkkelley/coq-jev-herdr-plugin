---
{
  "id": "WO-20261011-ceea",
  "slug": "blueprint-page-report-loop-renders-the-system-de",
  "title": "Blueprint page: report/loop renders the system design from graph/ and work-orders/ as done, in flight and coming up, in the board's format, served by bearings at /blueprint",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:40:14+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-ceea - Blueprint page: report/loop renders the system design from graph/ and work-orders/ as done, in flight and coming up, in the board's format, served by bearings at /blueprint

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

The owner asked on 2026-10-11 for the whole system design presented as a blueprint in the loop board's format, showing what is done and what is coming up, reusing the board rather than a new page (DEC-blueprint-first). graph/ holds 109 nodes and GRAPH.mmd but no owner-facing view, and the board shows lines only.

## Scope

**In**

- a second view config report/loop/config/blueprint.json (same schema family) whose collectors read graph/nodes (CMP with defined_in RUN edges, DEC locked, REQ) and work-orders (status per ticket) and derive per component: done, in flight, coming up, missing runbook
- loop.sh renders any view named by config into its own out_dir; the template's station and legend components are reused, not copied; the mermaid of GRAPH.mmd is embedded as one component
- bearings serves /blueprint and /blueprint/data.json beside /board (config, no code outside the route table)
- RUNBOOK section: add a view to another repo by config only

**Out - non-goals**

- editing graph/ content; the page reads it
- a new renderer or a second template

## Degrees of freedom

- [free] grouping of components on the page (by SPEC, by workflow, by status), as long as it is a config choice
- [free] how a component's done state is derived, as long as it is from graph edges and ticket status fields and the rule is written in the RUNBOOK

## Acceptance criteria

- [ ] `AC-H1` *(human)* GET /blueprint 200 shows every CMP node with its state and its RUN runbook link, and every locked DEC; a new node file appears on the page within one watch pass
- [ ] `AC-H2` *(human)* the board page is unchanged pixel for pixel by this ticket (parity test)
- [ ] `AC-H3` *(human)* report/loop suite green with the new cases; make lint green; RUNBOOK documents adding a view by config

## Test plan

```sh
make -C report/loop test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
