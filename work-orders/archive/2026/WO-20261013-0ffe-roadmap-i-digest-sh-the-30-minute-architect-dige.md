---
{
  "id": "WO-20261013-0ffe",
  "slug": "roadmap-i-digest-sh-the-30-minute-architect-dige",
  "title": "Roadmap I - digest.sh, the 30-minute architect digest moves from ~/.cache/coq-watch/digest.sh into line/bin/digest.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T17:52:41+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-i-digest-sh-the-30-minute-architect-dige",
  "pr": 119,
  "closed": "2026-10-14",
  "approval": {
    "via": "override",
    "reason": "architect ruling ykne9 2026-10-13 (Roadmap I split one ticket per script); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-acdd",
    "WO-20261014-8814"
  ],
  "files": [
    "line/bin/digest.sh",
    "line/tests/cases/digest.sh"
  ]
}
---

# WO-20261013-0ffe - Roadmap I - digest.sh, the 30-minute architect digest moves from ~/.cache/coq-watch/digest.sh into line/bin/digest.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/digest.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/digest.sh behaves as ~/.cache/coq-watch/digest.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/digest.sh: with DIGEST_SECONDS shortened, two records addressed to the architect in one interval give exactly one stubbed prompt, and an interval with none gives no prompt
- after the merge (orchestrator lane): the running ~/.cache/coq-watch/digest.sh instance is stopped and started from $COQ_REPO/line/bin/digest.sh in the pane that runs it today, then ~/.cache/coq-watch/digest.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/digest.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
  - observed `2026-10-13` make lint exit 0; make -C line test: 6 passed, 0 failed from test pane wD3:p16Q, digest case 18 checks ok; with the window filter broken the case fails 5 checks; grep of /home/luna and .cache/coq-watch in line/bin/digest.sh: 0 each; the case asserts the state root holds only records and run/digest.last
- [x] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/digest.sh is empty, ~/.cache/coq-watch/digest.sh is gone, and the archive path is in a 200 note on this ticket
  - observed `2026-10-14` NOT MET, split out, not ticked as done work: PR 119 is MERGED 2026-10-13T19:46:38Z, but at 2026-10-14 00:02Z pgrep -f coq-watch/digest.sh counts 1 process(es) and ~/.cache/coq-watch/digest.sh is exists, so the cutover has not happened. This criterion moved to WO-20261014-8814 - Roadmap I cutover (duplicate audit F7, ruled 2026-10-13T23:55Z); closing this ticket on AC-H1 (the merged code), per the ruling to split what cannot be observed.

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

- `2026-10-13` Retro. digest.sh moved as it was with three record-format fixes kept inside the same behaviour: it read the repo events/ tree (empty since A1), cut its window on a file name that no longer sorts against the stamp, and counted route failures by a file name pattern; it now reads the state root records tree and cuts on the record at field. Added DIGEST_ROUNDS as a test hook. Worker lease deviation: this worktree was cut by wo-start.sh (start-WO-20261013-0ffe), so treehouse status lists no lease for it; worked here as the brief named. AC-H2 (stop the running instance, start it from the repo, archive and delete the cache copies and .bak files, put the archive path in a 200 note) is the orchestrator lane after the merge.

## Outcome

_Written by `work-order done`. Empty until then._
