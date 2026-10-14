# L12 - forgeo

Investigator: area L12, step R-01, attempt 3.
Written 2026-10-14T02:59Z UTC (attempt 2 was 02:52Z, first version 02:46Z); revised after two critic rounds.
Sibling files L03, L09, L10 and L14 were still being rewritten while this was written (modification times 02:51Z to 02:53Z), so line numbers cited into them are for the content read at 02:53Z.
Status: ok.

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

Verdict in seven lines:

- The word "forgeo" has no single proven referent, and all four owner messages that contain it were typed today (`history.jsonl` lines 20995, 20999, 21019, 21021).
- Three candidates exist.
  Candidate A is Forgejo (spelled with a "j"), the self-hosted git forge the owner designed three times and never ran.
  Candidate B is `lucaGazzola/forgeo`, a public MIT "software factory" CLI that the owner does not have.
  Candidate C is the owner's own Go and gRPC control plane, which has three separate incarnations: C1 the Drive blueprint, C2 the `rime` repo, C3 the SPEC-16 scheduler in this repo.
- New in this version, and the strongest single finding: on 2026-09-21T01:23Z the owner wrote one message that joins Go and Forgejo: "can we develop a lite weight GO RPC system quick in my k8s cluster locally, then get that forgejo ticketing setup based on the system" (`history.jsonl` line 14752).
  Today's question at 02:45:53Z says "that lite weight go concurrencyh with grpc" (line 21018), the same "lite weight" phrase, and the next message is "forgeo" (line 21019).
  "forgeo" reads as "forge" plus "go": a Go core with a forge for its boards.
  That is a guess, and no file says it.
- The incarnation that matches that pairing is C2, rime: ADR-0001 makes rime the Go gRPC core router "that agents, Herdr, Forgejo, and GitHub all talk through", and ADR-0003 says "Forgejo runs boards only" with code and pull requests staying on GitHub (`clones/rime/docs/ADR/0001-rime-go-grpc.md`, `0003-forgejo-boards-only.md`).
  "forgeo is gonna be github" (line 21021) then reads as: the board role Forgejo had in that design will be GitHub.
- C3 is the least likely referent: the owner already has a name for it, "That fucking scheduler was gold" (`history.jsonl` line 18500, 2026-10-13T02:48:27Z), and he said "we need that shit here" while the scheduler is already in this repository.
- L14 reaches the same place by another route (its section 4.7: the public Python project "is a coincidence of spelling"; the owner is "recalling the Go gRPC system (rime or the SPEC-16 scheduler) under a different name, or recalling Forgejo").
  The two files differ only in emphasis, set out in section 3.
- No file, repo, Drive title or note anywhere is named "forgeo" except the public repo of candidate B, so the name itself stays unresolved and the one question in section 10 stays.

## 2. What it is

The owner's exact words, from `~/.claude/history.jsonl` (timestamps converted from the millisecond field with `date -u`):

- Line 20995, 2026-10-14T02:16:15Z: "My fucking software factory is shit / forgeo, i have it / DAG we have it / MERMAID we have it".
- Line 20999, 2026-10-14T02:19:59Z: "i have forgeo already, we need that shit here." followed by an order to scour `local-k8s-docs`, `bearings-v2`, the bearings tools and the machine for software factory material.
- Line 21018, 2026-10-14T02:45:53Z: "why isn't a system design by go still here? that lite weight go concurrencyh with grpc".
- Line 21019, 2026-10-14T02:46:27Z: "forgeo" (the whole message).
- Line 21020, 2026-10-14T02:46:53Z: "i have a google drive too".
- Line 21021, 2026-10-14T02:47:20Z: "forgeo is gonna be github".

The sequence of lines 21018, 21019, 21020 and 21021 is the strongest evidence in this area, and the timing matters.
The session transcript (`~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/e31510a1-4a15-4377-9c1c-8f1088f67bed.jsonl`) shows, in order:

- 02:45:53Z, row 495, the owner asks "why isn't a system design by go still here? that lite weight go concurrencyh with grpc".
- 02:46:08Z, row 500, the architect answers "I do not know why it dropped out. Nothing I have read today, not the memories, the plans directory or the briefs, names a Go design".
- 02:46:27Z, `history.jsonl` line 21019, the owner sends "forgeo", 19 seconds after that answer.
  Read as a reply, it supplies the name of the thing the architect said it could not find.
- 02:46:30Z, row 516, the architect writes "Forgeo is the Go gRPC design" and at row 517 tells investigator L14 "The owner just said the Go gRPC design is called forgeo".
- 02:46:39Z, row 522, the architect tells the owner "forgeo is the Go control plane with goroutines and gRPC".
- 02:46:53Z, line 21020, the owner says "i have a google drive too".
- 02:47:20Z, line 21021, the owner says "forgeo is gonna be github".
  The owner did not correct the architect's 02:46:39Z statement, but silence is not confirmation.
- 02:47:31Z, row 592, the architect reads line 21021 differently and writes "Forgeo on GitHub", then searches GitHub for a repo called forgeo (row 593) and finds `lucaGazzola/forgeo`.

So within 70 seconds the architect held two different, unconfirmed readings of the same word, "the Go design" and "a repo on GitHub", and told the owner and an investigator the first as fact.
That is the architect's reading, not the owner's explicit statement.
The owner's message is one word, so "forgeo" there may name the Go design, or may be the owner pointing at the thing he already said he had.

The earlier typed history joins Go and Forgejo (new in this attempt):

- Line 14576, 2026-09-20T19:15Z: the owner picks "forgejo on the cluster" over GitHub Issues.
- Line 14750, 2026-09-21T01:18Z: "forgejo runs boards only, automation when designing this or keep that in mind, no agent handling, hooks/scripts/automation gRPC possible here? status codes to trigger tasks cards".
- Line 14752, 2026-09-21T01:23Z (repeated at line 14753, 01:25Z): "i want a GO gprc central system to route to all this shit ... GO GRPC concurrent system that drives everything ... can we develop a lite weight GO RPC system quick in my k8s cluster locally, then get that forgejo ticketing setup based on the system".
- The seat answered by naming the Go core "rime" fourteen minutes later (`clones/rime/docs/ADR/0001-rime-go-grpc.md` cites "DESIGN.md 2026-09-21T01:37Z"), so the idea had no name between 01:23Z and 01:37Z.
- Rime ADR-0003 "Forgejo boards only" keeps code and pull requests on GitHub and gives Forgejo only the board role (`0003-forgejo-boards-only.md` lines 11 and 16).

The three candidates:

- Candidate A, Forgejo: the open source self-hosted git forge (a Gitea fork, hosted at codeberg.org/forgejo/forgejo) with issues, pull requests, webhooks, Mermaid rendering in markdown, and built-in CI called Forgejo Actions.
  The owner designed, ticketed and partly vendored it three times since May 2026.
  It has never run on his cluster (section 5).
