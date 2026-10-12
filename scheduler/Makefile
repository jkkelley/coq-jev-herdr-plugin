# scheduler/Makefile - the one entry point of the Go scheduler (SPEC-16.H h-build, SPEC-16 l-make).
#
#   make -C scheduler build        static binary into dist/, built in the pinned Go image
#   make -C scheduler test         go test over the module ($(PKG), default ./...) in the test image, network off
#   make -C scheduler lint         go vet and the gofmt check in the pinned Go image, network off
#   make -C scheduler image        the runtime image: one static binary, no shell, proven by running a shell in it
#   make -C scheduler proto        regenerate api/ from the proto in the pinned Go image; git diff must stay empty
#   make -C scheduler run          the scheduler container in the foreground of its pane (host/bin/run.sh)
#   make -C scheduler run-exec     the executor in the foreground of its pane (host/bin/run-exec.sh)
#   make -C scheduler status       the status subcommand from the runtime image, STATE_DIR mounted for the control socket
#   make -C scheduler clean        dist/ and the local images
#
# No Go toolchain runs on the host (SPEC-16.H h-build-rule, SPEC-16.K k-examples NEVER): every Go command below is a
# podman run of the digest-pinned Go image or of the test image built from it. The module cache and the build cache
# live in one named volume, so only deps (the first build, or a version change) needs the network; test and lint run
# with --network=none. run-exec is the one target whose process is on the host, because the executor is the host half
# by design (DEC-scheduler-two-processes): it runs the static binary make build produced, never the toolchain.
HERE := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
REPO := $(patsubst %/,%,$(dir $(HERE)))

# The Go image every build, test, lint and generation runs in. Repin together with tests/Containerfile and the
# builder stage of Containerfile:
#   podman pull docker.io/library/golang:1.26-bookworm
#   podman image inspect docker.io/library/golang:1.26-bookworm --format '{{index .RepoDigests 0}}'
GO_IMAGE := docker.io/library/golang@sha256:116d58cbd88c1297624acc6e967a060012422bacf9930927e23fb719189c6f36
TEST_IMAGE := localhost/coq-scheduler-test:1
IMAGE := localhost/coq-scheduler:1
CACHE_VOLUME := coq-scheduler-gocache
PKG ?= ./...
VERSION ?= $(shell git -C "$(HERE)" describe --always --dirty 2>/dev/null || echo dev)

# The code generators, pinned. protoc-gen-go comes from the protobuf module go.mod pins; protoc-gen-go-grpc is its
# own module and is installed by version here, so it never enters go.mod (SPEC-16.H h-build-deps). protoc comes from
# the Go image's Debian release; its version is asserted, because it is written into every generated file's header.
PROTOC_GEN_GO_GRPC_VERSION := v1.6.2
PROTOC_VERSION := 3.21.12

# BREADCRUMB 2026-10-12 - WO-20261012-48ab. Why --userns=keep-id with the volume's :U flag: dist/ and go.sum are written
#   into the bind-mounted scheduler directory, and under keep-id the container user is the host user, so they land owned
#   by the owner and `make clean` needs no sudo. :U hands the named cache volume to that same user, or the first go
#   command fails writing the cache. The repository is mounted read-only at /repo (testkit reads events/bin/event.sh and
#   the factory tables from it) and the scheduler directory read-write over /repo/scheduler, so nothing but this
#   module's own outputs can be written. GOTOOLCHAIN=local stops a go line in go.mod from downloading another toolchain
#   behind the pinned image's back; -buildvcs=false because a worktree's .git file names a host path the container
#   cannot see. Rejected: running as container root (files owned by a mapped root on some hosts) and a host GOPATH
#   mount (binds the owner's home into every build).
RUN_GO = podman run --rm --userns=keep-id \
  -e HOME=/tmp -e GOCACHE=/cache/build -e GOMODCACHE=/cache/mod -e GOFLAGS=-buildvcs=false -e GOTOOLCHAIN=local \
  -v $(CACHE_VOLUME):/cache:U -v "$(REPO):/repo:ro" -v "$(HERE):/repo/scheduler" -w /repo/scheduler
