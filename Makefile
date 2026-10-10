# coq-jev-herdr-plugin - entry points. Every target is a thin call into a script;
# logic lives in the script so the same thing runs from a pane, Jenkins and a container.
#   make lint            every static check, in the lint container (specs, graph, configs, shell, markdown)
#   make test            every tool's suite (tools/*/Makefile test), in Podman
#   make graph-check     graph/bin/graph.sh check + index
#   make contents        regenerate the Contents block of every AGENTS.md
#   make bearings-*      delegate to tools/bearings (serve, stop, status, url, test)
#   make images          build the lint and test images once
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
LINT_IMAGE := localhost/coq-lint:1
TOOLS := $(wildcard $(HERE)tools/*/Makefile)

.PHONY: help lint test graph-check contents images bearings-% event
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
