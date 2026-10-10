---
{
  "id": "WO-20261010-d354",
  "slug": "dated-entry-files-yyyy-mm-yyyymmdd-name-ext-fron",
  "title": "Dated entry files: YYYY/MM/YYYYMMDD-name.ext, frontmatter, UTC, one script per tree",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:43:51+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect: sure of it; owner 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for this project",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-d354 - Dated entry files: YYYY/MM/YYYYMMDD-name.ext, frontmatter, UTC, one script per tree

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

Owner order 2026-10-10 UTC: every scripted entry (logs, issues, backlog, checkpoints, index and context files) is a new file on one layout, <tree>/YYYY/MM/YYYYMMDD-<descriptive-name under 50 chars>.<ext>, with frontmatter and UTC stamps, never an overwrite. Today issues/ and backlog/ write YYYY/MM/<timestamp>-<suffix>.md, CONTEXT_STATE.md stacks checkpoints in one file, and INDEX.md is regenerated in place, so an entry can be lost and nothing is visible per entry.

## Scope

**In**

- bin/entry.sh (or one script per tree) that mints the path, writes the frontmatter (title, at, type) and refuses to overwrite; same-day same-name gets a short suffix
- checkpoint.sh new writes each checkpoint as context/YYYY/MM/YYYYMMDD-checkpoint-<slug>.md and CONTEXT_STATE.md becomes a generated index of the newest 10
- log-issue.sh and backlog.sh write YYYYMMDD-<name>.md paths; a migrate verb moves existing entries without rewriting their content
- a check verb that fails on any file in a managed tree that is off the layout or missing frontmatter, wired into make lint
- AGENTS.md hard rule 'dated entry files, one file per entry' stays inside the first 100 lines and names the script

**Out - non-goals**

- retention or pruning of old entries
- changing the work-order ticket file format itself (tickets keep the work-order skill's layout)
- rewriting the content of any existing entry

## Degrees of freedom

- [free] the name of the shared script and whether each tree keeps its own thin wrapper
- [free] the exact frontmatter keys beyond title, at and type

## Acceptance criteria

- [ ] `AC-H1` *(human)* writing two entries with the same name on the same day produces two files and the first is byte-identical afterwards
- [ ] `AC-H2` *(human)* every path under issues/, backlog/, context/ and events/ matches <tree>/YYYY/MM/YYYYMMDD-[a-z0-9-]{1,50}(-[a-z0-9]{5})?\.(md|json|jsonl) and the check verb exits 3 on one that does not
- [ ] `AC-H3` *(human)* every entry opens with frontmatter carrying title, type and an ISO 8601 UTC at with a Z suffix
- [ ] `AC-H4` *(human)* checkpoint.sh new writes a new file per checkpoint and CONTEXT_STATE.md lists the newest 10 with the top one first
- [ ] `AC-H5` *(human)* make lint runs the check verb and the repo is green

## Test plan

```sh
podman run --rm -v $PWD:/w -w /w localhost/coq-lint:1 make lint; plus the Podman suite under tests/ for the entry script: mint twice same name, check verb on a planted bad path, migrate on a fixture tree
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
