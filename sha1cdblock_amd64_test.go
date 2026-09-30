//go:build !noasm && gc && amd64 && !arm64

package sha1cd

import (
	"math/rand"
	"os"
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

// TestScheduleAVX2 checks both lanes of the AVX2 message schedule against an
// independent expansion, including when both lanes hold the same block.
func TestScheduleAVX2(t *testing.T) {
	t.Parallel()

	if !hasAVX2 {
		t.Skip("CPU does not support AVX2 and BMI2")
	}

	rng := rand.New(rand.NewSource(5))
	p := make([]byte, 2*shared.Chunk)
	for i := 0; i < 256; i++ {
		rng.Read(p)

		var m1 [2][shared.Rounds]uint32
		scheduleAVX2(&p[0], &p[shared.Chunk], &m1[0], &m1[1])
		if want := messageSchedule(p[:shared.Chunk]); m1[0] != want {
			t.Fatalf("first lane\nwanted: %08x\n   got: %08x", want, m1[0])
		}
		if want := messageSchedule(p[shared.Chunk:]); m1[1] != want {
			t.Fatalf("second lane\nwanted: %08x\n   got: %08x", want, m1[1])
		}

		var same [shared.Rounds]uint32
		scheduleAVX2(&p[0], &p[0], &same, &same)
		if same != m1[0] {
			t.Fatal("expanding a block into both lanes differs from expanding it once")
		}
	}
}

// TestBlockAVX2MatchesGeneric hashes the collision files with blockAVX2, which
// must detect the same collisions as blockGeneric and end in the same state.
func TestBlockAVX2MatchesGeneric(t *testing.T) {
	t.Parallel()

	if !hasAVX2 {
		t.Skip("CPU does not support AVX2 and BMI2")
	}

	for _, name := range []string{"shattered-1.pdf", "shattered-2.pdf", "sha-mbles-1.bin", "sha-mbles-2.bin", "valid-file.txt"} {
		data, err := os.ReadFile("test/testdata/files/" + name)
		if err != nil {
			t.Fatal(err)
		}
		// An odd number of blocks exercises the single block schedule too.
		for _, n := range []int{len(data), len(data) - shared.Chunk} {
			if n < 0 {
				continue
			}
			p := data[:n&^(shared.Chunk-1)]

			var want, got digest
			want.Reset()
			got.Reset()
			blockGeneric(&want, p)
			blockAVX2(&got, p)
			if got.h != want.h || got.col != want.col {
				t.Errorf("%s (%d bytes): h = %08x col = %v, want %08x col = %v",
					name, len(p), got.h, got.col, want.h, want.col)
			}
		}
	}
}

// FuzzBlockAVX2 checks the AVX2 schedule and BMI2 rounds against an
// independent compression, over fuzzed blocks and chaining states. Unlike
// SHA-NI, the rounds record the states before steps 58 and 65 directly.
func FuzzBlockAVX2(f *testing.F) {
	if !hasAVX2 {
		f.Skip("CPU does not support AVX2 and BMI2")
	}

	seedBlockCorpus(f)

	f.Fuzz(func(t *testing.T, p []byte, h0, h1, h2, h3, h4 uint32) {
		if len(p) < shared.Chunk {
			return
		}
		p = p[:shared.Chunk]

		var m1 [2][shared.Rounds]uint32
		scheduleAVX2(&p[0], &p[0], &m1[0], &m1[1])
		w := messageSchedule(p)
		if m1[0] != w || m1[1] != w {
			t.Fatalf("m1\nwanted: %08x\n   got: %08x", w, m1[0])
		}

		in := [shared.WordBuffers]uint32{h0, h1, h2, h3, h4}
		h := in
		cs := [shared.PreStepState][shared.WordBuffers]uint32{}
		roundsBMI2(&h, &m1[0], &cs)

		wantH, wantCS := referenceBlock(in, w)
		if h != wantH {
			t.Errorf("h\nwanted: %08x\n   got: %08x", wantH, h)
		}
		if cs != wantCS {
			t.Errorf("cs\nwanted: %08x\n   got: %08x", wantCS, cs)
		}
	})
}

func BenchmarkBlock(b *testing.B) {
	p := make([]byte, 8192)
	rand.New(rand.NewSource(1)).Read(p)

	impls := []struct {
		name string
		ok   bool
		fn   func(*digest, []byte)
	}{
		{"shani", hasSHANI, blockSHANI},
		{"avx2", hasAVX2, blockAVX2},
		{"generic", true, blockGeneric},
	}
	for _, impl := range impls {
		b.Run(impl.name, func(b *testing.B) {
			if !impl.ok {
				b.Skip("not supported by this CPU")
			}
			var d digest
			d.Reset()
			b.SetBytes(int64(len(p)))
			for i := 0; i < b.N; i++ {
				impl.fn(&d, p)
			}
		})
	}
}
