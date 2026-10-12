---
{
  "id": "WO-20261011-5064",
  "slug": "merger-regenerates-generated-files-on-a-merge-co",
  "title": "Merger regenerates generated files on a merge conflict: a 409 whose only conflicts are CHANGELOG.md, INDEX.md or epic READMEs is resolved by their scripts, not kicked back",
  "type": "bug",
  "status": "cancelled",
  "priority": "p1",
  "created": "2026-10-11",
  "updated": "2026-10-12",
  "created_at": "2026-10-11T16:11:37+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-12",
  "approval": {
    "via": "override",
    "reason": "Claude seat: Lavish prohibited for Claude runtimes; architect approves, every main move today cost a hand merge of generated files",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "superseded_by": "WO-20261012-0677"
}
---

# WO-20261011-5064 - Merger regenerates generated files on a merge conflict: a 409 whose only conflicts are CHANGELOG.md, INDEX.md or epic READMEs is resolved by their scripts, not kicked back

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

Every PR that lands after another PR conflicts on CHANGELOG.md, work-orders/INDEX.md and the epic README, because all three are regenerated on every make step. PR 12 and PR 14 each took a 409 round for this on 2026-10-11: merger 409, worker merges main and regenerates, tester and reviewer run again on the new head, merger again. That is three seats of work for files that have one deterministic source.

## Scope

**In**

- merger playbook and roles/merger.json: on a 409 whose conflicting paths are all generated files, merge origin/main, run bin/changelog.sh render and work-order.sh reindex, commit the merge, push, and continue to the merge; the test and review records on the pre-merge head stay valid because no hand-written file changed
- routes.json: merge.conflict 409 with only generated paths routes to the merger, not the worker

**Out - non-goals**

- conflicts in any hand-written file, which stay a worker kickback

## Degrees of freedom

- [free] how the merger lists generated paths, as long as the list lives in one file the lint reads

## Acceptance criteria

- [ ] `AC-H1` *(human)* a PR whose only conflicts are the three generated files is merged by the merger seat with no worker, tester or reviewer wake, shown on one real PR
- [ ] `AC-H2` *(human)* a PR with a conflict in a hand-written file still produces merge.conflict 409 to the worker; a herdr/tests or factory test case covers both

## Test plan

```sh
make -C factory test in the labelled test pane
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` architect 21:25Z: start deferred. The ticket exists only on chore/architect-records-20261011; starting from main failed and a stray commit 7c58cde reached main. Starts from main resume once the records branch has merged to main through the line (after PR 15 and PR 17).
- `2026-10-11` architect 21:20Z: generated-path set seen in every 409 today: CHANGELOG.md, changelog/, work-orders/INDEX.md, epic README.md, graph/INDEX.md, graph/GRAPH.mmd (graph.sh index); CONTEXT_STATE.md and .gitignore keep both sides by union. Nine hand merges by the architect on 2026-10-11 (PR 11, 15 x3, 16, records branch x3) were all this set.

## Outcome

Cancelled `2026-10-12` - nothing shipped.

- reason: superseded: owner 2026-10-12 18:07Z wants no clash ever, so generated files leave PRs instead of the merger resolving their conflicts
- superseded by: `WO-20261012-0677`

No branch, no PR and no merge commit exist for this work order.

