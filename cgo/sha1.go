package cgo

// #include <sha1.h>
// #include <ubc_check.h>
import "C"

import (
	"hash"
	"unsafe"
)

const (
	Size      = 20
	BlockSize = 64
)

func New() hash.Hash {
	var d digest
	d.Reset()
	return &d
}

type digest struct {
	ctx C.SHA1_CTX
	h   [Size]byte
}

// sum finalises ctx in place. No further writes are possible afterwards.
func (d *digest) sum() ([Size]byte, bool) {
	c := C.SHA1DCFinal((*C.uchar)(unsafe.Pointer(&d.h[0])), &d.ctx)
	return d.h, c != 0
}

func (d *digest) Sum(in []byte) []byte {
	h, _ := d.CollisionResistantSum(in)
	return h
}

func (d *digest) CollisionResistantSum(in []byte) ([]byte, bool) {
	// SHA1DCFinal consumes the context it is given, so sum a copy. That
	// leaves the caller able to keep writing, and lets several goroutines
	// sum the same digest at once.
	d0 := *d
	h, c := d0.sum()
	return append(in, h[:]...), c
}

func (d *digest) Reset() {
	C.SHA1DCInit(&d.ctx)
}

func (d *digest) Size() int { return Size }

func (d *digest) BlockSize() int { return BlockSize }

func Sum(data []byte) ([]byte, bool) {
	var d digest
	d.Reset()
	d.Write(data)

	h, c := d.sum()
	return h[:], c
}

func (d *digest) Write(p []byte) (nn int, err error) {
	if len(p) == 0 {
		return 0, nil
	}

	data := (*C.char)(unsafe.Pointer(&p[0]))
	C.SHA1DCUpdate(&d.ctx, data, (C.size_t)(len(p)))

	return len(p), nil
}
