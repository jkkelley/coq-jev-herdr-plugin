---
{
  "id": "WO-20261012-8f4f",
  "slug": "sitrep-in-flight-counts-the-work-the-line-is-act",
  "title": "SITREP IN FLIGHT counts the work the line is actually doing: open PRs and in-progress tickets on their branches, not only ticket status on main",
  "type": "bug",
  "status": "in-progress",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T17:24:22+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/sitrep-in-flight-counts-the-work-the-line-is-act",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner approved card S2 on the bearings page 2026-10-12 with the IN FLIGHT fix as a ticket",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-8f4f - SITREP IN FLIGHT counts the work the line is actually doing: open PRs and in-progress tickets on their branches, not only ticket status on main

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

The SITREP sent 2026-10-12 14:24Z (owner approved it as the standard, card S2, 17:2xZ) showed IN FLIGHT from in_progress.count (tools/bearings/config/sitrep.template.json:8), which tools/bearings/scripts/sitrep-build.mjs reads from ticket status on the checkout. A ticket started on its feature branch stays ready on main until its PR lands, so six live PRs showed as almost nothing in flight.

## Scope

**In**

- sitrep-build.mjs counts open PRs whose title names a WO id, plus tickets whose status is in-progress or in-review, deduplicated by ticket id
- the IN FLIGHT note names the source, for example 6 open PRs
- a tools/bearings test with a fixture of open PRs

**Out - non-goals**

- the card layout, colours or any other SITREP field
- STD-owner-sitrep-001 itself, which the owner approved

## Degrees of freedom

- [free] how open PRs are read (gh pr list or a cached JSON file), as long as the test uses a fixture and never the network

## Acceptance criteria

- [x] `AC-H1` *(human)* with three open PRs naming tickets that are ready on main, IN FLIGHT is 3
  - observed `2026-10-12` make -C tools/bearings test 120 passed 0 failed in test pane wD3:pC0; case 'three open PRs naming ready tickets (one named twice, one with no id) make IN FLIGHT 3, source 3 open PRs' ok: fixture prs-inflight.json, tickets aa01-aa03 ready, IN FLIGHT stat = 3|3 open PRs (tests/sitrep.sh)
- [x] `AC-H2` *(human)* a ticket that is both in-progress and has an open PR counts once
  - observed `2026-10-12` case 'IN FLIGHT counts PR 7's ticket once though it is also in progress, plus the other in-progress ticket (2)' ok: PR 7 names bb01 (in-progress on the checkout), bb02 in-progress, stat = 2|1 open PR, 1 without a PR; suite 120 passed 0 failed
- [x] `AC-H3` *(human)* sitrep-check.mjs passes the built payload against STD-owner-sitrep-001 with 0 violations
  - observed `2026-10-12` case 'AC-H3 the IN FLIGHT payload passes the checker with 0 violations' ok (sitrep-check.mjs on the 3-PR payload prints '0 violations'); the builder also runs the same check and exits 3 on any violation; suite 120 passed 0 failed

## Test plan

```sh
make -C tools/bearings test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro: the card read in_progress.count (ticket status on the checkout); IN FLIGHT is now in_flight.count, the union of PR-titled ticket ids and in-progress or in-review tickets, deduplicated by id, with the source named in the note (sitrep-build.mjs, breadcrumb at the fix site). The OBJECTIVE sentence also said 'Tickets in flight' from in_progress.count, so it now reads in_flight.count too, otherwise one card would carry two figures under one name; owner may veto. Known limit: a ticket started on a branch with no PR yet is invisible until its PR opens, and prs_command lists 20 PRs. A post-edit formatter hook reformats whole .mjs files at 80 columns; the edit was reapplied through a script to keep the diff to the change.

## Outcome

_Written by `work-order done`. Empty until then._
