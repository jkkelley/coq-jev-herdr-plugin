# L11 - The governance layer

Investigator: L11, Factory Rebuild step R-01, attempt 2.
Attempt 1 written 2026-10-14T02:50Z (UTC); this revision written 2026-10-14T03:05Z (UTC).
Read-only investigation; the only writes are this file.
Counts marked "live" are read from append-only ledgers and can grow while the rebuild runs.

## 1. Contents

1. Contents
2. What it is
3. Where it lives
   - 3.1 Rule and hook stores
   - 3.2 The firing map: what fires at which moment
   - 3.3 The ten named skills: what each does and when it fires
4. What works
5. What broke and why
   - 5.1 Where the evidence disagrees with the brief
   - 5.2 Findings F1 to F18
   - 5.3 Which of it would fight a rebuild
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

The governance layer is every rule, hook, skill, plugin, guard and gate that fires around a Claude seat before and while it does its ticket.
It is spread over at least nine stores, and only the playbooks and the seat settings are generated from another store (the role JSON).
The nine stores are the global agent file, the project agent file, the roadmap, the architect's private memory, the user-level and project-level `settings.json` hooks, the user skills, the superpowers plugin, the compaction-guard binary, and the seat fence rendered from the role JSON.
The owner's own words for the failure, typed 2026-10-14T02:27:10Z in the architect session: "I keep getting fucked by the governance of the system, it gets half built or whatever and the rules start fucking with my building" (transcript `/home/luna/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/e31510a1-4a15-4377-9c1c-8f1088f67bed.jsonl`, promptIndex 12).
The short result of this investigation: Claude hooks rarely block anything here.
The cost sits in contradictory prose rules, a ticket skill built for one human and one checkout, a fence that stalls seats, and a session-start payload carried by every seat.
No Claude hook fires on PR open or on merge at all (section 3.2); those two moments are governed by playbook text, shell scripts and records, never by a hook.
Most important for the rebuild: "build mode" exists only as a private memory note, not as a mechanism (F1), and the guard already bit the rebuild session itself 70 seconds after it was bound (F17).

## 3. Where it lives

### 3.1 Rule and hook stores

| Store                      | Path                                                                                                                                                                              | Size                                                                                     | Loaded into a seat by                                                                                      |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Global agent rules         | `/home/luna/.claude/CLAUDE.md`, a symlink to `/home/luna/AGENTS.md`                                                                                                               | 14,823 bytes, 217 lines, 8 "Hard rule" sections (re-counted)                              | Claude Code, every session on the machine                                                                  |
| Project agent rules        | `/home/luna/projects/coq-jev-herdr-plugin/AGENTS.md`                                                                                                                              | 23,235 bytes, 365 lines, 21 Golden/Hard/Law sections, 25 GOOD or NEVER lines (re-counted) | `CLAUDE.md` (438 bytes, re-measured; it says "Read AGENTS.md") and the seat reads AGENTS.md by tool call   |
| Roadmap                    | `ROADMAP.md` in the project                                                                                                                                                       | 17,117 bytes                                                                             | AGENTS.md line 36 says read it before any work                                                             |
| Architect memory           | `/home/luna/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/memory/`                                                                                                    | 39 files, 176 KB live; index `MEMORY.md` 7,134 characters live (6,118 in the Oct 14 worker snapshot) | Claude Code AutoMem, including seats in treehouse slots (F7)                          |
| Memory-only rule           | `memory/build-mode-rule.md` (modified 2026-10-14T02:32:28Z)                                                                                                                       | 1,378 bytes (re-measured with `wc -c`)                                                   | its one-line index entry is `MEMORY.md` line 35, so every new seat sees the index line; the body is read only if a seat opens it |
| User hooks                 | `/home/luna/.claude/settings.json`                                                                                                                                                | 174 lines; hook events PostToolUse, SessionStart, UserPromptSubmit, Stop, Notification, SessionEnd; no PreToolUse | Claude Code, every session                                                       |
| Project hooks              | `/home/luna/projects/coq-jev-herdr-plugin/.claude/settings.json`, tracked                                                                                                         | 82 lines; SessionStart, Stop, PreCompact, PostCompact, PreToolUse, plus a `statusLine` tap | Claude Code, sessions with this project as cwd                                                           |
| Seat settings              | `<state>/seats/<seat>/settings.json`, rendered by `herdr/bin/seat.sh` `render_settings` (lines 129-139)                                                                           | per seat                                                                                 | `claude --settings` at seat start (seat.sh line 809)                                                       |
| User skills                | `/home/luna/.claude/skills/`                                                                                                                                                      | 17 skill directories (8 symlinks into `/home/luna/dotfiles/claude/skills`, 9 real directories) plus `synced` and `.trash` | skill listing, 80 entries, 32,566 bytes in the first turn                              |
| Project skills             | `.claude/skills/` (gitignored copies) from `.claude/skills.toml`                                                                                                                  | work-order 2.2.0, living-docs 1.0.2, container-sandbox 1.6.0, context-compaction 2.0.1   | `skill-sync --boot` at session start                                                                       |
| Plugins                    | `/home/luna/.claude/plugins/`, enabled in user settings.json lines 152-158                                                                                                        | superpowers 6.3.0, github, context7, frontend-design, figma; only superpowers ships a hooks.json | plugin SessionStart hook                                                                            |
| compaction-guard           | `/home/luna/projects/compaction-guard` (source), `/home/luna/.local/bin/compaction-guard` (live release 1.2.8-5203f8b5, byte-identical to the source, `diff -q`)                   | 1,574 lines bash                                                                         | five hook entries in the project `.claude/settings.json` plus the status line tap                          |
| Role schemas and playbooks | `roles/*.json` (11), `playbooks/*.md` (11, 693 lines)                                                                                                                             | generated, lint-checked                                                                  | `herdr/bin/seat.sh`, `roles/bin/brief.sh`                                                                  |
| Other rule stores          | `/home/luna/projects/how-i-work/rules.json` (34 rules), `/home/luna/projects/stable/principles/principles.json` (105 principles, linked as `~/OPINIONS.md`), `/home/luna/dotfiles/CLAUDE.md` (486 lines, 19 rules), `/home/luna/.claude/skills/bearings/priorities.md` | various                                                                    | only by the project that vendors them                                                                      |
| Dead enforcement           | `/home/luna/.claude/hooks/no-hand-start.mjs` (276 lines), `shell-lex.mjs` (508 lines)                                                                                             | 784 lines                                                                                | nothing; `grep no-hand-start` over `~/.claude/settings*.json` and the project `.claude/settings*.json` finds no match in any current file |

### 3.2 The firing map: what fires at which moment

Session start, every Claude process (seat or not).
User settings, `/home/luna/.claude/settings.json`:

- `lavish-axi` on startup|resume, timeout 10 (entry lines 38-47).
- `gh-axi` on startup|resume, timeout 10 (lines 48-57).
- `chrome-devtools-axi` on startup|resume, timeout 10 (lines 58-67).
- `skill-sync --boot` on startup|resume|clear, timeout 30 (lines 68-77).
- `herdr-agent-state idle` with matcher "" (every source), timeout 5 (lines 78-87).
- `herdr-agent-state.sh session` on `*`, timeout 10 (lines 88-97).

Plugin: the superpowers `session-start` hook (`hooks/hooks.json`, matcher `startup|clear|compact`) injects `<EXTREMELY_IMPORTANT>` text, 3,587 bytes, that says a skill MUST be invoked before any response including clarifying questions.
Project settings, `.claude/settings.json`: `compaction-guard hook` on every source, timeout 30 (entry lines 8-17); `herdr/bin/resume-checkpoint.sh` on compact, timeout 10 (lines 18-27).
Seat settings, rendered from the role: the same compact-only `resume-checkpoint.sh` entry (seat.sh lines 129-139), plus break-glass hooks only while a break glass is open (`herdr/bin/break-glass-lib.sh` lines 146-147 add a Bash PreToolUse and PostToolUse; `herdr/bin/break-glass-guard.sh`).
Instruction files: global CLAUDE.md 14,638 characters, project CLAUDE.md, MEMORY.md 6,118 characters (attachment type `instructions` in the Oct 14 worker transcript `6fe8d57b-81d4-49cc-82d7-b91f580e68b5.jsonl`).

Every tool call.

- `PreToolUse` with matcher "" (every tool) runs `compaction-guard hook`, timeout 10 (project `.claude/settings.json` lines 65-76; it is the only PreToolUse entry in any current settings file).
  It denies while a compaction is pending (`hook_pre_tool_use`, compaction-guard line 916 onward).
  For a role-bound session only, it denies any command that mentions the guard state or `.claude/settings.json` (`tamper_check`, lines 888-915; the role-bound test is line 890).
- `PostToolUse` with matcher `Write|Edit` (user settings lines 22-36): `npx prettier --write --ignore-unknown` on the file unless the path contains `work-orders/` (line 28), then `go test ./...` when the file ends in `.go` (line 32).

Every turn.

- `UserPromptSubmit` herdr-agent-state working (user settings lines 99-110), `Stop` herdr-agent-state idle (lines 111-122) and `compaction-guard hook` (project lines 29-40; it arms `/compact` at or over the threshold, 30 percent unbound, `hook_stop` line 762 onward), `Notification` blocked (lines 123-134), `SessionEnd` release (lines 135-146).
- Project `PreCompact` (lines 41-52) and `PostCompact` (lines 53-64) run `compaction-guard hook` with timeouts 120 and 60.

