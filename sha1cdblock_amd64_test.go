//go:build !noasm && gc && amd64 && !arm64

package sha1cd

import (
	"math/rand"
	"testing"

	shared "github.com/pjbgf/sha1cd/internal"
)

func initState() [shared.WordBuffers]uint32 {
	return [shared.WordBuffers]uint32{shared.Init0, shared.Init1, shared.Init2, shared.Init3, shared.Init4}
}

// blockAMD64 must compress exactly one chunk per call. The collision detection
// in block() inspects m1 and cs once per call, so a call that compressed more
// than one chunk would leave every chunk but the last unchecked.
func TestBlockAMD64CompressesASingleChunk(t *testing.T) {
	t.Parallel()

	if !hasSHANI {
		t.Skip("CPU does not support SHA-NI")
	}

	rng := rand.New(rand.NewSource(7))
	p := make([]byte, 2*shared.Chunk)
	rng.Read(p)

	m1 := [shared.Rounds]uint32{}
	cs := [shared.PreStepState][shared.WordBuffers]uint32{}

	whole := initState()
	blockAMD64(whole[:], p, m1[:], cs[:])
	wholeM1 := m1

	first := initState()
	blockAMD64(first[:], p[:shared.Chunk], m1[:], cs[:])
	firstM1 := m1

	if whole != first {
		t.Errorf("h after a %d-byte call = %08x, want the first chunk only %08x",
			len(p), whole, first)
	}
	if wholeM1 != firstM1 {
		t.Error("m1 after a two-chunk call does not match the first chunk: a later chunk overwrote it")
	}
}

// A length that is not a whole number of chunks must be truncated down, never
// walked past the end of p.
func TestBlockAMD64TruncatesPartialChunks(t *testing.T) {
	t.Parallel()

	if !hasSHANI {
		t.Skip("CPU does not support SHA-NI")
	}

	rng := rand.New(rand.NewSource(11))
	p := make([]byte, 2*shared.Chunk)
	rng.Read(p)

	m1 := [shared.Rounds]uint32{}
	cs := [shared.PreStepState][shared.WordBuffers]uint32{}

	want := initState()
	blockAMD64(want[:], p[:shared.Chunk], m1[:], cs[:])

	partial := initState()
	blockAMD64(partial[:], p[:shared.Chunk+36], m1[:], cs[:])
	if partial != want {
		t.Errorf("h for a %d-byte call = %08x, want the whole chunk only %08x",
			shared.Chunk+36, partial, want)
	}

	short := initState()
	blockAMD64(short[:], p[:shared.Chunk-1], m1[:], cs[:])
	if short != initState() {
		t.Errorf("h for a short call = %08x, want it left untouched %08x", short, initState())
	}
}

// FuzzBlockAMD64 checks blockAMD64 against blockGeneric and against an
// independently computed message schedule, over fuzzed block contents and
// chaining states. The digest only exposes h, so a fault confined to m1 or cs
// is invisible unless the input reaches the collision detection logic.
func FuzzBlockAMD64(f *testing.F) {
	if !hasSHANI {
		f.Skip("CPU does not support SHA-NI instructions")
	}

	seedBlockCorpus(f)

	f.Fuzz(func(t *testing.T, p []byte, h0, h1, h2, h3, h4 uint32) {
		if len(p) < shared.Chunk {
			return
		}

		in := [shared.WordBuffers]uint32{h0, h1, h2, h3, h4}
		checkBlockASM(t, blockAMD64, in, p[:shared.Chunk])
	})
}
