---
{
  "id": "WO-20261012-c41f",
  "slug": "threshold-per-role-seat-sh-renders-a-guard-schem",
  "title": "Threshold per role: seat.sh renders a guard schema per seat from its role, so the guard compacts at the role's threshold and names the seat",
  "type": "feature",
  "status": "in-progress",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T16:32:54+00:00",
  "parent": "WO-20261012-265d",
  "branch": "feat/threshold-per-role-seat-sh-renders-a-guard-schem",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner answered card C4 on the bearings page 2026-10-12 16:32Z: cut all four",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-c41f - Threshold per role: seat.sh renders a guard schema per seat from its role, so the guard compacts at the role's threshold and names the seat

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

Every role carries context_threshold_percent (roles/architect.json:11) but only render-playbook.sh reads it; seat.sh exports no guard schema, so every coq seat binds with schema null, the default 30, the name session-<hex> and a GOV-130 LOW alert (27 since 02:00Z on 2026-10-12). Editing a role's threshold changes nothing.

## Scope

**In**

- seat.sh renders a per-seat guard schema (name, role, agent_kind, model, thresholds.compact from the role) into the seat state directory outside the seat's write fence
- seat.sh exports COMPACTION_GUARD_SCHEMA in the seat's launch line
- seat.sh --check fails a seat whose binding has schema null

**Out - non-goals**

- any compaction-guard change
- changing any role's threshold value

## Degrees of freedom

- [free] schema file name, as long as it sits in the seat state directory and seat.sh --check reads the same path

## Acceptance criteria

- [ ] `AC-H1` *(human)* a seated role with threshold 40 binds with thresholds.compact 40 and the seat's name
- [ ] `AC-H2` *(human)* no GOV-130 alert for a seat brought up by seat.sh
- [ ] `AC-H3` *(human)* seat.sh --check exits non-zero for a seat whose binding has schema null

## Test plan

```sh
make -C herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
