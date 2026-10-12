---
{
  "id": "WO-20261011-e618",
  "slug": "interface-agent-seat-owns-the-bearings-page-owne",
  "title": "Interface agent seat owns the bearings page: owner requests become records and the done line comes from it",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-12",
  "created_at": "2026-10-11T14:39:41+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/interface-agent-seat-owns-the-bearings-page-owne",
  "pr": 17,
  "closed": "2026-10-11",
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-2a12"
  ]
}
---

# WO-20261011-e618 - Interface agent seat owns the bearings page: owner requests become records and the done line comes from it

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

The owner talks to the architect in chat. DEC-interface-agent-owns-bearings says only the interface agent runs bearings and everything transfers at P0 completion; nothing has transferred

## Scope

**In**

- seat.sh brings up the interface-agent seat (roles/interface-agent.json: read only, dontAsk); the bearings stable serve and wait panes move into its tab
- its brief: an owner message on the page becomes a request.forwarded 300 record; a verified 201 or an owner-card 423 becomes one line on the page; on owner request it publishes a SITREP snapshot from report/sitrep/sitrep.sh and a board snapshot from report/loop/out
- the architect stops addressing the owner except through an escalation record; RUNBOOK.md: handing the owner channel to the interface agent

**Out - non-goals**

- the Go SITREP site
- bearings code changes beyond the board route (B0)

## Degrees of freedom

- [free] how the seat watches the page (bearings wait, poll of /state), as long as it is read only and runs in a labelled pane

## Acceptance criteria

- [x] `AC-H1` *(human)* interface-agent seat up with a read-only permission mode, bearings serve and wait panes in its tab
  - observed `2026-10-11` herdr case 12 (real headless herdr, stub bearings.sh): role interface-agent (permission_mode dontAsk, read_only true) came up as seat interface with panes 'MONITOR - interface|bearings-stable|bearings-stable-wait|claude-sonnet-5-5 - high - interface-agent'; pre_start ran status, serve --join and wait --to the agent pane, all three from the agent pane with the seat's tab id; a live seat repair repeats nothing; full herdr suite 12 passed, 0 failed. Not run: the live cutover of the stable page into this tab (RUNBOOK Hand over, the owner's or architect's act).
- [x] `AC-H2` *(human)* an owner message on the page produces a request.forwarded 300 record within 60 seconds with no architect involvement
  - observed `2026-10-11` make -C interface test, case 1 (Podman, bearings stub): a MESSAGE wake becomes one request.forwarded 300 to the orchestrator, seat interface, note led by the message id, page-key-shaped run scrubbed, files suffix dropped, and a second wake for the same message returns the same record and writes no second one; ANSWER is forwarded; STOPPED and prose forward nothing. Not timed against the live page; the wake path is bearings wait --to the agent pane, whose aim case 12 asserts.
- [x] `AC-H3` *(human)* a verified 201 record produces one line on the page written by the interface agent
  - observed `2026-10-11` make -C interface test, cases 3 and 4: a verified 201 for WO-20261011-e618 becomes one bearings reply threaded under the owner's last message reading '<id> - <full title> - verified 201: <note> (<record id>)'; a second run prints 'already on the page' and posts none; a 423 reads 'needs you (423)'; a 300, a record with no ticket, an unknown record and a ticket with no file are refused with exits 3, 3, 6, 6. Written by interface.sh in the interface seat's name, not the architect's. Not run against the live page.
- [x] `AC-H4` *(human)* on owner request the seat publishes a SITREP snapshot built by sitrep.sh and links it on the page
  - observed `2026-10-11` make -C interface test, case 5: snapshot sitrep renders report/sitrep/entries/2026/10/20261011-sitrep-003.json with report/sitrep/sitrep.sh into <state>/interface/snapshots (page title Qud Factory SITREP 003); snapshot board with no board under report/loop/out exits 6; snapshot --to m-100 posts a reply under that message naming the path and, with WSL_DISTRO_NAME set, its Windows form; without --to it posts none. The link is a path, not an http link, because a bearings reply carries text only (interface.sh link() breadcrumb, RUNBOOK Limits).
- [x] `AC-H5` *(human)* RUNBOOK.md lets a fresh reader hand the owner channel to an interface agent on another repo
  - observed `2026-10-11` interface/RUNBOOK.md: Hand over (stop the page, make -C interface up), Verify table, what the architect does from now on, repair and take-back, Setting this up on another repository (file list, label changes), Limits. Targets checked with make -n; seat.sh, bearings.sh, event.sh and routes.json facts read from source. Not walked by a fresh reader or run on a second repository.

## Test plan

```sh
herdr/bin/seat.sh --check interface-agent post a test message on the uat page; events/bin/event.sh list --kind request.forwarded
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Retro 2026-10-11 (worker seat). Built: interface/bin/interface.sh (forward, line, snapshot), herdr/layouts/interface-2x2.json plus a seat.sh pre_start hook, herdr case 12, interface/RUNBOOK.md, brief.txt and make up|check|down. Hurt: (1) this branch predated PR 15, so events/bin/event.sh ignored COQ_EVENTS_ROOT and the first suite run wrote seven fake records, a fake 423 among them, into the slot's real events/; the architect read the fake 423 as a block. Fixed by adopting PR 15's ROOT line and creating the temp root in the fixture. (2) The shared test pane queues behind other seats' suites; polling an output file worked, resending did not. (3) A role edit does not re-render its playbook; lint would have flagged the drift. (4) The branch copy of the ticket still said ready while the records branch said in-progress, which blocks submit; adopted the committed in-progress copy. Not done: the live cutover of the stable page and a timed live run of AC-H2, which need the owner's page; both are in the runbook. Open for the architect: the role's must lines still describe the seat writing the record itself.
- `2026-10-11` Owner 2026-10-11 16:25Z: the interface agent is station one of the line and must be built first, not last. Reordered ahead of B4 (belt) and the rest of P0; the architect stops addressing the owner once it is up.
- `2026-10-11` Owner law 2026-10-11 15:34Z (graph DEC-system-runs-the-loop, on REQ-north-star): the system runs the loop, not agents. Notification sound, automated, deterministic; cleanup done by the system; no idle agents; greens visible from records. Every hand step in SOP-0001 (wake by prompt, down after record, salvage, cleanup) must be owned by the belt when this lands.

## Outcome

_Written by `work-order done`. Empty until then._
