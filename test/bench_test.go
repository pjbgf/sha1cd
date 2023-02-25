package test

import (
	"crypto/sha1"
	"hash"
	"os"
	"testing"

	"github.com/pjbgf/sha1cd"
	"github.com/pjbgf/sha1cd/cgo"
	"github.com/pjbgf/sha1cd/ubc"
)

func BenchmarkCalculateDvMask(b *testing.B) {
	data := shattered1M1s[0]

	b.Run("go", func(b *testing.B) {
		b.ReportAllocs()
		ubc.CalculateDvMask(data)
	})
	b.Run("cgo", func(b *testing.B) {
		b.ReportAllocs()
		cgo.CalculateDvMask(data)
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

func benchmarkContent(b *testing.B, n string, d hash.Hash, data []byte) {
	b.Run(n, func(b *testing.B) {
		b.ReportAllocs()
		b.SetBytes(int64(len(data)))
		for i := 0; i < b.N; i++ {
			d.Reset()
			d.Write(data)
			d.Sum(data[:0])
		}
	})
}

func BenchmarkHash8Bytes(b *testing.B) {
	benchmarkSize(b, "sha1", sha1.New(), 8)
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 8)
	benchmarkSize(b, "sha1cd_generic", sha1cd.NewGeneric(), 8)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 8)
}

func BenchmarkHash320Bytes(b *testing.B) {
	benchmarkSize(b, "sha1", sha1.New(), 320)
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 320)
	benchmarkSize(b, "sha1cd_generic", sha1cd.NewGeneric(), 320)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 320)
}

func BenchmarkHash1K(b *testing.B) {
	benchmarkSize(b, "sha1", sha1.New(), 1024)
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 1024)
	benchmarkSize(b, "sha1cd_generic", sha1cd.NewGeneric(), 1024)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 1024)
}

func BenchmarkHash8K(b *testing.B) {
	benchmarkSize(b, "sha1", sha1.New(), 8192)
	benchmarkSize(b, "sha1cd_native", sha1cd.New(), 8192)
	benchmarkSize(b, "sha1cd_generic", sha1cd.NewGeneric(), 8192)
	benchmarkSize(b, "sha1cd_cgo", cgo.New(), 8192)
}

func BenchmarkHashWithCollision(b *testing.B) {
	shambles, err := os.ReadFile("testdata/files/sha-mbles-1.bin")
	if err != nil {
		b.Fatal(err)
	}
	benchmarkContent(b, "sha1cd_native", sha1cd.New(), shambles)
	benchmarkContent(b, "sha1cd_generic", sha1cd.NewGeneric(), shambles)
	benchmarkContent(b, "sha1cd_cgo", cgo.New(), shambles)
}
