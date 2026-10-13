---
{
  "id": "WO-20261012-90ce",
  "slug": "roadmap-i-line-scripts-live-in-the-repo-the-merg",
  "title": "Roadmap I - Line scripts live in the repo: the merge watch, digest, route retry, record bus, ticket start, seat queue and main verify scripts move from ~/.cache/coq-watch into line/, and everything they write goes to the state root",
  "type": "chore",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:51:31+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner order on Getting My Bearings 2026-10-12 22:49Z; lavish is prohibited for Claude seats",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/*",
    "ROADMAP.md"
  ],
  "superseded_by": "WO-20261013-acdd"
}
---

# WO-20261012-90ce - Roadmap I - Line scripts live in the repo: the merge watch, digest, route retry, record bus, ticket start, seat queue and main verify scripts move from ~/.cache/coq-watch into line/, and everything they write goes to the state root

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

Owner 2026-10-12 22:49Z (bearings m-20261012224955626-rjghl): all scripts live within the project; only their artifacts sit outside it, with clear instructions where they sit. Seven interim scripts that run the line today live in ~/.cache/coq-watch: outside git, never tested or reviewed, with hardcoded /home/luna paths, writing logs next to themselves.

## Scope

**In**

- line/bin/ holds merge-watch.sh, digest.sh, route-retry.sh, record-bus.sh, seat-queue.sh, start-tickets.sh (from start-roadmap.sh) and verify-main.sh (from verify-phase1.sh), each behaving as its ~/.cache/coq-watch source does today, breadcrumb comments kept
- each script finds the repository root from its own location, and the state and cache roots from bin/state-root.sh when present, else COQ_STATE and COQ_CACHE with the ROADMAP.md defaults
- every log, seen set, pid file and lock is written under the state root, logs named by the ROADMAP.md rule; nothing is written in the repository or in ~/.cache/coq-watch
- line/README.md: per script, what it does, the pane that runs it, how it stops (the halt flag run/line.halted), the roadmap ticket that retires it, and the exact path of every file it writes
- line/Makefile with a test target that runs line/tests in Podman, as the other areas do
- ROADMAP.md: this item listed under Phase 2 as an owner addition, 2026-10-12

**Out - non-goals**

- changing what the scripts do
- the root Makefile, claimed by tickets G, F and C
- retiring the scripts; roadmap items A, B, C and D replace them
- one-off scripts that already ran; the architect archives those to the state root

## Degrees of freedom

- [free] file names inside line/bin, as long as line/README.md maps each one to its old ~/.cache/coq-watch name

## Acceptance criteria

- [ ] `AC-H1` *(human)* no file under line/ contains /home/luna or .cache/coq-watch
- [ ] `AC-H2` *(human)* with COQ_STATE set to a temp dir, every file a script writes lands under it, and none in the repository
- [ ] `AC-H3` *(human)* merge-watch test: the first run seeds past merges without a prompt, one new merge gives exactly one stubbed prompt, a second tick repeats nothing, and the halt flag makes it exit
- [ ] `AC-H4` *(human)* digest test: two addressed records in one interval give exactly one stubbed prompt
- [ ] `AC-H5` *(human)* make -C line test and make lint pass in Podman

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

- `2026-10-12` 2026-10-12 23:50Z architect: route-retry.sh now also retries a max_agents refusal when a slot is free (PR 80 merger waited 17 min, record h7h10). The moved line/bin/route-retry.sh keeps that behaviour.

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: architect ruling ykne9: split into one ticket per ~/.cache/coq-watch script (13) under the size rule; this closing ticket ends the split
- superseded by: `WO-20261013-acdd`

No branch, no PR and no merge commit exist for this work order.

