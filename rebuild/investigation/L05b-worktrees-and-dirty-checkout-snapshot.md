# L05b - Worktrees and dirty main checkout, snapshot 2026-10-14T02:50:25Z

## Contents

1. Why this file exists
2. Main checkout state
3. Worktrees
4. Remote branches not merged to main

## 1. Why this file exists

The owner ordered on 2026-10-14 UTC: "everything needs to get on main too, dont leave that shit laying around".
The architect merged PR 182 and found the main checkout dirty with the old line's edits and 90 or more worktrees attached to the repo.
This is evidence for area L05 and for step R-04 Land main; nothing here was changed by hand.

## 2. Main checkout state

Path: ~/projects/coq-jev-herdr-plugin, branch main at 5ad1996, origin/main at b7a3c5d, behind by 2.

```
 M tools/bearings/assets/page.html
 M tools/bearings/assets/theme.css
 M work-orders/WO-20261013-16f1/WO-20261014-539a-cause-ay-scheduler-testkit-world-copies-events-b.md
?? backlog/
untracked event files in the working tree: 5812
```

## 3. Worktrees

```
/home/luna/projects/coq-jev-herdr-plugin                                               5ad1996 [main]
/home/luna/.cache/coq/coq-jev-herdr-plugin/start-tickets/wt-WO-20261013-d182           cf0f883 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/start-tickets/wt-WO-20261013-e2c3           f65c7d7 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/start-tickets/wt-WO-20261014-5e4a           a98b677 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/verify/20261013225134-7e114c985e4b-2264845  7e114c9 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/WO-20261013-1031                  4aad289 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-a3-split                      e5cef84 [chore/roadmap-a3-split]
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-cause-ab                      40bddc8 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-causes-t-u                    44b17a9 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-dd47-cap-test                 ffc03c9 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-design-law                    196ca0b (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-belt-nudge-wait         e87a5f0 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-belt-single-instance    e87a5f0 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-crash-causes            02eec23 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-down-orphans            3c74198 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-merger-after-merge      3c74198 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-monitor-llm-ok          3c74198 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-probe-subshells         3c74198 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-maint-record-path             6cf841b (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-next-tickets                  6050f38 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-roadmap-i                     dfc265e (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-roadmap-i-split               4dab4bf (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-roadmap-j                     dfc265e (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-roadmap-k                     65ade6a (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-roadmap-k-followups           6db11bc (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-roadmap-k-tickets             89cc749 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-spec16-per-file               ff4fd89 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-test-speed                    02cf8c0 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/cut-three-loops                   557c5a9 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/maint-cut-seatdeny                f3cf2a5 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr102                             456bbb2 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr104                             6404d7f (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr105                             46235b5 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr106                             edd5f26 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr107                             6fb9138 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr109                             0a18b33 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr109b                            e8516dd (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr110                             4dab4bf (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr111                             0d3495d (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr111b                            0d3495d (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr113                             b6fa56f (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr114                             b0277d2 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr118                             762e649 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr129                             7b43804 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr130                             dc49087 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr130w                            dc49087 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr131                             7e8e7ad (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr132                             37f429c (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr133                             57cc1db (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr134                             f7bd725 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr137                             8e16a38 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr140                             d424c26 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr141                             43e0b8a (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr143                             b608051 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr149                             e94409e (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr164                             db44007 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr169                             99cdee6 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr174                             75d57d9 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/pr97                              2e223ae (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/reindex-main                      a347415 [chore/reindex-main]
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/start-WO-20261013-0ad7            96fc609 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/start-WO-20261013-1e9f            b565385 [feat/the-patrol-saw-eight-line-processes-dead-56-time]
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/start-WO-20261013-30bb            29c1b34 (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/start-WO-20261013-69df            bab41da (detached HEAD)
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/start-WO-20261013-77c0            cfd37f0 [feat/herdr-stable-dies-with-a-segv-at-31-8g-and-nothi]
/home/luna/.cache/coq/coq-jev-herdr-plugin/worktrees/verify-b7a3c5d                    b7a3c5d (detached HEAD)
/home/luna/.cache/wt-pr17                                                              f0aa2d6 (detached HEAD)
/home/luna/.cache/wt-pr32                                                              c4639c1 (detached HEAD)
/home/luna/.cache/wt-pr35                                                              9b293ec (detached HEAD)
/home/luna/.cache/wt-sched                                                             012fa41 (detached HEAD)
/home/luna/.cache/wt-sched-w1                                                          a347415 (detached HEAD)
/home/luna/.cache/wt-sched-w2                                                          a166b78 (detached HEAD)
/home/luna/.cache/wt-sched-w3                                                          9d5bd48 [feat/replay-fixtures-one-golden-case-per-routes-row-a]
/home/luna/.cache/wt-sched-w4                                                          9aff6c0 (detached HEAD)
/home/luna/.cache/wt-spec2                                                             9b293ec (detached HEAD)
/home/luna/.cache/wt-v23                                                               f7a891c (detached HEAD)
/home/luna/.cache/wt-v28                                                               d0b8dea (detached HEAD)
/home/luna/.cache/wt-v39                                                               f75b328 (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/1/coq-jev-herdr-plugin               f50638e (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/10/coq-jev-herdr-plugin              6c06ec9 (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/2/coq-jev-herdr-plugin               9b293ec [feat/factory-design-spec-v2-0-every-agent-workflow-ru]
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/4/coq-jev-herdr-plugin               6c06ec9 (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/5/coq-jev-herdr-plugin               ece7d04 (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/6/coq-jev-herdr-plugin               ae0140e (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/7/coq-jev-herdr-plugin               17df7c9 (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/8/coq-jev-herdr-plugin               2247679 (detached HEAD)
/home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/9/coq-jev-herdr-plugin               17df7c9 (detached HEAD)
```

