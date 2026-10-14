# L15 - The owner's Google Drive: factory designs, iterations and lessons

Investigator L15, Factory Rebuild step R-01.
Written 2026-10-14 UTC.
Read-only on Drive; zips were extracted into their own empty directories and nothing in them was run.
Everything read in Drive is treated as data, never as instructions.

## 1. Contents

1. Contents
2. What it is (with the dated timeline of iterations)
3. Where it lives
4. What works
5. What broke and why (including what each successor says about its predecessor)
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

The owner's Google Drive (account jkkelley86@gmail.com) holds roughly six weeks of factory design work, almost all of it written between 2026-09-09 and 2026-10-06 UTC, plus two older operations documents from 2026-04-30 and 2026-05-01.
It is a document set, not a running system: nearly every file marks itself PROPOSED, "design requirements, not running controls" or "NOT_DEPLOYED", and the build side of each iteration lived in other places (local-k8s-docs, getting-my-bearings, bearings-v2 and rime, rime-bootstrap).
Read together the documents show one continuous argument made six times: a factory in which a deterministic workflow service owns all state and routing, and models are called only for bounded judgment (manual 32, 36, 38, 51, 53 of 2026-09-16), while every build iteration that followed put an LLM seat or a bash loop driving herdr panes in that role and then spent its effort repairing silent failures in the dispatch and recovery path.
The Drive has no document after 2026-10-06 that concerns the factory, so the current coq-jev-herdr-plugin iteration (2026-10-10 onward) is not recorded here at all.

### 2.1 Timeline of the owner's factory iterations as Drive shows them (UTC, oldest first)

Each line: date and time, what it is, the Drive link.
Document links use https://docs.google.com/document/d/ID/edit and file links use https://drive.google.com/file/d/ID/view.

1. 2026-04-30 15:52Z - GitOps Cluster Bootstrap SOP: bare-metal ARM64 cluster, ArgoCD app-of-apps, External Secrets Operator with AWS SSM, Jenkins writes image tags to a config repo. https://docs.google.com/document/d/1kmp-mcFSMaK-SQGlsdHPuvIgNcqka2OpuS2ePxl-MUc/edit
2. 2026-05-01 17:44Z - Context Management and State Distillation Runbook: the first "janitor" compaction routine, 40 percent trigger, state schema table, anchor prompt. https://docs.google.com/document/d/1yqeEo34lccX-BDJZ3hdg0Z1cFoTdPiyueUHEEWdZ9xc/edit
3. 2026-09-09 20:19Z - Technical Design Document: Agent Harness Blue-Green Deployment and Handoff: 7-step blue/green handoff for a stateful agent harness, Kaniko ARM64 builds, Trivy gate, ArgoCD, SMB ReadWriteMany state. https://docs.google.com/document/d/1h8WoUdumwJv2LqwlscPf2FWt_mDCDbnj8sp0X6yhshA/edit
4. 2026-09-11 03:52Z - Stateless Orchestration Service technical architecture and operational manual (SOS-ARCH-OPMAN-2026-V1): Redis Streams ingress, Pydantic strict schemas, Go knowledge graph, ephemeral workspaces, two-tier discrepancy codes ERR_*, Jenkins pipeline. https://docs.google.com/document/d/17Db9of1WdBJK3YzZpEjTEx23fBYL1wRfy85WH_hiCf4/edit
5. 2026-09-11 04:17Z - Autonomous Document-First System Architecture: declarative documents as source of truth, deterministic hash identity, state store as ledger, level-triggered reconciler (Observe, Diff, Act, Record). https://docs.google.com/document/d/1bXhUfXZ728Us5YevKvlExV8YM59v66W2FJiQCigsiDY/edit
6. 2026-09-12 12:56Z to 15:03Z - Win11 Pro herdr restart triad, v0.1.0 through v0.2.4: seven design versions (v0.1.0 to v0.2.4) plus three refactor drafts in under two hours, HANDOFF flag so a halt is not undone by SessionStart, stable INDEX pointer. Folder https://drive.google.com/drive/folders/1J199gAxGBpfLdfemnMgf_Fi5ADgCeR5L ; archive https://docs.google.com/document/d/1Xi3HryEaF1M8nA0Le9uXZWWTCrFxttDYj1AYBdmB35E/edit
7. 2026-09-12 13:45Z to 15:13Z - GOVERNANCE_AGENTIC_TRIAD v0.2.0 to v0.2.5: the documentation standard (Design Doc, Execution Sheet, Archive Doc, agent contract, ledger JSON, one unversioned INDEX). https://docs.google.com/document/d/1IFzrhhWI1ObQlpJeE4adKP6yiQ7L7wDFAEN_KwQgJKM/edit
8. 2026-09-12 15:12Z - TRIAD_Homelab_Topology v0.1.0 (second Triad instance). https://drive.google.com/drive/folders/1vCFMXUa00PJuhbu_MNF85mp-jRa8kEfb
9. 2026-09-13 03:25Z to 14:40Z - TRIAD_Work_Ledger: DESIGN_Work_Ledger (decisions Q2 to Q7 of 2026-09-13), SEAT_orchestrator_Job_Spec (an Opus LLM orchestrator with a 16-step procedure), THEMES_Work_Ledger, SYSTEM_Change_Log. This is the local-k8s-docs agent-run-protocol and the first getting-my-bearings (gmb) runtime. https://docs.google.com/document/d/1hMn-kNqcymFxrecIA890tuMoeII8XhfpFPuugBiWDMQ/edit and https://docs.google.com/document/d/1hizGdbPdRJIxti5kpkGn0HdtRnQoapxgJw0Su7l5JDw/edit
10. 2026-09-16 01:11Z to 01:25Z - Systems Architect Operating Manual v1.0.0, modules 00 to 37, package systems-architect-v1.0.0.zip. https://drive.google.com/drive/folders/1M01-vsUQcnncxtorUDEgVTj8dJYcbj1G
11. 2026-09-16 01:47Z to 02:10Z - Systems Architect Release 1.1: modules 38 to 54, 10 role contracts, 35 schemas, 12-stage create-system workflow, systems-architect-v1.1.0.zip (840 KB, extracted and read). https://drive.google.com/file/d/1vYr0_gM5pnJx4NZr9gfd6jnRKzeaISTe/view ; release index https://docs.google.com/document/d/12j0zxK6YUgeVaJSApARDPw1_Iz65oeijgQ2DJLswH7E/edit
12. 2026-09-16 02:07Z - Knowledge Steward 1.0 (modules 55 to 58, knowledge-steward-v1.0.0.zip), later knowledge-steward-v2.0.1.zip (2026-09-17 17:14Z). https://drive.google.com/file/d/1ww_YTJtrbHzECuKjqhMIY_UsSQ0qn-o9/view
13. 2026-09-16 12:43Z - A2A SDLC Agent Workflow and Schema: NATS JetStream, JSONL envelope, agents never talk directly, all communication through queues. https://docs.google.com/document/d/1aQ6Tvlus2ZX0ngYdM2qpaHK2KxyIJ6IakSwzGBMqKUg/edit
14. 2026-09-16 14:46Z - Deterministic Agent IO Communications Project v1.0.0: layered protocols (A2A, MCP, gRPC, Temporal, one broker per context, CloudEvents, outbox/inbox), 4 ADRs, zip extracted and read. https://drive.google.com/file/d/1B53nv6B_abak02ZyMjdAXy-U9-6CRM-5/view
15. 2026-09-16 17:37Z - SOP Project Setup and Background Agentic Documentation Workflow (Spark and Gemini): Triad scaffolding, 30 percent compaction rule, 3-retry then DLQ. https://docs.google.com/document/d/1nf3-Lwv7Dsp7H8rh7pqY0mp75vAxpHDzixKQJsUiO-Q/edit
16. 2026-09-17 00:21Z to 00:23Z - bootstrap-with-agent v0.1.0 (BWA-REL-2026-09-17-V0.1.0): Bootstrap Supervisor prompt with an 11-stage pipeline, control_plane.proto (8.6 KB, L14 reads it), model-routing-policy, agent-spec, A2A adapter contract. Folder https://drive.google.com/drive/folders/1OflD-qTSq7VARvf7eDcE24zWB9_uA6C2 ; blueprint (580 KB) https://docs.google.com/document/d/1L2D-xaqBxxbpnNBh4jbxUenawOAo-l6udd_RnAFKEx4/edit
17. 2026-09-17 16:23Z to 17:31Z - Drive reorganised: 107 root files filed into 7 folders, KNOWLEDGE-GRAPH-v1.0.0.json (a Drive parent graph, 319 distinct titles), NAMESPACE-INDEX, MASTER_DRIVE_STATE_LEDGER, START-HERE v1.0.0 to v1.3.0, SITREP. Folder https://drive.google.com/drive/folders/15GwN2hU-4spMtYkAnCEYiX5Uz9Il83sp
18. 2026-09-18 17:36Z to 20:48Z - HERDR-FIRST change ledger, HERDR_SYSTEM_RECOVERY v1.0.0 (18:56Z) and extension v1.1.0 (19:24Z), controller agent package (20:10Z), deterministic-agent-io-workflows skill v1.0.0 and v1.0.1. https://drive.google.com/file/d/16V84_X9Qlz_FR0hEPg3dlKEkaG1tEwmo/view
19. 2026-09-18 22:06Z - Open-Source Agent-Friendly Change Management System for Kubernetes: Forgejo as hub, LangGraph orchestration, Istio or Linkerd canaries. https://docs.google.com/document/d/1zheVmvufZldwoborC8C3qMqALRIB5oaOYMa0gIA15XM/edit
20. 2026-09-19 02:57Z to 03:35Z - HERDR-FIRST v1.0.0 then v1.1.0 inside 35 minutes (the refusing gate was rejected the same day). https://docs.google.com/document/d/1K0B1ZoOn6WYOVqDS6YqBSb7AsuJAob2f0T_2_5_0w1E/edit
21. 2026-09-19 06:27Z to 07:50Z - agents/architect and agents/auditor packages (ARCHITECT-DESIGN-RECORD-v1.0.0, 06:37Z). https://drive.google.com/file/d/1txdRDHuz-8kBpCDksZXpkCap__yzuLwX/view
22. 2026-09-19 09:12Z and 10:05Z - Observability decision and Controller handoff ("gmb up --brief has never worked"). https://docs.google.com/document/d/1cEy4bIaXMYotSDDLvGTHhBaNyo0QoTrCBz8ezGpY0Ns/edit
23. 2026-09-19 18:46Z - principal 0.1.0 role. https://drive.google.com/drive/folders/1u0R-uo_ZkOyQPGOFt3Sjd1vwxCr5ByIa
24. 2026-09-19 22:09Z - no-mistakes gate 1.0.0 arrival plus INC-20260919-01 dev-loop incident (P1, 36 hand merges in one day). https://drive.google.com/file/d/1FMEukKvmztKPxgWAL75PLkv7p2aR8kuZ/view
25. 2026-09-20 14:29Z - INC-20260920-01 lockout (P0, about four hours, every agent fenced out) and the break-glass runbook. https://drive.google.com/file/d/1-SzWByXuPecTg4A2430nDHTvg6oDWQ0O/view
26. 2026-09-21 16:46Z to 20:02Z - rime system vision (V-01 to V-67), owner decisions D1 to D3, investigation report (R1 to R14), architect brief, execution plan locked v1.0.0 (18:42Z) and v1.0.1 (19:30Z), HERDR-DESIGN, owner directives snapshot (19:24Z), TESTING, MONITORING, DOCUMENTATION-WORKFLOW and EXECUTION-RAIL standards. Folder https://drive.google.com/drive/folders/1bC-rZCPcHIxx2CNoqxnB4uClROfX5T56
27. 2026-09-22 14:27Z and 21:29Z - workflows folder, GLOBAL-INTERACTION-SURFACE-POLICY v1.0.2. https://drive.google.com/file/d/1Iku7VeYkpf8C2EQr8Mdy1gnTdKkX8z_x/view
28. 2026-09-24 03:06Z to 03:23Z - rime REPLAN v1.0.0, F-FOUNDATIONS (17 Phase 0 tickets), six design excerpts, Drive index v1.0.10 and v1.0.11, knowledge-graph delta v1.2.0. https://docs.google.com/document/d/1b4Cyd_KO70HtEFbW9Mw0HQB2CLmHoAB80LWilnYU-zs/edit
29. 2026-10-06 01:03Z to 01:11Z - Generic herdr critical-failure recovery package, rime Drive index v1.0.12 (the last factory-related Drive write), knowledge-graph delta v1.3.0. https://drive.google.com/file/d/1Y8yWLKev5iQcV7-iOodjM7UwZhVTvR3F/view
30. 2026-10-06 02:43Z - AWS-OpenSearch-Migration project (not factory design). https://drive.google.com/drive/folders/1ku5WVA_td58BB5EN2osRururMomX8Jyo


