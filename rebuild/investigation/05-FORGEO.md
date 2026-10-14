# 05 - forgeo: what L12 found

Lead deliverable of step R-01 of the Factory Rebuild investigation.
Finished 2026-10-14T03:17Z (UTC) by the merge seat from `L12-forgeo.md`, `L12-addendum-owner-confirmed-forgejo.md`, `L14-go-grpc-control-plane.md`, `L15-google-drive-designs.md`, `L09-earlier-factory-iterations.md` and `L10-cluster-and-gitops.md`.

## Contents

1. The answer
2. The owner's words, in order
3. What Forgejo is, and what the owner has of it
4. Readings that did not survive
5. What it changes in the rebuild
6. The process lesson
7. Sources

## 1. The answer

"forgeo" is Forgejo, the self-hosted Go git forge (a fork of Gitea, hosted at codeberg.org/forgejo/forgejo).
The owner confirmed it at 2026-10-14T03:02:11Z: asked "is forgeo Forgejo, the self-hosted forge?", the owner answered "yah i was say it wrong lol" (`~/.claude/history.jsonl` line 21040, verified by the merge seat; `L12-addendum-owner-confirmed-forgejo.md` section 1).
"i have forgeo already" is true only as a design: Forgejo has been designed three times and partly vendored, and it has never run on the owner's cluster (L12 section 5; L10 section 3).
It is not the `jkkelley/software-factory` repository under another name (L12 section 2).

## 2. The owner's words, in order

All from `~/.claude/history.jsonl`, times UTC (L12 section 2; merge seat re-read for line 21040).

| Line | Time | Words |
| --- | --- | --- |
| 14576 | 2026-09-20T19:15Z | picks "forgejo on the cluster" over GitHub Issues |
| 14750 | 2026-09-21T01:18Z | "forgejo runs boards only, automation when designing this ..." |
| 14752 | 2026-09-21T01:23Z | "can we develop a lite weight GO RPC system quick in my k8s cluster locally, then get that forgejo ticketing setup based on the system" |
| 20995 | 2026-10-14T02:16:15Z | "My fucking software factory is shit / forgeo, i have it / DAG we have it / MERMAID we have it" |
| 20999 | 2026-10-14T02:19:59Z | "i have forgeo already, we need that shit here." |
| 21018 | 2026-10-14T02:45:53Z | "why isn't a system design by go still here? that lite weight go concurrencyh with grpc" |
| 21019 | 2026-10-14T02:46:27Z | "forgeo" |
| 21021 | 2026-10-14T02:47:20Z | "forgeo is gonna be github" |
| 21040 | 2026-10-14T03:02:11Z | "yah i was say it wrong lol" |

The owner spelled "forgejo" correctly at least five times in September and "forgeo" only on 2026-10-14 (L12 section 2).

## 3. What Forgejo is, and what the owner has of it

What it is (L12 sections 2 and 4, web pages fetched 2026-10-14):

- A self-hosted forge with issues, pull requests, webhooks, Mermaid in markdown, and Forgejo Actions CI, which is "designed to be familiar to users of GitHub Actions, but it is not designed to be compatible".
- Current releases: v16.0.6 stable and v15.0.10 LTS, both 2026-10-12; v17.0 scheduled for 2026-10-15.
- Its REST API has no project-board endpoint, so boards are built from exclusive scoped labels (L12 section 5, break 6).

What the owner has (L12 sections 3 and 4; L10 sections 3 and 9; L15 section 2.1):

| Iteration | Date | State |
| --- | --- | --- |
| `cortex-hub` design spec and plan, then `forge-config`, `forge-gitops`, `forge-eks-infra` | 2026-05-19 to 2026-05-25 | Manifests with a `PLACEHOLDER_FORGE_CONFIG_REPO_URL`; EKS and homelab co-equal; never applied |
| Drive "Open-Source, Agent-Friendly Change Management System for Kubernetes" (Forgejo as hub, LangGraph, a service mesh) | 2026-09-18 | Design only; assumes components the owner later removed |
| `bearings-core` Forgejo deploy (PR 2, `d69375d`) | 2026-09-20 | Ran in Podman once; superseded by rime the next day |
| rime ADR-0003 "Forgejo boards only", deploy tree `deploy/forgejo/` (chart 17.1.7), Argo Application, REPLAN ticket B-08 | 2026-09-21 to 2026-10-06 | Merged to rime main; the last step is a hand copy into `homelab-gitops` that never happened |

