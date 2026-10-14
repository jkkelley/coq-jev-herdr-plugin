---
{
  "id": "WO-20261010-539f",
  "slug": "nats-jetstream-is-the-producer-consumer-bus-and-",
  "title": "NATS JetStream is the producer-consumer bus and gRPC the control plane: amend SPEC-03, stand up the bus, port the queue",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-13",
  "created_at": "2026-10-10T19:44:33+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect: sure of it; owner 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for this project",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "superseded_by": "WO-20261012-be64"
}
---

# WO-20261010-539f - NATS JetStream is the producer-consumer bus and gRPC the control plane: amend SPEC-03, stand up the bus, port the queue

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

Owner decision 2026-10-10 UTC: the producer-consumer model runs on NATS JetStream with gRPC. SPEC-03 s-locks (REQ-locks-and-queues, locked) still says the queue is a directory of files with rename-dequeue, and seats are woken by the monitor by hand (herdr agent prompt). A file queue cannot fan out, replay, ack or redeliver, and every consumer polls.

## Scope

**In**

- SPEC-03 amended: records and queue entries are JetStream messages on subjects factory.<kind>.<priority>; durable pull consumers per seat role; ack, nak and AckWait replace lease TTL for queue work; explicit ack with max deliver and a dead-letter subject
- gRPC service contracts (proto under factory/proto/) for the synchronous control plane only: orchestrator, monitor, seat bring-up; everything asynchronous goes over JetStream, never gRPC streaming
- nats-server with JetStream runs in a labelled herdr pane (SPEC-04 bring-up DAG), state under ~/.local/state/coq-jev-herdr-plugin/nats, dev tier in Podman for tests
- queue/bin ported onto the bus with the same verbs (enqueue, dequeue, status) so callers do not change; the file queue stays only as the offline fallback and is named as such
- wake-on-publish: a seat waiting on a lease or a ticket is a consumer, not a poller (REQ-status-change-wakeups)
- graph node DEC-nats-jetstream-grpc locked; AGENTS.md law names the bus

**Out - non-goals**

- Kafka, Redis streams, or any second broker
- gRPC for fire-and-forget events
- multi-host clustering of NATS

## Degrees of freedom

- [free] subject naming below factory.<kind>.<priority> and stream retention limits
- [free] the gRPC language bindings (Node first is the recommendation since the factory scripts are Node and bash)

## Acceptance criteria

- [ ] `AC-H1` *(human)* SPEC-03 validates against spec.xsd, REQ-locks-and-queues text names JetStream and the file queue is named the offline fallback
- [ ] `AC-H2` *(human)* an enqueue on the dev tier is consumed by a pull consumer within one second with no polling loop in the consumer
- [ ] `AC-H3` *(human)* a message nak'd past max deliver lands on the dead-letter subject and the monitor records a 500
- [ ] `AC-H4` *(human)* a gRPC health call against the orchestrator stub answers SERVING in the Podman suite
- [ ] `AC-H5` *(human)* make lint is green and the graph node DEC-nats-jetstream-grpc resolves its edges

## Test plan

```sh
Podman: nats:2.10 image with -js plus the suite under tests/bus/: enqueue-consume, nak-to-dead-letter, grpc health; make lint in localhost/coq-lint:1
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: Duplicate audit F6, ruled 2026-10-13T23:55Z: ROADMAP.md row C15 drops NATS JetStream for now (the bus is files in the state root, owned by the Go scheduler, SPEC-16 l-bus), and ROADMAP item L says this ticket is re-scoped or cancelled; WO-20261012-be64 already marks the NATS decision deferred. A cancel that follows an existing roadmap row, not a new decision.
- superseded by: `WO-20261012-be64`

No branch, no PR and no merge commit exist for this work order.

