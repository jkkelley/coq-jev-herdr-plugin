---
{
  "id": "WO-20261010-ba08",
  "slug": "vendor-bearings-into-tools-bearings-with-stable-",
  "title": "Vendor bearings into tools/bearings with stable, uat and dev tiers",
  "type": "feature",
  "status": "in-progress",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T18:17:38+00:00",
  "parent": "WO-20261010-98ea",
  "branch": "feat/vendor-bearings-into-tools-bearings-with-stable-",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Lavish is prohibited for Zenith by the owner-surface rule; approved by the owner on the bearings page, card Q9, 2026-10-10 UTC",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers

## Problem

The bearings page the owner uses runs from ~/.claude/skills/bearings, a Sep 15 snapshot that shipped a startup crash (null element listener) and has no tests, no config and no way to try a change without touching the owner's live page.

## Scope

**In**

- copy server.mjs, wait.mjs, reply.mjs, page.html, theme.css into tools/bearings and strip every hardcoded value into config/bearings.json with a JSON schema
- three tiers from config: stable (main checkout, the owner's page), uat (treehouse worktree on the PR branch, verified by the owner or a verifier seat), dev (feature worktree, where tests run); each with its own page name, port, state dir and labelled herdr pane
- Makefile entry points: serve, stop, wait, reply, status, test, verify, upgrade; a Podman Playwright test that loads the page and asserts Live, cards rendered, no page errors, answer round-trip
- tools/bearings/AGENTS.md with a contents list, GOOD and NEVER examples, the dev to uat to stable promotion procedure

**Out - non-goals**

- changing the card format or the theme (SKILL.md: only after the owner approves a sample)
- the SITREP site and websocket channel (sibling ticket)
- editing the copy in ~/.claude/skills/bearings beyond the breadcrumbed null-guard already applied

## Acceptance criteria


- [ ] `AC-H1` *(human)* make -C tools/bearings test passes in Podman: scratch state dir, /state returns the cards, page reports Live with cards rendered, zero page errors, one queued answer appears in answers.jsonl
- [ ] `AC-H2` *(human)* no hardcoded port, host, path, page name or poll interval remains in scripts/; every tunable is read from config/bearings.json and a missing or invalid key fails with exit 3 naming the key
- [ ] `AC-H3` *(human)* stable, uat and dev tiers each start from their own checkout with distinct page name, port, state dir and herdr pane label; a second start of the same tier is refused with exit 3 and the live url printed
- [ ] `AC-H4` *(human)* tools/bearings/AGENTS.md opens with a contents list and carries at least three GOOD and three NEVER examples plus the promotion procedure
- [ ] `AC-H5` *(human)* the stable tier serves the owner's current questions and answers migrated from ~/.bearings/coq-jev-herdr-plugin-05518e with no answer lost, verified by diffing answers.jsonl

## Test plan

```sh
make -C tools/bearings test # podman run --rm --network=host -v tools/bearings:/skill:ro -v scratch:/work mcr.microsoft.com/playwright/python@sha256:14a2d829e8cf75dcca11f38da9878b4b0f42299d6c6edcd864d64c5594ec28eb
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-10` Owner, 2026-10-10 UTC: the work-order skill in dotfiles gains a Degrees of freedom section and a Contents list before further tickets are cut; tracked as its own dotfiles ticket

## Outcome

_Written by `work-order done`. Empty until then._
