//go:build gofuzz
// +build gofuzz

package test

import (
	"bytes"
	"crypto/sha1"
	"encoding/binary"
	"encoding/hex"
	"testing"

	"github.com/pjbgf/sha1cd"
	"github.com/pjbgf/sha1cd/cgo"
	shared "github.com/pjbgf/sha1cd/internal"
	"github.com/pjbgf/sha1cd/ubc"
)

func FuzzDeviationDetection(f *testing.F) {
	requireCgo(f)

	for _, seed := range deviationSeeds(f) {
		f.Add(seed)
	}

	g := sha1cd.New().(sha1cd.CollisionResistantHash)
	c := cgo.New().(sha1cd.CollisionResistantHash)

	f.Fuzz(func(t *testing.T, in []byte) {
		cv, cc := sum(c, in)

		for _, generic := range []bool{false, true} {
			forceGeneric = generic

			gv, gc := sum(g, in)
			if !bytes.Equal(gv, cv) || gc != cc {
				t.Fatalf("generic=%v input: %q\n go result: %q %v\ncgo result: %q %v",
					generic, hex.EncodeToString(in), hex.EncodeToString(gv), gc,
					hex.EncodeToString(cv), cc)
			}

			// Absent a detected collision the digest must match SHA-1.
			if !gc {
				want := sha1.Sum(in)
				if !bytes.Equal(gv, want[:]) {
					t.Fatalf("generic=%v input: %q\n     result: %q\nsha1 result: %q",
						generic, hex.EncodeToString(in), hex.EncodeToString(gv),
						hex.EncodeToString(want[:]))
				}
			}
		}

		forceGeneric = false
	})
}

// FuzzWriteChunking fuzzes the sizes of the writes an input is split over,
// which drives the buffering of partial blocks in digest.Write.
func FuzzWriteChunking(f *testing.F) {
	requireCgo(f)

	for _, seed := range deviationSeeds(f) {
		f.Add(seed, []byte{1})
		f.Add(seed, []byte{63, 1})
		f.Add(seed, []byte{64})
	}

	g := sha1cd.New().(sha1cd.CollisionResistantHash)
	c := cgo.New().(sha1cd.CollisionResistantHash)

	f.Fuzz(func(t *testing.T, in, chunks []byte) {
		if len(chunks) == 0 {
			return
		}

		cv, cc := sum(c, in)

		g.Reset()
		rest := in
		for i := 0; len(rest) > 0; i++ {
			// The chunk sizes are offset by one so that the loop always
			// makes progress.
			n := int(chunks[i%len(chunks)]) + 1
			if n > len(rest) {
				n = len(rest)
			}
			g.Write(rest[:n])
			rest = rest[n:]
		}

		gv, gc := g.CollisionResistantSum(nil)
		if !bytes.Equal(gv, cv) || gc != cc {
			t.Fatalf("input: %q chunks: %q\n go result: %q %v\ncgo result: %q %v",
				hex.EncodeToString(in), hex.EncodeToString(chunks),
				hex.EncodeToString(gv), gc, hex.EncodeToString(cv), cc)
		}
	})
}

// FuzzCalculateDvMask fuzzes the expanded message the disturbance vector mask
// is derived from. Reaching the same states through hashing would require
// inputs the fuzzer cannot generate.
func FuzzCalculateDvMask(f *testing.F) {
	requireCgo(f)

	for i := range shattered1M1s {
		f.Add(marshalW(&shattered1M1s[i]))
	}
	f.Add(make([]byte, shared.Rounds*4))

	f.Fuzz(func(t *testing.T, in []byte) {
		if len(in) < shared.Rounds*4 {
			return
		}

		var w [shared.Rounds]uint32
		for i := range w {
			w[i] = binary.BigEndian.Uint32(in[i*4:])
		}

		got := ubc.CalculateDvMask(&w)
		want := cgo.CalculateDvMask(&w)
		if got != want {
			t.Fatalf("W: %q\n go dvmask: %d\ncgo dvmask: %d",
				hex.EncodeToString(in[:shared.Rounds*4]), got, want)
		}
	})
}

func marshalW(w *[shared.Rounds]uint32) []byte {
	b := make([]byte, shared.Rounds*4)
	for i, v := range w {
		binary.BigEndian.PutUint32(b[i*4:], v)
	}
	return b
}

func sum(d sha1cd.CollisionResistantHash, in []byte) ([]byte, bool) {
	d.Reset()
	d.Write(in)
	return d.CollisionResistantSum(nil)
}

func requireCgo(f *testing.F) {
	f.Helper()

	if !cgoEnabled {
		f.Fatal("differential fuzzing requires CGO_ENABLED=1, otherwise the cgo package falls back to the Go implementation")
	}
}
