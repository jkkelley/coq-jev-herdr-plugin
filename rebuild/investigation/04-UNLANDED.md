# 04 - Everything not on main, with a verdict

Lead deliverable of step R-01 of the Factory Rebuild investigation.
Finished 2026-10-14T03:17Z (UTC) by the merge seat; revised 2026-10-14T03:45Z (sections 11 and 12 added).
Snapshot: `origin/main` at `b7a3c5d` (2026-10-14T02:49:41Z); the owner checkout `~/projects/coq-jev-herdr-plugin` is on `main` at `5ad1996`, 2 commits behind.
Sources are L05 (`L05-git-state.md`, with its evidence scripts in `L05-evidence/`), L05b (the worktree snapshot of 2026-10-14T02:50:25Z), L02, L08, L09, L10, and read-only `git` and `gh` calls made by the merge seat at 03:05Z to 03:20Z.
Owner order behind this file: "everything needs to get on main too, dont leave that shit laying around" (`~/.claude/history.jsonl` line 21023, 2026-10-14T02:49:18Z).
Nothing here was changed; every verdict is a proposal for a cleanup ticket, and none runs before GOFACTORY (section 12; D25).

## Contents

1. Verdict codes
2. Open pull requests
3. Remote branches not merged to main (34)
4. Stale remote refs
5. Local-only branches, gone branches and the stash
6. Worktrees (88)
7. Uncommitted and untracked changes in the owner checkout
8. Runtime and scripts outside the repository that should be in it or deleted
9. Merged but dark, and ruled or ready but unbuilt
10. Other repositories
11. Open GitHub issues (33)
12. Ordering and trigger
13. Sources

## 1. Verdict codes

| Code | Meaning | Who acts |
| --- | --- | --- |
| LAND | Bring it onto main as is or through one small ticket | A rebuild build ticket |
| SUPERSEDE | Its content reached main another way or is replaced by a rebuild decision; tag if it has history worth keeping, then delete | The rebuild cleanup ticket |
| CLOSE | Nothing worth keeping; delete the branch, ref, worktree or file | The rebuild cleanup ticket |
| KEEP | Hold until the named work or decision lands, then re-verdict | Nobody until the trigger |
| DECIDE | Blocked on a decision in `03-DECISIONS.md` | Owner |

## 2. Open pull requests

| PR | Branch | State | Verdict | Reason |
| --- | --- | --- | --- | --- |
| 35 | `feat/factory-design-spec-v2-0-every-agent-workflow-ru` (WO-20261012-fd87 - Factory design spec v2.0: every agent, workflow, runbook, SOP, schema and status code of the small loop and the software factory, generic and portable) | open since 2026-10-12T18:28:25Z, CONFLICTING, 113 to 114 behind, 0 reviews | DECIDE D14, then CLOSE | Describes a machine 114 commits old; 8 of its 14 files are changelog, record or aggregate files the source-only rule forbids; its S2-051 "Bus decided: NATS" contradicts C15; a second XML format with its own checker (L03 sections 4.7 and 5.5; L05 section 9). Its slot lease on treehouse slot 2 is about 30 hours old and goes with it (L02 section 5 item 7). |

No other PR is open; 142 PRs are merged and 5 closed unmerged (L05 section 4).

## 3. Remote branches not merged to main

Verdicts from L05 section 9, re-checked against the ticket statuses on main at 03:10Z.

