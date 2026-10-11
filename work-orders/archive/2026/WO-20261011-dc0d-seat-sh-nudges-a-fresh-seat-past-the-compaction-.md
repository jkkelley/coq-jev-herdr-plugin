---
{
  "id": "WO-20261011-dc0d",
  "slug": "seat-sh-nudges-a-fresh-seat-past-the-compaction-",
  "title": "seat.sh nudges a fresh seat past the compaction-guard ack, so a worker never ends its first turn on the memo's 'nothing else'",
  "type": "bug",
  "status": "done",
  "priority": "p2",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T05:43:22+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/seat-sh-nudges-a-fresh-seat-past-the-compaction-",
  "pr": 11,
  "closed": "2026-10-11",
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-dc0d - seat.sh nudges a fresh seat past the compaction-guard ack, so a worker never ends its first turn on the memo's 'nothing else'

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

compaction-guard sends every new session a GOV-100 memo whose last action is 'reply with the ack line below and nothing else'. A worker that is mid-turn when the memo lands acks and keeps going, but a worker whose turn has already ended (brief read, work.started posted) acks and stops dead: it sat idle on 2026-10-10 (WO-20261010-8fa8) and 2026-10-11 (WO-20261010-a429, WO-20261010-2d04, WO-20261011-4c5e) until the architect ran herdr agent prompt by hand. Three of the four ticket seats this day stalled this way. The guard is outside this repo and its memo wording is its own; the seat that brought the worker up is the one that knows a brief is pending.

## Scope

**In**

- seat.sh door 1 and door 2, after the brief is sent, wait for the agent pane to show the ack line (herdr pane wait-output on 'ACK compaction-guard', bounded by a config timeout) and then send one continue prompt through herdr agent prompt naming the ticket and the step to resume from; no ack within the timeout is logged and not an error
- the nudge text lives in roles/ next to the brief so render-playbook keeps it in sync, and the seat.json records nudged_at
- a Podman case with the stub claude prints the memo and the ack and proves exactly one nudge is sent, and none when the agent keeps working past the ack

**Out - non-goals**

- any change to compaction-guard or its memo
- nudging a seat more than once

## Degrees of freedom

- [free] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* a worker seat that acks the guard memo and goes idle receives one continue prompt from seat.sh within the configured window and resumes its brief
  - observed `2026-10-11` Observed at 2dd8da7 from test pane wD3:p1V, make -C herdr test case 11 (stub claude in a headless herdr): a seat that printed '● ACK compaction-guard' and went idle received exactly one prompt 'WO-... - <title>. Continue your brief from the step you reached.' from seat.sh (agent read counted 1, log 'idle after the guard ack, nudged once'); a repair rerun sent no second. Not observed: a real Claude seat resuming its brief after the nudge, which needs a live bring-up the owner or architect runs.
- [x] `AC-H2` *(human)* a worker that keeps working after the ack receives no prompt
  - observed `2026-10-11` Observed at 2dd8da7 from test pane wD3:p1V, case 11: a stub seat that acked and then showed the working title for 12 s received no prompt (continue-prompt count 0, log 'still working after the guard ack, no nudge'); herdr's pane list read the seat as agent_status working at that moment, and the count stayed 0 after it finished. A seat whose guard sent no ack within nudge_wait_seconds was also not prompted and seat.sh exited 0.
- [x] `AC-H3` *(human)* seat.json carries nudged_at or null, and --check reports neither as a difference
  - observed `2026-10-11` Observed at 2dd8da7 from test pane wD3:p1V, case 11: seat.json nudged_at was a UTC timestamp (2026-10-11T06:08:11Z shape) for the nudged seat and JSON null for the seats not nudged; seat.sh --check exited 0 for both, and a repair rerun kept the recorded nudged_at unchanged.

## Test plan

```sh
make -C herdr test from the labelled test pane, then make lint and roles/bin/render-playbook.sh roles playbooks --check
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Retro 2026-10-11 (worker): seat.sh nudge_seat landed with case 11 (suite 11 passed, 0 failed). Cost found: a claude seat with no guard memo blocks seat.sh for nudge_wait_seconds, which made the first full run sit 8 min in case 03 until herdr/tests/lib/world.sh set both nudge keys to 1 s. Added nudge_settle_seconds beyond the ticket's one key. Gap for the architect: the nudge wording belongs in roles/bin/nudge.sh, which the worker fence denied (blocked 423 20261011T060054Z-423-qkuw4); seat.sh uses that file when present and an inline line otherwise. The three criteria are human-typed: the behaviour is observed against a stub claude only, so a live bring-up check by the architect or owner is still the one thing nobody has seen.
- `2026-10-11` Decision 2026-10-11 05:5x UTC (architect): approved --no-lavish (Claude seat, Lavish prohibited by the owner hard rule). Fixed points: the nudge watches the agent pane for the line '● ACK compaction-guard' with herdr pane wait-output (milliseconds), then polls agent_status via herdr pane list; idle after the ack means nudge, working means do not. Config key nudge_wait_seconds in herdr config, default 180. The nudge text names the ticket and says 'continue your brief from the step you reached'. seat.json nudged_at is null when no nudge was needed.

## Outcome

_Written by `work-order done`. Empty until then._
