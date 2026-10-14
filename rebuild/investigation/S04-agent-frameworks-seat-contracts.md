# S04 - Agent orchestration frameworks and seat contracts

Investigated 2026-10-14T02:50Z (UTC) by the S04 investigator, step R-01.
Read-only: nothing in the main checkout, on the cluster, in any pane or in any repo was changed.
The only writes are this file and the clones listed in section 3 under `clones/`.
No agent, framework or API was run against a real task; every claim is from source, a spec or a vendor document, each dated.

## 1. Contents

1. Contents
2. What it is
3. Where it lives
4. What works
5. What broke and why
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

Every agent product in this area reduces to the same shape: a bounded, single-task worker process that takes one prompt plus a workspace, runs a tool loop, and ends in a machine-readable result.
That shape is what this file calls a seat contract: input, output, evidence, limits, and terminal states.
The owner's current seat is the opposite shape: an interactive Claude Code TUI in a herdr pane, started by `herdr/bin/seat.sh`, given its brief as a typed prompt, and expected to report by calling `events/bin/event.sh` itself.
Verdict in one line: the field's workers are headless processes whose result, cost, turn count and stop reason are returned by the harness and not by the model, and Claude Code itself already ships every piece needed to run the owner's seats that way (`claude -p`, `--json-schema`, `--max-budget-usd`, `--max-turns`, `--bare`, `--bg`, hooks, and the Agent SDK), so the seat contract can be enforced by the system and not by the agent.
The evidence disagrees with one part of the brief's framing: "we're using herdr wrong" is half right.
herdr is not the problem as a pane host; the problem is that the seat inside the pane is a conversational TUI, which forces a trust dialog, an ACK-memo nudge and a typed brief, none of which exist in a headless worker (section 5).
None of the frameworks surveyed is a fleet scheduler either; they are worker harnesses, and the scheduling layer is a separate job (see S01, S02, S03).

## 3. Where it lives

Clones made 2026-10-14 under `~/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/` (shallow, treated as data):

- `claude-agent-sdk-python` HEAD f33ec2b1e31abf9d6a285eb286e13336f283a00e, committed 2026-10-13, `pyproject.toml` line 7 version 0.2.165, bundled CLI 2.1.294 (`CHANGELOG.md` lines 3-6).
- `claude-agent-sdk-typescript` HEAD 85d8f8e0772199ec7965a0c2e874ac88343f2a01, committed 2026-10-09.
- `claude-code-action` HEAD 1d6de8cb0c237e7c15e9e1bdf973826ebae490cc, committed 2026-10-09.
- `langgraph` HEAD a6731f436700c7d46a9224ccd3a0e0ce3a5bfdb5, committed 2026-10-13, `libs/langgraph/pyproject.toml` line 7 version 1.2.15.
- `OpenHands` (github.com/All-Hands-AI/OpenHands, now github.com/OpenHands/OpenHands) HEAD 0e9ce191390f535347ff17055038c45eeef3fedf, committed 2026-10-13.
- `software-agent-sdk` (github.com/OpenHands/software-agent-sdk) HEAD 6e7a8532ef4426da08b5c06dd57cf4795303be01, committed 2026-10-14.
- `SWE-agent` HEAD 3ea751c087f32b16e039a2233dd6eefecef325d5, committed 2026-07-16.
- `mini-swe-agent` HEAD 04d809ceab9df28f9adaed044884180159172930, committed 2026-09-03.
- `aider` HEAD 5dc9490bb35f9729ef2c95d00a19ccd30c26339c, committed 2026-05-22, `aider/__init__.py` line 3 version 0.86.3.dev.
- `codex` (github.com/openai/codex) HEAD 1b6e0d8145e1fe5b2663d32fbe7ee02f51a10e1c, committed 2026-10-14.
- `devin-openapi/v3-openapi.json`, downloaded from https://docs.devin.ai/v3-openapi.json on 2026-10-14 (title "Devin API v3", version 3.0.0).