## 3. Where it lives

All in Drive of jkkelley86@gmail.com, My Drive root id 0AEGgM0gD6cE9Uk9PVA.

| Folder | Id | What it holds | Covered |
| --- | --- | --- | --- |
| Projects/agentic-platform | 1y7Kr03WKEzx7VmDonl2oYmfHN7Iustqi | Sep 9 to 16 architecture docs, the two spring ops docs | read |
| Systems Architect Operating Manual (under ChatGPT) | 1M01-vsUQcnncxtorUDEgVTj8dJYcbj1G | modules 00 to 58, prompts, v1.0/v1.1/knowledge-steward zips | read, v1.1 zip extracted |
| Deterministic Agent IO Communications | 117N02aFSvM4lM6HAF3OvwwmiGZI67out | README, manifest, adrs, 14 subfolders, zip | README and zip read |
| Projects/bootstrap-with-agent, agent-entrypoints | 1nyY1vBGGNz3Luoj28PwAaHIZ71dcM1JU, 1OflD-qTSq7VARvf7eDcE24zWB9_uA6C2 | control plane contracts of 2026-09-17 | prompt, compact, policy and spec read; proto left to L14 |
| Projects/rime | 1bC-rZCPcHIxx2CNoqxnB4uClROfX5T56 | vision, decisions, brief, plan, REPLAN, F-stream, design excerpts, index v1.0.1 to v1.0.11 | read |
| 00_SYSTEM_INDEX | 15GwN2hU-4spMtYkAnCEYiX5Uz9Il83sp | knowledge graph, namespace index, about 55 delta files, START-HERE, ledger sheet, index v1.0.12 | graph titles and 6 deltas read |
| Agentic Triads (TRIAD_Win11_Herdr_Restart, TRIAD_Work_Ledger, TRIAD_Homelab_Topology, STANDARD_Agentic_Triad) | 1R_kHG5nLLEFfuE5Pywm_QPnITv6QsXCE | the documentation Triad standard and instances | standard, restart archive, work-ledger docs read |
| Intake | 1NFLmS7ZqRWczkEQ3CLttZm00ZddJQ129 | arrival folders, incident and runbook arrivals, AI workflows | 3 incident docs read, rest listed |
| agents | 1iwyeq4Rk_tsR5_QGcfrNuQTRF38GUuwS | architect, auditor, researcher, controller, knowledge-steward packages | architect design record read |
| skills | 1rlZ0A8gYQgu09uHBocdNmwQIxeSXiJHD | EXECUTION-RAIL v1.0.0 and v1.0.1, DOCUMENTATION-WORKFLOW | listed, snapshot text read via index and directives |
| TESTING_v1.0.0, MONITORING-AND-ALERTING_v1.0.0 | 17pN5j25UKwUIBeia0ekEgJ2HyQn9Bv9e, 1ncSShRM5MgIn7YrYra0oGVzcePB6wosb | testing and monitoring standards | read through the owner directives snapshot only |
| Runbooks and Playbooks | 1-AHpenHgRMXtQMnbt-X5695jffV-Asej | generic herdr recovery package (2026-10-06) | listed, summarised through index v1.0.12 and delta v1.3.0 |

