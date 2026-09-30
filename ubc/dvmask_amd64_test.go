//go:build !noasm && gc && amd64

package ubc

import (
	"fmt"
	"math/bits"
	"math/rand"
	"os"
	"testing"
	"unsafe"
)

// misalignedTerms is a copy of avx512Terms that deliberately starts half way
// through a cache line, which must only cost speed.
var misalignedTerms = func() *uint32 {
	buf := make([]uint32, len(avx512Terms)+32)
	off := (64-uintptr(unsafe.Pointer(&buf[0]))%64)%64/4 + 8
	copy(buf[off:], avx512Terms[:])
	return &buf[off]
}()

func expand(p []byte) [80]uint32 {
	var w [80]uint32
	for i := 0; i < 16; i++ {
		w[i] = uint32(p[4*i])<<24 | uint32(p[4*i+1])<<16 | uint32(p[4*i+2])<<8 | uint32(p[4*i+3])
	}
	for i := 16; i < 80; i++ {
		w[i] = bits.RotateLeft32(w[i-3]^w[i-8]^w[i-14]^w[i-16], 1)
	}
	return w
}

// TestAVX512MatchesGeneric checks the generated kernel against the code it
// was generated from. Most inputs leave no DV standing, so it weights the
// blocks of the collision files and their neighbourhood, which keep them.
func TestAVX512MatchesGeneric(t *testing.T) {
	if !useAVX512 {
		t.Skip("CPU does not support AVX-512")
	}

	rng := rand.New(rand.NewSource(1))
	var n, nonzero int
	var seen uint32
	check := func(w *[80]uint32) {
		t.Helper()
		n++
		want := calculateDvMaskGeneric(w)
		if want != 0 {
			nonzero++
			seen |= want
		}
		if got := calculateDvMaskAVX512(w, alignedTerms, avx512Groups); got != want {
			t.Fatalf("avx512 = %08x, want %08x for %#v", got, want, *w)
		}
		if got := calculateDvMaskAVX512(w, misalignedTerms, avx512Groups); got != want {
			t.Fatalf("avx512 (misaligned table) = %08x, want %08x for %#v", got, want, *w)
		}
		if got := CalculateDvMask(w); got != want {
			t.Fatalf("CalculateDvMask = %08x, want %08x", got, want)
		}
	}

	var near [][80]uint32
	for _, f := range []string{"shattered-1.pdf", "shattered-2.pdf", "sha-mbles-1.bin", "sha-mbles-2.bin"} {
		data, err := os.ReadFile("../test/testdata/files/" + f)
		if err != nil {
			t.Fatal(err)
		}
		for ; len(data) >= 64; data = data[64:] {
			w := expand(data)
			check(&w)
			if calculateDvMaskGeneric(&w) != 0 {
				near = append(near, w)
			}
		}
	}
	for _, m := range near {
		for i := 0; i < 50; i++ {
			w := m
			for f := 1 + rng.Intn(3); f > 0; f-- {
				w[35+rng.Intn(30)] ^= 1 << rng.Intn(32)
			}
			check(&w)
		}
	}

	// Keep going until every DV has been left standing at least once, which
	// DV_I_52_0 rarely is.
	for i := 0; i < 40000 || (seen != ^uint32(0) && i < 2000000); i++ {
		var w [80]uint32
		switch i % 4 {
		case 0: // arbitrary words
			for j := range w {
				w[j] = rng.Uint32()
			}
		case 1: // a message schedule
			var p [64]byte
			rng.Read(p[:])
			w = expand(p[:])
		case 2: // sparse words pass most tests that two bits are equal
			for j := range w {
				w[j] = rng.Uint32() & rng.Uint32() & rng.Uint32()
			}
		case 3: // dense words
			for j := range w {
				w[j] = rng.Uint32() | rng.Uint32() | rng.Uint32()
			}
		}
		check(&w)
	}

	if seen != ^uint32(0) {
		t.Errorf("only DVs %08x were reached, want all of them", seen)
	}
	t.Logf("%d inputs, %d with DVs standing", n, nonzero)
}

var benchmarkMask uint32

func BenchmarkCalculateDvMask(b *testing.B) {
	rng := rand.New(rand.NewSource(1))
	ws := make([][80]uint32, 128)
	for i := range ws {
		var p [64]byte
		rng.Read(p[:])
		ws[i] = expand(p[:])
	}
	impls := []struct {
		name string
		fn   func(*[80]uint32) uint32
	}{{"generic", calculateDvMaskGeneric}}
	if useAVX512 {
		impls = append(impls, struct {
			name string
			fn   func(*[80]uint32) uint32
		}{"avx512", func(w *[80]uint32) uint32 { return calculateDvMaskAVX512(w, alignedTerms, avx512Groups) }})
	}
	for _, impl := range impls {
		b.Run(fmt.Sprint(impl.name), func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				benchmarkMask |= impl.fn(&ws[i&127])
			}
		})
	}
}

// TestTermTableGeometry checks that the kernel is told to run the whole table.
// A group count that truncates would silently skip terms, which no differential
// test catches unless the skipped terms happen to matter for its inputs.
func TestTermTableGeometry(t *testing.T) {
	t.Parallel()

	group := avx512Fields * avx512Lanes
	if n := len(avx512Terms); n%group != 0 {
		t.Errorf("avx512Terms holds %d words, which is not a whole number of %d word groups", n, group)
	}
	if got, want := avx512Groups*group, len(avx512Terms); got != want {
		t.Errorf("the kernel runs %d words of the table, which holds %d", got, want)
	}
}
