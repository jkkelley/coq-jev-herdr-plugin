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