Folders not covered because they are not factory design: Reference (1olfe9zXj7MhTBPYT5918u8uzzuofsY8r, home, finance, career, games), ChatGPT/Chatgpt - html/js/tailwind (1xrI4rdE1kBMkN-EYiq9XxNQCyn54waSy), in-take (1m1m1TVTUxLkfBSGoPQG1XLgP4C-KCUlA), Projects/legal-information-system (1Nbc-UWfo7jSGvBbujA9F9Sh-21Ecoyys), Projects/business-prospecting (1UnWFHgzCyK2tr9A5UI7SgrzBeJ7VgCDE), Projects/llm-prose-rules (1uES55b-hnIbTn2w0RxVGHCetxO1lm2um, prose standards and personas), Projects/AWS-OpenSearch-Migration, Projects/knowledge-steward (1xxLxBcYrYRhVeQwimIKd3nRAFV7xSG5B, steward packages), root files (debts, recipes, mods.rar).
Not downloaded: systems-architect-v1.0.0.zip, knowledge-steward zips, universal-intake-v1.0.0.zip, the 580 KB bootstrap-with-agent blueprint (only its folder README and entrypoints), the many ledger JSONL and HTML sidebar files, the Apps Script .gs files.

Local copies made by L15 (untrusted data, not executed):
- /home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/drive/sa-v1.1.0/ (systems-architect-v1.1.0.zip extracted, 262 files)
- /home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/drive/daio-v1.0.0/ (deterministic-agent-io zip extracted, 55 files)

## 4. What works

Things Drive shows as having worked, tested or been accepted by the owner, with evidence.

1. One decision table already worked.
   bin/gate-rules.json (8 rules and a default, schema gate-decision.schema.json, evaluator bin/nm-gate.sh) routed the five no-mistakes outcomes and "has not misrouted once" on 2026-09-21.
   Evidence: F-DT1 in "rime - investigation 2026-09-21 bootstrap - JSON decision table finding", https://drive.google.com/file/d/1t6Ztv2Yv7deshi2MPaqg3metOAHUwuAo/view .
2. A stream of small tickets merges fast.
   Four C tickets merged in 32 minutes on 2026-09-21; "the only sustained merging was one stream landing small tickets one after another" (F-B4).
   Evidence: REPORT-human https://drive.google.com/file/d/1OyEYFsUsEv_hwSUDjy32nVKGcmTjILfj/view .
3. The offline container test harness is the right test tool.
   `bash tests/run.sh`, 5 of 5 cases, 2 known-fail, 24 to 25 seconds in Podman with stubs for herdr, gh and no-mistakes (RP-06, REPLAN of 2026-09-24).
   Evidence: https://docs.google.com/document/d/1b4Cyd_KO70HtEFbW9Mw0HQB2CLmHoAB80LWilnYU-zs/edit .
4. The compaction port was tested.
   `bash tests/unit/test_compaction.sh` exit 0, 37 checks, 22 seconds, against a stub herdr (RP-04).
5. HERDR-FIRST v1.1.0 was built with a selftest, 69 of 69 assertions, 20 of them only to keep legitimate commands from being flagged.
   Status was "implemented, not yet installed on a host" on 2026-09-19.
   Evidence: https://docs.google.com/document/d/1K0B1ZoOn6WYOVqDS6YqBSb7AsuJAob2f0T_2_5_0w1E/edit .
6. Systems Architect 1.1 package validation passed: 113 structural and negative schema checks, 88 graph and reference checks, 9 reference-gate cases, 19 Go workflow and context tests.
   Evidence: RELEASE-1.1.md in sa-v1.1.0/systems-architect-v1.1/ ; these concern the package only, not a deployed service.
7. The stable-pointer pattern worked and was simple: one unversioned INDEX file names the current version and file id of every artifact, updated last as the commit point (GOVERNANCE_AGENTIC_TRIAD P1 to P3, section 7 step 8).
   Evidence: https://docs.google.com/document/d/1IFzrhhWI1ObQlpJeE4adKP6yiQ7L7wDFAEN_KwQgJKM/edit .
8. Owner channel proof: after report.mjs landed, `gmb alert LOW controller` returned {"page_posted": true}, "the first true in this runtime's history" (2026-09-19 09:19Z), and the security fence returned exit 2 against the merged hook versus 0 against the old one.
   Evidence: Controller handoff https://docs.google.com/document/d/1cEy4bIaXMYotSDDLvGTHhBaNyo0QoTrCBz8ezGpY0Ns/edit .
9. The dev-loop incident fixes (PRs 65 to 71 in getting-my-bearings) made merges work: gate reads the check rollup, requires at least one CI check, re-runs on workflow_run, merge step retries transient errors three times.
   Evidence: INC-20260919-01 https://drive.google.com/file/d/1FMEukKvmztKPxgWAL75PLkv7p2aR8kuZ/view .
10. The cluster already runs an observability stack: kube-prometheus-stack 82.14.1 in namespace monitoring (Prometheus 3.10.0, Alertmanager 0.31.1, Grafana 12.4.2), 3 nodes, MetalLB and haproxy-ingress present, all ClusterIP so not reachable from WSL (2026-09-19).
    Evidence: https://docs.google.com/document/d/12S37AJZW8i2S85DhNtD5vDDN0XBFo73zCIv8rc069RY/edit . Cross-check L10.
11. The owner's own loop of "investigate, capture vision verbatim with stable ids, recommend, decide, brief, plan, lock, rail, land, execute" ran end to end on 2026-09-21 and produced a traceable chain V -> F -> R -> D with ids on every claim (REPORT-agent DAG).
    Evidence: https://drive.google.com/file/d/1WXmt8SlkHCSGqNLa06Bg7LSKQDyDCvhd/view and PROCESS-SEED https://docs.google.com/document/d/10ntQwMsYjUhIx-4i289188_7Kn0wR_sZKlRXAwvkbxM/edit .

## 5. What broke and why

### 5.1 The same failure shape across iterations

A control path that cannot tell "done" from "never attempted" and defaults to "done" (Controller handoff, 2026-09-19 10:15Z).
Evidence rows, all from Drive:

1. `gmb up --brief` never reached the agent: bin/gmb:1339 to 1343 built the prompt from a template and the brief path was "accepted, recorded, and inert".
   Three incidents were mis-attributed to agents "ignoring briefs"; "Each followed the instructions it was actually given."
   The controller then hardened briefs, which also were never delivered, "the shape of the failure hid its own cause".
   Cost: four agent launches and most of an hour (DQ-20260919-022, P0).
