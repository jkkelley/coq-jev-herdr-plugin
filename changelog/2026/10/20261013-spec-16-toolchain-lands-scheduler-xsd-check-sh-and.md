---
title: SPEC-16 toolchain lands: scheduler XSD, check.sh and config, partial-landing aware
at: 2026-10-13T16:49:22Z
type: feat
ticket: WO-20261013-fc47
sha: null
---

check.sh passes on a tree with none, some or all SPEC-16 files: spec_set in check.json lists the twelve, citations of unlanded specs and unowned rows are counted until the set is complete, an owner twice or an unknown id still fails.
