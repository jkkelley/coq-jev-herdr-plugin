# 02 - Mapping the owner's patterns against the field

Lead deliverable of step R-01 of the Factory Rebuild investigation.
Finished 2026-10-14T03:17Z (UTC) by the merge seat; revised 2026-10-14T03:45Z (V14 amended, T15 and section 6 added).
Three lists: owner patterns the field also arrived at (validated, keep), patterns the field dropped that the owner still carries (kill), and patterns the field has that the owner has not touched (steal).
Every item cites the area files it draws on; RC and D numbers point into `01-ROOT-CAUSES.md` and `03-DECISIONS.md`.

## Contents

1. Codes
2. Validated: keep (V01 to V18)
3. Dropped by the field, still carried here: kill (K01 to K12)
4. In the field, untouched here: steal (T01 to T15)
5. Where the field does not back the owner's stricter line
6. Where the unlanded work sits in the sequence
7. Sources

## 1. Codes

| Prefix | Meaning | What happens to it in the rebuild |
| --- | --- | --- |
| V | Validated: the owner built it and the field converged on the same thing | Carried into the design unchanged or wired |
| K | Kill: the field tried it and dropped it, and the owner still runs it | Retired by a rebuild ticket |
| T | Steal: the field runs it and the owner has not built it | Specified in the design, built or adopted |

## 2. Validated: keep

- V01. One append-only record log written by one validating writer, with an HTTP-shaped status code map.
  Owner: `event.sh` exclusive-create writes and the code enum, unchanged since rime (L02 sections 4 and 8; L09 section 4.2; L01 section 8).
  Field: Shopify River's Postgres append-only session log and Anthropic Managed Agents' session log outside the sandbox (I01 section 4.2).
- V02. Claim before act, with a ledger keyed on the record, and an interrupted claim turned into one escalation.
  Owner: `route.sh` ledger (L01 section 4 item 1; L02 section 4 item 2).
  Field: Symphony's claim states Unclaimed, Claimed, Running, RetryQueued, Released (I03 section 4.3); idempotency keys in Argo and Temporal (S03 section 8 item 3).
- V03. Merge and verify as pure functions of records and the head, with three bounded attempts and a hold file for a red main.
  Owner: `merge.sh`, `verify-main.sh`, `merge-hold.json` (L01 section 8 item 3; L05 section 8; L06 section 8).
  Field: Stripe's deterministic nodes for push and lint (I01 section 4.2); Optio's reconciler-owned auto-merge (I03 section 7).
- V04. A pod per test case, hermetic, with no service account token and a public fetch by sha.
  Owner: `ci/pod/herdr-suite.pod.yaml`, 30 of 31 cases passing in pods (L07 section 4; L10 section 8 item 4).
  Field: one disposable sandbox per task, "cattle, not pets" (I01 section 4.2); the Job and Argo container template have the same shape (S01 section 4; S02 section 8).
- V05. Infrastructure failures retried, test failures never retried.
  Owner: the `coqGate()` ladder 10, 30, 90, 300 s (L07 section 4).
  Field: Kubernetes `podFailurePolicy` and Argo `retryPolicy` split the same way (S02 section 4 item 3; S01 section 4).
- V06. Suites planned from the diff, with an unmapped path planning the full set.
  Owner: `suites.sh` plus `suites.json` (L07 section 4; S02 section 8).
  Field: the planner is executor-independent and ports to Jobs, Tekton or Argo (S02 section 4 item 4); Argo does not plan from a diff, so keep it (S01 section 9).
- V07. One file, one in-flight ticket, declared at cut and refused at start.
  Owner: `claims.sh`, `wo-start.sh` (L01 section 8 item 6; L11 section 8).
  Field: Cognition's single-threaded writes and Claude Code teams' "each teammate owns a different set of files" (I02 section 4.1); Factory's "serialize code changes" (I01 section 4.2).
- V08. Probes, not opinions, for liveness.
  Owner: `patrol-tick.sh` v2 probes after the Haiku monitor said OK to a blocked merger (L01 section 4 item 5; L06 section 4).
  Field: Symphony's stall timeout in the service (I02 section 4.4); "An LLM opinion is not a probe" matches the NEEDLE watchdog lesson (S03 F8).
- V09. Small tickets, one concern each.
  Owner: global rule and rime's fastest runs, four tickets merged in 32 minutes (L09 section 4.3; L15 section 4 item 2).
  Field: Claude Code teams' "self-contained units that produce a clear deliverable" (I02 section 8); Stripe's one-shot minions (I01 section 4.1).
- V10. The node contract: schema in, schema out, three attempts, a black-box seat.
  Owner: SPEC-03 and software-factory v0.1 (L03 section 8; L09 section 4.1).
  Field: every worker harness returns one structured result (S04 section 4.1).
- V11. Git as the only write path for cluster config.
  Owner: Argo CD app-of-apps, AppProject fence, one tag bump, 12 apps healthy (L10 section 4).
  Field: the same pattern is Argo CD's design (S01 section 4).