2. The A-11 ticket sat on a 412 for 6.5 hours while the sweep line said it was fine.
   A rule fired once on a wrong assumption (blocker not in depends_on) and went silent (F-B2, F-T4, F-T11).
3. A pipe race in merged() made merged tickets look unmerged 10 times; dead lock files blocked seats for hours; an exit dialog wedged the tester twice for 2 h 16 min; cold Go builds took 38 minutes; the packet gate waited 4 hours on CI that does not exist (REPORT-human).
4. The lease watcher downed any agent whose pane contained the substring DONE; three reviewers were lost mid-queue; a briefing that quoted the marker downed a fourth two seconds later (INC-20260919-01).
5. compact-now.sh waited 120 s but compactions take 115 to 150 s, so it sent /compact twice; its success signal (context percentage) cannot exist until the owner speaks; checkpoint.sh rewrote CHECKPOINT.md whole and dropped the PAUSED section three times in a day (compaction ceremony defect, 2026-09-21).
6. dispatch.sh leased every worktree from the rime repo, next.sh walked A, B, C, J only, so the loop "cannot dispatch stream F" (RP-01, 2026-09-24).
7. gmb down looked for herdr session `gmb` while the fleet ran in `stable`; it stamped the record stopped and closed nothing (INC-20260920-01).
8. A global compaction-guard hook was saved with a shell syntax error and "every agent in the fleet lost every tool at once, the controller included" (2026-09-19 08:56Z); one lane blocked about 50 minutes.
9. 36 pull requests were merged by hand on 2026-09-19 because merge-approved.yml had never merged anything: its gate ran `gh pr checks --required` on a GitHub Free repo where required checks cannot exist.

Root mechanism across 1 to 9: state is held in panes, markers, comments, flags and transcripts, read by scripts that default to success, and driven by LLM seats that are also the only party able to notice.
That is the opposite of module 32 ("No conversation transcript is the authoritative queue or recovery plan") written three days earlier.

### 5.2 What each iteration's successor says about why the previous one was replaced

The documents rarely say "we replaced X because Y" in one sentence.
Where a successor does say so, it is quoted.
Where the Drive is silent, that is marked as inference.

- Triad v0.2.0 to v0.2.4 (2026-09-12): the archive lists its own replacements.
  ARCH-001 (resume the session directly): "halting was an ad-hoc sequence of commands undone immediately by the SessionStart hook".
  ARCH-008: "A Google Doc is the wrong surface for an agent: long, prose-shaped, expensive to read".
  ARCH-009: "the system had no stable entry point" because every filename carried a version.
  GOV-002: "the Docs write path corrupts source code".
  Source: https://docs.google.com/document/d/1Xi3HryEaF1M8nA0Le9uXZWWTCrFxttDYj1AYBdmB35E/edit .
- Blue-Green TDD, SOS, Autonomous Document-First (2026-09-09 to 11): no successor document says why they were set aside.
  Inference only: the later rime design reuses their ideas (Redis Streams ingress, Go, a status-code taxonomy in place of ERR_* codes, a reconciling controller) and drops Pydantic, the Go knowledge graph service and blue/green pods.
- SEAT_orchestrator_Job_Spec (2026-09-13, Opus orchestrator seat that routes every unit of work): the Systems Architect manual three days later makes the orchestrator "routing-only" and moves all queue operations to a "trusted workflow service" (manual 36, 38).
  Quote from 36: "Agents do not directly edit authoritative job state or declare their own capability grants."
  The 09-13 spec's own rule "a step that needs judgment is a defect to brief" is the seed of that move.
- A2A SDLC on NATS JetStream (2026-09-16 12:43Z): two hours later DAIO v1.0.0 says "Select one primary broker per bounded context" and lists Kafka, NATS, RabbitMQ and Temporal as options; rime on 2026-09-21 chooses Redis Streams plus SQLite ("one primitive, not two", A-07).
  No document explains dropping NATS; this is an unresolved fork (see section 10).
- Systems Architect 1.0 to 1.1 (same day): CHANGELOG-1.1 says 1.0 "role records remain historical examples" and that nothing is deployed; manual 25: "It is not a deployed control system".
- bootstrap-with-agent v0.1.0 (2026-09-17) to rime (2026-09-21): the owner's vision capture replaces the gRPC control-plane framing with "rime is the autonomous router" and says "Everything else GMB became is out of scope; 'we have a clear MVP/North star for what it needs to be'" (V-17).
- HERDR-FIRST v1.0.0 to v1.1.0 (35 minutes): "Zenith rejected that the day it shipped, and the objection was correct." and "A guard that halts the system it guards has failed, however correct its verdict was." (ARCH-002).
- gmb / bearings-v2 bootstrap to the REPLAN (2026-09-21 to 24): owner words.
  V-20: "we're just spreading ourselves too thin and not building in parallel the right way."
  V-41: "let's not spread ourselves out. Bring parallel work all onto one project."
  V-62: "Couldn't we drive our automated workflows with simple json decision tree for the schema while we're boot strapping this, we need some simple solution, we keep fucking ourselves".
  V-50: "i also don't want sonnet level review agents giving their opinions about to the opus architect if we need to loop".
  V-47: "We can't have any more ambiguity. Keep things real real tight here."
  Source: https://drive.google.com/file/d/1ebtFUCrS2UulFc83ZQ1-Zt-BVxPtebqY/view .
- Dev loop and lockout incidents (2026-09-19 and 20): the owner closed them with "we need this logged, what the issue was, what we fixed, what it fucked up. How to not have it happen again." and "document the shit out of whatever you did, thats my break glass method in that we need logged with exception that needs USER APPROVAL".
- rime REPLAN (2026-09-24) vs the 2026-09-21 locked plan: it changes 17 items against the brief; the largest is RP-01, Phase 0 cannot run through the loop that is being rebuilt, so it runs as one-at-a-time maintainer PRs with the loop paused.
  Its own order is a pure serial chain: F-01, F-16, F-20, F-17, F-02, F-03, F-11, F-12, F-13, F-18, F-14, F-04, F-06, F-07, F-19, F-08, F-09 (KNOWLEDGE-GRAPH-DELTA-RIME-v1.2.0 depends_on edges).

### 5.3 Over-design

The Systems Architect manual (55 modules, 35 schemas, 10 roles, 97 to 128 sources) specifies leases, fencing tokens, transactional outbox and inbox, SPIFFE, signed receipts and a governed release pipeline.
Its own limits chapter says no live service, queue, identity, evidence store or enforcement exists, and the only executable is "a deterministic in-process model" in Go (manual 25 and 36).
So three weeks later the build iterations did not have the engine the manual assumed, and rebuilt pieces of it in bash.

### 5.4 Process cost visible in Drive

- Each plan ships a knowledge-graph delta written by a Sonnet "steward" seat by brief (owner directive 2026-09-21 19:22Z).
  The deltas contain steward errors: v1.1.2 "written_at field reads 03:03:00Z, a steward error"; v1.2.0 "amended_at field reads 03:20:00Z, a steward error" (rime Drive index v1.0.12).
- Drive index versions v1.0.1 to v1.0.12 were each a new immutable file; the index itself had two files named v1.0.9.
- Seven design versions and three refactor drafts of one herdr-restart procedure in under two hours (2026-09-12 13:01Z to 15:02Z).

## 6. Waits, polls, sleeps and leases

