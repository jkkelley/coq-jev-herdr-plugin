---
{
  "id": "WO-20261013-e2c3",
  "slug": "cause-ab-the-route-runner-drops-a-pr-opened-post",
  "title": "Cause ab: the route runner drops a pr.opened posted with code 200 and stalls its queue behind one failing route; event.sh writes pr.opened as 100, route.sh routes pr.opened for any 1xx or 2xx, retries a failed route 3 times then skips it, and re-routes a held gate when a newer head is opened",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T22:14:52+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect cause ab 2026-10-13; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-439d"
  ],
  "blocks": [],
  "files": [
    "factory/bin/route.sh",
    "events/bin/event.sh",
    "factory/tests/cases/25-route-retry-skip.test.sh",
    "events/tests/cases/05-pr-opened-code.test.sh"
  ]
}
---

# WO-20261013-e2c3 - Cause ab: the route runner drops a pr.opened posted with code 200 and stalls its queue behind one failing route; event.sh writes pr.opened as 100, route.sh routes pr.opened for any 1xx or 2xx, retries a failed route 3 times then skips it, and re-routes a held gate when a newer head is opened

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

(1) PR 149's pr.opened was posted with code 200 (record 20261013T221040Z-200-2sw89) by a spec-author seat on the architect role; routes key on (kind, code), so the runner logged 'no route for pr.opened 200' (20261013T221235-note-wo-20261013-58c9) and nothing gated the PR. (2) PR 136's test.passed (20261013T220815Z-201-vnaju) was routed at 22:12:19, 4 minutes late, and HELD 'head moved' because it cited the stale sha f50638e: the runner was serially blocked on one failing route (423 20261013T220813Z-423-hw2ci, 'herdr agent prompt interface failed', 20261013T221218). One bad route stops every route behind it (also GitHub issue 76).

## Scope

**In**

- events/bin/event.sh: a pr.opened with any 1xx or 2xx code is written as 100, the original code kept in the note, with a breadcrumb naming this ticket
- factory/bin/route.sh: a pr.opened row matches any 1xx or 2xx code, for records written before the writer fix
- factory/bin/route.sh: a failed route is retried up to 3 times, then marked skipped with one 500 to the orchestrator lane, and the runner moves to the next record instead of waiting on it
- factory/bin/route.sh: a gate record held 'head moved' is routed again when a pr.opened for the same ticket names a newer head
- tests: events/tests/cases/05-pr-opened-code.test.sh (200 in, 100 written) and factory/tests/cases/25-route-retry-skip.test.sh (a pr.opened 200 routes; a route that fails 3 times is skipped and the next record still routes on the same tick; a held gate re-routes on a newer pr.opened)

**Out - non-goals**

- factory/config/routes.json, claimed by four open tickets: the code match lives in route.sh
- moving route-retry.sh (WO-20261013-acbf), which this makes redundant
- the ticket a route belongs to (cause aa, WO-20261013-9b21 on pull request 148)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* both cases pass and each fails when its fix is removed; make lint, bash events/tests/run.sh and make -C factory test pass

## Test plan

```sh
make lint && bash events/tests/run.sh && make -C factory test, in Podman through the repository targets
```

## Assumptions

1. WO-20261013-9b21 (cause aa, pull request 148) also edits factory/bin/route.sh; the edge is written once pull request 148 merges, and claims.sh start keeps the two apart until then

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` events/bin/event.sh is held by pull request 145 (WO-20261013-f298, Roadmap K5, in flight). Start this ticket only after pull request 145 merges; the edge is not written because pull request 145 moves the f298 ticket file to the archive.

## Outcome

_Written by `work-order done`. Empty until then._
