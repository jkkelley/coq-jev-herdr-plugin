---
{
  "id": "WO-20261011-e618",
  "slug": "interface-agent-seat-owns-the-bearings-page-owne",
  "title": "Interface agent seat owns the bearings page: owner requests become records and the done line comes from it",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:41+00:00",
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

# WO-20261011-e618 - Interface agent seat owns the bearings page: owner requests become records and the done line comes from it

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

The owner talks to the architect in chat. DEC-interface-agent-owns-bearings says only the interface agent runs bearings and everything transfers at P0 completion; nothing has transferred

## Scope

**In**

- seat.sh brings up the interface-agent seat (roles/interface-agent.json: read only, dontAsk); the bearings stable serve and wait panes move into its tab
- its brief: an owner message on the page becomes a request.forwarded 300 record; a verified 201 or an owner-card 423 becomes one line on the page; on owner request it publishes a SITREP snapshot from report/sitrep/sitrep.sh and a board snapshot from report/loop/out
- the architect stops addressing the owner except through an escalation record; RUNBOOK.md: handing the owner channel to the interface agent

**Out - non-goals**

- the Go SITREP site
- bearings code changes beyond the board route (B0)

## Degrees of freedom

- [free] how the seat watches the page (bearings wait, poll of /state), as long as it is read only and runs in a labelled pane

## Acceptance criteria

- [ ] `AC-H1` *(human)* interface-agent seat up with a read-only permission mode, bearings serve and wait panes in its tab
- [ ] `AC-H2` *(human)* an owner message on the page produces a request.forwarded 300 record within 60 seconds with no architect involvement
- [ ] `AC-H3` *(human)* a verified 201 record produces one line on the page written by the interface agent
- [ ] `AC-H4` *(human)* on owner request the seat publishes a SITREP snapshot built by sitrep.sh and links it on the page
- [ ] `AC-H5` *(human)* RUNBOOK.md lets a fresh reader hand the owner channel to an interface agent on another repo

## Test plan

```sh
herdr/bin/seat.sh --check interface-agent post a test message on the uat page; events/bin/event.sh list --kind request.forwarded
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
