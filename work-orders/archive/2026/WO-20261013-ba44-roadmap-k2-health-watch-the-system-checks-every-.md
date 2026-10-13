---
{
  "id": "WO-20261013-ba44",
  "slug": "roadmap-k2-health-watch-the-system-checks-every-",
  "title": "Roadmap K2 - Health watch: the system checks every agent each tick, alive, stuck, out of context and at capacity, with three retries and one repair per retry, exactly one of each system process, the nudge and the health line",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:57:27+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-f268"
  ],
  "blocks": [
    "WO-20261013-14f9",
    "WO-20261013-f52a"
  ],
  "files": [
    "line/bin/health.sh",
    "line/config/health.json",
    "line/config/health.schema.json",
    "line/tests/cases/health-*.sh",
    "herdr/config/monitors.json"
  ],
  "superseded_by": "WO-20261013-b296"
}
---

# WO-20261013-ba44 - Roadmap K2 - Health watch: the system checks every agent each tick, alive, stuck, out of context and at capacity, with three retries and one repair per retry, exactly one of each system process, the nudge and the health line

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

Nobody checks the agents: on 2026-10-12 dead, stuck, frozen and refused seats were found by the architect reading panes and fixed by hand (SPEC-17 s-inventory H08, H10, H16, H21, H25). SPEC-17 s-health defines checks C1 to C5; nothing runs them.

## Scope

**In**

- line/bin/health.sh: one tick runs C1 alive, C2 stuck, C3 out of context, C4 at capacity and C5 exactly one of each system process, over every seat record with no end and every fixed seat; three retries, one repair per retry (C1 down then re-seat when the ticket is live; C2 nudge, then Escape and nudge, then retire and re-seat with resume; C3 release an expired guard lease; C4 retry when a slot frees, then the down order); a finding on the orchestrator lane after the third; one health line entry per outcome; never a repair of an open finding
- the nudge: one line naming the lane and the count, at most once per nudge_seconds per idle seat, never to a busy seat; the architect's interval is digest_seconds
- line/config/health.json and line/config/health.schema.json: poll_seconds, retries, busy_grace_seconds, idle_down_seconds, context_threshold_percent, capacity.down_order, notify.owner_cap_per_hour, processes (name, pid file, command, slot) for the runner, stall watch, policy watch and health watch, architect_nudge_threshold
- a health watch slot in herdr/config/monitors.json; the queue slot becomes the board watch
- cases T04 to T07 of SPEC-17 s-tests as line/tests/cases/health-*.sh against a fake herdr

**Out - non-goals**

- the orchestrator's decisions beyond the down order (K3)
- halt, drain and resume (K4)
- the compaction itself, which the guard owns (SPEC-05)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a seat whose agent is gone is downed after three ticks and re-seated when its ticket is live, with seat.down 500 and seat.up 100 (T04)
- [ ] `AC-H2` *(human)* a seat in a question dialog is freed by Escape and nudged on the second retry, the third retry retires and re-seats with resume (T05); at max_agents with an open merger item an idle fixed seat is downed and the merger seated within three ticks with the architect lane empty (T06)
- [ ] `AC-H3` *(human)* a second runner process is detected by its pid file and stopped, and the health line shows it (T07)

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: owner 02:50Z (lvvtd): probes and the reaper are SPEC-16.F and C, not new bash; the interim is the patrol already on main (PR 86) until SPEC-16.F is active; T04 to T07 move to SPEC-16.K
- superseded by: `WO-20261013-b296`

No branch, no PR and no merge commit exist for this work order.

