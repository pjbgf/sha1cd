package test

import (
	"bytes"
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"hash"
	"math/rand"
	"os"
	"testing"
	_ "unsafe"

	"github.com/pjbgf/sha1cd"
	"github.com/pjbgf/sha1cd/cgo"
	"github.com/pjbgf/sha1cd/ubc"
)

//go:linkname forceGeneric github.com/pjbgf/sha1cd.forceGeneric
var forceGeneric bool

var benchmarkMask uint32

func BenchmarkCalculateDvMask(b *testing.B) {
	data := shattered1M1s[0]

	b.Run("go", func(b *testing.B) {
		b.ReportAllocs()
		for i := 0; i < b.N; i++ {
			benchmarkMask = ubc.CalculateDvMask(&data)
		}
	})
	b.Run("cgo", func(b *testing.B) {
		b.ReportAllocs()
		for i := 0; i < b.N; i++ {
			benchmarkMask = cgo.CalculateDvMask(data)
		}
	})
}

// The hash benchmarks aligns with upstream Go implementation,
// for easier comparison across both.
var buf = make([]byte, 8192)

func benchmarkSize(b *testing.B, n string, d hash.Hash, size int) {
	sum := make([]byte, d.Size())
	b.Run(n, func(b *testing.B) {
		b.ReportAllocs()
		b.SetBytes(int64(size))
		for i := 0; i < b.N; i++ {
			d.Reset()
			d.Write(buf[:size])
			d.Sum(sum[:0])
		}
	})
}

func benchmarkContent(b *testing.B, n string, d hash.Hash, data []byte, fragment int, wantCollision bool) {
	b.Run(n, func(b *testing.B) {
		sum := make([]byte, 0, d.Size())
		write := func() {
			for offset := 0; offset < len(data); {
				end := min(offset+fragment, len(data))
				d.Write(data[offset:end])
				offset = end
			}
		}
		d.Reset()
		write()
		if cd, ok := d.(sha1cd.CollisionResistantHash); ok {
			_, collision := cd.CollisionResistantSum(sum)
			if collision != wantCollision {
				b.Fatalf("collision = %v, want %v", collision, wantCollision)
			}
		}
		b.ReportAllocs()
		b.SetBytes(int64(len(data)))
		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			d.Reset()
			write()
			d.Sum(sum)
		}
	})
}

func BenchmarkHashRandom(b *testing.B) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	data := make([]byte, 8192)
	rand.New(rand.NewSource(1)).Read(data)
	for _, size := range []int{8, 1024, 8192} {
		b.Run(fmt.Sprintf("%d", size), func(b *testing.B) {
			for _, fragment := range []int{size, 7} {
				b.Run(fmt.Sprintf("fragment%d", fragment), func(b *testing.B) {
					benchmarkContent(b, "sha1", sha1.New(), data[:size], fragment, false)
					forceGeneric = false
					benchmarkContent(b, "sha1cd_native", sha1cd.New(), data[:size], fragment, false)
					forceGeneric = true
					benchmarkContent(b, "sha1cd_generic", sha1cd.New(), data[:size], fragment, false)
					benchmarkContent(b, "sha1cd_cgo", cgo.New(), data[:size], fragment, false)
				})
			}
		})
	}
}

func BenchmarkHash8Bytes(b *testing.B) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	benchmarkSize(b, "sha1", sha1.New(), 8)
	forceGeneric = false
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 8)

	forceGeneric = true
	benchmarkSize(b, "sha1cd_generic", sha1cd.New(), 8)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 8)
}

func BenchmarkHash320Bytes(b *testing.B) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	benchmarkSize(b, "sha1", sha1.New(), 320)
	forceGeneric = false
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 320)

	forceGeneric = true
	benchmarkSize(b, "sha1cd_generic", sha1cd.New(), 320)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 320)
}

func BenchmarkHash1K(b *testing.B) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	benchmarkSize(b, "sha1", sha1.New(), 1024)
	forceGeneric = false
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 1024)

	forceGeneric = true
	benchmarkSize(b, "sha1cd_generic", sha1cd.New(), 1024)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 1024)
}

func BenchmarkHash8K(b *testing.B) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	benchmarkSize(b, "sha1", sha1.New(), 8192)
	forceGeneric = false
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 8192)

	forceGeneric = true
	benchmarkSize(b, "sha1cd_generic", sha1cd.New(), 8192)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 8192)
}

func BenchmarkHashWithCollision(b *testing.B) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	shambles, err := os.ReadFile("testdata/files/sha-mbles-1.bin")
	if err != nil {
		b.Fatal(err)
	}
	for _, fragment := range []int{len(shambles), 7} {
		b.Run(fmt.Sprintf("fragment%d", fragment), func(b *testing.B) {
			forceGeneric = false
			benchmarkContent(b, "sha1cd_native", sha1cd.New(), shambles, fragment, true)
			forceGeneric = true
			benchmarkContent(b, "sha1cd_generic", sha1cd.New(), shambles, fragment, true)
			benchmarkContent(b, "sha1cd_cgo", cgo.New(), shambles, fragment, true)
		})
	}
}