Ticket cut and approve (work-order skill 2.2.0, `scripts/work-order.sh`).

- `new` refuses without `--out` and without `--parent` or `--top-level`.
- `approve` needs `lavish-axi` on PATH or `--no-lavish --reason` (work-order.sh lines 782-790), refuses open questions and a ticket with no `AC-` criteria.
- `approve` rewrites the ticket, so the tree is dirty and `start` refuses until it is committed (`references/lifecycle.md` lines 49 and 58).

Ticket start.

- `bin/wo-start.sh` runs `factory/bin/claims.sh start` (file overlap with any open PR or live ticket), then `work-order.sh start`: status must be `ready`, tree must be clean (line 813), `git checkout -b feat/<slug>` from the checkout HEAD (line 820).
- `line/bin/start-tickets.sh` wraps this: throwaway worktree from `origin/main` (line 40), copies the gitignored `.claude/skills` in (line 41), `make step`, push, copies the ticket into the main checkout, removes the worktree, then `seat.sh`.

Seat bring-up (`herdr/bin/seat.sh`).

- Refuses without `compaction-guard` on PATH (line 519), without the monitor seat live (lines 523-527), over the role cap, over the system cap, when the seat would post to a different records tree (`state_root_gate`).
- Writes `hasTrustDialogAccepted` into `/home/luna/.claude.json` for the worktree (`ensure_trust`, line 722).
- Starts `claude --model --effort --permission-mode --settings` in a herdr pane (line 809), then types a one-line brief from `roles/bin/brief.sh`, then waits up to 15 seconds for a guard ACK line and nudges once (`nudge_seat`, line 772).

Work.

- `make step` (`bin/step.sh`): checkpoint body check, `make lint` in a Podman container (line 23), `changelog.sh add` (line 25), `git add -A` (line 26), commit with a trailer (lines 32-33), push (line 35), `checkpoint.sh new` (line 43).
- Tests only in the labelled test pane through `herdr/bin/testpane.sh` (worker playbook step 3 and Forbidden list, `playbooks/worker.md` lines 33 and 50).
- Fence: `bypassPermissions` plus the role deny list (for example the tester denies `git *` and `gh *`, `roles/tester.json` deny.commands).

PR open.

- No Claude hook fires on PR open.
  The only PreToolUse entry anywhere is the matcher-"" compaction-guard entry at project `.claude/settings.json` lines 65-76, which fires on every tool call alike and has no `gh pr create` rule.
  The user `settings.json` has no PreToolUse key (its six hook events are listed in section 3.1; PostToolUse is limited to the `Write|Edit` matcher at line 24).
  The superpowers plugin's `hooks.json` holds only SessionStart; the github, context7, frontend-design and figma plugin caches hold no hooks file (`find` over `~/.claude/plugins/cache/claude-plugins-official/<plugin>`).
  The seat settings add a Bash PreToolUse only while a break glass is open (`break-glass-lib.sh` lines 146-147).
  Git side: no `core.hooksPath` is set and `.git/hooks` holds only `.sample` files.
  The seat's `gh pr create` is permitted by the fence; the project `.claude/settings.local.json` lines 7-9 also allow `gh-axi pr create`, `gh-axi pr edit` and `gh-axi pr *`, and those are permissions, not hooks.
- What does act on a PR open is playbook text: worker playbook step 6 (`playbooks/worker.md` line 36): evidence per criterion, retro note, commit, push, `gh pr create`, `work-order.sh submit --pr N`, `work-order.sh done`, push the archive move, post `pr.opened`.
- `factory/bin/gate.sh pr-files` fails a diff that strays from the ticket's files, but nothing calls it automatically: its own breadcrumb says "routes.json does not call it yet ... the gate is run by hand or by the merger's step" (gate.sh lines 28-33), and `grep pr-files` over `factory/config/routes.json` and `line/bin/merge.sh` finds nothing.
  There is no `pr-fence` verb anywhere in the repository (`grep -rn pr-fence`); attempt 1 named one in error.
  The path fence for `roles/`, `specs/`, `graph/` is the worker role's `deny.paths`, rendered as `Edit` rules (roles/worker.json), which is a fence on the seat and not a check on the PR.
- Jenkins `coqGate()` posts `coq/gate` on the head sha (`Jenkinsfile` lines 1-16; L07 covers it).
  GitHub does not require it: `gh api repos/jkkelley/coq-jev-herdr-plugin/branches/main/protection` on 2026-10-14T02:55Z returned `required_status_checks: null`, `required_pull_request_reviews: null`, `required_linear_history: true`, `enforce_admins: false`; `gh api .../hooks` returned `[]` and `.github/` does not exist.

Merge.

- No Claude hook fires on merge, for the same reasons as PR open (project `.claude/settings.json` lines 65-76 is the only PreToolUse; user settings have none).
- `line/bin/merge.sh` is the gate, and it is code, not a hook.
  It reads records, not the `coq/gate` status: the newest `review.passed` 201 must name the PR head, `gate.sh same-head` and `gate.sh when heads_match` must find a `test.passed` 201 on it (merge.sh lines 337-353); a missing review holds the merge with exit 3 (line 339).
  `grep coq/gate line/bin/merge.sh factory/bin/*.sh herdr/bin/*.sh` finds nothing, so attempt 1 was wrong that merge.sh "keys on coq/gate".
  GitHub's `--match-head-commit` makes the merge fail if the head moves (merge.sh breadcrumb lines 33-45).
- After the merge it does its own cleanup without `work-order.sh cleanup` (merge.sh lines 289-300).
- `git` itself has no merge hook set (see PR open).

### 3.3 The ten named skills: what each does and when it fires

None of the ten is a hook.
A skill fires in two ways only: its one-line description is in the skill listing of every session (32,566 bytes for 80 entries, F6), and a model or the owner invokes it through the Skill tool.
The "Skill calls" column is a count of `Skill` tool_use blocks across the 682 coq transcripts (python scan, 2026-10-14T02:56Z).
Scripts that a skill ships are called through Bash and are not counted there.

