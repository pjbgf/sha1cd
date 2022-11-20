package test

import (
	"bytes"
	"encoding/hex"
	"fmt"
	"os"
	"testing"

	"github.com/pjbgf/sha1cd"
	"github.com/pjbgf/sha1cd/cgo"
	"github.com/pjbgf/sha1cd/testdata"
	"github.com/pjbgf/sha1cd/ubc"
)

func TestCollisionDetection(t *testing.T) {
	defaultHashers := []sha1cd.CollisionResistantHash{
		cgo.New(),
		sha1cd.New(),
	}

	tests := []struct {
		name          string
		inputFile     string
		wantHash      string
		wantCollision bool
		hashers       []sha1cd.CollisionResistantHash
	}{
		{
			name:          "shattered-1 ",
			inputFile:     "../testdata/files/shattered-1.pdf",
			wantCollision: true,
			wantHash:      "16e96b70000dd1e7c85b8368ee197754400e58ec",
			hashers:       defaultHashers,
		},
		{
			name:          "shattered-2",
			inputFile:     "../testdata/files/shattered-2.pdf",
			wantCollision: true,
			wantHash:      "e1761773e6a35916d99f891b77663e6405313587",
			hashers:       defaultHashers,
		},
		{
			name:          "sha-mbles-1",
			inputFile:     "../testdata/files/sha-mbles-1.bin",
			wantCollision: true,
			wantHash:      "4f3d9be4a472c4dae83c6314aa6c36a064c1fd14",
			hashers:       defaultHashers,
		},
		{
			name:          "sha-mbles-2",
			inputFile:     "../testdata/files/sha-mbles-2.bin",
			wantCollision: true,
			wantHash:      "9ed5d77a4f48be1dbf3e9e15650733eb850897f2",
			hashers:       defaultHashers,
		},
		{
			name:      "Valid File",
			inputFile: "../testdata/files/valid-file.txt",
			wantHash:  "3a97ef20e25305c580a172c7590d0753e51e72be",
			hashers:   defaultHashers,
		},
	}

	for _, tt := range tests {
		for i, d := range tt.hashers {
			t.Run(fmt.Sprintf("%s[%d]", tt.name, i), func(t *testing.T) {
				data, err := os.ReadFile(tt.inputFile)
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}

				d.Reset()
				d.Write(data)

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

func FuzzDeviationDetection(f *testing.F) {
	f.Add([]byte{})

	g := sha1cd.New()
	c := cgo.New()

	f.Fuzz(func(t *testing.T, in []byte) {
		g.Reset()
		c.Reset()

		g.Write(in)
		c.Write(in)

		gv, gc := g.CollisionResistantSum(nil)
		cv, cc := c.CollisionResistantSum(nil)

		if bytes.Compare(gv, cv) != 0 || gc != cc {
			t.Fatalf("input: %q\n go result: %q %v\ncgo result: %q %v",
				hex.EncodeToString(in), hex.EncodeToString(gv), gc, hex.EncodeToString(cv), cc)
		}
	})
}

func TestCalculateDvMask(t *testing.T) {
	for i := range testdata.Shattered1M1s {
		t.Run(fmt.Sprintf("m1[%d]", i), func(t *testing.T) {
			got := ubc.CalculateDvMask(testdata.Shattered1M1s[i])
			want := cgo.CalculateDvMask(testdata.Shattered1M1s[i])

			if want != got {
				t.Fatalf("dvmask: %d want %d", got, want)
			}
		})
	}
}
