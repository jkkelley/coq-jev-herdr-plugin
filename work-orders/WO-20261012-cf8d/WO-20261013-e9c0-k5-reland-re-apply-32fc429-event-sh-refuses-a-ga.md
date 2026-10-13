---
{
  "id": "WO-20261013-e9c0",
  "slug": "k5-reland-re-apply-32fc429-event-sh-refuses-a-ga",
  "title": "K5 reland: re-apply 32fc429, event.sh refuses a gate record without --sha and any code outside the SPEC-17 map, once every fixture posts its sha",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:36:06+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13, re-cut on review yv8xi; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-d1cd",
    "WO-20261013-9189",
    "WO-20261013-5dce"
  ],
  "blocks": [],
  "files": [
    "events/bin/event.sh",
    "events/schema/event.schema.json",
    "events/tests/cases/03-read.test.sh",
    "events/tests/cases/04-refusals.test.sh"
  ]
}
---

# WO-20261013-e9c0 - K5 reland: re-apply 32fc429, event.sh refuses a gate record without --sha and any code outside the SPEC-17 map, once every fixture posts its sha

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

32fc429 (WO-20261013-f298) is right but landed before the fixtures it breaks and is reverted. With the fixtures fixed by the three parts it depends on, the same change lands again. Review yv8xi: the code map refused 450, which the compliance officer posts (roles/compliance-officer.json), and nothing tracked it.

## Scope

**In**

- re-apply 32fc429's changes to events/bin/event.sh, events/schema/event.schema.json, events/tests/cases/03-read.test.sh and events/tests/cases/04-refusals.test.sh, with the breadcrumb naming the revert and this reland
- 450 (compliance report) is in the schema's code enum with a breadcrumb, so the reland refuses nothing a role posts; 04-refusals asserts 450 is accepted and an unmapped code is refused; its routes row is WO-20261013-612d and its SPEC-17 row is WO-20261013-d101

**Out - non-goals**

- any fixture (the three parts)
- new refusal rules beyond 32fc429

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the writer refuses test.passed without --sha with exit 3, accepts 450, refuses an unmapped code, and every suite in the test plan passes on the same commit

## Test plan

```sh
make lint && bash events/tests/run.sh && make -C factory test && make -C herdr test, all in Podman (events/tests/run.sh re-execs itself in Podman)
```

## Assumptions

1. herdr/tests/cases/13-break-glass and 18-watches post with --sha after A3 parts WO-20261013-5c06 and WO-20261013-f9f2 (pull request 89); if they have not landed when this starts, make -C herdr test names them and this part waits

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
