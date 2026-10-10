# herdr/ - the seat lifecycle (SPEC-04). Every target is a thin call into a script in bin/.
#   make -C herdr test            the seat suite in Podman against a headless scratch herdr (tests/run.sh)
#   make -C herdr image           build the suite image once
#   make -C herdr lint            configs and layouts against their schemas, shellcheck on bin/ and tests/
#   make -C herdr up TICKET=WO-.. ROLE=worker [WORKTREE=dir]   one seat (bin/seat.sh)
#   make -C herdr check NAME=..   / down NAME=..  / audit
#   make -C herdr bringup         the bring-up DAG (bin/bringup.sh); recover [MODE=--check|--apply]
#   make -C herdr monitors        the three 3x3 monitoring tabs (bin/monitors.sh grid)
#   make -C herdr unfreeze SEAT=.. [FORCE=1] / unfreeze-all   break glass for a stuck compaction-guard lease (bin/unfreeze.sh)
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
WORKTREE ?= $(abspath $(HERE)..)
MODE ?= --check
.PHONY: help test image lint up check down audit bringup recover monitors unfreeze unfreeze-all
help:
	@sed -n '1,8p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
test:
	bash $(HERE)tests/run.sh
image:
	bash $(HERE)tests/run.sh --image-only
lint:
	for c in $(HERE)config/*.json; do case $$c in *.schema.json) continue;; esac; s=$${c%.json}.schema.json; python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$$c" "$$s"; done
	for l in $(HERE)layouts/*.json; do case $$l in *.schema.json) continue;; esac; python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$$l" $(HERE)layouts/layout.schema.json; done
	shellcheck -S warning $(HERE)bin/*.sh $(HERE)tests/run.sh $(HERE)tests/lib/*.sh $(HERE)tests/cases/*.sh $(HERE)tests/stubs/*
up:
	@test -n "$(TICKET)" && test -n "$(ROLE)" || { echo "make up TICKET=WO-.. ROLE=.. [WORKTREE=dir]" >&2; exit 2; }
	$(HERE)bin/seat.sh --ticket $(TICKET) --role $(ROLE) --worktree $(WORKTREE)
check:
	$(HERE)bin/seat.sh --check $(NAME)
down:
	$(HERE)bin/seat.sh --down $(NAME)
audit:
	$(HERE)bin/seat.sh --audit
bringup:
	$(HERE)bin/bringup.sh
recover:
	$(HERE)bin/recover.sh $(MODE)
monitors:
	$(HERE)bin/monitors.sh grid
# make unfreeze SEAT=<seat-name|pane-id> [FORCE=1]   break glass: release that seat's guard lease and wake it (never your own)
# make unfreeze-all                                one pass over every seat: release expired leases
unfreeze:
	@test -n "$(SEAT)" || { echo "make unfreeze SEAT=<seat-name|pane-id> [FORCE=1]" >&2; exit 2; }
	$(HERE)bin/unfreeze.sh $(SEAT) $(if $(FORCE),--force)
unfreeze-all:
	$(HERE)bin/unfreeze.sh --all
