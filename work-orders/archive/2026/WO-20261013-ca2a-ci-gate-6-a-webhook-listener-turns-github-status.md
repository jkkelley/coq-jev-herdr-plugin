---
{
  "id": "WO-20261013-ca2a",
  "slug": "ci-gate-6-a-webhook-listener-turns-github-status",
  "title": "CI gate 6: a webhook listener turns GitHub status, check_run and pull_request events into records, fed by gh webhook forward under systemd --user with a restart ladder",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T20:07:22+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/ci-gate-6-a-webhook-listener-turns-github-status",
  "pr": 177,
  "closed": "2026-10-14",
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

- [x] `AC-H1` *(human)* A status event for coq/gate on a head sha produces one record carrying the sha and state
  - observed `2026-10-14` line/tests/cases/hook-listener.test.sh, run from test pane wD3:p1T9 (72 checks, tests: 1 passed, 0 failed): a coq/gate status on sha 0123456789abcdef0123456789abcdef01234567 gave 200 and exactly one record with that sha, code 201 for success, 422 for failure, 100 for pending.
- [x] `AC-H2` *(human)* Killing the listener restarts it up to 3 times, then coq-hook-page.service pages the orchestrator by running `events/bin/event.sh add --kind blocked --code 423 --seat hook-listener --to orchestrator --note "<unit> failed 3 restarts"`; the page is that blocked 423 record, which factory/config/routes.json already routes (escalate to the architect, then the owner page), not a message to a pane
  - observed `2026-10-14` Same run, 'the units climb the ladder' and 'the page' checks: both listener and forward units have Restart=always, StartLimitBurst=3 equal to restart_limit in hook.json, OnFailure=coq-hook-page.service; 'hook-listener.sh page' posts blocked 423 seat hook-listener to orchestrator with note '<unit> failed 3 restarts'. systemd-analyze --user verify accepts the units. The kill and restart itself is systemd's and was not run: installing units on the host is forbidden to a worker.
- [x] `AC-H3` *(human)* The listener pipes the status payload to each handler hook.json names for the event, and skips a missing handler file with a logged note
  - observed `2026-10-14` Same run: stub-a and stub-b each received the status payload byte for byte on stdin with HOOK_SHA and HOOK_RECORD set; the missing handler file was skipped with the logged note 'skipping handler ${repo}/ci/bin/missing.sh: the file does not exist yet'; a failing handler posted a note 500 and the next still ran. make lint: all ok.

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

- `2026-10-14` Retro. (1) Step 1 lease check could not pass: the seat was brought up in a start-tickets wt- path with no treehouse lease, then start-tickets.sh/seat.sh deleted that directory (blocked 423 20261014T004237Z-423-4vsui). After the architect's 00:46Z order I recreated the worktree at the same COQ_WORKTREE path on the existing branch with git worktree add; that hand step is a defect to turn into a seat.sh fix (seat-up must lease a slot or keep the wt- path). (2) Records are kind note, not gate: gate has no routes.json row so route.sh would post a 'no route' 500 per event; a gate kind plus an ignore row is a follow-up for WO-20261013-3217 or WO-20261013-aff2 if they want to route on it. (3) The units hard-code %h/projects/coq-jev-herdr-plugin; the install (systemctl --user link, enable --now) and gh extension install cli/gh-webhook are the owner or orchestrator's one-time steps, written in the headers of hook-listener.sh and the units. (4) No payload signature check; the socket binds 127.0.0.1 only.

## Outcome

_Written by `work-order done`. Empty until then._
