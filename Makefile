FUZZ_TIME ?= 1m
FUZZ_FLAGS ?=

# The fuzz targets of each package, along with the tags needed to build them.
FUZZ_TARGETS = ./test/:gofuzz .:sha1cd_asmtest

export CGO_ENABLED := 1

.PHONY: test
test:
	go test -race -timeout 15s -tags sha1cd_asmtest ./...

.PHONY: bench
bench:
	go test -benchmem -run=^$$ -bench ^Benchmark ./...

# go test only fuzzes a single target per invocation, so each one is run in
# turn for FUZZ_TIME.
.PHONY: fuzz
fuzz:
	@set -e; for entry in $(FUZZ_TARGETS); do \
		pkg="$${entry%%:*}"; tags="$${entry##*:}"; \
		for target in $$(go test -tags "$$tags" -list '^Fuzz' "$$pkg" | grep '^Fuzz' || true); do \
			echo "fuzzing $$target in $$pkg for $(FUZZ_TIME)"; \
			go test $(FUZZ_FLAGS) -tags "$$tags" -run '^$$' -fuzz "^$$target"'$$' \
				-fuzztime=$(FUZZ_TIME) "$$pkg"; \
		done; \
	done

# Cross build project in arm/v7.
build-arm:
	docker build -t sha1cd-arm -f Dockerfile.arm .
	docker run --rm sha1cd-arm

# Cross build project in arm64.
build-arm64:
	docker build -t sha1cd-arm64 -f Dockerfile.arm64 .
	docker run --rm sha1cd-arm64

# Build with cgo disabled.
build-nocgo:
	CGO_ENABLED=0 go build ./cgo

# Run cross-compilation to assure supported architectures.
cross-build: build-arm build-arm64 build-nocgo

verify:
	git diff --exit-code
	go vet ./...
