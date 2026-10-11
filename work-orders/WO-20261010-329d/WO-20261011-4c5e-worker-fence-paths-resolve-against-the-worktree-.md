---
{
  "id": "WO-20261011-4c5e",
  "slug": "worker-fence-paths-resolve-against-the-worktree-",
  "title": "Worker fence paths resolve against the worktree: render_settings substitutes ${worktree} in allow.paths and deny paths name the slot, not the main checkout",
  "type": "bug",
  "status": "ready",
  "priority": "p3",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T03:28:10+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-4c5e - Worker fence paths resolve against the worktree: render_settings substitutes ${worktree} in allow.paths and deny paths name the slot, not the main checkout

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

The a429 worker reported that roles/worker.json as rendered by seat.sh render_settings keeps the literal ${worktree} in allow.paths, so the Edit allow rule comes out as Edit(//<slot>/${worktree}/**): malformed, harmless under bypassPermissions, wrong all the same. The worker also reported the deny paths naming the main checkout; a rendered settings.json (seat worker-wo-20261011-36d7, 2026-10-11) shows that is not so: render_settings maps ${repo} to the seat's worktree already, and the deny rules name <slot>/specs/, <slot>/graph/ and <slot>/roles/. Only the allow side is broken, and the two spellings ${repo} and ${worktree} for the same path invite the next role file to get it wrong.

## Scope

**In**

- render_settings resolves ${worktree} exactly as it resolves ${repo}: the seat's worktree
- roles/worker.json (and any other role file using paths) spells the seat's worktree one way; the render_settings comment and the role schema name that spelling
- case 01 asserts the rendered settings carry the slot path in allow and deny with no literal ${worktree} or ${repo} left

**Out - non-goals**

- changing which directories a worker may edit
- the deny side, which already renders against the slot

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the rendered settings.json for a ticket seat contains no literal ${worktree} or ${repo}, allows Edit under <slot>/ and denies <slot>/roles/
- [ ] `AC-H2` *(human)* render-playbook.sh roles playbooks --check is clean and make -C herdr test passes from the labelled test pane

## Test plan

```sh
make -C herdr test from the labelled test pane, then make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Decision 2026-10-11 05:4x UTC (architect): amended before approval. Verified against seat worker-wo-20261011-36d7's rendered settings.json: deny rules already name the slot (${repo} maps to the seat worktree in render_settings), so the deny half of the original report is dropped; the defect is the unsubstituted ${worktree} in allow.paths. Freedom [fixed]: pick one spelling for the seat worktree in role paths and make render_settings accept both while the comment and the role schema name the one. Approved --no-lavish: Claude seat, Lavish prohibited by the owner hard rule.

## Outcome

_Written by `work-order done`. Empty until then._