| Branch | Holds | Verdict | Reason |
| --- | --- | --- | --- |
| `backup/4562-before-rebuild` | Snapshot of the break-glass work, 77 ahead, 130 behind | SUPERSEDE (tag, delete) | WO-20261011-4562 - Break glass: one owner-authorised action at a time flips one seat to bypass permissions and back, recorded, never a session or a day is done on main |
| `chore/seat-deny-from-declared-files-ticket` | Draft ticket WO-20261013-4c0d - Seat deny list derives from the ticket's declared files | DECIDE D13 | Overlaps three ready fence tickets on main (L05 section 9); D13 B makes the fence a launch property |
| `feat/factory-design-spec-v2-0-every-agent-workflow-ru` | PR 35 | DECIDE D14 | See section 2 |
| `feat/go-scheduler-design-one-xml-spec-per-domain-unde` | Eleven SPEC-16 domain specs and eight graph nodes (WO-20261012-5826 - Go scheduler design: one XML spec per domain under specs/scheduler, each at most 1000 lines, plus the build tickets cut for four Opus workers, PR 37 closed) | KEEP until D09 | Ten build tickets take their file from this branch at `012fa41`; under D09 B, keep only what the cut packages need, then delete |
| `feat/herdr-stable-dies-with-a-segv-at-31-8g-and-nothi` | One "started" commit for WO-20261013-77c0 - herdr-stable dies with a SEGV at 31.8G and nothing brings the seats back: it has no memory ceiling, no core kept, and no restart that resumes each seat by its pane session id | CLOSE | Status flip and changelog line only; the ticket is ready on main and becomes part of D08 |
| `feat/interface-agent-seat-owns-the-bearings-page-owne` | PR 17 work, 37 commits, 119 files (WO-20261011-e618 - Interface agent seat owns the bearings page: owner requests become records and the done line comes from it) | DECIDE D12 | Kept for Phase 5 by PR 17's closing comment; D12 B replaces the agent reader with the owner lane, so most of it would be superseded |
| `feat/record-bus-every-slot-s-new-records-reach-the-ch` | PR 25 (WO-20261012-da52 - Record bus: every slot's new records reach the checkout events/ within ten seconds, so the belt routes seat records with no copy by hand) | SUPERSEDE | Card C17; the state root replaces it (L05 section 9) |
| `feat/replay-fixtures-one-golden-case-per-routes-row-a` | WO-20261012-8d87 - Replay fixtures: one golden case per routes row and per policies row under scheduler/testdata/replay, derived from the factory suite's cases, synthetic, with a schema and a check script; 6 commits, 46 files absent on main, never a PR | KEEP until D09 | Golden cases per routes row are exactly the reconciler's regression suite under D01 B, but they read `events/`, which A4 removes (L05 section 5 item 10) |
| `feat/spike-1-native-linux-qud-runs-in-wsl2-under-xvfb` | Nothing: 0 ahead | CLOSE | WO-20261010-eaa3 - Spike 1: native Linux Qud runs in WSL2 under Xvfb or WSLg is cancelled |
| `feat/tester-reviewer-and-merger-seats-come-up-through` | PR 15 (WO-20261011-23df - Tester, reviewer and merger seats come up through seat.sh and each writes one record on a real PR) | SUPERSEDE | Seats come up through `seat.sh` on main already; D11 retires two of the three roles |
| `feat/the-patrol-saw-eight-line-processes-dead-56-time` | "started" commit only | CLOSE | WO-20261013-1e9f - The patrol saw eight line processes dead 56 times but only queued them for an architect who was dead, and posts no card on the owner page is cancelled and re-cut as WO-20261013-9617 (same title, re-cut at `line/bin/patrol-tick.sh`) |
| `feat/threshold-per-role-seat-sh-renders-a-guard-schem` | Started commit and epic ticket copies | CLOSE | WO-20261012-c41f - Threshold per role: seat.sh renders a guard schema per seat from its role, so the guard compacts at the role's threshold and names the seat is ready on main; under D02 B the guard memo path goes away |
| `feat/verifier-seat-a-merged-record-wakes-a-verifier-t` | PR 29 (WO-20261012-72a0 - Verifier seat: a merged record wakes a verifier that checks the merge on main against the ticket's criteria and posts verified or rejected, so no merge waits on the architect) | SUPERSEDE | Card C18 and `verify-main.sh` (L05 section 9) |
| 21 `tmp-*` branches (`tmp-WO-20261012-` 0677, 277d, 3bb0, 3cb1, 48ab, 5826, 5d09, 72a0, 8d87, 8f4f, 8fb2, 9b2c, 9f5d, c41f, da52, df2b, e27e, e36e, ee9c, fd87, and `tmp-b800`) | One ticket-carry commit each | CLOSE | Pure carry branches from the retired records branch; their tickets are on main (16 done, 2 cancelled, 2 ready) or on PR 35 (L05 section 9) |

Net: delete 28, tag and delete 1, keep 5 for a named decision (L05 section 9, unchanged at `b7a3c5d`).
Also set the repository's `delete_branch_on_merge` to true; it is false today (L05 section 5 item 7).

## 4. Stale remote refs

| Ref | Verdict | Reason |
| --- | --- | --- |
| `refs/remotes/pr/36`, `pr/37`, `pr/38`, `pr/40`, `pr/41`, `pr/42` (a second remote named `pr`) | CLOSE (remove the remote) | PRs 36, 38, 40, 41 and 42 merged on 2026-10-12 and PR 37 closed on 2026-10-13 (`gh pr view`, read 03:10Z) |

## 5. Local-only branches, gone branches and the stash

Patch counts below come from `git cherry origin/main <branch>`, which over-counts after squash merges, so the ticket status on main decides the verdict.

| Branch | State | Verdict | Reason |
| --- | --- | --- | --- |
| `backup/4db1-merge-8ee2c45`, `backup/4db1-old-base` | snapshots of WO-20261011-4db1 - Belt seats the line: route.sh brings a role seat up before a wake, takes a seat down after its gate record, and ignores housekeeping records by table | SUPERSEDE (tag, delete) | Ticket done on main |
| `backup/8fb3-a930f3c` | snapshot of WO-20261011-8fb3 - seat.sh adopt: a running claude session becomes a seat in place, keeping its context, under the role's label, settings and record | SUPERSEDE (tag, delete) | Ticket done |
| `backup/ceea-wip-3c7864f`, `backup/ceea-wip-reboot-58118eb`, and `stash@{0}` | WIP of WO-20261011-ceea - Blueprint page: report/loop renders the system design from graph/ and work-orders/ as done, in flight and coming up, in the board's format, served by bearings at /blueprint | SUPERSEDE (archive to the state root backup tree, delete) | Ticket done (commit `f329478`, #24) |
| `chore/approve-WO-20261010-ba08` | one approval commit for WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers | CLOSE | Ticket done |
| `chore/cut-cause-ab`, `chore/reindex-main`, `chore/roadmap-a3-split`, `feat/recover-sh-check-apply-per-run-recover-with-its-` | 0 unmerged patches | CLOSE | Content is on main |
| `chore/dd47-cap-test` | cut for WO-20261013-5f41 - Role caps pinned: herdr case 28 asserts the seat caps pull request 99 sets (worker 6, reviewer 4, orchestrator 2), 0 unmerged patches | CLOSE | The cut is on main; the ticket is ready |
| `chore/system-loop-tickets` | 2 commits ahead, cut of WO-20261013-d127 - Cause 2wbaq: a SPEC-16 spec ticket's worker is denied specs/ and graph/; a spec-author role (the worker on claude-opus-5-5 with specs/ and graph/ writable, roles/ still denied, three seats) and seat.sh picks it when every file of the ticket is under specs/ or graph/ | CLOSE | Ticket done on main |
| `pr88` | 4 commits for WO-20261012-0229 - Roadmap A2 - The belt reads the state root: route.sh, flow.sh, gate.sh and policy.sh read records and keep their ledger and belt files under the state root | CLOSE | Ticket done (PR 88 merged) |
| `tmp-668a` | cut of WO-20261012-668a - SITREP panel in this project's bearings: a #SITREP/v1# reply renders as the colored status card, built from records by a script and checked against the owner standard before it is sent | CLOSE | Ticket done |
| `tmp-WO-20261012-9f5d` (local) | cut of WO-20261012-9f5d - Case 17-resume-checkpoint builds its own CONTEXT_STATE.md in its test world, so it passes now that the file is gitignored | CLOSE | Ticket done |
| 8 branches whose upstream is `[gone]` (`feat/cause-ab-...`, `feat/cause-m-routes-...`, `feat/gate-models-...`, `feat/roadmap-i-record-bus-sh-...`, `feat/test-speed-a-path-...`, `feat/test-speed-polls-part-1-...`, `feat/test-speed-polls-part-4-...`, `fix-pr96`) | merged and deleted upstream | CLOSE | L05 section 3 |

Every title in this table is copied whole from the ticket file's front matter.

## 6. Worktrees (88)

| Group | Count | Verdict | Reason |
| --- | --- | --- | --- |
| Owner checkout `~/projects/coq-jev-herdr-plugin` | 1 | KEEP | The main checkout; see section 7 |
| Treehouse pool slots `~/.treehouse/coq-jev-herdr-plugin-f314e6/{1,2,4..10}` | 9 | KEEP the pool, release slot 2 with PR 35 | Slot 2 holds PR 35's branch under a 30-hour lease (L02 section 5 item 7); `treehouse.toml` says `max_trees = 8` while 9 exist, and a second empty pool exists |
| `~/.cache/wt-sched` (go-scheduler design branch at `012fa41`) and `~/.cache/wt-sched-w3` (replay-fixtures branch) | 2 | KEEP until D09 | They hold the two KEEP branches |
| `start-WO-20261013-1e9f`, `start-WO-20261013-77c0` | 2 | CLOSE with their branches | Section 3 |
| `verify-b7a3c5d` | 1 | CLOSE after the next verify | Current main; transient |
| All other `cut-*`, `pr*`, `wt-*`, `start-*`, `start-tickets/*`, `verify/*` and `~/.cache/wt-*` entries | 73 | CLOSE | 81 of 88 are detached heads of finished work (L05 section 3; L05b section 3) |

## 7. Uncommitted and untracked changes in the owner checkout

| Change | Verdict | Reason |
| --- | --- | --- |
| The checkout is 2 commits behind `origin/main` | LAND (fast-forward) | `ae0140e` and `b7a3c5d` are on origin only (L05 section 3) |
| ` M work-orders/WO-20261013-16f1/WO-20261014-539a-cause-ay-scheduler-testkit-world-copies-events-b.md` (status `ready` to `in-progress`, branch set) | CLOSE (discard) | Start residue; on `origin/main` the ticket WO-20261014-539a - Cause ay: scheduler testkit world copies events/bin/event.sh without bin/state-root.sh and config/state.json, so make -C scheduler test fails on main is archived as done with PR 181 (`git show origin/main:work-orders/archive/2026/WO-20261014-539a-...md`, read 03:10Z) |
| ` M tools/bearings/assets/page.html` (75 lines) and ` M tools/bearings/assets/theme.css` (17 lines), last written 2026-10-13T15:28:46Z | LAND through one ticket, with the formatter churn removed | Owner-requested Board link, clickable links and solves list (owner 2026-10-12T19:19Z), live on the stable page without a PR or test because the server re-reads the file per request; the diff also holds non-requested reformatting of a locked file (L08 section 5 item 10) |
| `?? backlog/now/` (3 files: ids `58p3s`, `jiy7z`, `re6ps`) | CLOSE (delete) | Already filed as issues 76, 77 and 78 (`L05-evidence/issues.json` holds each id); backlog moved to GitHub issues by PR 81 (L05 section 5 item 6) |
| 5,812 untracked files under `events/2026/10/` (2026-10-12T17:17Z to 2026-10-14T00:35Z) | SUPERSEDE | Copies made by `record-bus.sh`; 3,015 ids also exist in the state root (L02 section 5 item 3); reconcile any id missing from the state root, then delete, as part of WO-20261012-99d6 - Roadmap A4 - events/ and factory/state leave git: cut over under USERHALT, records copied to the state root, merging main strips events/ from a branch, rollback written |
| 179 tracked `events/` files and 341 tracked `changelog/` files on `origin/main` | LAND their removal under A4 and C13 | Runtime data in git against `AGENTS.md:111-123` and card C13 (L02 section 5 item 12; L03 section 5.2); counted with `git ls-tree` on `origin/main` at 03:15Z |

## 8. Runtime and scripts outside the repository

These are not git changes, but they are work that lives off main, which the owner's rule forbids (L06 section 5.8 item f; L02 section 5 item 10).

| Item | Verdict | Reason |
| --- | --- | --- |
| `~/.cache/coq-watch/patrol-tick.sh` (running, pid 3868571) | LAND into `line/` under WO-20261013-9617 - The patrol saw eight line processes dead 56 times but only queued them for an architect who was dead, and posts no card on the owner page (re-cut at line/bin/patrol-tick.sh), keeping the probes only | Its probes are the health checks worth keeping (L06 section 8) |
| `~/.cache/coq-watch/watchdog.sh` and `~/.config/systemd/user/watchdog.{service,timer}` | LAND into `line/` under WO-20261013-bf70 - The dead man's switch counts the patrol's own notes as records, so it never fired in a 9.5h outage (re-cut at line/bin/watchdog.sh), with the count fixed | `watchdog.sh:45` still counts any record, including the patrol's own (L06 section 5.2) |
| `~/.cache/coq-watch/{architect-rounds.sh,flow-tick.sh}`, 7 `.bak` files, stale copies of `aq`, `digest`, `flow-table`, `merge-watch`, `record-bus`, `route-retry`, `seat-queue` | CLOSE | Halted by owner order or superseded by `line/bin` copies (L06 section 9) |
| `~/.cache/coq-held-records/` (15 files) | CLOSE | Records never enter a commit once A4 lands (L02 section 7 item 2) |
| Stranded roots `~/.local/state/coq/{start-WO-20261013-496d,start-case12-fix,verify-fba7551}/records/` (11 records) | SUPERSEDE (reconcile into the canonical root, then delete) | Verdicts the merger never saw (L02 section 5 item 2) |
| Legacy seat root `~/.local/state/coq/seats/` (426 directories) | SUPERSEDE | `herdr.json` `state_dir` points at the wrong root (L02 section 5 item 1) |
| `~/.local/state/coq-jev-herdr-plugin/ids/SOP.counter` (a third root) | SUPERSEDE (move under `state-root.sh`) | `mint-id.sh:19` hardcodes it (L01 F12) |
| `~/.local/state/coq/coq-jev-herdr-plugin/crash/` (877 MB core of herdr 0.9.0) | KEEP until D08 | Unanalysed; no symbols; becomes moot after the planned upgrade (L04 section 5.1) |
| `~/.claude/hooks/no-hand-start.mjs`, `shell-lex.mjs` (784 lines referenced by no settings file) | DECIDE D13 | A reader assumes a gate exists where none does (L11 section 9) |

## 9. Merged but dark, and ruled or ready but unbuilt

Code on main that does not run, and decided work that is not on main.
Under D01 B several of these become the reconciler's actions instead of separate wiring tickets.

| Item | State | Verdict | Evidence |
| --- | --- | --- | --- |
| `line/bin/merge.sh`, `line/bin/verify-main.sh` | merged, no caller | LAND as reconciler actions (D01) | L05 section 5 item 11; L01 F4 |
| WO-20261014-d93a - R1 - routes.json run action: review.passed and merged run merge.sh and after-merge.sh, the architect wake on merged deleted | ready, 0 commits | SUPERSEDE by D01 B, or LAND as is if D01 is not B | L05 section 5 item 11 |
| WO-20261014-7f99 - R2 - Result records down their own seat through the route down key and patrol reports survivors as a defect | ready | SUPERSEDE by D02 B (one-shot seats end themselves) | L13 D14 |
| WO-20261014-3dae - R3 - start-loop.sh with its systemd user unit starts the next ready ticket when depends are done, files are free and a slot is free | ready | SUPERSEDE by D01 B (the reconciler is the start loop) | L06 section 7 item 5 |
| WO-20261013-48f2 - Post-merge cleanup is code: line/bin/after-merge.sh cleans the branches, downs the ticket's seats and returns their slots, restores the checkout's ticket copies, starts verify-main.sh in an unowned pane and posts one record; WO-20261013-612d - Route row: merged 200 runs line/bin/after-merge.sh instead of waking the architect to verify | ready | SUPERSEDE by D01 B | L13 D13 |
| WO-20261013-3217 - CI gate 3: line/bin/merge.sh keys on the coq/gate status of the head sha plus review.passed, triggered by the GitHub status event, not on a test.passed record; WO-20261013-aff2 - CI gate 4: a green coq/gate status on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold, triggered by the GitHub status event; WO-20261013-3eac - CI gate 5: pr.opened routes to the reviewer only; the tester role is retired and its playbook marked retired | ready | LAND after D05 and D07, with the trigger changed from a webhook event to the reconciler tick (D06 C) | L07 section 5 item 4 |
| Jenkins `coq-ci` library, multibranch job, webhook | never configured | LAND as JCasC and job DSL in a repo (D07 A) | L10 section 5.2; S02 B2, B3 |
| `line/units/coq-hook-{listener,forward,page}.service` | merged, not installed | DECIDE D06 (C makes them accelerators only) | L06 section 5.8 item h; L07 section 5 item 5 |
| `herdr/systemd/coq-supervisor.{service,timer}.in` | template, not installed | SUPERSEDE by D08 B units | L01 F5; L04 section 5.2 |
| `line/bin/board.sh` and the owner lane (WO-20261013-b221 - Roadmap K6 - The owner lane on the page: bearings renders owner-lane items as cards and the health line from the board's health file, so the owner never has to ask where the line stands, done) | merged, unwired, `owner_board` absent | LAND the wiring (D12 B) | L02 section 5 item 9; L08 section 5 item 2 |
| WO-20261013-a1c6 - Capacity: herdr max_agents goes from 8 to 16, pinned by a herdr test case | ruled by card C27 on 2026-10-13T02:10Z, ready | LAND, or SUPERSEDE by reconciler caps under D01 B | L06 section 5.8 item g |
| WO-20261013-8e0c - The supervisor keeps only bearings stable alive while the halt flag exists, and the runbook says how the owner's USERHALT and USERGO reach the line commands (K4 part 4 of 4) | ready | LAND with D08 and D12 | L08 section 5 item 4 |
| WO-20261013-d1cd - K5 reland, part 1: the factory test world and cases 03, 06 and 09 post every gate record with its sha; WO-20261013-9189 - K5 reland, part 2: factory cases 10, 11, 12 and 13 post every gate record with its sha; WO-20261013-5dce - K5 reland, part 3: factory cases 14 and 17 post every gate record with its sha | ready, 0 commits | CLOSE | The reland chose a fixture shim instead; a ticket whose acceptance already passes on main is done (L05 section 5 item 2) |
| WO-20261012-be64 - Roadmap L - Decision nodes for the locked roadmap decisions in the design graph, the NATS decision marked deferred and the bus ticket re-scoped | ready | LAND | `DEC-nats-jetstream-grpc.json` still says locked (L03 section 5.2; S03 F5) |

## 10. Other repositories

| Repository or path | What is not landed | Verdict | Evidence |
| --- | --- | --- | --- |
| `jkkelley/rime` (private, Go) | 13 unmerged ticket branches; the gRPC server ticket never built; the loop still "halted, await STARTAGAIN" | KEEP frozen until D09 and D10 (D01 is ruled: a Go service speaking gRPC, 2026-10-14T03:28Z) | The transition table (1,009 lines of tests with mutants) and the SQLite store are carry-forward candidates (L09 sections 4.2 and 10; L14 section 8) |
| `~/projects/rime` (13 behind), `~/projects/rime-gate-proof` (older) | stale local checkouts | CLOSE | L09 section 3; L14 section 3.2 |
| `jkkelley/rime-bootstrap` and its live copy `~/tools/bearings-v2` | 97 remote ticket branches; F-49 to F-54 merged as cuts and never built; one untracked `HYDRATION.md` | SUPERSEDE (harvest the decision table and the investigation, then archive) | L09 sections 4.3, 5.2, 7 |
| `~/projects/getting-my-bearings` | about 50 worktrees, 39 holding unmerged work at the 2026-09-19 triage | DECIDE the triage's Hold items, then archive | The owner declared the rest out of scope (V-17); only the page module and incident write-ups are reusable (L08 sections 5 item 8 and 9) |
| `~/projects/bearings-core-wk091` | empty directory | CLOSE | L08 section 3 |
| Stale pages under `~/.bearings/` (`bearings-test`, `stable-442cf4`, `coq-uat-WO-20261010-ba08`, September test directories, `--help`) | clutter | CLOSE | L08 section 9 |
| `~/Documents/local-k8s-docs` | local `main` 25 behind `origin/main`; 5 untracked compaction records and an `oom` file | LAND (fast-forward), DECIDE the untracked files | L10 section 5.4 |
| `~/projects/dropship-01-gitops` | unmerged retire branches, 4 behind | DECIDE (low priority) | L10 section 9 |
| `~/projects/crypto-max-gitops` | live Argo Applications for a retired tenant | DECIDE (low priority) | L10 section 9 |
| `~/projects/homelab-gitops` | checkout on `feat/ntfy-alerts` at `88f27e4` (2026-09-15) | DECIDE; not verified whether the branch is merged | L10 section 3 |
| `~/projects/forge-config`, `forge-gitops`, `forge-eks-infra` | Forgejo manifests with placeholders, never applied | KEEP as reference for D18 | L10 section 9; L12 section 5 |
| `jkkelley/software-factory` | default branch `claude/new-session-z3nzz0`, plus `main` and `feat/initial-capture`, 0 PRs | KEEP as a contract reference; nothing to land | L09 sections 3 and 8 |

## 11. Open GitHub issues (33)

Verdicts are L05's, from `L05-evidence/issue-verdicts.tsv` (checked against main at `b7a3c5d`); titles are copied whole from `L05-evidence/issues.json`.
Actions: CLOSE (completed) for fixed work, CLOSE (not planned) for superseded or conflicting asks, CLOSE on Dnn once that decision is ruled as recommended, FOLD into the named build item or decision and close when it lands, KEEP-OPEN for work outside the rebuild.
Every closing comment names the commit or the ruling, so the close is evidence and not a stamp.

| Issue | Title | L05 verdict | Action | Reason and evidence |
| --- | --- | --- | --- | --- |
| 45 | Event log directory: git-tracked, one file per entry, status code and UTC only | CLOSE-CONFLICT | CLOSE (not planned) | Asks for a git-tracked event log; ROADMAP item A (`ROADMAP.md:75-104`, `:190`) and card C13 move runtime data out of git |
| 46 | No process under an agent: tests and watchers run in labelled panes | PARTLY | FOLD into D02 B and D08 B | Labelled test panes exist (`05ef0d2`); under one-shot headless runs and systemd units no process sits under an agent; close when the launcher lands |
| 47 | Mod-based game adapter family (Qud, Cities Skylines 2) | PARK | KEEP-OPEN (label product) | Product backlog; held by D19 until the line passes its exit test |
| 48 | Monitor seat and herdr tab group for the event log and system health | PARTLY | CLOSE on D11 B and D17 B | Monitor panes and the compliance-officer role exist; the rebuild retires the LLM monitor and replaces it with reconciler probes and the owner lane health line |
| 49 | Owner notifications through herdr | PARTLY | CLOSE on D12 B | `notify_owner` already goes to the page (`routes.json:17,21,28`); herdr notifications stop being an owner channel |
| 50 | System and monitoring come up before any agent | PARTLY | FOLD into D08 B bring-up | Bring-up order is SPEC-17 B1 to B10 and `bringup.sh:6`; the line-up Make target (BI04) asserts it; WO-20261013-8ed9 - make line-resume: the preflight judges open items by rule, the system comes up B1 to B10 in order and stops at the first FAILED, seats one at a time, line.resumed 100, flags removed last (SPEC-17 T09; K4 part 3 of 4) is ready with 0 commits (L05 section 5) |
| 51 | Agents notified on status change instead of idling | PARTLY | CLOSE on D01 B and D02 B | No seat waits for status under one-shot runs; the reconciler tick dispatches on state change |
| 52 | Local DNS on the owner's Raspberry Pi names every local web server (bearings, board, blueprint dev, uat and stable) so the owner reaches them from an iPhone | PARK | KEEP-OPEN (owner infrastructure) | No repository change is possible; it belongs in the owner's homelab repositories |
| 53 | Seats start without the owner's global MCP servers: every seat spawns a jenkins-mcp podman container and loads k8s, notion, gmail and figma tool schemas it never uses | OPEN | FOLD into D13 B | `--strict-mcp-config` and a rendered settings file at launch end the global MCP load; only a comment exists today (`seat-lib.sh:242`) |
| 54 | work-order start branches from origin/main whatever the checkout has checked out, or a repo wrapper does it before calling start | PARTLY | FOLD into the reconciler start action (D01 B, BI04) | `start-tickets.sh:38` branches from `origin/main`, `bin/wo-start.sh:14-23` does not; one start path replaces both |
| 55 | Bearings stable server survives the owner's absence: no 240-minute idle stop while the factory runs, and bringup --check plus recover.sh restart it when it is dead | PARTLY | FOLD into WO-20261013-8e0c - The supervisor keeps only bearings stable alive while the halt flag exists, and the runbook says how the owner's USERHALT and USERGO reach the line commands (K4 part 4 of 4), and D12 B | Supervisor restarts bearings by process (`55e799e`); the 240-minute idle stop is still in `server.mjs:604-620` |
| 56 | Records cannot be hidden from git: lint and bringup --check fail when .git/info/exclude or any .gitignore matches events/, and the worker role is told to exclude events per command, never by exclude file | CLOSE-CONFLICT | CLOSE (not planned) | A lint that fails when `events/` is ignored contradicts ROADMAP item A, which removes `events/` from git |
| 57 | Legacy record kinds test, review and merge leave the schema or gain route rows: a gate record the belt cannot route is a silent stall | OPEN | FOLD into BI02 | Legacy kinds still at `event.schema.json:14` and `event.sh:68` |
| 58 | shellcheck no longer segfaults inside the lint container: pin a shellcheck build that runs on this host or run it outside the GHC runtime, and make lint retries a crashed checker once with a named line | OPEN | FOLD into D07 A (lint unit in pods) | `lint/lint.sh:40-41` runs shellcheck once with no retry; the pod lint unit replaces `make lint` (S02 B7) and must pin a working shellcheck |
| 59 | The architect is woken by herdr, not by its own watchers: bringup places an idle watch that prompts the architect pane when a seat goes idle or done, and recover.sh checks podman and runs podman system migrate when the pause process is gone | SUPERSEDED | CLOSE (not planned) | An idle watch that prompts the architect is the opposite of "driven by system, not agent" (brief section 2) and of D17 B |
| 60 | Seat records never leave the line: the events schema accepts pr and sha before any seat writes them, so no record is held outside git | FIXED | CLOSE (completed) | `pr` and `sha` in `event.schema.json:22-23` (`3b5717f`) |
| 61 | compaction-guard watch sends governance memos only to live sessions, never to every past session mapped to a pane | FIXED | CLOSE (completed) | `d0b8dea`, WO-20261012-ee9c - Scoped guard watch: monitor slot 1.1.2 runs the guard only for live seats, each pane resolved to the Claude session running in it every tick (#31) |
| 62 | Board reads the belt from the runner's own config: loop.sh takes the belt file and its stale age from factory/config/runner.json, not a second hardcoded path | FIXED | CLOSE (completed) | `report/loop/loop.sh:174-175` reads `runner.json` (`3878c97`) |
| 63 | bringup.sh --check and recover.sh judge a monitor pane by its process, not its label | FIXED | CLOSE (completed) | `bringup.sh:109-116` judges by foreground process (`55e799e`) |
| 64 | event.sh add validates against events/schema/event.schema.json before writing, so a seat can never write a record that event.sh check and make lint refuse | PARTLY | FOLD into BI01 | Sha and code refused at `event.sh:95-97`; no observation-count check although the schema caps it at 5 |
| 65 | Factory suite flake on main 3b5717f: make -C factory test exited 1 once then passed 15/15 on the same tree | UNVERIFIED | FOLD into the first CI gate run (D07 A) | No captured failing run; run `make -C factory test` 20 times in pods; close if 20 of 20 pass, else it becomes a ticket with the captured log |
| 66 | factory/schema/routes.schema.json is an unread copy that lacks main's break-glass and none actions: delete it or make it the one schema lint reads | PARTLY | FOLD into BI05 | Two byte-identical routes schemas still exist; the done-when asks for exactly one |
| 67 | Belt seat-ups block the line: route.sh waits on seat.sh, which waits up to nudge_wait_seconds (180) for a guard ACK line that never comes, so every record behind a seat-up waits 3+ minutes | PARTLY | CLOSE on D01 B and D02 B | The ACK wait is 15 s, not removed (`seat.sh:778`); with no seat bring-up inside the routing path the block cannot exist |
| 68 | Verifier follow-ups from PR 29: brief.sh and nudge.sh read an archived ticket so seat.sh's verifier special case goes, a ROL-verifier graph node, and WFL-integration text that still routes merged to the architect | SUPERSEDED | CLOSE (not planned) | No verifier role on main; `verify-main.sh` (`9b3d105`, #112) replaced it |
| 69 | Gate records must carry the head: event.sh add refuses test.passed, test.failed, review.passed and review.changes without --sha and --pr, and the tester and reviewer playbooks say so | FIXED | CLOSE (completed) | `event.sh:70,97` refuse a gate kind without `--sha` (`7e114c9`, #145) |
| 70 | Merger brief names its job before the ticket: a belt-seated merger read PR 29's verifier ticket and took itself for the verifier | OPEN | CLOSE on D11 B | No "not your role" line in `roles/bin/brief.sh`; the merger seat is retired under D11 B; if D11 is not B, FOLD into the brief renderer |
| 72 | work.started has no route row: every worker resume writes a no-route 500 to the monitor (65 on 2026-10-12) | FIXED | CLOSE (completed) | Ignore row at `routes.json:26` (`fba7551`, #126) |
| 73 | seat.sh max_seats refusal says the queue holds the ticket, but no queue exists: a refused seat is never brought up when a slot frees | PARTLY | CLOSE on D01 B | `seat.sh:532` promises a queue nothing reads; the level-triggered reconcile re-dispatches refused work on the next tick (BI08) |
| 74 | A seat's test pane can open in the main checkout instead of the seat's worktree, so a tester's run tests the wrong tree | FIXED | CLOSE (completed) | `testpane.sh:3,33-34` runs in `COQ_WORKTREE` (`778e9df`) |
| 75 | work-order.sh reindex --check passes with one ticket id in two files (a ready copy beside its archived done copy) | OPEN | FOLD into D04 | Under D04 C tickets leave git and `reindex` goes; under D04 A or B, `reindex --check` joins lint |
| 76 | route.sh never retries a failed route: a gate record whose seat-up was refused for max_seats waits forever | PARTLY | CLOSE on D01 B (BI08) | `route.sh:281,288` still marks failed and never retries; `route-retry.sh` is a side loop; the reconciler owns one bounded retry |
| 77 | Seats post their start notice under a gate kind with code 100 (test.passed 100, review.passed 100, test 100, review 100) instead of no record | PARTLY | FOLD into BI01 | A gate kind with a wrong code and a sha is accepted (`event.sh:95-97`) |
| 78 | A merge wake sent to the one busy merger is lost: the belt downs the merger after its gate record for the PR it was working, and the queued PR is never merged | PARTLY | CLOSE on D01 B and D11 B | `merge.sh` as a reconciler action has no seat to lose a wake to; `routes.json:12` and `:15` go |

Totals, 33 in all: CLOSE now 11 (the seven FIXED 60, 61, 62, 63, 69, 72, 74; the two SUPERSEDED 59, 68; the two CLOSE-CONFLICT 45, 56); CLOSE on a ruling 8 (48, 49, 51, 67, 70, 73, 76, 78); FOLD 12 (46, 50, 53, 54, 55, 57, 58, 64, 65, 66, 75, 77); KEEP-OPEN 2 (47, 52).
Going forward the merge step writes `Closes #N` from the ticket's issue field, because 0 of 142 merged PRs ever closed an issue (L05 section 5; `prstats.sh`).
Issue #71 (Bearings card: the About text runs into the DECIDE label at phone and narrow widths; give the facts rows real space) is already closed (2026-10-12T22:40:07Z).

## 12. Ordering and trigger

One line: nothing in this file runs before GOFACTORY; the cleanup is the first slice GOFACTORY starts, run by one script generated from these tables (BI09), dry-run first, in the order below, unless the owner rules D25 otherwise.

Why it is not exempt: the owner's "dont leave that shit laying around" (`~/.claude/history.jsonl` line 21023, 02:49:18Z) came three minutes before "nothing is started again till the GOFACTORY signal" (line 21028, 02:52:15Z), so the later, broader order governs until the owner says otherwise (D25 in `03-DECISIONS.md`).
What may happen before the signal: the dry-run itself, which reads and writes nothing in the repository, and its output attached to the GOFACTORY card so the owner sees every deletion before saying go.

Order after GOFACTORY, each step three attempts then a record, never a hand step:

1. Back up first: copy the `tools/bearings/assets/page.html` and `theme.css` diffs, the residue diff of WO-20261014-539a - Cause ay: scheduler testkit world copies events/bin/event.sh without bin/state-root.sh and config/state.json, so make -C scheduler test fails on main, and the three `backlog/now/` files into the state root backup tree, because the bearings edits are live on the stable page today (section 7).
2. Records: run WO-20261012-99d6 - Roadmap A4 - events/ and factory/state leave git: cut over under USERHALT, records copied to the state root, merging main strips events/ from a branch, rollback written; it needs USERHALT by its own title, reconciles every one of the 5,812 untracked event copies whose id is missing from the state root, and only then deletes them; the 179 tracked `events/` files leave git in the same change, and the 341 tracked `changelog/` files under card C13 (section 7).
3. Checkout: discard the WO-20261014-539a residue, delete `backlog/now/` (already issues 76, 77, 78), then fast-forward the owner checkout to `origin/main`.
4. Owner page: land the bearings asset edits through one small ticket with the formatter churn removed, so the stable page keeps what the owner asked for and main holds it.
5. Git clutter: the branch, ref, worktree and stash verdicts in sections 3 to 6, then `delete_branch_on_merge` set to true.
6. Issues: the 11 CLOSE-now issues in section 11 at once; the 8 CLOSE-on-ruling issues as each decision is ruled; the 12 FOLD issues when their build item merges, by `Closes #N`.
7. Off-repo runtime and dark code: sections 8 and 9, in step with D08 (systemd units) and D01 (the reconciler), since those decide whether each item lands or is superseded.

Trigger for each step: GOFACTORY starts step 1; each later step starts on the previous step's success record; steps 6 and 7 also wait on the named ruling, read as a record, never on a prompt.

## 13. Sources

- `L05-git-state.md` sections 3 to 9 and `L05-evidence/` (`branches.tsv`, `issues.json`, `issue-verdicts.tsv`, `ticketlag.tsv`, `worktrees.tsv`), written 2026-10-14T02:58Z.
- Owner messages `~/.claude/history.jsonl` lines 21023 and 21028, read by the merge seat 2026-10-14T03:35Z; title of WO-20261013-8ed9 read from `origin/main` at 03:38Z.
- `L05b-worktrees-and-dirty-checkout-snapshot.md`, snapshot 2026-10-14T02:50:25Z.
- `L02-state-stores.md`, `L06-owner-retros-and-plans.md`, `L08-bearings-owner-surface.md`, `L09-earlier-factory-iterations.md`, `L10-cluster-and-gitops.md`, `L11-governance-layer.md`, `L12-forgeo.md`, `L13-llms-doing-scheduler-work.md`, `L14-go-grpc-control-plane.md`.
- Read-only calls by the merge seat, 2026-10-14T03:05Z to 03:20Z, all with `GIT_OPTIONAL_LOCKS=0`: `git branch -vv`, `git branch -a`, `git cherry origin/main <branch>` for the 15 local-only branches, `git diff --stat`, `git stash list`, `git show origin/main:<archived 539a ticket>`, `git ls-tree -r origin/main` counts, `gh pr view` for PRs 15, 17, 25, 29, 36, 37, 38, 40, 41, 42; ticket titles taken from the JSON front matter of the 263 ticket files in the owner checkout.
