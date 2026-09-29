//go:build !noasm && gc && (amd64 || arm64)

package sha1cd

import (
	"math/bits"
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
// checks its outputs against an independent compression. The chaining state is
// an input rather than always being the initial vector, so that state
// dependent bugs are reachable.
func checkBlockASM(t *testing.T, fn blockFunc, in [shared.WordBuffers]uint32, p []byte) (
	[shared.WordBuffers]uint32, [shared.Rounds]uint32, [shared.PreStepState][shared.WordBuffers]uint32) {
	t.Helper()

	h := in
	m1 := [shared.Rounds]uint32{}
	cs := [shared.PreStepState][shared.WordBuffers]uint32{}
	fn(h[:], p, m1[:], cs[:])

	// The assembly returns the states before steps 56 and 64, which block()
	// advances to the ones the collision detection consumes.
	rectifyCompressionState(&m1, &cs)

	w := messageSchedule(p)
	if m1 != w {
		t.Errorf("m1\nwanted: %08x\n   got: %08x", w, m1)
	}

	wantH, wantCS := referenceBlock(in, w)
	if h != wantH {
		t.Errorf("h\nwanted: %08x\n   got: %08x", wantH, h)
	}
	if cs != wantCS {
		t.Errorf("cs\nwanted: %08x\n   got: %08x", wantCS, cs)
	}

	return h, m1, cs
}

// referenceBlock compresses a single block, returning the resulting chaining
// state along with the compression states before steps 0, 58 and 65, which are
// the ones the collision detection consumes.
func referenceBlock(in [shared.WordBuffers]uint32, w [shared.Rounds]uint32) (
	[shared.WordBuffers]uint32, [shared.PreStepState][shared.WordBuffers]uint32) {
	cs := [shared.PreStepState][shared.WordBuffers]uint32{}

	a, b, c, d, e := in[0], in[1], in[2], in[3], in[4]
	for i := 0; i < shared.Rounds; i++ {
		switch i {
		case 0:
			cs[0] = [shared.WordBuffers]uint32{a, b, c, d, e}
		case 58:
			cs[1] = [shared.WordBuffers]uint32{a, b, c, d, e}
		case 65:
			cs[2] = [shared.WordBuffers]uint32{a, b, c, d, e}
		}

		var f, k uint32
		switch {
		case i < 20:
			f, k = b&c|(^b)&d, shared.K0
		case i < 40:
			f, k = b^c^d, shared.K1
		case i < 60:
			f, k = (b|c)&d|b&c, shared.K2
		default:
			f, k = b^c^d, shared.K3
		}

		t := bits.RotateLeft32(a, 5) + f + e + w[i] + k
		a, b, c, d, e = t, a, bits.RotateLeft32(b, 30), c, d
	}

	h := [shared.WordBuffers]uint32{in[0] + a, in[1] + b, in[2] + c, in[3] + d, in[4] + e}

	return h, cs
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
