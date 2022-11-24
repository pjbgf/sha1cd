package test

import (
	"encoding/hex"
	"fmt"
	"io/ioutil"
	"strings"
	"testing"

	"github.com/pjbgf/sha1cd"
	"github.com/pjbgf/sha1cd/cgo"
	"github.com/pjbgf/sha1cd/testdata"
	"github.com/pjbgf/sha1cd/ubc"
)

func TestCollisionDetection(t *testing.T) {
	defaultHashers := []sha1cd.CollisionResistantHash{
		cgo.New().(sha1cd.CollisionResistantHash),
		sha1cd.New().(sha1cd.CollisionResistantHash),
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
				data, err := ioutil.ReadFile(tt.inputFile)
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

func TestCalculateDvMask_Shattered1(t *testing.T) {
	for i := range testdata.Shattered1M1s {
		t.Run(fmt.Sprintf("m1[%d]", i), func(t *testing.T) {
			got, gotErr := ubc.CalculateDvMask(testdata.Shattered1M1s[i])
			want, wantErr := cgo.CalculateDvMask(testdata.Shattered1M1s[i])

			if want != got || gotErr != wantErr {
				t.Fatalf("dvmask: %d %v\nwant %d %v", got, gotErr, want, wantErr)
			}
		})
	}
}

func TestCalculateDvMask(t *testing.T) {
	tests := []struct {
		name    string
		input   []uint32
		want    uint32
		wantErr string
	}{
		{
			name:    "empty",
			input:   nil,
			wantErr: "invalid input: len(W) must be 80, was 0",
		},
		{
			name:    "[79]uint32{}",
			input:   make([]uint32, 79),
			wantErr: "invalid input: len(W) must be 80, was 79",
		},
		{
			name:  "[80]uint32{}",
			input: make([]uint32, 80),
		},
	}

	impls := []func(W []uint32) (uint32, error){
		cgo.CalculateDvMask,
		ubc.CalculateDvMask,
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			for _, impl := range impls {
				got, err := impl(tt.input)
				if tt.wantErr == "" && err != nil {
					t.Errorf("unexpected error: %v", err)
				}
				if tt.wantErr != "" {
					if err == nil {
						t.Errorf("expected error: %q, got nil", tt.wantErr)
					} else if !strings.Contains(err.Error(), tt.wantErr) {
						t.Errorf("got: %q, want: %q", err.Error(), tt.wantErr)
					}
				}

				if got != tt.want {
					t.Errorf(" got: %d\n want: %v", got, tt.want)
				}
			}
		})
	}
}
