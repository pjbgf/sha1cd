// Package cpu detects the CPU features that sha1cd dispatches on.
//
// It covers only what the assembly implementations need, which keeps
// start up cheap and avoids an external dependency. Every flag is false
// where a feature cannot be detected safely, which selects the generic
// implementation.
package cpu

// X86 holds the features of the current amd64 CPU. All flags are false on
// other architectures.
var X86 struct {
	// HasAVX is set only when the OS also preserves the YMM state.
	HasAVX   bool
	HasSHA   bool
	HasSSSE3 bool
	HasSSE41 bool
}

// ARM64 holds the features of the current arm64 CPU. All flags are false on
// other architectures.
var ARM64 struct {
	HasSHA1 bool
}