| Skill and version                                                    | What it does                                                                                                                                                                                  | Seat start                                       | Ticket start                                                                                          | PR open                                                                                                                      | Merge                                                                                                   | Skill calls | Would it fight a rebuild                                                                                                                                                              |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| work-order 2.2.0 (real directory, project copy synced)               | Ticket lifecycle in `scripts/work-order.sh`: new, approve, start, evidence, submit, done, cleanup.                                                                                          | Listing only; `skill-sync` re-copies it          | `start` refuses a dirty tree (line 813) and runs `git checkout -b` (line 820); `approve` needs Lavish (lines 782-790) | `submit --pr` and `done` run from worker playbook step 6                                                                      | `cleanup` runs `git checkout main` (line 969); `merge.sh` replaced it (lines 289-300)                     | 9           | Yes. F3 and F4: ceremony approval, two PRs per ticket, single-checkout assumptions.                                                                                                   |
| hydration-prompt 2.1.0 (symlink)                                     | Writes the next-session prompt, keeps `HYDRATION.md` as a 10-entry window, acquires and releases a treehouse slot lease.                                                                   | None                                             | Its `acquire` verb leases a slot (SKILL.md line 124 "refuses a second slot for one ticket"); interactive                   | The description puts it at close-out "before the pull request is opened"                                                      | None                                                                                                    | 0           | Not on its own. `seat.sh` lines 175-178 record that its lease path "is an interactive skill, not a command a seat can call", so the line already replaced it with `seat.sh` and treehouse. |
| session-workflow 1.0.3 (symlink)                                     | A 275-line session ritual for multi-session plans: orient, branch, work, test, verify, checkpoint, PR, hand-off, stop. Written for terraform and Ministack sessions (SKILL.md lines 73 and 120).    | None; triggered by the owner saying "session-mode", "start session N" or `/session-workflow` (lines 13-15) | Step 0 creates `feat/session-<name>` with `git checkout -b` (line 38), never `main` (line 266)          | Step 4 asks "Ready for context compaction before I open the PR? (yes / no)" (line 139), then `gh pr create` (line 158); step 6 waits for the user to confirm the review (line 176) | Step 6 waits for the user to confirm the merge (line 189); it never cleans the branch without asking (lines 198, 270) | 0           | Yes, if any seat ever invoked it: three mandatory waits for a human, a branch name the line does not use, a PR-log skill `daily-pr-log` that is not installed (lines 180-183; `ls ~/.claude/skills | grep daily` is empty). Not in `.claude/skills.toml`; `git grep session-workflow` in the repository finds nothing. |
| no-mistakes (binary v1.75.2, 2026-09-14; skill file real directory)  | A local Git proxy and pipeline: intent, rebase, review, test, document, lint, push, PR, CI watch (SKILL.md lines 8-11; `no-mistakes --help`: "validates code before pushing to the configured target"). | None                                             | Needs a feature branch and `no-mistakes init` (SKILL.md lines 97-103)                                  | Yes, if the repo is initialized: it gates the push and then opens the PR and watches CI (`ci_timeout: 4h` in `~/.no-mistakes/config.yaml`). In this repo it gates nothing. | It does not merge; it stops at checks-passed (SKILL.md lines 223-224)                                  | 0           | Yes if turned on: it owns push, PR open and CI wait, which are `make step`, `gh pr create` and `coqGate()` here. Not initialized for this repo: `git remote -v` shows only `origin`, and the 12 initialized repos in `~/.no-mistakes/repos` are other projects (yieldpoint, bearings, rime, firstmate and more). The `no-mistakes` pipeline is a second agent loop, and its test-quality rule (SKILL.md lines 66-95) forbids source-grep tests that the repo's own lint steps use. |
| container-sandbox 1.6.0 (real directory, project copy synced)        | Runs npm, go and pip work in Podman containers; a localhost preview recipe (SKILL.md line 16 "never run npm install on the host").                                                         | Listing only                                     | None                                                                                                  | None                                                                                                                         | None                                                                                                    | 0           | Partly. The Podman-only rule is also in global CLAUDE.md and AGENTS.md "Law: testing"; line 619 runs `( sleep 1800 && podman stop ) &`, a background job (F2). The rebuild's pods and Jobs need the wording to allow them. |
| context-compaction 2.0.1 (real directory, project copy synced)       | Checkpoint format for `CONTEXT_STATE.md`, a 10-deep window, `checkpoint.sh new`.                                                                                                              | `resume-checkpoint.sh` reads the top checkpoint on compact | None                                                                                                  | `bin/step.sh` line 43 writes a checkpoint after every step                                                                    | None                                                                                                    | 2           | Mildly. A seat-authored "restated in full" body is a decision a rule could make (section 7); the guard builds its own (`checkpoint_build`, line 483). |
| living-docs 1.0.2 (real directory, project copy synced)              | The documentation standard; no gate of its own, it rides `work-order` `done` behind `--observed` evidence (SKILL.md lines 21 and 112).                                                     | Listing only                                     | None                                                                                                  | Through `work-order.sh done` at playbook step 6                                                                                | None                                                                                                    | 0           | No direct fight. Its gate is work-order's, so it moves with F4.                                                                                                                       |
| project-scaffold 1.6.0 (symlink)                                     | Installs AGENTS.md, COMPASS.md, `issues/`, `backlog/`, NAMING.md and the scripts that own their formats; "an agent never hand-edits a managed file" (SKILL.md line 11).                   | None                                             | None                                                                                                  | None, unless installed with `--ci` (`.github/workflows/context-check.yml`, SKILL.md lines 76-80); this repo has no `.github/` | None                                                                                                    | 1           | Residue, not behaviour. `.claude/scripts/{backlog.sh,log-issue.sh,lib/common.sh}` are tracked, COMPASS.md is the unfilled template, `backlog/now` is untracked, while ROADMAP decision C14 and AGENTS.md line 117 say the backlog lives in GitHub issues (F2). |
| bearings (real directory)                                            | Publishes a decision page for the owner and runs a wait loop for answers.                                                                                                                     | Listing only                                     | None                                                                                                  | None                                                                                                                         | None                                                                                                    | 2           | Yes where a seat follows it: lines 33 and 66 order `run_in_background: true`, against AGENTS.md lines 184-196 (F2).                                                                  |
| execution-rail 1.0.1 (real directory; project holds its own fork in `report/rail/`) | A tracker page for a numbered plan: `plan.json`, a TSV ledger appended only by `bin/ledger.sh`, a page built by `bin/rail-build.sh` and published as a claude.ai artifact; a plan step with `gate` true stops for the owner and the page waits for a `GOTEAM`-style signal (SKILL.md lines 16-19, 32). | None                                             | None                                                                                                  | None. `grep rail.sh` over `bin line herdr factory roles playbooks Makefile lint .claude` finds no caller, so nothing fires it; AGENTS.md lines 220-245 name `report/rail.sh` as the Claude seat's owner surface | None                                                                                                    | 1           | Yes on the principle, not the code: the page moves only when an agent appends a ledger row ("Log with `bin/ledger.sh`", SKILL.md line 29; "Republish only after a ledger row", line 38), which is the agent-driven pattern the owner rejected on 2026-10-14. The project fork exists because the upstream scripts wrote to another project's ledger (`report/rail.sh` breadcrumb, `report/rail/bin/ledger.sh` line 9). |

## 4. What works

Evidence is a file and line, a record, or a count I took from the stores named in section 11.

- The seat fence and settings are one deterministic render.
  `herdr/bin/seat.sh` lines 129-139 render `permissions.allow`, `permissions.deny` and the hooks from `roles/<role>.json`, and `--check` compares the rendered text to the file on disk with `cmp` (line 314, inside the check block lines 310-320).
  Drift is detected, not assumed.
- Roles, playbooks and briefs come from one source.
  `lint/lint.sh` step "roles: schema + playbooks in sync" runs `roles/bin/render-playbook.sh --check`; `roles/bin/brief.sh` prints the one-line brief a seat receives.
  A seat starts from one line plus a 62-line playbook (`playbooks/worker.md`).
- Hooks cost little and almost never block.
  Across 682 coq transcripts there are 2,861 `stop_hook_summary` rows with zero hook errors and 5,699 Stop-hook runs (herdr-agent-state and compaction-guard) with a median of 140 ms, p95 250 ms (attempt 1 scan, not re-run).
  There are no `hook_blocking_error` attachments in those transcripts (re-run: 0 of 682 files contain the string).
  I timed 10 `compaction-guard hook` PreToolUse calls against a scratch state directory: 0.855 s total, about 85 ms each.
  The guard ledger holds 26 `tool_denied` events in 25 days, of which 12 fall in October, and 43 `tamper_denied`, 4 in October (`/home/luna/.local/state/compaction-guard/events.jsonl`, re-counted with `jq` on 2026-10-14T02:54Z; the count was 42 before 02:41:32Z on 2026-10-14, see F17).
- The guard core does its one job.
  The ledger holds 73 `armed`, 93 `compacted`, 84 `green` events, and 1,097 `session_start` (re-counted).
  Its freeze is now a lease: `DEFAULT_FREEZE=180` is defined at compaction-guard line 40, read from the binding at lines 944-945, and `hook_pre_tool_use` (function begins line 916) releases a stuck armed or compacting phase after that age, raising `CMP-350` at line 953 (WK-20260920-099, comment at lines 937-942).
  Releases are immutable and gated: `promote` refuses bytes that did not pass `tests/run.sh` (README, "Release discipline", line 34).
- The breadcrumb habit is the best artifact of the layer.
  `git grep -c BREADCRUMB` finds 219 breadcrumbs in 106 files (attempt 1 count); each states what broke, why this fix, what was rejected and the cost.
  Together they are a catalogue of failure causes with file and ticket pointers (examples: `bin/step.sh` lines 27-31, 36-41 and 44-52, `herdr/bin/seat.sh` lines 744-757, `line/bin/merge.sh` lines 289-300).
- The one-file-one-PR rule became code.
  `bin/wo-start.sh` (header, lines 2-10) calls `factory/bin/claims.sh start`; `factory/bin/gate.sh pr-files` fails a diff that strays, but it is not yet wired into any route (gate.sh lines 28-33).
  Origin: five PRs edited one `seat.sh` on 2026-10-12 (AGENTS.md lines 255-265).
- The work-order skill has real internal discipline.
  Closed status set, cycle-refusing dependency graph, `evidence --observed` and `resolve --answer` gates, exit codes 0/2/3/4/5/6, and a 24-case Podman test suite (`/home/luna/.claude/skills/work-order/testing/cases/`).
  The idea is sound; the packaging is the problem (F4).
- skill-sync is careful about its own blast radius.
  Per-directory ownership, a receipt, a 900 s churn guard (`STAMP_MAX_AGE=900`, line 65), a lock with a 20 s wait and 300 s stale age (`LOCK_MAX_AGE=300`, line 78; `LOCK_WAIT`, line 82), three fetch attempts (`FETCH_ATTEMPTS=3`, line 100), and failures end in a loud message and exit 0.
  449 runs in the transcripts show a median of 1,287 ms (attempt 1 scan).
- The startup-text narrowing landed.
  The three `-axi` hooks moved from matcher "" to `startup|resume` on 2026-09-24T03:00Z (`/home/luna/.claude/hooks/SESSIONSTART-MATCHERS.md`) and card C6 confirmed it on 2026-10-12T17:23Z (`/home/luna/.bearings/coq-stable/answers.jsonl`).
  SessionStart:compact hook runs in the transcripts fell to 107 against 3,159 startup runs (attempt 1 scan).
- `.prettierignore` is a correct local fix.
  Its breadcrumb (`.prettierignore` lines 1-8, WO-20261011-616c) records that the global formatter re-indented the owner-locked `report/loop/assets/template.html` from 247 to 1,182 lines on the first edit.

## 5. What broke and why

### 5.1 Where the evidence disagrees with the brief

1. The brief (section 6) says "This is build mode: the old governance is off".
   Nothing makes that true.
   `git grep -i "build mode"` over the repository finds nothing (re-run 2026-10-14T02:56Z), no flag file exists under `/home/luna/.local/state/coq/coq-jev-herdr-plugin/run/`, and the hooks in the tracked `.claude/settings.json` (lines 6-77) and in `/home/luna/.claude/settings.json` are unchanged.
   The only statement of build mode is the architect's private memory file `build-mode-rule.md`, indexed at `MEMORY.md` line 35 (see F1).
   The guard is in fact more active in the rebuild session than before: it was bound to a role at 02:40:22Z and denied the session's own memory write at 02:41:32Z (F17).
