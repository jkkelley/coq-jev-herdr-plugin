---
{
  "id": "WO-20261012-5fa8",
  "slug": "owner-law-in-agents-md-questions-go-on-cards-pro",
  "title": "Owner law in AGENTS.md: questions go on cards, prose to the owner is short and high level, the chain is owner then architect then orchestrator then system, and tooling lives in the repository with its artifacts outside and documented",
  "type": "chore",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T23:56:17+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/owner-law-in-agents-md-questions-go-on-cards-pro",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner order on Getting My Bearings 2026-10-12 23:55Z; lavish is prohibited for Claude seats",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "AGENTS.md"
  ]
}
---

# WO-20261012-5fa8 - Owner law in AGENTS.md: questions go on cards, prose to the owner is short and high level, the chain is owner then architect then orchestrator then system, and tooling lives in the repository with its artifacts outside and documented

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

Owner orders on the bearings page 2026-10-12 22:49Z to 23:55Z lived only in the architect's private memory, so no other agent follows them. Owner: 'saved fucking where, hopefully in the AGENTS.md'.

## Scope

**In**

- AGENTS.md section 'Law: talking to the owner': every question or decision goes to the owner as a card (tools/bearings/scripts/bearings.sh stable ask FILE), never inside a reply; replies are a few short lines with blank lines between them, high level, outcomes not plumbing (no record ids, pids, pane ids or ledger paths unless asked); quote the owner: 'your prose to me needs to be spacious, concise', 'high level', 'your questions go where too'
- AGENTS.md section 'Law: the chain of command': owner, then architect, then orchestrator, then system; the architect makes rulings and designs; line operations (re-routing refused seats, downing finished seats, branch cleanup, verify on main) belong to the orchestrator and the system, never the architect; quote: 'like me > you > orchestrator > system'
- AGENTS.md section 'Law: tooling in the repository, artifacts documented': every script this project uses lives in the repository and is tracked; what scripts write lives outside it under the state or cache root and is documented, so cleanup commands can exist; quotes: 'all scripts better live within the project', 'artifacts live outside but documented always'
- AGENTS.md contents list updated for the three sections

**Out - non-goals**

- building the orchestrator (Roadmap K, card C23), the artifact manifest (Roadmap J) or moving scripts (Roadmap I)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* AGENTS.md has the three law sections with the owner quotes and dated UTC owner orders, one sentence per line, each with a GOOD and a NEVER line as the other laws have
- [ ] `AC-H2` *(human)* make lint passes in Podman

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
