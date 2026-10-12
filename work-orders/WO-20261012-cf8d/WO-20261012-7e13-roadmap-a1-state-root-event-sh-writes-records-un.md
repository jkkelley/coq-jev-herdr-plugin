---
{
  "id": "WO-20261012-7e13",
  "slug": "roadmap-a1-state-root-event-sh-writes-records-un",
  "title": "Roadmap A1 - State root: event.sh writes records under the state root with timestamped descriptive names, and one resolver gives every script the state and cache roots",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:13+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-0229"
  ],
  "files": [
    "events/bin/*",
    "events/schema/*",
    "events/tests/*",
    "bin/state-root.sh",
    "config/state.json",
    "config/state.schema.json"
  ]
}
---

# WO-20261012-7e13 - Roadmap A1 - State root: event.sh writes records under the state root with timestamped descriptive names, and one resolver gives every script the state and cache roots

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

Records are committed to git under events/, named <UTC>-<code>-<suffix>.json that say nothing until opened (ROADMAP.md, Where runtime data lives; owner cards C10, C11).

## Scope

**In**

- a resolver script that prints the state root and cache root: COQ_STATE and COQ_CACHE when set, else the defaults from a schema-validated config file (XDG state and cache homes plus coq/<repo>)
- event.sh add writes records to <state>/records/YYYY/MM/YYYYMMDDHHMMSS-<descriptive name>.json, name at most 55 characters, lowercase, hyphens; exclusive create with -2, -3 on a same-second same-name clash
- event.sh list, tail and check read the state root and, until A4, the repository events/ too

**Out - non-goals**

- switching the belt, seats, reports or bearings to the state root (A2, A3)
- removing events/ from git (A4)

## Degrees of freedom

- [free] how the descriptive name is built from kind, ticket and pr, as long as it is unique within the second and under 55 characters

## Acceptance criteria

- [ ] `AC-H1` *(human)* with COQ_STATE unset, event.sh add writes under the default state root and prints the new path
- [ ] `AC-H2` *(human)* with COQ_STATE set to a temp dir, the record lands there with a YYYYMMDDHHMMSS-<name>.json name and validates against the event schema
- [ ] `AC-H3` *(human)* two writes in the same second with the same name produce <name>.json and <name>-2.json, neither overwritten
- [ ] `AC-H4` *(human)* no path or default is hardcoded in a script; every default comes from the config file

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
