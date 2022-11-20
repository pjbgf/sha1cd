package cgo

// #include <../cgo/lib/ubc_check.h>
// #include <stdlib.h>
//
// uint32_t check(const uint32_t W[80])
// {
//	 uint32_t ubc_dv_mask[DVMASKSIZE] = {(uint32_t)(0xFFFFFFFF)};
//   ubc_check(W, ubc_dv_mask);
//   return ubc_dv_mask[0];
// }
import "C"
import (
	"unsafe"
)

// CalculateDvMask takes as input an expanded message block and verifies the unavoidable
// bitconditions for all listed DVs. It returns a dvmask where each bit belonging to a DV
// is set if all unavoidable bitconditions for that DV have been met.
// Thus, one needs to do the recompression check for each DV that has its bit set.
func CalculateDvMask(W []uint32) uint32 {
	// Pre-allocating the C array instead of simply sending across an
	// unsafe pointer to W, as that approach yielded non-deterministic
	// results at scale or with high GC pressure.
	l := (C.uint64_t)(len(W))
	p := C.calloc(l, l)
	defer C.free(p)

	sliceHeader := struct {
		p   unsafe.Pointer
		len int
		cap int
	}{p, len(W), len(W)}

	s := *(*[]uint32)(unsafe.Pointer(&sliceHeader))
	copy(s, W)

	return uint32(C.check((*C.uint32_t)(p)))
}
