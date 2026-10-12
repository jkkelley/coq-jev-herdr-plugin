---
{
  "id": "WO-20261012-8fb2",
  "slug": "own-checkpoint-after-compaction-a-sessionstart-c",
  "title": "Own checkpoint after compaction: a SessionStart compact hook puts the seat's newest CONTEXT_STATE.md checkpoint in front of it",
  "type": "feature",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T16:32:52+00:00",
  "parent": "WO-20261012-265d",
  "branch": "feat/own-checkpoint-after-compaction-a-sessionstart-c",
  "pr": 30,
  "closed": "2026-10-12",
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

- [x] `AC-H1` *(human)* after a compact, the seat's context holds its own newest checkpoint text
  - observed `2026-10-12` herdr case 17 passed in the test pane: seat.sh brings up a worker, the hook run with that seat's HERDR_PANE_ID printed 'your own newest checkpoint from <worktree>/CONTEXT_STATE.md' plus the top checkpoint verbatim (checkpoint.sh read --top 1), and not the second. A live run of herdr/bin/resume-checkpoint.sh in the test pane for this seat printed the same. Still to see on a real compact: that Claude Code adds the SessionStart stdout to the context after /compact.
- [x] `AC-H2` *(human)* the hook exits 0 when the worktree or checkpoint is missing and prints one line saying so
  - observed `2026-10-12` herdr case 17: a worktree with no CONTEXT_STATE.md, a file with no checkpoint, a gone worktree, a pane no live seat holds, an unset HERDR_PANE_ID, no seat records, and no checkpoint.sh each exit 0 with exactly one stdout line naming what was missing.
- [x] `AC-H3` *(human)* the hook runs only on compact, not on startup or resume
  - observed `2026-10-12` Both .claude/settings.json and the render_settings output carry one SessionStart entry with matcher compact and the identical command, asserted in case 17; no entry names startup, resume or clear, and the guard's unmatched entry stays first. Break glass keeps the entry (case 13 assertion added).

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

- `2026-10-12` Retro: the test pane's cwd is the main checkout, so 'make -C herdr test' there ran the main tree, not the slot; cases must be run with make -C $COQ_WORKTREE/herdr. Break glass used '.hooks =' and would have dropped the entry; changed to '.hooks +=' with a case 13 assertion. Live seats' settings.json now differ from the render until the next restart, so seat.sh --check names drift once. Not proved without a real compact: that Claude Code folds two identical hook commands into one run.

## Outcome

_Written by `work-order done`. Empty until then._
