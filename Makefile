FUZZ_TIME ?= 1m

.PHONY: test
test:
	go test ./...

.PHONY: bench
bench:
	go test -benchmem -run=^$$ -bench ^Benchmark_ github.com/pjbgf/go-hardened-sha1/cgo

.PHONY: fuzz
fuzz:
	go test -fuzz=. -fuzztime=$(FUZZ_TIME) ./cgo/