- V12. A failure catalogue written at the fix site and in blameless retros.
  Owner: 219 breadcrumbs, rime's F-01 to F-20, stable's 13-row catalogue, the rime investigation (L11 section 4; L09 sections 4.2 and 8; L04 section 8).
  Field: software-factory-reliability's patterns with drills (I03 section 4.3).
- V13. The doorbell is not the mail: a nudge carries a lane and a count, and the worker pulls.
  Owner: `board.sh` (S03 section 4 item 3).
  Field: JetStream pull consumers; Cursor's event subscription (S03 section 4 item 3; I01 section 4.2).
- V14. Make as the thin entry layer.
  Owner: eight Makefiles where every target calls a script (S03 section 4 item 1).
  Field: 22 of the 61 repositories cloned for this investigation have a root Makefile, 4 a justfile and none a Taskfile; a mixed set, not a survey (S03 section 8 item 1).
  Limit: today it is only an entry-point list; none of the line's own operations is a target with prerequisites (L01 F9), which T15 fixes.
- V15. A separate reviewer from the writer.
  Owner: a reviewer seat (L13 section 7 D21).
  Field: the generator-verifier split works best with no shared context (I02 section 4.2).
- V16. A small file protocol for the owner's page: append-only JSON lines, idempotent ids, a consumed-set.
  Owner: bearings (L08 sections 4 and 8).
  Field: none needed; it is validated by four days of use with a median reply of 32 s (L08 section 4).
- V17. Standing policies: an escalation carries a deadline and a default, so nothing waits on an answer.
  Owner: `policy.sh`, `policies.json` (L03 section 4.3; L13 section 4).
  Field: a bounded escalation to a terminal state is the field norm (I02 section 7).
- V18. A watchdog that is a timer outside the line.
  Owner: `watchdog.timer`, the one installed supervisor (L01 section 4 item 8).
  Field: the owner's own best-practices report places the dead man's switch outside the line (L06 section 8); fix its count of the patrol's own notes first (L06 section 5.2).

## 3. Dropped by the field, still carried here: kill

- K01. An LLM integrator, gatekeeper or orchestrator in the dispatch path.
  Field: Cursor removed its integrator because it "created more bottlenecks than it solved"; Symphony's scheduler is deterministic (I02 section 5.2; I01 section 4.2).
  Here: the architect wake on merge, the shared merger seat, `sched-worker-1` and `sched-worker-2` as acting orchestrators (L13 sections 5.2 and 9; RC1).
- K02. A long-lived "pet" agent that holds state in its context or pane.
  Field: Anthropic's single container became a pet and was lost when it failed (I01 section 4.2).
  Here: interactive seats with compaction guards and ACK nudges (S04 section 5; L11 F10; RC4).
- K03. Agents that wait for a result by polling.
  Field: every published wait has a timer or an event, and the waiter is a daemon or a hook (I01 section 6).
  Here: tester seats sleeping and reading panes (L11 F13; L06 section 5.4).
- K04. LLM monitors and idle alarms as the control mechanism.
  Field: replaced by stall timeouts and caps (I02 sections 5.4 and 9).
  Here: the Haiku monitor, the compliance officer reading every screen each minute, 350 idle notes (L06 section 5.6; L13 D17).
- K05. Shared mutable coordination state and locks between equal workers.
  Field: Cursor's lock file slowed 20 agents to the throughput of 2 or 3 (I02 section 5.2).
  Here: the shared merger seat downed while another ticket's wake is in its input (L01 F4), and the racy `queue.sh` (S03 F1).
- K06. A terminal multiplexer as the production substrate for an unattended fleet.
  Field: no published fleet hosts agents in multiplexer panes; Gas City ships herdr as an opt-in session backend only (I01 section 5; I03 F5).
  Here: herdr as service host and supervisor (L04 sections 5.3 to 5.6; RC6).
- K07. Two sources of truth kept in sync.
  Field: Gas Town's data-loss era came from "two sources of truth" and ended with one store (I02 section 5.3).
  Here: two record trees bridged by `record-bus.sh`, two state roots, ticket status in git and in records (L02 section 5; RC3).
- K08. Events alone as the path to state progress.
  Field: "Events make it fast; reconciliation makes it true"; Optio replaced worker-owned transitions because lost events stranded tasks (I03 F3).
  Here: a failed route is written once and never revisited (L01 F2; RC2).
- K09. Adding a role per incident.
  Field: Cursor removed a role; Gas Town's critic calls its concept count overwhelming (I02 section 5.9).
  Here: the compliance officer, verifier and interface agent roles, and about 51 lettered causes in 12.6 hours (L03 section 5.3; L06 section 5.7).
- K10. Limits written as prose for the model to count.
  Field: limits are launcher fields (`--max-turns`, `--max-budget-usd`, `max_acu_limit`, `wall_time_limit_seconds`) (S04 section 4.2).
  Here: "at most 3 attempts" in the role `must` list (S04 section 5 item 4).
- K11. An approval step that approves nearly everything.
  Field: users approve 93 percent of permission prompts, which is why Anthropic built auto mode (I02 section 5.5).
  Here: 238 of 238 ticket approvals were overrides (L11 F3).
