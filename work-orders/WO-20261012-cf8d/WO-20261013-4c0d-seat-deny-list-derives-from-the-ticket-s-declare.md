---
{
  "id": "WO-20261013-4c0d",
  "slug": "seat-deny-list-derives-from-the-ticket-s-declare",
  "title": "Seat deny list derives from the ticket's declared files",
  "type": "bug",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T02:54:28+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/tests/cases/*seat-deny-declared*"
  ]
}
---

# WO-20261013-4c0d - Seat deny list derives from the ticket's declared files

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

herdr/bin/seat.sh render_settings copies roles/worker.json deny.paths (specs/, graph/, roles/) into every worker seat's settings, so a ticket that declares a file under roles/ cannot be built by its own worker: PR 86 (WO-20261013-5b33) needed one enum line in roles/schema/role.schema.json (ruling p0zz5) and a maintenance agent had to be seated by hand (blocked 423 xpg8e). No per-ticket allow exists.

## Scope

**In**

- herdr/bin/seat.sh render_settings: for a worker seat, a role deny path that covers a file in the ticket's frontmatter files list is narrowed so that exact declared file (or glob) is editable, and every other path under that deny stays denied
- one herdr test case herdr/tests/cases/*seat-deny-declared* that renders settings for a ticket declaring roles/schema/role.schema.json and asserts that file is editable while roles/worker.json and the rest of roles/, specs/ and graph/ stay denied, and that a ticket with no declared files renders the deny list unchanged
- a breadcrumb at the change in seat.sh: what broke (PR 86, blocked 423 xpg8e), why the declared files are the allow list, the rejected alternative, the cost

**Out - non-goals**

- lifting a deny path for every seat or every worker (never)
- changing roles/worker.json or any role file
- tester, reviewer, merger or any non-worker seat

## Degrees of freedom

- [free] how the narrowing is expressed in Claude Code settings (an explicit Edit allow for the declared path ahead of the deny, or splitting the deny into its non-declared siblings), as long as the AC test proves the declared file editable and every undeclared file under the deny still refused

## Acceptance criteria

- [ ] `AC-H1` *(human)* a worker seated on a ticket whose files list names roles/schema/role.schema.json can Edit that file and nothing else under roles/, specs/ or graph/ (rendered settings asserted by the test case)
- [ ] `AC-H2` *(human)* a ticket with an empty or missing files list renders exactly today's deny list (byte-identical settings for the deny block)
- [ ] `AC-H3` *(human)* no seat other than a worker on a ticket that declares the file gains any edit right

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