Installed on this machine, from the shell (read-only `--version`/`--help` only): Claude Code 2.1.296 and codex-cli 0.156.1.
`claude --help` on this machine lists `--bg`, `--bare`, `--json-schema`, `--max-budget-usd`, `--permission-prompts`, `--fallback-model`, `--worktree`, `--session-id`, `--no-session-persistence`; it does not list `--max-turns`, which the CLI reference says `claude --help` may omit (https://code.claude.com/docs/en/cli-reference, fetched 2026-10-14).

Owner-side comparison points (main checkout `~/projects/coq-jev-herdr-plugin`, HEAD 5ad1996de26bfd872a38c14d54bbb0f6d73f746b):

- `herdr/bin/seat.sh` (848 lines), `roles/*.json` plus `roles/schema/role.schema.json`, `roles/bin/brief.sh`, `specs/SPEC-03-dag-and-node-contract.xml`.

## 4. What works

### 4.1 The seat contract in each system

All rows fetched or read 2026-10-14.

| System | Input | Output | Evidence returned | Limits | Terminal states |
| - | - | - | - | - | - |
| Owner today (herdr seat) | Brief typed into a TUI pane by `herdr agent prompt` (`herdr/bin/seat.sh` line 843), role JSON | Whatever the agent chooses to post via `events/bin/event.sh` (`roles/worker.json` `records`: work.started, pr.opened, test.failed, blocked) | Agent-written record, PR comment | Prose rules only: "at most 3 attempts" in `must`; no turn, budget or wall-clock field in `roles/schema/role.schema.json` (property list checked 2026-10-14) | None from the harness; the line infers from records and pane idle reads |
| Claude Code `claude -p` | Prompt arg or stdin (10MB cap), `--append-system-prompt`, `--settings`, `--mcp-config`, `--agents` | `text`, `json` or `stream-json`; `--json-schema` puts a validated object in `structured_output` | `session_id`, `total_cost_usd`, per-model usage, `permission_denials`, `terminal_reason`, `num_turns` | `--max-turns`, `--max-budget-usd`, `--permission-mode`, `--permission-prompts none`, `--tools`, `--fallback-model` | Exit 0 success, non-zero on failure, 143 on SIGTERM (https://code.claude.com/docs/en/headless and /cli-reference) |
| Claude Agent SDK | `query(prompt, options)`, `ClaudeAgentOptions` (`src/claude_agent_sdk/types.py` line 2326) | Stream of messages ending in one `ResultMessage` (line 1695) | `subtype`, `is_error`, `total_cost_usd`, `usage`, `model_usage`, `structured_output`, `terminal_reason`, `permission_denials`, `api_error_status` (lines 1695-1725) | `max_turns` (2405), `max_budget_usd` (2411), `task_budget` (2785), `output_format` (2742), `can_use_tool` (2513), `hooks` (2531), `sandbox` (2686), `session_store` (2758) | `success`, `error_max_turns`, `error_max_budget_usd`, `error_during_execution`, `error_max_structured_output_retries` (https://code.claude.com/docs/en/agent-sdk/agent-loop) |
| Claude Code `--bg` and `claude agents` | Prompt as positional arg | A background session the supervisor owns; transcript on disk | `claude agents --json`: `state` working, blocked, done, failed, stopped; `status` busy, waiting, idle; `waitingFor`; `sessionId` | Supervisor stops idle unattached processes after about an hour; quota is shared with interactive use | state enum above (https://code.claude.com/docs/en/agent-view) |
| Claude Code self-hosted environments | A cloud session from claude.ai, `claude --cloud`, `--environment ccpool_...`, or a routine | Session runs on the owner's runner; repo cloned by runner | Event stream to api.anthropic.com | Runner lease about 60 s without poll, requeue within minutes; capacity per runner; Team and Enterprise plans only, public beta | Session lifecycle documented at https://code.claude.com/docs/en/self-hosted-environments |
| Claude Managed Agents | Agent plus Environment plus Session, events over SSE | Streamed events, history stored server-side | Event history fetchable in full | Beta header `managed-agents-2026-04-01`; no ZDR or HIPAA; self-hosted sandboxes possible | Not a PR-shaped worker; see section 9 (https://platform.claude.com/docs/en/managed-agents/overview) |
| OpenAI `codex exec` | Prompt arg or stdin | Final message on stdout; `--json` JSONL events `thread.started`, `turn.started`, `turn.completed`, `turn.failed`, `item.*`, `error` | `--output-last-message <path>`, `--output-schema <file>` | `--sandbox read-only` (default), `workspace-write`, `danger-full-access`; `--ephemeral` | `turn.completed` or `turn.failed`; resume with `codex exec resume <SESSION_ID>` (https://learn.chatgpt.com/docs/non-interactive-mode) |
| Codex cloud | Task against a published environment | Reviewable diff, then PR on request | Task view, changed files | Per-environment network policy; docs page does not state task time limits | Not documented on the page read (https://learn.chatgpt.com/docs/cloud) |
| Google Jules API (alpha) | `POST /v1alpha/sessions` with `prompt`, `sourceContext.githubRepoContext.startingBranch`, `requirePlanApproval`, `automationMode` | Activities stream (`planGenerated`, `planApproved`, `progressUpdated`, `sessionCompleted`); `pullRequest` output (url, title, description) | Activities list | Max 3 API keys; alpha, "experimental" (https://developers.google.com/jules/api, https://developers.google.com/jules/api/reference/rest) | Session states not defined on the pages read |
| GitHub Copilot cloud agent | Assign `copilot-swe-agent[bot]` with an `agent_assignment` object (`target_repo`, `base_branch`, `custom_instructions`, `custom_agent`, `model`), or `gh agent-task create` | One PR per task | `GET /agents/repos/OWNER/REPO/tasks/TASK-ID` | One branch at a time, "maximum execution time of 59 minutes" that "cannot be extended or bypassed"; user-to-server tokens only; public preview | `queued`, `in_progress`, `completed`, `failed`, `idle`, `waiting_for_user`, `timed_out`, `cancelled` (https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-via-the-api, https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent) |
| Devin API v3 | `POST /v3/organizations/{org_id}/sessions`: `prompt` (required), `playbook_id`, `repos`, `max_acu_limit`, `structured_output_schema` (Draft 7, max 64KB), `structured_output_required` (default true), `resumable`, `platform` (including your own machines via an outpost pool), `secret_ids`, `tags`, `bypass_approval` | Session object with `pull_requests`, `structured_output` | `acus_consumed`, `status_detail`, parent and child session ids | `max_acu_limit`, suspension reasons including `usage_limit_exceeded`, `total_session_limit_exceeded` | `status`: new, claimed, running, exit, error, suspended, resuming (`clones/devin-openapi/v3-openapi.json`, schemas for session create and get) |
| LangGraph | A graph plus state plus `thread_id` checkpointer | Final state or streamed updates; `GraphOutput` | Checkpoints per step; `interrupt()` payloads | `RetryPolicy` (`libs/langgraph/langgraph/types.py` line 427: `max_attempts=3`, exponential backoff, jitter), `TimeoutPolicy` (`run_timeout` hard cap, `idle_timeout`, `refresh_on`), `recursion_limit` (`pregel/main.py` lines 3096-3098), `Durability` `sync`/`async`/`exit` (`types.py` line 98) | Completion, `GraphRecursionError` (`errors.py` line 68), interrupted-then-resumed with `Command(resume=...)` (`types.py` line 833) |
| OpenHands (software-agent-sdk) | Conversation via REST/WebSocket on the Agent Server | Event stream persisted to local filesystem | `ConversationExecutionStatus`: idle, running, paused, waiting_for_confirmation, finished, error, stuck, deleting (`openhands-sdk/openhands/sdk/conversation/state.py` lines 48-60) | `max_iteration_per_run=500` (`conversation/conversation.py` line 75), stuck detector (five loop patterns, `conversation/stuck_detector.py` lines 24-33), conversation lease TTL 45 s (`agent_server/conversation_lease.py` line 18) | `finished`, `error`, `stuck` are terminal (`state.py` lines 62-78) |
| mini-swe-agent (successor to SWE-agent) | Task string, one config yaml | Trajectory json with `exit_status` and `submission` | `info.model_stats.instance_cost`, `api_calls` (`src/minisweagent/agents/default.py` lines 160-180) | `step_limit`, `cost_limit` (default 3.0), `wall_time_limit_seconds`, `max_consecutive_format_errors` 3 (lines 26-35) | `Submitted` via the literal first line `COMPLETE_TASK_AND_SUBMIT_FINAL_OUTPUT` (`environments/local.py` line 48), `LimitsExceeded`, `TimeExceeded`, `RepeatedFormatError` |
| Aider | `--message` / `--message-file`, `--test-cmd`, `--lint-cmd` | Git commits (`--auto-commits` default True, `aider/args.py` lines 439-442) | The git history | No budget or turn flags found in `args.py`; one process | Exits after `--message` is processed (`args.py` lines 636-643) |

### 4.2 Things the field has that work and are directly relevant

- The result is returned by the harness, not written by the model.
  `ResultMessage` carries `subtype`, `is_error`, cost, turns and `terminal_reason` (`clones/claude-agent-sdk-python/src/claude_agent_sdk/types.py` lines 1695-1725), and `claude -p --output-format json` carries the same fields (https://code.claude.com/docs/en/headless, fetched 2026-10-14).
  Devin and the Agent SDK both make the structured output mandatory-or-error: Devin `structured_output_required` defaults to true (`clones/devin-openapi/v3-openapi.json` line 39074), and the SDK returns `error_max_structured_output_retries` when validation never passes (https://code.claude.com/docs/en/agent-sdk/structured-outputs).
  The owner's SPEC-03 already says the same thing in principle: "Output: exactly one record" validated by `events/bin/event.sh` (`specs/SPEC-03-dag-and-node-contract.xml` section s-node), so the schema idea is validated and only the enforcement point is different.
- Limits are fields on the contract and are enforced by the harness.
  Claude Code: `--max-budget-usd` stops the run and also stops background subagents (https://code.claude.com/docs/en/cli-reference); the SDK adds `task_budget` so the model sees remaining tokens (`types.py` line 2785).
  Devin: `max_acu_limit` on create.
  mini-swe-agent: step, cost and wall-clock limits are checked before every model call (`agents/default.py` lines 130-146).
  LangGraph: `TimeoutPolicy.run_timeout` is "never refreshed by progress signals" and `idle_timeout` is a separate progress watchdog (`langgraph/types.py` lines 449-480).
  The Agent SDK hosting guide states the gap plainly: "No top-level session timeout" and "No per-subagent wall-clock deadline", so even Anthropic's SDK needs an external deadline from the caller (https://code.claude.com/docs/en/agent-sdk/hosting, fetched 2026-10-14).
- Unattended means no prompts, by flag.
  `--permission-prompts none` denies anything that would prompt and tells the model not to retry (https://code.claude.com/docs/en/headless "Turn off permission prompts in unattended runs"); `--permission-mode dontAsk` is the locked-down variant; `--bare` skips hooks, skills, plugins, MCP, auto memory and CLAUDE.md (same page).
  The trust dialog the owner's seat had to work around does not exist under `-p`: "A `-p` session shows no workspace trust dialog and no per-server approval prompt" (same page).
- Idle and liveness are states the harness reports, not things the line scrapes.
  `claude agents --json` returns `state`, `status` and `waitingFor`, and the docs say to prefer it over reading `~/.claude/jobs/` (https://code.claude.com/docs/en/agent-view).
  The installed 2.1.296 has `~/.claude/jobs/` populated on this machine (listing of directory names only), so the supervisor is already running here.
  OpenHands reports `stuck` as a terminal state from a detector over the event history (`stuck_detector.py` lines 24-33).
  Copilot and Devin both report `waiting_for_user` as a first-class status (cloud-agent API page; `v3-openapi.json` `status_detail`).
- Leases are first class and use TTL plus a liveness probe.
  OpenHands `conversation_lease.py`: file lease, `DEFAULT_LEASE_TTL_SECONDS = 45.0`, a generation counter, `takeover` on expiry, and an `_is_pid_alive` probe that "conservatively" reports alive when it cannot tell, "so we never steal a lease that might still be in use" (lines 18, 26, 36-60).
  Claude Code self-hosted runners: the poll refreshes the lease and doubles as the heartbeat, lapse after about 60 s, requeue within minutes (https://code.claude.com/docs/en/self-hosted-environments "Session lifecycle").
  The owner's SPEC-03 s-locks specifies the same model (lease with TTL, monitor releases an expired lease), so this is validated design.
- Resume is by id and does not need the old process.
  `claude --resume <id>`, `--session-id`, `--fork-session`; the SDK `session_store` mirrors transcripts to an external store so another host can resume (`types.py` lines 2758-2776); Codex `codex exec resume <SESSION_ID>`; Devin `resumable` flag; LangGraph checkpointers (`libs/checkpoint-sqlite`, `libs/checkpoint-postgres`).
- Retry semantics are declarative.
  LangGraph `RetryPolicy` defaults to 3 attempts with exponential backoff and jitter and a `retry_on` predicate (`types.py` lines 427-446); Claude Code emits `system/api_retry` events with `attempt`, `max_retries`, `retry_delay_ms` and an error category (https://code.claude.com/docs/en/headless "Handle API retries").
  The owner's "3 retries" rule (`specs/SPEC-03-dag-and-node-contract.xml` s-retry) matches the field default, so the number is validated; what differs is that the field applies it in the harness and the owner applies it in a prose `must` list the model is trusted to count (`roles/worker.json`, `must`: "at most 3 attempts").
- Claude Code already has most of a fleet harness.
  Hooks include `Stop` (exit 2 or `{"decision":"block"}` keeps the agent working), `PreToolUse` (blocks), `TaskCompleted` (blocks completion), `PostToolBatch` (stops the loop), `SessionEnd` (1.5 s budget), `WorktreeCreate` and `WorktreeRemove`, with handler types `command`, `http`, `mcp_tool`, `prompt` and `agent` (https://code.claude.com/docs/en/hooks, fetched 2026-10-14, first 100000 of 268946 characters read).
  The `http` handler type matters for a system-driven factory: a hook can POST the event JSON to a URL the system owns, so evidence capture needs no agent action.
  The `Stop` hook gives a system-enforced definition of done (for example "tests must pass before the seat may stop") with no memo and no nudge.
  `claude-code-action` exposes `conclusion`, `execution_file`, `branch_name`, `structured_output` and `session_id` as step outputs (`clones/claude-code-action/action.yml` lines 169-187), so a GitHub Actions or Argo step can consume a seat result as data.

## 5. What broke and why

These are the places the owner's seat contract differs from the field's, with the owner-side evidence.
They are findings about the contract only; the line scripts themselves are L01's area.

1. The seat is an interactive TUI, so the system has to type to it and read its screen.
   `herdr/bin/seat.sh` line 843 sends the brief with `herdr agent prompt` after starting claude with `--model --effort --permission-mode --settings` (line 809), then, because the TUI may sit idle, runs `nudge_seat` (lines 770-787) that waits on a pane regex `● ACK compaction-guard ` and issues a second prompt.
   The breadcrumb at lines 728-739 records the cost: three of four ticket seats on 2026-10-11 sat idle until the architect typed a continue prompt by hand (WO-20261011-dc0d), and WO-20261013-7af7 later found the wait froze every bring-up for 180 s (breadcrumb at line 745).
   Under `claude -p` the brief is the prompt argument, the run ends with a result, and there is nothing to nudge.
2. The trust dialog.
   Breadcrumb at `seat.sh` lines 716-722: the monitor seat opened "Is this a project you trust?", never reached idle, and `herdr agent start` failed after `agent_start_timeout_ms`; the fix writes `hasTrustDialogAccepted` into `~/.claude.json` for each worktree (`ensure_trust`).
   The headless docs state `-p` shows no trust dialog (https://code.claude.com/docs/en/headless).
   The same page warns that without `--bare` a `-p` session runs the project's `.claude/settings.json` hooks and `.mcp.json` servers "even in a folder you've never trusted", so the owner's governance hooks would also fire; that interacts with L11 and is the reason `--bare` plus explicit `--settings` is the contract to use.
3. The result is whatever the agent decides to say.
   `roles/worker.json` lists `outputs` as `pr`, `record.pr_opened`, `record.evidence` and the agent writes them through `events/bin/event.sh`.
   If the agent stops without posting, nothing in the harness reports it; the line waits.
   Contrast: a headless run cannot end without a `ResultMessage` or a non-zero exit, and Devin and the SDK fail the run if the structured output is missing.
4. Limits live in prose.
   `roles/schema/role.schema.json` has no property for turns, spend or wall clock (properties listed: schema_version, name, title, purpose, runtime, model, effort, permission_mode, read_only, context_threshold_percent, max_seats, label, pane_layout, allow, deny, records, must, forbidden, inputs, outputs, wakes_on, owner_channel, breadcrumbs).
   The 3-attempt limit is an instruction to the model (`roles/worker.json`, `must`), the context limit is `context_threshold_percent` 30 enforced by a separate compaction-guard memo, and nothing caps spend.
   The field puts all three in the launcher: `--max-turns`, `--max-budget-usd`, `task_budget`, `wall_time_limit_seconds`.
5. The contract forbids what the harness provides.
   `roles/worker.json` `forbidden` includes "spawning a subagent or any background process; every process is a labelled herdr pane" and `deny.tools` is `["Agent","Task"]`, while Claude Code subagents run in-process, return only a final summary to the parent, and keep the parent's context small (https://code.claude.com/docs/en/agent-sdk/agent-loop "Keep context efficient").
   This was a deliberate trade (visibility in herdr) but it costs context and capacity.
6. Capacity is a seat count against a pane budget and not a quota.
   `roles/orchestrator.json`, `reviewer.json` and `worker.json` breadcrumbs (2026-10-13, owner message m-20261013161912217-3d6g0 "15 seats available, why idle") raise `max_seats` 1 to 2, 2 to 4, 4 to 6.
   The field bounds concurrency by RAM per subprocess (the hosting guide: "agents per host = (host RAM - overhead) / (per-session RAM ceiling)", 1 GiB, 5 GiB disk and 1 CPU per agent as a starting point, https://code.claude.com/docs/en/agent-sdk/hosting) or by queue plus runner capacity, and never by a hand-edited per-role cap.
7. The agent is the scheduler's input channel.
   Wake-ups are `herdr agent prompt` messages to a live seat (`SPEC-03` s-routes: "wake (herdr agent prompt ...)"), so a wake-up to a seat that is not at a prompt is lost.
   In the field a follow-up is a new run that resumes by id (`claude --resume`, `codex exec resume`, Devin `resuming` status), which cannot be lost because there is no live process to be absent.
8. Where the field also has gaps (so the rebuild does not assume they are solved):
   the Agent SDK has no session timeout and no per-subagent wall-clock deadline (hosting guide, "Known limitations");
   Copilot cloud agent is capped at 59 minutes and one PR per task and is public preview;
   Jules is alpha and its pages do not define session states;
   Codex cloud's docs page does not state limits;
   Claude Managed Agents is beta and excluded from Zero Data Retention.

## 6. Waits, polls, sleeps and leases

This is a shelf area, so the brief's local-area requirement does not apply, but the bounds each system uses are the design input for the rebuild, so they are listed with their source.

- Claude Code self-hosted runner: poll request timeout 10 s; failed polls retry after 1 to 2 s, doubling to a cap of 20 s; lease lapses about 60 s after the last poll; server requeues within a few minutes (https://code.claude.com/docs/en/self-hosted-environments, fetched 2026-10-14).
- Claude Code `-p` background wait: stops background work after 10 minutes of continuous idle waiting unless `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS` is set; Monitor watches time out after 5 minutes by default; stream drain wait capped at 30 s (https://code.claude.com/docs/en/headless).
- Claude Code hooks: command, http and mcp_tool 600 s by default, 30 s on `UserPromptSubmit`, 10 s on `MessageDisplay`; `prompt` 30 s; `agent` 60 s; `SessionEnd` 1.5 s up to 60 s (https://code.claude.com/docs/en/hooks).
- Claude Code supervisor: stops an unattached finished session after about an hour, restarts a crashed one (https://code.claude.com/docs/en/agent-view).
- MCP startup under `-p --mcp-config`: waits up to `MCP_TIMEOUT`, 30 s by default (headless page).
- Agent SDK `session_store.load()` during resume: `load_timeout_ms` default 60000 so "the iterator" does not hang forever (`types.py` lines 2776-2783).
- OpenHands conversation lease TTL 45 s with a pid liveness probe (`conversation_lease.py` lines 18, 36-60).
- LangGraph per node attempt: `run_timeout` hard cap and `idle_timeout` progress watchdog (`langgraph/types.py` lines 449-480); `recursion_limit` caps super-steps.
- Copilot cloud agent: 59 minute session cap.
- Owner-side blocking in the seat contract for comparison (not investigated further here, L01 owns them): `seat.sh` waits up to `nudge_wait_seconds` on a pane regex (lines 732-739), up to `prompt_timeout_ms` for a shell prompt (line 805), up to `agent_start_timeout_ms` for the agent (line 719), and a `sleep` loop for the claude session file (lines 828-834).

## 7. Decisions an LLM makes that a rule could make

Not required for a shelf area.
The one cross-cutting finding for L13: with a headless contract the following decisions leave the model and become launcher flags or exit-code rules.

- Whether a seat is finished: today the agent decides and posts a record; headless, `ResultMessage.subtype` plus `terminal_reason` decide, with a `Stop` hook able to refuse stopping until a command (for example the ticket's test target) exits 0.
- Whether to stop after 3 failures: today `roles/worker.json` `must` asks the model to count; headless, the launcher retries a failed run up to 3 times and then records a blocked state, as Argo and LangGraph retry policies do.
- Whether the seat is stuck: today the monitor reads pane idle state; headless, a wall-clock cap plus `--max-turns` plus the exit status, or `claude agents --json` `state`.

## 8. What to carry forward

1. The headless Claude Code worker as the seat: `claude --bare -p "<brief>" --settings <role-settings.json> --permission-mode dontAsk (or bypassPermissions in a pod) --permission-prompts none --max-turns N --max-budget-usd X --json-schema <seat-result.schema.json> --output-format json`.
   Why: it is the same binary the roles already run, it returns result, cost, turns and session id as data, and it removes the trust dialog, the ACK nudge and the typed brief (section 5 items 1 and 2).
   Cost to weigh: `--bare` never reads OAuth or the keychain, so it needs `ANTHROPIC_API_KEY` or an `apiKeyHelper` (https://code.claude.com/docs/en/headless); a subscription-login worker would use `claude setup-token` and no `--bare`, and then the project hooks must be neutralised another way.
2. The Agent SDK as the driver where a process needs callbacks: `hooks` (`Stop`, `PreToolUse`, `SubagentStop`, `PreCompact`), `can_use_tool`, `session_store`, `output_format`, `max_budget_usd`.
   Python 0.2.165 and TypeScript are both current (CHANGELOG entry for 0.2.165 dated by commit 2026-10-13).
   Why: it moves the compaction-guard, the allow and deny lists and the permission mode from settings files into code the system owns, and returns typed messages.
3. The owner's own record schema and routes table, with enforcement moved to the harness.
   `factory/schema/record.schema.json` and `factory/config/routes.json` (per SPEC-03) are the same idea as `--json-schema` plus Devin `structured_output_schema`; keep the schema, change who emits the record: the launcher turns `ResultMessage` plus `structured_output` into the record, so a seat that dies still produces a `blocked` record.
4. The seat result schema should carry the fields the field converged on: terminal state, exit reason, attempt, cost, turns, session id, pr url and sha, evidence list.
   Sources of the field set: `ResultMessage` (`types.py` 1695-1725), Devin session object (`v3-openapi.json`), Copilot task `state` values.
5. A state vocabulary of working, blocked (needs a human or a ruling), done, failed, stopped, as in `claude agents --json`, and a distinct `waiting_for_user` so it is never conflated with idle.
6. The OpenHands stuck-detection idea as an external check over the transcript: five patterns (action-observation loop, action-error loop, monologue, alternating loop, repeated context-window error) in `stuck_detector.py`, applied to the Claude transcript JSONL, which is cheaper than a pane scrape.
7. The lease with pid probe from `conversation_lease.py`: TTL 45 s, generation counter, never steal when liveness is unknown.
   SPEC-03 s-locks already says this; take the failure-safe default (alive when unknown) as the explicit rule.
8. Resume-by-id as the only follow-up mechanism (`--resume`, `--session-id`, `--fork-session`), so wakes are new runs and cannot be lost.
9. For the self-hosted option: Claude Code self-hosted environments, if the owner's plan is Team or Enterprise, give a runner/queue/lease system with Kubernetes recipes that Anthropic operates the control plane for (https://code.claude.com/docs/en/self-hosted-environments-deploy referenced from the overview page; not read in full).
   It is a candidate only; plan eligibility is unverified (section 10).
10. mini-swe-agent's `default.py` (190 lines) as a reference for how small a correct worker loop is: limits first, one exit message per terminal reason, trajectory saved on every exit.

## 9. What to kill

1. Interactive TUI seats driven by `herdr agent prompt` as the worker mechanism: kill the ACK-memo nudge (`seat.sh` lines 728-787), the trust-file writer (`ensure_trust`, lines 716-727) and the typed brief; keep herdr only where a human wants to watch.
   Why: all three exist solely because the worker is interactive (section 5).
2. A model-written handoff as the only record of completion.
   Why: the field returns the result from the harness and fails the run when it is missing.
3. Role JSON `must` rules that count attempts or limit spend, as the enforcement point.
   Keep them as documentation; enforce in the launcher.
4. The ban on subagents for workers (`roles/worker.json` `forbidden`, `deny.tools` Agent and Task) as a blanket rule.
   Reconsider per role: it costs the parent's context for no isolation gain inside a pod, though the Agent SDK hosting guide notes subagents have no per-subagent wall-clock deadline, so a cap is needed if enabled.
5. SWE-agent as a candidate.
   Its own README (`clones/SWE-agent/README.md`, warning block at the top) says development moved to mini-swe-agent, "which has superseded SWE-agent", and the last commit is 2026-07-16.
6. Aider as a fleet worker.
   Single process, no budget or turn flags found in `aider/args.py`, last commit 2026-05-22, version string `0.86.3.dev`; useful as a human pair tool, not a factory seat.
7. OpenHands as a library to adopt.
   The `All-Hands-AI/OpenHands` repo is now the Agent Canvas React frontend (`clones/OpenHands/README.md` title, `AGENTS.md` first lines: "This repository is the OpenHands Agent Canvas React/TypeScript frontend"); the agent lives in `OpenHands/software-agent-sdk`.
   The pieces worth reading are the lease and stuck detector; adopting the server would add a second control plane next to whatever the rebuild chooses.
8. Alpha and preview worker APIs as a dependency of the merge path: Jules (alpha, "experimental"), Copilot cloud agent API and `gh agent-task` (public preview, user-to-server tokens only), Claude Managed Agents (beta).
   They can be used as optional extra capacity behind the same seat result schema, never as the only path.
9. Devin as a worker.
   The v3 API is the most complete contract in the survey, but it is a paid SaaS that runs the work on the vendor's VM unless an outpost pool is used; there is no evidence in this investigation that it adds anything the headless Claude worker lacks for this repo.
10. Claude Managed Agents for PR-shaped work.
    It is stateful, beta, excluded from Zero Data Retention and HIPAA, and exchanges events rather than producing a branch and PR contract (overview page, 2026-10-14).

## 10. Open questions for the owner

1. Which Claude plan are the seats billed on: the Claude subscription (then `--bare` is unavailable and `claude setup-token` is the CI credential) or an API key (then `--bare`, `--max-budget-usd` and spend caps are exact)?
   It decides whether the worker is launched with `--bare` and which hooks fire, and it is a billing decision the evidence cannot settle.
2. Is the Claude organisation Team or Enterprise?
   Self-hosted environments are public beta only on those plans (https://code.claude.com/docs/en/self-hosted-environments), and they would give a vendor-operated queue and lease; if not, the queue has to come from the S01-S03 shelf.
3. Should a human-watchable pane remain for any seat, or may every seat be headless with herdr used only for the owner's own sessions and for tests?
   This changes whether `claude --bg` plus `claude agents --json` (supervisor-hosted, attachable with `claude attach`) is enough, or whether panes stay.

## 11. Sources

Local files read 2026-10-14 (main checkout HEAD 5ad1996de26bfd872a38c14d54bbb0f6d73f746b):

- `/home/luna/projects/coq-jev-herdr-plugin/herdr/bin/seat.sh` lines 3-30, 716-722, 728-745, 770-787, 805-845.
- `/home/luna/projects/coq-jev-herdr-plugin/roles/worker.json`, `roles/orchestrator.json` line 87, `roles/reviewer.json` line 92, `roles/schema/role.schema.json`.
- `/home/luna/projects/coq-jev-herdr-plugin/specs/SPEC-03-dag-and-node-contract.xml`.
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/briefs/20261014-brief-B-investigation.md`.

Clones, all under `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/` and dated by HEAD commit in section 3:

- `claude-agent-sdk-python/src/claude_agent_sdk/types.py`, `pyproject.toml`, `CHANGELOG.md`.
- `claude-agent-sdk-typescript`, `claude-code-action/action.yml`.
- `langgraph/libs/langgraph/langgraph/types.py`, `errors.py`, `pregel/main.py`, `libs/langgraph/README.md`.
- `software-agent-sdk/openhands-sdk/openhands/sdk/conversation/state.py`, `stuck_detector.py`, `conversation.py`, `openhands-agent-server/openhands/agent_server/conversation_lease.py`.
- `OpenHands/README.md`, `AGENTS.md`, `docs/architecture.md`.
- `SWE-agent/README.md`, `mini-swe-agent/src/minisweagent/agents/default.py`, `environments/local.py`.
- `aider/aider/args.py`, `aider/aider/__init__.py`.
- `codex/codex-rs/exec/src/cli.rs` line 53, `codex-rs/utils/cli/src/sandbox_mode_cli_arg.rs`.
- `devin-openapi/v3-openapi.json` (downloaded 2026-10-14 from https://docs.devin.ai/v3-openapi.json).

Web, all fetched 2026-10-14:

- https://code.claude.com/docs/en/headless
- https://code.claude.com/docs/en/cli-reference
- https://code.claude.com/docs/en/hooks (first 100000 of 268946 characters)
- https://code.claude.com/docs/en/agent-view (first 100000 of 137050 characters)
- https://code.claude.com/docs/en/self-hosted-environments
- https://code.claude.com/docs/en/agent-sdk/hosting
- https://code.claude.com/docs/en/agent-sdk/agent-loop
- https://code.claude.com/docs/en/agent-sdk/structured-outputs
- https://platform.claude.com/docs/en/managed-agents/overview
- https://developers.google.com/jules/api
- https://developers.google.com/jules/api/reference/rest
- https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent
- https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-via-the-api
- https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-from-cli
- https://learn.chatgpt.com/docs/non-interactive-mode (redirect target of developers.openai.com/codex/noninteractive)
- https://learn.chatgpt.com/docs/cloud (redirect target of developers.openai.com/codex/cloud)
- https://docs.devin.ai/api-reference/overview and https://docs.devin.ai/llms.txt

Not read, so not claimed: Cursor background agents, LangGraph Platform docs, the self-hosted environments deploy and Kubernetes pages, the Claude Agent SDK hooks page, the Devin human-facing docs for playbooks and pricing.