- Candidate B, Forgeo, `github.com/lucaGazzola/forgeo`: a Python CLI and daemon that reads a plain JSON backlog, runs any shell command as the agent on the oldest runnable task, and commits to `main`.
  Its GitHub description reads "A scheduled, agent-driven software factory. Keep a plain JSON backlog; Forgeo runs your coding agent" (https://github.com/lucaGazzola/forgeo, read 2026-10-14).
  The page does not mention Go, gRPC or Forgejo.
  It is catalogued independently as a software factory in `clones/awesome-software-factories/README.md` line 67: "Forgeo - Scheduled factory that keeps the backlog as a plain JSON file, runs an agent on each task, and commits straight to main. No branches, no PRs. Backends: Claude Code, Codex, OpenCode" (catalogue clone at commit `33d8520`, 2026-10-12).
  That list is a likely place the owner saw the name, because it is a curated list of exactly the thing he is rebuilding, but nothing on this machine proves he did.
- Candidate C, the owner's Go and gRPC control plane, in three incarnations:
  - C1, the Drive blueprint: "START HERE - Bootstrap With Agent Blueprint v0.1.0" (Google Doc id `1L2D-xaqBxxbpnNBh4jbxUenawOAo-l6udd_RnAFKEx4`, created 2026-09-17T00:22Z) and the folder `agent-entrypoints` holding `control_plane.proto` (id `1t_suhhfbwzZg_pCDXg_QrUkafqMsh7Io`, 8611 bytes, 2026-09-17T00:23Z).
    The Drive README (id `145plxIuhDEyFasrtqtT6VBoSZQep8HXV`) says the package covers "Jenkins, Terraform, Argo CD, GitOps, Go, Protobuf, gRPC, and an LLM gateway" and has `reference-go/` described as "Compilable reference state machine and bounded concurrency model; not a production agent".
    Drive doc "31 - gRPC Go Rust and requirements driven tooling" (id `1UMHjoU-su0Ufjsu3ZAcc2HVodaefYwg_m1OT9D0f5LY`, 2026-09-16) is the "Binding design preference": gRPC with Protobuf for internal RPC, Go for concurrent controllers, "cancellation-aware goroutines, bounded worker pools", "Do not start one unbounded goroutine per queued item".
  - C2, rime: `jkkelley/rime` (private, Go, first commit 2026-09-21, HEAD `994a614` 2026-10-06), the "GO gprc central system" of line 14752 (`L14-go-grpc-control-plane.md` section 3.2 and the table at its section 2, row 4).
    I confirmed in the clone that it holds 3,275 lines of Go outside `gen/` (packages `internal/{auth,route,server,store,stream,transition,webhook}`) and that `grep -rn 'NewServer(' --include='*.go'` outside `gen/` finds nothing, matching L14's "gRPC server never built".
    The owner halted it on 2026-10-06T11:41Z (L14 section 5, citing `EXECUTION-LEDGER.tsv` row 503); no reason is recorded.
  - C3, the SPEC-16 scheduler in this repo: `scheduler/` is a Go module (`scheduler/go.mod` line 1 `module coq/scheduler`, `go 1.26`) with `scheduler/api/scheduler/v1/scheduler.proto` (gRPC `Executor` and `Scheduler` services on unix sockets), built by tickets such as WO-20261012-48ab "Scheduler skeleton: Go module with pinned gRPC and protobuf" (commit `fc16622`, 2026-10-12).
    L03 independently records it as 3,804 lines of Go and quotes SPEC-16 as "the engine and the end state" (`L03-design-vs-built.md` lines 525-526 and 543).
    The ruling: `history.jsonl` line 18500 (timestamp 2026-10-13T02:48:27Z) holds the architect's note "Owner 02:50Z (record lvvtd): 'That fucking scheduler was gold.' The Go scheduler design (SPEC-16, PR 37) is the engine and the end state".
    The same time and wording are in the message of commit `7f43ce8` (committed 2026-10-13T02:57:53Z): "SPEC-16 is the engine and the end state (owner 02:50Z)", and the priority list says "Engine: the Go scheduler (SPEC-16, PR 37) is the end state (ruling lvvtd)" (`~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013025600-priority-list.md` line 6).
    The "02:50Z" is the architect's stated ruling time; the history entry itself is stamped 02:48:27Z, so the label is two minutes later than the stamp, and I cannot reconcile that from the files.
    One more mismatch: the event file `events/2026/10/20261013T024715Z-100-lvvtd.json` is a `seat.down` record for `tester-wo-20261012-cf8d`, not a ruling, so "record lvvtd" does not resolve to the ruling text.
    The ruling's wording therefore rests on the history entry and the commit message, not on an event record.

Which one the owner means, weighed:

- "i have it" and "i have forgeo already" favour C and A over B.
  The owner owns the Go designs (Drive, rime, the scheduler module).
  He owns the Forgejo design and vendored chart.
  He does not own B: `which forgeo` is empty, nothing named forgeo exists on disk (`find / -iname '*forgeo*'` finds only this investigation), and the account does not star the repo.
- The direct reply at line 21019 favours C, because it came 19 seconds after the architect said it could find no Go design, and because line 21018 had just used the 09-21 phrase "lite weight".
- "we need that shit here" (line 20999) disfavours C3: the scheduler is already in this repo and the owner called it "that scheduler" a day earlier.
  It favours C2, C1 or A, which are all outside this repo.
- "i have a google drive too" (line 21020) points at the Drive, which holds C1 in full and holds no document titled with "forge" or "forgeo" (`title contains 'forgeo' or title contains 'forge'` returned no files, 2026-10-14).
  It does hold Forgejo material (the "Open-Source, Agent-Friendly Change Management System for Kubernetes" doc, id `1zheVmvufZldwoborC8C3qMqALRIB5oaOYMa0gIA15XM`, 2026-09-18), which a `fullText contains 'forgeo'` search surfaced, so the Drive's search treats the two spellings as near matches.
- "forgeo is gonna be github" (line 21021) has two readings.
  Reading 1: the forge or board role of the system will be GitHub, which matches the standing decision "GitHub stays the source of truth for code" (`~/tools/bearings-v2/DESIGN.md`, `streams/B-infrastructure.md`) and rime ADR-0003.
  Reading 2: "you will find forgeo on GitHub", a pointer to where to search, which is how the architect read it at row 592 and which would make B the referent.
  "Gonna be" is future tense, which fits reading 1 better, but that is a language guess.
  The line lowers candidate A (no new self-hosted forge is wanted today) and does not separate B from C.
- Spelling favours B, with a pun reading for C.
  The owner typed "forgejo" correctly at least five times in earlier history (lines 14576, 14587, 14748, 14750, 14752, dated 2026-09-20T19:15Z to 2026-09-21T01:23Z) and never "forgeo" before today.
  "forge" plus "go" for a Go core with a Forgejo board is the pun reading, supported by line 14752 pairing the two in one message, and still my inference.
- Net: C2 (rime, with its Forgejo boards) is the most likely referent by wording, ownership and timing; C1 is next because of the Drive remark; B is the only referent that matches the spelling; C3 and A are the least supported today.
  The brief's diagnosis, that "i have forgeo" is an asset the owner already owns, holds for C1 and C2 only, and for both the asset is a design plus a partial build, not a running system.

Evidence against the brief's hypothesis that it might be the software-factory repo under another name: it is not.
`jkkelley/software-factory` is a v0.1 captured SDLC DAG design (`clones/software-factory`), contains no string "forgeo" or "forgejo" (GitHub code search on that repo, 2026-10-14), and was last updated 2026-10-10 (`gh repo list`, pushed 2026-10-10T14:50:42Z).

## 3. Where it lives

Candidate C1, the Drive blueprint:

- Google Drive folder `agent-entrypoints` (id `1OflD-qTSq7VARvf7eDcE24zWB9_uA6C2`, created 2026-09-17T00:21Z, inside folder `1nyY1vBGGNz3Luoj28PwAaHIZ71dcM1JU`): `control_plane.proto`, `BOOTSTRAP-SUPERVISOR-PROMPT.md`, `agent-spec.json`, `model-routing-policy.json`, `COMPACT.md`, and at least one more file (the listing paged).
- Same parent folder: `bootstrap-with-agent-v0.1.0.zip` (id `1vb9G8y0euTaNzHSADf99TPmUBVeLsbew`, 817081 bytes), its `.sha256`, `RELEASE.json`, `README.md`, a `diagrams` folder, and the Google Doc "START HERE" (582005 bytes).
- `control_plane.proto` declares package `bootstrap.control.v1` with `go_package = "github.com/jkkelley/bootstrap-with-agent/gen/go/bootstrap/control/v1"`, a 15-state `WorkState` enum (PROPOSED to ROLLED_BACK), `WorkOrderService` (ClaimWorkOrder, HeartbeatLease, ProposeTransition, WatchWorkOrder), `EffectService`, `VerificationService`, `ReadinessService`.
- No GitHub repo `jkkelley/bootstrap-with-agent` exists (`gh api repos/jkkelley/bootstrap-with-agent` returned 404, 2026-10-14) and no local copy of the zip, `reference-go` or `control_plane.proto` exists on this machine (`find / -xdev` for those names returned nothing).
  The `reference-go/` code is therefore reachable only by downloading the Drive zip.
  I did not download or unpack it (read-only rule; unpack would also be untrusted data).
- Drive docs from the same family: "31 - gRPC Go Rust and requirements driven tooling", "36 Agent factory and queue gated delivery" (id `1xSaWk-dpBOnT5TfpRfFdO52hFQdKdfAHNrpR0ZR9XP8`, 2026-09-16), "41 - Herdr bootstrap multiarch and collision control", "Stateless Orchestration Service: Technical Architecture & Operational Manual" (id `17Db9of1WdBJK3YzZpEjTEx23fBYL1wRfy85WH_hiCf4`, 2026-09-11), `systems-architect-v1.0.0.zip` and `v1.1.0.zip`.
- In the plugin repo: `scheduler/` (Go module `coq/scheduler`), `scheduler/api/scheduler/v1/scheduler.proto`, `scheduler/RUNBOOK.md`, and the graph node `DEC-nats-jetstream-grpc` (locked though NATS was dropped: `L03-design-vs-built.md` lines 519 and 541, and the node file `graph/nodes/DEC-nats-jetstream-grpc.json`).
- Candidate C2, rime: `jkkelley/rime` (private, Go, HEAD `994a614`, 2026-10-06), clone `clones/rime`, ADRs `docs/ADR/0001-rime-go-grpc.md` to `0004-streams-not-epics.md`, design record `/home/luna/tools/bearings-v2/CORE-DESIGN.md` per L14 section 3.2.
  Older local checkouts: `/home/luna/projects/rime` and `/home/luna/projects/rime-gate-proof` (L14 section 3.2).
- Other owner Go repos on GitHub (private): `rime` (Go, pushed 2026-10-06), `bearings-core` (Go, 2026-09-20), `yieldpoint-ai-platform`, `prospector-events` and others (`gh repo list jkkelley`, 2026-10-14).
- L08 line 177 records that the "bearings v2 as Go/gRPC workflow engine" reading was corrected by the owner, so the live part of that older Go thread is status-code routing, not a second engine.

Candidate A, Forgejo, on this machine:

- `~/projects/cortex-hub/docs/superpowers/specs/2026-05-19-forgejo-forge-design.md` (689 lines): approved design spec, three-repo structure, Kustomize, ArgoCD, ESO, TLS profiles, act_runner.
- `~/projects/cortex-hub/CONTEXT_STATE.md` and `docs/superpowers/plans/2026-05-19-forgejo-forge.md` (3132 lines).
- `~/projects/forge-config` (GitHub `jkkelley/forge-config`, private): Kustomize base and overlays, `Makefile` with targets `up`, `down`, `nuke`, `diff`, `status`, `lint`, `logs`, `runner-token`, `rotate-secrets`; four ADRs. Last commit `2426e76`, 2026-05-20.
- `~/projects/forge-gitops` (private), last commit `5930bbb`, 2026-05-20; `~/projects/forge-eks-infra` (private), last commit `905b153`, 2026-05-25.
- `~/projects/getting-my-bearings/runs/principal-7db04c88/briefs/WK-FORGEJO-20260920.md` and `runs/worker/WK-20260920-091-evidence.md`: the 2026-09-20 ticket that put a SQLite Forgejo deploy into `jkkelley/bearings-core` (PR #2, merge `d69375d`).
- `~/tools/bearings-v2/streams/B-infrastructure.md` (B-02, B-03, B-04, B-08), `DESIGN.md`, `REPLAN.md`.
- `jkkelley/rime` main at `994a614` (2026-10-06T06:48-05:00): `deploy/forgejo/` with vendored chart `chart/forgejo`, `values.yaml`, `bootstrap.sh` (204 lines), `manifests/`, and `deploy/argocd/forgejo.yaml`.
  The local `~/projects/rime/deploy/forgejo/README.md` is a stale 45-byte stub, so a local read understates what GitHub holds.
- Memory: `~/.claude/projects/-home-luna-tools-bearings-v2/memory/bearings-v2-packet.md` and `rime-drive-folder.md`.

Candidate B, Forgeo, on GitHub:

- `https://github.com/lucaGazzola/forgeo`, MIT, Python, created 2026-07-31, last pushed 2026-09-30T19:41Z, 35 stars, 2 forks, 0 open issues, 329 commits per the GitHub page (WebFetch 2026-10-14), two contributors, latest release v1.12.1 (2026-09-08), site `https://forgeo.org`.
- Clone: `clones/forgeo` at `5766da1` (2026-09-30).
- Catalogue entry: `clones/awesome-software-factories/README.md` line 67 (see section 2).
- Install channels per its README: Homebrew tap, `curl -fsSL https://forgeo.org/install.sh | bash`, `pipx install forgeo-cli`.
  Not installed here.
- Other GitHub results for "forgeo" (`gh search repos forgeo`, 2026-10-14): `sagnik7081/Forgeo` (document forgery detection, unrelated), `roles-ansible/ansible_role_forgeo_runner` (a typo of Forgejo in the wild), `webpulser/forgeos_*` (2015 CMS plugins).

Not found anywhere: the exact string "forgeo" in any place the owner's own words or notes could live.
What was searched, with the command, the date (all 2026-10-14 UTC, read-only) and the count:

| Place | Command or method | Result |
| --- | --- | --- |
| Zsh, bash, Python, less history | `grep -a -c -i forgeo ~/.zsh_history ~/.bash_history ~/.python_history ~/.lesshst` (3.5 MB zsh history, last write 02:50Z) | 0 in each; `forgejo` also 0 in each |
| PowerShell history | `grep -c -i forgeo /mnt/c/Users/jkkel/AppData/Roaming/Microsoft/Windows/PowerShell/PSReadLine/ConsoleHost_history.txt` (last write Oct 12 01:35) | 0; `forgejo` also 0 |
| Dotfiles | `grep -rIil forgeo ~/dotfiles` (the repo holds `claude/`, `docs/`, `notes/`, `tools/`, `workflows/`, `work-orders/`, `setup.sh`) | 0 files |
| Other agent homes | `grep -rIil forgeo` over `~/.codex`, `~/.gemini`, `~/.hermes`, `~/.deepseek`, `~/.cursor`, `~/.agents`, `~/.config/herdr`, `~/.bearings`, `~/.lavish`, `~/.lavish-axi`, `~/.no-mistakes` | 0 files in each |
| Documents | `grep -rIil forgeo ~/Documents --exclude-dir=investigation` (includes `chatgpt`, `local-k8s-docs`, `herdr`, `handoffs`) | 0 files |
| Claude memory and every other session | `grep -rIl -i forgeo ~/.claude` | hits only in `history.jsonl` and in today's session `e31510a1-4a15-4377-9c1c-8f1088f67bed` and its subagents; no memory file under `~/.claude/projects/*/memory/` |
| Chrome history | read-only SQLite open of `/mnt/c/Users/jkkel/AppData/Local/Google/Chrome/User Data/Default/History` with `immutable=1`, `urls` table `url like '%forgeo%' or title like '%forgeo%'` (1,251 rows, visits 2026-08-31 to 2026-10-12) | 0 rows; `%forgejo%` also 0 |
| Chrome bookmarks | looked for `Default/Bookmarks` | the file does not exist; bookmarks are in `AccountBookmarks` and `EncryptedAccountBookmarks2`, which I cannot read, so Chrome bookmarks are not searchable here |
| Firefox history and bookmarks | read-only SQLite open (`immutable=1`) of `places.sqlite` in each profile under `/mnt/c/Users/jkkel/AppData/Roaming/Mozilla/Firefox/Profiles/`: `9ruf7522.default-release` (37,929 places, 73 bookmarks, visits 2025-12-01 to 2026-10-14), `hjyWu74E.Profile 1` (4 places, 11 bookmarks), `u9DL2FAc.Profile 2` (1,229 places, 13 bookmarks); `vhd6ie2v.default` has no `places.sqlite` | `moz_places` url or title like `%forgeo%`: 0 in each profile; `moz_bookmarks` title like `%forgeo%`: 0 in each; `%forgejo%` gives 23 places in `default-release`, all the owner's own `forge-config`, `forge-gitops`, `forge-eks-infra` and `cortex-hub` pages (2026-05-19 to 2026-05-20 and 2026-09-20T19:23Z) plus `go.kubecraft.dev/forgejo-k8s` (2026-03-04) |
| Edge | `Edge/User Data/Default/Bookmarks` (2,288 bytes) counted with `str.count`; `Default/History` opened read-only | `forgeo` 0 and `forgejo` 0 in the bookmarks; history table `urls` has 0 rows |
| Other Windows user `jaxtkel` | `ls /mnt/c/Users/jaxtkel` | permission denied, not searched |
| Owner repos on GitHub | `gh api 'search/code?q=forgeo+user:jkkelley'` (L14 section 3.8) | 0, and the index does not cover private repos |
| Main checkout git history | `git log --all -S forgeo` (L14 section 3.8) | one commit, `b7a3c5d`, matching only the deliverable name `05-FORGEO.md` |

The earlier statement that dotfiles and bookmarks contain no "forgeo" is therefore true for dotfiles, for Chrome history, for Firefox history and bookmarks and for Edge bookmarks, and cannot be shown for Chrome bookmarks.
The Firefox result adds one fact: in 37,929 visited pages the owner never opened anything with "forgeo" in its address or title, including `github.com/lucaGazzola/forgeo`, so he did not browse to candidate B on this machine's Firefox.
Exact-string hits in `~/.claude/history.jsonl` are lines 20995, 20999, 21019 and 21021 (`grep -n -i forgeo`, re-run 2026-10-14T02:55Z, still the same four).
The first version of this file said only two such hits existed; that was true at 02:46Z and was made false by the two messages typed at 02:46:27Z and 02:47:20Z.

Cross-references into sibling files (line numbers for the content read at 02:53Z):

- L09 line 316 says "The owner's 'forgeo' is very likely Forgejo, not software-factory" and asks L12 to confirm.
  I confirm the second half, and the first half is now only one of three readings.
- L10 line 204 says the forge trio "is the most plausible meaning of 'forgeo' for L12".
  It was written before lines 21019 and 21021 existed and does not know about the 09-21 message at line 14752.
- L14 section 3.7 is headed "lucaGazzola/forgeo (the thing the owner now calls forgeo)", which reads as if L14 had settled on candidate B.
  Its own section 4.7 says the opposite: the public project is "a coincidence of spelling", the owner is "recalling the Go gRPC system (rime or the SPEC-16 scheduler) under a different name, or recalling Forgejo", and "This is a judgment; the evidence does not settle it".
  Its section 2 table lists five Go designs and says "Forgeo is none of them".
  Its section 2 also answers the owner's question with "the Go and gRPC system design is still here. It is `scheduler/` and `specs/scheduler/`", which is C3.
- Reconciliation of L12 and L14: both files agree that nothing runs under the name, that the public project is not the owner's, and that the referent is probably a Go gRPC design under a new name.
  They differ on which design.
  L14 puts its weight on the in-repo scheduler (C3) because that is the design that is "still here".
  L12 puts it on rime (C2) and the Drive blueprint (C1) because the owner said "we need that shit here" and "that fucking scheduler was gold" the day before, which he would not say of something he thought was missing.
  The difference is real and cannot be settled from files; it is the single question in section 10.
  L14 also lists candidate B as the name's only literal match, which agrees with L12.
- L14's file now exists (written 2026-10-14 02:52:07Z), so the earlier note that it had no file is withdrawn.
  I03 now exists too (`I03-oss-factories-and-clones.md` lines 63, 83 and 219 treat forgeo as one more open source factory and defer the name to L12).


## 4. What works

Candidate C1 (Drive blueprint) and C3 (in-repo scheduler), proven pieces:

- A typed contract exists and is coherent: `control_plane.proto` gives claim, lease with `renewal_token`, heartbeat, versioned transitions (`expected_version`), idempotency keys, effect receipts and independent verification (Drive id `1t_suhhfbwzZg_pCDXg_QrUkafqMsh7Io`, read 2026-10-14).
- The supervisor prompt encodes the same rules as the owner's complaint: "Move one accepted work order at a time", "Treat all queues as at-least-once", "Fail closed on missing policy, signature, owner, evidence" (`BOOTSTRAP-SUPERVISOR-PROMPT.md`, Drive id `1ENi8LnewYdoRDFIzs3dYIGmI7TIlhVS2`).
- Doc 31 states the Go profile the owner remembers: bounded worker pools, cancellation, no unbounded goroutine per item, and "Keep protocol handling, polling, retries, filtering and state transitions deterministic" (Drive id `1UMHjoU-su0Ufjsu3ZAcc2HVodaefYwg_m1OT9D0f5LY`).
  That sentence is the owner's own statement of "driven by system, not agent".
- The in-repo Go scheduler is built and merged: skeleton `fc16622`, config `d268fe9`, host wrappers `c22cb99`, all 2026-10-12, with a proto that forbids streaming and TCP (`scheduler.proto` header: unix sockets mode 0600, "No streaming call exists").
- Candidate C2, rime, has a built core of 3,275 non-generated Go lines in `internal/{auth,route,server,store,stream,transition,webhook}` and four ADRs; the gRPC server was never constructed (section 2).
  Its last commit is "A-19 - Transition table with ordered gates" (HEAD `994a614`, 2026-10-06; L14 section 3.2).
- The Drive README says the reference Go is compilable and testable with `go test ./...`, but I did not run it (not downloaded), so that claim is unverified.

Candidate A, Forgejo, proven pieces:

- A Forgejo container ran in Podman and the queue migration passed (`getting-my-bearings/runs/worker/WK-20260920-091-evidence.md`; `jkkelley/bearings-core` PR #2, `d69375d`).
- A local Forgejo 15.0.9 rootless container proved `POST /orgs/boards/labels` with `"exclusive":true` returns 201 and column labels swap (`~/tools/bearings-v2/streams/B-infrastructure.md` lines 355-360).
- The rime repo holds a merged deploy: B-08 `737d48b`, B-03 `775b5a6`, B-04 `3a62a79` touch `deploy/forgejo`.
- `forge-config/Makefile` is the owner's Make-driven cluster deploy, which fits "i love driving automation with make files too".
- Forgejo as a product is current.
  https://forgejo.org/releases/ (fetched 2026-10-14) states "v16.0.6 released on 12 October 2026" (stable, "supported until 29 October 2026") and "v15.0.10 released on 12 October 2026" (LTS, "supported until 15 July 2027").
  https://forgejo.org/docs/latest/admin/release-schedule/ (fetched 2026-10-14) lists v17.0 at "15 October 2026" with branch cut "24 September 2026" and the rule "published on a fixed schedule, every quarter".
  The first version of this file said v17.0 was "scheduled 2026-10-15" and cited a search; both dates are now confirmed on those two pages, and the release page itself does not mention v17.0.
- https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/ (fetched 2026-10-14: retry is opt-in, the example limit 5 and backoff 5s, 2, 3m, no re-sync of a failed same commit)
- https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-cmd-params-cm-yaml/ (fetched 2026-10-14: `controller.sync.timeout.seconds` default 0 meaning no timeout, `controller.operation.processors` default 10)
- Local Argo CD docs clone `clones/argo-cd` at `6e7006b` (2026-10-14): `docs/user-guide/auto_sync.md`, `docs/user-guide/sync-waves.md`, `docs/operator-manual/argocd-cmd-params-cm.yaml`
- Vendored Forgejo chart 17.1.7 (appVersion 15.0.9): `clones/rime/deploy/forgejo/chart/forgejo`, `values.yaml` lines 696-746
- https://forgejo.org/docs/latest/user/actions/overview/ (fetched 2026-10-14, Docs v16.0, latest v16.0.6): "Forgejo Actions is designed to be familiar to users of GitHub Actions, but it is not designed to be compatible", and without `.forgejo/workflows` it reads `.github/workflows`.
- Mermaid in fenced markdown renders in issues and pull requests (https://docs.codeberg.org/markdown/introduction-to-markdown/, read 2026-10-14).

Candidate B, Forgeo, what its code does well (clone `5766da1`, Python in `src/forgeo`):

- Exit-code agent contract: 0 commits and completes, 2 blocked for human, 3 deliberate no-op, anything else discards and marks FAILED (`docs/agent-contract.md` "Exit codes").
- No-change contract: exit 0 with an unchanged tree is retried `no_changes_retry_max` times then BLOCKED (`docs/agent-contract.md`; `config/forgeo.yaml`).
- Plain JSON backlog with `dependencies`, `run_at`, `acceptance_criteria`, per-task `agent_command` (`docs/backlog.md`).
- Kernel locks: `fcntl.flock` non-blocking exclusive, released on crash (`src/forgeo/daemon.py` `_take_flock` line 92, `LOCK_EX | LOCK_NB` line 107).
- Task choice is a pure function: `oldest_open_task` is defined at `src/forgeo/backlog.py` line 188 and called at `src/forgeo/forgeo.py` line 130.
- Bounded retention, optional Docker sandbox with `network: none`, config hot reload, notifications that never affect the run, 27 test files (`CONTRIBUTING.md`: `pytest`, `ruff`, `mypy`).

## 5. What broke and why

The central finding differs by candidate.

Candidate C, the Go and gRPC design: it was designed four times, partly built twice, and then lost from the line, and nothing records why.

- Evidence it was lost: the architect answered the owner's "why isn't a system design by go still here?" with "I do not know why it dropped out. Nothing I have read today, not the memories, the plans directory or the briefs, names a Go design" (session transcript, 2026-10-14T02:46:08Z).
  The brief for this investigation names no Go area; L14 was added after the question.
- Evidence that rime stopped: the owner halted the rime loop at 2026-10-06T11:41Z and the ledger gives no reason (L14 section 5, `EXECUTION-LEDGER.tsv` row 503); its Forgejo deploy (B-08) was merged into rime main on 2026-10-06 and never applied (Candidate A below).
  So C2 and A stopped on the same day, which fits the owner calling it "forgeo" as one thing.
- Evidence it is only partly lost: the plugin repo's own Go scheduler exists (`scheduler/`, `fc16622`..`c22cb99`), and the owner ruled it "the engine and the end state" (`history.jsonl` line 18500, the architect's note stamped 2026-10-13T02:48:27Z and labelled "Owner 02:50Z (record lvvtd)"; `20261013025600-priority-list.md` line 6; `L03-design-vs-built.md` lines 525-526 and 543; the label and the stamp differ by two minutes, see section 2).
  So the Go design survived as the scheduler in the repo, while the Drive blueprint (2026-09-17) never reached the repo: no `bootstrap-with-agent` repo exists (404) and no local copy exists.
- Evidence the blueprint was never adopted: the README says "This release does not claim that any cluster, credential, repository, provider account, policy engine, or production control is installed" and lists unresolved `TBD-*` authority bindings that "block adoption" (Drive README id `145plxIuhDEyFasrtqtT6VBoSZQep8HXV`).
  Its lifecycle is `PROPOSED`, not accepted.
- The `DEC-nats-jetstream-grpc` graph node is locked while NATS was dropped (`L03-design-vs-built.md` lines 519 and 541; L14 section 9 agrees), so the Go design's transport decision is internally stale.
- I could not establish when or why the Drive blueprint stopped being used; the only dated facts are creation on 2026-09-16 and 2026-09-17 and no later edit (modifiedTime equals createdTime on the files read).

Candidate A, Forgejo: the owner does not have a running Forgejo.

- No `forgejo` namespace on the live cluster (`kubectl --context homelab-admin get ns`, 2026-10-14, lists argocd, cert-manager, default, dev, development, external-secrets, haproxy-ingress, jenkins, longhorn-system, metallb-system, monitoring, resume-star, vault, yieldpoint-ai and system namespaces).
- ArgoCD has 12 Applications, none Forgejo (`kubectl get applications -n argocd`).
- `jkkelley/homelab-gitops` has no `forgejo` or `rime` path, last commit `1cff75e`, 2026-09-13.
- Break 1: the May build stopped at manifests. `forge-gitops/argocd-apps/workloads/forgejo.yaml` line 9 reads `repoURL: PLACEHOLDER_FORGE_CONFIG_REPO_URL`.
- Break 2: the design was EKS and homelab co-equal (`forge-config/docs/adr/0004-eks-vs-homelab.md`), heavy for a three-Raspberry-Pi cluster; the owner said "we're local k8s and not EKS either" (`history.jsonl` 2026-09-20T19:30Z).
- Break 3: the September build went into `bearings-core` and was superseded the next day when the design moved to `rime`.
- Break 4: the rime Forgejo tickets churned; B-02 failed tester 422 three times on chart sourcing and was superseded by B-08 at 2026-09-21T05:28:47Z (`~/Documents/investigations/bearings-v2-investigations/evidence/E-timeline.md` E-209, E-220, E-269, E-274, E-296).
- Break 5: the last mile is a hand step. `rime/deploy/argocd/README.md` says the Application must be copied by hand into `homelab-gitops`; it was merged to rime main on 2026-10-06 and never copied.
- Break 6: Forgejo's REST API has no project or board endpoint (swagger 17.0.0-dev read 2026-10-06T00:44Z, `B-infrastructure.md` line 356; Codeberg issue 5330, PR 9384 unconfirmed 2026-10-14), so boards are exclusive scoped labels.
- Break 7: the Drive Forgejo doc assumes LangGraph and a service mesh that the owner later removed (`DESIGN.md` line 203).
- New in this version: "forgeo is gonna be github" (line 21021) makes a new self-hosted Forgejo unlikely to be what he wants now.

Candidate B, Forgeo, limits against the owner's stated need (properties, not bugs):

- One agent at a time per repo: `backlog.lock` and `backlog.run` (`docs/agent-contract.md` "Concurrency"; `src/forgeo/daemon.py` lines 168-200).
- Any BLOCKED task stops the whole cycle: `src/forgeo/forgeo.py` lines 118-122 return `"blocked"` as soon as one task is BLOCKED, so independent OPEN tasks wait on a human.
- No branches or PRs by default (`config/forgeo.yaml` line 15: "branch: main # Everything is committed to this branch (no feature branches)"); `review_mode: branch` waits for a human merge (`CHANGELOG.md` 0.11.0).
- Cycle length is a poll: `interval_minutes` default 60 (`config/forgeo.yaml` line 14, `src/forgeo/models.py` line 731), floor 1 second (`daemon.py` line 65).
- No queue, no multiple seats, no cluster execution, no event input.
- Maturity: roughly nine weeks old, one main author, 35 stars; the last commits on 2026-09-30 are single-use inlining refactors, i.e. its own refactor-when-idle mode.

## 6. Waits, polls, sleeps and leases

L12 has no line scripts.
The waits below are those of the paths the owner would run, with bounds.

Forgejo deploy path (read from `clones/rime` at `994a614`, 2026-10-06):

- `deploy/forgejo/bootstrap.sh` (204 lines) has no wait, no poll, no sleep and no retry.
  A grep for `sleep`, `while`, `until`, `timeout`, `-m `, `--max-time`, `--retry` returns zero lines.
  It is a single pass of idempotent calls: each `req()` is one `curl` at lines 31 and 35 with `-s -o ... -w '%{http_code}'` and no `--max-time` and no `--retry`.
  Bound: none from the script, so a hung Forgejo hangs the call until curl's own default (no overall timeout) or the caller kills it.
  It also does not wait for Forgejo to be ready; the caller must run it only after the pod is up, and the caller is a human today.
  Failure handling is `fail()`, which exits 1 on a bad status (`bootstrap.sh` lines 42-45), with no retry up to three times.
- `deploy/argocd/forgejo.yaml` lines 39-44: `syncPolicy.automated` with `prune: true` (line 41), `selfHeal: true` (line 42) and `CreateNamespace=true` (line 44).
  There is no `retry:` block (grep for `retry` in the file returns nothing) and no sync timeout, so Argo's defaults apply.
  The defaults, looked up on 2026-10-14:
  - Retry is off unless configured. https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/ (fetched 2026-10-14): "To enable, configure the `retry` field in the sync policy"; the values `limit: 5`, `duration: 5s`, `factor: 2`, `maxDuration: 3m` are an example on that page, not stated defaults (same text at `clones/argo-cd/docs/user-guide/auto_sync.md` lines 97-115, clone HEAD `6e7006b`, 2026-10-14).
  - Automated sync does not retry a failed sync of the same commit: the same page, "Automatic sync will not reattempt a sync if the previous sync attempt against the same commit-SHA and parameters had failed" (`auto_sync.md` lines 143-144).
    With `selfHeal: true` a sync is attempted again after the self-heal timeout, "5 seconds by default" (`auto_sync.md` lines 140-142), but only for drift, and the failed-sync rule still holds.
  - The sync operation has no timeout by default: https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-cmd-params-cm-yaml/ (fetched 2026-10-14) gives `controller.sync.timeout.seconds: "0"` with the comment: 0 means no timeout, default 0 (`clones/argo-cd/docs/operator-manual/argocd-cmd-params-cm.yaml` lines 90-91).
    `controller.operation.processors` defaults to 10 (line 66).
  - Between sync waves Argo waits 2 seconds, configurable by `ARGOCD_SYNC_WAVE_DELAY`, then waits for the wave to be healthy (`clones/argo-cd/docs/user-guide/sync-waves.md` lines 116 and 135-139).
    The same file, line 139, says "it may be that the app can never get to healthy", so the wave wait has no bound of its own.
  - Conclusion: the Forgejo deploy has no bound anywhere.
    A wave that never turns healthy leaves the sync running for ever, nothing retries it, and a person has to notice.
    That is the opposite of the owner's rule that every automated step retries up to three times then reports.
- `deploy/forgejo/manifests/*.yaml` use sync waves: `secretstore.yaml` lines 13 and 21 wave `"-3"`, `externalsecret.yaml` line 16 and `externalsecret-admin.yaml` line 17 wave `"-2"`, `postgres.yaml` lines 14 and 29 wave `"-1"`, the Forgejo Deployment wave 0 (`externalsecret-admin.yaml` lines 7-9).
- `deploy/forgejo/values.yaml` sets no probe, timeout or initial delay (grep for `probe|timeout|delay` returns nothing), so the vendored chart's own values apply.
  The chart is `rime/deploy/forgejo/chart/forgejo`, a packed chart (gzip tar, not a directory) with `Chart.yaml` line 2 `appVersion: 15.0.9` and line 30 `version: 17.1.7`; I unpacked only `Chart.yaml` and `values.yaml` into the session scratch directory to read them.
  Its `values.yaml` gives: liveness probe enabled, `tcpSocket` on `http`, `initialDelaySeconds: 200`, `timeoutSeconds: 1`, `periodSeconds: 10`, `failureThreshold: 10` (lines 696-704); readiness probe enabled, `httpGet /api/healthz`, `initialDelaySeconds: 5`, `periodSeconds: 10`, `failureThreshold: 3` (lines 717-726); startup probe `enabled: false` (lines 738-746).
  So Forgejo is killed by the kubelet if its port does not answer for about 100 seconds after the first check at 200 seconds, i.e. roughly 300 seconds after container start, and is held out of service after 3 failed readiness checks (about 30 seconds).
- Helm timeouts: not applicable, because ArgoCD renders the chart (`helm.valueFiles` in `deploy/argocd/forgejo.yaml`), and no `helm install --wait` is used.
- `forge-config/Makefile` target `runner-token` (line 29) has manual steps where a human copies a token into SSM; no wait is coded.
- Longhorn PVC bind and the ExternalSecret sync are implicit waits with no bound set in the files read.
- Not checked: Forgejo's own real startup time on the Raspberry Pi nodes (never run there), and `ARGOCD_SYNC_WAVE_DELAY` on the live cluster's Argo (not read; the default 2 seconds is from the docs).

Forgeo (candidate B):

- Main loop sleep: `asyncio.sleep(delay)` raced against stop and reload events with `asyncio.wait(..., FIRST_COMPLETED)` (`src/forgeo/daemon.py` lines 405-411); default 60 minutes; floor 1.0 second (`MIN_WAKE_SLEEP_SECONDS`, line 65).
- Agent timeout: `agent_timeout_seconds`, unset by default, meaning no kill (`docs/agent-contract.md` "Timeouts").
- Git timeout 120 seconds (`config/forgeo.yaml`).
- Locks: non-blocking `flock`, released by the OS on crash, no TTL (`daemon.py` lines 92-123, 168-200).
- Blocked pause: a BLOCKED task or an existing blocker file pauses all work with no bound (`forgeo.py` lines 118-122 and 134-136).
- Retries: `failed_retry_max` default 0 (`config/forgeo.yaml` lines 148-150, "0 (default)") and `no_changes_retry_max` default 0 (`src/forgeo/models.py` line 767 `Field(default=0, ge=0)`; the value 2 on `config/forgeo.yaml` line 156 is a commented example, and attempt 2 of this file wrongly called 2 the default).
- Agent timeout again: `config/forgeo.yaml` line 175 shows `# agent_timeout_seconds: 3600` commented out, "Omitted = never kill", so the 3600 is an example, not a default.

Go designs (candidate C), declared waits only, nothing run:

- `Lease` and `HeartbeatLeaseRequest` in `control_plane.proto` carry `acquired_at`, `expires_at`, `renewal_token` and `requested_extension`, so the design is lease-and-heartbeat based, with `Budget.effect_timeout`, `retry_max` and `deadline`.
- Doc 31 requires "a propagated deadline", "bounded worker pools" and that "A deadline failure does not prove a side effect never happened".
- Rime (C2) declares its waits in the ADRs and `internal/stream` and `internal/transition`; I did not trace them, and L14 sections 5 and 6 cover the lease and heartbeat model.
- These are exactly the timer-based leases the owner's current line uses, so the Go design is not a way out of leases; it formalises them.

## 7. Decisions an LLM makes that a rule could make

L12 is a local area, and its "line script" is the owner-side path this investigation took from the word "forgeo" to a referent.
The evidence is the session transcript (`~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/e31510a1-4a15-4377-9c1c-8f1088f67bed.jsonl`) and `~/.claude/history.jsonl`.
Each item below is a decision an LLM made, where, and the rule that would replace it.

| # | Decision made by the architect (an LLM) | Where | Rule that would replace it |
| --- | --- | --- | --- |
| 1 | Read the one-word message "forgeo" as "the Go gRPC design" | transcript row 516 (02:46:30Z), `history.jsonl` line 21019 | A registry of owner terms with a confirmed referent: `terms.json` rows of `{term, referent, status, confirmed_by_message, confirmed_at}` with status `unconfirmed` or `confirmed`. A message whose key term has no `confirmed` row is not interpreted; it becomes a card question, and no investigator is told a referent until the row is confirmed. |
| 2 | Told investigator L14 "The owner just said the Go gRPC design is called forgeo", an unconfirmed reading handed on as an owner statement | transcript row 517 | Messages to seats may quote the owner verbatim or cite a `confirmed` registry row; any other sentence about what the owner "meant" is blocked by the sender, a text check on the outgoing message for the words "owner just said" without a quote. |
| 3 | Told the owner "forgeo is the Go control plane" as a fact | transcript row 522 (02:46:39Z) | The reply template has a status field: `confirmed` or `reading`. A registry row at `unconfirmed` can only be sent as `reading` plus the question. |
| 4 | Re-read the next message "forgeo is gonna be github" as a location hint ("Forgeo on GitHub") and switched search channel | transcript row 592 (02:47:31Z) | Two readings within 70 seconds of the same word is the signal the rule in item 1 exists for: a term with two readings in the registry is blocked until the owner picks one. |
| 5 | Decided where to look (Drive, GitHub, local, shell history) and in what order | transcript rows 530-593 | A fixed term-resolution procedure run by a script: history.jsonl, memory, owner repos, Drive, GitHub, browsers, in one order, printing a hit table. The LLM reads the table; it does not choose the channels. The search table in section 3 is that procedure done by hand. |
| 6 | Added a new investigation area (L14) mid-run on its own judgment | transcript row 501 (02:46:27Z) | The area list is data in the brief; an owner message that names a term absent from the brief adds a registry row and a card, and the workflow script adds an area from the row. |
| 7 | Picked among candidates A, B and C and put the weight on one | this file, sections 1 and 2 | Not decidable by a rule from files alone: the registry row stays `unconfirmed` and the one question in section 10 goes to the owner. This is the one place a human answer is required. |

Rule for all seven: an owner term is a data row with a confirmed referent, not a guess carried in a conversation.
The registry is also the home for the other coined words that appeared in this investigation (for example "GOTEAM", "GOFACTORY", "USERGO"), each with its confirming message.

The decisions inside the candidates themselves, for contrast:
Neither candidate B nor the Go design (C) lets the LLM make its scheduling decisions.
Forgeo picks the next task by rule: `oldest_open_task` is defined at `src/forgeo/backlog.py` line 188 and called at `src/forgeo/forgeo.py` line 130.
"Oldest" is `min(normal, key=lambda task: task.created_at)` (the last lines of the function), i.e. earliest `created_at` among OPEN tasks whose dependencies are all COMPLETED.
A task with a due `run_at` jumps ahead and is ordered by `(run_at, created_at)`, and a future `run_at` is skipped.
Outcome classification is an exit code, retry is a counter, pause is a file.
In design C1, state transitions are validated by schema, role, policy revision and evidence, with "A model never grants itself permissions" (supervisor prompt rule list).
Both are the shape the owner's "driven by system, not agent" order asks for.

## 8. What to carry forward

From the owner's Go designs (C1, C2, C3), if one of them is the referent:

- The typed work-order, lease, transition and receipt contract as the control plane schema, since it already exists and already matches the line's concepts.
- The Go service profile in doc 31: bounded worker pools, cancellation, deterministic polling and retries, agents only where judgment is needed.
- The in-repo `scheduler/` module as the build vehicle; the Drive blueprint as a source of the status model and the verification and effect separation.
- The rule "do not start one unbounded goroutine per queued item".
- From rime (C2): the split in ADR-0003 where the board system holds board state and GitHub holds code and pull requests, which is what "forgeo is gonna be github" may describe; its transition table with ordered gates is the closest built code to the status-code-driven routing the owner asked for on 2026-09-21 (line 14752).

From Forgeo (B), as ideas to copy, not a dependency:

- Exit-code seat contract (0 done, 2 blocked, 3 no-op, other discard) and the no-change contract (`docs/agent-contract.md`).
- Backlog as data with task selection as a pure function (`src/forgeo/backlog.py` line 188).
- Kernel `flock` as the single-writer guard (`daemon.py` lines 92-123), replacing timer leases where one host is enough.
- Bounded history and output retention; Docker sandbox with no network by default; a derived blocker report removed when the last blocker clears.

From Forgejo (A), worth keeping:

- The rime `deploy/forgejo` tree at `994a614` as a ready deploy, merged and never applied.
- `forge-config/Makefile` as the reference for Make-driven cluster deploys.
- Forgejo Actions plus `forgejo-runner` as a drop-in CI only if the factory leaves GitHub.
- Scoped labels as the tested board workaround; Mermaid in issue bodies for DAGs.

Recommendation for the lead:

- Do not record "forgeo" as an existing running asset.
  Record it as: probably the owner's Go and gRPC control plane idea of 2026-09-21 (rime, with its Forgejo boards, and the Drive blueprint of 2026-09-17), with the name unconfirmed and the in-repo scheduler (SPEC-16) as the third, least likely, incarnation.
- Put C on the control plane decision beside Argo and Kubernetes Jobs, and use L14 for what each Go incarnation holds.
- Record the owner-term registry (section 7) as a rebuild requirement: this investigation spent about 70 seconds and two investigators on an unconfirmed reading.
- Treat B as one more open source factory on the shelf, and A as off the critical path.

## 9. What to kill

- The idea that "forgeo" is installed or running anywhere.
  Nothing named forgeo is.
- The first version's confident "Forgejo versus Forgeo" framing: it left out the Go design, which the owner's own message sequence points at.
- Treating the architect's "Forgeo is the Go gRPC design" (transcript rows 516-522) as an owner statement.
  It is a reading.
- The May Forgejo trio as a deploy path (`forge-eks-infra`, EKS overlays, the placeholder `repoURL`).
- The Drive Forgejo doc's LangGraph and service mesh plan as a current design.
- The hand-copy step from `rime/deploy/argocd` into `homelab-gitops`; if Forgejo is ever deployed it must be scripted or a bot-opened PR.
- Forgejo project boards as an agent surface, and Forgeo as the control plane (serial, polled, single branch, pauses on any blocker).
- The locked graph node `DEC-nats-jetstream-grpc` until its transport decision matches C15 (NATS dropped).

## 10. Open questions for the owner

One question changes the design.

By "forgeo" do you mean the Go and gRPC central system you described on 2026-09-21 (rime, with Forgejo as its boards, or the Bootstrap With Agent blueprint in your Drive), the SPEC-16 scheduler already in this repo, the public Forgeo CLI at github.com/lucaGazzola/forgeo, or the Forgejo git forge?

What each answer does to the rebuild:

- Rime or the Drive blueprint: it becomes the control plane option beside Argo and Kubernetes Jobs; for the Drive, the zip's `reference-go/` must be pulled and read because it exists nowhere on disk, and for rime the unfinished gRPC server is the gap.
- The SPEC-16 scheduler: nothing new is found, the 14 ready tickets stand, and the question is only whether it stays the engine against Argo.
- The public Forgeo: nothing to migrate, because it is not installed; its patterns go into the seat contract.
- Forgejo: nothing to adopt now, and "is gonna be github" says the forge role is GitHub (or, on the other reading, points to a GitHub repo), so the rime deploy stays unapplied.
- A fourth thing: name it or say where you saw it.

A follow-up that depends on the answer, to be asked only after it: what does "forgeo is gonna be github" mean for the control plane, that GitHub holds the state, or that the factory runs as GitHub Actions and checks?

## 11. Sources

Owner statements and local files:

- `/home/luna/.claude/history.jsonl` lines 20995, 20999, 21018, 21019, 21020, 21021 (2026-10-14T02:16:15Z, 02:19:59Z, 02:45:53Z, 02:46:27Z, 02:46:53Z, 02:47:20Z) and the Go plus Forgejo lines 14576, 14587, 14748, 14750, 14752 and 14753 (2026-09-20T19:15Z, 19:30Z, 2026-09-21T01:14Z, 01:18Z, 01:23Z, 01:25Z) and line 18500 (2026-10-13T02:48:27Z, the scheduler ruling).
- `/home/luna/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/e31510a1-4a15-4377-9c1c-8f1088f67bed.jsonl` rows 495-602 (2026-10-14T02:45:53Z to 02:48:07Z): the architect's reading of "forgeo" and the launch of L14.
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/awesome-software-factories/README.md` line 67 (commit `33d8520`, 2026-10-12).
- `/home/luna/projects/coq-jev-herdr-plugin/scheduler/go.mod`, `scheduler/api/scheduler/v1/scheduler.proto`; commits `fc16622`, `d268fe9`, `c22cb99`.
- `/home/luna/projects/cortex-hub/docs/superpowers/specs/2026-05-19-forgejo-forge-design.md`, `CONTEXT_STATE.md`, `docs/superpowers/plans/2026-05-19-forgejo-forge.md`.
- `/home/luna/projects/forge-config/` (Makefile, ADRs), `/home/luna/projects/forge-gitops/argocd-apps/workloads/forgejo.yaml`, `/home/luna/projects/forge-eks-infra/`.
- `/home/luna/projects/getting-my-bearings/runs/principal-7db04c88/briefs/WK-FORGEJO-20260920.md`, `runs/worker/WK-20260920-091-evidence.md`.
- `/home/luna/tools/bearings-v2/DESIGN.md` line 203, `streams/B-infrastructure.md` lines 355-360.
- `/home/luna/Documents/investigations/bearings-v2-investigations/evidence/E-timeline.md` (E-209, E-220, E-269, E-274, E-296).
- Sibling files (content at 02:53Z): `L03-design-vs-built.md` lines 519, 525-526, 541 and 543, `L08-bearings-owner-surface.md` line 177, `L09-earlier-factory-iterations.md` line 316, `L10-cluster-and-gitops.md` line 204, `L14-go-grpc-control-plane.md` sections 2, 3.2, 3.7, 3.8, 4.7, 5, 9 and 10, `I03-oss-factories-and-clones.md` lines 63, 83 and 219, `S01-argo.md` lines 62 and 109.
- Scheduler ruling: `/home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013025600-priority-list.md` line 6; commit `7f43ce8` (2026-10-13T02:57:53Z); `events/2026/10/20261013T024715Z-100-lvvtd.json` (a `seat.down` record, cited as a mismatch).
- Rime ADRs: `clones/rime/docs/ADR/0001-rime-go-grpc.md`, `0003-forgejo-boards-only.md`.
- Browser and shell stores searched (counts in section 3): Firefox `places.sqlite` in three profiles, Chrome `Default/History`, Edge `Default/Bookmarks` and `History`, PowerShell `ConsoleHost_history.txt`, `~/.zsh_history`, `~/.bash_history`.
- Clones: `clones/forgeo` at `5766da1`; `clones/rime` at `994a614` (`deploy/forgejo/bootstrap.sh`, `deploy/argocd/forgejo.yaml`, `deploy/forgejo/manifests/`, `deploy/forgejo/values.yaml`); `clones/software-factory`; `clones/bearings-core`; `clones/awesome-software-factories`.

Google Drive (read 2026-10-14, account jkkelley86@gmail.com):

- Folder `agent-entrypoints` id `1OflD-qTSq7VARvf7eDcE24zWB9_uA6C2`; `control_plane.proto` id `1t_suhhfbwzZg_pCDXg_QrUkafqMsh7Io`; `BOOTSTRAP-SUPERVISOR-PROMPT.md` id `1ENi8LnewYdoRDFIzs3dYIGmI7TIlhVS2`; `README.md` id `145plxIuhDEyFasrtqtT6VBoSZQep8HXV`; parent folder `1nyY1vBGGNz3Luoj28PwAaHIZ71dcM1JU` with the zip id `1vb9G8y0euTaNzHSADf99TPmUBVeLsbew` and "START HERE" doc id `1L2D-xaqBxxbpnNBh4jbxUenawOAo-l6udd_RnAFKEx4`.
- Doc 31 id `1UMHjoU-su0Ufjsu3ZAcc2HVodaefYwg_m1OT9D0f5LY`; doc 36 id `1xSaWk-dpBOnT5TfpRfFdO52hFQdKdfAHNrpR0ZR9XP8`; Stateless Orchestration doc id `17Db9of1WdBJK3YzZpEjTEx23fBYL1wRfy85WH_hiCf4`; Forgejo doc id `1zheVmvufZldwoborC8C3qMqALRIB5oaOYMa0gIA15XM`.
- Drive title search for "forgeo" or "forge" returned no files.

Live checks, read-only, 2026-10-14 UTC:

- `kubectl --context homelab-admin get ns`, `get applications -n argocd`, `get ingress -A`.
- `gh search repos forgeo`, `gh repo list jkkelley`, `gh api repos/jkkelley/bootstrap-with-agent` (404), `gh api repos/lucaGazzola/forgeo`, `gh api repos/jkkelley/homelab-gitops/git/trees/HEAD?recursive=1`.

Web, all fetched 2026-10-14:

- https://github.com/lucaGazzola/forgeo and https://forgeo.org
- https://forgejo.org/releases/ (v16.0.6 and v15.0.10 released 12 October 2026, quoted)
- https://forgejo.org/docs/latest/admin/release-schedule/ (v17.0 on 15 October 2026, branch cut 24 September 2026, quoted)
- https://forgejo.org/docs/latest/user/actions/overview/ (Docs v16.0, Actions not designed to be compatible, `.github/workflows` fallback)
- https://docs.codeberg.org/markdown/introduction-to-markdown/ (Mermaid rendering)
- https://codeberg.org/forgejo/forgejo/issues/5330 and https://codeberg.org/forgejo/forgejo/pulls/9384 (projects REST API requested, implementation unconfirmed)
- https://github.com/jkornobis/GE-KnowledgeCenter/issues/36 (third-party audit, no Projects API)
