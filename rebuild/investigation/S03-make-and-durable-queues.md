# S03 - Make, Task, just, and durable queues

Investigated 2026-10-14T02:52Z (UTC) by the S03 investigator, step R-01; revised in attempt 3 on 2026-10-14T02:58Z after a critic's gap list.
Every live count in this file carries its capture time, and section 11 lists the command that reproduces it.
Read-only on every repo, directory, page and pane: no line script, herdr mutation, bearings script, event script or scheduler was run.
The only writes are this file, five shallow clones under `clones/` (`just`, `task`, `nats-server`, `nats.docs`, `helm-charts-temporal`; these five are "the investigator's own clones" wherever this file uses that phrase), and scratch experiments in the session scratchpad.
Experiments ran Make 4.3, Python 3.12 with SQLite 3.45.1, and a throwaway rootless Podman container of `nats:2.15.1-alpine` that was removed afterwards.
Toy scripts in the experiments copy the shape of owner code; they are labelled as toys and are not the owner scripts.

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

This area covers the two layers under any factory control plane: the declarative runner that says what depends on what (Make, Task, just) and the durable queue that makes sure a unit of work or a wake-up survives a crash (NATS JetStream, Redis Streams, Temporal, RabbitMQ).
The verdict in one paragraph: none of Make, Task or just is a scheduler, because none of them has a lease, a durable pending state or (except Task per command, since 3.53.1) a timeout, and none of them retries; they are the right entry layer and a good declarative DAG, and the owner already uses Make that way in eight Makefiles.
Of the four durable systems, only NATS JetStream fits the owner's size and shape (one static binary, arm64 build, 6 MB resident idle in my test), Temporal is the right model for multi-step durable runs but needs a database and a deterministic-code discipline, and Redis Streams and RabbitMQ add nothing JetStream does not.
The evidence disagrees with one framing in the brief: the brief says durable queues exist so "a wakeup is never lost", but the largest measured failure class on the line is a wake aimed at a seat that does not exist or a ticket that is gone (212 of 391 failed routes by L01's own table, 54.2 percent; L01's prose line `L01-line-scripts.md:119` says "the other 95 percent is naming and addressing, or ordering", and its table supports 95.4 percent only as "everything except the 18 capacity refusals", not as addressing alone, so this file uses the table and not the prose; counts captured 2026-10-14T02:57:43Z, unchanged from L01's 02:45Z read), and a durable queue would hold that wake for a consumer that never comes.
What the line is missing is a system-owned bounded retry and a level-triggered reconcile pass; a broker supplies redelivery but not the reconcile, and the field projects that run queues also run a reconciler on top.

## 3. Where it lives

Local, main checkout `/home/luna/projects/coq-jev-herdr-plugin` at HEAD 5ad1996 (2026-10-14T01:44Z), read only:

- Make: root `Makefile` (51 lines), `line/Makefile` (18), `herdr/Makefile` (58), `factory/Makefile` (40), `scheduler/Makefile` (111), `tools/bearings/Makefile` (67), `report/loop/Makefile`, `report/sitrep/Makefile` (`git ls-files` lists exactly these eight; no justfile, no Taskfile).
- The file queue: `queue/bin/queue.sh` (one file, exactly one commit: `920807a` "fix: commit the factory scripts that **/bin/ kept out of git", committed 2026-10-10T19:52:40Z; `git log --all --oneline -- queue/bin/queue.sh` returns that one line, checked 2026-10-14T02:57Z; `git log --follow` also returns one).
  Commit `bec8276` (PR #1, 2026-10-10) added the queue's config `queue/config/queue.json` and `queue.schema.json` and the graph nodes `CMP-queue` and `REQ-locks-and-queues`, but not `queue.sh`: `git show --stat bec8276` lists no `queue/bin` path, because `**/bin/` was gitignored until `920807a`.
  So `bec8276` is the origin of the queue's contract and `920807a` is the only commit that carries the script.
  Config `queue/config/queue.json`; items `queue/items/` (one item).
- The newer lane board that copies the queue contract: `line/bin/board.sh` (241 lines, commit `e5cef84`, config `line/config/board.json`).
- The architect queue: `line/bin/aq.sh` (88 lines), state in `~/.local/state/coq/coq-jev-herdr-plugin/queues/architect/{open,done}` (14 open, 830 done; captured 2026-10-14T02:58:17Z with `ls ... | wc -l`; unchanged on a second read at 02:57:14Z, so the line is quiet).
- Poll loops that stand in for a queue: `factory/bin/route.sh` (`poll_seconds` 10), `line/bin/route-retry.sh`, `line/bin/seat-queue.sh`, `line/bin/merge-watch.sh`, `line/bin/record-bus.sh`, `line/bin/digest.sh`.
- The abandoned broker design: ticket `work-orders/archive/2026/WO-20261010-539f-nats-jetstream-is-the-producer-consumer-bus-and-.md` (status cancelled), graph node `graph/nodes/DEC-nats-jetstream-grpc.json`, `ROADMAP.md:62` (C15), `AGENTS.md:119`.
- The owner's own research on queues: `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013021500-best-practices-agent-line.md` sections 4.5 and 5.

Upstream (versions read on 2026-10-14):

- GNU Make 4.4.1 (tag on `gnu.googlesource.com/make`, 2023-02-26 commit date per the release commit), installed here: 4.3.
- Task (`go-task/task`) v3.54.0, released 2026-10-01 (`clones/task/CHANGELOG.md:3`).
- just (`casey/just`) 1.58.0, released 2026-08-03 (GitHub releases API).
- NATS server v2.15.1, released 2026-10-09 (GitHub releases API); linux arm64 and amd64 tarballs are attached to the release.
- Temporal server 1.32.1 (2026-10-08, GitHub releases API); Helm chart 1.7.0, app version 1.32.0 (`clones/helm-charts-temporal/charts/temporal/Chart.yaml:25,28`).
- Redis 8.10.2 (2026-09-17) and Valkey 9.2.0-rc1 (2026-09-16), GitHub releases API.
- RabbitMQ 4.3.6 (2026-09-14), GitHub releases API.

The owner's cluster (from S01, read through `mcp-viewer@homelab`, re-checked by me on 2026-10-14): three arm64 nodes, namespaces `argocd`, `jenkins`, `monitoring`, `vault` and others; the only Redis is `redis:8.2.3-alpine` inside `argocd` (Argo CD's own cache) and the only Postgres is `postgres:16-alpine` in `resume-star`; no NATS, RabbitMQ or Temporal pod or CRD.

## 4. What works

Local, with evidence:

1. Make as a thin entry layer already works and is the owner's idiom.
   Every root target is a call into a script (`Makefile:1-2`: "Every target is a thin call into a script; logic lives in the script so the same thing runs from a pane, Jenkins and a container"), with `.SHELLFLAGS := -euo pipefail -c` (`Makefile:14`; line 16 is the `HERE :=` assignment, checked 2026-10-14T02:57Z at HEAD 5ad1996).
   The same file names the targets the factory needs as steps: `lint`, `test`, `graph-check`, `step`, `aggregates`, `event` (`Makefile:21-50`).
2. The claim-by-rename pattern in `board.sh` is correct under concurrency.
   `board.sh:97` is `claim() { ... mv -- "$1" "$c" 2>/dev/null && printf '%s' "$c"; }`, and `pull` re-checks the lease after winning the rename (`board.sh:134-139`).
   My toy of that exact shape (12 parallel holders on one item, 5 trials) produced exactly one winner every time (toyB, scratchpad `race/`).
3. `board.sh` already has the right wake model: the nudge carries a lane and a count, never content, and a seat learns of work by pulling (`board.sh:4-5`, `:15`, `board.json:14` `nudge_seconds` 60).
   That is the "doorbell versus mail" separation that JetStream pull consumers and BullMQ workers implement; the owner arrived at it independently on 2026-10-13 (commit `e5cef84`).
4. `route.sh` has the one at-most-once property a queue gives for free: it claims in the ledger before acting (`route.sh:266`) and a runner that dies mid-action leaves `claimed` (`route.sh:291-297`, per L01 section 4 item 1).
5. Bounded retry exists in the GitHub-facing scripts and in Jenkins: `merge.sh:30` and `verify-main.sh:23` default to 3 attempts with growing backoff, and `ci/jenkins-lib/vars/coqGate.groovy:201` carries `retryWaitSeconds: [10, 30, 90]` with a clean re-run rung at 300 s.
6. A per-lane lease with a deadline plus a sweep exists and is tested in the owner's idiom (`queue.sh:2-14`, `board.sh:156-160`, lease TTL 7200 s in `queue.json`, 1800 s in `board.json:13`).

Shelf, with evidence:

7. Make's declarative-target model reconciles correctly when observation is separate from action.
   Toy `M7` (scratchpad `mk/`): five tickets as stamp files with a "sense" step that rewrites an observation file only when its value changed.
   Run 1 built 10 stamps; run 2 with nothing changed ran zero recipes; run 3 after one ticket's head moved re-ran only that ticket's test and merge (12 trace lines total).
8. Make's job slots are a capacity cap with no extra code: `make -j2` over five one-second jobs took 3.03 s, which is the ceiling of 5/2 seconds (toy `M6`, run 1).
   That is the same property `max_seats` implements by hand in `seat.sh:530-537`.
9. NATS JetStream does the jobs the owner's file queue lacks, and I verified each against a live 2.15.1 server on 2026-10-14:
   - A message published while no consumer was fetching stayed in the stream (`Messages: 1`), and publishing the same `Nats-Msg-Id` twice stored one copy (dedupe window 2m0s default).
   - After `kill -9` of the server process and a restart on the same store directory the message was still there (`Messages: 1`).
   - A pull consumer with `ack_wait` 3 s and `max_deliver` 3 redelivered an unacked message three times and then stopped (consumer sequence 3 after three fetches, fourth fetch timed out).
   - At `max_deliver` a `$JS.EVENT.ADVISORY.CONSUMER.MAX_DELIVERIES.FACTORY.seat-b` advisory was published (`{"stream_seq":2,"deliveries":2}`), and the message stayed in the stream (`Messages: 2` afterwards): there is no built-in dead-letter queue, the advisory is the hook.
   - Idle footprint: 6.0 MB memory, 0.55 percent CPU in the container (`podman stats`).
   - Source anchors: default `AckWait` 30 s at `clones/nats-server/server/consumer.go:597`; advisory subject at `clones/nats-server/server/jetstream_api.go:281`.
10. Temporal's model matches the owner's own best-practices rule list: activity timeouts schedule-to-start, start-to-close, schedule-to-close and heartbeat (blog dated 2021-06-22), an event history that replays after a crash ("Temporal will automatically recreate its pre-failure state", docs.temporal.io/workflows, fetched 2026-10-14), timers recorded as events, and signals as the human-in-the-loop path (blog 2026-08-06).
    Temporal states it powers OpenAI's Codex product (Temporal blog 2025-06-11), and the open-source `mitkox/esf` factory chose Temporal on 2026-09-19 for exactly the owner's step shape (`clones/esf/docs/adr/0002-use-temporal-for-durable-workflows.md`, Status Accepted).
11. A single-file SQLite queue claims atomically with one statement and needs no daemon.
    My toy (`UPDATE q SET holder=? WHERE id=(SELECT id FROM q WHERE holder IS NULL ORDER BY id LIMIT 1) RETURNING id`, SQLite 3.45.1, 12 parallel processes, 3 trials) produced exactly one winner each time.
    `UPDATE ... RETURNING` exists since SQLite 3.35.0 (2021-03-12); WAL allows one writer at a time and does not work over a network filesystem (sqlite.org/wal.html, fetched 2026-10-14).

## 5. What broke and why

Local:

F1. `queue/bin/queue.sh` has a check-then-write race in `dequeue`, and nothing calls it.
`queue.sh:41` reads `.lease` and continues if empty; `queue.sh:44` then writes the lease with `jq ... > "$f.tmp" && mv`; nothing sits between the two (the file header claims "No lock: distinct filenames, atomic mv", `queue.sh:3-4`, but two holders do not use distinct filenames).
My toy of lines 41-44 (check lease, then write, 12 parallel holders, 3 trials) let 11, 10 and 12 holders each believe they leased the single item (toyA).
This is a reproduction of the pattern, not of the script, because the brief forbids running line scripts; the script itself is unrun.
Today it does no harm only because nothing dequeues: `grep` over scripts, JSON and Makefiles finds no caller of `dequeue` or `sweep` in the repo except `scheduler/config/executor.json:136` (`queue_sweep`, a verb the scheduler is not running) and role allowlists (`roles/monitor.json:50`, `roles/orchestrator.json:48`).
`route.sh:227` does call `enqueue`, so the queue only fills.
The one item on disk, `queue/items/p2-20261014T012050Z-WO-20261013-0b48.json`, is for a ticket whose PR #176 already merged at 5ad1996, so the queue also drifts from reality (consistent with L01 F5).

F2. The owner has three separate file-queue implementations with three lease clocks and one race.
`queue.sh` (lease 7200 s, racy), `board.sh` (lease 1800 s, claim-by-rename, correct, not running: `~/.local/state/coq/coq-jev-herdr-plugin/` has no board directory on 2026-10-14), and `aq.sh` (done by atomic mv, no lease; header `aq.sh:2-14` says it copies the style of `queue.sh`).
Plus three polling loops that act as queues without being one: `seat-queue.sh:28-29` (`until git ls-remote ...; do sleep`, `until seat.sh ...; do sleep "$SLOT_WAIT"`), `route-retry.sh` (30 s pass that deletes ledger entries after grepping prose, `route-retry.sh:55,65-68`), and `merge-watch.sh` (60 s poll, `merge-watch.sh:41`).
The result is the pattern the owner's own research warned about: the work queue is "the record store" with leases (best-practices doc section 5, "Rule for our line"), but each script re-derives its own claim, retry and sweep.

F3. Over half of the measured wake failures are addressing errors, so a broker alone would not have fixed them.
From L01 section 5 F1 (391 failed-route notes classified by text, 2026-10-13T15:30Z to 2026-10-14T02:2xZ): 88 merged wakes to a seat `architect-wo-<ticket>` that nobody starts, 75 owner notifications to an `interface` seat that is not running, 43 tickets archived before their gate record routed, 6 records with a PR and no ticket: 212 are naming and addressing errors; 89 are "branch not on origin yet", 18 capacity, 19 slot, 42 pane prompt failures: 168 are transient and would be cured by bounded retry (the remaining 11 are other `seat.sh` exit 3 or 4 on a gone tester or a failed `herdr agent start`; 212 + 168 + 11 = 391; L01-line-scripts.md lines 107-109 hold the corrected rows, and attempt 1 had printed 17 and 44 for the slot and pane rows).
I recounted the ledger itself, capture time 2026-10-14T02:58:17Z (same numbers at 02:57:24Z): `ledger/routed` holds 3,248 files, one of which is `README.md`, so 3,247 entries.
By the first line of each entry: ignored 1,442, own 925, unrouted 394, failed 373, done 74 (seat 31, escalate 27, wake 15, enqueue 1), held 38 (heads_match 27, head_current 11), interrupted 1; the sum is 3,247.
Reproduce with `cd ~/.local/state/coq/coq-jev-herdr-plugin/ledger/routed; for f in *; do [ "$f" = README.md ] && continue; head -1 "$f"; done | sort | uniq -c | sort -rn`.
The earlier version of this file said 3,243 entries and done 73; that equals L01's 02:45Z figure (`L01-line-scripts.md:400`, 3,243 files), so it was a read from about that time, and four more entries have arrived since, among them the single `done enqueue` entry.
Failed (373) and held (38) did not move.
The failure-note count (391 `route failed` records under `records/2026/10`, 3,343 record files in total) was recomputed with L01's classifier at 2026-10-14T02:57:43Z and gives 88, 75, 89, 43, 18, 19, 6, 42, 11, the same nine rows as L01 (`L01-line-scripts.md:107-108`).
The ledger is live state; the line was quiet across my two reads a minute apart, but any later reader should expect these numbers to have grown.
With JetStream and a pull consumer per role, the 212 misaddressed wakes would sit in the stream with no consumer to take them, or, if a consumer exists but cannot act, would be redelivered up to `max_deliver`, produce an advisory and stay in the stream, exactly what my live test showed for the second case.
The 168 transient ones are what a retry with backoff fixes, and `routes.json:4` already declares `"max_attempts": 3` that no script reads (L01 F2).
So the missing primitive is a bounded retry owned by the system plus an address check, and a level-triggered reconcile that lists open records and live seats and acts on the difference (best-practices doc section 2.1).

F4. One real lost wake exists and it is a level-triggering gap, not a transport gap.
Issue 78 (open, filed 2026-10-12T22:40:15Z): a `review.passed` wake went to the single busy merger, the belt downed the merger after its gate record, and two PRs were never merged.
A durable pull queue with ack-after-merge would hold those two items; so would a reconcile pass that lists every PR with `review.passed` and no `merged` (what `line/bin/merge.sh --all` does, but nothing calls it per L01 F4).
Both fixes work; the second needs no new daemon.

F5. The owner dropped the broker, the cancellation reason is recorded, but the reason for dropping NATS in the first place is not, and two sources of truth contradict.
The ticket WO-20261010-539f - NATS JetStream is the producer-consumer bus and gRPC the control plane: amend SPEC-03, stand up the bus, port the queue (created 2026-10-10, owner quote in the graph node: "NATS JetStream for producer consumer model on gRPC, be smart") was cancelled on 2026-10-13 with `superseded_by WO-20261012-be64` (WO-20261012-be64 - Roadmap L - Decision nodes for the locked roadmap decisions in the design graph, the NATS decision marked deferred and the bus ticket re-scoped); `ROADMAP.md:62` row C15 says "NATS JetStream is dropped for now; the bus is files in the state root, owned by the Go scheduler".
The cancelled ticket does carry a reason line, at `work-orders/archive/2026/WO-20261010-539f-nats-jetstream-is-the-producer-consumer-bus-and-.md:99`: "reason: Duplicate audit F6, ruled 2026-10-13T23:55Z: ROADMAP.md row C15 drops NATS JetStream for now ... A cancel that follows an existing roadmap row, not a new decision."
That line explains why the ticket was cancelled (it follows C15), and the duplicate-work audit F6 says the same (`20261013-duplicate-work-audit.md:217-236`, "a cancel that follows an existing row, not a new decision").
What is missing is the reason for C15 itself, the decision to drop NATS: `20261012212500-roadmap.md:43` reads "C15 NATS JetStream: dropped for now (owner answer 2026-10-12); the bus is state-root files, the Go scheduler owns them", gives no weight, cost or ops rationale, and my search of `plans/`, `specs/`, `docs/`, `COMPASS.md` and the auto-memory directory for "nats" found only restatements of the decision (SPEC-16 `l-bus`, SPEC-17 `X09`), no argument.
`graph/nodes/DEC-nats-jetstream-grpc.json:5` still reads `"status": "locked"` in the working tree, while `AGENTS.md:119` says deferred; the roadmap ticket L that fixes the node is open.
The word "for now" in C15 and in the ticket's reason makes it a deferral, and `ROADMAP.md:194` (item L) calls the NATS node "deferred", so the decision may be reversed; the roadmap's own open-work list is at `20261012212500-roadmap.md:90`.
The ticket's own non-goals list "Kafka, Redis streams, or any second broker" (`WO-20261010-539f...md:60`), so Redis and RabbitMQ were already excluded by the owner before this investigation.

Shelf, what breaks in each candidate:

F6. Make cannot retry, time out, lease or remember; my experiments on Make 4.3:
- No retry: `make -j2` with a failing prerequisite stopped with `Error 1`, and the second invocation re-ran the failed recipe once (`attempts.log` shows `attempt-b` twice, `attempt` once) only because a person ran make again; Make itself never repeats a recipe.
- A failed recipe leaves its half-written target in place, and the next run calls it up to date (`make: 'x.out' is up to date.`); `.DELETE_ON_ERROR:` deletes it (`Deleting file 'y.out'`).
- Staleness is modification time only: a changed input with an unchanged mtime is invisible (`o.out` stayed `1` after `in.txt` became `2`).
- No timeout: a recipe runs until it exits or an outer `timeout` kills it (`make: *** [M4:2: t] Terminated`).
- A `.PHONY`/`FORCE` prerequisite makes every dependent rebuild on every run (toy `M6`: run 2 re-ran all 10 recipes, 20 trace lines), so observation must happen outside the Makefile (toy `M7`).
- No daemon and no watch: a rule runs when someone runs make, so a timer or an event must call it.
- Pods: the Jenkins lint pod image has no `make` (`Jenkinsfile:66`), so `make` as the only entry point needs `make` in every pod image.

F7. Task and just are not retry engines either.
Task 3.54.0 has a per-command `timeout` (`clones/task/CHANGELOG.md:58`, added in v3.53.1 on 2026-08-18, exit code 124) and `sources`/`generates` with `method` checksum (default), timestamp or none, `run: once|when_changed`, `defer`, `watch`; its schema has no `retries` or `retry` key (`taskfile.dev/docs/reference/schema`, fetched 2026-10-14; `grep -ri retr` over the clone finds only a templating example).
just 1.58.0 is "a command runner, not a build system" (just.systems/man, fetched 2026-10-14), has `[parallel]` since 1.42.0 (`clones/just/README.md:4796`), and has no timeout or retry in its README (`grep -n -i "retry\|retries"` returns nothing; `timeout` returns nothing).
Neither tracks lease or durable state; just has no up-to-date check at all (recipes with the same arguments run once per invocation, `README.md:1345`).

F8. JetStream's durability default is lazy, and a durable broker can wedge silently.
`defaultSyncInterval = 2 * time.Minute` (`clones/nats-server/server/filestore.go:339`): acknowledged messages can be lost on an OS crash or power cut unless `sync_interval: always`.
Jepsen tested 2.12.1 and reported acknowledged-message loss on single kernel crash or power failure largely because of that default (jepsen.io/blog/2025-12-08-nats-2.12.1, published 2025-12-07, fetched 2026-10-14); my kill -9 test does not exercise this, because an OS page cache survives a process kill.
NEEDLE's CI sensor lost its JetStream subscription silently on 2026-07-31 after a leadership change: "webhooks kept returning 200 OK, the pod stayed Ready, and every push went unverified for days"; they added a watchdog that polls consumer metrics every 15 s and restarts the sensor (`clones/NEEDLE/docs/notes/ci-sensor-jetstream-watchdog.md`, dated 2026-08-22).
So a broker needs its own liveness probe and a reconciler anyway, the same lesson as the owner's "An LLM opinion is not a probe".

F9. Redis Streams: reclaim exists, replication is asynchronous.
Consumer groups keep a pending entries list, `XAUTOCLAIM` reassigns idle entries, `XPENDING` reports delivery counts (redis.io streams docs, fetched 2026-10-14), but the docs say AOF "must be used with a strong fsync policy", asynchronous replication "will not guarantee that XADD commands or consumer groups state changes are replicated: after a failover something can be missing", and `WAIT` is best effort.
Redis 8 is tri-licensed (RSALv2, SSPLv1, AGPLv3 since 8.0 on 2025-05-01, Phoronix coverage); Valkey is BSD with Linux Foundation governance.
The only Redis on the owner's cluster is Argo CD's private cache.

F10. Temporal's cost is a database, four services and a coding discipline.
It runs against Cassandra, MySQL or PostgreSQL; the Helm chart 1.7.0 deploys frontend, history, matching and worker services plus admin tools and a web UI (`clones/helm-charts-temporal/charts/temporal/templates/server-deployment.yaml`, `web-deployment.yaml`, `admintools-deployment.yaml`), pairs with Elasticsearch for visibility in production (docs.temporal.io/self-hosted-guide/visibility), and the docs call the service "a critical control and persistence component [to be] secured similarly to a database" (docs.temporal.io/self-hosted-guide/deployment, fetched 2026-10-14).
Workflow code must be deterministic; the esf ADR records this as accepted cost (`esf/docs/adr/0002...md`, "Negative / accepted").
The Temporal Agent Harness (blog 2026-08-20) covers Gemini, the OpenAI Agents SDK and PydanticAI and says it is "earlier than public preview"; it does not mention the Claude Agent SDK or herdr panes.

F11. RabbitMQ is a capable broker with nothing the owner needs that JetStream lacks.
Quorum queues are Raft replicated, `delivery-limit` defaults to 20 since 4.0, at-least-once dead-lettering is opt-in and requires `overflow: reject-publish`, publisher confirms arrive after quorum replication (rabbitmq.com/docs/quorum-queues, fetched 2026-10-14).
It is an AMQP broker with an Erlang runtime, more ceremony than JetStream for the same ack/nak/redelivery contract, and not on the cluster.

## 6. Waits, polls, sleeps and leases

This is a shelf area; the entries below are the places in the owner's code where the S03 primitives (a queue, a lease, a timer) are re-implemented by hand, with the bound where one exists.
L01 section 6 lists every wait in the line; I list only those that a queue or declarative runner would replace.

| Where | What it waits on | Bound |
| --- | --- | --- |
| `factory/bin/route.sh:339-343` (`read -r -t "$POLL"`), `runner.json:3` | next record pass, `poll_seconds` 10 | none on count, wakes every 10 s forever |
| `line/bin/route-retry.sh:55,88` | next retry pass, `EVERY` 30 s | forever; retries only `max_seats`/`max_agents` notes |
| `line/bin/seat-queue.sh:28` | `git ls-remote` for the ticket branch, `SEAT_QUEUE_BRANCH_WAIT` 15 s | unbounded `until` loop |
| `line/bin/seat-queue.sh:29` | a worker slot, `SEAT_QUEUE_SLOT_WAIT` 60 s | unbounded `until` loop |
| `line/bin/merge-watch.sh:41,91` | GitHub merge list, 60 s | self-exits after 7 days or on halt flag |
| `line/bin/record-bus.sh:53,107` | slot event copy, `interval` 5 s | forever |
| `line/bin/digest.sh:5-6` | digest, 1800 s | forever |
| `queue/bin/queue.sh` lease | `lease_ttl_seconds` 7200 (`queue.json`) | swept only if `sweep` is run; no caller |
| `line/bin/board.sh` lease | `lease_seconds` 1800, nudge 60 s (`board.json:13-14`) | swept by `board sweep`; third expiry is printed as a finding |
| `line/bin/merge-watch.sh:52` | `flock -n 9`, single instance | non-blocking |

Shelf primitives for the same waits, with their bounds:

- JetStream pull consumer: `AckWait` 30 s default (`consumer.go:597`), `MaxDeliver` -1 default (unlimited redelivery, nats docs acknowledgment page, fetched 2026-10-14), `MaxAckPending` 1000 default, `BackOff` list replaces AckWait, `InProgress` resets the AckWait timer, dedupe window 2 m.
- Temporal: four timeouts (schedule-to-start, start-to-close, schedule-to-close, heartbeat); default retry policy is unbounded in time ("up to 10 years", blog 2021-06-22), so the bound must be set.
- Redis Streams: idle time in `XAUTOCLAIM min-idle-time` set by the caller; nothing is bounded unless the caller bounds it.
- RabbitMQ: delivery limit 20 default, consumer ack timeout set per node.
- Make: no wait of its own; `-j N` job slots; `.WAIT` since 4.4 (LWN 2022-10-31).

## 7. Decisions an LLM makes that a rule could make

- Which seat to wake for a record, and whether it exists.
  Where: the architect and orchestrator seats read a prompt typed by `route.sh:205,223` and by `merge-watch.sh`, then decide whether to act.
  Rule: a pull queue per lane (`board.sh pull --lane L`) where the nudge says "N items in lane L" and the seat pulls; address validity is a table check against `herdr` pane names before enqueue, not after.
- Whether a failed route should be retried.
  Where: the acting orchestrator reads 500 notes and clears the ledger by hand (L06: "hand-patched queue-clear loops", roadmap:160,165).
  Rule: retry with backoff `[10, 30, 90]` s, at most 3, then a named fallback record; the shape already exists in `coqGate.groovy:135-148` and `merge.sh:106-132`.
- Which PRs are ready to merge.
  Where: the acting orchestrator (`sched-worker-2`) merges after `merge-watch.sh` prompts it.
  Rule: `merge.sh --all` on a systemd timer (a reconcile pass over `review.passed` and not `merged`); the decision is already code (`merge.sh:359-360`).
- When a queued item has been abandoned.
  Where: nobody; `queue/items` held a merged ticket.
  Rule: the sweep verb (`queue.sh sweep`, `board.sh sweep`) on a timer plus an attempt counter and `dead/` after 3 (best-practices doc section 5).
- Which of two workers gets the item.
  Where: a race in `queue.sh:41-44`.
  Rule: atomic rename or one `UPDATE ... RETURNING`, never read-then-write.

## 8. What to carry forward

1. Keep Make as the entry and static-DAG layer, and add `.DELETE_ON_ERROR:` to every Makefile that writes files.
   Reasons: it is already the owner's idiom (eight Makefiles), it is installed on the host (4.3), it has capacity for free (`-j`), and the field uses it far more than the alternatives: of the repositories other investigators cloned under `clones/` (a mixed set, not a survey), 21 have a root Makefile, 4 have a justfile (`centaur`, `codex`, `esf`, `machinist`) and none has a Taskfile.
   The count is dated 2026-10-14T02:57:56Z.
   `clones/` held 63 entries then (62 with a `.git`, `devin-openapi` has none); excluding the investigator's own five clones (`just`, `task`, `nats-server`, `nats.docs`, `helm-charts-temporal`) leaves 58, which is the population of the 21 and the 4 and the 0.
   Counting all 61 entries except the two tool repos `just` and `task` (which carry the tools' own `justfile` and `Taskfile.yml`) gives 22 root Makefiles, because `nats.docs` has one; `clones/task/Taskfile.yml` exists and is Task's own repo, not a project that chose Task.
   An earlier version of this file gave 58 and 21 without a date or the exclusion rule; this paragraph replaces it.
   The 22 Makefile repos are `NEEDLE agent-sandbox agentic-orchestrator argo-cd argo-events argo-workflows astro-template-factory coq esf gascity gastown jobset kueue langgraph nats.docs pipeline pipelines-as-code rime software-agent-sdk software-factory-reliability sortie triggers`.
   Reproduce with `cd clones; for d in */; do d=${d%/}; case $d in just|task) continue;; esac; ls $d | grep -qx -E 'Makefile|makefile|GNUmakefile' && echo $d; done` (Makefile), and the same loop with `-E '[Jj]ustfile'` and `-E 'Taskfile\.(yml|yaml)'`; the clone directory is live, so a later run can differ.
   Make is how Argo Events, Argo Workflows, Kueue, Tekton and JobSet build themselves (their clones each carry a Makefile).
   Use GNU Make 4.4.1 for `.WAIT` and the FIFO jobserver if the host Make is upgraded; 4.3 is what is installed.
2. Adopt the sense / plan / act shape: a sense step writes observation files only on change (write-if-changed), `make` derives the plan from stamps, and each recipe is idempotent.
   Proof: toy `M7` (zero rebuilds when nothing changed, one ticket rebuilt when its head moved).
   Run `make reconcile` from a timer so a missed event is repaired on the next tick, which is the Kubernetes principle named in section 2.1 of the owner's best-practices doc and in kubernetes.io/docs/concepts/architecture/controller (fetched 2026-10-14).
3. Name these design principles and write them into the factory design once:
   - Declare outputs, derive the plan (Make targets and prerequisites).
   - Level-triggered reconcile: act on the full desired-versus-actual difference every pass, events are hints only (Kubernetes controllers; the HackerNoon edge-versus-level article dated 2018-01-23).
   - Bounded retry then a named fallback: Argo `retryStrategy` with `limit`, `retryPolicy`, `expression` over `lastRetry.exitCode`, `backoff` (`clones/argo-workflows/docs/retries.md`, commit 4192c5b), Temporal retry policy with schedule-to-close.
   - Lease plus heartbeat plus deadline: JetStream `AckWait` with `InProgress`, Temporal heartbeat timeout.
   - Idempotency key: `Nats-Msg-Id` with a 2-minute window, Temporal workflow id, the owner's ledger claim.
   - Doorbell versus mail: the wake carries a lane and a count, the work lives in the store (`board.sh nudge`; JetStream pull consumers).
   - One owner per transition with compare-and-swap (Optio: "Lost events left rows stuck ... No single decision point", `clones/optio/docs/reconciliation.md:11-12`, commit a6a047e0, 2026-10-13).
4. Fold the three file queues into the correct one: `board.sh` (claim-by-rename, lease, nudge, sweep) replaces `queue.sh`, `aq.sh`, `seat-queue.sh` and `route-retry.sh`; keep its contract and its tests (`line/tests`), delete the rest.
5. If a broker is wanted, it is NATS JetStream, single replica, one static binary, arm64 build, 6 MB idle, with `sync_interval: always` for the wake stream and a consumer-metrics probe (the NEEDLE watchdog pattern).
   It arrives bundled if the control plane is Argo Events (the default EventBus is a JetStream StatefulSet, S01 section 5), in which case do not run a second one; S01 documents the default three replicas and that it should be sized or reduced to one before use.
   Stream shape that passed my test: `--retention work`, `--storage file`, `--replicas 1`, pull consumer with `--ack explicit --wait 3s --max-deliver 3`, a consumer on `$JS.EVENT.ADVISORY.CONSUMER.MAX_DELIVERIES.>` that posts the failure record.
6. If no broker is wanted, a single SQLite file in WAL mode on the WSL host is the durable queue with atomic claim, a retry counter column and a dead status; it holds one writer at a time, needs no daemon, and survives a process kill; set `PRAGMA synchronous=FULL` for the wake table.
   It does not work over a network filesystem, so it is a host-side store only.
7. Temporal is the reference design for the durable multi-step run (ticket as a workflow, test and review as activities with start-to-close and heartbeat, human approval as a signal).
   Adopt its vocabulary and timeouts in the Make and board layer now; adopt the server only if the control plane decision moves to code-defined workflows.

## 9. What to kill

1. `queue/bin/queue.sh` `dequeue`, `renew`, `release` and the `queue/items` directory, once `board.sh` is running: a read-then-write race, zero callers, one drifted item (F1, F2).
2. `line/bin/seat-queue.sh` and `line/bin/route-retry.sh` as separate loops: replace by a bounded retry in the runner and a pull from the board; both are unbounded `until` loops or prose-grepping side loops (F2, F3).
3. The idea that a durable transport fixes the line: 212 of 391 failed routes are addressing errors that a broker would store and redeliver (F3).
4. Any plan to run NATS, Redis and RabbitMQ side by side, or a Redis for the queue while Argo CD's Redis is a private cache: the owner's own ticket excluded a second broker (`WO-20261010-539f...md:60`).
5. Make `FORCE`/`.PHONY` prerequisites as a change detector, because every dependent rebuilds (F6); use a sense step.
6. Using Make, Task or just as the runtime scheduler: none retries, none leases, none remembers (F6, F7).
7. Task or just as a replacement for Make for its own sake: Task adds a per-command timeout since 3.53.1 and a checksum default, just adds ergonomics, and neither has retry or lease; they would be a new dependency in every pod image, and the lint image already lacks `make` (`Jenkinsfile:66`).

## 10. Open questions for the owner

1. Where does the control plane run: on the WSL host next to herdr, or in the cluster?
   This is the question that decides the durable layer: in the cluster, Argo Events brings JetStream with it and no separate queue is chosen; on the host, a SQLite file or the claim-by-rename board is the queue and no broker is run.
2. Why was NATS dropped in C15 on 2026-10-12, weight or operations cost or something else?
   The cancelled ticket's reason line (`WO-20261010-539f...md:99`) explains only why the ticket was cancelled, namely that it follows C15; no document records the reason for C15 itself.
   If the reason was "one more daemon to keep alive", a JetStream that arrives with Argo Events changes the answer, and a host-side SQLite file keeps it; if the reason was "the Go scheduler owns the bus", the answer is the same either way and the S03 broker comparison only matters for the in-cluster case.

## 11. Sources

Local files read (main checkout `/home/luna/projects/coq-jev-herdr-plugin`, HEAD 5ad1996):

- `Makefile`, `line/Makefile`, `herdr/Makefile`, `factory/Makefile`, `scheduler/Makefile`, `tools/bearings/Makefile`, `Jenkinsfile` (line 66), `ci/jenkins-lib/vars/coqGate.groovy` (lines 135-148, 194, 201).
- `queue/bin/queue.sh`, `queue/config/queue.json`, `queue/items/p2-20261014T012050Z-WO-20261013-0b48.json`.
- `line/bin/board.sh`, `line/config/board.json`, `line/bin/aq.sh`, `line/bin/seat-queue.sh`, `line/bin/route-retry.sh`, `line/bin/merge-watch.sh`, `line/bin/record-bus.sh`, `line/bin/digest.sh`, `line/bin/hook-listener.sh`.
- `factory/bin/route.sh` (lines 205-227, 266, 335-343), `factory/config/runner.json`, `factory/config/routes.json`.
- `scheduler/config/executor.json` (lines 107-140), `roles/orchestrator.json`, `roles/monitor.json`.
- `ROADMAP.md` (line 62), `AGENTS.md` (line 119), `graph/nodes/DEC-nats-jetstream-grpc.json`, `work-orders/archive/2026/WO-20261010-539f-nats-jetstream-is-the-producer-consumer-bus-and-.md`.
- `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013021500-best-practices-agent-line.md`, `20261012212500-roadmap.md` (line 43), `20261013-duplicate-work-audit.md` (F6).
- State read: `~/.local/state/coq/coq-jev-herdr-plugin/ledger/routed` (counts, 2026-10-14T02:58:17Z), `queues/architect/{open,done}` (counts, 2026-10-14T02:58:17Z), `records/2026/10` (391 `route failed` notes, 2026-10-14T02:57:43Z; commands in section 5 F3 and section 8 item 1).
- Git history read with `git log --all --oneline -- queue/bin/queue.sh` and `git show --stat bec8276` (2026-10-14T02:57Z).
- Roadmap and audit lines: `20261012212500-roadmap.md:43,90` and `ROADMAP.md:62,194`, `20261013-duplicate-work-audit.md:217-236`.
- GitHub issues 76 and 78 on `jkkelley/coq-jev-herdr-plugin` (read with `gh issue view`).
- Sibling findings: `investigation/L01-line-scripts.md` (sections 4 and 5), `investigation/S01-argo.md` (sections 3, 5 and 8), `investigation/L06-owner-retros-and-plans.md`.

Clones under `~/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/`:

- `just` (a6bc306d, 2026-10-14T01:40Z), `task` (ad2782e, 2026-10-13), `nats-server` (64dda80, 2026-10-09), `nats.docs` (f115bec, 2026-08-24), `helm-charts-temporal` (ac0be25, 2026-10-07).
- Read from other investigators' clones: `argo-workflows` (4192c5b), `optio` (a6a047e0, https://github.com/jonwiggins/optio), `esf` (0ef8e23, https://github.com/mitkox/esf), `NEEDLE` (https://github.com/jedarden/NEEDLE).

Experiments (session scratchpad, throwaway):

- `mk/Makefile`, `M2` to `M7`: Make 4.3 failure, partial target, timeout, mtime, `-j2` and reconcile toys.
- `race/toyA.sh`, `toyB.sh`, `toyC.py`: check-then-write race, claim-by-rename, SQLite `UPDATE ... RETURNING`.
- NATS: `docker.io/library/nats:2.15.1-alpine` with `docker.io/natsio/nats-box:latest`, 2026-10-14T02:49Z to 02:53Z.

Web (all fetched or searched 2026-10-14 UTC unless the page carries its own date):

- GNU Make tags: https://gnu.googlesource.com/make/+refs (4.4.1 highest); GNU Make 4.4 announcement summary: https://lwn.net/Articles/913253 (dated 2022-10-31); 4.4.1 release commit: https://gnu.googlesource.com/make/+/refs/tags/4.4.1%5E%21 (2023-02-26).
  The GNU manual pages (gnu.org/software/make/manual) returned HTTP 429 and 403 to my fetches, so Make semantics in this file rest on my experiments, the 4.4 NEWS summary and the local `make` 4.3.
- Task: https://taskfile.dev/docs/reference/schema, https://taskfile.dev/docs/guide, https://api.github.com/repos/go-task/task/releases.
- just: https://just.systems/man/en/, https://api.github.com/repos/casey/just/releases.
- NATS: https://docs.nats.io/learn/jetstream/acknowledgment, https://docs.nats.io/learn/jetstream/retention-policies, https://docs.nats.io/nats-concepts/jetstream/streams, https://docs.nats.io/nats-concepts/jetstream/consumers, https://api.github.com/repos/nats-io/nats-server/releases, https://github.com/nats-io/nats-server/discussions/4994 (no DLQ by design, per search result).
- Jepsen, NATS 2.12.1: https://jepsen.io/blog/2025-12-08-nats-2.12.1 (published 2025-12-07).
- Redis: https://redis.io/docs/latest/develop/data-types/streams/, https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/, https://api.github.com/repos/redis/redis/releases, https://api.github.com/repos/valkey-io/valkey/releases, https://www.phoronix.com/news/Redis-8.0-Goes-AGPLv3 (2025-05).
- Temporal: https://docs.temporal.io/workflows, https://docs.temporal.io/self-hosted-guide/deployment, https://docs.temporal.io/self-hosted-guide/visibility, https://temporal.io/blog/activity-timeouts (2021-06-22), https://temporal.io/blog/from-ai-hype-to-durable-reality-why-agentic-flows-need-distributed-systems (2025-06-11, Codex statement), https://temporal.io/blog/durable-flexible-multi-agent-systems (2026-08-06), https://temporal.io/blog/temporal-agent-harness-durable-agent-infrastructure (2026-08-20), https://api.github.com/repos/temporalio/temporal/releases, https://api.github.com/repos/temporalio/helm-charts/releases/latest.
- RabbitMQ: https://www.rabbitmq.com/docs/quorum-queues, https://api.github.com/repos/rabbitmq/rabbitmq-server/releases.
- SQLite: https://www.sqlite.org/lang_returning.html, https://www.sqlite.org/wal.html.
- Kubernetes: https://kubernetes.io/docs/concepts/architecture/controller/, https://hackernoon.com/level-triggering-and-reconciliation-in-kubernetes-1f17fe30333d (2018-01-23).