2. The brief's framing is that the governance layer "starts fucking with my building" through gates.
   The mechanical gates are few and cheap: 12 guard tool denials in October, no hook errors, 237 fence denials (F9) and the seat bring-up gates (F10).
   The heavier cost is prose: contradictory rules (F2), a ticket skill with single-checkout assumptions (F4), and a payload every seat carries (F6).
   Hooks are the wrong first suspect; the text, the fence and the skill are the right ones.
3. The brief implies the old mechanical enforcement is live.
   The strongest enforcement hooks were removed.
   The backup `settings.json.bak-20260920T235755Z-breakglass` still holds three `PreToolUse` entries: `Agent|TeamCreate` (blocks subagent spawning), `Bash` (blocks `run_in_background`, and runs `no-hand-start.mjs`), and the guard.
   The next backup in time, `settings.json.pre-kimi.20260922T030927Z`, holds no PreToolUse key, and neither does the current file.
   I found no record of why they were removed between those two backups; the reason is unknown.
   The rules survive only as prose (AGENTS.md lines 184-196, `playbooks/worker.md` Forbidden list), so today they are kept by the model, not by the system.
   Example: on 2026-10-13T02:16Z the architect launched research with the Agent tool and the owner objected (memory `owner-page-and-process-rules.md`).
4. Attempt 1 said merge is gated by `coq/gate`.
   It is gated by `review.passed` and `test.passed` records read by `merge.sh` (lines 337-353); `coq/gate` is posted by Jenkins and is not a required check on GitHub (section 3.2).
   Whether the merge ever consults the Jenkins verdict is therefore an open design question for L07, not a fact of today's line.

### 5.2 Findings F1 to F18

**F1. Build mode is a note, not a mechanism.**
The owner's order is in `memory/build-mode-rule.md`: "no gate, hook, guard, lease, watch or status rule from the old line ... runs against rebuild tickets", with "when an old hook or script fires on a rebuild ticket, switch it off for the rebuild and log which rule bit".
That is an agent doing a manual switch-off, which is the pattern the owner rejected the same day ("we need it driven by system, not agent").
It also breaks the owner's own rule that an agent's private memory is never the only home of a rule (`/home/luna/.claude/CLAUDE.md` lines 141-142): the rule lives only in the architect's memory directory and in no repository file.
Update since attempt 1: `MEMORY.md` line 35 now carries a one-line entry for the note, and F7 shows every seat in a treehouse slot loads that index, so a new worker will read "factory governance never applies to the rebuild" with no mechanism behind it and no instruction on what it may skip.
The CLI already has the mechanical switches: `claude --help` on 2.1.296 lists `--bare` (skips hooks, CLAUDE.md auto-discovery, auto-memory, plugin sync), `--setting-sources user,project,local`, `--settings`, `--strict-mcp-config`, `--disable-slash-commands`, `--plugin-dir`.
Not tested here: whether `--setting-sources project` also drops user-level `enabledPlugins` hooks; `--bare` also requires `ANTHROPIC_API_KEY` or `apiKeyHelper` and never reads OAuth, which is a cost and auth decision for the owner.

**F2. The rule stores contradict each other.**

| Topic                           | Rule A                                                                                                      | Rule B                                                                                                                                                                                                          | Effect                                                                                        |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Owner surface for a Claude seat | Global: Getting My Bearings only, lavish prohibited (`/home/luna/.claude/CLAUDE.md` lines 22-35)            | Project: Claude seat uses a claude.ai artifact via `report/rail.sh` (AGENTS.md lines 220-245); `seat.sh` exports `RAIL_SURFACE=artifact` (line 797)                                                             | Two surfaces; the seat picks                                                                  |
| Lavish                          | Global rule forbids it for Claude seats                                                                     | `lavish-axi` runs at every startup and prints "consider using Lavish Editor" (transcript `6fe8d57b`, hook content); `work-order.sh approve` requires it (line 788)                                              | The tooling steers toward what the rule forbids; `SESSIONSTART-MATCHERS.md` already says this |
| Background processes            | AGENTS.md lines 184-196 and dotfiles Rule 18: never `&`, `nohup`, background jobs                           | `bearings` SKILL.md lines 33 and 66 order `run_in_background: true` for the server and the wait; `container-sandbox` SKILL.md line 619 runs `( sleep 1800 && podman stop ) &`                                   | A Claude seat that follows the skill breaks the law                                           |
| Post-merge cleanup              | AGENTS.md line 331 and the work-order skill: `work-order.sh cleanup` checks out main and fast-forwards      | `line/bin/merge.sh` lines 289-300: it never calls `work-order.sh cleanup` because `git checkout main` fails when main is checked out in another worktree (record vn435)                                         | The documented close-out is not the one that runs                                             |
| Runtime data                    | AGENTS.md lines 111-123: nothing runtime in git                                                             | Line 120 admits `event.sh`, `make step` and `backlog.sh` still write into the repository; commits still carry `Changelog: changelog/2026/10/...` entries; the working tree holds untracked `events/2026/10/*.json` | The law is stated and broken in the same section                                              |
| Questions to the owner          | Global lines 125-126: every question is a card, never in a reply                                            | Global lines 194-217: on a merged PR or closed issue "prompt user: This looks like a milestone worth capturing" (line 207)                                                                                       | Seats are told to ask in chat                                                                 |
| Backlog                         | ROADMAP decision C14 and AGENTS.md line 117: backlog lives in GitHub issues                                 | `.claude/scripts/backlog.sh` is tracked, the global capture rule still names `backlog.sh done` (global line 198), and `backlog/now` is untracked in the working tree                                              | Two backlogs                                                                                  |
| Project map                     | AGENTS.md line 77 and `COMPASS.md` line 10: `COMPASS.md` routes in under 100 lines                           | The file is the unfilled template (`<what this project is, in a single sentence>` at line 5, `<path>` rows at lines 15-16) four days in                                                                         | The project's routing document is empty                                                       |

**F3. The Lavish approval gate is ceremony that is always overridden.**
238 of 238 tickets that carry an `approval` record were approved with `via: "override"`; none through Lavish (re-run: `grep` over `work-orders/**/WO-*.md`, 263 tickets, 0 with `via: "lavish"`).
Four reason strings recur, for example "architect: lavish is prohibited for Claude seats" (18) and "architect P0 order 2026-10-13 ... always" (15).
The gate adds one free-text field typed by an LLM and no check.

**F4. The work-order skill assumes one human, one checkout.**

- `start` refuses a dirty tree (work-order.sh line 813) and runs `git checkout -b` in the project directory (line 820), so the line cannot call it in the main checkout.
- `cleanup` runs `git checkout main` (line 969), which fails across worktrees (merge.sh lines 289-300).
- `approve` dirties the tree and `start` then refuses (`references/lifecycle.md` lines 49 and 58); a ticket therefore reaches main in its own "cut" PR before it can start: 7 of the last 246 commits are cut PRs (re-run with `git log --oneline -246 | grep ' - cut '`), for example `c9b6f9f ... cut cause ay ... (#180)`.
- `reindex --check` needs `INDEX.md`, which the project gitignores, so a fresh tree fails: ticket WO-20261013-9040 records a false `test.failed 422`.
- `start` leaves the main checkout dirty: ticket WO-20261013-32bd (cause q).
- The skill copy is gitignored, so `line/bin/start-tickets.sh` line 41 copies `.claude/skills` into each throwaway worktree, and tickets WO-20261012-aac3 and WO-20261012-e36e exist only to make `make aggregates` and case 17 work without it.
- 28 tracked files outside tickets and docs name `work-order.sh` or `skills/work-order` (re-run: `git grep -l` with `:!work-orders :!docs`).
- Starting one ticket costs 4.4 to 8 minutes of belt-serial time in the start logs (`/home/luna/.local/state/coq/coq-jev-herdr-plugin/logs/start-tickets/2026/10/`: files `20261014003651` 4m26s, `20261014002115` 8m00s, `20261014014627` 7m30s, file-name stamp to last write time, re-measured), and 13 `FAIL ... start (claims or status)` lines in the same logs (re-counted).
  I did not time `make lint` separately; the split between lint, push and seat bring-up is unmeasured.

**F5. The governance is pulled from GitHub main at every session start, unpinned.**
`skill-sync` fetches `https://raw.githubusercontent.com/$SRC_REPO/$SRC_REF/claude/skills/registry.json` (line 89, with `SRC_REPO=jkkelley/dotfiles` at line 87 and `SRC_REF=main` at line 88) and replaces its own file from `SELF_URL` (line 90).
`.claude/skills.toml` states that nothing pins a version (its header comment).
The line's scripts depend on the replaced copy: `bin/wo-start.sh` line 9 says the skill is "a managed skill copy (gitignored, replaced on every session start)".
A push to `jkkelley/dotfiles` main changes the behaviour of every seat that starts afterwards.
Measured this pass: local dotfiles is at `7672b3c` (2026-10-10T14:22:47-05:00) while GitHub main is `6159bd8`, a bot commit "chore(skills): allocate versions on main" made 9 seconds after the last feature merge (`gh api repos/jkkelley/dotfiles/commits`, 2026-10-14T02:54Z).
So main moves by CI without a human push, and a seat started after it pulls a registry the local clone has not seen.
Today the installed versions equal the registry's (work-order 2.2.0, living-docs 1.0.2, container-sandbox 1.6.0, context-compaction 2.0.1; `curl` of `registry.json`, 2026-10-14T02:55Z), so no drift is live; the exposure is structural.

