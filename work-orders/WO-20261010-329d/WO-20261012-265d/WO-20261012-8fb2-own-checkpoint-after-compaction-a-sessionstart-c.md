---
{
  "id": "WO-20261012-8fb2",
  "slug": "own-checkpoint-after-compaction-a-sessionstart-c",
  "title": "Own checkpoint after compaction: a SessionStart compact hook puts the seat's newest CONTEXT_STATE.md checkpoint in front of it",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T16:32:52+00:00",
  "parent": "WO-20261012-265d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner answered card C4 on the bearings page 2026-10-12 16:32Z: cut all four",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-8fb2 - Own checkpoint after compaction: a SessionStart compact hook puts the seat's newest CONTEXT_STATE.md checkpoint in front of it

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

After a compaction the guard injects only its own checkpoint (git status, last prompts, last message); the seat-written CONTEXT_STATE.md checkpoint where the golden rule puts the resume line (AGENTS.md:37) is never shown, so a seat resumes from a generic summary instead of its own next step.

## Scope

**In**

- one SessionStart entry, matcher compact, after the guard's, in .claude/settings.json and in the settings seat.sh renders
- it prints checkpoint.sh read --project <seat worktree> --top 1 for the seat HERDR_PANE_ID names

**Out - non-goals**

- the owner's global hooks in ~/.claude/settings.json
- any compaction-guard change

## Degrees of freedom

- [free] hook script name and location, as long as it lives in the repo and is wired in both settings files

## Acceptance criteria

- [ ] `AC-H1` *(human)* after a compact, the seat's context holds its own newest checkpoint text
- [ ] `AC-H2` *(human)* the hook exits 0 when the worktree or checkpoint is missing and prints one line saying so
- [ ] `AC-H3` *(human)* the hook runs only on compact, not on startup or resume

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
