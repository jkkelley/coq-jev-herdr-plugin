---
title: Tester playbook says git is off and the worktree is already at the head
at: 2026-10-12T20:40:53Z
type: fix
ticket: WO-20261012-5d09
sha: null
---

roles/tester.json must and forbidden now tell a tester that git and gh are denied on purpose, the PR head is already checked out, and to run the plan through testpane.sh without asking; playbooks/tester.md re-rendered.