func TestCollisionDetection(t *testing.T) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	hashers := []struct {
		name    string
		hasher  sha1cd.CollisionResistantHash
		generic bool
	}{
		{name: "sha1cd_cgo", hasher: cgo.New().(sha1cd.CollisionResistantHash)},
		{name: "sha1cd_native", hasher: sha1cd.New().(sha1cd.CollisionResistantHash)},
		{name: "sha1cd_generic", hasher: sha1cd.New().(sha1cd.CollisionResistantHash), generic: true},
	}

	tests := []struct {
		name          string
		inputFile     string
		wantHash      string
		wantCollision bool
	}{
		{
			name:          "shattered-1 ",
			inputFile:     "testdata/files/shattered-1.pdf",
			wantCollision: true,
			wantHash:      "16e96b70000dd1e7c85b8368ee197754400e58ec",
		},
		{
			name:          "shattered-2",
			inputFile:     "testdata/files/shattered-2.pdf",
			wantCollision: true,
			wantHash:      "e1761773e6a35916d99f891b77663e6405313587",
		},
		{
			name:          "sha-mbles-1",
			inputFile:     "testdata/files/sha-mbles-1.bin",
			wantCollision: true,
			wantHash:      "4f3d9be4a472c4dae83c6314aa6c36a064c1fd14",
		},
		{
			name:          "sha-mbles-2",
			inputFile:     "testdata/files/sha-mbles-2.bin",
			wantCollision: true,
			wantHash:      "9ed5d77a4f48be1dbf3e9e15650733eb850897f2",
		},
		{
			name:      "Valid File",
			inputFile: "testdata/files/valid-file.txt",
			wantHash:  "2b915da50f163514d390c9d87a4f3e23eb663f8a",
		},
	}

	for _, tt := range tests {
		for _, hasher := range hashers {
			for _, fragment := range []int{1 << 20, 7} {
				t.Run(fmt.Sprintf("%s[%s]/fragment%d", tt.name, hasher.name, fragment), func(t *testing.T) {
					data, err := os.ReadFile(tt.inputFile)
					if err != nil {
						t.Fatalf("unexpected error: %v", err)
					}

					forceGeneric = hasher.generic

					d := hasher.hasher
					d.Reset()
					for offset := 0; offset < len(data); offset += fragment {
						d.Write(data[offset:min(offset+fragment, len(data))])
					}

					h, collision := d.CollisionResistantSum(nil)
					if collision != tt.wantCollision {
						t.Errorf("collision\nwanted: %v\n   got: %v", tt.wantCollision, collision)
					}
					if hex.EncodeToString(h) != tt.wantHash {
						t.Errorf("hash\nwanted: %q\n   got: %q", tt.wantHash, hex.EncodeToString(h))
					}
				})
			}
		}
	}
}

func TestCalculateDvMask_Shattered1(t *testing.T) {
	for i := range shattered1M1s {
		t.Run(fmt.Sprintf("m1[%d]", i), func(t *testing.T) {
			want := cgo.CalculateDvMask(shattered1M1s[i])

			got := ubc.CalculateDvMask(&shattered1M1s[i])
			if want != got {
				t.Fatalf("[go] dvmask: %d\nwant %d", got, want)
			}
		})
	}
}

// TestCalculateDvMask_Mutated checks the Go and cgo implementations against
// each other on expanded messages derived from the shattered ones. Purely
// random messages almost never yield a non-zero mask, so they only reach the
// first condition of each disturbance vector check.
func TestCalculateDvMask_Mutated(t *testing.T) {
	t.Parallel()

	rng := rand.New(rand.NewSource(1))
	nonZero := 0

	for i := range shattered1M1s {
		for j := 0; j < 64; j++ {
			w := shattered1M1s[i]
			w[rng.Intn(len(w))] ^= 1 << uint(rng.Intn(32))

			want := cgo.CalculateDvMask(w)
			if got := ubc.CalculateDvMask(&w); got != want {
				t.Fatalf("m1[%d] mutation %d\n go dvmask: %d\ncgo dvmask: %d", i, j, got, want)
			}
			if want != 0 {
				nonZero++
			}
		}
	}

	if nonZero == 0 {
		t.Error("no mutation produced a non-zero mask, the vectors no longer reach the checks")
	}
}

// Exercise schedule reuse across blocks and padding boundaries with differing data.
func TestRandomFragmentedHashes(t *testing.T) {
	previous := forceGeneric
	defer func() { forceGeneric = previous }()
	data := make([]byte, 8192)
	rand.New(rand.NewSource(1)).Read(data)
	for _, size := range []int{0, 1, 55, 56, 63, 64, 65, 127, 128, 129, 1024, 8192} {
		want := sha1.Sum(data[:size])
		for _, generic := range []bool{false, true} {
			forceGeneric = generic
			for _, fragment := range []int{1, 7, 63, 64, 65, 8192} {
				d := sha1cd.New().(sha1cd.CollisionResistantHash)
				for offset := 0; offset < size; offset += fragment {
					d.Write(data[offset:min(offset+fragment, size)])
				}
				got, collision := d.CollisionResistantSum(nil)
				if collision || !bytes.Equal(got, want[:]) {
					t.Fatalf("size=%d generic=%v fragment=%d: hash=%x collision=%v, want %x", size, generic, fragment, got, collision, want)
				}
			}
		}
	}
}
