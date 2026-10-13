# tools/bearings - entry points. Nothing here carries a value of its own: tier
# names, ports, pages and labels come from config/bearings.json.
#
#   make serve TIER=dev TICKET=WO-...    start a tier's page in a labelled herdr pane
#   make wait  TIER=dev TICKET=WO-...    start the wait loop pane for that tier
#   make stop  TIER=dev TICKET=WO-...    stop the server and hand its panes back as OPEN slots
#   make status / url / ask Q=file.json / migrate FROM=dir
#   make sitrep-build TIER=stable [OUT=file]   build a SITREP payload from this repo's records (SAVE=1 keeps the queue counts for the next delta)
#   make sitrep-check PAYLOAD=file             measure a payload against STD-owner-sitrep-001, exit 1 on a violation
#   make sitrep TIER=stable PAYLOAD=file [TO=m-id]   check, then send the payload as a reply on the page
#   make test                            the Podman Playwright suite (tests/run-tests.sh)
#   make lint                            schema-validate config + shell and node syntax
#   make image                           build the pinned test image once
#   make upgrade                         promote main into the stable tier (restart stable)
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BIN := $(HERE)scripts/bearings.sh
TIER ?= dev
TICKET ?= $(shell git -C $(HERE) rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's#^feat/##; s#[^A-Za-z0-9._-]#-#g' | cut -c1-40)
CONFIG ?= $(HERE)config/bearings.json
TICKET_FLAG := $(if $(filter stable,$(TIER)),,--ticket $(TICKET))
ARGS := $(TICKET_FLAG) --config $(CONFIG)

.PHONY: help serve wait stop status url ask migrate test lint image upgrade sitrep sitrep-build sitrep-check
help:
	@sed -n '1,15p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
serve:
	$(BIN) $(TIER) serve $(ARGS) $(if $(SESSION),--session $(SESSION)) $(if $(MODEL),--model $(MODEL)) $(if $(WORKING_ON),--working-on "$(WORKING_ON)")
wait:
	$(BIN) $(TIER) wait $(ARGS)
stop:
	$(BIN) $(TIER) stop $(ARGS)
status:
	$(BIN) $(TIER) status $(ARGS)
url:
	$(BIN) $(TIER) url $(ARGS)
ask:
	@test -n "$(Q)" || { echo "make ask Q=<questions.json>" >&2; exit 2; }
	$(BIN) $(TIER) ask $(ARGS) $(Q)
migrate:
	@test -n "$(FROM)" || { echo "make migrate FROM=<page-dir>" >&2; exit 2; }
	$(BIN) $(TIER) migrate $(ARGS) $(FROM) $(if $(FORCE),--force)
sitrep-build:
	node $(HERE)scripts/sitrep-build.mjs --tier $(TIER) $(TICKET_FLAG) --config $(CONFIG) $(if $(OUT),--out $(OUT)) $(if $(SAVE),--save)
sitrep-check:
	@test -n "$(PAYLOAD)" || { echo "make sitrep-check PAYLOAD=<file>" >&2; exit 2; }
	node $(HERE)scripts/sitrep-check.mjs $(PAYLOAD) --config $(CONFIG)
sitrep:
	@test -n "$(PAYLOAD)" || { echo "make sitrep TIER=<tier> PAYLOAD=<file> [TO=<message-id>]" >&2; exit 2; }
	$(BIN) $(TIER) sitrep $(ARGS) --payload $(PAYLOAD) $(if $(TO),--to $(TO))
test:
	bash $(HERE)tests/run-tests.sh
image:
	bash $(HERE)tests/run-tests.sh --image-only
lint:
	bash -n $(BIN) && node --check $(HERE)scripts/server.mjs && node --check $(HERE)scripts/wait.mjs && node --check $(HERE)scripts/reply.mjs && node --check $(HERE)scripts/lib/config.mjs && node --check $(HERE)scripts/lib/sitrep.mjs && node --check $(HERE)scripts/sitrep-check.mjs && node --check $(HERE)scripts/sitrep-build.mjs
	bash $(HERE)tests/run-tests.sh --lint-only
# upgrade: the stable tier always runs the main checkout. Pull main, then restart
# stable so server.mjs changes take effect (page.html is re-read per request anyway).
upgrade:
	git -C $(HERE) fetch -q origin main 2>/dev/null || true
	@b=$$(git -C $(HERE) rev-parse --abbrev-ref HEAD); [ "$$b" = main ] || { echo "upgrade runs from the main checkout, not $$b" >&2; exit 3; }
	git -C $(HERE) pull -q --ff-only origin main 2>/dev/null || echo "no remote yet; using local main" >&2
	-$(BIN) stable stop --config $(CONFIG)
	$(BIN) stable serve --config $(CONFIG) $(if $(SESSION),--session $(SESSION)) $(if $(MODEL),--model $(MODEL)) $(if $(WORKING_ON),--working-on "$(WORKING_ON)")
