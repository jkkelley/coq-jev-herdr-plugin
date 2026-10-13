---
{
  "id": "WO-20261012-7e13",
  "slug": "roadmap-a1-state-root-event-sh-writes-records-un",
  "title": "Roadmap A1 - State root: event.sh writes records under the state root with timestamped descriptive names, and one resolver gives every script the state and cache roots",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:13+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a1-state-root-event-sh-writes-records-un",
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
    "config/state.schema.json",
    "factory/tests/lib/world.sh",
    "herdr/tests/lib/world.sh"
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

- [x] `AC-H1` *(human)* with COQ_STATE unset, event.sh add writes under the default state root and prints the new path
  - observed `2026-10-12` events/tests case 02-add: with COQ_STATE unset and XDG_STATE_HOME inside the test world, event.sh add printed one line, <xdg>/coq/repo/records/2026/10/<14 digits>-work-started-wo-20261012-7e13.json, the file exists, and no record file appeared in the repository events/ tree. Suite log: state root tests/2026/10/20261012231146-wo-20261012-7e13-events-suite-3-of-3-green.log
- [x] `AC-H2` *(human)* with COQ_STATE set to a temp dir, the record lands there with a YYYYMMDDHHMMSS-<name>.json name and validates against the event schema
  - observed `2026-10-12` events/tests case 02-add: with COQ_STATE set to a temp dir the record landed at <state>/records/2026/10/<14 digits>-test-passed-pr-36-wo-20261012-0677.json, the file name time equals the record's at, and python3 jsonschema validated it against events/schema/event.schema.json. Suite log: state root tests/2026/10/20261012231146-wo-20261012-7e13-events-suite-3-of-3-green.log
- [x] `AC-H3` *(human)* two writes in the same second with the same name produce <name>.json and <name>-2.json, neither overwritten
  - observed `2026-10-12` events/tests case 02-add: three writes in one frozen second with one name gave <name>.json, <name>-2.json and <name>-3.json with their own notes, the first not overwritten; a name at the 55 character limit takes -2 and stays at most 55; eight parallel writers (xargs -P8) left eight distinct files and no temporary file. Suite log: state root tests/2026/10/20261012231146-wo-20261012-7e13-events-suite-3-of-3-green.log
- [x] `AC-H4` *(human)* no path or default is hardcoded in a script; every default comes from the config file
  - observed `2026-10-12` events/tests case 01-resolver: changing namespace, home_fallback, name_max and a tree name in config/state.json changed what bin/state-root.sh prints; a missing config is exit 4, not a guess; grep of the code lines (comments excluded) of bin/state-root.sh and events/bin/event.sh finds none of .local/state, .cache, /coq/, XDG_STATE_HOME, XDG_CACHE_HOME, COQ_STATE, COQ_CACHE; config/state.json validates against config/state.schema.json and make lint passed. Suite log: state root tests/2026/10/20261012231146-wo-20261012-7e13-events-suite-3-of-3-green.log

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

- `2026-10-13` Retro after ruling B. Final plan on the merged tree (origin/main with PR 80 merged): make lint ok, events/tests 3 of 3, make -C factory test 21 of 21, make -C herdr test 25 of 25; logs under tests/2026/10 of the state root, names ending factory-suite-21-of-21-green, herdr-suite-25-of-25-green, events-suite-3-of-3-green, make-lint-green. Worlds: factory/tests/lib/world.sh runs the real event.sh as event-real.sh with a temp COQ_STATE behind a shim that moves each record to the events/YYYY/MM/<id>.json place the belt reads, because route.sh and gate.sh key on the file name until A2; herdr/tests/lib/world.sh points EVENTS at the state root records tree, prints the record id from a shim (case 13 uses add's output as an id) and drops the copied .claude/skills symlink, which PR 80 did not cover and which failed case 17 in every treehouse slot. For A2 (WO-20261012-0229 - Roadmap A2 - The belt reads the state root): delete the factory shim when route.sh, flow.sh, gate.sh and policy.sh read the state root; record ids still differ from file names; herdr.json state_dir is still ~/.local/state/coq without the repo name; until A2 the live checkout must not take this event.sh. Not run: scheduler Go tests.
- `2026-10-12` Architect ruling on blocked record 20261012T231224Z-423-8cv0o: option B. Nothing merges red; no legacy switch. Add factory/tests/lib/world.sh and herdr/tests/lib/world.sh (and any test helper they strictly need, nothing under tests/cases) to the files list with claims.sh set; claims.sh start must exit 0. Each test world gives the test its own temp COQ_STATE, copies the resolver and its config, and event_count and friends read records from that state root. Both suites green except herdr case 17, which PR 80 fixes; after PR 80 merges, merge origin/main into the branch, retest the full plan, then open the PR.
- `2026-10-12` Correction to the note above: the line in factory/tests/lib/world.sh that copies only events/bin and events/schema is line 24, not 25.
- `2026-10-12` Retro and BLOCKER. Built and green in its own suite (events/tests, 3 cases, 114 checks, run in Podman through the test pane): bin/state-root.sh, config/state.json and config/state.schema.json, and event.sh add, list, tail and check on the state root (AC-H1 to AC-H4). The test plan in this ticket also names make -C factory test and make -C herdr test, and both go red because of the change itself, not a defect in it: factory 4 of 21 pass (the 17 failures are all event.sh exit 4, bin/state-root.sh is missing, because factory/tests/lib/world.sh line 25 copies only events/bin and events/schema), herdr 10 of 25 pass (14 failures are event_count reading $REPO/events while herdr/tests/lib/world.sh line 46 exports COQ_STATE=$STATE, so records land in $STATE/records; the 15th, 17-resume-checkpoint, fails on mkdir .claude/skills File exists because this slot's .claude/skills is a symlink to the installed skills, which is not A1). Neither file is in this ticket's files list, and making them read the new place needs route.sh and the seat scripts to read it too, which is item A2. Logs: tests/2026/10 under the state root, names 20261012231146-wo-20261012-7e13-*. Not run: scheduler Go tests (its testkit copies events/bin/event.sh and runs event.sh check). Other facts for A2: herdr.json state_dir is ~/.local/state/coq with no repo name, while the resolver gives ~/.local/state/coq/<repo>; a record's id field keeps the old shape, so the file name no longer equals the id. Recommended resolution: merge A1 with these suites known red and let A2 (WO-20261012-0229 - Roadmap A2) repair the worlds in the same change that switches the belt, keeping the live checkout off this event.sh until A2 lands. A fallback that writes the old tree when the resolver is missing was rejected: it would put records back in git silently.

## Outcome

_Written by `work-order done`. Empty until then._
