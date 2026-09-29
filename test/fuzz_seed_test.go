//go:build gofuzz

package test

import (
	"math/rand"
	"os"
	"testing"
)

// boundaryLengths are the input lengths where the block and padding handling
// changes behaviour: 55/56 is where the length field no longer fits in the
// final block, 63/64/65 is the block buffering boundary, and the higher values
// repeat both one and two blocks in.
var boundaryLengths = []int{
	1, 55, 56, 63, 64, 65, 119, 120, 127, 128, 191, 192,
}

// collisionFiles trigger the collision detection logic. The shattered PDFs do
// so within their first 320 bytes, so only that prefix is seeded: a 400KiB
// seed would be a poor target for mutation.
var collisionFiles = []struct {
	path   string
	length int
}{
	{path: "testdata/files/shattered-1.pdf", length: 320},
	{path: "testdata/files/shattered-1.pdf", length: 512},
	{path: "testdata/files/shattered-2.pdf", length: 320},
	{path: "testdata/files/shattered-2.pdf", length: 512},
	{path: "testdata/files/sha-mbles-1.bin"},
	{path: "testdata/files/sha-mbles-2.bin"},
}

// seedDeviationCorpus adds inputs covering the block and padding boundaries
// along with inputs that reach the collision detection logic, which the
// fuzzer has no realistic chance of generating on its own.
func seedDeviationCorpus(f *testing.F) {
	f.Helper()

	f.Add([]byte{})

	rng := rand.New(rand.NewSource(1))
	for _, n := range boundaryLengths {
		zeros := make([]byte, n)
		f.Add(zeros)

		ones := make([]byte, n)
		for i := range ones {
			ones[i] = 0xff
		}
		f.Add(ones)

		random := make([]byte, n)
		rng.Read(random)
		f.Add(random)
	}

	for _, c := range collisionFiles {
		data, err := os.ReadFile(c.path)
		if err != nil {
			f.Fatalf("unexpected error: %v", err)
		}
		if c.length > 0 {
			data = data[:c.length]
		}
		f.Add(data)
	}
}
