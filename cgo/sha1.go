package cgo

// #include <lib/sha1.h>
// #include <lib/sha1.c>
// #include <lib/ubc_check.h>
// #include <lib/ubc_check.c>
import "C"

import (
	"crypto"
	"hash"
	"unsafe"
)

const (
	Size      = 20
	BlockSize = 64
)

func init() {
	crypto.RegisterHash(crypto.SHA1, New)
}

func New() hash.Hash {
	d := new(digest)
	d.Reset()
	return d
}

type digest struct {
	ctx C.SHA1_CTX
}

func (d *digest) Write(p []byte) (nn int, err error) {
	data := (*C.char)(C.CBytes(p))
	C.SHA1DCUpdate(&d.ctx, data, (C.ulong)(len(p)))
	C.free(unsafe.Pointer(data))

	return len(p), nil
}

func (d *digest) sum() ([]byte, bool) {
	b := make([]byte, Size)
	ptr := C.CBytes(b)
	defer C.free(unsafe.Pointer(ptr))

	c := C.SHA1DCFinal((*C.uchar)(ptr), &d.ctx)
	collision := c != 0

	return C.GoBytes(ptr, Size), collision
}

func (d *digest) Sum(in []byte) []byte {
	d0 := *d // use a copy of d to avoid race conditions.
	h, _ := d0.sum()
	return append(in, h...)
}

func (d *digest) CollisionResistantSum(in []byte) ([]byte, bool) {
	d0 := *d // use a copy of d to avoid race conditions.
	h, c := d0.sum()
	return append(in, h...), c
}

func (d *digest) Reset() {
	C.SHA1DCInit(&d.ctx)
}

func (d *digest) Size() int { return Size }

func (d *digest) BlockSize() int { return BlockSize }

func Sum(data []byte) ([]byte, bool) {
	d := New().(*digest)
	d.Write(data)

	return d.sum()
}
