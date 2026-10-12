# factory/ - the route runner (SPEC-03 s-routes). Every target is a thin call into a script.
#   make -C factory test      the runner suite in Podman, --network=none, herdr stubbed (tests/run.sh)
#   make -C factory image     build the suite image once
#   make -C factory lint      runner.json and routes.json against their schemas, shellcheck on bin/ and tests/
#   make -C factory once      one tick of the runner against this checkout (bin/route.sh once)
#   make -C factory status    the belt age (bin/route.sh status); exit 1 when stale
#   make -C factory flow-once   one tick of the flow watch (bin/flow.sh once)
#   make -C factory flow-status the stalls now present (bin/flow.sh status); exit 1 when there is one
#   make -C factory policy-once   one tick of the policy watch (bin/policy.sh once)
#   make -C factory policy-status the escalations a policy covers that still wait (bin/policy.sh status); exit 1 when one is past its deadline
# The long-running form is bin/route.sh run, started in a labelled herdr pane by herdr/bin/bringup.sh, never from here.
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
.PHONY: help test image lint once status flow-once flow-status policy-once policy-status
help:
	@sed -n '1,11p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
test:
	bash $(HERE)tests/run.sh
image:
	bash $(HERE)tests/run.sh --image-only
lint:
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/runner.json $(HERE)config/runner.schema.json
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/routes.json $(HERE)config/routes.schema.json
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/flow.json $(HERE)config/flow.schema.json
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/policies.json $(HERE)config/policies.schema.json
	shellcheck -S warning $(HERE)bin/*.sh $(HERE)tests/run.sh $(HERE)tests/lib/*.sh $(HERE)tests/cases/*.sh
once:
	$(HERE)bin/route.sh once
status:
	$(HERE)bin/route.sh status
flow-once:
	$(HERE)bin/flow.sh once
flow-status:
	$(HERE)bin/flow.sh status
policy-once:
	$(HERE)bin/policy.sh once
policy-status:
	$(HERE)bin/policy.sh status
