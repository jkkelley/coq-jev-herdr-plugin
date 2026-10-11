# interface/ - the interface-agent seat's scripts (WO-20261011-e618).
#   make test        the suite in the lint image (bash, jq, python3 + jsonschema; no host deps)
#   make test-host   the suite on this host
#   make up          bring the interface-agent seat up (herdr/bin/seat.sh, brief.txt as its task); its tab holds the bearings serve and wait panes
#   make check       seat.sh --check interface: one line per difference, exit 1 if any
#   make down        seat.sh --down interface (the bearings panes go back to OPEN slots on make -C tools/bearings stop)
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(HERE)/..)
LINT_IMAGE ?= ghcr.io/jkkelley/coq-lint:1
.PHONY: test test-host up check down
test:
	podman run --rm --network=none -v "$(REPO)":/w:Z -w /w $(LINT_IMAGE) bash interface/tests/run.sh
test-host:
	bash $(HERE)tests/run.sh
up:
	$(REPO)/herdr/bin/seat.sh --role interface-agent --task "$$(cat $(HERE)brief.txt)"
check:
	$(REPO)/herdr/bin/seat.sh --check interface
down:
	$(REPO)/herdr/bin/seat.sh --down interface
