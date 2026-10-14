---
{
  "id": "WO-20261013-7af7",
  "slug": "belt-frozen-180s-per-seat-bring-up-seat-sh-waits",
  "title": "Belt frozen 180s per seat bring-up: seat.sh waits for a compaction-guard ACK line no seat prints, inside the belt's serial tick",
  "type": "bug",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T01:24:13+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/belt-frozen-180s-per-seat-bring-up-seat-sh-waits",
  "pr": 163,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-d127",
    "WO-20261013-cc5b",
    "WO-20261013-0bda",
    "WO-20261013-a1c6",
    "WO-20261013-0b48"
  ],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/config/herdr.json",
    "herdr/config/herdr.schema.json",
    "herdr/tests/cases/31-seat-up-no-wait.test.sh"
  ]
}
---

# WO-20261013-7af7 - Belt frozen 180s per seat bring-up: seat.sh waits for a compaction-guard ACK line no seat prints, inside the belt's serial tick

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

factory/bin/route.sh runs seat.sh --ticket T --role R inside its serial tick (route.sh:185-188). seat.sh nudge_seat (herdr/bin/seat.sh:723) then blocks on herdr pane wait-output for '● ACK compaction-guard ' for nudge_wait_seconds (herdr/config/herdr.json:11, 180). On 2026-10-13 none of the 7 live Claude seats (wD3:pNF pPB pPM pQ1 pQ5 pQ8 pQB) ever printed that line, so every bring-up holds the belt the full 180s: seen 01:19:44Z-01:22:51Z bringing up reviewer-wo-20261013-1031, belt status 'stopped (last touched 173s ago, stale after 60s)' while the reviewer was already working. Routing freezes for every other record, four bring-ups per ticket cost about 12 minutes, and a stale belt invites a duplicate runner to be started. The seat.sh:686-702 breadcrumb named this cost when the guard memo still came; the guard no longer sends it, so the cost is now paid on every seat. Patrol record 20261013T012320Z-100-susie.

## Scope

**In**

- one Claude seat bring-up through route.sh holds the belt tick for less than route.sh stale_seconds (60)
- the nudge-once-after-the-guard-ack behaviour of WO-20261011-dc0d is kept for a seat that does print the ack
- a breadcrumb at the fix site naming this ticket and the 01:20Z observation

**Out - non-goals**

- changing compaction-guard or its memo (outside this repo, the dc0d breadcrumb rejects it)
- a background seat.sh or a background nudge (AGENTS.md herdr-first; route.sh:79 rejects it)
- the belt's own serial design, which the Go scheduler replaces

## Degrees of freedom

- [free] how the wait is shortened, as long as one bring-up holds the tick under 60s and a seat that prints the ack is still nudged once
- [free] a new herdr.json key, as long as herdr.schema.json requires it and bounds it

## Acceptance criteria

- [x] `AC-H1` *(human)* a herdr suite case: a stubbed Claude seat that never prints the ack makes seat.sh --ticket T --role R return in under 60s with no nudge
  - observed `2026-10-13` herdr case 31 in the test pane: a stub claude that prints no ack, seat.sh exit 0 in 20s (budget 60s), log 'no guard ack within 15s, no nudge', nudged_at null; shipped nudge_wait_seconds 180 -> 15, schema maximum 30
- [x] `AC-H2` *(human)* a herdr suite case: a stubbed seat that prints the ack and then idles is nudged exactly once, as WO-20261011-dc0d's case asserts today
  - observed `2026-10-13` herdr case 31 and case 11 in the test pane: a stub seat that acks then idles returns in 7s and receives exactly one continue prompt, nudged_at set; case 11 full matrix and case 36 pass, make -C herdr lint rc 0
- [x] `AC-H3` *(human)* a live bring-up through route.sh leaves route.sh status 'running' throughout
  - observed `2026-10-14` herdr case 31 AC-H3 section in the test pane: the real factory/bin/route.sh once drives a pr.opened 100 through the default routes to a real seat.sh tester bring-up (stub claude that never acks, shipped nudge_wait_seconds 15); route.sh status polled every second reads running before, during (19 polls, oldest belt 20s, budget 60s) and after, ledger 'done seat', tester never nudged; make lint rc 0. The stub seat, not a live agent, as the architect ruled (note ha64w)

## Test plan

```sh
make lint && make -C herdr test
```

## Assumptions

1. the compaction-guard GOV-100 memo is no longer delivered to seats started by seat.sh; seen on 7 of 7 live seats, cause not traced into the guard

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-14` 2026-10-14 rework of PR 163 (architect ruling ha64w): AC-H3 now proven by herdr case 31, which runs the real factory/bin/route.sh through the stub bring-up of AC-H1 and polls route.sh status before, during and after. work-order evidence and reopen both refuse an archived ticket, so the AC-H3 line was edited by hand, as the review commit a035e5c had edited it.
- `2026-10-13` retro: the wait was a bound and not a rendezvous, so cut 180s to 15s and capped it at 30 in the schema so the key cannot regrow past the belt's 60s stale window. Case 31 reads the shipped value and runner.json stale_seconds, so it fails if either moves. Rejected a background nudge and a blind nudge, see the seat.sh breadcrumb. Open: AC-H3 needs one live route.sh bring-up after merge.

## Outcome

_Written by `work-order done`. Empty until then._
