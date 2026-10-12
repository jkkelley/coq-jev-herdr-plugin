# coq-jev-herdr-plugin - entry points. Every target is a thin call into a script;
# logic lives in the script so the same thing runs from a pane, Jenkins and a container.
#   make lint            every static check, in the lint container (specs, graph, configs, shell, markdown)
#   make test            every tool's suite (tools/*/Makefile test), in Podman
#   make graph-check     graph/bin/graph.sh check + index
#   make lint-image-push  build lint/Containerfile for amd64+arm64 and push ghcr.io/jkkelley/coq-lint:1 (Jenkins pulls it)
#   make changelog       bin/changelog.sh render (CHANGELOG.md from changelog/YYYY/MM/*.md)
#   make aggregates      render every gitignored aggregate: CHANGELOG.md and work-orders/INDEX.md plus the READMEs (WO-20261012-0677)
#   make step MSG=.. TYPE=.. TITLE=.. [TICKET=..] [TEXT=..] [CP=body.md]   one step: lint, changelog, commit, push, checkpoint, /compact
#   make contents        regenerate the Contents block of every AGENTS.md
#   make bearings-*      delegate to tools/bearings (serve, stop, status, url, test)
#   make images          build the lint and test images once
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
LINT_IMAGE := localhost/coq-lint:1
TOOLS := $(wildcard $(HERE)tools/*/Makefile) $(wildcard $(HERE)report/*/Makefile)

.PHONY: lint-image-push step changelog aggregates help lint test graph-check contents images bearings-% event
help:
	@sed -n '1,9p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
images:
	podman image exists $(LINT_IMAGE) || podman build -q -t $(LINT_IMAGE) -f $(HERE)lint/Containerfile $(HERE)lint >/dev/null
	$(foreach m,$(TOOLS),$(MAKE) -C $(dir $(m)) image;)
lint: images
	podman run --rm --network=none --userns=keep-id -v "$(HERE):/repo:ro,Z" $(LINT_IMAGE) bash /repo/lint/lint.sh /repo
test:
	$(foreach m,$(TOOLS),$(MAKE) -C $(dir $(m)) test;)
graph-check:
	$(HERE)graph/bin/graph.sh check && $(HERE)graph/bin/graph.sh index
contents:
	for f in $(HERE)AGENTS.md $(HERE)tools/*/AGENTS.md; do bash $(HERE)bin/md-contents.sh --fix "$$f"; done
bearings-%:
	$(MAKE) -C $(HERE)tools/bearings $*
# make event CODE=423 SEAT=worker-ba08 TICKET=WO-... NOTE="..."
event:
	$(HERE)events/bin/event.sh add --code "$(CODE)" --seat "$(SEAT)" --ticket "$(TICKET)" --note "$(NOTE)"
changelog:
	bash $(HERE)bin/changelog.sh render
# CHANGELOG.md, work-orders/INDEX.md and the work-orders READMEs are gitignored renders, so no PR can carry them (.gitignore).
# bin/aggregates.sh finds work-order.sh (project copy, then machine copy) or exits 4 naming what to install (WO-20261012-aac3).
aggregates: changelog
	bash $(HERE)bin/aggregates.sh --project $(patsubst %/,%,$(HERE))
step:
	bash $(HERE)bin/step.sh --msg "$(MSG)" --type "$(TYPE)" --title "$(TITLE)" $(if $(TICKET),--ticket $(TICKET)) $(if $(TEXT),--text "$(TEXT)") $(if $(CP),--cp-body $(CP))
LINT_IMAGE ?= ghcr.io/jkkelley/coq-lint:1
lint-image-push:
	-podman manifest rm $(LINT_IMAGE) 2>/dev/null; podman untag $(LINT_IMAGE) 2>/dev/null || true
	podman build -q --platform linux/amd64,linux/arm64 --manifest $(LINT_IMAGE) -f $(HERE)lint/Containerfile $(HERE)lint
	podman manifest push --all $(LINT_IMAGE) docker://$(LINT_IMAGE)
