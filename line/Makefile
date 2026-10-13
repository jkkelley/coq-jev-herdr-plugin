# line - entry points for the line scripts (SPEC-17). Every target is a thin call into a script.
#   make test    the line suite, in Podman (tests/run.sh): the board cases T01 to T03 and T14
#   make image   build the pinned test image once (the seat suite's image)
#   make check   board.sh check against this checkout's config and the state root
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: help test image check
help:
	@sed -n '1,4p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
test:
	bash $(HERE)tests/run.sh
image:
	bash $(HERE)tests/run.sh --image-only
check:
	bash $(HERE)bin/board.sh check