Live state on 2026-10-14: no `forgejo` namespace, no Forgejo Argo Application, no Forgejo path in `homelab-gitops` (L12 section 5).
The vendored deploy has no bound anywhere: the bootstrap script has no retry or timeout, Argo retry is off by default, the sync has no timeout by default, and the chart's liveness probe kills the pod about 300 seconds after start (L12 section 6).

## 4. Readings that did not survive

| Reading | Who held it | Why it fell |
| --- | --- | --- |
| forgeo is `jkkelley/software-factory` renamed | brief, L12 question | software-factory has no "forgeo" or "forgejo" string and is a v0.1 design capture (L12 section 2; L09 section 5.1) |
| forgeo is the Go gRPC design | the architect at 02:46:30Z, passed to investigator L14 and to the owner as fact | an unconfirmed reading, held for 70 seconds beside a second reading; withdrawn by the owner's answer (L12 section 2 and section 7; addendum section 2) |
| forgeo is rime (a Go core with Forgejo boards) | L12's strongest pre-answer inference | the owner's answer names the forge; the Go control-plane question is separate and belongs to D01 and D09 (addendum section 2; L14) |
| forgeo is `lucaGazzola/forgeo` | the only literal match on GitHub | a public Python single-repo, single-agent loop that commits to main; not installed, never visited in 37,929 Firefox pages; kept only as an idea source for its exit-code contract (L12 sections 3 and 4; L14 section 4.7) |

## 5. What it changes in the rebuild

- Forgejo is a shelf candidate for the forge and for CI runners (Forgejo Actions), not for scheduling seats (addendum section 2).
- "forgeo is gonna be github" reads, with the confirmation, as: the forge role is GitHub for now (L12 section 2, reading 1).
- Recommended in `03-DECISIONS.md` D18: GitHub stays the forge for the rebuild, and Forgejo gets its own design later, off the critical path, because a second forge holding board state is "two systems stay in sync instead of one" (rime ADR-0003, L09 section 9), and every earlier Forgejo deploy stopped at a hand step.
- If Forgejo is adopted later, the rime `deploy/forgejo` tree at `994a614` is the starting point, with a bounded bootstrap, an explicit Argo retry block and a sync timeout added, and the hand copy into `homelab-gitops` replaced by a scripted pull request (L12 sections 6 and 9).
- The Go and gRPC control-plane question is unaffected by forgeo; the owner ruled D01 on 2026-10-14T03:28Z (a Go service speaking gRPC), and its scope stays in D09: the owner's Go designs exist five times over and none runs (L14 section 2).

## 6. The process lesson

The investigation spent about 70 seconds and two investigators on an unconfirmed reading of one word, and the architect passed the reading on as an owner statement (L12 section 7, items 1 to 4).
The rule that would have prevented it: an owner term is a data row with a confirmed referent (`term`, `referent`, `status`, `confirmed_by_message`, `confirmed_at`); a message whose key term has no confirmed row becomes a card question, and no seat is told a referent until the row is confirmed (L12 section 7).
The same registry is the home for the line's other coined words such as GOTEAM, GOFACTORY and USERGO (L12 section 7).
This is listed as job J26 in `00-INVENTORY.md`.

## 7. Sources

- `L12-forgeo.md` sections 2 to 10 (written 2026-10-14T02:59Z) and `L12-addendum-owner-confirmed-forgejo.md` (written 2026-10-14T03:02Z).
- `L14-go-grpc-control-plane.md` sections 2, 3.7, 4.7; `L15-google-drive-designs.md` section 2.1 item 19; `L09-earlier-factory-iterations.md` sections 5.1, 9 and the closing pointer; `L10-cluster-and-gitops.md` sections 3 and 9.
- `~/.claude/history.jsonl` line 21040, read by the merge seat on 2026-10-14T03:05Z (timestamp 1791946931896 ms, 2026-10-14T03:02:11Z).
- Web pages cited inside L12 section 11, all fetched 2026-10-14: https://forgejo.org/releases/, https://forgejo.org/docs/latest/admin/release-schedule/, https://forgejo.org/docs/latest/user/actions/overview/, https://github.com/lucaGazzola/forgeo.