OFFLINE = --network=none -e GOPROXY=off

.PHONY: help deps build test lint image test-image proto contract run run-exec status clean
help:
	@sed -n 's/^#   //p' $(HERE)/Makefile

# deps fills the module cache and writes go.sum (gitignored; every sum is checked against the Go checksum database on
# the way in). It is the only Go step with the network, and every other target runs it first; it is a no-op once the
# cache holds the pinned versions.
deps:
	$(RUN_GO) $(GO_IMAGE) go mod download -json all >/dev/null

build: deps
	$(RUN_GO) $(OFFLINE) -e CGO_ENABLED=0 $(GO_IMAGE) \
	  go build -trimpath -ldflags "-s -w -X coq/scheduler/internal/cli.version=$(VERSION)" -o dist/scheduler ./cmd/scheduler
	@file "$(HERE)/dist/scheduler" 2>/dev/null || ls -l "$(HERE)/dist/scheduler"

test-image:
	podman image exists $(TEST_IMAGE) || podman build -q -t $(TEST_IMAGE) -f $(HERE)/tests/Containerfile $(HERE)/tests >/dev/null

test: deps test-image
	$(RUN_GO) $(OFFLINE) $(TEST_IMAGE) go test -count=1 $(PKG)

lint: deps
	$(RUN_GO) $(OFFLINE) $(GO_IMAGE) sh -c 'go vet ./... && out=$$(gofmt -l .) && { [ -z "$$out" ] || { echo "gofmt needed:"; echo "$$out"; exit 1; }; }'

# image builds the runtime image, then proves SPEC-16.H h-t6: the binary answers, and a shell as the command fails
# because there is no shell to run.
image:
	podman build -q -t $(IMAGE) --build-arg VERSION=$(VERSION) -f $(HERE)/Containerfile $(HERE) >/dev/null
	podman run --rm --network=none $(IMAGE) version
	@if podman run --rm --network=none --entrypoint /bin/sh $(IMAGE) -c true >/dev/null 2>&1; then \
	  echo "image: a shell ran inside $(IMAGE); the runtime image must hold the binary only" >&2; exit 3; fi
	@echo "image: $(IMAGE) holds the binary only; a shell as the command fails"

# proto runs as the container's root (rootless podman maps it to the owner) because it installs protoc with apt.
proto: deps
	podman run --rm -e GOTOOLCHAIN=local -e GOFLAGS=-buildvcs=false -v "$(HERE):/src" -w /src $(GO_IMAGE) sh -euc '\
	  apt-get update -qq >/dev/null && apt-get install -y -qq --no-install-recommends protobuf-compiler >/dev/null; \
	  v=$$(protoc --version); [ "$$v" = "libprotoc $(PROTOC_VERSION)" ] || { echo "proto: want libprotoc $(PROTOC_VERSION), got $$v" >&2; exit 3; }; \
	  go install google.golang.org/protobuf/cmd/protoc-gen-go; \
	  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@$(PROTOC_GEN_GO_GRPC_VERSION); \
	  protoc -I api --go_out=api --go_opt=paths=source_relative --go-grpc_out=api --go-grpc_opt=paths=source_relative \
	    api/scheduler/v1/scheduler.proto'

# contract runs the contract suite of SPEC-16.K k-contract in the test image; its script belongs to the contract ticket.
contract: deps test-image
	$(RUN_GO) $(OFFLINE) $(TEST_IMAGE) bash tests/contract/run.sh

run:
	bash $(HERE)/host/bin/run.sh

run-exec:
	bash $(HERE)/host/bin/run-exec.sh

status:
	@[ -n "$(STATE_DIR)" ] || { echo "status: STATE_DIR=<the scheduler state directory> is required" >&2; exit 2; }
	podman run --rm --network=none --userns=keep-id -v "$(REPO):/repo:ro" -v "$(STATE_DIR):$(STATE_DIR)" $(IMAGE) status $(ARGS)

clean:
	rm -rf $(HERE)/dist
	-podman rmi -f $(IMAGE) $(TEST_IMAGE) >/dev/null 2>&1
