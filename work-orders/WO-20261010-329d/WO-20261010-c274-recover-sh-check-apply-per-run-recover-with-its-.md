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

- [x] `AC-H1` *(human)* recover.sh --check on a healthy world prints ok per object and exits 0; with a seat whose agent exited it prints FAILED <name> (agent gone) and exits 1 without changing anything
  - observed `2026-10-10` Case 05 in the Podman suite (CASES=05 and the full run, 2026-10-10 UTC): recover.sh --check on a healthy world printed ok herdr, ok monitors, ok monitor, ok worker-wo-20269999-aaaa, ok compaction-guard and exited 0. After the worker's stub agent was ended with /exit it printed 'FAILED worker-wo-20269999-aaaa (agent gone)', exited 1, wrote no event file and left ended_at null. Also read-only against the live host: ok herdr, ok monitors, ok monitor, ok worker-wo-20261010-c274, exit 0.
- [x] `AC-H2` *(human)* recover.sh --apply downs the gone seat (seat.down 100 recorded, ended_at set), prints fixed <name>, exits 0, and a second --check exits 0
  - observed `2026-10-10` Case 05: recover.sh --apply on the gone seat printed 'fixed worker-wo-20269999-aaaa (agent gone, seat downed)', exited 0, recorded exactly one seat.down 100, set ended_at on the seat record, wrote one closing note 100 and a second --check exited 0 without listing the downed seat. Same case: a gone monitor seat is FAILED in --check and 'fixed monitor (bringup.sh ...)' in --apply. A difference other than agent-not-running (pane missing) is FAILED in --apply, the agent is untouched and the closing record is 500.
- [x] `AC-H3` *(human)* with the halt flag present both modes print HALTED and exit 0 and change nothing
  - observed `2026-10-10` Case 05: with STATE/HALT present both --check and --apply printed one line starting HALTED and exited 0. The event file count was identical before and after, the guard stub log stayed empty, and the flag file was still present afterwards.
- [x] `AC-H4` *(human)* case 05 is green in the suite run from the labelled test pane: tests: 5 passed, 0 failed
  - observed `2026-10-10` make -C herdr test (full suite, Podman, --network=none, image localhost/coq-herdr-test:1): 'tests: 5 passed, 0 failed'. Caveat for the human check: I ran it as a foreground make from the worker seat because the worker playbook allows make but not herdr pane run, so it was NOT run from a labelled test pane; the tester should rerun it there. Cases 01-04 were red on entry (archived ticket 8777, repo events leaking into the world) and are fixed in herdr/tests/lib/world.sh.

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

- `2026-10-10` Retro. Built herdr/bin/recover.sh (halt flag, herdr, monitors, monitor seat via bringup.sh, every open seat record, guard once, ticket WARNs, closing note 100/500 plus one notification in apply mode) and herdr/tests/cases/05-recover.test.sh with a stub compaction-guard. Cases 01-04 failed on entry for two reasons unrelated to recover: ticket WO-20261010-8777 had moved to work-orders/archive/, which seat.sh refuses, and the world copied the repo's real events/ so absolute event counts were wrong. Both fixed once in tests/lib/world.sh with a breadcrumb. Decision to review: compaction-guard recover is host-wide (111 sessions needing recovery on the owner's host from other projects), so --check reports a WARN and never FAILED, and --apply will act on all of them; I did not run --apply on the host. Not done by me: AC-H4 in the labelled test pane.

## Outcome

_Written by `work-order done`. Empty until then._
