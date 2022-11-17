package cgo

// #include <lib/sha1.h>
// #include <lib/sha1.c>
// #include <lib/ubc_check.h>
// #include <lib/ubc_check.c>
import "C"

import (
	"crypto/sha1"
	"crypto/sha256"
	"errors"
	"unsafe"
)

var ErrSHA1CollisionDetected = errors.New("sha1 collision attack detected")

func New() *digest {
	d := new(digest)
	d.Reset()
	d.WithPanic()
	return d
}

func (d *digest) WithReducedRoundCollisionDetection(enabled bool) *digest {
	if enabled {
		C.SHA1DCSetDetectReducedRoundCollision(&d.ctx, 1)
	} else {
		C.SHA1DCSetDetectReducedRoundCollision(&d.ctx, 0)
	}
	return d
}

func (d *digest) WithPanic() {
	d.outcome = func(_ []byte) []byte {
		panic(ErrSHA1CollisionDetected.Error())
	}
}

func (d *digest) WithSHA256Truncated() {
	d.outcome = func(in []byte) []byte {
		h := sha256.Sum256(in)
		return h[:sha1.Size]
	}
}

func (d *digest) WithCallBack(cb func([]byte) []byte) {
	d.outcome = cb
}

type digest struct {
	ctx C.SHA1_CTX

	// outcome is executed when a collision is found
	// and the errorless Sum() func was called.
	outcome func([]byte) []byte
}

func (d *digest) Write(p []byte) (nn int, err error) {
	data := (*C.char)(C.CBytes(p))
	C.SHA1DCUpdate(&d.ctx, data, (C.ulong)(len(p)))
	C.free(unsafe.Pointer(data))

	return len(p), nil
}

func (d *digest) sum() ([]byte, error) {
	b := make([]byte, sha1.Size)
	ptr := C.CBytes(b)
	defer C.free(unsafe.Pointer(ptr))

	c := C.SHA1DCFinal((*C.uchar)(ptr), &d.ctx)
	if c != 0 {
		return nil, ErrSHA1CollisionDetected
	}

	return C.GoBytes(ptr, sha1.Size), nil
}

func (d *digest) Sum(in []byte) []byte {
	h, err := d.sum()
	if err != nil {
		h = d.outcome(in)
	}
	return append(in, h...)
}

func (d *digest) SumOrError(in []byte) ([]byte, error) {
	h, err := d.sum()
	if err != nil {
		return nil, err
	}
	return append(in, h...), nil
}

func (d *digest) Reset() {
	C.SHA1DCInit(&d.ctx)
}

func (d *digest) Size() int { return sha1.Size }

func (d *digest) BlockSize() int { return sha1.BlockSize }

func Sum(data []byte) ([]byte, error) {
	d := New()
	d.Reset()
	d.Write(data)

	return d.sum()
}
