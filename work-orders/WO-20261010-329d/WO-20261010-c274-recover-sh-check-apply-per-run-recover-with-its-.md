---
{
  "id": "WO-20261010-c274",
  "slug": "recover-sh-check-apply-per-run-recover-with-its-",
  "title": "recover.sh --check|--apply per RUN-recover with its Podman case",
  "type": "feature",
  "status": "in-progress",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T20:50:09+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/recover-sh-check-apply-per-run-recover-with-its-",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect approval; owner order 2026-10-10: approval is the architect's job, the owner adds nothing more",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-c274 - recover.sh --check|--apply per RUN-recover with its Podman case

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

After a crash, a reboot or a herdr restart nothing closes the record of a seat that died, re-arms the guard or reports the tickets left open; the owner does it by hand. SPEC-04 s-recovery names recover.sh and herdr/bin has none.

## Scope

**In**

- herdr/bin/recover.sh with --check (report only) and --apply, in this order: halt flag (config .halt_flag, print HALTED and exit 0, never lifted here), herdr reachable, monitors.sh status (apply: grid), monitor seat seat.sh --check (apply: bringup.sh), every seat record with no ended_at: seat.sh --check, 'agent not running' means apply does seat.sh --down (fixed) and check reports FAILED, any other difference is reported never repaired, compaction-guard recover [--apply] once when require_guard, WARN line per open ticket whose seat is gone (the queue resumes it), one note 100 or 500 record and one herdr notification show at the end in apply mode; herdr/tests/cases/05-recover.test.sh in the same world as case 04; make -C herdr recover MODE= already exists

**Out - non-goals**

- resuming a seat (seat.sh --ticket does that); starting the herdr server; lifting the halt flag; changing seat.sh, monitors.sh or bringup.sh beyond what recover needs

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* recover.sh --check on a healthy world prints ok per object and exits 0; with a seat whose agent exited it prints FAILED <name> (agent gone) and exits 1 without changing anything
- [ ] `AC-H2` *(human)* recover.sh --apply downs the gone seat (seat.down 100 recorded, ended_at set), prints fixed <name>, exits 0, and a second --check exits 0
- [ ] `AC-H3` *(human)* with the halt flag present both modes print HALTED and exit 0 and change nothing
- [ ] `AC-H4` *(human)* case 05 is green in the suite run from the labelled test pane: tests: 5 passed, 0 failed

## Test plan

```sh
bash herdr/tests/run.sh in a labelled herdr pane (podman, --network=none, image localhost/coq-herdr-test:1); CASES=05 for the one case
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
