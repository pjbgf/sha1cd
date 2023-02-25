package test

import (
	"encoding/hex"
	"fmt"
	"io/ioutil"
	"testing"

	"github.com/pjbgf/sha1cd"
	"github.com/pjbgf/sha1cd/cgo"
	"github.com/pjbgf/sha1cd/ubc"
)

func TestCollisionDetection(t *testing.T) {
	hashers := []struct {
		name   string
		hasher sha1cd.CollisionResistantHash
	}{
		{name: "sha1cd_cgo", hasher: cgo.New().(sha1cd.CollisionResistantHash)},
		{name: "sha1cd_native", hasher: sha1cd.New().(sha1cd.CollisionResistantHash)},
		{name: "sha1cd_generic", hasher: sha1cd.NewGeneric().(sha1cd.CollisionResistantHash)},
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
			t.Run(fmt.Sprintf("%s[%s]", tt.name, hasher.name), func(t *testing.T) {
				data, err := ioutil.ReadFile(tt.inputFile)
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}

				d := hasher.hasher
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

func TestCalculateDvMask_Shattered1(t *testing.T) {
	for i := range shattered1M1s {
		t.Run(fmt.Sprintf("m1[%d]", i), func(t *testing.T) {
			got := ubc.CalculateDvMask(shattered1M1s[i])
			want := cgo.CalculateDvMask(shattered1M1s[i])

			if want != got {
				t.Fatalf("dvmask: %d\nwant %d", got, want)
			}
		})
	}
}
