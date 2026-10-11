---
{
  "id": "WO-20261011-ceea",
  "slug": "blueprint-page-report-loop-renders-the-system-de",
  "title": "Blueprint page: report/loop renders the system design from graph/ and work-orders/ as done, in flight and coming up, in the board's format, served by bearings at /blueprint",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:40:14+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule; owner order 18:47Z",
    "at": "2026-10-11"
  },
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
- its own local web client server (not bearings): report/blueprint/serve.sh serves the rendered view and data.json on a port from config, with three tiers dev, uat and stable, each its own config, port, out_dir and pane label, started by bringup in labelled panes and checked by recover; promotion dev to uat to stable is a Makefile target that copies a tagged build, never a hand copy
- Makefile targets: render, serve-<tier>, promote-<tier>, test, lint; functional style: small pure collectors (input files in, JSON out) each with its own test; the suite runs in the lint container
- RUNBOOK section: add a view or a tier to another repo by config only; CI runs the full suite and lint on this directory when its files change

**Out - non-goals**

- editing graph/ content; the page reads it
- a second template or renderer; bearings changes beyond nothing

## Degrees of freedom

- [free] grouping of components on the page (by SPEC, by workflow, by status), as long as it is a config choice
- [free] how a component's done state is derived, as long as it is from graph edges and ticket status fields and the rule is written in the RUNBOOK
- [free] the server runtime, as long as it is already in the repo's lint image or python3 stdlib and nothing is installed on the host

## Acceptance criteria

- [ ] `AC-H1` *(human)* GET /blueprint 200 on the dev tier shows every CMP node with its state and its RUN runbook link, and every locked DEC; a new node file appears within one watch pass
- [ ] `AC-H2` *(human)* three tiers serve from three ports and out_dirs by config; make promote-uat and promote-stable move a build forward and the stable page shows the promoted build number
- [ ] `AC-H3` *(human)* bringup.sh --check lists the three server panes ok; recover.sh restarts a killed one
- [ ] `AC-H4` *(human)* the board page is unchanged pixel for pixel by this ticket (parity test); each collector has a unit test; suite and lint green

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

- `2026-10-11` Owner 18:47Z: 'a separate local web client server for that blueprint that mimics the system design and blueprint, automatically updated; it needs a dev uat and stable version. Make files. Functional programming small scope easy testing. Full suite on CICD linting when smartly needed.' Folded into In, Degrees of freedom and ACs.

## Outcome

_Written by `work-order done`. Empty until then._