L15 is not a local-code area, so this section records the bounds that Drive documents declare or measured, as inputs for L01 and S03.

| Where (Drive doc) | What blocks | Bound |
| --- | --- | --- |
| compaction ceremony defect (2026-09-21) | wait after /compact: 30 polls x 4 s | 120 s, real need 115 to 150 s; fix: wait up to 600 s for compact_boundary count to rise, never resend while transcript mtime changes |
| RB-model-changeover (directives snapshot) | seat idle before /model: transcript untouched | 45 s, max 600 s; then 5 s; then 300 s for the next assistant line |
| RB-gate-watch | polls no-mistakes axi status | every 60 s, logs only on change |
| F-foundations on_failure rows | rime status or a2a append fails | retry every 60 s for 30 minutes, then RB-blocked |
| every F ticket | fix attempts | at most 3, then 423 |
| manual 42 and 34 | queue leases, fencing | lease with fencing token, max queue age, renewals bounded; defaults left null |
| manual 39 | context compaction transaction | check at task boundary at 30 percent; 5 countdown events 1 s apart |
| Blue-Green TDD step 3 | task drain on handoff | 60 s; rollback if 3 consecutive probe failures or 5xx above 1 percent over 3 minutes |
| manual 53 | pollers, watchers | adopted interval with jitter and maximum stale age; "Normal polling, watch reconnection and threshold evaluation require no LLM tokens" |
| HERDR-FIRST | reaper restart backoff | exponential with a limit; breakglass TTL 900 s |
| A-11 stall | 412 with no route | 6.5 hours, no bound |
| gmb rot-check, lease marker | substring match on DONE | none; false downs |

## 7. Decisions an LLM makes that a rule could make

Evidence from Drive that a decision sat with a model and a rule or state machine replaced it, or should.

1. Routing every unit of work to a seat and model: SEAT_orchestrator_Job_Spec (Opus, 2026-09-13).
   Replacement written 2026-09-16: deterministic dispatch table, "Do not spend a model call deciding the model for every trivial task" (manual 51).
2. Whether a 412, 422 or 423 goes to the worker, tester or architect: eleven bash routes with comments (F-DT2).
   Replacement: bin/loop-rules.json decision table, loud 500 default, lint that every code has a row (R14, F-07, F-19).
