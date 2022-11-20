FUZZ_TIME ?= 1m

.PHONY: test
test:
	go test ./...

.PHONY: bench
bench:
	go test -benchmem -run=^$$ -bench ^Benchmark ./...

.PHONY: fuzz
fuzz:
	go test -fuzz=. -fuzztime=$(FUZZ_TIME) ./test/
