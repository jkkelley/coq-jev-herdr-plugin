---
{
  "id": "WO-20261014-af7c",
  "slug": "merge-cleanup-refuses-treehouse-return-while-for",
  "title": "Merge cleanup refuses treehouse return while foreign processes remain in the slot (cause aj)",
  "type": "bug",
  "status": "cancelled",
  "priority": "p1",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:25:21+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": "2026-10-14",
  "approval": {
    "via": "override",
    "reason": "architect ruling 00:24Z: slot return with live processes is the defect",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-a18c"
  ],
  "blocks": [],
  "files": [
    "line/bin/merge.sh",
    "line/tests/cases/merge-cleanup-foreign.test.sh"
  ],
  "superseded_by": "WO-20261013-a18c"
}
---

# WO-20261014-af7c - Merge cleanup refuses treehouse return while foreign processes remain in the slot (cause aj)

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

On 2026-10-14 cleanups returned slots with conmon, kubectl and claude processes still inside them (PRs 162 and 166). That is the defect of causes w and x. Architect ruling 00:24Z: kill only processes attributable to the downed seat, or leave the slot leased and post a note. The cause ag ticket WO-20261013-a18c is ready and cannot be amended, so this is a new ticket that depends on it.

## Scope

**In**

- line/bin/merge.sh: before treehouse return, list processes with a cwd or open file in the slot; kill only those whose parent chain is the downed seat; if any other remain, skip the return, leave the slot leased and post a 200 note naming the slot and the processes. A case proves both paths.

**Out - non-goals**

- Changing treehouse, the seat retire script, or the rest of the merge cleanup.

## Degrees of freedom

- [free] The attribution test may use the seat's pane pid or the seat state file, whichever the seat records.

## Acceptance criteria

- [ ] `AC-H1` *(human)* treehouse return is not run while a foreign process is in the slot, and a note record names it. A process of the downed seat is killed and the return then runs. A case covers both. Lint and the line suite pass.

## Test plan

```sh
line case with a fake slot dir and a fake foreign process.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-14` - nothing shipped.

- reason: Architect ruling 00:34Z: the foreign-process criterion rides a note on WO-20261013-a18c; a second ticket for a ruling is not wanted.
- superseded by: `WO-20261013-a18c`

No branch, no PR and no merge commit exist for this work order.

