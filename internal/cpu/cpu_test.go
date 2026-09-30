package cpu

import (
	"encoding/binary"
	"testing"
)

func TestHwcapFromAuxv(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		auxv   []uintptr
		want   uint64
		wantOK bool
	}{
		{name: "nil"},
		{name: "no hwcap", auxv: []uintptr{6, 4096, 0, 0}},
		{name: "sha1", auxv: []uintptr{6, 4096, _AT_HWCAP, 0xff, 0, 0}, want: 0xff, wantOK: true},
		{name: "no sha1", auxv: []uintptr{_AT_HWCAP, 0x1f, 0, 0}, want: 0x1f, wantOK: true},
		{name: "truncated", auxv: []uintptr{6, 4096, _AT_HWCAP}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			got, ok := hwcapFromAuxv(tt.auxv)
			if got != tt.want || ok != tt.wantOK {
				t.Errorf("got %#x, %v, want %#x, %v", got, ok, tt.want, tt.wantOK)
			}

			// The procfs encoding of the same vector must agree.
			buf := make([]byte, 16*(len(tt.auxv)/2))
			for i := 0; i+1 < len(tt.auxv); i += 2 {
				binary.LittleEndian.PutUint64(buf[8*i:], uint64(tt.auxv[i]))
				binary.LittleEndian.PutUint64(buf[8*i+8:], uint64(tt.auxv[i+1]))
			}
			got, ok = hwcapFromProcAuxv(buf)
			if got != tt.want || ok != tt.wantOK {
				t.Errorf("procfs: got %#x, %v, want %#x, %v", got, ok, tt.want, tt.wantOK)
			}
		})
	}
}
