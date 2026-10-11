---
{
  "id": "WO-20261011-4562",
  "slug": "break-glass-one-owner-authorised-action-at-a-tim",
  "title": "Break glass: one owner-authorised action at a time flips one seat to bypass permissions and back, recorded, never a session or a day",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:42:53+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
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

- [ ] `AC-H1` *(human)* a break.glass 200 with a valid owner answer flips the named seat to bypassPermissions, the action runs, and the role settings are restored and verified by seat.sh --check within ttl
- [ ] `AC-H2` *(human)* a break.glass 200 without an owner answer is refused 423 and changes nothing
- [ ] `AC-H3` *(human)* a second action under the same answer is refused; the board shows every break glass as a line
- [ ] `AC-H4` *(human)* make -C factory test and make -C herdr test green with the new cases; make lint green

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
