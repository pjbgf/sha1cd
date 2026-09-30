//go:build !noasm && gc && amd64

package cpu

// cpuid and xgetbv are implemented in cpu_amd64.s.
func cpuid(eaxArg, ecxArg uint32) (eax, ebx, ecx, edx uint32)
func xgetbv() (eax, edx uint32)

func init() {
	const (
		// CPUID EAX=1: ECX
		ssse3   = 1 << 9
		sse41   = 1 << 19
		osxsave = 1 << 27
		avx     = 1 << 28

		// CPUID EAX=7, ECX=0: EBX
		sha = 1 << 29

		// XCR0
		xmmState = 1 << 1
		ymmState = 1 << 2
	)

	maxID, _, _, _ := cpuid(0, 0)
	if maxID < 1 {
		return
	}

	_, _, ecx1, _ := cpuid(1, 0)
	X86.HasSSSE3 = ecx1&ssse3 != 0
	X86.HasSSE41 = ecx1&sse41 != 0

	// VEX encoded instructions also need the OS to preserve the YMM state,
	// which XGETBV reports once OSXSAVE says it is available.
	if ecx1&(osxsave|avx) == osxsave|avx {
		xcr0, _ := xgetbv()
		X86.HasAVX = xcr0&(xmmState|ymmState) == xmmState|ymmState
	}

	if maxID < 7 {
		return
	}
	_, ebx7, _, _ := cpuid(7, 0)
	X86.HasSHA = ebx7&sha != 0
}
