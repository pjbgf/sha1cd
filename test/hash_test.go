package test

import (
	"bytes"
	"crypto/sha1"
	"encoding"
	"encoding/hex"
	"fmt"
	"math/rand"
	"os"
	"sync"
	"testing"

	"github.com/pjbgf/sha1cd"
	shared "github.com/pjbgf/sha1cd/internal"
)

// writeSplits covers the boundaries of the partial block buffering in
// digest.Write: the block size itself, one byte either side of it, and the
// point at which the padding no longer fits in the final block.
var writeSplits = []int{1, 7, 55, 56, 63, 64, 65, 127, 128}

func TestWriteSplitting(t *testing.T) {
	t.Parallel()

	for _, in := range hashInputs(t) {
		whole := sha1cd.New().(sha1cd.CollisionResistantHash)
		whole.Write(in.data)
		wantHash, wantCol := whole.CollisionResistantSum(nil)

		for _, n := range writeSplits {
			t.Run(fmt.Sprintf("%s/%d", in.name, n), func(t *testing.T) {
				t.Parallel()

				d := sha1cd.New().(sha1cd.CollisionResistantHash)
				for rest := in.data; len(rest) > 0; {
					size := min(n, len(rest))
					if _, err := d.Write(rest[:size]); err != nil {
						t.Fatalf("unexpected error: %v", err)
					}
					rest = rest[size:]
				}

				h, col := d.CollisionResistantSum(nil)
				if !bytes.Equal(h, wantHash) {
					t.Errorf("hash\nwanted: %q\n   got: %q",
						hex.EncodeToString(wantHash), hex.EncodeToString(h))
				}
				if col != wantCol {
					t.Errorf("collision\nwanted: %v\n   got: %v", wantCol, col)
				}
			})
		}
	}
}

func TestEmptyWrite(t *testing.T) {
	t.Parallel()

	d := sha1cd.New()
	for _, p := range [][]byte{nil, {}, []byte("abc"), nil, {}} {
		if _, err := d.Write(p); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
	}

	want := sha1.Sum([]byte("abc"))
	if got := d.Sum(nil); !bytes.Equal(got, want[:]) {
		t.Errorf("hash\nwanted: %q\n   got: %q",
			hex.EncodeToString(want[:]), hex.EncodeToString(got))
	}
}

// TestSumDoesNotConsumeState checks that Sum can be interleaved with Write,
// which the hash.Hash contract requires.
func TestSumDoesNotConsumeState(t *testing.T) {
	t.Parallel()

	d := sha1cd.New()
	d.Write([]byte("abc"))

	first := d.Sum(nil)
	if second := d.Sum(nil); !bytes.Equal(first, second) {
		t.Fatalf("Sum is not repeatable\nfirst: %q\nsecond: %q",
			hex.EncodeToString(first), hex.EncodeToString(second))
	}

	d.Write([]byte("def"))
	want := sha1.Sum([]byte("abcdef"))
	if got := d.Sum(nil); !bytes.Equal(got, want[:]) {
		t.Errorf("hash after continued write\nwanted: %q\n   got: %q",
			hex.EncodeToString(want[:]), hex.EncodeToString(got))
	}
}

func TestResetClearsCollision(t *testing.T) {
	t.Parallel()

	data := readFile(t, "testdata/files/shattered-1.pdf")

	d := sha1cd.New().(sha1cd.CollisionResistantHash)
	d.Write(data)
	if _, col := d.CollisionResistantSum(nil); !col {
		t.Fatal("wanted a collision for shattered-1")
	}

	d.Reset()
	d.Write([]byte("abc"))

	h, col := d.CollisionResistantSum(nil)
	if col {
		t.Error("collision reported after Reset")
	}
	want := sha1.Sum([]byte("abc"))
	if !bytes.Equal(h, want[:]) {
		t.Errorf("hash\nwanted: %q\n   got: %q",
			hex.EncodeToString(want[:]), hex.EncodeToString(h))
	}
}

