package cgo

import (
	"bytes"
	"crypto/sha1"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"testing"

	. "github.com/onsi/gomega"
)

func Test_Hashes(t *testing.T) {
	tests := []struct {
		name        string
		inputFile   string
		reducedHash bool
		wantHash    string
		wantErr     string
	}{
		{
			name:      "shattered-1",
			inputFile: "../testdata/shattered-1.pdf",
			wantErr:   "sha1 collision attack detected",
		},
		{
			name:      "shattered-2",
			inputFile: "../testdata/shattered-2.pdf",
			wantErr:   "sha1 collision attack detected",
		},
		{
			name:      "sha-mbles-1",
			inputFile: "../testdata/sha-mbles-1.bin",
			wantErr:   "sha1 collision attack detected",
		},
		{
			name:      "sha-mbles-2",
			inputFile: "../testdata/sha-mbles-2.bin",
			wantErr:   "sha1 collision attack detected",
		},
		{
			name:      "Reduced SHA disabled",
			inputFile: "../testdata/sha1_reducedsha_coll.bin",
			wantHash:  "a56374e1cf4c3746499bc7c0acb39498ad2ee185",
		},
		{
			name:        "Reduced SHA enabled",
			inputFile:   "../testdata/sha1_reducedsha_coll.bin",
			wantErr:     "sha1 collision attack detected",
			reducedHash: true,
		},
		{
			name:      "Valid File",
			inputFile: "../testdata/valid-file.txt",
			wantHash:  "3a97ef20e25305c580a172c7590d0753e51e72be",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			g := NewWithT(t)

			data, err := os.ReadFile(tt.inputFile)
			g.Expect(err).ToNot(HaveOccurred())

			d := New().WithReducedRoundCollisionDetection(tt.reducedHash)
			d.Write(data)

			h, err := d.SumOrError(nil)
			if tt.wantErr == "" {
				g.Expect(err).ToNot(HaveOccurred())
			} else {
				g.Expect(err).To(HaveOccurred())
				g.Expect(err.Error()).To(ContainSubstring(tt.wantErr))
			}

			g.Expect(hex.EncodeToString(h)).To(Equal(tt.wantHash))
		})
	}
}

var inputTest = []byte("detecting-collision")

func Benchmark_Go_Sha1(b *testing.B) {
	h := sha1.New()

	for n := 0; n < b.N; n++ {
		h.Reset()
		h.Write(inputTest)
	}
}

func Benchmark_Hardened_Sha1(b *testing.B) {
	h := New()

	for n := 0; n < b.N; n++ {
		h.Reset()
		h.Write(inputTest)
	}
}

func Fuzz_DeviationDetection(f *testing.F) {
	f.Add([]byte(inputTest))

	std := sha1.New()
	h := New()

	f.Fuzz(func(t *testing.T, in []byte) {
		std.Reset()
		h.Reset()

		std.Write(in)
		h.Write(in)

		v, err := h.SumOrError(nil)
		if bytes.Compare(std.Sum(nil), v) != 0 {
			// When comparing against the standard SHA1 implementation,
			// the output hash must always match, unless there was a collision
			// detected.
			if err == nil || !errors.Is(err, ErrSHA1CollisionDetected) {
				panic(fmt.Sprintf("input %v caused a hash deviation", in))
			}
		}
	})
}
