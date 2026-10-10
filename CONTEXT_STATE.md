# CONTEXT_STATE.md

> Session state, newest checkpoint first.
> **Read the top checkpoint and stop.** It restates current state in full and is
> complete on its own. Everything below it is how you got here.
>
> Go deeper only when the top checkpoint points at an older one, when you are
> chasing something that recurs across the window, or when asked. Say so when
> you do.
>
> Never edit a checkpoint. A new one is prepended above the last; the ones below
> are history and are immutable. Written by `checkpoint.sh`, never by hand.







## Checkpoint 2026-10-10 19:56 UTC

### Current state

#### Infrastructure

- Public repo https://github.com/jkkelley/coq-jev-herdr-plugin, main: PR #1 (feat/p0-foundation) squash-merged 19:48 UTC as bec8276. 920807a: the factory scripts are in git (`.gitignore` had `**/bin/`, breadcrumb left in place), architect owns approval, 16 tickets ready. This step: graph schemas on nodes, WFL-integration, bin/changelog.sh + CHANGELOG.md, bin/step.sh + `make step`.
- Main checkout /home/luna/projects/coq-jev-herdr-plugin is the working checkout now; slot 2 worktree (feat/p0-foundation, merged) is stale and can be released. Slot 1 /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1 holds WO-20261010-ba08 (branch feat/vendor-bearings-into-tools-bearings-with-stable-, 9805ff0, suite 20/20): the uat page http://localhost:44910/?key=f18907f3a02cec0412ad14fa027bda0f (pane wD3:pA server, wD3:pB wait) with card UAT-1 still unanswered; the owner will not answer it (chat 2026-10-10: "I'm not adding shit any more"), so this seat decides it.
- Owner page (old skill copy) http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928, panes wD3:p3 server, wD3:p4 wait; 12 answers in ~/.bearings/coq-jev-herdr-plugin-05518e. No Claude Code Monitors armed.
- Caves of Qud: Steam app 333640, Windows build installed at /mnt/d/SteamLibrary/steamapps/common/Caves of Qud (D:\SteamLibrary). No Linux build anywhere on disk or in Google Drive (searched). Card Q12 is answered by this: Spike 1 uses the Windows build or the Steam console depot download, not the owner.
- Kube contexts: homelab-admin (default, 192.168.1.248:6443), eks-upgrade-dev, kind-prospector-events-smoke. Jenkins reachable through the jenkins-mcp tools.

#### Toolchain

- herdr 0.9.0 protocol 22. work-order v2.1.0 (`approve --no-lavish --reason`). context-compaction checkpoint.sh. Podman images localhost/coq-lint:1, localhost/coq-bearings-test:1. make lint green at this checkpoint (graph check now validates every node against graph/schema/node.schema.json and every attached data instance against its schema; changelog check included).
- `make step MSG=.. TYPE=.. TITLE=.. [TICKET=..] [TEXT=..] [CP=body.md]` is the only way a step lands: lint, changelog entry, commit, push, checkpoint, `/compact` queued into $COQ_SEAT_PANE (wD3:p2).
- compaction-guard sensor still reads 0 for this seat; the step script queues `/compact` by `herdr agent prompt` until WO-20261010-7083 lands.

#### Active Tasks

- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: ready; step D now: stop the old server (panes wD3:p3/p4), `make -C tools/bearings migrate TIER=stable FROM=~/.bearings/coq-jev-herdr-plugin-05518e` in slot 1, evidence AC-H5 by diff, submit PR, done, merge, `make -C tools/bearings upgrade`, stop uat panes wD3:pA/pB, release slot 1.
- WO-20261010-8777 - herdr seat scripts: bringup, seat, monitors, recover, retire: ready, p0. This is what makes agents do the work instead of this seat; next after ba08.
- WO-20261010-539f - NATS JetStream is the producer-consumer bus and gRPC the control plane: amend SPEC-03, stand up the bus, port the queue: ready, p0.
- WO-20261010-d354 - Dated entry files: YYYY/MM/YYYYMMDD-name.ext, frontmatter, UTC, one script per tree: ready, p0 (changelog/ already on the layout).
- WO-20261010-7083 - Quiet window in compaction-guard: quiet.json, 5 second countdown, watchers pause and queue, inbox drains after resume: ready, p0.
- WO-20261010-fbad - Land the P0 foundation branch: SPEC-00, 01, 03, 04, 05, graph, lint, events, queue, roles: ready; the branch is merged, evidence its ACs and close it.
- Jenkins: a pipeline job for this repo running `make lint` on every push, so lint never runs in a pane by hand (owner, 2026-10-10 UTC: nothing by hand).
- Other ready tickets: WO-20261010-eaa3 Spike 1 (Windows build path decided above), WO-20261010-6a3b Spike 11, WO-20261010-c6e9 Spike 9, WO-20261010-d08d Spike 10; full titles in the ticket files.