- K12. Bash loops as the control plane.
  Field: the Anthropic compiler experiment used a bash loop only as a research prototype (I02 section 4.4).
  Here: rime's `watch.sh` died silently six times in one day, and the coq line's `seat-queue.sh` has two unbounded `until` loops (L09 sections 5.2 and 9).

## 4. In the field, untouched here: steal

- T01. A headless one-shot worker that returns its own result: `claude -p` with `--json-schema`, `--max-turns`, `--max-budget-usd`, `--permission-prompts none`, ending in a `ResultMessage` (S04 sections 4 and 8 item 1; D02).
- T02. The Symphony control loop as a reference algorithm: poll, reconcile before dispatch, stall timeout (5 min default), capped backoff (`min(10 s * 2^(n-1), 5 min)`), concurrency cap (10 default), restart recovery from the tracker with no database (I01 section 8; I02 section 4.4; I03 section 4.3; D01).
- T03. Level-triggered reconcile as the correctness path, with events as accelerators (I03 F3 and section 8 item 2; S03 section 8 item 3).
- T04. A verdict the agent can read and cannot edit: Factory's validation contract written before code, Spotify's verifiers behind a stop hook, ArtCraft's generated scorecard with ratchet floors, Anthropic's feature list where only `passes` may change (I01 section 4.2; I03 sections 4.2 and 8 item 8; I02 section 8; D05).
- T05. Claude Code hooks as system enforcement: a `Stop` hook as the definition of done, `http` hooks posting evidence to a system URL (S04 section 4.2).
- T06. A lease with heartbeat, generation counter and compare-and-swap, renewed at a third of its length, never stolen when liveness is unknown (S04 section 8 item 7; I03 section 6).
- T07. A stuck detector over the transcript: action-observation loops, error loops, monologue (OpenHands, S04 section 8 item 6).
- T08. Blueprints: a workflow in code with named deterministic and agentic nodes and a hard limit of CI rounds (Stripe, I01 section 8).
- T09. Failure-mode drills driven by `make` as acceptance tests: event-is-lost, worker-dies-agent-survives, stale-writer-completes, retry-storm (I03 section 8 item 3).
- T10. herdr's own event stream and hook-reported state: `events.subscribe` and `pane.report_agent`, already written by the owner in September and unused by the line (L04 sections 4.1 and 8; D08).
- T11. A webhook redelivery reconciler: list deliveries, redeliver non-OK ones within GitHub's 3-day window (S01 section 5; D06).
- T12. Kubernetes Job primitives for worker pods: `podFailurePolicy`, `backoffLimit`, `activeDeadlineSeconds`, `ttlSecondsAfterFinished` (S02 section 8).
- T13. Budget and loop caps enforced before the model call, because alerts lag ("They had observability. They did not have enforcement.") (I02 section 4.7).
- T14. A broker-owned delivery contract, if a broker is ever used: JetStream ack wait, max deliver and the max-deliveries advisory, verified live on 2.15.1 (S03 section 4 item 9; D10).
- T15. Make as the static DAG of line operations, not only an entry list: "bring the line up", "start a ticket", "seat a worker", "merge" and "verify main" as targets with real prerequisites, `.DELETE_ON_ERROR:` so a failed recipe never leaves a target that reads as done, stamps outside the repository, and observation done by a sense step outside the Makefile so nothing rebuilds when nothing changed (S03 F6 and toy M7; L01 F9; build item BI04 and row J30 in `00-INVENTORY.md`).
  Make supplies order and idempotence only; retry, timeout and lease stay in the reconciler (S03 F6, F7).
  The design is owned by the rebuild design document (D14 D), written by a spec-author run and ruled by the owner.

## 5. Where the field does not back the owner's stricter line

- No LLM decides anything: the field keeps an LLM for decomposition (Factory, Cognition, Cursor) and for review, and moves dispatch, claim, stall, retry and merge to code (I01 section 5; I02 section 5.9; D16).
- Script every step inside a ticket: OpenAI reports that "treating agents as rigid nodes in a state machine doesn't work well" and moved to objectives per ticket; the evidence supports code owning ticket-level state, not micro-steps (I02 section 5.9).
- Three retries everywhere: the number is the owner's own rule; the field agrees only that a retry is bounded and escalates (I02 section 7).
- A global merge queue: Anthropic never replicated one at agent scale and Shopify says merge queues "became load-bearing", so it is an open choice (I01 section 4.2).
- One-minute idle alarms: the field alarms on stalls with a bound, not on idleness (I02 section 5.9; D17).

## 6. Where the unlanded work sits in the sequence

The 5,812 untracked event copies, the dirty `tools/bearings/assets` edits, the untracked `backlog/now/` files and the 33 open issues are not patterns and have no row above; their verdicts, order and trigger are in `04-UNLANDED.md` sections 7, 11 and 12, and whether that cleanup may run before GOFACTORY is decision D25.

## 7. Sources

All area files in this directory (list in `01-ROOT-CAUSES.md` section 7), written 2026-10-14 between 02:40Z and 03:02Z; web sources and their dates are in each cited area file's section 11.