**F6. Every seat carries a large fixed payload before it reads its ticket.**
First assistant turn of worker session `6fe8d57b`: 2 input, 31,642 cache-creation, 12,332 cache-read tokens, about 44k tokens.
Of that, in bytes: skill listing 32,566 (80 entries: 39 user, 14 superpowers, 12 figma, 7 design, 7 anthropic-skills, 1 frontend-design), instruction files 21,105 characters, SessionStart hook context about 9.5 KB (superpowers 3,587, gh-axi 2,838, lavish preview 2,312 of an 18,992-byte output, chrome 789).
The lavish output lists 82 "open" sessions whose server is not running (`ss -ltnp` finds nothing on 4387).
Estimate, not measured: 727 `SessionStart:startup` runs in the coq transcripts times about 63 KB at 4 bytes per token is roughly 11 million tokens of preamble in four days, mostly cache reads.
The seat also reads `AGENTS.md` (23 KB) and often `ROADMAP.md` (17 KB) by tool call.

**F7. Worker seats receive the architect's private memory.**
The `instructions` attachment of a worker in a treehouse slot lists `/home/luna/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/memory/MEMORY.md` as AutoMem (6,118 characters; re-confirmed in transcript `6fe8d57b`, attachment type `instructions`, entry type `AutoMem`).
The index carries architect-only rules ("Architect sends specs off", "Clear the architect queue by listed id") into every worker, tester and reviewer.
Because the index is live, every line the architect adds reaches the next seat that starts: it is 7,134 characters now.

**F8. Global PostToolUse hooks rewrite repo files and one is a silent no-op.**

- `npx prettier --write` runs on every Write or Edit of any file but `work-orders/` (user settings.json line 28).
  62 transcript notices read "PostToolUse hook modified <path> ... (likely a formatter)", including `factory/config/routes.json` and `suites.json`.
  `prettier --check` finds 35 of the files I checked not clean, among them `roles/*.json`, `playbooks/*.md`, `ROADMAP.md`, `factory/config/routes.json`.
  A prettier pass over `routes.json` changes 183 lines of a 38-line file, and `suites.json` changes 229 of 279.
  The repo has no `.prettierrc` (`ls .prettierrc*` finds none); only the two locked design paths are in `.prettierignore` (lines 9-10).
  Effect: an Edit that should change one line can rewrite the whole file, which feeds the file-clash problem AGENTS.md lines 255-265 forbids.
- `go test ./...` on a `.go` write (line 32) cannot run: `which go` finds nothing, the repo's Go module is `scheduler/go.mod` not the root, and the hook ends in `|| true`.
  It looks like a gate and is none.

**F9. The seat fence stalls seats and does not cover MCP.**

- 237 unique denied tool calls in 170 of 682 sessions ("Permission to use Bash with command ... has been denied"); the commands are almost all `git status`, `git rev-parse` and `gh` variants.
  Cause: `roles/tester.json` denies `git *` and `gh *`, and the model's habit is to run `git status` first.
  Owner message 2026-10-13T01:00Z: "Each had one git command refused ... took it as no shell at all. One sat 40 minutes asking."
- The fence is a deny list under `bypassPermissions` (`roles/*.json` deny lists rendered by `seat.sh`; `herdr/bin/testpane.sh` header lines 9-10: "a seat runs under bypassPermissions, where an allow rule restricts nothing").
  Cause t shows its leak: `deny.paths` rendered as `Edit` rules only, and PRs 118 and 125 changed `roles/` from worker seats (tickets WO-20261013-d0dd, WO-20261013-2298, WO-20261013-4464).
- User-scope MCP servers `kubernetes-mcp-server`, `github`, `jenkins-mcp`, `notion` in `/home/luna/.claude.json` attach to every Claude session.
  `ps` shows 10 `jenkins-mcp` Podman containers for 16 claude processes, started with `--env-file /home/luna/.claude/.env.jenkins-mcp`.
  No role file mentions `mcp`; MCP servers are reparented to init when a seat dies (seat-lib.sh lines 238-246, cause g).

**F10. compaction-guard was built for an earlier iteration and the coq seats never bind to it.**

- The guard finds a role schema from `COMPACTION_GUARD_SCHEMA`, `GMB_ROLE`/`GMB_ROOT`, `STABLE_ROLE`/`STABLE_ROOT`, or `.claude/compaction-guard.json` (`resolve_schema`, compaction-guard lines 201-221).
  The coq seats set none: `grep` for those names over `herdr roles bin line factory .claude/settings.json` finds nothing, and the project has no `.claude/compaction-guard.json`.
  Result: 897 of 1,104 alerts are `GOV-130 no schema resolved; default threshold 30 applied` (live, 2026-10-14T02:54Z; attempt 1 read 896 of 1,102), and the 400 most recent sessions as of attempt 1 had role "-" and threshold 30.
- Because no role is bound, the guard sends no GOV-100 memo, so `seat.sh` waited the full `nudge_wait_seconds` (180) for an ACK nobody printed: the belt was frozen 180 s per bring-up (ticket WO-20261013-7af7, `seat.sh` lines 744-757); the key is now 15 (`herdr/config/herdr.json` line 13) and capped at 30 in the schema (`herdr/config/herdr.schema.json` lines 92-96).
- 322 `recover_failed` events and 106 critical `RCV-520 recovery failed after 3 tries; a human must run: ...` alerts fall on 2026-10-12, aimed at gmb-era sessions (815 session directories under `~/.local/state/compaction-guard/sessions`; counts re-run for the events and alerts).
- The failure classes the guard and its satellites exist for come from typing `/compact` into an interactive TUI: `send_held` 132 events (re-counted), `CMP-340` (the `/compact` line merging with composer text), the stacked `/compact` prompts in `bin/step.sh` lines 44-52, the trust dialog (`seat.sh` lines 716-727), the nudge (`seat.sh` lines 728-788).
  A headless or one-shot seat has none of these.

**F11. The same governance machinery has been built four times.**
compaction-guard (first install 2026-09-19), `bearings-v2` (September), `dotfiles/claude/workflow` (PR 99, 2026-09-23: compaction, model-chain failover, seat watcher, test-plan gate, `make herdr-first`), and this repository's `herdr/` plus `line/` (from 2026-10-10).
The rule stores multiply the same way: 105 principles in `~/OPINIONS.md`, of which the file itself counts "Live 10, manual 48, designed 41, none 6"; 34 rules in `how-i-work`; 19 in dotfiles; 8 hard rules global; 21 laws project.
`~/projects/how-i-work/README.md` already proposes the cure (rules as data, pinned, rendered, locked rules); no seat consumes it.
`dotfiles/CLAUDE.md` Rule 5 says "Use the model only for judgment calls ... Do NOT use for routing, retries"; that rule is loaded only in dotfiles sessions, not in the global file.

**F12. The owner's tooling-in-repo rule is violated by the governance layer itself.**
The seat's liveness and "done" signal depends on user-level hooks outside the repository (`herdr-agent-state` in `/home/luna/.local/bin`, installed by dotfiles `setup.sh`), and on screen-scraping Claude Code's footer (`herdr/bin/turnwatch.sh` header line 13: "The footer is the signal, not herdr's agent_status").
`.claude/settings.json` hard-codes `/home/luna/.local/bin/compaction-guard` (lines 13, 35, 47, 59, 71, 80).
`chezmoi`, which dotfiles PR 101 makes the owner of the `-axi` matchers, is not installed (`which chezmoi` finds nothing), so that edit is still a hand edit and a re-run of `setup.sh` could revert it (setup.sh lines 37-49, 563-573).

**F13. Polling is a product of the rules.**
Rules "tests only in the labelled test pane, through `testpane.sh`" (worker playbook, Forbidden), "never background" (AGENTS.md lines 184-196) and "all testing in Podman" (container-sandbox lines 15-17) leave the seat one way to run a suite: type it into a pane and watch.
Tester session `e852f31c` on WO-20261014-539a made 14 tool calls; 8 are `sleep 20`, `sleep 30`, `herdr pane read` and `Monitor until ...` loops.
Worker session `6deb36df` on the same ticket: 55 assistant messages, 3.65 million cache-read tokens in 4m18s of wall time.
The owner's diagnosis on 2026-10-13T19:45Z: "Models are bad at waiting, so it polls, forgets or waits on the wrong thing."

**F14. Attribution has three sources and the hard-coded one is wrong.**
`bin/step.sh` line 32 appends `Claude-Session: https://claude.ai/code/session_01694jMaqrg4CVo5zWF3jq6Z` to every step commit.
583 of 595 trailers in the last 400 commits carry that one id (attempt 1 count).
Settings `attribution.commit` is "" (user settings.json line 3, project `.claude/settings.json` line 3) and the global rule says never add the agent as co-author; the harness reminder in some sessions asks for the trailer.
The trailer identifies no session.

**F15. Shared mutable global state is written by seats.**

