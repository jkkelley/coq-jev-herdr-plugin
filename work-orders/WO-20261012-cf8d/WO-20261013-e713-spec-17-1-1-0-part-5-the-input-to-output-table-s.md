---
{
  "id": "WO-20261013-e713",
  "slug": "spec-17-1-1-0-part-5-the-input-to-output-table-s",
  "title": "SPEC-17 1.1.0, part 5: the input-to-output table, seat lifetime and the one-minute idle limit",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:46:57+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 2026-10-13: bf48 split under the size rule; design read and approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-3f2e"
  ],
  "blocks": [
    "WO-20261013-7951"
  ],
  "files": [
    "specs/SPEC-17-orchestrator-and-agent-health.xml"
  ]
}
---

# WO-20261013-e713 - SPEC-17 1.1.0, part 5: the input-to-output table, seat lifetime and the one-minute idle limit

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

SPEC-17 1.1.0 (WO-20261013-bf48) was one large design ticket; under the size rule it lands one section per pull request on the same file, in order. This part writes the owner's 02:01Z and 02:02Z rules. Inputs: the bf48 scope (archived ticket WO-20261013-bf48), the parked draft $COQ_STATE/plans/2026/10/20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.xml and the research $COQ_STATE/plans/2026/10/20261013021500-best-practices-agent-line.md; SPEC-16 sections cited by their per-file tickets under WO-20261012-5826.

## Scope

**In**

- the input-to-output table: one row per node of every DAG in the spec with input, output, seat, code and the SPEC-16 domain that opens and closes it, and a checklist with proofs per node
- seat lifetime: a seat comes up on its input and leaves after posting its output; stuck is input with no output by the deadline; C downs a seat idle sixty seconds; only the architect, monitor and orchestrator stand by (record 3h4ih)

**Out - non-goals**

- building anything; builds are cut from the spec after the architect approves it (card C29)
- ROADMAP.md; additions there wait for the owner
- sections owned by the other SPEC-17 1.1.0 parts

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* make lint passes, the spec validates and stays under 1000 lines, and every pointer in the new section resolves
- [ ] `AC-H2` *(human)* the architect reads the section and approves it in the owner's place (card C29), with the record id in the pull request

## Test plan

```sh
make lint, in Podman through the repository target; the spec validates against spec.xsd and stays under 1000 lines
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
