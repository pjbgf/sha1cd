//go:build !noasm && gc && arm64 && !amd64 && sha1cd_asmtest

package sha1cd

import (
	"math/rand"
	"testing"

	shared "github.com/pjbgf/sha1cd/internal"
)

//go:noescape
func callBlockARM64DirtyRegs(h []uint32, p []byte, m1 []uint32, cs [][5]uint32)

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
		callBlockARM64DirtyRegs(hp[:], p, m1p[:], csp[:])

		if h != want.h {
			t.Fatalf("block %d: blockARM64 h = %08x, want %08x", i, h, want.h)
		}
		if hp != h {
			t.Errorf("block %d: dirty registers: h = %08x, want %08x", i, hp, h)
		}
		if m1p != m1 {
			t.Errorf("block %d: dirty registers: m1 differs", i)
		}
		if csp != cs {
			t.Errorf("block %d: dirty registers: cs differs", i)
		}
	}
}

// FuzzBlockARM64 checks blockARM64 against blockGeneric and against an
// independently computed message schedule, over fuzzed block contents and
// chaining states, with and without the registers the function does not own
// poisoned. The digest only exposes h, so a fault confined to m1 or cs is
// invisible unless the input reaches the collision detection logic.
func FuzzBlockARM64(f *testing.F) {
	if !hasSHA1 {
		f.Skip("CPU does not support SHA1 instructions")
	}

	seedBlockCorpus(f)

	f.Fuzz(func(t *testing.T, p []byte, h0, h1, h2, h3, h4 uint32) {
		if len(p) < shared.Chunk {
			return
		}

		in := [shared.WordBuffers]uint32{h0, h1, h2, h3, h4}
		p = p[:shared.Chunk]

		h, m1, cs := checkBlockASM(t, blockARM64, in, p)
		hd, m1d, csd := checkBlockASM(t, callBlockARM64DirtyRegs, in, p)

		if hd != h {
			t.Errorf("dirty registers: h\nwanted: %08x\n   got: %08x", h, hd)
		}
		if m1d != m1 {
			t.Errorf("dirty registers: m1\nwanted: %08x\n   got: %08x", m1, m1d)
		}
		if csd != cs {
			t.Errorf("dirty registers: cs\nwanted: %08x\n   got: %08x", cs, csd)
		}
	})
}
