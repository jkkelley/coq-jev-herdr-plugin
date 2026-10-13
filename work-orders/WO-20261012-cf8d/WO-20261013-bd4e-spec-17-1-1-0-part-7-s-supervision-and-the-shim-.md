---
{
  "id": "WO-20261013-bd4e",
  "slug": "spec-17-1-1-0-part-7-s-supervision-and-the-shim-",
  "title": "SPEC-17 1.1.0, part 7: s-supervision and the shim column of s-build",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:47:03+00:00",
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
    "WO-20261013-7951"
  ],
  "blocks": [
    "WO-20261013-d101"
  ],
  "files": [
    "specs/SPEC-17-orchestrator-and-agent-health.xml"
  ]
}
---

# WO-20261013-bd4e - SPEC-17 1.1.0, part 7: s-supervision and the shim column of s-build

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

SPEC-17 1.1.0 (WO-20261013-bf48) was one large design ticket; under the size rule it lands one section per pull request on the same file, in order. This part writes records kvloh and lvvtd. Inputs: the bf48 scope (archived ticket WO-20261013-bf48), the parked draft $COQ_STATE/plans/2026/10/20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.xml and the research $COQ_STATE/plans/2026/10/20261013021500-best-practices-agent-line.md; SPEC-16 sections cited by their per-file tickets under WO-20261012-5826.

## Scope

**In**

- s-supervision: systemd user units supervise exactly the scheduler binary and the interim belt until the SPEC-16.J cut-over; the compliance patrol (WO-20261013-5b33) listed as an interim probe; the watcher chain to bearings stable's dead man's switch
- s-build: the shim column for K1 to K8 (what SPEC-16 already does and what each ticket keeps), the per-file SPEC-16 tickets as K9, and the build ticket that renders both diagrams on the factory board

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