// TestMarshalRoundTrip checks that a hash can be marshalled part way through
// an input and resumed, for every offset around the block boundary.
func TestMarshalRoundTrip(t *testing.T) {
	t.Parallel()

	for _, in := range hashInputs(t) {
		for _, n := range writeSplits {
			if n > len(in.data) {
				continue
			}

			t.Run(fmt.Sprintf("%s/%d", in.name, n), func(t *testing.T) {
				t.Parallel()

				whole := sha1cd.New().(sha1cd.CollisionResistantHash)
				whole.Write(in.data)
				wantHash, wantCol := whole.CollisionResistantSum(nil)

				d := sha1cd.New().(sha1cd.CollisionResistantHash)
				d.Write(in.data[:n])

				state, err := d.(encoding.BinaryMarshaler).MarshalBinary()
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}
				if len(state) != shared.MarshaledSize {
					t.Errorf("marshaled size\nwanted: %d\n   got: %d", shared.MarshaledSize, len(state))
				}

				resumed := sha1cd.New().(sha1cd.CollisionResistantHash)
				if err := resumed.(encoding.BinaryUnmarshaler).UnmarshalBinary(state); err != nil {
					t.Fatalf("unexpected error: %v", err)
				}
				resumed.Write(in.data[n:])

				h, col := resumed.CollisionResistantSum(nil)
				if !bytes.Equal(h, wantHash) {
					t.Errorf("hash\nwanted: %q\n   got: %q",
						hex.EncodeToString(wantHash), hex.EncodeToString(h))
				}
				if col != wantCol {
					t.Errorf("collision\nwanted: %v\n   got: %v", wantCol, col)
				}
			})
		}
	}
}

func TestUnmarshalRejectsInvalidState(t *testing.T) {
	t.Parallel()

	valid, err := sha1cd.New().(encoding.BinaryMarshaler).MarshalBinary()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	tests := []struct {
		name  string
		state []byte
	}{
		{name: "empty", state: nil},
		{name: "truncated magic", state: valid[:3]},
		{name: "wrong magic", state: append([]byte("xxxxx\x01"), valid[len(shared.Magic):]...)},
		{name: "truncated", state: valid[:len(valid)-1]},
		{name: "too long", state: append(valid, 0)},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			d := sha1cd.New().(encoding.BinaryUnmarshaler)
			if err := d.UnmarshalBinary(tt.state); err == nil {
				t.Error("wanted an error, got nil")
			}
		})
	}
}

// TestConcurrentHashing hashes the same input from several goroutines. Under
// -race this varies the register and scheduling state the assembly is entered
// with, which is how the uninitialised R16 on arm64 first surfaced.
func TestConcurrentHashing(t *testing.T) {
	t.Parallel()

	for _, in := range hashInputs(t) {
		t.Run(in.name, func(t *testing.T) {
			t.Parallel()

			d := sha1cd.New().(sha1cd.CollisionResistantHash)
			d.Write(in.data)
			wantHash, wantCol := d.CollisionResistantSum(nil)

			var wg sync.WaitGroup
			for i := 0; i < 8; i++ {
				wg.Add(1)
				go func() {
					defer wg.Done()

					for j := 0; j < 16; j++ {
						h, col := sha1cd.Sum(in.data)
						if !bytes.Equal(h[:], wantHash) {
							t.Errorf("hash\nwanted: %q\n   got: %q",
								hex.EncodeToString(wantHash), hex.EncodeToString(h[:]))
							return
						}
						if col != wantCol {
							t.Errorf("collision\nwanted: %v\n   got: %v", wantCol, col)
							return
						}
					}
				}()
			}
			wg.Wait()
		})
	}
}

type hashInput struct {
	name string
	data []byte
}

// hashInputs covers the block and padding boundaries, along with inputs that
// reach the collision detection logic.
func hashInputs(t *testing.T) []hashInput {
	t.Helper()

	inputs := []hashInput{{name: "empty", data: []byte{}}}

	rng := rand.New(rand.NewSource(1))
	for _, n := range []int{1, 55, 56, 63, 64, 65, 127, 128, 191, 192} {
		data := make([]byte, n)
		rng.Read(data)
		inputs = append(inputs, hashInput{name: fmt.Sprintf("random-%d", n), data: data})
	}

	for _, name := range []string{"shattered-1.pdf", "sha-mbles-1.bin"} {
		inputs = append(inputs, hashInput{
			name: name,
			data: readFile(t, "testdata/files/"+name),
		})
	}

	return inputs
}

func readFile(t *testing.T, path string) []byte {
	t.Helper()

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	return data
}
