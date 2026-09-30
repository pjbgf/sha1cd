//go:build !noasm && gc && linux && (amd64 || arm64)

package cpu

import (
	"os"
	"runtime"
	"strings"
	"testing"
)

// TestAgainstProcCpuinfo cross checks the detected features with the ones the
// Linux kernel reports.
func TestAgainstProcCpuinfo(t *testing.T) {
	t.Parallel()

	data, err := os.ReadFile("/proc/cpuinfo")
	if err != nil {
		t.Skip(err)
	}

	var line string
	for _, l := range strings.Split(string(data), "\n") {
		if strings.HasPrefix(l, "flags") || strings.HasPrefix(l, "Features") {
			line = l
			break
		}
	}
	if line == "" {
		t.Skip("no feature line in /proc/cpuinfo")
	}
	flags := map[string]bool{}
	for _, f := range strings.Fields(line[strings.Index(line, ":")+1:]) {
		flags[f] = true
	}

	check := func(name string, got, want bool) {
		t.Helper()
		if got != want {
			t.Errorf("%s = %v, /proc/cpuinfo says %v", name, got, want)
		}
	}
	switch runtime.GOARCH {
	case "amd64":
		check("X86.HasSHA", X86.HasSHA, flags["sha_ni"])
		check("X86.HasSSSE3", X86.HasSSSE3, flags["ssse3"])
		check("X86.HasSSE41", X86.HasSSE41, flags["sse4_1"])
		// The kernel hides these when it does not manage the matching state.
		check("X86.HasAVX", X86.HasAVX, flags["avx"])
		check("X86.HasAVX2", X86.HasAVX2, flags["avx2"])
		check("X86.HasAVX512F", X86.HasAVX512F, flags["avx512f"])
		check("X86.HasBMI1", X86.HasBMI1, flags["bmi1"])
		check("X86.HasBMI2", X86.HasBMI2, flags["bmi2"])
	case "arm64":
		check("ARM64.HasSHA1", ARM64.HasSHA1, flags["sha1"])
	}
}
