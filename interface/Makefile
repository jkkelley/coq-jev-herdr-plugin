# interface/ - the interface-agent seat's scripts (WO-20261011-e618).
#   make test        the suite in the lint image (bash, jq, python3 + jsonschema; no host deps)
#   make test-host   the suite on this host
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(HERE)/..)
LINT_IMAGE ?= ghcr.io/jkkelley/coq-lint:1
.PHONY: test test-host
test:
	podman run --rm --network=none -v "$(REPO)":/w:Z -w /w $(LINT_IMAGE) bash interface/tests/run.sh
test-host:
	bash $(HERE)tests/run.sh
