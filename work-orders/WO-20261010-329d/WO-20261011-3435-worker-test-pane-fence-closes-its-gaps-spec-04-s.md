---
{
  "id": "WO-20261011-3435",
  "slug": "worker-test-pane-fence-closes-its-gaps-spec-04-s",
  "title": "Worker test-pane fence closes its gaps: SPEC-04 s-seat lists COQ_TEST_PANE, testpane.sh denies pane send-text and send-keys, brief.sh usage names --test-pane",
  "type": "bug",
  "status": "draft",
  "priority": "p3",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T05:19:17+00:00",
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

# WO-20261011-3435 - Worker test-pane fence closes its gaps: SPEC-04 s-seat lists COQ_TEST_PANE, testpane.sh denies pane send-text and send-keys, brief.sh usage names --test-pane

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

The worker on WO-20261010-8fa8 reported three gaps left by the test-pane fence: SPEC-04 s-seat does not list COQ_TEST_PANE among the seat environment it documents; herdr/bin/testpane.sh and roles/worker.json fence herdr pane run only, so a worker can still drive the test pane with herdr pane send-text or send-keys; the second usage string in roles/bin/brief.sh lacks [--test-pane ID]. None breaks a run today, but the fence is documented as complete and is not.

## Scope

**In**

- SPEC-04 s-seat lists COQ_TEST_PANE with its meaning
- roles/worker.json denies herdr pane send-text * and herdr pane send-keys * the same way it denies pane run, and the Podman case for the fence proves both are refused
- roles/bin/brief.sh both usage strings name [--test-pane ID]

**Out - non-goals**

- any change to which pane the worker may use
- the fence for panes outside the worker's tab, already covered

## Degrees of freedom

- [free] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* SPEC-04 s-seat names COQ_TEST_PANE
- [ ] `AC-H2` *(human)* a worker seat's settings deny herdr pane send-text and send-keys, and the Podman fence case shows the refusal
- [ ] `AC-H3` *(human)* both usage strings in roles/bin/brief.sh show [--test-pane ID]

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

## Outcome

_Written by `work-order done`. Empty until then._
