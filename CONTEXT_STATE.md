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

## Checkpoint 2026-10-10 18:40 UTC

### Current state

#### Infrastructure

- Repo: /home/luna/projects/coq-jev-herdr-plugin, branch main (3 commits: scaffold + Apache-2.0 + treehouse.toml; tickets cut). Public monorepo decided, no GitHub remote yet.
- Work slot: /home/luna/.treehouse/coq-jev-herdr-plugin-81af2c/1/coq-jev-herdr-plugin, branch feat/vendor-bearings-into-tools-bearings-with-stable-, leased by WO-20261010-ba08 via slot.sh.
- Dotfiles slot: /home/luna/.treehouse/dotfiles-ff4128/1/dotfiles, branch feat/work-order-degrees-of-freedom, commit b85d1ac, 338 checks green, not pushed, no PR, slot held by WO-20261010-ba08-dof.
- Owner page (stable, old skill copy): ~/.bearings/coq-jev-herdr-plugin-05518e, server pane wD3:p3, wait loop pane wD3:p4, url http://localhost:44967/?key=6e636c7db73a36c5a802bf2fd5df5928. Patched ~/.claude/skills/bearings/assets/page.html line ~1144 with a null guard (backup .bak-20261010T1815Z).
- Test pane wD3:p5 "test - bearings WO-20261010-ba08" runs make test in tools/bearings (Podman image localhost/coq-bearings-test:1 from mcr.microsoft.com/playwright@sha256:b27e719e...).
- compaction-guard 1.2.8 bound to this session (name fable-discovery, pane wD3:p2, threshold 30) and installed into the slot's .claude/settings.json (5 hooks). Its ctx sensor reads 0 for this session (no status line tap at session start).
- SITREP 001: https://claude.ai/artifact/PnNrFEYTqaqsg2xx2MVc9d (source scratchpad/sitrep-001.html).
- herdr 0.9.0, session stable, this agent pane wD3:p2 in workspace wD3 tab wD3:t2.

#### Toolchain

- herdr CLI + socket API (digest in SITREP), treehouse v2.3.0 (pool ~/.treehouse), work-order skill v2.1.0 (+ degrees-of-freedom branch in dotfiles slot), project-scaffold v1.6.0 (applied), compaction-guard 1.2.8, bearings skill (~/.claude/skills/bearings, stale Sep 15 copy; owner refuses the gmb CLI), Podman, node 22 in test image, jq.

#### Active Tasks

- WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers: in-progress. Written: tools/bearings/{Makefile,VERSION,config/bearings.json,config/bearings.schema.json,scripts/{bearings.sh,server.mjs,wait.mjs,reply.mjs,lib/config.mjs},assets/{page.html,theme.css},tests/{Containerfile,run-tests.sh,inside.sh,probe.mjs}}. Suite: 13 pass, 4 fail (probe page errors; queued answer not reaching answers.jsonl; dependent migrate/wait cases). Missing: tools/bearings/AGENTS.md (contents list, GOOD/NEVER, promotion dev->uat->stable), commit, PR.
- WO-20261010-98ea - Owner surface: bearings page, SITREP site and factory dashboard: epic, ready.
- Backlog now/next (slot): event log dir (status codes, UTC, one file per entry), monitor seat + herdr tab group, herdr notifications, mod-based adapter family (Qud + Cities Skylines 2), no process under an agent, system-before-agents bring-up, status-change notifications to agents (owner msg m-...x90s1, not yet queued).
- P0 to write this session (owner Q7): SPEC-00 index + knowledge graph, SPEC-01 conventions, seat briefs for 10 seats + 1 Rust terminal spike seat, handoff ticket to the interface agent (migrate page state, transcript, memory, hydration).

#### Blockers

- compaction-guard cannot see this session's context percent (sensor none); compaction for this session relies on the harness.
- No GitHub remote yet; PR flow needs the public repo created (owner decision: public monorepo, Apache-2.0; name unconfirmed).

### New this checkpoint

#### Decisions

- 2026-10-10 UTC owner, bearings cards Q1..Q9: Linux-native Qud in WSL2; bypass for working roles, dontAsk for interface/orchestrator; Layla = second System One model; one public monorepo Apache-2.0; DRM-free Qud copy; SITREP server local first then cluster; this session writes the whole P0; Rust terminal spike starts in parallel as an 11th seat; vendored bearings layout approved.
- Owner on page: only the interface agent gets the bearings tool; at P0 completion everything (page state, chat, logs) transfers to it. Owner talks only through the page.
- Owner: no process under an agent (blocks compaction, hides work); no Agent-tool subagents in the factory, herdr seats only; monitoring and the system come up before any agent; agents are notified on status change instead of idling.
- Owner: config files and variables, S3-portable; Makefiles as entry points; nothing hardcoded.

#### Lessons Learned

- ~/.claude/skills/bearings is a stale snapshot: page.html bound a listener to a missing #list element and died before polling; verify a page in a browser before shipping its link.
- Playwright ESM import ignores NODE_PATH; resolve the global package with createRequire.
- work-order start refuses a dirty tree: commit approvals on a chore branch first, then start.
- Backgrounded podman runs under the agent are exactly what the owner forbids; run them in a labelled pane and read with pane wait-output.

### Hydration prompt

Read HYDRATION.md top entry when it exists, else this checkpoint. Continue WO-20261010-ba08 - Vendor bearings into tools/bearings with stable, uat and dev tiers in the slot: fix the 4 failing cases (read pane wD3:p5), write tools/bearings/AGENTS.md, commit on the feature branch, then migrate the owner page into the stable tier only after owner confirmation from the uat tier.