- `/model` in a seat saved `claude-opus-5-5` as the global default in `/home/luna/.claude/settings.json` (line 17; memory `right-size-agent-models.md`; owner card C30 answered "Keep Opus").
- `seat.sh` `ensure_trust` (line 722) rewrites `/home/luna/.claude.json` (386,852 bytes, 399 project entries, 313 trusted) with `jq ... > tmp && mv`, no lock, while Claude Code writes the same file (risk, not an observed loss).

**F16. The cleanup of rules is manual and lagging.**
`AGENTS.md` grew from 209 lines (2026-10-10) to 365 lines in 7 commits over 3 days, mostly "Owner order" paragraphs; each order also produced a code gate (`gate.sh`, `claims.sh`, `policy.sh`, lint steps).
`lint/lint.sh` now checks 13 properties, among them an em-dash grep and contents-list sync.
The cost model: a chat sentence becomes a Law, a ticket, a gate and a lint step; nothing retires a rule.

**F17. The guard bit the rebuild session within 70 seconds of the owner asking for it.**
Owner order, recorded in memory `compaction-guard-35-for-rebuild.md`: "i have a bunch of auto compaction systems that worked great, ensure its used here at 35%".
The session `e31510a1` was bound by hand to `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/roles/rebuild-architect.json` (compact 35) at 02:40:22Z (`sessions/e31510a1-.../binding.json`, `bound_at`).
At 02:41:32Z the guard logged `tamper_denied` for that session because a Bash heredoc that wrote a memory file contained text naming the guard (events.jsonl; `tamper_check` is active only for role-bound sessions, compaction-guard lines 888-890, and matches the command text against the guard's state and knobs).
The memory file records the lesson itself: "The guard's PreToolUse hook refuses any Bash command whose text names the guard's state, hooks or knobs, even an unrelated memory write; use the Write or Edit tool for such text."
Two points matter for the rebuild.
First, binding is a step an agent performs ("bind it with the guard's bind verb" at the start of every session), which is the manual pattern the owner rejected.
Second, a rule meant to stop an agent disabling the guard also stops legitimate writes, and the denial is a text match, not an intent check; the same match denied three reads in the `fable-discovery` session on 2026-10-10 (events at 20:13:44Z, 20:14:06Z, 21:37:27Z, for example a `cat .claude/settings.json`).

**F18. Two skills and one plugin steer a seat toward a human that an unattended seat does not have.**
`session-workflow` has three mandatory waits for the user (SKILL.md lines 139, 176, 189), the superpowers `session-start` text forbids any response before a skill check, and `brainstorming` forbids code until a human partner approves.
In 682 sessions the first two were never invoked and brainstorming once, by the architect on 2026-10-10T17:43Z, so the damage so far is tokens (F6), not stalls.
The risk is latent: a seat on a new model or a new prompt that does read them has no one to answer.

### 5.3 Which of it would fight a rebuild

Ranked by how directly each blocks a plain branch and PR, or an unattended seat.

| Rank | Item                                                                      | Where it fires                 | Why it fights                                                                                                                                                              | Evidence                                                                                                                                                                                                                                             |
| ---- | ------------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Build mode is not a switch                                                | whole layer                    | Every old rule still applies; switching off is by hand                                                                                                                     | F1                                                                                                                                                                                                                                                   |
| 2    | superpowers HARD-GATE and "invoke a skill before any response"            | SessionStart in every seat     | `brainstorming` forbids code until a "human partner" approves; an unattended seat can stall on it                                                                          | plugin hook text; `/home/luna/.claude/plugins/cache/claude-plugins-official/superpowers/6.3.0/skills/brainstorming/SKILL.md`; in practice 1 of 682 sessions invoked it (the architect, 2026-10-10T17:43Z), so the cost is tokens, the risk is latent |
| 3    | Fence deny list (git, gh for tester; `herdr pane run *`)                  | every Bash call                | 237 denied calls; a refusal read as "no shell"                                                                                                                             | F9                                                                                                                                                                                                                                                   |
| 4    | work-order `approve` Lavish gate, dirty-tree start, checkout-main cleanup | ticket lifecycle               | Two PRs per ticket; failures in worktrees                                                                                                                                  | F3, F4                                                                                                                                                                                                                                               |
| 5    | Global PostToolUse prettier                                               | every Write/Edit               | Whole-file rewrites; conflicts                                                                                                                                             | F8                                                                                                                                                                                                                                                   |
| 6    | compaction-guard PreToolUse freeze (180 s lease) and tamper deny          | every tool call in project cwd | Denies all but reads while armed; a rebuild seat whose command text names the guard or `.claude/settings.json` is refused if role-bound, as the rebuild session was at 02:41:32Z | compaction-guard lines 40, 888-960; F17                                                                                                                                                                                                              |
| 7    | AGENTS.md "ROADMAP binds, work not on it waits"                           | AGENTS.md lines 36-47          | A rebuild is not on the 2026-10-12 roadmap; the rebuild plan pointer says it "stands beside it and does not replace it" (`plans/2026/10/20261014-factory-rebuild-plan.md`)  | file text                                                                                                                                                                                                                                            |
| 8    | herdr-first law and test-pane rule                                        | AGENTS.md lines 184-196        | Rules assume panes; a pod or Job seat has no pane                                                                                                                          | F13                                                                                                                                                                                                                                                  |
| 9    | Session-start network pulls (`skill-sync`, `gh-axi`, `lavish-axi`)        | startup                        | Need network, GitHub and local binaries; absent in a pod; unpinned                                                                                                         | F5                                                                                                                                                                                                                                                   |
| 10   | User-level MCP servers with cluster and Jenkins credentials               | every session                  | Unfenced power in an automated seat                                                                                                                                        | F9                                                                                                                                                                                                                                                   |
| 11   | `session-workflow` and `no-mistakes`, if ever invoked                     | owner phrase or `/no-mistakes` | Three human waits; or a second push, PR and CI loop beside `make step`, `gh pr create` and `coqGate()`                                                                     | section 3.3; zero calls so far                                                                                                                                                                                                                       |

## 6. Waits, polls, sleeps and leases

| Where                                | What it waits on                            | Bound                                                                                                                             |
| ------------------------------------ | ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `settings.json` SessionStart hooks   | lavish-axi, gh-axi, chrome-devtools-axi     | 10 s each; measured medians 1,576 ms, 875 ms, 322 ms (attempt 1)                                                                  |
| `skill-sync --boot`                  | GitHub registry fetch, other sync's lock    | hook 30 s; `curl --max-time 10`, 3 attempts (line 100); lock wait 20 s (line 82); stale lock 300 s (line 78); churn guard 900 s (line 65) |
| herdr-agent-state hooks              | herdr socket                                | 5 s and 10 s; every path exits 0                                                                                                  |
| superpowers session-start hook       | plugin script                               | median 309 ms, max 1,673 ms (attempt 1)                                                                                           |
| compaction-guard hooks               | file writes, jq                             | SessionStart 30, Stop 60, PreCompact 120, PostCompact 60, PreToolUse 10 s (project `.claude/settings.json` lines 14, 36, 48, 60, 72); measured median 114 ms |
| guard freeze lease                   | the armed or compacting phase               | `DEFAULT_FREEZE=180` (compaction-guard line 40), from the schema `thresholds.freeze_seconds` or `COMPACTION_GUARD_FREEZE_SECONDS` (lines 284-288, 944-945); expiry raises `CMP-350` (line 953) |
| guard memo ACK                       | a seat printing `● ACK compaction-guard `   | `nudge_wait_seconds` 15 (was 180; schema cap 30, `herdr.schema.json` lines 92-96), `nudge_settle_seconds` 10 (`herdr/config/herdr.json`) |
| `seat.sh` prompt and start           | a shell prompt, `herdr agent start`         | `prompt_timeout_ms` 15,000; `agent_start_timeout_ms` 30,000; `session_wait_seconds` 10                                            |
| `seat.sh --down`                     | process exit                                | SIGTERM, wait `down_kill_wait_seconds` (2), SIGKILL, `down_kill_tries` (3) rounds                                                 |
| `work-order.sh`                      | file lock                                   | exit 5 on lock timeout                                                                                                            |
| `hydration-prompt` `slot.sh release` | `treehouse return`                          | no wait; asks the pool afterwards (not used by this project's flow)                                                               |
| `make step`                          | `make lint` (Podman), `git push`            | none stated; lint runs twice on failure, the first call silenced and the second printing the failures (`bin/step.sh` line 23)     |
| Tester seat                          | pane output of a test run                   | `sleep 20`, `sleep 30`, `Monitor until ...`; no bound except the Monitor tool's own                                               |
| `bearings` skill                     | `wait.mjs` in the background                | "keep exactly one wait running the whole time the page is up" (SKILL.md line 68); stops after 4 hours without activity (line 80)  |
| container-sandbox preview            | a container                                 | `sleep 1800` in a background subshell (SKILL.md line 619)                                                                         |
| `session-workflow` hand-off          | the owner confirming review and merge       | no bound; "Wait for the user" at SKILL.md lines 176 and 189                                                                       |
| `no-mistakes` CI step                | CI checks on the PR it opened               | `ci_timeout: "4h"` in `~/.no-mistakes/config.yaml`; not used in this repo                                                         |
| `execution-rail` gate steps          | the owner's approval signal (default GOTEAM) | none; the page says the plan is waiting (SKILL.md lines 16-19)                                                                    |
| Break glass                          | owner-authorised one command                | ttl in the state file; an expired break glass keeps denying until restored (`break-glass-guard.sh` header line 19)                |
| Exemptions                           | a card-backed lift of one rule for one seat | `until` UTC in `herdr/config/exemptions.json`; currently one entry, `seat.audit` for `wD3:p2` until 2026-10-17T00:00Z             |

## 7. Decisions an LLM makes that a rule could make

| Decision                                       | Where                                                                            | Rule that would replace it                                                                                                                     |
| ---------------------------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Which skills apply to this task                | superpowers hook (1 percent rule), 80-entry listing                              | The seat's settings name the skills; `--disable-slash-commands` and no plugin in seat sessions                                                 |
| Whether to run brainstorming before building   | superpowers `using-superpowers`                                                  | A ticket with approved scope is the approval; remove the plugin from seats                                                                     |
| Whether a denied command means "no shell"      | tester sessions after `git status`                                               | Allow read-only git and `gh pr view` / `gh pr diff` in the role, or answer from the brief                                                      |
| When a test run has finished                   | tester sleeps, pane reads, `Monitor until`                                       | Run the suite as a Job and read one status; the Jenkins `coq/gate` check already exists                                                        |
| The order of the eight close-out commands      | `playbooks/worker.md` step 6                                                     | One `make close-out` that runs evidence, note, commit, push, PR, submit, done in order                                                         |
| What an `--observed` string says               | `work-order.sh evidence`                                                         | Point at the test output id; the gate checks the id, not prose                                                                                 |
| Whether to approve a ticket                    | architect, 238 overrides                                                         | `approve` becomes a validator on fields (files, AC, test plan), no human text                                                                  |
| Whether the compaction checkpoint is right     | seat-authored `checkpoint.sh new` body, "restated in full"                       | The guard already builds a checkpoint from git status, prompts and last message (`checkpoint_build`, compaction-guard line 483); use only that |
| When to compact                                | `make step --compact` and `/compact` typed by `step.sh`, `AGENTS.md` golden rule | One-shot seats per ticket never reach a threshold; the guard keeps the interactive case                                                        |
| Whether to prompt the owner at a milestone     | global lines 194-217                                                             | A script on the merged record, or nothing                                                                                                      |
| Which surface to use for the owner             | bearings vs lavish vs artifact                                                   | `RAIL_SURFACE` set by the spawner, already coded in `seat.sh` line 797; delete the competing prose                                             |
| Whether a hook's output is rule or noise       | lavish and gh-axi preambles                                                      | No such hooks in seat settings                                                                                                                 |
| Whether a rebuild ticket is exempt from a rule | build-mode note                                                                  | A flag read by the gates, set by the plan, logged by the system                                                                                |
| Whether to bind a session to a guard role      | an agent runs the guard's bind verb (memory `compaction-guard-35-for-rebuild.md`) | The launcher exports `COMPACTION_GUARD_SCHEMA` from the role JSON; `resolve_schema` already reads it first (compaction-guard line 203)         |
| Whether to run a session ritual (session-workflow, no-mistakes) | the model reading a skill description                           | The seat's settings name the only skills it may use; the push and PR steps are `make step` and `gh pr create` from the playbook                 |

## 8. What to carry forward

- Render seat governance from role JSON into a per-seat settings file and compare it with `cmp` (`herdr/bin/seat.sh` lines 129-139, 314).
  Why: one deterministic carrier that lives in the repository and is checkable; drift is a failing `--check`, not a surprise (section 4).
- Generate playbooks from role schemas and lint the generated text; keep the one-line brief (`roles/bin/brief.sh`).
  Why: rules and prompts have one source, and a 62-line playbook plus one line is a cheap seat start (section 4).
- The breadcrumb comment standard and the 219 existing breadcrumbs as the seed of the failure catalogue for the rebuild's design review.
  Why: each names the file and line that broke, the effect, the fix, the rejected alternative and the cost, so this investigation traced causes in `bin/step.sh` lines 27-52, `seat.sh` lines 744-757 and `merge.sh` lines 289-300 without reading a transcript; it is also the owner's global rule (`/home/luna/.claude/CLAUDE.md`, "leave the breadcrumb at the fix site"), so dropping it would break a stated order.
  Cost: long comment blocks (20 of the 28 lines of `bin/step.sh` lines 25-52 are comment).
- The claims check as a CI gate (`factory/bin/claims.sh`, `gate.sh pr-files`).
  Why: it turned a chat order into a failing check; carry it and wire it into a route, because today nothing calls `pr-files` (gate.sh lines 28-33).
- The work-order concepts: closed status set, dependency graph with cycle refusal, `Degrees of freedom` section, `evidence --observed`, test-plan block, exit-code contract.
  Why: sound; re-home them off bash, off gitignored vendoring and off the single-checkout assumptions (F4).
- The guard's design pieces: immutable releases promoted on a test hash, rollback as break glass, status-code table `docs/status-codes.md`, append-only event and alert ledgers, the freeze as a lease.
  Why: they are good practice and have run for 25 days with zero hook errors; the TUI-specific parts are not needed for one-shot seats (F10).
- Rules as data, pinned and rendered (`/home/luna/projects/how-i-work`): `rules.json` plus schema, locked rules, a pinned tag, rendered Markdown.
  Why: the owner has already designed the cure for F2 and F11, and it is the only candidate that makes the global and project files one source.
- Exemptions with an expiry and a card id (`herdr/config/exemptions.json`): the shape of a build-mode switch.
  Why: it is already a system-read, time-bound, card-backed lift of one rule for one seat, which is exactly what F1 lacks.
- Mechanical Claude Code switches for a clean seat: `--settings`, `--setting-sources`, `--strict-mcp-config`, `--disable-slash-commands`, `--bare` (local `claude --help`, 2.1.296, 2026-10-14).
  Why: `seat.sh` already passes `--settings` in its flag array (line 809), so the rest are one-line additions that make "which layers a seat loads" a property of the launch command rather than an agent's judgement (F1, F6, F7, F9); `--bare` needs an API key, which is the owner's call (question 1).
- The `.prettierignore` practice, extended to a repo `.prettierrc` that matches the committed files.
  Why: its breadcrumb records a formatter turning a 247-line locked file into 1,182 lines (`.prettierignore` lines 1-8), and F8 measured the same effect on `routes.json` and `suites.json`; a repo-owned formatter config makes the rule travel with the repository instead of living in the owner's global hook.

## 9. What to kill

- `lavish-axi`, `gh-axi`, `chrome-devtools-axi` SessionStart hooks for seat sessions.
  Why: the output steers against the owner's rule, costs about 6 KB of context per seat and lists 82 stale sessions (F6; user settings lines 38-67).
- The superpowers plugin and the 80-entry skill listing in seat sessions; a seat needs the skills its role names.
  Why: 32,566 bytes of listing plus 3,587 bytes of hook text per seat, and a hard gate that waits for a human (F6, F18).
- The AutoMem leak: stop loading the architect's `MEMORY.md` into slot sessions.
  Why: it hands architect-only rules, and now the unenforced build-mode line, to every worker, tester and reviewer (F7, F1).
- The global `PostToolUse` prettier hook for seats, and the `go test` hook.
  Why: prettier rewrites whole files (183 of 38 lines changed in `routes.json`) and the `go test` hook cannot run and ends in `|| true`, so it reports safety it does not give (F8).
  Replace with a CI formatting check and a repo formatter config.
- The Lavish clause in `work-order.sh approve` (lines 782-790).
  Why: 238 of 238 approvals were overrides and the clause adds a free-text field with no check (F3).
- The hard-coded `Claude-Session` trailer in `bin/step.sh` line 32.
  Why: 583 of 595 recent trailers carry one id that names no real session (F14).
- The `Capture Milestones` block in the global file for automated seats (global lines 194-217).
  Why: it tells a seat to prompt the owner in chat, against the cards rule at global lines 125-126 (F2).
- Dead enforcement files `~/.claude/hooks/no-hand-start.mjs` and `shell-lex.mjs` unless re-wired in repo-owned settings.
  Why: 784 lines that no current settings file references, so a reader assumes a gate exists where none does; the backup `settings.json.bak-20260920T235755Z-breakglass` shows they once ran on every Bash call and the removal is unrecorded (section 5.1, point 3).
- The `bearings` skill's `run_in_background` steps for Claude seats, and the `sleep 1800 &` preview recipe.
  Why: they contradict AGENTS.md lines 184-196, so a seat that obeys the skill breaks the law (F2).
- Role denial of `git *` and `gh *` for tester and reviewer where the denied commands are read-only.
  Why: 237 denied calls in 170 sessions, one seat idle for 40 minutes after a `git status` refusal (F9).
- The unfilled `COMPASS.md` template or fill it.
  Why: the file is a 41-line template with placeholders at lines 5 and 15-16, so an agent that opens it first learns nothing and AGENTS.md line 77 promises it stays a short map.
- The duplicate rule stores: pick one source (`how-i-work` style) and render the rest from it.
  Why: eight global hard rules, 21 project laws, 34 `how-i-work` rules, 19 dotfiles rules and 105 principles overlap and contradict (F2, F11), and nothing retires a rule (F16).
- The compaction-guard bindings to gmb and stable sessions.
  Why: 815 session directories and 322 failed recoveries on one day came from sessions that no longer exist (F10).
- The stale close-out text in AGENTS.md line 331 (`work-order.sh cleanup`), which `merge.sh` has replaced.
  Why: the documented close-out is not the one that runs, so a seat that follows the text hits the `git checkout main` failure (F2, F4).
- The `session-workflow` and `no-mistakes` skills from seat sessions (keep them for the owner's interactive use).
  Why: neither is used by the line (zero calls in 682 sessions, no reference in the repository), each adds listing bytes, and each would put a human wait or a second push-and-PR loop in front of an unattended seat (section 3.3, F18).

## 10. Open questions for the owner

1. Does the rebuild seat run with a repository-owned governance layer only (no user hooks, no user skills, no AutoMem, no user MCP servers, via `--setting-sources`/`--bare`/`--strict-mcp-config`), or does it keep the user layer?
   Why it changes the design: it decides whether F5 to F9 are fixed by deleting hooks or by never loading them, and whether `--bare` forces an API key in place of the current login.
2. Which owner surface binds a Claude seat: the bearings page only (global file), or an artifact via the rail (project file)?
   Why it changes the design: three artifacts (hooks, work-order approve, rail) are built around the answer.
3. Is the work-order skill the ticket system of record in the rebuild, or GitHub issues (decision C14, 2026-10-12)?
   Why it changes the design: F4 is a packaging problem if the tickets stay, and disappears if they move.

## 11. Sources

Local files read (all on this machine, read 2026-10-14 UTC between 02:30Z and 03:05Z):

- `/home/luna/.claude/CLAUDE.md` (symlink to `/home/luna/AGENTS.md`), lines 1-217.
- `/home/luna/projects/coq-jev-herdr-plugin/AGENTS.md`, lines 1-365; `CLAUDE.md`; `ROADMAP.md` lines 1-70; `COMPASS.md`; `Makefile`; `lint/lint.sh`; `.gitignore`; `.prettierignore`; `Jenkinsfile`; `.claude/settings.json`; `.claude/settings.local.json`; `.claude/skills.toml`; `.claude/scripts/`; `report/rail.sh`; `report/rail/bin/`.
- `/home/luna/.claude/settings.json`, `settings.local.json`, backups `settings.json.bak-20260920T235755Z-breakglass`, `settings.json.pre-kimi.20260922T030927Z`, `settings.json.20260924T0300Z.bak`; `/home/luna/.claude/hooks/SESSIONSTART-MATCHERS.md`, `no-hand-start.mjs`, `herdr-agent-state.sh`.
- `/home/luna/.claude/plugins/cache/claude-plugins-official/superpowers/6.3.0/hooks/hooks.json`; the cache directories of the github, context7, frontend-design and figma plugins (searched for a hooks file).
- `/home/luna/.claude/skills/{work-order,hydration-prompt,session-workflow,no-mistakes,container-sandbox,context-compaction,living-docs,project-scaffold,bearings,execution-rail}/SKILL.md`; `work-order/scripts/work-order.sh`; `work-order/references/lifecycle.md`.
- `/home/luna/.no-mistakes/config.yaml`, `/home/luna/.no-mistakes/repos/*.git` (config, hooks directory), `no-mistakes --help` and `--version` (v1.75.2).
- `/home/luna/.local/bin/skill-sync` (v2.1.0), `herdr-agent-state`.
- `/home/luna/projects/compaction-guard/{README.md,bin/compaction-guard,docs/status-codes.md}`; ledgers `/home/luna/.local/state/compaction-guard/{events.jsonl,alerts.jsonl}` and `sessions/e31510a1-4a15-4377-9c1c-8f1088f67bed/binding.json`.
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/roles/rebuild-architect.json`.
- `/home/luna/projects/coq-jev-herdr-plugin/{bin/step.sh,bin/wo-start.sh,line/bin/start-tickets.sh,line/bin/merge.sh,line/bin/board.sh,herdr/bin/seat.sh,herdr/bin/seat-lib.sh,herdr/bin/resume-checkpoint.sh,herdr/bin/turnwatch.sh,herdr/bin/testpane.sh,herdr/bin/break-glass-guard.sh,herdr/bin/break-glass-lib.sh,herdr/config/herdr.json,herdr/config/herdr.schema.json,herdr/config/exemptions.json,factory/bin/{gate,policy,flow}.sh,factory/config/routes.json,roles/*.json,playbooks/worker.md,roles/bin/brief.sh}`.
- Tickets under `work-orders/WO-20261013-16f1/` (32bd, 9040, 4dc2, 7af7 via seat.sh, d0dd, 2298, 4464) and `work-orders/**` approval records (238 overrides).
- `/home/luna/dotfiles/{CLAUDE.md,setup.sh,claude/workflow/Makefile,claude/workflow/config/project.json}` and git log; `/home/luna/projects/how-i-work/{README.md,rules.json}`; `/home/luna/projects/stable/principles/OPINIONS.md`.
- Transcripts under `/home/luna/.claude/projects/*coq-jev-herdr-plugin*/` (682 sessions), in particular `-home-luna--treehouse-coq-jev-herdr-plugin-f314e6-6-coq-jev-herdr-plugin/{6fe8d57b-81d4-49cc-82d7-b91f580e68b5,6deb36df-2af6-4d49-b5da-c27e2d6c4059,e852f31c-decb-4ad0-8798-1ab7c54ae3ed}.jsonl` and the architect session `-home-luna-projects-coq-jev-herdr-plugin/e31510a1-4a15-4377-9c1c-8f1088f67bed.jsonl`.
- Owner page `/home/luna/.bearings/coq-stable/{messages,answers}.jsonl`; memory files `build-mode-rule.md`, `compaction-guard-35-for-rebuild.md`, `MEMORY.md`, `owner-page-and-process-rules.md`, `right-size-agent-models.md`, `checkpoint-discipline.md`, `one-file-one-in-flight-ticket.md`.
- Plans `/home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/{20261012222000-retro-architect-flood-and-halt.md,20261014-factory-rebuild-plan.md}`; start logs `/home/luna/.local/state/coq/coq-jev-herdr-plugin/logs/start-tickets/2026/10/`.
- `claude --help`, Claude Code 2.1.296, run 2026-10-14 (flags `--bare`, `--setting-sources`, `--settings`, `--strict-mcp-config`, `--disable-slash-commands`).
- Live process table (`ps`) and `ss -ltnp` at 2026-10-14T02:40Z for MCP containers and the lavish port.

Web and network reads, all read-only, all 2026-10-14:

- `gh api repos/jkkelley/dotfiles/commits?per_page=8`, 02:54Z: main is `6159bd8` (2026-10-10T19:22:56Z), above `7672b3c`.
- `https://raw.githubusercontent.com/jkkelley/dotfiles/main/claude/skills/registry.json`, 02:55Z: work-order 2.2.0, living-docs 1.0.2, container-sandbox 1.6.0, context-compaction 2.0.1.
- `gh api repos/jkkelley/coq-jev-herdr-plugin/branches/main/protection` and `.../hooks`, 02:55Z: no required checks, no required reviews, linear history on, no webhooks.

Verification log of attempt 2 (what I re-ran, so the reader knows which counts are fresh):

- Every `file:line` cited for `bin/step.sh`, `bin/wo-start.sh`, `line/bin/start-tickets.sh`, `line/bin/merge.sh`, `herdr/bin/seat.sh`, `herdr/bin/seat-lib.sh`, `work-order.sh`, `skill-sync`, `compaction-guard`, both `settings.json` files, `AGENTS.md`, the global `CLAUDE.md`, `COMPASS.md` and `setup.sh` was re-read with `sed -n` against the file.
  Corrections made: step.sh lint is line 23 (24 is the changelog args line), start-tickets copy is line 41, the "gitignored, replaced" text in wo-start.sh is line 9, DEFAULT_FREEZE is line 40, `resolve_schema` ends at line 221, the user `settings.json` hook entries start one line earlier than attempt 1 said, the post-merge text in AGENTS.md is line 331, and the `step.sh` breadcrumbs are at lines 27-31, 36-41 and 44-52, not 33-45.
  Attempt 1 also named a `gate.sh pr-fence` verb that does not exist and said `merge.sh` keys on `coq/gate`, which it does not; both are corrected above.
- Re-counted: `tamper_denied` 43 (39 in 2026-09, 4 in 2026-10); `tool_denied` 26 (14 and 12); `build-mode-rule.md` 1,378 bytes; `GOV-130` 897 of 1,104 alerts; `RCV-520` 106; 682 transcript files with 0 containing `hook_blocking_error`; 263 tickets, 238 `via: "override"`, 0 `via: "lavish"`; 28 tracked files naming the work-order skill; 7 cut PRs in the last 246 commits; 13 `FAIL ... start` lines and the three start-log durations; AGENTS.md 21 sections and 25 GOOD or NEVER lines; 17 skill directories.
- Not re-run, carried from attempt 1: the stop-hook and skill-sync timing medians, the 62 formatter notices, the 237 fence denials, the token estimates in F6, the 219 breadcrumbs in 106 files, the 583 of 595 trailers, and the prettier diff sizes.
- Not done: did not read the contents of the `6159bd8` commit (a fetch would write to `~/dotfiles/.git`), did not time `make lint`, and did not test `--setting-sources` or `--bare` in a seat.
