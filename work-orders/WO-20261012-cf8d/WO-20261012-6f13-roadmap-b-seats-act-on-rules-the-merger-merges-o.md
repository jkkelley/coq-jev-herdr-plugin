---
{
  "id": "WO-20261012-6f13",
  "slug": "roadmap-b-seats-act-on-rules-the-merger-merges-o",
  "title": "Roadmap B - Seats act on rules: the merger merges on the gate and verifies on main without asking, and seat.sh takes a started ticket's branch from origin",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:42+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-496d",
    "WO-20261013-73be"
  ],
  "blocks": [
    "WO-20261012-da1e",
    "WO-20261013-70c4",
    "WO-20261013-bed2"
  ],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/bin/seat-lib.sh",
    "roles/merger.json",
    "playbooks/merger.md",
    "herdr/tests/cases/*merger-gate*",
    "herdr/tests/cases/*seat-branch-origin*"
  ]
}
---

# WO-20261012-6f13 - Roadmap B - Seats act on rules: the merger merges on the gate and verifies on main without asking, and seat.sh takes a started ticket's branch from origin

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

On 2026-10-12 the merger asked the architect twice before merging four passed PRs, there is no verifier after the verifier seat closed (card C18), and seat.sh refuses a started ticket because the checkout copy has no branch once the records branch is gone.

## Scope

**In**

- the merger merges when review.passed and test.passed name the head sha, then runs the ticket test plan on main and posts verified or rejected
- seat.sh reads a started ticket's branch from origin when the checkout copy has none

**Out - non-goals**

- routing rules (D)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* in the herdr test world a PR with both gate records is merged and verified with no prompt to the architect
- [ ] `AC-H2` *(human)* seat.sh seats a reviewer for a ticket whose checkout copy is ready with branch null and whose branch exists on origin

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