#### Blockers

- None that need the owner. UAT-1 is decided by this seat; Q12 is answered by the disk search.

### New this checkpoint

#### Decisions

- 2026-10-10 19:5x UTC, owner: approval is the architect's job, done only when sure (roles/architect.json must line 2; playbook rendered).
- 2026-10-10 UTC, owner: "define schemas and attach them to the nodes": graph nodes carry `schema` and `data`, graph.sh attach/check enforce them (graph/schema/node.schema.json). "We should have an integration node in DAG": WFL-integration, owned by ROL-merger.
- 2026-10-10 UTC, owner: "change log too": changelog/YYYY/MM entries by bin/changelog.sh, CHANGELOG.md generated, lint checks it. "Nothing by hand": bin/step.sh is the step cycle.

#### Lessons Learned

- `**/bin/` in the shared ignore set silently dropped every factory script from PR #1; lint passed only because the worktree had the files. A lint that runs in CI from a clean clone would have caught it, which is why Jenkins is next.
- A keep line over a few hundred characters arrives as pasted text and the queued `/compact` never fires; the step script sends the one-sentence form.

### Hydration prompt

Run from /home/luna/projects/coq-jev-herdr-plugin on main. Next step: WO-20261010-ba08 step D as listed under Active Tasks (decide UAT-1 yourself, the owner will not), then the Jenkins lint job, then WO-20261010-8777 - herdr seat scripts: bringup, seat, monitors, recover, retire. Every step lands with `make step ... CP=<body>`; never lint, commit, checkpoint or compact by hand. Re-arm no Monitors unless a pane is being waited on; stop every Monitor before the step script runs. Decide, do not ask; the owner said this seat is in charge and is adding nothing more.

## Checkpoint 2026-10-10 19:45 UTC

### Current state

#### Infrastructure

- Public repo https://github.com/jkkelley/coq-jev-herdr-plugin: main protected; origin/main = local main (tickets WO-20261010-d354 and WO-20261010-539f pushed, 2c3ce00). PR #1 = feat/p0-foundation (slot 2, pushed, lint all ok). Bearings branch feat/vendor-bearings-into-tools-bearings-with-stable- pushed (9805ff0), no PR yet.
- Main checkout /home/luna/projects/coq-jev-herdr-plugin on main: 30 tickets; INDEX.md is the router.
- Slot 1 /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1/coq-jev-herdr-plugin (WO-20261010-ba08): attachment port wired, suite 20/20 green in Podman, stop fix (herdr pane list has no --tab). uat page http://localhost:44910/?key=f18907f3a02cec0412ad14fa027bda0f served by the PORTED code (pid 188179), server pane wD3:pA, wait loop pane wD3:pB; card UAT-1 open.
- Slot 2 (this checkout) feat/p0-foundation: SPEC-05 1.1.0 with s-quiet, graph 96 nodes (DEC-nats-jetstream-grpc added), AGENTS.md routes in its first 100 lines: contents, golden rule, hard rule the first 100 lines route, hard rule dated entry files, law NATS JetStream bus + gRPC control plane + status codes. Pushed.
- Owner page (old skill copy) http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928, server pane wD3:p3, wait loop pane wD3:p4.
- Claude Code Monitors on panes wD3:p4 (bc2qfx1dd) and wD3:pB (br4niuv3u) are STOPPED for the quiet window; re-arm both on resume after reading each pane for ANSWER/MESSAGE lines newer than 20:10 UTC. Card Q12 (where is the DRM-free Qud Linux build) is open on the owner page. The owner is around in chat but told this seat it is in charge.
- Test pane wD3:p5 free after lint. Memory: checkpoint-discipline.md holds the checkpoint orders. The owner said the dated-entry-file rule must NOT live in memory: it lives in AGENTS.md and WO-20261010-d354 only.
- SITREP 002: https://claude.ai/artifact/PnNrFEYTqaqsg2xx2MVc9d

#### Toolchain

- herdr 0.9.0 protocol 22. treehouse v2.3.0 + slot.sh. work-order v2.1.0+#103. project-scaffold v1.6.0. compaction-guard 1.2.8 (sensor reads 0 for this session, so compaction is queued by hand via herdr agent prompt wD3:p2 until WO-20261010-7083 lands). Podman images localhost/coq-bearings-test:1, localhost/coq-lint:1.

#### Active Tasks

