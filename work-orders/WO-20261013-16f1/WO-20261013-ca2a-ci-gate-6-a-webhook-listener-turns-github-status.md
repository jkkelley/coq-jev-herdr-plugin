---
{
  "id": "WO-20261013-ca2a",
  "slug": "ci-gate-6-a-webhook-listener-turns-github-status",
  "title": "CI gate 6: a webhook listener turns GitHub status, check_run and pull_request events into records, fed by gh webhook forward under systemd --user with a restart ladder",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:07:22+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 20:20Z webhook gap (CI gate design amendment), system loop p0; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-8573"
  ],
  "blocks": [
    "WO-20261013-3217",
    "WO-20261013-aff2"
  ],
  "files": [
    "line/bin/hook-listener.sh",
    "line/config/hook.json",
    "line/config/hook.schema.json",
    "line/units/coq-hook-forward.service",
    "line/units/coq-hook-listener.service",
    "line/units/coq-hook-page.service",
    "line/tests/cases/hook-listener.test.sh"
  ]
}
---

# WO-20261013-ca2a - CI gate 6: a webhook listener turns GitHub status, check_run and pull_request events into records, fed by gh webhook forward under systemd --user with a restart ladder

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, Amendment 2026-10-13T20:20Z. This host has no public ingress. gh webhook forward (cli/gh-webhook) opens an outbound connection and forwards the repo's status, check_run and pull_request events to a localhost port; a small listener writes each as a record in the state root, so merge.sh and the main gate (tickets 3 and 4) react to events. Fallback rung: merge-watch reads the PR's coq/gate status on its 1-minute tick if the forward is down past the ladder.

## Scope

**In**

- line/bin/hook-listener.sh: listen on a localhost port from config, parse the event, post a record through events/bin/event.sh (coq/gate status on a head sha, check_run, pull_request opened or synchronize), retry 3 times then report; after the record is written it runs every handler hook.json names for that event, piping the raw payload to the handler on stdin and skipping, with a logged note, a handler file that does not exist yet (tickets WO-20261013-3217 and WO-20261013-aff2 land after this one)
- line/config/hook.json and its schema: port, repo, event list, and a handlers list mapping a status event for coq/gate to ci/bin/pr-gate-hook.sh (WO-20261013-3217 - CI gate 3) and ci/bin/main-gate.sh (WO-20261013-aff2 - CI gate 4); this ticket owns the file, so neither handler ticket edits it (no literals in the script)
- line/units/coq-hook-forward.service and coq-hook-listener.service: systemd --user, Restart=always, StartLimitBurst=3, and OnFailure= coq-hook-page.service, which pages the orchestrator
- line/units/coq-hook-page.service: a oneshot that posts the page, see AC-H2
- line/tests/cases/hook-listener.test.sh: post a sample status payload to the listener, assert one record with the head sha and that a stub handler named in a test hook.json received the same payload on stdin

**Out - non-goals**

- merge.sh and main-gate consuming the records (tickets 3 and 4)
- smee.io or any public relay, and opening a port on the host (rejected in the design)

## Degrees of freedom

- [free] Shell or a few lines of Go for the listener

## Acceptance criteria

- [ ] `AC-H1` *(human)* A status event for coq/gate on a head sha produces one record carrying the sha and state
- [ ] `AC-H2` *(human)* Killing the listener restarts it up to 3 times, then coq-hook-page.service pages the orchestrator by running `events/bin/event.sh add --kind blocked --code 423 --seat hook-listener --to orchestrator --note "<unit> failed 3 restarts"`; the page is that blocked 423 record, which factory/config/routes.json already routes (escalate to the architect, then the owner page), not a message to a pane
- [ ] `AC-H3` *(human)* The listener pipes the status payload to each handler hook.json names for the event, and skips a missing handler file with a logged note

## Test plan

```sh
bash line/tests/cases/hook-listener.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
