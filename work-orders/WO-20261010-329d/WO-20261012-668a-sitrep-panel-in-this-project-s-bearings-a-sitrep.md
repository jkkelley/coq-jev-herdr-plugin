---
{
  "id": "WO-20261012-668a",
  "slug": "sitrep-panel-in-this-project-s-bearings-a-sitrep",
  "title": "SITREP panel in this project's bearings: a #SITREP/v1# reply renders as the colored status card, built from records by a script and checked against the owner standard before it is sent",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T12:52:40+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/sitrep-panel-in-this-project-s-bearings-a-sitrep",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner ordered this work as CRITICAL on the bearings page, message m-20261012125155555-gvggg",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-668a - SITREP panel in this project's bearings: a #SITREP/v1# reply renders as the colored status card, built from records by a script and checked against the owner standard before it is sent

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

The owner reads the bearings page, and a status briefing there today is plain text in a chat bubble. The colored SITREP panel (handoff ~/.bearings/.handoff/sitrep-panel-v1, built 2026-09-16) exists only in other bearings copies, not in tools/bearings, so no seat can send the owner a briefing he can read at a glance. Owner, 2026-10-12, CRITICAL: copy it here, generic, templated and scriptable, then send a SITREP for approval.

## Scope

**In**

- port the handoff patches into tools/bearings: page.html renderer (sitrep node kind, built with textContent, unparseable payload falls back to a bubble), theme.css panel styles, server.mjs build stamp that reloads a stale tab once, reply.mjs text cap raised to 32000
- the standards STD-owner-sitrep-001 and STD-owner-comms-001 copied into tools/bearings as generic config, no owner names or paths
- a checker script enforcing every rule of sitrep-check.py, exit 1 on a violation
- a payload template and a builder script that fills it from this repo's events, work-orders and open PRs, all inputs from config
- bearings.sh <tier> sitrep --payload FILE: check, then send as a reply; refuses on a failed check
- tests in tools/bearings/tests and a RUNBOOK section

**Out - non-goals**

- changes to ~/tools/bearings-v2, ~/projects/getting-my-bearings or ~/.bearings
- lavish or any other surface
- the service supervisor

## Degrees of freedom

- [free] checker language: node or bash, as long as its rules and exit codes match sitrep-check.py case for case
- [free] builder data sources, as long as every path and count comes from config or the repo, none typed in

## Acceptance criteria

- [ ] `AC-H1` *(human)* a #SITREP/v1# reply from claude renders as the colored panel on the coq stable page, and the same text from the owner renders as a bubble
- [ ] `AC-H2` *(human)* an unparseable payload renders as an ordinary bubble
- [ ] `AC-H3` *(human)* the checker passes the last SITREP actually sent in ~/.bearings/stable-442cf4/messages.jsonl, copied in as a fixture, with exit 0, and fails a fixture that breaks the 15 word, semicolon, two item and ticket title rules with exit 1
- [ ] `AC-H4` *(human)* bearings.sh stable sitrep sends a builder payload for this repo that passes the checker, with ticket ids carrying their full titles
- [ ] `AC-H5` *(human)* make -C tools/bearings test and make lint green

## Test plan

```sh
make -C tools/bearings test; make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