- WO-20261010-fbad - Land the P0 foundation branch: PR #1 lint green; merge it (step of its own, next), then approve it and the P0 epic.
- WO-20261010-7083 - Quiet window in compaction-guard: quiet.json, 5 second countdown, watchers pause and queue, inbox drains after resume: draft p0; approve and start after the merge.
- WO-20261010-d354 - Dated entry files: YYYY/MM/YYYYMMDD-name.ext, frontmatter, UTC, one script per tree: draft p0 under WO-20261010-329d - P0 foundation: specs, knowledge graph, factory scripts. Owner order 2026-10-10 UTC.
- WO-20261010-539f - NATS JetStream is the producer-consumer bus and gRPC the control plane: amend SPEC-03, stand up the bus, port the queue: draft p0 under WO-20261010-329d. Owner decision 2026-10-10 UTC; graph node DEC-nats-jetstream-grpc supersedes REQ-locks-and-queues.
- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: step D when UAT-1 is answered: evidence AC5 via `make migrate`, submit PR, done, merge, `make upgrade` on the main checkout, stop the old server (panes wD3:p3, p4), release slot 1.
- Then from INDEX.md: WO-20261010-6a3b Spike 11, WO-20261010-8777 herdr seat scripts, WO-20261010-c6e9 Spike 9, WO-20261010-eaa3 Spike 1 (needs the owner's Qud Linux build), WO-20261010-d08d Spike 10 coq-term variant A, wireframes ticket under 98ea, handoff WO-20261010-3593.

#### Blockers

- UAT-1 unanswered.
- Spike 1 needs the Qud Linux build from the owner (card Q12).

### New this checkpoint

#### Decisions

- 2026-10-10 ~20:00 UTC, owner: every scripted entry is a new file at <tree>/YYYY/MM/YYYYMMDD-<name under 50 chars>.<ext> with frontmatter and UTC; never overwrite. AGENTS.md hard rule (line 68), ticket WO-20261010-d354. Not in memory, by owner order.
- 2026-10-10 ~20:05 UTC, owner: NATS JetStream is the producer-consumer bus, gRPC the control plane, status codes drive routing, every component a black box behind a subject. AGENTS.md law (line 94), DEC-nats-jetstream-grpc locked, ticket WO-20261010-539f.

#### Lessons Learned

- A rule the owner gives in chat goes into the repo (AGENTS.md inside the first 100 lines, graph, ticket) in the same step; the owner does not want it to depend on this seat's memory.
- A stale Monitor (bzlo9put6 on the closed pane wD3:p7) survived two compactions; list and stop every Monitor before a compact, not only the ones named in the checkpoint.

### Hydration prompt

Re-arm Monitor watches on panes wD3:p4 and wD3:pB (grep ^ANSWER|^MESSAGE|^STOPPED, 30 min, re-arm on expiry) after `herdr pane read` of each for lines newer than this checkpoint; act on any UAT-1 answer (WO-20261010-ba08 step D). Next step otherwise: merge PR #1 (`gh pr merge 1 --squash` from the main checkout), then approve and start WO-20261010-7083. One commit and one checkpoint per step, then queue `/compact` via `herdr agent prompt wD3:p2` with the keep line; stop every Monitor first. The owner said this seat is in charge: decide, do not ask; anything done by hand a second time becomes a script.

## Checkpoint 2026-10-10 19:40 UTC

### Current state

#### Infrastructure

- Public repo https://github.com/jkkelley/coq-jev-herdr-plugin: main protected, origin/main = local main (ticket WO-20261010-7083 pushed). PR #1 = feat/p0-foundation (slot 2, e9035b3 pushed, lint all ok). Bearings branch feat/vendor-bearings-into-tools-bearings-with-stable- pushed (9805ff0), no PR yet.
- Main checkout /home/luna/projects/coq-jev-herdr-plugin on main: 28 tickets; INDEX.md is the router.
- Slot 1 /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1/coq-jev-herdr-plugin (WO-20261010-ba08): attachment port wired (d38eaa4), suite case T4b (384876f, 20/20 green in Podman), stop fix (9805ff0: herdr pane list has no --tab). uat page http://localhost:44910/?key=f18907f3a02cec0412ad14fa027bda0f served by the PORTED code (pid 188179), server pane wD3:pA, wait loop pane wD3:pB; card UAT-1 open; owner message m-20261010192521524-wfo6h answered with the uat url at ~19:36 UTC.
- Slot 2 (this checkout) feat/p0-foundation: SPEC-05 1.1.0 with s-quiet, graph 95 nodes, AGENTS.md routes in its first 66 lines (contents, golden rule, hard rule: the first 100 lines route). Pushed.
- Owner page (old skill copy) http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928, server pane wD3:p3, wait loop pane wD3:p4.
- Claude Code Monitors on panes wD3:p4 and wD3:pB are STOPPED (tasks brolk9d0t, bvrie0e0z) for the quiet window; re-arm both on resume after reading each pane for ANSWER/MESSAGE lines newer than 19:39 UTC. Card Q12 (where is the DRM-free Qud Linux build) is open on the owner page; the owner is AWAY from ~19:55 UTC and left this seat in charge.
- Test pane wD3:p5 free. Memory: checkpoint-discipline.md holds both owner orders.
- SITREP 002: https://claude.ai/artifact/PnNrFEYTqaqsg2xx2MVc9d

#### Toolchain

- herdr 0.9.0 protocol 22. treehouse v2.3.0 + slot.sh. work-order v2.1.0+#103. project-scaffold v1.6.0. compaction-guard 1.2.8 (sensor reads 0 for this session, so compaction is queued by hand via herdr agent prompt wD3:p2 until WO-20261010-7083 lands). Podman images localhost/coq-bearings-test:1, localhost/coq-lint:1.

#### Active Tasks

- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: steps A, B, C done. Step D = when UAT-1 is answered: evidence AC5 via `make migrate` from ~/.bearings/coq-jev-herdr-plugin-05518e into stable, submit PR, done, merge, `make upgrade` on the main checkout, stop the old server (panes wD3:p3, p4), release slot 1.
- WO-20261010-fbad - Land the P0 foundation branch: PR #1 lint green; merge it (step of its own), then approve it and the P0 epic.
- WO-20261010-7083 - Quiet window in compaction-guard: quiet.json, 5 second countdown, watchers pause and queue, inbox drains after resume: draft, p0, under WO-20261010-84f1 - Monitoring: monitor seat, tab group, notifications, status codes; approve and start next (dotfiles compaction-guard change plus bearings wait loop).
- Then from INDEX.md: WO-20261010-6a3b Spike 11, WO-20261010-8777 herdr seat scripts, WO-20261010-c6e9 Spike 9, WO-20261010-eaa3 Spike 1 (needs owner's Qud Linux zip), WO-20261010-d08d Spike 10 coq-term variant A, wireframes ticket under 98ea, handoff WO-20261010-3593.

#### Blockers

- UAT-1 unanswered.
- Spike 1 needs the Qud Linux build from the owner.

### New this checkpoint

#### Decisions

- Owner, stepping away ~19:55 UTC: this seat is in charge; never do anything by hand more than once (the second time is a script); contents lists and routing to files everywhere; agents read head 100 and lose context past it, so every file routes in its first 100 lines (AGENTS.md hard rule); be ahead of the game.
- One question asked, on the page as Q12: where is the DRM-free Caves of Qud Linux build.

#### Lessons Learned

- A rule appended at line 121 of AGENTS.md was outside the window agents actually read; binding rules go right after the contents list.

### Hydration prompt

Read this checkpoint. Then: re-arm Monitor watches on panes wD3:p4 and wD3:pB (grep ^ANSWER|^MESSAGE|^STOPPED, 30 min, re-arm on expiry) after `herdr pane read` of each for lines newer than this checkpoint; act on any UAT-1 answer (step D above). Next step otherwise: merge PR #1 (gh pr merge 1 --squash), then approve and start WO-20261010-7083. One commit and one checkpoint per step, then queue `/compact` via herdr agent prompt wD3:p2 with the keep line, stop Monitors first. The owner is away: decide, do not ask; anything done by hand a second time becomes a script in bin/ or tools/.

## Checkpoint 2026-10-10 19:39 UTC

### Current state

#### Infrastructure

- Public repo https://github.com/jkkelley/coq-jev-herdr-plugin: main protected, origin/main = local main (ticket WO-20261010-7083 pushed). PR #1 = feat/p0-foundation (slot 2, e9035b3 pushed, lint all ok). Bearings branch feat/vendor-bearings-into-tools-bearings-with-stable- pushed (9805ff0), no PR yet.
- Main checkout /home/luna/projects/coq-jev-herdr-plugin on main: 28 tickets; INDEX.md is the router.
- Slot 1 /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1/coq-jev-herdr-plugin (WO-20261010-ba08): attachment port wired (d38eaa4), suite case T4b (384876f, 20/20 green in Podman), stop fix (9805ff0: herdr pane list has no --tab). uat page http://localhost:44910/?key=f18907f3a02cec0412ad14fa027bda0f served by the PORTED code (pid 188179), server pane wD3:pA, wait loop pane wD3:pB; card UAT-1 open; owner message m-20261010192521524-wfo6h answered with the uat url at ~19:36 UTC.
- Slot 2 (this checkout) feat/p0-foundation: SPEC-05 1.1.0 with s-quiet (REQ-checkpoint-every-step, REQ-compaction-quiet-window), graph 95 nodes, AGENTS.md golden rule section.
- Owner page (old skill copy) http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928, server pane wD3:p3, wait loop pane wD3:p4.
- Claude Code Monitors on panes wD3:p4 and wD3:pB are STOPPED for the compaction (quiet window); re-arm both on resume after reading each pane for ANSWER/MESSAGE lines newer than this checkpoint.
- Test pane wD3:p5 free. Memory: checkpoint-discipline.md holds both owner orders.
- SITREP 002: https://claude.ai/artifact/PnNrFEYTqaqsg2xx2MVc9d

#### Toolchain

- herdr 0.9.0 protocol 22. treehouse v2.3.0 + slot.sh. work-order v2.1.0+#103. project-scaffold v1.6.0. compaction-guard 1.2.8 (sensor reads 0 for this session, so compaction is queued by hand via herdr agent prompt wD3:p2 until WO-20261010-7083 lands). Podman images localhost/coq-bearings-test:1, localhost/coq-lint:1.

#### Active Tasks

- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: steps A, B, C done. Step D = when UAT-1 is answered: evidence AC5 via `make migrate` from ~/.bearings/coq-jev-herdr-plugin-05518e into stable, submit PR, done, merge, `make upgrade` on the main checkout, stop the old server (panes wD3:p3, p4), release slot 1.
- WO-20261010-fbad - Land the P0 foundation branch: PR #1 lint green; merge it (step of its own), then approve it and the P0 epic.
- WO-20261010-7083 - Quiet window in compaction-guard: quiet.json, 5 second countdown, watchers pause and queue, inbox drains after resume: draft, p0, under WO-20261010-84f1 - Monitoring: monitor seat, tab group, notifications, status codes; approve and start next (dotfiles compaction-guard change plus bearings wait loop).
- Then from INDEX.md: WO-20261010-6a3b Spike 11, WO-20261010-8777 herdr seat scripts, WO-20261010-c6e9 Spike 9, WO-20261010-eaa3 Spike 1 (needs owner's Qud Linux zip), WO-20261010-d08d Spike 10 coq-term variant A, wireframes ticket under 98ea, handoff WO-20261010-3593.

#### Blockers

- UAT-1 unanswered.
- Spike 1 needs the Qud Linux build from the owner.

### New this checkpoint

#### Decisions

- Owner (chat ~19:50 UTC): monitoring must never trip the compact; smart on and off, system message plus 5 second countdown, nothing stops the compact, nothing lost, every agent uses it. Recorded as REQ-compaction-quiet-window (SPEC-05 s-quiet), AGENTS.md golden rule, ticket WO-20261010-7083.
- Every step now ends commit + checkpoint + compact; this checkpoint closes step "spec quiet window".

#### Lessons Learned

- herdr 0.9.0 `pane list` has no --tab; a hidden usage exit under pipefail+errexit killed bearings.sh stop after the server died. Filter tab_id in jq.
- Running a reproduction of `stop` against the live uat tier stops it; reproduce against a dev tier next time.

### Hydration prompt

Read this checkpoint. Then: re-arm Monitor watches on panes wD3:p4 and wD3:pB (grep ^ANSWER|^MESSAGE|^STOPPED, 30 min, re-arm on expiry) after `herdr pane read` of each for lines newer than this checkpoint; act on any UAT-1 answer (step D above). Next step otherwise: merge PR #1 (gh pr merge 1 --squash), then approve and start WO-20261010-7083. One commit and one checkpoint per step, then queue `/compact` via herdr agent prompt wD3:p2 with the keep line, stop Monitors first.

## Checkpoint 2026-10-10 19:34 UTC

### Current state

#### Infrastructure

- Public repo https://github.com/jkkelley/coq-jev-herdr-plugin: main protected; PR #1 = feat/p0-foundation from slot 2 (now carries the golden rule in AGENTS.md, commit 6f5e759, pushed).
- Main checkout /home/luna/projects/coq-jev-herdr-plugin: 27 tickets; INDEX.md is the router; all draft except WO-20261010-ba08 (in-progress).
- Slot 1 /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1/coq-jev-herdr-plugin, branch feat/vendor-bearings-into-tools-bearings-with-stable- (WO-20261010-ba08): attachment port WIRED and committed (d38eaa4: POST /file, GET /file/:id, files-aware /message, wait prints `| files:`, file_max_bytes in config+schema, staging dir deleted). tests/inside.sh gained case T4b (3 checks, uncommitted). Suite running in pane wD3:p5 (prints MAKE_TEST_DONE rc=N). uat page http://localhost:44910/?key=f18907f3a02cec0412ad14fa027bda0f still serves the PRE-port process (wait pane wD3:p7), card UAT-1 open. Branch not pushed.
- Slot 2 (this checkout), branch feat/p0-foundation: specs 00,01,03,04,05 + stubs 02,15; graph 93 nodes; lint green; events/ queue/ roles/ playbooks/ factory/ bin/ Makefile.
- Owner page (old skill copy) http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928, server pane wD3:p3, wait loop pane wD3:p4 (its 30 min monitor expired; re-arm with herdr pane read polling). Open owner message m-20261010192521524-wfo6h (clipboard image paste) awaits the uat url reply.
- Memory: new file checkpoint-discipline.md (owner golden rule).
- SITREP 002: https://claude.ai/artifact/PnNrFEYTqaqsg2xx2MVc9d

#### Toolchain

- herdr 0.9.0 protocol 22 (pane.graphics.set live). treehouse v2.3.0 + slot.sh. work-order v2.1.0+#103. project-scaffold v1.6.0. compaction-guard 1.2.8 (sensor reads 0 for this session). Podman images localhost/coq-bearings-test:1, localhost/coq-lint:1.

#### Active Tasks

- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: step A (port) done; step B = read MAKE_TEST_DONE in pane wD3:p5, fix any red case, commit tests/inside.sh; step C = `make stop TIER=uat TICKET=WO-20261010-ba08` then `make serve ...` from slot 1 (new process has /file), reply on the old page to m-20261010192521524-wfo6h with the uat url; step D = UAT-1 answer, evidence AC5 via make migrate, push, PR, merge, make upgrade on main, stop old server, release slot 1. One checkpoint per step.
- WO-20261010-fbad - Land the P0 foundation branch: PR #1 open; merge after make lint.
- Then approve/start from INDEX.md: WO-20261010-6a3b Spike 11, WO-20261010-8777 herdr seat scripts, WO-20261010-c6e9 Spike 9, WO-20261010-eaa3 Spike 1 (needs owner's Qud Linux zip), WO-20261010-d08d Spike 10 coq-term variant A, wireframes ticket under 98ea, handoff WO-20261010-3593.

#### Blockers

- UAT-1 unanswered.
- Spike 1 needs the Qud Linux build from the owner.

### New this checkpoint

#### Decisions

- Owner golden rule (chat, 2026-10-10 ~19:40 UTC): every task carries its own checkpoints and compact points, scope small, compact sooner; written into AGENTS.md as "Golden rule: checkpoint every step, compact early" (replaces "Law: compaction") and into memory checkpoint-discipline.md.

#### Lessons Learned

- A staged verbatim extract can be cut short at a nested callback; always `node --check` after splicing and diff the tail against the source.
- Write the checkpoint while the suite runs in its pane, not after; the run outcome is one line to read on resume.

### Hydration prompt

Read this checkpoint. Then: `herdr pane read wD3:p5 --source recent-unwrapped --lines 60` for MAKE_TEST_DONE; green -> commit tests/inside.sh in slot 1 and do step C; red -> fix the case, rerun via `herdr pane run wD3:p5 "cd <slot1>/tools/bearings && make test 2>&1 | tail -40; echo MAKE_TEST_DONE rc=\${PIPESTATUS[0]}"`. Checkpoint after each step.

## Checkpoint 2026-10-10 19:27 UTC

### Current state

#### Infrastructure

- Public repo https://github.com/jkkelley/coq-jev-herdr-plugin (owner card Q11, 2026-10-10 19:28 UTC): main pushed and protected (linear history, no force push). PR #1 = feat/p0-foundation from slot 2.
- Main checkout /home/luna/projects/coq-jev-herdr-plugin: 27 tickets across epics WO-20261010-98ea (owner surface), 329d (P0 foundation), da54 (discovery spikes), coq-term epic, delivery epic, monitoring epic; all draft except ba08 (in-progress on its branch). INDEX.md is the router.
- Slot 1 /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1/coq-jev-herdr-plugin, branch feat/vendor-bearings-into-tools-bearings-with-stable- (WO-20261010-ba08): tools/bearings complete (17/17 cases, AC1-4 evidenced); assets/page.html now the owner's NEWER page (paste and drop composer); attachment server port staged under tools/bearings/scripts/lib/attach-port/ with README next steps; NOT yet wired, suite not rerun since the page swap. uat page served on http://localhost:44910/?key=f18907f3a02cec0412ad14fa027bda0f (panes bearings-uat-WO-20261010-ba08, wait wD3:p7), card UAT-1 open. Branch not pushed.
- Slot 2 /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/2/coq-jev-herdr-plugin, branch feat/p0-foundation (holder P0-foundation): specs 00,01,03,04,05 + stubs 02,15; graph 93 nodes; lint green; events/ queue/ roles/ playbooks/ factory/ bin/ Makefile. Pushed, PR #1 open.
- Owner page (old skill copy) ~/.bearings/coq-jev-herdr-plugin-05518e, url http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928, panes wD3:p3 server, wD3:p4 wait loop; cards Q1..Q11 and SPK5-1 all answered; latest owner message m-20261010192521524-wfo6h asks for clipboard image paste (answer: port in progress, see slot 1).
- Dotfiles: PRs #103 and #104 merged, ~/dotfiles main at 7672b3c, slots released; live work-order skill renders Contents and Degrees of freedom; container-sandbox has scripts/new-podman-suite.sh.
- compaction-guard bound (fable-discovery, pane wD3:p2) but sensor reads 0; owner reported 51 percent context at 19:30 UTC. Test pane wD3:p5 free (test card cleared).
- SITREP 002: https://claude.ai/artifact/PnNrFEYTqaqsg2xx2MVc9d

#### Toolchain

- herdr 0.9.0 protocol 22 with pane.graphics.set/clear/info (Spike 5 PASSED: owner saw the test card). treehouse v2.3.0 + slot.sh. work-order v2.1.0+#103 (--freedom). project-scaffold v1.6.0. compaction-guard 1.2.8. Podman images localhost/coq-bearings-test:1, localhost/coq-lint:1. Scratch RPC helper scratchpad/spike5/herdr-rpc.py (session-only; recreate from memory file herdr-pane-graphics-live).

#### Active Tasks

- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: finish the attachment port per attach-port/README.md, rerun make test (add the file case), restart the uat server from the slot, reply to m-20261010192521524-wfo6h, wait for UAT-1, evidence AC5 via make migrate, push branch, PR, merge, make upgrade on main, stop the old server, release slot 1.
- WO-20261010-fbad - Land the P0 foundation branch: PR #1 open; review and merge after lint in CI (no CI workflow yet; run make lint locally and record it).
- Next tickets to approve and start (main is draft): WO-20261010-8777 herdr seat scripts (depends on Spike 11 WO-20261010-6a3b), WO-20261010-c6e9 Spike 9, WO-20261010-eaa3 Spike 1 (needs the owner's DRM-free Qud Linux zip), WO-20261010-d08d Spike 10 coq-term variant A (depends on the protocol ticket), the wireframes ticket under 98ea (figma-wireframe skill, first visual gate), handoff ticket WO-20261010-3593.

#### Blockers

- UAT-1 unanswered (owner must confirm the uat page).
- Spike 1 needs the Qud Linux build from the owner.
- This session's context is past 50 percent; compact after this checkpoint.

### New this checkpoint

#### Decisions

- Owner cards: Q10 merge dotfiles PRs now (done); SPK5-1 the test card renders (Spike 5 passed); Q11 create jkkelley/coq-jev-herdr-plugin now (done).
- Owner chat: tiers everywhere; own Rust pane program coq-term as the path; variants in parallel with uat per herdr session; per-package CI/CD, semver, gitops; FP mindset; templates not hand-writing; local fast, CI full; leases and queues, no human blockers.

#### Lessons Learned

- Owner-facing surface drift: ~/.claude/skills/bearings is a stale snapshot of ~/projects/getting-my-bearings/skills/getting-my-bearings; always diff against the project copy before vendoring.
- The shell behind the Bash tool is zsh: unquoted $var does not word-split; generate files with python when a list must expand.
- A relative glob removal after cd is blocked by the harness; use absolute scratch paths.

### Hydration prompt

Read this checkpoint. Then: in slot 1 finish tools/bearings/scripts/lib/attach-port per its README, rerun make test from pane wD3:p5 via herdr pane run, restart the uat tier (make stop/serve TIER=uat TICKET=WO-20261010-ba08) and reply on the old page to m-20261010192521524-wfo6h with the uat url. Then act on UAT-1 when it lands. Then merge PR #1 after make lint, approve and start the next tickets from work-orders/INDEX.md.

## Checkpoint 2026-10-10 19:07 UTC

### Current state

#### Infrastructure

- Repo main: /home/luna/projects/coq-jev-herdr-plugin (scaffold, Apache-2.0, treehouse.toml, tickets). No GitHub remote yet.
- Slot 1: /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1/coq-jev-herdr-plugin, branch feat/vendor-bearings-into-tools-bearings-with-stable-, holder WO-20261010-ba08. tools/bearings complete, 17/17 Podman cases green, AC1-4 evidenced, AC5 waits on the owner's uat confirmation (card UAT-1 on the uat page http://localhost:44910/?key=f18907f3a02cec0412ad14fa027bda0f, panes bearings-uat-WO-20261010-ba08 and its -wait wD3:p7).
- Slot 2: /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/2/coq-jev-herdr-plugin, branch feat/p0-foundation, holder P0-foundation. Holds specs/ (XSD, SPEC-00, SPEC-01), graph/ (80 nodes, graph.sh), lint/ (Containerfile + lint.sh, image localhost/coq-lint:1), bin/md-contents.sh, events/ (schema + event.sh), roles/ (schema, 9 roles, render-playbook.sh), playbooks/ (rendered), root Makefile. make lint green.
- Dotfiles: PR #103 (work-order degrees of freedom + contents, CI green) and PR #104 (container-sandbox suite generator) open, both from slots ~/.treehouse/dotfiles-ff4128/{1,2}/dotfiles; owner card Q10 decides the merge.
- Owner old page: ~/.bearings/coq-jev-herdr-plugin-05518e (server pane wD3:p3, wait loop wD3:p4, url http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928) with cards Q1..Q10 and SPK5-1 open; all Q1..Q9 answered.
- Test pane wD3:p5 "test - bearings WO-20261010-ba08" holds the Spike 5 PNG test card pushed via pane.graphics.set (layer spike5).
- compaction-guard bound to this session (fable-discovery, pane wD3:p2) but its sensor reads 0; project hooks installed in slot 1's .claude/settings.json.
- SITREP 001: https://claude.ai/artifact/PnNrFEYTqaqsg2xx2MVc9d

#### Toolchain

- herdr 0.9.0 protocol 22: pane.graphics.set/clear/info exist live (docs v0.9.3 say removed). treehouse v2.3.0, slot.sh. work-order v2.1.0 (+#103). project-scaffold v1.6.0. compaction-guard 1.2.8. Podman images: localhost/coq-bearings-test:1, localhost/coq-lint:1. Scratch RPC helper: scratchpad/spike5/herdr-rpc.py.

#### Active Tasks

- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: in-progress, waiting on UAT-1. Then: evidence AC5 (migrate), PR (needs remote), merge, make upgrade on main, stop old server, release slot 1.
- WO-20261010-98ea - Owner surface: bearings page, SITREP site and factory dashboard: epic, ready.
- P0 foundation (slot 2): needs tickets once Q10 lands (cut with --freedom), SPEC-02..05 and 13 as data+XML, queue/ script (REQ-locks-and-queues), evidence.sh kickback, herdr layouts after wireframes, seat briefs (one line each from roles), handoff ticket to the interface agent, Rust coq-term spike ticket.
- Spike 5: owner card SPK5-1 asks whether the test card renders in pane wD3:p5.
- Backlog now/next in slot 1: event log (done in slot 2), monitor seat, notifications, mod adapter family, no process under agent, system before agents, status-change wakeups.

#### Blockers

- Owner cards open: UAT-1, Q10, SPK5-1.
- No GitHub remote for the public monorepo yet (name unconfirmed; "coq-jev-herdr-plugin" assumed).

### New this checkpoint

#### Decisions

- Owner chat 2026-10-10 19:00-19:30 UTC: container-sandbox is the testing source of truth (section + generator added, #104); test plans and harnesses are generated by scripts; functional programming mindset, frameworks, right tool; local runs only what proves the change, CI runs full suites and lint, speed is king; locks are TTL leases with automatic release, work is a priority queue, no human blockers except owner cards; build our own Rust pane program (coq-term) that renders game frames into a herdr pane, the browser plugin proved the pipeline (DEC-own-game-terminal supersedes DEC-rust-terminal-parallel).
- Prior art recorded: ogulcancelik/herdr-browser (CDP screencast PNG over pane.graphics.stream), zenbu-labs/terminal-browser (Electron offscreen + Kitty graphics).

#### Lessons Learned

- `tr | head -c` under pipefail dies with SIGPIPE 141; read a bounded chunk and cut instead.
- xs:sequence in XSD forbids interleaving; a section body is xs:choice unbounded.
- Playwright waitForFunction with interval polling treats a promise-returning predicate as true; poll from Node.
- Keep P0 work out of the scratchpad; a slot per concern, committed early.

### Hydration prompt

Read this checkpoint, then CONTEXT_STATE.md in slot 1 for the bearings detail. Next: read the three owner cards (UAT-1 on the uat page, Q10 and SPK5-1 on the old page), act on each, then cut P0 tickets in slot 2 with --freedom and continue SPEC-02..05.
