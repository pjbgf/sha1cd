//go:build !cgo

package test

// cgoEnabled reports whether the cgo-backed reference implementation is real.
// With cgo disabled, github.com/pjbgf/sha1cd/cgo falls back to the Go
// implementation, so any differential against it compares the Go
// implementation with itself and can never fail.
const cgoEnabled = false
