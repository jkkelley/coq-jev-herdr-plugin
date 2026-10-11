# report/loop - the factory board (WO-20261011-616c). Every target is a thin call into loop.sh or a test script.
#   make -C report/loop test           the case suite in Podman, --network=none (tests/run.sh)
#   make -C report/loop test-browser   the page in a real browser: pixel parity with the locked design, redraw in place (tests/browser.sh)
#   make -C report/loop image          build the suite image once
#   make -C report/loop lint           config and fixtures against their schemas, shellcheck on loop.sh and the tests
#   make -C report/loop render         validate and draw out/data.json into out/index.html
#   make -C report/loop watch          collect every watch_seconds and rewrite out/ only on a change (run it in a labelled herdr pane)
# The blueprint view (WO-20261011-ceea, report/blueprint): the system design from graph/ and work-orders/, in the same page.
#   make -C report/loop render-blueprint   one collect and render of the blueprint into the dev tier's out_dir
#   make -C report/loop serve-dev          dev tier in the foreground: serves and refreshes its own page (run it in a labelled herdr pane)
#   make -C report/loop serve-uat          uat tier in the foreground: serves the build promote-uat put there
#   make -C report/loop serve-stable       stable tier in the foreground: serves the build promote-stable put there
#   make -C report/loop promote-uat        move dev's current build to uat, tagged by its build number; never copy a page by hand
#   make -C report/loop promote-stable     move uat's build to stable
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
.PHONY: help test test-browser image lint render watch render-blueprint serve-dev serve-uat serve-stable promote-uat promote-stable
help:
	@sed -n '1,14p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
test:
	bash $(HERE)tests/run.sh
test-browser:
	bash $(HERE)tests/browser.sh
image:
	bash $(HERE)tests/run.sh --image-only
lint:
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/board.json $(HERE)config/board.schema.json
	python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)config/blueprint.json $(HERE)config/blueprint.schema.json
	for t in dev uat stable; do python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" $(HERE)../blueprint/config/$$t.json $(HERE)../blueprint/config/tier.schema.json; done
	for f in $(HERE)tests/fixtures/*.json; do $(HERE)loop.sh validate "$$f"; done
	jq -e --slurpfile d $(HERE)../blueprint/config/dev.json '.out_dir == $$d[0].out_dir' $(HERE)config/blueprint.json >/dev/null || { echo 'the blueprint view out_dir and the dev tier out_dir differ' >&2; exit 1; }
	jq -e --slurpfile b $(HERE)config/board.json '.board_dir == $$b[0].out_dir' $(HERE)../../tools/bearings/config/bearings.json >/dev/null || { echo 'bearings board_dir and the board config out_dir differ' >&2; exit 1; }
	shellcheck -S warning $(HERE)loop.sh $(HERE)lib/blueprint/gather.sh $(HERE)../blueprint/serve.sh $(HERE)../blueprint/bin/promote.sh $(HERE)tests/run.sh $(HERE)tests/browser.sh $(HERE)tests/lib/*.sh $(HERE)tests/cases/*.sh
render:
	$(HERE)loop.sh render
watch:
	$(HERE)loop.sh watch
render-blueprint:
	$(HERE)loop.sh --view blueprint collect --out $(HERE)../../$$(jq -r .out_dir $(HERE)config/blueprint.json)/data.json
	$(HERE)loop.sh --view blueprint render
serve-dev serve-uat serve-stable: serve-%:
	$(HERE)../blueprint/serve.sh $*
promote-uat promote-stable: promote-%:
	$(HERE)../blueprint/bin/promote.sh $*
