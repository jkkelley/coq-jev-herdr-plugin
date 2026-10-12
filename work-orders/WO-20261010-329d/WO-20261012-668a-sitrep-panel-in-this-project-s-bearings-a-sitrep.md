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

- [x] `AC-H1` *(human)* a #SITREP/v1# reply from claude renders as the colored panel on the coq stable page, and the same text from the owner renders as a bubble
  - observed `2026-10-12` tests/sitrep.sh S8 in make -C tools/bearings test (113 passed, 0 failed, test pane wD3:p7B, 2026-10-12 13:11 UTC): a claude message with #SITREP/v1# draws exactly 1 .sitrep panel (5 blocks, 4 stat cards, 4 queue cards, pill DEGRADED), the identical text from the owner and an unparseable claude payload each draw a bubble. Panel screenshot reviewed: /tmp/claude-1000/shots/sitrep-panel.png. The coq stable page itself only draws it once this branch is merged and make upgrade runs from main.
- [x] `AC-H2` *(human)* an unparseable payload renders as an ordinary bubble
  - observed `2026-10-12` tests/sitrep.sh S8: claude message '#SITREP/v1#{this is not json' renders as an ordinary bubble, thread order panel,bubble,bubble, zero page errors, no [object Object], announcer reads 'SITREP received' not the braces
- [x] `AC-H3` *(human)* the checker passes the last SITREP actually sent in ~/.bearings/stable-442cf4/messages.jsonl, copied in as a fixture, with exit 0, and fails a fixture that breaks the 15 word, semicolon, two item and ticket title rules with exit 1
  - observed `2026-10-12` tests/fixtures/sitrep-sent-ok.txt is message m-c20260916163752447, the last SITREP sent on the source page: node scripts/sitrep-check.mjs exits 0 ('8 items, 70 words of prose, 0 violations'), same as sitrep-check.py. tests/fixtures/sitrep-bad.json exits 1 naming '18 words, limit is 15' style, semicolon, '3 items, limit is 2', ticket id in the prose, 'carries no full title', more than one sentence; each rule also proved alone (S2 cases)
- [x] `AC-H4` *(human)* bearings.sh stable sitrep sends a builder payload for this repo that passes the checker, with ticket ids carrying their full titles
  - observed `2026-10-12` bearings.sh stable sitrep --payload briefing.txt exit 0 from this branch: sitrep-build.mjs on this repo's real records gave 7 items, 44 words, 5996 chars, 0 violations; the send wrote a claude reply to m-20261012125155555-gvggg, 5996 chars, into a scratch page directory (scratchpad ac4/state/coq-stable). Refs carry full titles read from the ticket files, e.g. WO-20261012-668a - SITREP panel in this project's bearings: a #SITREP/v1# reply renders as the colored status card, built from records by a script and checked against the owner standard before it is sent. NOT sent to the live stable page: a worker has no owner channel and stable still runs main without the renderer; the interface agent sends it after merge. Suite S5 proves send, refusal (exit 3, nothing written) and unknown --to (exit 6) on a live dev page
- [x] `AC-H5` *(human)* make -C tools/bearings test and make lint green
  - observed `2026-10-12` make -C tools/bearings test: 'bearings tests: 113 passed, 0 failed' in the test pane wD3:p7B 2026-10-12 13:11 UTC; make lint green as the lint step of make step (commit 4561c50, ok), after fixing two shellcheck warnings in tests/sitrep.sh found by that run

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

- `2026-10-12` Retro. Ported: page.html hunk 3 by hand (the vendored page has a files field the handoff base lacked), server.mjs and reply.mjs by hand (they diverged), theme.css clean. Decisions: reply cap is a new config key max_reply_chars (32000) so the owner's typed messages stay at 8000; checker is node with rules in scripts/lib/sitrep.mjs and limits in config/sitrep.json, a superset of sitrep-check.py (added: five blocks in order, link scheme, queue entry titles read from next_items, reply cap) and it still passes the real sent SITREP; the python checker read dicts in next where the payload has strings, so the title rule never fired there. Builder friction rule: newest failure record inside 24h with no later passing record on the same ticket or seat. Limit: a briefing is only as true as the records. Open for the interface agent: the live stable send (AC-H4 above) after merge and make upgrade; ticket-id regexes in config/sitrep.json cover WO- ids plus the handoff prefixes.

## Outcome

_Written by `work-order done`. Empty until then._