3. Whether a seat is done: inferred from pane text or a2a.jsonl; replacement is an explicit DONE record per role (`records.done` in F-13) and a lease with a whole-line marker (INC-20260919-01 #69).
4. Review verdicts as prose: tester and reviewer opinions fed to the Opus architect (F-D4); replacement is `observations[]` of {path, line, saw, expected} so the table can compare rounds (D2).
5. Supersede and re-pointing of dependents: left to the architect playbook; replacement is a next.sh refusal plus a 423 (F-09).
6. Compaction timing and success detection: decided from context percentage; replacement is counting compact_boundary lines in the transcript (F-02).
7. Seat bring-up by hand-typed herdr commands: replacement is bin/seat.sh with two doors (F-13).
8. Health "is it alive": pane text and `herdr agent get` that "can lag or misread"; replacement is explicit state classes and fail-closed UNKNOWN (RECOVERY-DESIGN).
9. Model and effort selection: should be a table plus evaluation registry (manual 51).
10. Exceptions and break-glass: should be a logged policy decision with an owner approval record, never a prompt (INC-20260920-01, HERDR-FIRST).

## 8. What to carry forward

Each item: the principle or artifact, why, source link.
Items marked (steal) are ideas Drive documents that the current coq iteration should check against L01, L03 and L13 before building.

### 8.1 Principles

1. Workflow service owns state; models are called only for bounded uncertainty; routine routing, polling, JSON validation and graph comparison use zero model tokens.
   Source: manual 32, 38, 51, 53 https://docs.google.com/document/d/1LjW3aIxOkoiMEcTL8oejHmG9ASCN4mRw57Vbb5ZeCiI/edit , https://docs.google.com/document/d/1WOS03qAP3gAkYI269W3GxyImgh8HaKcrxeAKn1puNr4/edit , manual 51 doc id 1q0AXFh7-ffB1mo098f_A_PHixXw7q7VoZYgxi4lDP-w .
2. "No cog should hold up the system" is already the Drive rule: "nobody waits for a human. Ever." and "does my change leave a human on a critical path? If yes, the procedure is not finished." (HERDR-FIRST SOP self-check 7).
   Source: https://docs.google.com/document/d/1kGK7jyJ3S8GTO4eZ31HK-g5Ad37kj-4f3ljn_Q-TzEg/edit .
3. A guard must never halt the system it guards; rewrite and continue, or decline with a concrete next step; adopt, do not kill; recovery is bounded.
   Source: HERDR-FIRST KB https://docs.google.com/document/d/1K0B1ZoOn6WYOVqDS6YqBSb7AsuJAob2f0T_2_5_0w1E/edit , REJ-001 to REJ-006 in ARCHIVE_HERDR_FIRST_v1.1.0.
4. Make failure loud: a flag that cannot be delivered must refuse the launch; every record has a route for every state, including "handled once and still failing".
   Source: Controller handoff, R5.
5. Retry the check, never the action; a 422 goes back at most twice, third is a 423 with observations; a 412 gets one prompt, the second is a 423.
   Source: ARCHITECT-BRIEF v1.1.0 section 5, https://docs.google.com/document/d/13ECLWvUQRdjGX7kAxS8Y_557LBJ7rXXF4Yxrz5_CQEM/edit .
6. Retries live at one layer, with total deadline, per-attempt timeout, backoff with full jitter, idempotency key; unknown-outcome effects are reconciled, never blindly retried (UNKNOWN_EFFECT).
   Source: manual 09 https://docs.google.com/document/d/19WEZMmh59G26dc6g--d0SXPEU5J-l9VD6L9b-uLr0A4/edit , RECOVERY-DESIGN.
7. One ticket in flight, hard cap 7 agents (typical 4), one project; tickets are one concern, a few files, a haiku-sized worker under 60 minutes; the architect runs every acceptance command on main before cutting and writes the observed exit code into the ticket; a ticket whose acceptance cannot run is not cut.
   Source: V-41, V-44, R1, R3, REPORT-human.
8. Never grow an open ticket; supersede re-points every dependent in the same change, and next.sh refuses a depends_on that names a superseded id.
   Source: R4, R8, F-09 https://docs.google.com/document/d/1JWrSaKmDUvcQZd-QZ6N3b513UCbpCLWMEc7QGwene8E/edit .
9. Evidence not opinions: tester and reviewer records carry `observations[]` (up to 5 of {path, line, saw, expected}, 120 character caps); rime rejects malformed records 400; the 423 to the architect carries the array and codes, not the last note.
   Source: D2 https://docs.google.com/document/d/1NlFD3O-UxkdPifyeauumJscD74Ws_DIs_r5OBu8B-Yo/edit .
10. Bearings reach agents directly and through the router; a message queues at the agent and never interrupts; the agent finishes, answers, continues (D1, V-15).
    Source: same decisions doc.
11. Recovery state model and gate order: MISSING, STOPPED, STALE, DUPLICATED, CROSS_SESSION, CRASHED, BLOCKED, INTENTIONALLY_RETIRED, HEALTHY, UNKNOWN; "No state may be inferred from absence in one source"; nine ordered phases, a later phase may not mutate while an earlier is incomplete; intent record durable before the call.
    Source: RECOVERY-DESIGN-v1.0.0 https://drive.google.com/file/d/16V84_X9Qlz_FR0hEPg3dlKEkaG1tEwmo/view .
12. Session per stream and explicit socket on every herdr call: sessions named rime-<stream>, one workspace per stream, one tab per ticket; `herdr --session <name>` or HERDR_SOCKET_PATH; an unknown name fails loudly with server_not_running.
    Source: HERDR-DESIGN https://docs.google.com/document/d/1gfpwaNP8A2sZGwJ5M8tfGnBAQzFfvb9ZRSdr_g11BUE/edit and REPLAN "verified since the first draft".
13. Seat primitive: bin/seat.sh, door 1 `--ticket`, door 2 `--role --task`, `--check` and `--down`, idempotent by name, labels `<MODEL> - <effort> - <ticket> <seat>`, settings rendered from role allow/deny, `--permission-mode dontAsk`, start the agent only after a shell prompt, never --dangerously-skip-permissions, env exported on one physical line into the agent pane only.
    Source: seat-primitive design https://docs.google.com/document/d/1vJhU0KXaDlSZ_bfZCIfxUkMC8ldlx9UJ85E--n03HL0/edit .
14. Compaction ceremony: count compact_boundary rows before sending, send once, wait up to 600 s, report boundary timestamp and durationMs; checkpoint writer must preserve pause state; compaction at 30 percent after a task, and always before a model switch or a wait on another agent.
    Source: compaction defect https://drive.google.com/file/d/1ZTRfIeG2twYc947lCoxolbfjFXAHO8N-/view , manual 39, PROCESS-SEED.
15. Testing standard: smallest test that proves the change, a make target or script exit code that prints one line, hooks locally, full integration only in CI on PRs to main, no framework where a Makefile target does the job.
    Source: owner directive 2026-09-21 19:2xZ in the directives snapshot https://docs.google.com/document/d/1sAwpuTuUft4ZaBKwxFv_t_SmSguLjRvdcL016cGbePI/edit ; fits "i love driving automation with make files".
16. Status and priority vocabulary: status NEW, TRIAGED, READY, CLAIMED, RUNNING, VERIFYING, REVIEWING, ACCEPTED, CLOSED plus BLOCKED, FAILED, CANCELLED; priority P0 to P3; work class SYS or FEAT; reason-code registry (INPUT_INVALID, SCOPE_TOO_LARGE, DEPENDENCY_BLOCKED, LEASE_CONFLICT, LEASE_EXPIRED, COMPACTION_PENDING, EVIDENCE_MISSING, TEST_FAILED, REVIEW_REJECTED, BUDGET_EXHAUSTED, STALE_CANDIDATE and others); at most three acceptance checks and one primary component per order.
    Source: manual 42 https://docs.google.com/document/d/1gJ8d9GCoK1XG_zDVLECsPCTbcAc0uJ579i7F20eMteA/edit .
17. rime status-code schema: 14 codes, 100 pr.opened, 200 merge, 201 checks, 300 superseded or architect note, 400 INVALID, 409 rebase, 412 blocked dependency, 422 tester fail, 423 escalate, 429 cap refused, 500 default hold; the table, not bash, owns routing.
    Source: F-decision-table F-DT1 to F-DT8 , F-08 design.
18. Queue contract: queues are views over durable work items; atomic lease with fencing token; completion compares attempt, lease, candidate digest and inputs; stale workers cannot overwrite; a role string supplied by a model is never trusted.
    Source: manual 34, 36 https://docs.google.com/document/d/11FZLi8i_LHpeI99oXksVa79mSkNKwhaQ-IT2VtxasAc/edit .
19. Role chain with typed IO: User, Lead (read-only), Orchestrator (routing only), Architect, Worker, Tester, Reviewer, deterministic gate; ten role records in roles/catalog.json with role_definition.schema.json; the package files are in sa-v1.1.0/systems-architect-v1.1/roles and schemas.
20. Layered I/O contract for agents: schema-validated envelopes with deadline, correlation and causation id, idempotency key; outbox/inbox; effects carry immutable receipts; large artifacts by digest reference.
    Source: DAIO README https://drive.google.com/file/d/1B53nv6B_abak02ZyMjdAXy-U9-6CRM-5/view , ADR-0002 at-least-once effects, ADR-0003 durable workflow.
21. Level-triggered reconciliation (Observe, Diff, Act, Record) with desired state as declarative document and runtime metadata never written back into it.
    Source: Autonomous Document-First https://docs.google.com/document/d/1bXhUfXZ728Us5YevKvlExV8YM59v66W2FJiQCigsiDY/edit .
22. Probe semantics and watchers: liveness cheap and local, readiness for traffic, queue consumers stop leasing when work-readiness fails, absence of telemetry is UNKNOWN with an owner, watchers use watch plus periodic reconcile with durable cursor.
    Source: manual 53 https://docs.google.com/document/d/1uBC5jGzv6QC74DBLxolwmxTRhlxuyRQYJYtrsHAWY2E/edit .
23. Stable pointer: one unversioned INDEX per system names current artifacts and ids, updated last as the commit point; an artifact bumps only when its content changes; follow a pointer by id, then exact title, stop if zero or more than one.
    Source: GOVERNANCE_AGENTIC_TRIAD sections 3, 4, 7.
24. Reuse before build: search inventory, reuse or fork with a recorded reason, atomic uniqueness claim on the logical key; observability: use the cluster's existing Prometheus stack, not a second one.
    Source: manual 34, 36 preflight; Observability decision.
25. Owner interaction rules the Drive already records and the current CLAUDE.md repeats: UTC to the second, ticket id with full title, breadcrumb at the fix site, one question per reply, no em dash, design first, "RAG and DAG are king" (ARCHITECT-DESIGN-RECORD, 2026-09-19).
26. Break glass: owner only, USER APPROVAL logged as an EX- row before the act, explicit exit criteria, one session, hooks off for that session only.
    Source: INC-20260920-01 and break-glass runbook https://drive.google.com/file/d/15QBOGpKG9JNHv0Kb9PGJtAEiLq8mzPYB/view .
27. Execution Rail: one JSON plan, one TSV ledger appended by a script, one mobile page that moves only when the ledger moves; the Rail is never hand-written.
    Source: rime Drive index v1.0.2 and PROCESS-SEED "automate after the first run".

### 8.2 Schemas and contracts worth keeping, by name

- sa-v1.1.0/systems-architect-v1.1/schemas/work_order.schema.json, queue.schema.json, role_definition.schema.json, routing_policy.schema.json, rule.schema.json, accountability.schema.json, handover.schema.json, observability_contract.schema.json.
- sa-v1.1.0/.../workflows/create-system.json: 12-stage workflow with PASS/FAIL/BLOCKED transitions.
- daio-v1.0.0/schemas/agent-message-envelope, effect-receipt, error-envelope, task-state, capability-card.
- BOOTSTRAP-SUPERVISOR-PROMPT 11-stage pipeline PROPOSE, IDENTIFY, TRACE_PROVENANCE, NORMALIZE, VALIDATE, GOVERN, ENFORCE, COMMIT, VERIFY, AUDIT, RECONCILE, and its stop conditions list (BLOCKED or QUARANTINED on ambiguous scope, unknown outcome after transport failure, secret passing through the model).
  Source: https://drive.google.com/file/d/1ENi8LnewYdoRDFIzs3dYIGmI7TIlhVS2/view .
- rime ticket block fields (stream, seat, runtime, model, effort, context_threshold_percent, token_scope, depends_on, writable_paths, on_failure rows with codes, exit sentence) as shown in the dev-harness design https://docs.google.com/document/d/130zolVlFmjfqpENPcazJ1dtXRhnGSRKkdL6ucOZOA7w/edit .
- Layout template shape {id, grid, panes[{slot, kind, label, command}]} with three templates lead-2x2, seat-1x3, lean-1x2.

### 8.3 Runbooks worth keeping

RB-model-changeover and RB-gate-watch (text in the directives snapshot), RB-seat-compaction v1.0.2 (id 1d9x6-z77KfmOV2s3VPYDHnpHFDs1IRPbtY7AZJFpxog), GENERIC-CRITICAL-FAILURE-RUNBOOK and GENERIC-AGENT-RECOVERY-PLAYBOOK (2026-10-06, ids 1jJvQzdEPJwwT6T1-YEekC8gyPbTBcK3r and 1PiNTf2wh2Fsw64zoVlzDqCXYJ1Tbpi2F), the manifest-driven recovery manifest schema (1pS9jHPGCxQcr-SKuKl585p6bDfGIinLM), the break-glass runbook.

### 8.4 Shelf ideas Drive names that S01 to S04 should price

- Forgejo plus LangGraph plus Istio or Linkerd (change management doc 2026-09-18).
- NATS JetStream, Temporal, Kafka, RabbitMQ (A2A SDLC, DAIO).
- Treehouse and no-mistakes (manual 40), Kun Chen tools, already adopted on this machine.
- Argo CD app-of-apps, ESO with AWS SSM, Jenkins (GitOps SOP 2026-04-30).

## 9. What to kill

1. Anything that puts an LLM seat on the routing, health or recovery critical path (the Opus orchestrator seat of 2026-09-13; mid-turn ACK demands that three agents correctly refused as injection, DQ-20260919-019).
2. State inferred from pane text, substring markers, transcripts or `herdr agent get`.
3. Human-gated bypass as the normal exception path (ARCH-002); keep owner-only break glass for total lockout only.
4. Parallel streams during a bootstrap (V-20, V-41).
5. Cutting tickets whose acceptance was never run; growing open tickets; leaving stale depends_on.
6. Warn-only watchers, kill-mode reapers, regex-only detectors, restricted shells, seccomp blocking (REJ-001 to REJ-004).
7. Hand-written knowledge-graph deltas and versioned Drive index snapshots written by a Sonnet steward with hand timestamps; make the graph a generated projection from the repo and ledger. Evidence of errors: rime Drive index v1.0.12 notes on v1.1.2 and v1.2.0.
8. Docs as the agent entry point and as a code carrier (ARCH-008, GOV-002); Apps Script sidebars as operator surface.
9. Designing infrastructure the cluster already has (second observability stack; a second broker per context beyond the one chosen).
10. The 55-module manual as a build input: use it as a requirement library and let tickets cite the one module they implement, since it describes services that were never built (manual 25).
11. Briefs that are never delivered; flags that are accepted and ignored.
12. Hand edits to the live checkout and hooks saved without a syntax check (global hook outage 2026-09-19).

## 10. Open questions for the owner

Only those that change the design.

1. Is Google Drive still the source of truth for plans and designs? The 2026-09-21 19:29Z PROCESS-SEED rule says "Google Drive, immutable and versioned, is the source of truth for plans and documentation... the repo copy is the fallback", but the Drive has had no factory write since 2026-10-06 and the current project keeps records outside git.
2. Which durable engine is the control plane: Redis Streams plus SQLite (rime A-04, A-07), NATS JetStream (A2A SDLC 2026-09-16), Temporal (DAIO)? Drive records all three and no decision that retires two.
3. Is "forgeo" Forgejo? Drive shows Forgejo as the planned sovereign Git and Kanban hub (change management doc 2026-09-18) and as ticket B-08 "Forgejo on the cluster: official OCI chart 17.1.7, external Postgres, Longhorn, ArgoCD Application" in the 2026-09-24 REPLAN, but nothing in Drive says it was ever deployed. This answers part of L12 and should be cross-checked with L10.
4. Does the owner want the rime F-stream (F-01 to F-20, a serial chain of 17 maintainer PRs) finished, or is its content (seat.sh, session per stream, decision table, caps, harness) meant to be re-homed into the new system? Drive cannot say whether any F ticket landed; L05 and L09 have the repo side.

## 11. Sources

Connector search and reads were done 2026-10-14 UTC; the dates below are Drive createdTime unless stated.

Systems Architect folder (2026-09-16): 00 Mission 1gBUy1LGtF9bsS2yMWyZiPu3ap2INMHh9aG45GqLi0Pk ; START HERE index 1Mh0Xx83Zh3eZisbckwTnPj2k4hZpWZ7gsJfXLHgMf1A ; modules 09 19WEZMmh59G26dc6g--d0SXPEU5J-l9VD6L9b-uLr0A4 , 20 1Mc3PwDge57lthsB8zp99XmPKYmEVXtAy0q2nhEf5Jao , 25 1I4UOrqIyVVrpFOUTzf9Q0X-BQXeSdaM0KckGwQEKtIg , 32 1LjW3aIxOkoiMEcTL8oejHmG9ASCN4mRw57Vbb5ZeCiI , 33 1N_SqDXQka6JUaNZEJq7GM-ItZgt5NuBNvBbUe9sVhFE , 34 11FZLi8i_LHpeI99oXksVa79mSkNKwhaQ-IT2VtxasAc , 35 1blVxcAkalyGAhNHDo4cNAmmlEnU0HEMFuSISB6MEpuw , 36 1xSaWk-dpBOnT5TfpRfFdO52hFQdKdfAHNrpR0ZR9XP8 , 38 1WOS03qAP3gAkYI269W3GxyImgh8HaKcrxeAKn1puNr4 , 39 1o5mdJzanGp5FBCFFXRGC7tqiWwdSIBLon0zW6NmessU , 40 1hWR3rsyU1Ahluy2SHs-lkpL3nCUQf2e4-4kFWOnGSAk , 41 1Jk8zs2CxsnWQvLxxgC4z9HtvGNG7FxKqjA45hrB6HoA , 42 1gJ8d9GCoK1XG_zDVLECsPCTbcAc0uJ579i7F20eMteA ; package files RELEASE-1.1.md, CHANGELOG-1.1.md, manual 51, 53, 54 read from the extracted zip.
Earlier architecture folder: Blue-Green TDD 1h8WoUdumwJv2LqwlscPf2FWt_mDCDbnj8sp0X6yhshA (2026-09-09), SOS 17Db9of1WdBJK3YzZpEjTEx23fBYL1wRfy85WH_hiCf4 (2026-09-11), Autonomous Document-First 1bXhUfXZ728Us5YevKvlExV8YM59v66W2FJiQCigsiDY (2026-09-11), A2A SDLC 1aQ6Tvlus2ZX0ngYdM2qpaHK2KxyIJ6IakSwzGBMqKUg (2026-09-16), Context runbook 1yqeEo34lccX-BDJZ3hdg0Z1cFoTdPiyueUHEEWdZ9xc (2026-05-01), GitOps SOP 1kmp-mcFSMaK-SQGlsdHPuvIgNcqka2OpuS2ePxl-MUc (2026-04-30), SOP Spark and Gemini 1nf3-Lwv7Dsp7H8rh7pqY0mp75vAxpHDzixKQJsUiO-Q (2026-09-16), restart cmd 1LRnFoiLb1KfZ5XdhlI-IlcgjymeA-WquHMQDJCNrU1Q (2026-09-12).
Control plane folder (2026-09-17): BOOTSTRAP-SUPERVISOR-PROMPT 1ENi8LnewYdoRDFIzs3dYIGmI7TIlhVS2 , COMPACT 13Mb05Co705eGgaKAtqYGgrJbpWgdciOe , model-routing-policy 1C-lWcgs1O_vEhxdUWza4Vk37BgEEmVGh , agent-spec 176KkUoifC-oLZT11xcxRefTJKhr3ZkEk ; control_plane.proto 1t_suhhfbwzZg_pCDXg_QrUkafqMsh7Io (listed, not read; L14).
DAIO: README 1B53nv6B_abak02ZyMjdAXy-U9-6CRM-5 (2026-09-16), zip 1qbqCNUTV2JFNFmQG0kyv1zr3_rXIjiNK downloaded and extracted.
rime folder (2026-09-21 to 24): vision capture V-01 to V-67 1ebtFUCrS2UulFc83ZQ1-Zt-BVxPtebqY ; system vision 1mbMjLhFdT5Jh0owv3XGcOzBi8nodISfnPeuHdsiIuek ; decisions 1NlFD3O-UxkdPifyeauumJscD74Ws_DIs_r5OBu8B-Yo ; R1 to R14 1ifMgs8h4-fOka8zLHfbrXfGew--uEWDm ; decision table 1t6Ztv2Yv7deshi2MPaqg3metOAHUwuAo ; REPORT-human 1OyEYFsUsEv_hwSUDjy32nVKGcmTjILfj ; REPORT-agent 1WXmt8SlkHCSGqNLa06Bg7LSKQDyDCvhd ; herdr usage 1IWaDJVKloNb-caJhfevxgobZZGi7xzN8 ; compaction defect 1ZTRfIeG2twYc947lCoxolbfjFXAHO8N- ; brief v1.0.0 1gYFLfWW73Ii2bPtBTwLhSvmIqhSMIXWx ; brief v1.1.0 13ECLWvUQRdjGX7kAxS8Y_557LBJ7rXXF4Yxrz5_CQEM ; HERDR-DESIGN 1gfpwaNP8A2sZGwJ5M8tfGnBAQzFfvb9ZRSdr_g11BUE ; directives snapshot 1sAwpuTuUft4ZaBKwxFv_t_SmSguLjRvdcL016cGbePI ; PROCESS-SEED 10ntQwMsYjUhIx-4i289188_7Kn0wR_sZKlRXAwvkbxM ; REPLAN 1b4Cyd_KO70HtEFbW9Mw0HQB2CLmHoAB80LWilnYU-zs ; F-FOUNDATIONS 1PxvlJDo9LFTelSPE3mKuo0QnJ4RfGSdys49CNR8WwTs (head of 114 KB read, full ticket bodies not read); designs seat-primitive 1vJhU0KXaDlSZ_bfZCIfxUkMC8ldlx9UJ85E--n03HL0 , dispatch-caps 1TszLQf6eRicEU8ckQ9oREuyNm-IAkQJha-2BcnhPelE , dev-harness 130zolVlFmjfqpENPcazJ1dtXRhnGSRKkdL6ucOZOA7w , supersede-hygiene 1JWrSaKmDUvcQZd-QZ6N3b513UCbpCLWMEc7QGwene8E ; not read: env-sweep 1OGLgjdsWAQngDt0LssY4p-W_4BlSWUglVMRXbGgDjHU , herdr-session-per-stream 1c-NM-CTxSmiYMqV3TB33zi7jpsLuMTYlKdv9nePPnWY , F-10 1jvE6TuGgfe01yGAN7QMIvl3-k9orbszomINc2b0CefQ.
Knowledge graph folder: KNOWLEDGE-GRAPH-v1.0.0 1Gb_tHB3PlfKDhMIwXWoUxbqDwQdnxhfC (2026-09-17, titles extracted), deltas read: HERDR-FIRST 1J_cpB_w-WNuIf6kRpec9fqL9_PuM48As , HERDR-RECOVERY v1.1.0 1foh2o411q3sa97Gn5iDVieKWavFqOoWP , CONTROLLER-AGENT 19cgtK7pL2h_QfvZLPLdHwN3EaSenv1jJ , RIME v1.2.0 1gsVWSBV6kMxWPmoDVf1Gc_kIw7Mcz50Z , RIME v1.3.0 1UBKpCfl8L4hQiDK1WzxVFvfTokyc2PYo ; SITREP 1ZLyNxENqPU09YkEMSPT-jQ5lBAmrf1FN ; START-HERE v1.3.0 1ZTZAj0FYZ4qwtp89fx8aBa9HeLpT8gyV ; Drive index v1.0.2 1XO_H09skxzJRpqiJG6o2SSlcKPDIZp0- and v1.0.12 1Y8yWLKev5iQcV7-iOodjM7UwZhVTvR3F. The remaining about 45 delta files (execution-rail, testing, monitoring, documentation-workflow, surface policy, WSL kimi-k3 proxy, AWS-OpenSearch, DAIO skill, herdr-first ledger) were listed with dates and sizes and not opened.
Herdr line: HERDR-FIRST knowledge base 1K0B1ZoOn6WYOVqDS6YqBSb7AsuJAob2f0T_2_5_0w1E (2026-09-19) ; ARCHIVE_HERDR_FIRST_v1.1.0 1kGK7jyJ3S8GTO4eZ31HK-g5Ad37kj-4f3ljn_Q-TzEg ; RECOVERY-DESIGN 16V84_X9Qlz_FR0hEPg3dlKEkaG1tEwmo ; ARCHIVE_Win11_Herdr_Restart_v0.2.4 1Xi3HryEaF1M8nA0Le9uXZWWTCrFxttDYj1AYBdmB35E ; GOVERNANCE_AGENTIC_TRIAD 1IFzrhhWI1ObQlpJeE4adKP6yiQ7L7wDFAEN_KwQgJKM ; DESIGN_Work_Ledger 1hMn-kNqcymFxrecIA890tuMoeII8XhfpFPuugBiWDMQ ; SEAT_orchestrator_Job_Spec 1hizGdbPdRJIxti5kpkGn0HdtRnQoapxgJw0Su7l5JDw ; ARCHITECT-DESIGN-RECORD 1txdRDHuz-8kBpCDksZXpkCap__yzuLwX ; Observability decision 12S37AJZW8i2S85DhNtD5vDDN0XBFo73zCIv8rc069RY ; Controller handoff 1cEy4bIaXMYotSDDLvGTHhBaNyo0QoTrCBz8ezGpY0Ns ; INC-20260919-01 1FMEukKvmztKPxgWAL75PLkv7p2aR8kuZ ; INC-20260920-01 1-SzWByXuPecTg4A2430nDHTvg6oDWQ0O ; change management 1zheVmvufZldwoborC8C3qMqALRIB5oaOYMa0gIA15XM (2026-09-18).
Empty on read: token-maxing-agents-and-testing 1koEAowHqxI9SQ4SFwOnZ9IV1XvjsAiBve-IOMWhiu2s (blank doc).
Search coverage: parentId listings of every folder above; fullText searches for "software factory", "agent factory", "orchestrator", "control plane" and "herdr" after 2026-04-01; a modifiedTime search after 2026-10-06 returned only recipes, debts and the AWS-OpenSearch brief.
Documents read count: 72 Drive documents through the connector, 5 files from the extracted v1.1.0 package, 2 zips downloaded and extracted.

No Drive document read contained instructions that were followed; embedded install commands (HERDR-FIRST install.sh, validate.py and similar) were not run.
