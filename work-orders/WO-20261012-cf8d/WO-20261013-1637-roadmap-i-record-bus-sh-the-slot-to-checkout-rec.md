---
{
  "id": "WO-20261013-1637",
  "slug": "roadmap-i-record-bus-sh-the-slot-to-checkout-rec",
  "title": "Roadmap I - record-bus.sh, the slot-to-checkout record copier moves from ~/.cache/coq-watch/record-bus.sh into line/bin/record-bus.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:53:15+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-i-record-bus-sh-the-slot-to-checkout-rec",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling ykne9 2026-10-13 (Roadmap I split one ticket per script); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-acdd"
  ],
  "files": [
    "line/bin/record-bus.sh",
    "line/tests/cases/record-bus.sh"
  ]
}
---

# WO-20261013-1637 - Roadmap I - record-bus.sh, the slot-to-checkout record copier moves from ~/.cache/coq-watch/record-bus.sh into line/bin/record-bus.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/record-bus.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/record-bus.sh behaves as ~/.cache/coq-watch/record-bus.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/record-bus.sh: a new record in a stub slot's events/ is copied once into the target records tree and a second tick copies nothing; the slot base and the target come from arguments or the state root, never a typed treehouse path
- after the merge (orchestrator lane): the running ~/.cache/coq-watch/record-bus.sh instance is stopped and started from $COQ_REPO/line/bin/record-bus.sh in the pane that runs it today, then ~/.cache/coq-watch/record-bus.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/record-bus.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
  - observed `2026-10-13` line/bin/record-bus.sh + line/tests/cases/record-bus.sh. Case record-bus passes in pane wD3:p16P (copy once, second tick copies nothing, held/broken/old skipped, --target and state-root bridge each once, no .tmp, files only under the state root). Breaking the already-copied check makes it FAIL on 3 assertions. grep '/home/luna|.cache/coq-watch' in the script: 0. make lint ok, make -C line test: 6 passed, 0 failed. AC-H1 clause 'every file lands under COQ_STATE' holds for the default target; the cache copy wrote into the checkout events/, so the live instance needs --target <checkout>/events (see note).
- [ ] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/record-bus.sh is empty, ~/.cache/coq-watch/record-bus.sh is gone, and the archive path is in a 200 note on this ticket

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro. Went well: the port was paths-only plus one flag set (--slots --target --held --window --interval --once) so the real script runs in the scratch world; a mutation of the already-copied check fails the case. Cost found on the way: the state-root block copies by id name, so with the default target it would have re-copied every record in; it is skipped when target equals the state records tree. Playbook step 1 (lease_holder check) does not fit a seat on a start-WO worktree with no treehouse lease; I went on from the brief's worktree.
- `2026-10-13` For the orchestrator lane (AC-H2): the default --target is the state root records tree (AC-H1: every file lands under the state root). The cache copy wrote into the checkout events/, which digest.sh and aq.sh still read, so start the live instance as: bash $COQ_REPO/line/bin/record-bus.sh --target $COQ_REPO/events. Without --target the belt and patrol see slot records in the state root but digest.sh and aq.sh do not. The live cache instance (pid 2814830, pane wD3:p14 at time of writing) is still running and untouched.

## Outcome

_Written by `work-order done`. Empty until then._
