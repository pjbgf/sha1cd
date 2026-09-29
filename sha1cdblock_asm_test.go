//go:build !noasm && gc && (amd64 || arm64)

package sha1cd

import (
	"math/rand"
	"testing"

	shared "github.com/pjbgf/sha1cd/internal"
)

// blockFunc matches the assembly block implementations.
type blockFunc func(h []uint32, p []byte, m1 []uint32, cs [][5]uint32)

// seedBlockCorpus adds a block sized input for each of the chaining states
// and block contents worth starting from.
func seedBlockCorpus(f *testing.F) {
	f.Helper()

	blocks := [][]byte{
		make([]byte, shared.Chunk),
		repeatByte(0xff, shared.Chunk),
	}

	rng := rand.New(rand.NewSource(1))
	for i := 0; i < 4; i++ {
		b := make([]byte, shared.Chunk)
		rng.Read(b)
		blocks = append(blocks, b)
	}

	for _, b := range blocks {
		f.Add(b, uint32(shared.Init0), uint32(shared.Init1), uint32(shared.Init2),
			uint32(shared.Init3), uint32(shared.Init4))
		f.Add(b, uint32(0), uint32(0), uint32(0), uint32(0), uint32(0))
		f.Add(b, ^uint32(0), ^uint32(0), ^uint32(0), ^uint32(0), ^uint32(0))
	}
}

func repeatByte(v byte, n int) []byte {
	b := make([]byte, n)
	for i := range b {
		b[i] = v
	}
	return b
}

// checkBlockASM runs a single block through an assembly implementation and
// checks its outputs. The chaining state is an input rather than always being
// the initial vector, so that state dependent bugs are reachable.
func checkBlockASM(t *testing.T, fn blockFunc, in [shared.WordBuffers]uint32, p []byte) (
	[shared.WordBuffers]uint32, [shared.Rounds]uint32, [shared.PreStepState][shared.WordBuffers]uint32) {
	t.Helper()

	h := in
	m1 := [shared.Rounds]uint32{}
	cs := [shared.PreStepState][shared.WordBuffers]uint32{}
	fn(h[:], p, m1[:], cs[:])

	// m1 is the expanded message, which does not depend on the chaining state.
	if want := messageSchedule(p); m1 != want {
		t.Errorf("m1\nwanted: %08x\n   got: %08x", want, m1)
	}

	// cs[0] is the compression state before step 0, which is the chaining
	// state the block was entered with.
	if cs[0] != in {
		t.Errorf("cs[0]\nwanted: %08x\n   got: %08x", in, cs[0])
	}

	var dig digest
	dig.h = in
	blockGeneric(&dig, p)

	// blockGeneric rehashes a near-collision block, the assembly does not, so
	// only the states agree when no collision was detected.
	if !dig.col && h != dig.h {
		t.Errorf("h\nwanted: %08x\n   got: %08x", dig.h, h)
	}

	return h, m1, cs
}

// messageSchedule returns the SHA-1 expanded message for a single block,
// independently of any of the block implementations.
func messageSchedule(p []byte) [shared.Rounds]uint32 {
	var w [shared.Rounds]uint32

	for i := 0; i < 16; i++ {
		j := i * 4
		w[i] = uint32(p[j])<<24 | uint32(p[j+1])<<16 | uint32(p[j+2])<<8 | uint32(p[j+3])
	}
	for i := 16; i < shared.Rounds; i++ {
		t := w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16]
		w[i] = t<<1 | t>>31
	}

	return w
}
