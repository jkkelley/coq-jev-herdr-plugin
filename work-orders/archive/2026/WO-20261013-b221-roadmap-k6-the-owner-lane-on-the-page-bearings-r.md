---
{
  "id": "WO-20261013-b221",
  "slug": "roadmap-k6-the-owner-lane-on-the-page-bearings-r",
  "title": "Roadmap K6 - The owner lane on the page: bearings renders owner-lane items as cards and the health line from the board's health file, so the owner never has to ask where the line stands",
  "type": "feature",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T01:04:10+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-k6-the-owner-lane-on-the-page-bearings-r",
  "pr": 92,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "tools/bearings/scripts/*",
    "tools/bearings/tests/*"
  ]
}
---

# WO-20261013-b221 - Roadmap K6 - The owner lane on the page: bearings renders owner-lane items as cards and the health line from the board's health file, so the owner never has to ask where the line stands

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

The owner had to ask where the line stood on 2026-10-12 and decisions reached the owner in prose (SPEC-17 s-inventory H19; owner rule: every decision is a card, never inside a reply). SPEC-17 s-owner defines the owner lane and the health line; the page reads neither.

## Scope

**In**

- the bearings stable page renders every open owner-lane item as a card (title, options, recommendation) and marks it done when the answer record exists
- the health line read from the board's health file: running, draining or halted, per lane the open and leased counts, seats and their check state, stalls, counters; pulled by the page, never pushed, never capped; still rendered while the line is halted
- tests for both renderings against fixture files, in the bearings suite

**Out - non-goals**

- the interface agent seat itself (pull request 17)
- the board script (K1)
- the health checks (K2)
- the factory board view (K8)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* a second 423 on one ticket renders as exactly one card and the answer record clears it
  - observed `2026-10-13` tests/owner.sh: two 423 items on one ticket render as one card (2 cards for 2 tickets, 'raised 2 times'); an answer record naming a member id clears it; 135 passed in Podman
- [x] `AC-H2` *(human)* the health line on the page matches the health file within one refresh and still renders while the line is halted
  - observed `2026-10-13` tests/owner.sh: the page draws state, lanes, seats, stalls from health.json; halted line still renders with its reason; missing or malformed file draws 'not reporting' with the reason; 135 passed
- [x] `AC-H3` *(human)* the bearings test suite passes in Podman
  - observed `2026-10-13` make lint: all ok; make -C tools/bearings test in Podman: bearings tests: 135 passed, 0 failed

## Test plan

```sh
make lint && make -C tools/bearings test, in Podman through the repository targets
```

## Assumptions

1. the seat that owns the page is decided with pull request 17 (the interface agent); this ticket starts after that decision, and the live-line fix the owner asked for is Roadmap K8, so nothing waits on this one

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: K1 (board) and K2 (health) are not merged, so owner.mjs reads the item and health fields SPEC-17 names; only cardOf() and readHealthLine() change if they settle other names. Page theme untouched, new strip reuses existing classes. Lesson: a hook reformat split a ternary and my line delete broke owner.mjs; run node --check after any scripted edit.

## Outcome

_Written by `work-order done`. Empty until then._
