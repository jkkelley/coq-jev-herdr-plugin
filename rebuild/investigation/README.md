# R-01 investigation - Factory Rebuild Plan

## Contents

- What this folder is
- Reading order
- Files
- L05-evidence
- Sources kept outside the repo

## What this folder is

This folder is the R-01 investigation of the Factory Rebuild Plan, `rebuild/factory-rebuild-plan.xml`.
It was produced on 2026-10-14 UTC by a 20-investigator workflow with a critic per area.
An Opus merge combined the area reports into the six top-level documents.
A completeness critic then passed the result after one gap-close round.
`BRIEF.md` is the brief the investigators worked from.

## Reading order

Read `00-INVENTORY.md` to `05-FORGEO.md` first, in order.
Then read the area reports by prefix: `L` for the local system, `S` for the surveyed tools, `I` for the industry field.
`BRIEF.md` explains the questions each report was asked.

## Files

- `BRIEF.md`: Brief B - Factory Rebuild investigation, step R-01
- `00-INVENTORY.md`: 00 - Inventory: every factory job, what exists, what to do
- `01-ROOT-CAUSES.md`: 01 - Root causes: what is holding the factory back now
- `02-MAPPING.md`: 02 - Mapping the owner's patterns against the field
- `03-DECISIONS.md`: 03 - Decisions the owner has to make
- `04-UNLANDED.md`: 04 - Everything not on main, with a verdict
- `05-FORGEO.md`: 05 - forgeo: what L12 found
- `I01-production-agent-fleets.md`: I01 - Production fleets of coding agents
- `I02-postmortems-and-abandonment.md`: I02 - Post-mortems and abandonment
- `I03-oss-factories-and-clones.md`: I03 - Open-source software factories and the clone wave
- `L01-line-scripts.md`: L01 - Line scripts
- `L02-state-stores.md`: L02 - State stores
- `L03-design-vs-built.md`: L03 - Design documents versus what was built
- `L04-herdr.md`: L04 - herdr
- `L05-git-state.md`: L05 - Git state
- `L05b-worktrees-and-dirty-checkout-snapshot.md`: L05b - Worktrees and dirty main checkout, snapshot 2026-10-14T02:50:25Z
- `L06-owner-retros-and-plans.md`: L06 - The owner's own retros and plans
- `L07-ci-and-pods.md`: L07 - CI and pods
- `L08-bearings-owner-surface.md`: L08 - Bearings, the owner surface
- `L09-earlier-factory-iterations.md`: L09 - Earlier factory iterations
- `L10-cluster-and-gitops.md`: L10 - The cluster and gitops the owner has
- `L11-governance-layer.md`: L11 - The governance layer
- `L12-addendum-owner-confirmed-forgejo.md`: L12 addendum - owner confirmed: forgeo means Forgejo
- `L12-forgeo.md`: L12 - forgeo
- `L13-llms-doing-scheduler-work.md`: L13 - LLMs doing scheduler work
- `L14-go-grpc-control-plane.md`: L14 - Go control plane with gRPC
- `L15-google-drive-designs.md`: L15 - The owner's Google Drive: factory designs, iterations and lessons
- `S01-argo.md`: S01 - Argo Workflows, Argo Events, Argo CD
- `S02-k8s-jobs-tekton-jenkins.md`: S02 - Kubernetes Jobs, CronJobs, Kueue, operators, Tekton and Jenkins
- `S03-make-and-durable-queues.md`: S03 - Make, Task, just, and durable queues
- `S04-agent-frameworks-seat-contracts.md`: S04 - Agent orchestration frameworks and seat contracts

## L05-evidence

`L05-evidence/` holds the scripts and outputs behind `L05-git-state.md`.
Its own `README.md` says how each file was produced.

## Sources kept outside the repo

The clones, Google Drive exports and Kubernetes documentation used as sources are not in this repo.
They stay at `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/` under `clones/`, `drive/` and `k8s-docs/`.
Citations in the reports that start with `clones/` point there.
