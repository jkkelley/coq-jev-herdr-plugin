# report/sitrep - the owner's SITREP page from a data file (WO-20261011-3d78).
#   make render ENTRY=entries/2026/10/20261011-sitrep-003.json [OUT=...]   build the page
#   make test                                                              suite in the lint image (python3 + jsonschema, no host deps)
#   make test-host                                                         suite on this host
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(HERE)/../..)
LINT_IMAGE ?= ghcr.io/jkkelley/coq-lint:1
ENTRY ?=
OUT ?= $(HERE)out/sitrep.html
.PHONY: render test test-host
render:
	@[ -n "$(ENTRY)" ] || { echo "make render ENTRY=<entry.json> [OUT=file]" >&2; exit 2; }
	bash $(HERE)sitrep.sh render "$(ENTRY)" --out "$(OUT)"
test:
	podman run --rm --network=none -v "$(REPO)":/w:Z -w /w $(LINT_IMAGE) bash report/sitrep/tests/run.sh
test-host:
	bash $(HERE)tests/run.sh

# image: the root Makefile's `images` target runs `make -C <tool> image` for every TOOLS entry (Makefile line 24) and
# report/sitrep had no such target, so every `make step` on a checkout carrying PR 16 died with "No rule to make target
# 'image'" (2026-10-11 17:28Z, architect records branch). The suite runs inside the lint image, which `images` has already
# built by the time it gets here, so there is nothing to build: the target exists so the foreach succeeds. Rejected: a
# sitrep-specific image, which would duplicate the lint image for python3 + jsonschema. Record: WO-20261010-329d notes.
image:
	@true
