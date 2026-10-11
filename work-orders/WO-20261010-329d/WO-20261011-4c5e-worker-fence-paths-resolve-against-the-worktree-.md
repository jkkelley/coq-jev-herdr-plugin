---
{
  "id": "WO-20261011-4c5e",
  "slug": "worker-fence-paths-resolve-against-the-worktree-",
  "title": "Worker fence paths resolve against the worktree: render_settings substitutes ${worktree} in allow.paths and deny paths name the slot, not the main checkout",
  "type": "bug",
  "status": "draft",
  "priority": "p3",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T03:28:10+00:00",
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

The a429 worker reported two gaps in roles/worker.json as rendered by seat.sh render_settings: allow.paths keeps the literal ${worktree} so the rendered Edit allow rule is malformed (harmless under bypassPermissions, wrong all the same), and the deny paths ${repo}/specs/, ${repo}/graph/, ${repo}/roles/ name the main checkout, so a worker edits specs/, graph/ and roles/ in its own slot freely, which is exactly where it works. The 8fa8 worker hit the opposite edge: a sed -i on roles/ in a hand-rolled worktree was denied by path.

## Scope

**In**

- render_settings substitutes ${worktree} everywhere it substitutes ${repo}
- roles/worker.json deny paths name ${worktree}/specs/, ${worktree}/graph/, ${worktree}/roles/ (and keep the ${repo} ones); the playbook re-renders
- case 01 asserts the rendered settings carry the slot path in both allow and deny and no literal ${worktree}

**Out - non-goals**

- changing which directories a worker may edit

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the rendered settings.json for a ticket seat contains no literal ${worktree} and denies <slot>/roles/
- [ ] `AC-H2` *(human)* render-playbook.sh roles playbooks --check is clean

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

## Outcome

_Written by `work-order done`. Empty until then._
