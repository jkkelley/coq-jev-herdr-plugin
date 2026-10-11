---
{
  "id": "WO-20261011-8fb3",
  "slug": "seat-sh-adopt-a-running-claude-session-becomes-a",
  "title": "seat.sh adopt: a running claude session becomes a seat in place, keeping its context, under the role's label, settings and record",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:42:54+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/seat-sh-adopt-a-running-claude-session-becomes-a",
  "pr": 18,
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

# WO-20261011-8fb3 - seat.sh adopt: a running claude session becomes a seat in place, keeping its context, under the role's label, settings and record

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

The owner ordered the architect session to become the interface agent with all its context (DEC-architect-becomes-interface-agent). seat.sh can only start a fresh claude, so a context transfer today means a new model with none of the day in it.

## Scope

**In**

- seat.sh --adopt --role R --pane P --session ID [--worktree DIR]: writes seat.json for the role's seat name with the live session id, relabels the pane with the role label, writes the role settings.json for the next restart, exports nothing it cannot, records seat.up 100 with kind adopt in the note, and starts no agent
- seat.sh --check reads an adopted seat like any other; --down on an adopted seat retires the record and relabels but never kills the pane
- a --resume ID flag on the normal start path so a seat can also be re-started from a session transcript in a fresh pane
- runbook section and suite cases

**Out - non-goals**

- changing the live session's permission mode or model (the owner does that in the pane); the settings file applies at the next start

## Degrees of freedom

- [free] the adopt note wording, as long as it names the session id and the pane

## Acceptance criteria

- [x] `AC-H1` *(human)* seat.sh --adopt on a live pane writes seat.json and the label, records seat.up, and seat.sh --check reports the seat ok with the agent running
  - observed `2026-10-11` herdr/tests/cases/13-adopt.test.sh against a headless herdr with a stub claude run by hand in a split pane: seat.sh --adopt --role interface-agent --pane P --session ID exited 0 and started nothing (foreground pid of the pane unchanged), named the herdr agent interface in the same pane, labelled the pane 'claude-sonnet-5-5 - high - interface-agent', wrote seat.json (adopted true, claude_session, pane, lease null) and the role settings.json, recorded one seat.up 100 whose note starts 'adopt:' and names the session and pane; seat.sh --check interface exited 0 with the agent running, and exited 1 naming settings drift and a changed pane label when either was altered. Suite run 2026-10-11 20:0x UTC, 14 passed 0 failed.
- [x] `AC-H2` *(human)* seat.sh --down on the adopted seat leaves the pane and its agent alive and records seat.down
  - observed `2026-10-11` Same case 13: seat.sh --down interface on the adopted seat exited 0; the pane still existed, the agent's foreground pid was the same as before the adopt, herdr still reported the claude agent in the pane, its name and the pane label were put back to what adopt read, seat.down 100 was recorded once, seat.json got ended_at, --check then exited 3, a second --down exited 0 and recorded nothing, and the same pane could be adopted again.
- [x] `AC-H3` *(human)* seat.sh --ticket X --role R --resume ID starts claude with --resume ID in the stub harness
  - observed `2026-10-11` herdr/tests/cases/14-resume.test.sh: seat.sh --ticket WO-20261010-8777 --role worker --resume ID started the stub claude as 'claude --model claude-sonnet-5-5 --effort high --permission-mode bypassPermissions --settings <state>/seats/<name>/settings.json --resume ID' (read off the pane's process argv); door 2 (--role merger --task ... --resume ID) also carried --resume ID; without --resume the command line has none; --resume with runtime codex exited 3 and an id that is not a session id exited 2, both building nothing.
- [x] `AC-H4` *(human)* make -C herdr test and make lint green
  - observed `2026-10-11` make -C herdr test from the labelled test pane via testpane.sh: 'tests: 14 passed, 0 failed' (cases 01-12 unchanged, 13-adopt and 14-resume new). make -C herdr lint exited 0 (schemas and shellcheck -S warning over bin, tests, cases, stubs). make lint at the repo root ran clean inside make step before the commit.

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

- `2026-10-11` Rebuilt 2026-10-11 UTC on the architect's 422 (record 20261011T203651Z-422-3navb) and the reviewer's review.changes (20261011T210527Z-422-er3bq): the branch had been cut from the records branch and carried about 300 files of other tickets. It is now origin/main 4860361 plus this ticket alone: herdr/bin/seat.sh, cases 13 and 14, docs/sops/SOP-0001 (the runbook, now a docs.sh SOP with a Verification section and GOOD and NEVER lines, because interface/RUNBOOK.md is on open PR 17 and not on main), this archived ticket, its changelog entry and a checkpoint. Correction to the retro above: the runbook section is the SOP, not interface/RUNBOOK.md. Case 13 now derives the expected pane label from the layout the role names, since main's interface-agent role uses seat-1x2 and PR 17's layout is interface-2x2. Evidence above was observed on the old tree; make lint and make -C herdr test were rerun on the rebuilt tree: 13 passed 0 failed (cases 01-11, 13, 14; main has no case 12). The old tip is kept as local branch backup/8fb3-a930f3c. Pushing needs a force push, which this seat's role denies.
- `2026-10-11` Retro 2026-10-11 UTC. Built as three parts in one step: seat.sh --adopt (agent rename, layout agent-slot label, settings.json, seat.json with adopted, claude_session and prior label and name), adopted-seat branches in --check, --down and --audit, and --resume on both start doors; cases 13 and 14; runbook section in interface/RUNBOOK.md. Decisions: --session is checked against the session herdr itself reports for the pane (agent_session.value) so a wrong id cannot make a later restart resume someone else's conversation; an adopted seat owns one pane, so the layout's other panes and pre_start are not built and --check compares only that pane; --audit matches an adopted agent by pane because a hand-started process has no COQ_SEAT; --down of an adopted seat never runs retire.sh, a tab close or treehouse return. What this does NOT prove: every case uses the stub claude, never a real session, so adopting the live architect session is untested against the real thing, and --resume was only seen as an argv. Claude Code looks a session up under the project directory it starts in, so a --resume into a freshly leased slot may not find a transcript recorded under another checkout; the runbook says to pass the original checkout as --worktree, and this is the first thing to check when the real handover runs. An adopted agent has no COQ_SEAT, COQ_ROLE or COQ_EVENTS_ROOT in its environment, so it posts records with an explicit --seat. The shared test pane queues every worker's command: a run waited 10 to 20 minutes behind other suites, so batch the cases rather than running one at a time.

## Outcome

_Written by `work-order done`. Empty until then._
