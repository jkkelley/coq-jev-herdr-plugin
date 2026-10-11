---
{
  "id": "WO-20261011-36d7",
  "slug": "the-labelled-test-pane-never-keeps-its-cwd-insid",
  "title": "The labelled test pane never keeps its cwd inside a treehouse slot, so treehouse return --force cannot kill it",
  "type": "bug",
  "status": "draft",
  "priority": "p2",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T03:23:53+00:00",
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

# WO-20261011-36d7 - The labelled test pane never keeps its cwd inside a treehouse slot, so treehouse return --force cannot kill it

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

Reviewing PR 6 for WO-20261010-a429, the architect ran the suite in the test pane wD3:pF with 'cd <slot> && make -C herdr test', which left the pane's zsh with its cwd inside the slot. treehouse return --force (now run by seat.sh --down for every ticket seat) terminates every process whose cwd is in the slot, so it killed that zsh and herdr closed the pane; the architect tab lost its test pane and seat.sh would have refused the next ticket seat (no pane labelled 'test - herdr'). The same happens to any shell parked in a slot, including a worker's second pane if it survives retire.

## Scope

**In**

- herdr/bin/testpane.sh (and the review recipe in the checkpoint toolchain) run every command in a subshell: ( cd DIR && ... ), so the pane's own shell stays in the main checkout
- seat.sh --down checks treehouse status --json processes for the slot before treehouse return and names each process it is about to end in the log, so a killed pane is never a surprise
- a Podman case proves the test pane's cwd is unchanged after a testpane.sh run and that --down logs the processes

**Out - non-goals**

- any change to treehouse itself
- the worker's own panes, which retire.sh and the tab close already end

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* after herdr/bin/testpane.sh <pane> 'cd <slot> && true' the pane's cwd is still the main checkout
- [ ] `AC-H2` *(human)* seat.sh --down on a seat whose slot holds a foreign shell logs the pid and name before treehouse return
- [ ] `AC-H3` *(human)* the architect tab keeps its 'test - herdr' pane across a full seat up, review and down cycle

## Test plan

```sh
make -C herdr test from the labelled test pane (stub treehouse reports processes in its status --json), then make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
