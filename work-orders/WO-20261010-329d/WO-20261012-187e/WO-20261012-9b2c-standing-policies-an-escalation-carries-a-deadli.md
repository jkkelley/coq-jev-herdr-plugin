---
{
  "id": "WO-20261012-9b2c",
  "slug": "standing-policies-an-escalation-carries-a-deadli",
  "title": "Standing policies: an escalation carries a deadline and a default drawn from the owner's locked decisions, so the line takes the default when nobody answers instead of waiting",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:52+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/standing-policies-an-escalation-carries-a-deadli",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order 2026-10-12: get the factory working without the architect or owner as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-9b2c - Standing policies: an escalation carries a deadline and a default drawn from the owner's locked decisions, so the line takes the default when nobody answers instead of waiting

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

Escalations route to the owner with no deadline and no default; the PR 22 criteria split waited hours for an answer that the owner's locked decisions already implied (land PRs, no dead code).

## Scope

**In**

- policy table in config mapping escalation kinds to a default action and a deadline
- the monitor applies the default at the deadline and records it

**Out - non-goals**

- break glass, which stays owner-only every time

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* an escalation with a policy and no owner answer by its deadline produces the default action and a record naming the policy
- [ ] `AC-H2` *(human)* an escalation with no policy still waits for the owner

## Test plan

```sh
make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
