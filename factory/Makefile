# factory/ - the route runner (SPEC-03 s-routes). Every target is a thin call into a script.
#   make -C factory test      the runner suite in Podman, --network=none, herdr stubbed (tests/run.sh)
#   make -C factory image     build the suite image once
#   make -C factory lint      runner.json and routes.json against their schemas, shellcheck on bin/ and tests/
#   make -C factory once      one tick of the runner against this checkout (bin/route.sh once)
#   make -C factory status    the belt age (bin/route.sh status); exit 1 when stale
# The long-running form is bin/route.sh run, started in a labelled herdr pane by herdr/bin/bringup.sh, never from here.
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
.PHONY: help test image lint once status
help:
	@sed -n '1,7p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
test:
	bash $(HERE)tests/run.sh
image:
	bash $(HERE)tests/run.sh --image-only
lint:
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/runner.json $(HERE)config/runner.schema.json
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/routes.json $(HERE)config/routes.schema.json
	shellcheck -S warning $(HERE)bin/*.sh $(HERE)tests/run.sh $(HERE)tests/lib/*.sh $(HERE)tests/cases/*.sh
once:
	$(HERE)bin/route.sh once
status:
	$(HERE)bin/route.sh status
