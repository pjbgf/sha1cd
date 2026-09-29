//go:build !noasm && gc && arm64 && !amd64

package sha1cd

import (
	"math/rand"
	"testing"

	shared "github.com/pjbgf/sha1cd/internal"
)

//go:noescape
func blockARM64Poisoned(h []uint32, p []byte, m1 []uint32, cs [][5]uint32)

// TestBlockARM64IgnoresRegisterState checks that blockARM64 produces the same
// output regardless of the register values it is entered with. It previously
// read R16 without initialising it, and skipped the block when R16 was within
// 64 of 2^64.
func TestBlockARM64IgnoresRegisterState(t *testing.T) {
	if !hasSHA1 {
		t.Skip("CPU does not support SHA1 instructions")
	}

	rng := rand.New(rand.NewSource(1))
	p := make([]byte, shared.Chunk)

	for i := 0; i < 16; i++ {
		rng.Read(p)

		var want digest
		want.Reset()
		blockGeneric(&want, p)

		h := [shared.WordBuffers]uint32{shared.Init0, shared.Init1, shared.Init2, shared.Init3, shared.Init4}
		m1 := [shared.Rounds]uint32{}
		cs := [shared.PreStepState][shared.WordBuffers]uint32{}
		blockARM64(h[:], p, m1[:], cs[:])

		hp := [shared.WordBuffers]uint32{shared.Init0, shared.Init1, shared.Init2, shared.Init3, shared.Init4}
		m1p := [shared.Rounds]uint32{}
		csp := [shared.PreStepState][shared.WordBuffers]uint32{}
		blockARM64Poisoned(hp[:], p, m1p[:], csp[:])

		if h != want.h {
			t.Fatalf("block %d: blockARM64 h = %08x, want %08x", i, h, want.h)
		}
		if hp != h {
			t.Errorf("block %d: poisoned registers: h = %08x, want %08x", i, hp, h)
		}
		if m1p != m1 {
			t.Errorf("block %d: poisoned registers: m1 differs", i)
		}
		if csp != cs {
			t.Errorf("block %d: poisoned registers: cs differs", i)
		}
	}
}
