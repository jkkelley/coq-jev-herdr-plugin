# L05 evidence scripts and outputs

Everything here is read-only against GitHub and the investigation clone `../clones/coq` (a clone of jkkelley/coq-jev-herdr-plugin).
Nothing here touches the owner checkout except `worktrees.tsv`, which was produced by `git worktree list --porcelain` there with GIT_OPTIONAL_LOCKS=0.
All times are UTC.

| File | What it reproduces | How to re-run |
| --- | --- | --- |
| `last60.sh`, `last60.tsv` | the last 60 commits of origin/main with a diff-based kind (tickets-only or code) and a subject-based category | `./last60.sh > last60.tsv` |
| `prstats.sh`, `prs.json` | PR counts, cycle time median and p90, merges per UTC day, tickets-only PRs by diff, closing-issue references, open PRs | `./prstats.sh` |
| `branches.sh`, `branches.tsv` | every non-main remote branch, ahead and behind, files, last commit | `./branches.sh > branches.tsv` |
| `branchcompare.sh` | per branch: files absent, identical or different on main | `./branchcompare.sh BRANCH` |
| `ticketlag.sh`, `ticketlag.tsv`, `ticketlag.summary` | ticket status against implementing commits for all 263 tickets | `./ticketlag.sh > ticketlag.tsv 2> ticketlag.summary` |
| `issues.json`, `issue-verdicts.tsv` | all 34 issues as fetched, and the verdict for each open one | `gh issue list --repo jkkelley/coq-jev-herdr-plugin --state all --limit 200 --json number,title,state,createdAt,closedAt,labels,body,comments`; counts: `awk -F'\t' '$3!="CLOSED"{c[$3]++} END{for(k in c) print k, c[k]}' issue-verdicts.tsv` |
| `worktrees.tsv` | the registered worktrees of the owner checkout | `git worktree list --porcelain` in the owner checkout |

Time of the last full run: see the header of the L05 findings file.
