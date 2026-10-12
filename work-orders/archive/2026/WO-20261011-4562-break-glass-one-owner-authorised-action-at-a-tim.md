---
{
  "id": "WO-20261011-4562",
  "slug": "break-glass-one-owner-authorised-action-at-a-tim",
  "title": "Break glass: one owner-authorised action at a time flips one seat to bypass permissions and back, recorded, never a session or a day",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-12",
  "created_at": "2026-10-11T18:42:53+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/break-glass-one-owner-authorised-action-at-a-tim",
  "pr": 22,
  "closed": "2026-10-11",
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule; owner order 18:38Z get the system operational",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-4562 - Break glass: one owner-authorised action at a time flips one seat to bypass permissions and back, recorded, never a session or a day

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

Hotfixes and maintenance stall when a seat's role denies the one command the fix needs, and the only way through today is the architect by hand. DEC-break-glass-one-time: only the owner authorises, one action per authorisation, bypass permissions for that action only, then the role settings are back, every time a record.

## Scope

**In**

- a break.glass record kind (code 300 request, 200 granted, 423 refused) in the event schema with seat, action text, attempt and the owner answer id
- seat.sh --break-glass SEAT --record ID: verifies the record carries an owner answer from the bearings page for that id, writes the seat's settings.json with bypassPermissions and the one allowed action, prompts the seat with the record id, and restores the role settings when the action's follow-up record lands or after ttl_seconds, whichever first
- bearings card for the owner: seat, action, why, grant or refuse, posted by the interface agent on a 300
- routes.json rows for break.glass 300 (notify_owner) and 200 (do:break-glass); runbook; suite cases against the stub herdr and a stub owner answer

**Out - non-goals**

- any standing elevation; a seat that keeps bypass after its action is a 500
- the owner's identity check beyond the bearings page key (the page is the owner)

## Degrees of freedom

- [free] ttl_seconds default, as long as it is config and under one hour
- [free] how the one allowed action is expressed in settings.json, as long as a second command is still denied

## Acceptance criteria

- [x] `AC-H1` *(human)* a break.glass 200 with a valid owner answer flips the named seat to bypassPermissions, the action runs, and the role settings are restored and verified by seat.sh --check within ttl
  - observed `2026-10-11` AC-H1 at file and record level, in the test pane: herdr case 13 (68 assertions, make -C herdr test, 13 passed) grants through a stub owner answer, then sees bypassPermissions, the covering deny lifted, the exact action allowed, the guard hook on Bash, break.glass 100/201/204 recorded, settings byte-identical to the role after the 201, --check clean. NOT observed: a real Claude Code seat re-reading --settings and the hook on change; that live run needs an owner answer on the bearings page and is still owed.
- [x] `AC-H2` *(human)* a break.glass 200 without an owner answer is refused 423 and changes nothing
  - observed `2026-10-11` AC-H2 observed in herdr case 13: seven refusals (no answers file, 200 with no answer, answer Refuse, card naming another command, two commands in one action, another seat, command swapped after the yes) each exit 3 and a 423 record, seat settings byte for byte the role's, no state file written, --check clean.
- [x] `AC-H3` *(human)* a second action under the same answer is refused; the board shows every break glass as a line
  - observed `2026-10-11` AC-H3 second action: observed in herdr case 13, the same answer a second time and another command under it are refused 423 (already used), the state file stays marked restored. Board half: observed in report/loop case 08-glass (make -C report/loop test, 9 passed), one row per request id moving asked, granted, in effect, done, restored, a refused one kept, ticket lines untouched. NOT observed: the owner's Grant or Refuse card and the answer-to-200/423 step (interface.sh line and forward); they need interface/ from PR 17 (WO-20261011-e618 - Interface agent seat owns the bearings page: owner requests become records and the done line comes from it), not on main yet. The finished work is on origin/backup/4562-before-rebuild (56 interface checks passed there).
- [x] `AC-H4` *(human)* make -C factory test and make -C herdr test green with the new cases; make lint green
  - observed `2026-10-11` AC-H4 observed in the test pane on the merged tree: make lint green, make -C factory test 11 passed (case 08-break-glass), make -C herdr lint and make -C herdr test 13 passed (13-break-glass), make -C report/loop lint and test 9 passed. Not run: make -C report/loop test-browser.

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

- `2026-10-12` Owner decision 2026-10-12 (architect record 20261012T121854Z-200-uqz6z): the live halves of AC-H1 (a real Claude Code seat re-reading --settings and the hook on change, with an owner answer) and AC-H3 (the owner's Grant or Refuse card and the answer-to-200/423 step, needing PR 17) are re-homed to WO-20261012-2a12 - Break glass live proof: the owner's first real grant through the interface card flips a live seat to bypass permissions, runs one action, and restores it. Their ticks here cover the file and record level only, observed in herdr case 13 and report/loop case 08-glass. Review obs 1 is overruled by the owner: break glass flips every seat, dontAsk included, to bypassPermissions; case 13 asserts it on an orchestrator seat.
- `2026-10-11` Retro 2026-10-11: code, runbook and suites landed; two things are owed. (1) The interface card and verdict (interface.sh line/forward, interface/tests cases 6/6b) wait on PR 17 (WO-20261011-e618); patch at origin/backup/4562-before-rebuild commit 9907813. (2) AC-H1 live proof on a real Claude Code seat with an owner answer. Lessons: make step runs git add -A and swept foreign event records into two commits; cases 04/05 and monitors.json/herdr.json are merge hot spots for reserved watcher slots.

## Outcome

_Written by `work-order done`. Empty until then._