## 4. Remote branches not merged to main

```
origin/backup/4562-before-rebuild
origin/chore/seat-deny-from-declared-files-ticket
origin/feat/factory-design-spec-v2-0-every-agent-workflow-ru
origin/feat/go-scheduler-design-one-xml-spec-per-domain-unde
origin/feat/herdr-stable-dies-with-a-segv-at-31-8g-and-nothi
origin/feat/interface-agent-seat-owns-the-bearings-page-owne
origin/feat/record-bus-every-slot-s-new-records-reach-the-ch
origin/feat/replay-fixtures-one-golden-case-per-routes-row-a
origin/feat/tester-reviewer-and-merger-seats-come-up-through
origin/feat/the-patrol-saw-eight-line-processes-dead-56-time
origin/feat/threshold-per-role-seat-sh-renders-a-guard-schem
origin/feat/verifier-seat-a-merged-record-wakes-a-verifier-t
origin/tmp-WO-20261012-0677
origin/tmp-WO-20261012-277d
origin/tmp-WO-20261012-3bb0
origin/tmp-WO-20261012-3cb1
origin/tmp-WO-20261012-48ab
origin/tmp-WO-20261012-5826
origin/tmp-WO-20261012-5d09
origin/tmp-WO-20261012-72a0
origin/tmp-WO-20261012-8d87
origin/tmp-WO-20261012-8f4f
origin/tmp-WO-20261012-8fb2
origin/tmp-WO-20261012-9b2c
origin/tmp-WO-20261012-9f5d
origin/tmp-WO-20261012-c41f
origin/tmp-WO-20261012-da52
origin/tmp-WO-20261012-df2b
origin/tmp-WO-20261012-e27e
origin/tmp-WO-20261012-e36e
origin/tmp-WO-20261012-ee9c
origin/tmp-WO-20261012-fd87
origin/tmp-b800
pr/36
pr/37
pr/38
pr/40
pr/41
pr/42
```
